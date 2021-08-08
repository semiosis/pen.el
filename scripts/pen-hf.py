#!/usr/bin/python3

# model=os.environ.get("PEN_ENGINE"),
# os.environ.get("PEN_PROMPT"),
# response_length=int(os.environ.get("PEN_MAX_TOKENS")),
# top_p=float(os.environ.get("PEN_TOP_P")),
# temperature=float(os.environ.get("PEN_TEMPERATURE")),
# stop_sequence=os.environ.get("PEN_STOP_SEQUENCE"),

import json
import os
import requests

API_TOKEN = os.environ.get("HF_API_KEY")

API_URL = "https://api-inference.huggingface.co/models/gpt2"
headers = {"Authorization": f"Bearer {API_TOKEN}"}

def query(payload):
    data = json.dumps(payload)
    response = requests.request("POST", API_URL, headers=headers, data=data)
    return json.loads(response.content.decode("utf-8"))

print(query("Can you please let us know more details about your "))
