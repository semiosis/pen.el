export TTY

# tmux-lib.sh has all the environment variables that tm has
# $HOME/scripts/tm

# This is a library, not an executable script

# tmux pane var
tpv() {
    # Retrieving pane variables is actually the same syntax as getting
    # server options

    TARGET=
    while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
        -t) {
            TARGET="$2"

            shift
            shift
        }
        ;;

        *) break;
    esac; done
    # export TARGET

    if [ -z "$TARGET" ]; then
        TARGET="$CALLER_TARGET"
    fi

    varname="$1"
    tmux display -t "$TARGET" -p "#{$varname}"
    return 0
}

tpwd() {
    TARGET=
    while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
        -t) {
            TARGET="$2"

            shift
            shift
        }
        ;;

        *) break;
    esac; done
    # export TARGET

    if [ -z "$TARGET" ]; then
        TARGET="$CALLER_TARGET"
    fi

    pid="$(tpv -t $TARGET pane_pid)"

    last_pid="$( pstree -Asp $pid | head -n 1 | sed 's/^.*(\([^(]\+\)$/\1/' | sed -n 's/^\([0-9]\+\).*/\1/p')"
    dp="$(realpath /proc/$last_pid/cwd)"
    printf -- "%s" "$dp"
}

shpv() {
    varname="$1"; : ${varname:="pane_start_command"}
    tmux display -t "$CALLER_TARGET" -p "#{$varname}"
    # printf -- "%s\n" 
}

shpvs() {
    while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
        "") { shift; }; ;;
        -t) {
            # pane
            export CALLER_TARGET="$2"
            shift
        }
        ;;

        *) break;
    esac; done

    # out="$(
    for v in \
        pane_id \
        session_name \
        session_id \
        pane_tty \
        pane_width \
        pane_height \
        pane_start_command \
        pane_current_command \
        ; do
        cmd="$(shpv "$v" | s chomp | q)"
        printf -- "%s" "$v: $cmd"
        printf -- "%s\n" 
    done
    # )"
    # lit "$out"
}
