#!/usr/bin/python3.8

import os
import cohere
import json

def hard_bound(x, lower_lim, upper_lim):
    if (x is not None) and (upper_lim is not None) and x > upper_lim:
        return upper_lim

    if (x is not None) and (lower_lim is not None) and x < lower_lim:
        return lower_lim

    return x

COHERE_API_KEY = os.environ.get("COHERE_API_KEY")
PEN_MODEL = os.environ.get("PEN_MODEL") or "large"
PEN_PROMPT = os.environ.get("PEN_PROMPT")
PEN_PAYLOADS = os.environ.get("PEN_PAYLOADS")
PEN_PRESENCE_PENALTY = os.environ.get("PEN_PRESENCE_PENALTY") or "0"

if PEN_PRESENCE_PENALTY:
    PEN_PRESENCE_PENALTY = float(PEN_PRESENCE_PENALTY)

PEN_STOP_SEQUENCES = json.loads(os.environ.get("PEN_STOP_SEQUENCES") or "[\"\\n\"]") or ["\n"]
PEN_STOP_SEQUENCE = os.environ.get("PEN_STOP_SEQUENCE") or "\n"
# LOGPROBS can be None, and it doesn't return tonnes of logits.
PEN_LOGPROBS = os.environ.get("PEN_LOGPROBS") # or "10"
PEN_N_COMPLETIONS = os.environ.get("PEN_N_COMPLETIONS") or "2"

if PEN_N_COMPLETIONS:
    PEN_N_COMPLETIONS = int(PEN_N_COMPLETIONS)

# Can only generate 5 at a time
if PEN_N_COMPLETIONS > 5:
    PEN_N_COMPLETIONS = 5

PEN_FREQUENCY_PENALTY = os.environ.get("PEN_FREQUENCY_PENALTY") or "0"

if PEN_FREQUENCY_PENALTY:
    PEN_FREQUENCY_PENALTY = float(PEN_FREQUENCY_PENALTY)

PEN_MIN_TOKENS = os.environ.get("PEN_MIN_TOKENS") and int(os.environ.get("PEN_MIN_TOKENS"))
PEN_MAX_TOKENS = (os.environ.get("PEN_MAX_TOKENS") and int(os.environ.get("PEN_MAX_TOKENS"))) or int("30")
PEN_MAX_GENERATED_TOKENS = os.environ.get("PEN_MAX_GENERATED_TOKENS") and int(os.environ.get("PEN_MAX_GENERATED_TOKENS"))
PEN_ENGINE_MIN_TOKENS = os.environ.get("PEN_ENGINE_MIN_TOKENS") and int(os.environ.get("PEN_ENGINE_MIN_TOKENS"))
PEN_ENGINE_MAX_TOKENS = os.environ.get("PEN_ENGINE_MAX_TOKENS") and int(os.environ.get("PEN_ENGINE_MAX_TOKENS"))
PEN_ENGINE_MAX_GENERATED_TOKENS = os.environ.get("PEN_ENGINE_MAX_GENERATED_TOKENS") and int(os.environ.get("PEN_ENGINE_MAX_GENERATED_TOKENS"))
PEN_TEMPERATURE = os.environ.get("PEN_TEMPERATURE") or "0.1"
PEN_TOP_K = os.environ.get("PEN_TOP_K") or "0"
PEN_TOP_P = os.environ.get("PEN_TOP_P") or "0.0"
PEN_MIN_TOKENS = hard_bound(PEN_MIN_TOKENS, PEN_ENGINE_MIN_TOKENS, PEN_ENGINE_MAX_TOKENS)
PEN_MAX_TOKENS = hard_bound(PEN_MAX_TOKENS, PEN_ENGINE_MIN_TOKENS, PEN_ENGINE_MAX_TOKENS)

if __name__ == "__main__":
    # Get your API Key at https://cohere.ai/

    if PEN_ENGINE_MAX_GENERATED_TOKENS:
        PEN_MAX_GENERATED_TOKENS = hard_bound(PEN_MAX_GENERATED_TOKENS, 0, PEN_ENGINE_MAX_GENERATED_TOKENS)

    if not PEN_MAX_GENERATED_TOKENS:
        PEN_MAX_GENERATED_TOKENS = PEN_MAX_TOKENS

    final_top_p = PEN_TOP_P and float(PEN_TOP_P)
    final_top_k = PEN_TOP_K and int(PEN_TOP_K)

    final_temperature = PEN_TEMPERATURE and float(PEN_TEMPERATURE)

    final_stop_sequence = PEN_STOP_SEQUENCE

    api_key = os.environ.get("COHERE_API_KEY")
    co = cohere.Client(api_key)

    model = os.environ.get("PEN_MODEL")

    #  token_min_length=PEN_MIN_TOKENS,

    gen=co.generate(
                model=PEN_MODEL,
                prompt=PEN_PROMPT,
                max_tokens=PEN_MAX_GENERATED_TOKENS,
                temperature=final_temperature,
                presence_penalty=PEN_PRESENCE_PENALTY,
                stop_sequences=PEN_STOP_SEQUENCES,
                frequency_penalty=PEN_FREQUENCY_PENALTY,
                num_generations=PEN_N_COMPLETIONS,
                k=final_top_k,
                p=final_top_p
            )

    if len(gen.generations) == 1:
        print(PEN_PROMPT, end = '')
        print(gen.generations[0].text)
    else:
        for x in range(len(gen.generations)):
            print(f"===== Completion %i =====" % x)
            print(PEN_PROMPT, end = '')
            print(gen.generations[x].text)
