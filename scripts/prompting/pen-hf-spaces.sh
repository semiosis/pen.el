#!/bin/bash
export TTY

: "${PEN_MODEL:="valhalla/glide-text2im"}"

test -n "$PEN_PROMPT" || {
    echo No prompt given
    exit 1
}

td="$(mktemp -t "results_$(date-ts-hr)_${PEN_GEN_UUID}_XXXXX" -d -p ~/.pen/results)"

# Use 'jo'.

data="$(jo data="$(jo -a "$PEN_PROMPT")")"

png_data="$(curl -X POST "https://hf.space/gradioiframe/$PEN_MODEL/+/api/predict/" \
             -H 'Content-Type: application/json' \
             -d "$data" | jq -r ".data[0] // empty" | cut -d , -f 2)"

slug="$(printf -- "%s\n" "$PEN_PROMPT" | tr '\n' ' ' | sed 's/ $//' | slugify)"

mkdir -p "$td/images"
printf -- "%s" "$png_data" | base64 -d > "$td/images/result-$slug.png"

echo "$td/images/result-$slug.png" > "$td/response.txt"
echo "$td"