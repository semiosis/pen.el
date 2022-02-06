#!/bin/bash
export TTY

curl -X POST https://hf.space/gradioiframe/valhalla/glide-text2im/+/api/predict/ \
    -H 'Content-Type: application/json' \
    -d '{"data": ["an oil painting of a corgi"]}'
