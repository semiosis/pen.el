#!/bin/bash
export TTY

# Unset TMPDIR so mktemp doesn't use it
# unset TMPDIR
# Actually, tmpdir must be /tmp. The image is reorganised into ~/.pen/results/ outside of this script
export TMPDIR=/tmp

: "${PEN_MODEL:="OpenAI/DALLE2"}"

: "${OPENAI_API_KEY:="$PEN_LM_KEY"}"

if test -s $HOME/.pen/openai_api_key; then
    : "${OPENAI_API_KEY:="$(cat $HOME/.pen/openai_api_key)"}"
fi

test -n "$PEN_PROMPT" || {
    echo No prompt given
    exit 1
}

td="$(mktemp -t "results_$(date-ts-hr)_${PEN_GEN_UUID}_XXXXX" -d -p ~/.pen/results)"

# Use 'jo'.
# : "${PEN_SIZE:="1024x1024"}"
: "${PEN_SIZE:="256x256"}"
: "${PEN_N_COMPLETIONS:=1}"

data="$(jo prompt="$PEN_PROMPT" n=$PEN_N_COMPLETIONS size="$PEN_SIZE")"

img_url="$(curl -X POST "https://api.openai.com/v1/images/generations" \
             -H 'Content-Type: application/json' \
             -H "Authorization: Bearer $OPENAI_API_KEY" \
             -d "$data" | jq -r ".data[0].url // empty")"

slug="$(printf -- "%s\n" "$PEN_PROMPT" | tr '\n' ' ' | sed 's/ $//' | slugify)"

mkdir -p "$td/images"

# cmd mkdir -p "$td/images" | tv &>/dev/null
# cmd wget "$img_url" -O  "$td/images/result-$slug.png" | tv &>/dev/null

wget "$img_url" -O "$td/images/result-$slug.png" &>/dev/null

# echo "$td/images/result-$slug.png" | tv &>/dev/null

# echo "$td/images/result-$slug.png" > "$td/response.txt"
# The directory is moved. Leave out td to make it relative
bntd="$(basename -- "$td")"
# Keep the directory basename only.
echo "$bntd/images/result-$slug.png" > "$td/response.txt"
echo "$td"
