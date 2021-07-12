#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# e:gpt-j-complete.sh

import os

from transformers import GPTNeoForCausalLM, AutoTokenizer
import torch
import transformers
import copy
import gc
import pickle
import torch.cuda.comm
import time

from IPython.display import HTML, display
import ipywidgets as widgets

# # Import model

low_ram_method = True

if low_ram_method:
    directory = "parts/"
    with open(directory + "emptymodel" + ".pkl", "rb") as f:
        model = pickle.load(f)
    count = 0
    for i in model.parameters():
        count += 1
        with open(directory + str(count) + ".pkl", "rb") as f:
            current_layer = pickle.load(f)
        i.data = current_layer.data
print(count)

# # Tokenizer

tokenizer = AutoTokenizer.from_pretrained("gpt2")
tokenizer.pad_token = tokenizer.eos_token
tokenizer.padding_side = "left"

# # Set vram, shared/pinned memory and regular ram usage
#
# increase ram_blocks if cuda runs out of memory, decrease max_shared_ram_blocks if it raises an error in the code. Current settings are for 8gb vram and 8gb shared memory

breakmodel = True
ram_blocks = 23
max_shared_ram_blocks = 18
if ram_blocks > len(model.transformer.h):
    ram_blocks = len(model.transformer.h)
if ram_blocks < 2:
    ram_blocks = 2

# # Modify the forward pass

from transformers import GPTNeoForCausalLM, GPTNeoModel
from transformers.modeling_outputs import BaseModelOutputWithPast
from transformers.models.gpt_neo.modeling_gpt_neo import GPTNeoAttentionMixin


