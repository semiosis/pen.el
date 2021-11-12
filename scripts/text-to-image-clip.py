#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

from PIL import Image
import requests

from transformers import CLIPProcessor, CLIPModel

model = CLIPModel.from_pretrained("flax-community/clip-rsicd-v2")
processor = CLIPProcessor.from_pretrained("flax-community/clip-rsicd-v2")

url = "https://raw.githubusercontent.com/arampacha/CLIP-rsicd/master/data/stadium_1.jpg"
image = Image.open(requests.get(url, stream=True).raw)

labels = ["residential area", "playground", "stadium", "forest", "airport"]
inputs = processor(text=[f"a photo of a {l}" for l in labels], images=image, return_tensors="pt", padding=True)

outputs = model(**inputs)
logits_per_image = outputs.logits_per_image # this is the image-text similarity score
probs = logits_per_image.softmax(dim=1) # we can take the softmax to get the label probabilities
for l, p in zip(labels, probs[0]):
    print(f"{l:<16} {p:.4f}")