#!/usr/bin/python3

# model=os.environ.get("PEN_ENGINE"),
# os.environ.get("PEN_PROMPT"),
# response_length=int(os.environ.get("PEN_MAX_TOKENS")),
# top_p=float(os.environ.get("PEN_TOP_P")),
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


print(query({"inputs": PEN_PROMPT})[0].get("generated_text"))