def new_forward(
    self,
    input_ids=None,
    past_key_values=None,
    attention_mask=None,
    token_type_ids=None,
    position_ids=None,
    head_mask=None,
    inputs_embeds=None,
    use_cache=None,
    output_attentions=None,
    output_hidden_states=None,
    return_dict=None,
):
    global breakmodel

    if breakmodel:
        global ram_blocks
        global max_shared_ram_blocks

        if not hasattr(self, "extrastorage"):
            import copy

            setattr(self, "extrastorage", {})
            torch.cuda.empty_cache()

            for i in range(ram_blocks, len(self.h)):
                self.h[i].to("cuda")

            for i in range(ram_blocks):
                self.h[i].to("cpu")
                self.extrastorage[i] = copy.deepcopy(self.h[i])
                smalltensor = torch.tensor(0).to("cuda")
                for param1 in self.h[i].parameters():
                    param1.data = smalltensor
                self.h[i].to("cuda")

            for i in range(len(self.h)):
                for param in self.h[i].parameters():
                    param.requires_grad = False
                    param.data = param.data.detach()
                    gc.collect()
                    torch.cuda.empty_cache()

            for i in range(ram_blocks):
                for param in self.extrastorage[i].parameters():
                    param.requires_grad = False
                    if i < max_shared_ram_blocks:
                        try:
                            param.data = param.data.detach().pin_memory()
                        except:
                            raise ValueError(
                                "max_shared_ram_blocks is set too high, please set it to "
                                + str(i)
                            )
                    else:
                        param.data = param.data.detach()
                    gc.collect()
                    torch.cuda.empty_cache()

            for param1, param2 in zip(
                self.h[0].parameters(), self.extrastorage[0].parameters()
            ):
                param1.data = param2.data.to("cuda", non_blocking=False).detach()

            for param1, param2 in zip(
                self.h[ram_blocks - 1].parameters(),
                self.extrastorage[ram_blocks - 1].parameters(),
            ):
                param1.data = param2.data.to("cuda", non_blocking=False).detach()
        # END MODEL BREAK EDITS

        output_attentions = (
            output_attentions
            if output_attentions is not None
            else self.config.output_attentions
        )
        output_hidden_states = (
            output_hidden_states
            if output_hidden_states is not None
            else self.config.output_hidden_states
        )
        use_cache = use_cache if use_cache is not None else self.config.use_cache
        return_dict = (
            return_dict if return_dict is not None else self.config.use_return_dict
        )

        if input_ids is not None and inputs_embeds is not None:
            raise ValueError(
                "You cannot specify both input_ids and inputs_embeds at the same time"
            )
        elif input_ids is not None:
            input_shape = input_ids.size()
            input_ids = input_ids.view(-1, input_shape[-1])
            batch_size = input_ids.shape[0]
        elif inputs_embeds is not None:
            input_shape = inputs_embeds.size()[:-1]
            batch_size = inputs_embeds.shape[0]
        else:
            raise ValueError("You have to specify either input_ids or inputs_embeds")

        device = input_ids.device if input_ids is not None else inputs_embeds.device

        if token_type_ids is not None:
            token_type_ids = token_type_ids.view(-1, input_shape[-1])
        if position_ids is not None:
            position_ids = position_ids.view(-1, input_shape[-1])

        if past_key_values is None:
            past_length = 0
            past_key_values = tuple([None] * len(self.h))
        else:
            past_length = past_key_values[0][0].size(-2)

        device = input_ids.device if input_ids is not None else inputs_embeds.device
        if position_ids is None:
            position_ids = torch.arange(
                past_length,
                input_shape[-1] + past_length,
                dtype=torch.long,
                device=device,
            )
            position_ids = position_ids.unsqueeze(0).view(-1, input_shape[-1])

        # Attention mask.
        if attention_mask is not None:
            assert batch_size > 0, "batch_size has to be defined and > 0"
            global_attention_mask = attention_mask.view(batch_size, -1)
            # We create a 3D attention mask from a 2D tensor mask.
            # Sizes are [batch_size, 1, 1, to_seq_length]
            # So we can broadcast to [batch_size, num_heads, from_seq_length, to_seq_length]
            # this attention mask is more simple than the triangular masking of causal attention
            # used in OpenAI GPT, we just need to prepare the broadcast dimension here.
            global_attention_mask = global_attention_mask[:, None, None, :]

            # Since global_attention_mask is 1.0 for positions we want to attend and 0.0 for
            # masked positions, this operation will create a tensor which is 0.0 for
            # positions we want to attend and -10000.0 for masked positions.
            # Since we are adding it to the raw scores before the softmax, this is
            # effectively the same as removing these entirely.
            global_attention_mask = global_attention_mask.to(
                dtype=self.dtype
            )  # fp16 compatibility
            global_attention_mask = (1.0 - global_attention_mask) * -10000.0
        else:
            global_attention_mask = None

        # Local causal attention mask
        batch_size, seq_length = input_shape
        full_seq_length = seq_length + past_length

        # Prepare head mask if needed
        # 1.0 in head_mask indicate we keep the head
        # attention_probs has shape bsz x num_heads x N x N
        # head_mask has shape n_layer x batch x num_heads x N x N
        head_mask = self.get_head_mask(head_mask, self.config.num_layers)

        if inputs_embeds is None:
            inputs_embeds = self.wte(input_ids)

        if self.rotary:
            hidden_states = inputs_embeds
        else:
            position_embeds = self.wpe(position_ids)
            hidden_states = inputs_embeds + position_embeds

        if token_type_ids is not None:
            token_type_embeds = self.wte(token_type_ids)
            hidden_states = hidden_states + token_type_embeds

        hidden_states = self.drop(hidden_states)

        output_shape = input_shape + (hidden_states.size(-1),)

        presents = () if use_cache else None
        all_self_attentions = () if output_attentions else None
        all_hidden_states = () if output_hidden_states else None

        if breakmodel:
            copystream = torch.cuda.Stream(device=0, priority=-1)

        for i, (block, layer_past) in enumerate(zip(self.h, past_key_values)):

            if breakmodel:
                if i in range(ram_blocks):
                    index1 = (i + 1) % ram_blocks
                    for param1, param2 in zip(
                        self.h[index1].parameters(),
                        self.h[(i - 1) % ram_blocks].parameters(),
                    ):
                        param1.data = param2.data
                    for param1, param2 in zip(
                        self.h[index1].parameters(),
                        self.extrastorage[index1].parameters(),
                    ):
                        with torch.cuda.stream(copystream):
                            torch.cuda.comm.broadcast(param2.data, out=[param1.data])

            attn_type = self.config.attention_layers[i]
            attn_mask = global_attention_mask

            if output_hidden_states:
                all_hidden_states = all_hidden_states + (hidden_states,)

            if getattr(self.config, "gradient_checkpointing", False) and self.training:

                if use_cache:
                    logger.warning(
                        "`use_cache=True` is incompatible with `config.gradient_checkpointing=True`. Setting "
                        "`use_cache=False`..."
                    )
                    use_cache = False

                def create_custom_forward(module):
                    def custom_forward(*inputs):
                        # None for past_key_value
                        return module(*inputs, use_cache, output_attentions)

                    return custom_forward

                outputs = torch.utils.checkpoint.checkpoint(
                    create_custom_forward(block),
                    hidden_states,
                    None,
                    attn_mask,
                    head_mask[i],
                )
            else:
                outputs = block(
                    hidden_states,
                    layer_past=layer_past,
                    attention_mask=attn_mask,
                    head_mask=head_mask[i],
                    use_cache=use_cache,
                    output_attentions=output_attentions,
                )

            hidden_states = outputs[0]
            if use_cache is True:
                presents = presents + (outputs[1],)

            if output_attentions:
                all_self_attentions = all_self_attentions + (
                    outputs[2 if use_cache else 1],
                )

            if breakmodel:
                if i in range(ram_blocks):
                    torch.cuda.synchronize()
                    torch.cuda.empty_cache()

        if breakmodel:
            del copystream

        torch.cuda.empty_cache()

        hidden_states = self.ln_f(hidden_states)

        hidden_states = hidden_states.view(*output_shape)
        # Add last hidden state
        if output_hidden_states:
            all_hidden_states = all_hidden_states + (hidden_states,)

        if not return_dict:
            return tuple(
                v
                for v in [
                    hidden_states,
                    presents,
                    all_hidden_states,
                    all_self_attentions,
                ]
                if v is not None
            )

        return BaseModelOutputWithPast(
            last_hidden_state=hidden_states,
            past_key_values=presents,
            hidden_states=all_hidden_states,
            attentions=all_self_attentions,
        )


