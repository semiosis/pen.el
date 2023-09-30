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
    } | sed 's/\\n/\n/g'
}
# p() { printf -- "%s" "$@"; }

pl() { printf -- "%s\\n" "$@"; }
# This will break many things. It's not as good as the actual script
# cmd() { printf "%q " "$@"; } # Not POSIX, but desirable
# cmd() { printf "\"%s\" " "$@"; }
cmd() {
    for var in "$@"
    do
        if test "$var" = '|'; then
            printf -- "%s" '| '
        else
            # trailing newlines are removed for arguments. Fix this
            printf "'%s' " "$(printf %s "$var" | sed "s/'/'\\\\''/g")";
        fi
    done | sed 's/ $//'
}
ssh() { ( cmd command ssh -o LogLevel=QUIET "$@" | awk 1 1>&2; command ssh -o LogLevel=QUIET "$@"; ) }

# # This goes into zsh
# sshv() {
#     # Like ssh, except it sources .profile and .bashrc
#     # and provides variadic arguments for the command to be run.
#     # Warning: If relying on remote return codes then keep in mind the precedence
#     # of ssh return codes.
#
#     test "$#" -ge 2 || fail 203 "ssh command failed"
#
#     ssh_target="$1"
#     shift
#
#     while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
#         -E) {
#             CMD="$2"
#             shift; shift
#         }; ;;
#
#         *) break;
#     esac; done
#
#     CMD="$(cmd "$@")"
#
#     # -ic will indeed source ~/.bashrc
#     # shellcheck disable=SC2029
#     ssh "$ssh_target" "bash -ic $(cmd "$CMD")"
# }

stdin_exists() { ! [ -t 0 ] && ! test "$(readlink /proc/$$/fd/0)" = /dev/null; }
is_tty() { [ -t 1 ]; }
pager() { { is_tty && less "$@"; } || cat; }

s_join() {
    delim="$1"
    : "${delim:=" "}"
    paste -s -d "$delim" -
}

free_cs() {
    # This works

    stty stop undef
    stty start undef
}

isbehind()
{
    # Can use to check if a branch is behind origin/master
    vc g is-behind
}

debug_mode_enabled() {
    case "$-" in
        *x*) true;;
        *v*) true;;
        *) false;;
    esac
}

# test -t :: tests if as output stream is a tty
stdout_capture_exists() {
    # WARNING: false positives
    # Could have no tty but nothing listening

    ! is_tty
}

# This breaks sh so .profile won't work on login
# quoted_arguments() {
#     # sh doesn't like this
#
#     CMD=''
#     for (( i = 1; i <= $#; i++ )); do
#         eval ARG=\${$i}
#         CMD="$CMD $(printf -- "%s" "$ARG" | q)"
#     done
#
#     printf -- "%s\n" "$CMD"
#
#     return 0
# }

uniqpath() {
    # uniqnosort
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

#pathmunge () {
#        if ! printf -- "%s" "$PATH" | /bin/grep -Eq "(^|:)$1($|:)" ; then
#           if [ "$2" = "after" ] ; then
#              PATH="$PATH:$1"
#           else
#              PATH="$1:$PATH"
#           fi
#        fi
#}

# I should actually remove and re-add
# It's too bad that this is slow.
#pathmunge () {
#    if [ "$2" = "after" ] ; then
#        PATH="$(remove_from_path "$1"):$1"
#    else
#        PATH="$1:$(remove_from_path "$1")"
#    fi
#}

pathmunge () {
    if [ "$2" = "after" ] ; then
        PATH="$PATH:$1"
    else
        PATH="$1:$PATH"
    fi
}

prepend_to_path() {
    new="$1"

    # PATH="$(printf -- "%s" "$PATH" | /bin/sed "s/:$new://")"
    # PATH="$(printf -- "%s" "$PATH" | /bin/sed "s/:$new\$//")"

    case ":${PATH:=$new}:" in
        *:$new:*) ;;
        *) PATH="$new:$PATH" ;;
    esac
    printf -- "%s\n" "$PATH"

    return 0
}

append_to_path() {
    new="$1"

    # PATH="$(printf -- "%s" "$PATH" | /bin/sed "s/:$new://")"
    # PATH="$(printf -- "%s" "$PATH" | /bin/sed "s/^$new://")"

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