#!/usr/bin/python3

# model=os.environ.get("PEN_ENGINE"),
# os.environ.get("PEN_PROMPT"),
# response_length=int(os.environ.get("PEN_MAX_TOKENS")),
# top_p=float(),
# temperature=float(os.environ.get("PEN_TEMPERATURE")),
# stop_sequence=os.environ.get("PEN_STOP_SEQUENCE"),

# https://api-inference.huggingface.co/docs/python/html/detailed_parameters.html#text-generation-task

import json
import os
import requests

API_TOKEN = os.environ.get("HF_API_KEY")
PEN_ENGINE = os.environ.get("PEN_ENGINE")
PEN_PROMPT = os.environ.get("PEN_PROMPT")

API_URL = f"https://api-inference.huggingface.co/models/{PEN_ENGINE}"
headers = {"Authorization": f"Bearer {API_TOKEN}"}


def query(payload):
    data = json.dumps(payload)
    response = requests.request("POST", API_URL, headers=headers, data=data)
    return json.loads(response.content.decode("utf-8"))


ret = query(
    {
        "inputs": PEN_PROMPT,
        "parameters": {
            "top_k": os.environ.get("PEN_TOP_K") and int(os.environ.get("PEN_TOP_K")),
            "top_p": os.environ.get("PEN_TOP_P") and float(os.environ.get("PEN_TOP_P")),
            "temperature": os.environ.get("PEN_TEMPERATURE")
            and float(os.environ.get("PEN_TEMPERATURE")),
            "repetition_penalty": os.environ.get("PEN_REPETITION_PENALTY")
            and float(os.environ.get("PEN_REPETITION_PENALTY")),
            "max_new_tokens": os.environ.get("PEN_MAX_TOKENS")
            and int(os.environ.get("PEN_MAX_TOKENS")),
            "num_return_sequences": os.environ.get("PEN_N_COMPLETIONS")
            and int(os.environ.get("PEN_N_COMPLETIONS")),
            "return_full_text": False,
        },
        "options": {"wait_for_model": True},
    }
)

if len(ret) == 1 and type(ret) is list:
    print(PEN_PROMPT + ret[0].get("generated_text"))
elif len(ret) == 1 and type(ret) is dict and ret.get("error"):
    print(ret.get("error"))
elif len(ret) > 1:
    for i in range(len(ret)):
        # This is made automatically by hf. Also, it starts at 1
        print(f"===== Completion {i} =====")
        print(PEN_PROMPT + ret[i].get("generated_text"))