if breakmodel:
    model.eval().half().to("cpu")

    model.lm_head.to("cuda")
    model.transformer.wte.to("cuda")
    model.transformer.ln_f.to("cuda")

    gc.collect()
    print(GPTNeoModel.forward)
    print(new_forward)
    GPTNeoModel.forward = new_forward
    print(GPTNeoModel.forward)

# # Generation Settings

tail_free_sampling = 0.95  # @param {type:"number"}
top_k = 80  # @param {type:"number"}
top_p = 0.8  # @param {type:"number"}
temperature = 0.7  # @param {type:"number"}
number_generated_tokens = 25  # @param {type:"integer"}
repetition_penalty = 1.1  # @param {type:"number"}
repetition_penalty_range = 512  # @param {type:"number"}
repetition_penalty_slope = 3.33  # @param {type:"number"}

# # Few runs for testing

basic_prompt = "test " * 100000

inputs = tokenizer(
    basic_prompt, return_tensors="pt", truncation=True, max_length=2000
).to("cuda")
with torch.no_grad():
    outputs = model(**inputs)
del outputs
torch.cuda.empty_cache()
start_time = time.time()
with torch.no_grad():
    for i in range(1):
        outputs = model(**inputs)
print(time.time() - start_time)

del inputs, outputs
torch.cuda.empty_cache()

# # Functions for ui


def more_text(inputtext):
    # return "Epictest"
    with torch.no_grad():
        with torch.cuda.amp.autocast(enabled=True):

            context = 2000
            overhead = 50

            currpoint = len(inputtext)
            inputs = tokenizer(
                inputtext[-currpoint:],
                return_tensors="pt",
                truncation=True,
                max_length=context + overhead,
            )
            if inputs.input_ids[0].size()[0] == context + overhead:

                low = 0
                high = len(inputtext)
                currpoint = 0

                # BINARY SEARCH FOR A POINT WHERE TOKENIZER RETURNS BETWEEN CONTEXT AND CONTEXT + OVERHEAD TOKENS
                while low <= high:

                    currpoint = (high + low) // 2

                    # If x is greater, ignore left half
                    inputs = tokenizer(
                        inputtext[-currpoint:],
                        return_tensors="pt",
                        truncation=True,
                        max_length=context + overhead,
                    )

                    if inputs.input_ids[0].size()[0] < context:
                        low = currpoint + 1

                    # If x is smaller, ignore right half
                    elif inputs.input_ids[0].size()[0] == context + overhead:
                        high = currpoint - 1

                    # means x is present at mid
                    else:
                        break

                ids = tokenizer(
                    inputtext[-currpoint:],
                    return_tensors="pt",
                    truncation=True,
                    max_length=context + overhead,
                ).input_ids
            else:
                ids = tokenizer(
                    inputtext[-currpoint:],
                    return_tensors="pt",
                    truncation=True,
                    max_length=context + overhead,
                    padding="max_length",
                ).input_ids

            ids = ids[:, -context:]
            n_ids = ids.shape[1]
            if n_ids < 1:
                n_ids = 1
                ids = torch.tensor([[tokenizer.eos_token_id]])
            max_length = n_ids + number_generated_tokens

            gc.collect()

            basic_output = model.generate(
                ids.long().to("cuda"),
                do_sample=True,
                num_beams=1,
                min_length=max_length,
                max_length=max_length,
                temperature=temperature,
                top_k=top_k,
                top_p=top_p,
                repetition_penalty=repetition_penalty,
                repetition_penalty_range=repetition_penalty_range,
                repetition_penalty_slope=repetition_penalty_slope,
                use_cache=True,
                pad_token_id=tokenizer.eos_token_id,
                num_return_sequences=1,
            ).long()

            gc.collect()
            torch.cuda.empty_cache()

            return tokenizer.decode(basic_output[0][-number_generated_tokens:])

    # print(time.time()  - start_time)
    # print(number_generated_tokens)


def change_text(_):
    global box
    temp_message = "\nCOMPUTE IN PROGRESS"
    box.value += temp_message
    data = more_text(box.value[: -len(temp_message)])
    box.value = box.value[: -len(temp_message)]
    box.value += data


# # UI

box = widgets.Textarea(
    value="",
    placeholder="",
    description="",
    disabled=False,
    rows=20,
    layout={"width": "950px"},
)
button = widgets.Button(description="continue")

display(box)
display(button)
button.on_click(change_text)

#
# # Timing
# Use the last 2 cells to time the notebook <br>
# 1. Put some text in the box<br>
# 2. run the cell 1 to get the start time<br>
# 3. Press the continue button<br>
# 4. Run the cell 2.<br>

# cell 1
time.sleep(10)
start_time = time.time()

# cell 2
print(time.time() - start_time)
