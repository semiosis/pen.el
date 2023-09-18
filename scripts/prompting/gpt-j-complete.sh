#!/bin/bash

# Example of usage:
# export OPENAI_API_KEY
# export PEN_ environment variables
# openai-complete.sh

# OPENAI_API_KEY="insert key here and uncomment this line"

openai() {
    python3 `which openai` "$@"
}

p () {
    {
        i=1
        while [ "$i" -lt "$#" ]; do
            eval ARG=\${$i}
            printf -- "%s " "$ARG"
            i=$((i + 1))
        done
        eval ARG=\${$i}
        printf -- "%s" "$ARG"
    } | sed 's/\\n/\n/g' | pen-restore-chars
}

openai_results_split() {
    completions_fp="$1"
    test -f "$completions_fp" || exit 1

    completions_fp="$(realpath "$completions_fp")"

    td="$(mktemp -d)"

    cd "$td"

    if cat "$completions_fp" | grep -q -P '^===== Completion [0-9]+ =====$'; then
        csplit -f splitfile_ -z "$completions_fp" "/^===== Completion [0-9]\\+ =====$/" '{*}' &>/dev/null
        for fp in *; do
            sed -i 1d "$fp"
            tail -c "+$(( PEN_COLLECT_FROM_POS + 1 ))" "$fp" | pen-sponge "$fp"
        done
    else
        cat "$completions_fp" > splitfile_0.txt
    fi

    echo "$td"
}

if test "$PEN_DEBUG" = "y"; then
    echo "PEN_PROMPT:\"$PEN_PROMPT\""
    echo "PEN_MODEL:\"$PEN_MODEL\""
    echo "PEN_MAX_TOKENS:\"$PEN_MAX_TOKENS\""
    echo "PEN_STOP_SEQUENCE:\"$PEN_STOP_SEQUENCE\""
    echo "PEN_TOP_P:\"$PEN_TOP_P\""
    exit 1
fi

if test -s $HOME/.pen/openai_api_key; then
    : "${OPENAI_API_KEY:="$(cat $HOME/.pen/openai_api_key)"}"
fi

test -n "$OPENAI_API_KEY" || {
    echo "OPENAI_API_KEY not given to script"
    exit 1
}

export OPENAI_API_KEY

# tf_prompt="$(mktemp -t "openai_api_XXXXXX.txt" 2>/dev/null)"
# trap "rm \"$tf_prompt\" 2>/dev/null" 0

# Default for OpenAI is davinci
: "${PEN_MODEL:="davinci"}"
: "${PEN_MODEL:="curie"}"

test -n "$PEN_PROMPT" || {
    echo No prompt given
    exit 1
}

: "${PEN_MAX_TOKENS:="60"}"
: "${PEN_TEMPERATURE:="0.8"}"
: "${PEN_TOP_P:="1"}"
: "${PEN_N_COMPLETIONS:="1"}"

tf_response="$(mktemp -t "openai_api_XXXXXX.txt" 2>/dev/null)"
trap "rm \"$tf_response\" 2>/dev/null" 0

# This actually evaluates the newlines, but it also trims the prompt at the ends
PEN_PROMPT="$(p "$PEN_PROMPT")"
# This is designed to not trim whitespace from the ends of the stop sequence
IFS= read -rd '' PEN_STOP_SEQUENCE < <(p "$PEN_STOP_SEQUENCE");typeset -p PEN_STOP_SEQUENCE &>/dev/null

# Will it complain if PEN_STOP_SEQUENCE is empty?
openai api \
    completions.create \
    -e "$PEN_MODEL" \
    -t "$PEN_TEMPERATURE" \
    -M "$PEN_MAX_TOKENS" \
    -n "$PEN_N_COMPLETIONS" \
    --stop "$PEN_STOP_SEQUENCE" \
    -p "$PEN_PROMPT" > "$tf_response"

: "${PEN_COLLECT_FROM_POS:="$(cat "$tf_response" | wc -c)"}"

export PEN_COLLECT_FROM_POS
results_dir="$(openai_results_split "$tf_response")"

# The API returns the entire prompt + completion
# Which seems a little bit wasteful.
# That may change.

# jsonl output would be nice but jq is an extra dependency I don't want.
# Alternatively, can could make it linewise.

echo "$results_dir"
