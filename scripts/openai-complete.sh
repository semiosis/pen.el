#!/bin/bash

# Example of usage:
# export OPENAI_API_KEY
# export PEN_ environment variables
# openai-complete.sh

# OPENAI_API_KEY="insert key here and uncomment this line"

if test "$PEN_DEBUG" = "y"; then
    echo "PEN_PROMPT:\"$PEN_PROMPT\""
    echo "PEN_LM_COMMAND:\"$PEN_LM_COMMAND\""
    echo "PEN_ENGINE:\"$PEN_ENGINE\""
    echo "PEN_MAX_TOKENS:\"$PEN_MAX_TOKENS\""
    echo "PEN_STOP_SEQUENCE:\"$PEN_STOP_SEQUENCE\""
    echo "PEN_TOP_P:\"$PEN_TOP_P\""
    echo "PEN_CACHE:\"$PEN_CACHE\""
    exit 1
fi

if test -s $HOME/.pen/openai_api_key; then
    : "${OPENAI_API_KEY:="$(cat $HOME/.pen/openai_api_key)"}"
fi

test -n "$OPENAI_API_KEY" || {
    echo "OPENAI_API_KEY not given to script"
    exit 1
}

# tf_prompt="$(mktemp -t "openai_api_XXXXXX.txt" 2>/dev/null)"
# trap "rm \"$tf_prompt\" 2>/dev/null" 0

# Default for OpenAI is davinci
: "${PEN_ENGINE:="davinci"}"
: "${PEN_ENGINE:="curie"}"

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

# Will it complain if PEN_STOP_SEQUENCE is empty?
openai api \
    completions.create \
    -e "$PEN_ENGINE" \
    -t "$PEN_TEMPERATURE" \
    -M "$PEN_MAX_TOKENS" \
    -n "$PEN_N_COMPLETIONS" \
    --stop "$PEN_STOP_SEQUENCE" \
    -p "$PEN_PROMPT" > "$tf_response"

# The API returns the entire prompt + completion
# Which seems a little bit wasteful.
# That may change.

: "${PEN_END_POS:="$(cat "$tf_response" | wc -c)"}"

tail -c "+$(( PEN_END_POS + 1 ))" "$tf_response"
