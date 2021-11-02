#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os

API_TOKEN = os.environ.get("ALEPHALPHA_API_KEY")
PEN_MODEL = os.environ.get("PEN_MODEL")
PEN_PROMPT = os.environ.get("PEN_PROMPT")
PEN_PAYLOADS = os.environ.get("PEN_PAYLOADS")
PEN_MODE = os.environ.get("PEN_MODE")
PEN_TRAILING_WHITESPACE = os.environ.get("PEN_TRAILING_WHITESPACE")

from aleph_alpha_client import ImagePrompt, AlephAlphaClient

client = AlephAlphaClient(
    host="https://test.api.aleph-alpha.de",
    token=key
)

# You need to choose a model with multimodal capabilities for this example.
model = "EUTranMultimodal"
# model = "EUTranLarge128kAlpha001DataAlpha1"
# url = "https://cdn-images-1.medium.com/max/1200/1*HunNdlTmoPj8EKpl-jqvBA.png"
path = "/home/shane/blog/posts/148658560_2839287366296108_857180560792297037_n.jpg"

# image = ImagePrompt.from_url(url)
image = ImagePrompt.from_file(path)
prompt = [
    image,
    """In this surreal artwork,"""
]
result = client.complete(model, prompt=prompt, temperature=0.0, maximum_tokens=30)

print(result["completions"][0]["completion"])