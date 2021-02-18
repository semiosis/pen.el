#!/bin/bash
export TTY

( hs "$(basename "$0")" "$@" "#" "<==" "$(ps -o comm= $PPID)" 0</dev/null ) &>/dev/null

# https://github.com/shawwn/openai-server/blob/master/003_completions.sh

: "${OPENAI_API_KEY:="$(cat $HOME/.myrc.yaml | yq -r '.openai_api_key')"}"; export OPENAI_API_KEY

set -x
# export PORT="${PORT:-9000}"
# export OPENAI_API_BASE="${OPENAI_API_BASE:-http://localhost:${PORT}}"
export OPENAI_API_BASE="${OPENAI_API_BASE:-https://api.openai.com}"
# v +/"OPENAI_LOG = os.environ.get(\"OPENAI_LOG\")" "/media/sdc1$MYGIT/openai/openai-python/openai/util.py"
export OPENAI_LOG="${OPENAI_LOG:-debug}"
set +x

stdin_exists() {
    ! [ -t 0 ] && ! test "$(readlink /proc/$$/fd/0)" = /dev/null
}

stdin_exists || exit 0

# openai api completions.create -h | vs +/"-n N,"
prompt_complete() {
    \
    openai api \
    completions.create \
    -e davinci \
    ` # -t TEMPERATURE, --temperature TEMPERATURE ` \
    -t 0.6 \
    ` # -M MAX_TOKENS, --max-tokens MAX_TOKENS ` \
    -M 32 \
    ` # -n N, --n N           How many sub-completions to generate for each prompt. ` \
    -n 1 \
    -p "$prompt"
}

# take from stdin
prompt="$(cat)"
while true
do
  prompt="$(openai api completions.create -e davinci -t 0.6 -M 32 -n 1 -p "$prompt")"
  printf "\033c"
  #echo '----------'
  echo "$prompt"
done
