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

# The prompt is always chomped for OpenAI
# Bash by default will remove trailing whitespace for command substitution
PEN_PROMPT="$(printf -- "%s" "$PEN_PROMPT")"

# Default for OpenAI is davinci
: "${PEN_ENGINE:="davinci"}"
: "${PEN_ENGINE:="curie"}"

test -n "$prompt" || {
    echo No prompt given
    exit 1
}

: "${PEN_MAX_TOKENS:="60"}"
: "${PEN_TEMPERATURE:="0.8"}"
: "${PEN_TOP_P:="1"}"
: "${PEN_N_COMPLETIONS:="1"}"

ogprompt="$prompt"

prompt_prompt_fp="$(printf -- "%s" "$prompt" | pen-chomp | tf)"

if test "$USE_CONVERSATION_MODE" = "y"; then
    i=1
    for var in "$@"
    do
        # Ensure that nothing is chomped from the arguments
        printf -- "%s" "${var}" | uq -f | IFS= read -r -d '' var
        rlprompt="$(p "$rlprompt" | template -$i "$var")"

        # cmd-nice template -$i "$var"
        ((i++))
    done
fi

repl_run() {
    # Choose to reset after each entry.
    # I should do this by default because of the prompt size.
    # It can't grow beyond a particular length.
    prompt="$ogprompt"

    i=1
    for var in "$@"
    do
        # Ensure that nothing is chomped from the arguments
        printf -- "%s" "${var}" | uq -f | IFS= read -r -d '' var
        prompt="$(p "$prompt" | template -$i "$var")"

        # cmd-nice template -$i "$var"
        ((i++))
    done

    printf -- "%s" "$prompt" | pen-chomp > "$prompt_prompt_fp"

    gen_pos="$(grep "<:pp>" --byte-offset "$prompt_prompt_fp" | cut -d : -f 1)"
    sed -i 's/<:pp>//' "$prompt_prompt_fp"

    prompt="$(cat "$prompt_prompt_fp" | bs '$`"!')"

    IFS= read -r -d '' SHCODE <<HEREDOC
openai api \
    completions.create \
    -e "$engine" \
    -t "$temperature" \
    -M "$max_tokens" \
    -n "$sub_completions" \
    $(
        if test -n "$first_stop_sequence"; then
            printf -- "%s" " --stop $(cmd "$first_stop_sequence")"
        fi
    ) \
    -p "$prompt"
HEREDOC

    shfp="$(printf -- "%s\n" "$SHCODE" | sed -z 's/\n\+$//' | sed -z "s/\\n/\\\n/g" | tf sh)"

    # printf -- "%s\n" "$SHCODE" | tv
    # exit 1

    export UPDATE=y

    response_fp="$(sh "$shfp" | uq | pen-chomp | tf txt)"

    prompt_bytes="$(cat "$prompt_prompt_fp" | wc -c)"
    response_bytes="$(cat "$response_fp" | wc -c)"

    : "${gen_pos:="$((prompt_bytes + 1))"}"

    seddelim=%
    IFS= read -r -d '' stop_sequence_trimmer <<HEREDOC
$(
    printf -- "%s\n" "$stop_sequences" | while IFS=$'\n' read -r s; do
        printf -- "%s" "sed -z 's${seddelim}${s}.*${seddelim}${seddelim}' |"
    done
)
cat
HEREDOC

    tail -c +$gen_pos "$response_fp" | {
        if ( exec 0</dev/null; cat "$prompt_fp" | pen-yq-test chomp-start; ); then
            sed -z 's/^\n\+//' | sed -z 's/^\s\+//'
        else
            cat
        fi |
            if ( exec 0</dev/null; cat "$prompt_fp" | pen-yq-test chomp-end; ); then
                sed -z 's/\n\+$//' | sed -z 's/\s\+$//'
            else
                cat
            fi | {
                eval "$stop_sequence_trimmer"
            } | {
                if test -n "$postprocessor"; then
                    eval "$postprocessor"
                else
                    cat
                fi
            } |
                if test "$DO_PRETTY_PRINT" = y && test -n "$prettifier"; then
                    eval "$prettifier"
                else
                    cat
                fi
    }

    return 0
}

if test "$USE_CONVERSATION_MODE" = y && test "$conversation_mode" = "true"; then
    inputargpos="$(( $# + 1 ))"

    while IFS=$'\n' read -r line; do
        out="$(repl_run "$@" "$line" | awk 1)"
        printf -- "%s\n" "$out"

        prompt+="$out\n$first_stop_sequence\n"
        prompt+="$repeater"
    done
else
    repl_run "$@"
fi
