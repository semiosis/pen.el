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

API_URL = f"https://api-inference.huggingface.co/models/{PEN_ENGINE}"
headers = {"Authorization": f"Bearer {API_TOKEN}"}


def query(payload):
    data = json.dumps(payload)
    response = requests.request("POST", API_URL, headers=headers, data=data)
    return json.loads(response.content.decode("utf-8"))


print(
    query(
        {
            "inputs": os.environ.get("PEN_PROMPT"),
            top_k: os.environ.get("PEN_TOP_K"),
            top_p: os.environ.get("PEN_TOP_P"),
            temperature: os.environ.get("PEN_TEMPERATURE"),
            repetition_penalty: os.environ.get("PEN_REPETITION_PENALTY"),
            max_new_tokens: os.environ.get("PEN_MAX_TOKENS"),
            num_return_sequences: os.environ.get("PEN_N_COMPLETIONS"),
        }
    )[0].get("generated_text")
)
