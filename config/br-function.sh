br_help() {
    IFS= read -r -d '' br_help_text <<HEREDOC
You can combine searches with logical operators.             
For example, to search all toml or rs files containing tomat,
you may type (/toml/|/rs$/)&c/tomat.                         
For efficiency, place content search last.                   
HEREDOC

printf -- "%s\n" "$br_help_text"
}

function br_orig_fun {
    local cmd cmd_file code
    cmd_file=$(mktemp)
    if broot --outcmd "$cmd_file" "$@"; then
        cmd=$(<"$cmd_file")
        rm -f "$cmd_file"
        eval "$cmd"
    else
        code=$?
        rm -f "$cmd_file"
        return "$code"
    fi
}

function br_pen_fun {
    # For the original function, see: /root/.local/share/broot/launcher/bash/1
    # I replace the function to run the script instead.

    while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
        "") { shift; }; ;;

        -2) {
            DO_VT00=y
            shift
        }
        ;;

        -h|--help) {
            DO_PAGER=y
            shift
        }
        ;;

        -e|-ec|--editconf) {
            v /root/.emacs.d/host/pen.el/config/broot-conf.toml
            exit "$?"
        }
        ;;

        *) break;
    esac; done

    export PAGER="nw tless"
    export EDITOR="nw vs"

    if test "$DO_VT00" = "y"; then
        nvc -22 br --color no "$@"
        exit "$?"
    fi

    if test "$DO_PAGER" = "y"; then
        {
            br_help
            echo
            br_orig_fun --help "$@" 
        } | pavs
        return "$?"
    fi

    br_orig_fun "$@"
}

bredit() {
    v $PENEL_DIR/config/br-function.sh
}

alias br='br_pen_fun'
alias vbr='bredit'