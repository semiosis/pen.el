#!/bin/bash

: "${OPENAI_API_KEY:="$PEN_LM_KEY"}"

if test -s $HOME/.pen/openai_api_key; then
    : "${OPENAI_API_KEY:="$(cat $HOME/.pen/openai_api_key)"}"
fi

test -n "$OPENAI_API_KEY" || {
    echo "OPENAI_API_KEY not given to script"
    exit 1
}

export OPENAI_API_KEY

export PEN_PROMPT
export PEN_PROMPT_FULL
export PEN_SUFFIX
export PEN_VARS
export PEN_MODEL
export PEN_MODE
export PEN_MIN_TOKENS
export PEN_MAX_TOKENS
export PEN_MIN_GENERATED_TOKENS
export PEN_MAX_GENERATED_TOKENS
export PEN_ENGINE_MIN_TOKENS
export PEN_ENGINE_MAX_TOKENS
export PEN_ENGINE_MAX_GENERATED_TOKENS
export PEN_TEMPERATURE
export PEN_TOP_P
export PEN_TOP_K
export PEN_STOP_SEQUENCE
export PEN_STOP_SEQUENCES
export PEN_LOGPROBS
export PEN_LOGIT_BIAS
export PEN_N_COMPLETIONS
export PEN_PRESENCE_PENALTY
export PEN_FREQUENCY_PENALTY
export PEN_TRAILING_WHITESPACE

: "${PEN_N_COMPLETIONS:="2"}"
: "${PEN_MAX_TOKENS:="15"}"
: "${PEN_PRESENCE_PENALTY:="0"}"
: "${PEN_FREQUENCY_PENALTY:="0"}"
: "${PEN_MAX_GENERATED_TOKENS:="5"}"

# No more than 1 currenty supported
# export PEN_N_COMPLETIONS=1

# if test -n "$PEN_N_COMPLETIONS" && test "$PEN_N_COMPLETIONS" -gt 1; then
#     if test "$PEN_N_COMPLETIONS" -gt 4; then
#         PEN_N_COMPLETIONS=2
# 
#         # the mechanism of using multiple prompts might work for a paid
#         # account, but not for the free one
#         PEN_N_COMPLETIONS=1
#     fi
# 
#     FINAL_PEN_PROMPT="$(printf -- "%s" "$PEN_PROMPT" | pen-q-jq | awk 1)"
#     FINAL_PEN_PROMPT="[$(printf -- "%s\n" "$FINAL_PEN_PROMPT" | pen-str repeat-string "$PEN_N_COMPLETIONS" | pen-str join ',')]"
# else
#     # FINAL_PEN_PROMPT="$(cmd-nice-jq "$PEN_PROMPT")"
#     FINAL_PEN_PROMPT="$(printf -- "%s" "$PEN_PROMPT" | pen-q-jq)"
# fi

FINAL_PEN_PROMPT="$(printf -- "%s" "$PEN_PROMPT" | pen-q-jq)"
FINAL_PEN_SUFFIX="$(printf -- "%s" "$PEN_SUFFIX" | pen-q-jq)"

debug_cmd() {
    cmd-nice-posix "$@" | awk 1 1>&2
    "$@"
}

pen_openai() {
    if printf -- "%s\n" "$PEN_FLAGS" | grep -q -P '<openai-begin-newline>'; then
        echo
    fi

    # cmd-nice-jq is very slow. Find a faster, reliable solution.
    # Or use python

    # \"maxTokens\": $PEN_ENGINE_MAX_GENERATED_TOKENS,

    # \"n\": $PEN_N_COMPLETIONS,

    if test "$PEN_MODE" = edit; then
        input="$(PEN_STOP_SEQUENCES)"
        debug_cmd curl "https://api.openai.com/v1/engines/$PEN_MODEL/edits" \
             -H 'Content-Type: application/json' \
             -H "Authorization: Bearer $OPENAI_API_KEY" \
             -X POST \
             -d "{\"input\": $FINAL_PEN_PROMPT,
                  \"suffix\": $FINAL_PEN_SUFFIX,
                  \"max_tokens\": $PEN_MAX_GENERATED_TOKENS,
                  \"stop\": [$(cmd-nice-jq "$PEN_STOP_SEQUENCE")],
                  \"top_p\": $PEN_TOP_P,
                  \"best_of\": $PEN_TOP_K,
                  \"temperature\": $PEN_TEMPERATURE,
                  \"presence_penalty\": $PEN_PRESENCE_PENALTY,
                  \"frequency_penalty\": $PEN_FREQUENCY_PENALTY
                 }"
    elif test -n "$PEN_SUFFIX"; then
        debug_cmd curl "https://api.openai.com/v1/engines/$PEN_MODEL/completions" \
             -H 'Content-Type: application/json' \
             -H "Authorization: Bearer $OPENAI_API_KEY" \
             -X POST \
             -d "{\"prompt\": $FINAL_PEN_PROMPT,
                  \"suffix\": $FINAL_PEN_SUFFIX,
                  \"max_tokens\": $PEN_MAX_GENERATED_TOKENS,
                  \"stop\": [$(cmd-nice-jq "$PEN_STOP_SEQUENCE")],
                  \"top_p\": $PEN_TOP_P,
                  \"best_of\": $PEN_TOP_K,
                  \"temperature\": $PEN_TEMPERATURE,
                  \"presence_penalty\": $PEN_PRESENCE_PENALTY,
                  \"frequency_penalty\": $PEN_FREQUENCY_PENALTY
                 }"
     else
        curl "https://api.openai.com/v1/engines/$PEN_MODEL/completions" \
             -H 'Content-Type: application/json' \
             -H "Authorization: Bearer $OPENAI_API_KEY" \
             -X POST \
             -d "{\"prompt\": $FINAL_PEN_PROMPT,
                  \"max_tokens\": $PEN_MAX_GENERATED_TOKENS,
                  \"stop\": [$(cmd-nice-jq "$PEN_STOP_SEQUENCE")],
                  \"top_p\": $PEN_TOP_P,
                  \"best_of\": $PEN_TOP_K,
                  \"temperature\": $PEN_TEMPERATURE,
                  \"presence_penalty\": $PEN_PRESENCE_PENALTY,
                  \"frequency_penalty\": $PEN_FREQUENCY_PENALTY
                 }"
    fi
}

pen_openai "$@" # | pen-log openai-temp &>/dev/null

{
if test "$PEN_N_COMPLETIONS" = 1; then
    printf -- "%s" "$PEN_PROMPT"
    cat ~/.pen/temp/openai-temp.txt | jq -r ".choices[$((i - 1))].text"
else
    for i in $(seq 1 "$PEN_N_COMPLETIONS"); do
        echo "===== Completion $i ====="
        {
        printf -- "%s" "$PEN_PROMPT"
        cat ~/.pen/temp/openai-temp.txt | jq -r ".choices[$((i - 1))].text"
        } | awk 1
    done | pen-log openai
fi
} 