# run docker with volume

# resolvepath of directory

docker run -v $HOME/.pen:/root/.pen -v $MYGIT/semiosis/prompts :/root/.emacs.d/host/prompts -v pen.el:/root/.emacs.d/host/pen.el -ti --entrypoint= semiosis/pen.el:latest ./run.sh 'docker' 'run' '-v' '$HOME/.pen:/root/.pen' '-v' '$HOME e$MYGIT/semiosis/prompts:/ro ot/.emacs.d/host/prompts' '-v' 'pen.el:/root/.emacs.d/host/pen.el' '-ti' '-- entrypoint=' 'semiosis/pen.el:latest' './run.sh'

test -d "prompts" && : "${PROMPTS_DIR:="prompts"}"

if (Test-Path -Path $Folder) {
    "Path exists!"
} else {
    "Path doesn't exist."
}

# test -d "$MYGIT/semiosis/pen.el" && : "${PENEL_DIR:="$MYGIT/semiosis/pen.el"}"
test -d "pen.el" && : "${PENEL_DIR:="pen.el"}"
# : "${PENEL_DIR:="$(read -ep "PENEL_DIR (leave empty to use docker): ")"}"

test -d "$HOME/.pen" && : "${PEN_CONFIG_DIR:="$HOME/.pen"}"
: "${PEN_CONFIG_DIR:="$(read -ep "PEN_CONFIG_DIR (leave empty to use docker): ")"}"

# yn "Pull docker image?" && docker pull semiosis/pen.el:latest

set -v
docker pull semiosis/pen.el:latest

if test -d "$PROMPTS_DIR"; then
    yn "Pull prompts repo?" && (
        cd "$PROMPTS_DIR"
        git pull origin master
    )
else
    yn "Clone prompts repo here?" && (
        git clone "http://github.com/semiosis/prompts"
    )
fi

test -d "prompts" && : "${PROMPTS_DIR:="prompts"}"

test -d "$PENEL_DIR" && yn "Pull pen.el repo?" && (
    cd "$PENEL_DIR"
    git pull origin master
)

if test -d "$PROMPTS_DIR"; then
    PROMPTS_DIR="$(realpath "$PROMPTS_DIR")"
fi

if test -d "$PEN_CONFIG_DIR"; then
    PEN_CONFIG_DIR="$(realpath "$PEN_CONFIG_DIR")"
fi

IFS= read -r -d '' shcode <<HEREDOC
    cmd docker run \
        $(test -n "$OPENAI_API_KEY" && printf -- "%s " -e "OPENAI_API_KEY:$OPENAI_API_KEY" ) \
        $(test -n "$PEN_CONFIG_DIR" && printf -- "%s " -v "$PEN_CONFIG_DIR:/root/.pen" ) \
        $(test -n "$PROMPTS_DIR" && printf -- "%s " -v "$PROMPTS_DIR:/root/.emacs.d/host/prompts" ) \
        $(test -n "$PENEL_DIR" && printf -- "%s " -v "$PENEL_DIR:/root/.emacs.d/host/pen.el" ) \
        -ti --entrypoint= semiosis/pen.el:latest ./run.sh
HEREDOC

eval "$shcode"