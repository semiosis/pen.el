#!/bin/bash

# Example of usage:
# openai-complete.sh translate-to.prompt French Goodnight
# or:
# echo French | openai-complete.sh translate-to.prompt Goodnight

sn="$(basename "$0")"

yq() {
    command yq "$@" 2>/dev/null
}

stdin_exists() {
    ! [ -t 0 ] && ! test "$(readlink /proc/$$/fd/0)" = /dev/null
}

# TODO Ensure these are properly escaped, but efficiently
get_stop_sequences() {
    yq -r "(.\"stop-sequences\"[] |= @base64) .\"stop-sequences\"[] // empty" | awk 1 | base64 -d
}

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    "") { shift; }; ;;
    -cmode) {
        # This will create a readline REPL
        USE_CONVERSATION_MODE=y
        shift
    }
    ;;

    -nc) {
        NOCACHE=y
        shift
    }
    ;;

    -pp) {
        PRETTY_PRINT=y
        shift
    }
    ;;

    -s) {
        silence=y
          shift
    }
    ;;

    *) break;
esac; done

export PRETTY_PRINT

: "${NOCACHE:="n"}"

if test -n "$1"; then
    prompt_fp="$1"
    shift
fi

if stdin_exists; then
    # The stdin can be the first argument
    set -- "$@" "$(cat | pen-chomp)"
fi

if ! pl "$prompt_fp" | grep -q -P '\.prompt$'; then
    prompt_fp="${prompt_fp}.prompt"
fi

if ! test -f "$prompt_fp"; then
    if test -f "$MYGIT/semiosis/prompts/prompts/$prompt_fp"; then
        cd "$MYGIT/semiosis/prompts/prompts/"
    fi
fi

test -f "$prompt_fp" || exit

# https://stackoverflow.com/questions/44111831/bash-read-multi-line-string-into-multiple-variables

# Can only be a single character, so use something rare
delim="¬"
IFS="$delim" read -r -d$'\1' prompt rlprompt conversation_mode repeater first_stop_sequence haspreprocessors temperature engine preferred_openai_engine max_tokens top_p postprocessor prettifier < <(
cat "$prompt_fp" | yq -r '[.prompt,.rlprompt,."conversation-mode",.repeater,."stop-sequences"[0],.preprocessors[0],.temperature,.engine,."preferred-openai-engine",."max-tokens",."top-p",.postprocessor,.prettifier] | join("'$delim'")')

inputargpos="$(( $# + 1 ))"
repeater="$(p "$repeater" | sed "s/{}/<${inputargpos}>/g")"

if test "$conversation_mode" = "true"; then
    # Turn this into a normal prompt by joining the repeater with the main prompt
    prompt+="$repeater"
fi

haspreprocessors="$(printf -- "%s" "$haspreprocessors" | sed -z 's/^\n$//')"
postprocessor="$(printf -- "%s" "$postprocessor" | sed -z 's/^\n$//')"
prettifier="$(printf -- "%s" "$prettifier" | sed -z 's/^\n$//')"

if test "$engine" = myrc; then
    engine="$(myrc .default_openai_api_engine)"
fi

# The preprocessors must be loaded into memory, not simply used because the conversation-mode input may need preprocessing
if test -n "$haspreprocessors"; then
    # readarray is bash 4
    readarray -t pps < <(cat "$prompt_fp" | yq -r "(.preprocessors[] |= @base64) .preprocessors[] // empty" | awk 1)

    # This is slow. I should use a different language
    eval "set -- $(
    i=1
    for pp in "${pps[@]}"
    do
        pp="$(printf -- "%s" "$pp" | base64 -d)"

        eval val="\$$i"

        if ! test "$pp" = "null"; then
            val="$(printf -- "%s" "$val" | eval "$pp")"
        fi

        printf "'%s' " "$(printf %s "$val" | sed "s/'/'\\\\''/g")";
        i="$((i + 1))"
    done | sed 's/ $//'
    )"
fi

: "${engine:="$(myrc .default_openai_api_engine)"}"

: "${preferred_openai_engine:="davinci"}"
: "${engine:="$preferred_openai_engine"}"
: "${engine:="davinci"}"

# This is OK now because I have 'myeval'
first_stop_sequence="$(printf -- "%s" "$first_stop_sequence" | qne)"

stop_sequences="$(cat "$prompt_fp" | get_stop_sequences 2>/dev/null)"

test -n "$prompt" || exit 0

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    "") { shift; }; ;;
    -e) {
        engine="$2"
        shift
        shift
    }
;;

*) break;
esac; done

: "${engine:="ada"}"
: "${temperature:="0.6"}"
: "${max_tokens:="64"}"

: "${sub_completions:="1"}"

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

    response_fp="$(sh "$shfp" | uq | s pen-chomp | tf txt)"

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
        if ( exec 0</dev/null; cat "$prompt_fp" | yq-test chomp-start; ); then
            sed -z 's/^\n\+//' | sed -z 's/^\s\+//'
        else
            cat
        fi |
            if ( exec 0</dev/null; cat "$prompt_fp" | yq-test chomp-end; ); then
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
                if test "$PRETTY_PRINT" = y && test -n "$prettifier"; then
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