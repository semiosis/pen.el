export TTY

pl() { printf -- "%s\\n" "$@"; }
cmd() {
    for var in "$@"
    do
        if test "$var" = '|'; then
            printf -- "%s" '| '
        else
            printf "'%s' " "$(printf %s "$var" | sed "s/'/'\\\\''/g")";
        fi
    done | sed 's/ $//'
}
ssh() { ( cmd command ssh -o LogLevel=QUIET "$@" | awk 1 1>&2; command ssh -o LogLevel=QUIET "$@"; ) }


stdin_exists() { ! [ -t 0 ] && ! test "$(readlink /proc/$$/fd/0)" = /dev/null; }
is_tty() { [ -t 1 ]; }
pager() { { is_tty && less "$@"; } || cat; }

s_join() {
    delim="$1"
    : "${delim:=" "}"
    paste -s -d "$delim" -
}

free_cs() {

    stty stop undef
    stty start undef
}

isbehind()
{
    vc g is-behind
}

debug_mode_enabled() {
    case "$-" in
        *x*) true;;
        *v*) true;;
        *) false;;
    esac
}

stdout_capture_exists() {

    ! is_tty
}


uniqpath() {
    printf -- "%s\n" "$PATH" | tr ':' '\n' | awk '!seen[$0] {print} {++seen[$0]}' | sed -z "s~\n~:~g" | sed "s/:\$//"
}

pathdirsonly() {
    printf -- "%s\n" "$PATH" | tr ':' '\n' | awk '!seen[$0] {print} {++seen[$0]}' | eipct -E "xargs -l test -d" | sed -z "s~\n~:~g" | sed "s/:\$//"
}

remove_from_path() {
    pattern="$1"
    (
        exec 0</dev/null
        pattern="$(printf -- "%s" "$pattern" | bs /)"

        printf -- "%s\n" "${PATH}" | awk -v RS=: -v ORS=: "/^$pattern$/ {next} {print}" | sed -e 's/^:*//' -e 's/:*$//'
    )

    return 0
}

pathmunge () {
    if [ "$2" = "after" ] ; then
        PATH="$PATH:$1"
    else
        PATH="$1:$PATH"
    fi
}

prepend_to_path() {
    new="$1"


    case ":${PATH:=$new}:" in
        *:$new:*) ;;
        *) PATH="$new:$PATH" ;;
    esac
    printf -- "%s\n" "$PATH"

    return 0
}

append_to_path() {
    new="$1"


    case ":${PATH:=$new}:" in
        *:$new:*) ;;
        *) PATH="$PATH:$new" ;;
    esac
    printf -- "%s\n" "$PATH"

    return 0
}

hasdashes() {
    cmd "$@" | grep -q -P '(^| )--( |$)'
}

before_dashes() {
    eval "set -- $(cmd "$@" | sed -e "s/^-- .*//"  -e "s/ -- .*//" -e "s/ --$//")"
    printf -- "%s" "$(cmd "$@")"

    return 0
}

after_dashes() {
    eval "set -- $(cmd "$@" | sed -e "s/.* -- //" -e "s/.* --$//" -e "s/^-- //")"
    printf -- "%s" "$(cmd "$@")"

    return 0
}