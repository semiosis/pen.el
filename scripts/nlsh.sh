#!/bin/bash
export TTY

os="$1"
shift

export USE_CONVERSATION_MODE=y

# rlwrap openai-complete.sh prompts/nlsh-2.prompt "$os"

while IFS=$'\n' read -p "$os: " -r nlcommand; do
    pena -u pf-nlsh/2 "$os" "$nlcommand" | jq -r ".[]"
done
