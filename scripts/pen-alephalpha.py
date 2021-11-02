#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os

ALEPHALPHA_API_KEY = os.environ.get("ALEPHALPHA_API_KEY")
PEN_MODEL = os.environ.get("PEN_MODEL") or "EUTranMultimodal"
PEN_PROMPT = os.environ.get("PEN_PROMPT")
PEN_API_ENDPOINT = os.environ.get("PEN_API_ENDPOINT") or "https://api.aleph-alpha.de"
PEN_PAYLOADS = os.environ.get("PEN_PAYLOADS")
PEN_MODE = os.environ.get("PEN_MODE")
PEN_TRAILING_WHITESPACE = os.environ.get("PEN_TRAILING_WHITESPACE")

from aleph_alpha_client import ImagePrompt, AlephAlphaClient

client = AlephAlphaClient(
    host=PEN_API_ENDPOINT,
    token=ALEPHALPHA_API_KEY
)

# You need to choose a model with multimodal capabilities for this example.
# url = "https://cdn-images-1.medium.com/max/1200/1*HunNdlTmoPj8EKpl-jqvBA.png"
path = "/home/shane/blog/posts/148658560_2839287366296108_857180560792297037_n.jpg"

# image = ImagePrompt.from_url(url)
image = ImagePrompt.from_file(path)
prompt = [
    image,
    PEN_PROMPT
]
result = client.complete(PEN_MODEL,
                         prompt=prompt,
                         temperature=os.environ.get("PEN_TEMPERATURE") and float(os.environ.get("PEN_TEMPERATURE")),
                         maximum_tokens=30)

print(result["completions"][0]["completion"])