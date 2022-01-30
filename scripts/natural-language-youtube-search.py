#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from os import path, link
import sys

video_url = (len(sys.argv) > 1 and sys.argv[1])
if not video_url:
    exit(1)

query = (len(sys.argv) > 2 and sys.argv[2])

if not query:
    exit(1)

import re

if re.match(r"^https?.*", video_url):
    from pytube import YouTube

    # Choose a video stream with resolution of 360p
    streams = YouTube(video_url).streams.filter(adaptive=True, subtype="mp4", resolution="360p", only_video=True)

    # Check if there is a valid stream
    if len(streams) == 0:
      raise "No suitable stream found for this YouTube video!"

    # Download the video as video.mp4
    print("Downloading...")
    streams[0].download(filename="video")
    print("Download completed.")
    video_path = "video.mp4"
elif path.isfile(video_url):
    video_path = video_url
# elif path.isfile(video_url) and re.match(r".*\.mp4$", video_url):
    # link(video_url, 'video.mp4')
else:
    exit(1)

# How much frames to skip
N = 120

# pytube is used to download videos from YouTube
# !pip install pytube

# Intall a newer version of plotly
# !pip install plotly==4.14.3

# Install CLIP from the GitHub repo
# !pip install git+https://github.com/openai/CLIP.git

# Install torch 1.7.1 with GPU support
# !pip install torch==1.7.1+cu101 torchvision==0.8.2+cu101 -f https://download.pytorch.org/whl/torch_stable.html


import cv2
from PIL import Image

# The frame images will be stored in video_frames
video_frames = []

# Open the video file
capture = cv2.VideoCapture(video_path)

current_frame = 0
while capture.isOpened():
  # Read the current frame
  ret, frame = capture.read()

  # Convert it to a PIL image (required for CLIP) and store it
  if ret == True:
    video_frames.append(Image.fromarray(frame[:, :, ::-1]))
  else:
    break

  # Skip N frames
  current_frame += N
  capture.set(cv2.CAP_PROP_POS_FRAMES, current_frame)

# Print some statistics
print(f"Frames extracted: {len(video_frames)}")

import clip
import torch

# Load the open CLIP model
device = "cuda" if torch.cuda.is_available() else "cpu"
model, preprocess = clip.load("ViT-B/32", device=device, jit=False)

import math
import numpy as np
import torch

# You can try tuning the batch size for very large videos, but it should usually be OK
batch_size = 256
batches = math.ceil(len(video_frames) / batch_size)

# The encoded features will bs stored in video_features
video_features = torch.empty([0, 512], dtype=torch.float16).to(device)

# Process each batch
for i in range(batches):
  print(f"Processing batch {i+1}/{batches}")

  # Get the relevant frames
  batch_frames = video_frames[i*batch_size : (i+1)*batch_size]

  # Preprocess the images for the batch
  batch_preprocessed = torch.stack([preprocess(frame) for frame in batch_frames]).to(device)

  # Encode with CLIP and normalize
  with torch.no_grad():
    batch_features = model.encode_image(batch_preprocessed)
    batch_features /= batch_features.norm(dim=-1, keepdim=True)

  # Append the batch to the list containing all features
  video_features = torch.cat((video_features, batch_features))

# Print some stats
print(f"Features: {video_features.shape}")

import plotly.express as px

import plotly.io as pio; pio.renderers.default='browser'

from shanepy import *

def search_video(search_query, display_heatmap=True, display_results_count=3):

  # Encode and normalize the search query using CLIP
  with torch.no_grad():
    text_features = model.encode_text(clip.tokenize(search_query).to(device))
    text_features /= text_features.norm(dim=-1, keepdim=True)

  # Compute the similarity between the search query and each frame using the Cosine similarity
  similarities = (100.0 * video_features @ text_features.T)
  values, best_photo_idx = similarities.topk(display_results_count, dim=0)

  # Display the heatmap
  if display_heatmap:
    print("Search query heatmap over the frames of the video:")
    fig = px.imshow(similarities.T.cpu().numpy(), height=50, aspect='auto', color_continuous_scale='viridis')
    fig.update_layout(coloraxis_showscale=False)
    fig.update_xaxes(showticklabels=False)
    fig.update_yaxes(showticklabels=False)
    fig.update_layout(margin=dict(l=0, r=0, b=0, t=0))
    fig.show(renderer="png")
    print()

  # Display the top 3 frames
  for frame_id in best_photo_idx:
    # display(video_frames[frame_id])
    video_frames[frame_id].show()
    print()

search_video(query, display_heatmap=True)