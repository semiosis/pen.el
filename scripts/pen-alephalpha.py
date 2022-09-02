#!/usr/bin/env python3.8
# -*- coding: utf-8 -*-

import json
import os

from pathlib import Path

ALEPHALPHA_API_KEY = os.environ.get("ALEPHALPHA_API_KEY")
PEN_MODEL = os.environ.get("PEN_MODEL") or "EUTranMultimodal"
PEN_PROMPT = os.environ.get("PEN_PROMPT")
PEN_PAYLOADS = os.environ.get("PEN_PAYLOADS")
PEN_PRESENCE_PENALTY = os.environ.get("PEN_PRESENCE_PENALTY") or "0"
PEN_STOP_SEQUENCES = json.loads(os.environ.get("PEN_STOP_SEQUENCES") or "[\"\\n\"]") or ["\n"]
PEN_STOP_SEQUENCE = os.environ.get("PEN_STOP_SEQUENCE") or "\n"
# LOGPROBS can be None, and it doesn't return tonnes of logits.
PEN_LOGPROBS = os.environ.get("PEN_LOGPROBS") # or "10"
PEN_N_COMPLETIONS = os.environ.get("PEN_N_COMPLETIONS") or "2"
PEN_FREQUENCY_PENALTY = os.environ.get("PEN_FREQUENCY_PENALTY") or "0"
PEN_MAX_TOKENS = os.environ.get("PEN_MAX_TOKENS") or "30"
PEN_TEMPERATURE = os.environ.get("PEN_TEMPERATURE") or "0.1"
PEN_TOP_K = os.environ.get("PEN_TOP_K") or "0"
PEN_TOP_P = os.environ.get("PEN_TOP_P") or "0.0"

if PEN_LOGPROBS == "":
    PEN_LOGPROBS = None

if PEN_PAYLOADS:
    PEN_PAYLOADS = json.loads(PEN_PAYLOADS)

PEN_API_ENDPOINT = os.environ.get("PEN_API_ENDPOINT") or "https://api.aleph-alpha.de"
PEN_MODE = os.environ.get("PEN_MODE")
PEN_TRAILING_WHITESPACE = os.environ.get("PEN_TRAILING_WHITESPACE")

from aleph_alpha_client import ImagePrompt, AlephAlphaModel, AlephAlphaClient, CompletionRequest, Prompt

model = AlephAlphaModel(
    AlephAlphaClient(host="https://api.aleph-alpha.com", token=ALEPHALPHA_API_KEY),
    model_name = PEN_MODEL
)

client = AlephAlphaClient(
    host=PEN_API_ENDPOINT,
    token=ALEPHALPHA_API_KEY
)

payloads = None

# If PEN_PAYLOADS is a dict then iterate through the dict and build a list.
# For each key, if the key equals "image" then add to the new list, otherwise ignore it.
if type(PEN_PAYLOADS) == dict:
    payloads = []
    for key, value in PEN_PAYLOADS.items():
        if key == "image" and "://" in value:
            payloads.append(ImagePrompt.from_url(value))
        elif key == "image" and Path(value).exists():
            payloads.append(ImagePrompt.from_file(Path(value)))

# from shanepy import *
# myembed(globals(), locals())

if payloads is not None and not payloads == []:
    payloads.append(PEN_PROMPT)
    prompt = payloads
else:
    prompt = PEN_PROMPT

result = client.complete(PEN_MODEL,
                         prompt=prompt,
                         n=int(PEN_N_COMPLETIONS),
                         top_k=int(PEN_TOP_K),
                         top_p=float(PEN_TOP_P),
                         log_probs=PEN_LOGPROBS,
                         stop_sequences=PEN_STOP_SEQUENCES,
                         maximum_tokens=int(PEN_MAX_TOKENS),
                         temperature=float(PEN_TEMPERATURE),
                         presence_penalty=float(PEN_PRESENCE_PENALTY),
                         frequency_penalty=float(PEN_FREQUENCY_PENALTY))

cs = result["completions"]

if len(cs) == 1:
    print(PEN_PROMPT, end = '')
    print(cs[0]['completion'])
else:
    for x in range(len(cs)):
        print(f"===== Completion %i =====" % x)
        print(PEN_PROMPT, end = '')
        print(cs[x]['completion'])