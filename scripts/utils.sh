#!/bin/bash
export TTY

# Search command line history
# Uses zsh's history or bash's history
alias h="history | paged grep "

# This script should be sourced from other scripts
# It should be very short.
# Have only stdin_exists, is_tty, is_stdout_pipe
# and, sparingly other functions.

# It seems that aliases don't work when sourcing this file
# alias pf='printf --'
# alias pf='printf'

pf() {
    printf "$@"
}

# POSIX-compliant
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

# cmd-nice-posix is a bad function name for posix! I think it needs to be cmd_nice_posix to be truly POSIX
cmd_nice_posix() {
    for var in "$@"
    do
        # A grand test of this is that it's idempotent with myeval
        # myeval cmd-nice "$(cmd-nice "hi ")"

        # Remember that some chars escape differently
        # pl "\$"
        # pl "\)"
        # It might be too hairy to capture all these rules for the moment

        # printf '"%s" ' "$(printf %s "$var" | sed 's/\(\\*\)"/\1\1\\"/g')";

        # TODO Ensure that the first \ to touch the non-" is not doubled?
        # printf %s "$var"
        # sadlly, command substitution removes the trailing newlines
        # printf '"%s" ' "$(printf %s "$var")"
        # printf '"%s" ' "$(printf %s "$var" | sed 's/\(\\\)\([^"]\|$\)/\1\1\2/g' | sed 's/\(\\*\)"/\1\1\\"/g')";

        IFS= read -rd '' quoted < <(printf %s "$var" | sed 's/\(\\\)\([^"]\|$\)/\1\1\2/g' | sed 's/\(\\*\)"/\1\1\\"/g');typeset -p quoted &>/dev/null
        printf '"%s" ' "$quoted";
        # also escape backticks
    done | sed "s_\\([\`]\\)_\\\\\\1_g" | sed 's/ $//'
}

bs() {
    chars="$1"
    : ${chars:=" "}
    chars="$(printf -- "%s" "$chars" | qne)"

    sed "s_\\([$chars]\\)_\\\\\\1_g"
}

inside-docker-p() { test -f /.dockerenv; }
inside-emacs-p() { test -n "$EMACS_TERM_TYPE" || test -n "$INSIDE_EMACS"; }
inside-emacs-comint-p() { printf -- "%s\n" "$INSIDE_EMACS" | grep -q ',comint'; }
inside-tmux-p() { { test -n "$TMUX" || test -n "$PEN_TMUX"; } && tmux-pane-id 2>/dev/null; }
in-pen-p() { inside-docker-p && { test -n "$PEN_USER" || test -f ~/pen_user.txt; } }

pl() {
    printf -- "%s\n" "$@"
}

upd() {
    export UPDATE=y
    "$@"
}

fupd() {
    local FUNCTION_UPDATE=y

    # For example, rerun stdin_exists

    "$@"
}

varexists() {
    [[ -v $1 ]]
    return $?
}

# TODO Make a function_caching system
# which simply uses variables.
# A very lightweight memoisation system
# - No saving to file.
# Sadly, macros are just not a thing in bash.

# . $SCRIPTS/lib/stdin_exists
stdin_exists() {
    test "$FUNCTION_UPDATE" = y && unset hasstdin

    if ! varexists hasstdin; then
        {
        ! [ -t 0 ] && \
        ! test "$NO_STDIN" = y ` # for notty. e.g. notty xt vim ` && \
        ! test "$(readlink /proc/$$/fd/0)" = /dev/null  && \
        ! test "$(readlink /proc/$$/fd/0)" = "$(readlink /proc/$$/fd/1)"
        # stdin may be redirected to the tty, but  will continue to say false (due to a bash bug)
        # So test to make sure 0 does not point to 1
        } &>/dev/null
        hasstdin="$?"
    else
        :
        # echo stdin_exists using cache 1>&2
    fi
    return "$hasstdin"
}
stdin_exists

if test "$hasstdin" = 0; then
    has_stdin=y
fi

is_tty() { [ -t 1 ] && ! test "$TERM" = "dumb"; }
is_tty
istty="$?"

is_tty_stderr() { [ -t 2 ] && ! test "$TERM" = "dumb"; }
is_tty_stderr
istty_stderr="$?"

is_stdout_pipe() { [[ -p /dev/stdout ]]; }
is_stdout_pipe
isstdoutpipe="$?"
ispipe="$isstdoutpipe"

if test "$isstdoutpipe" = 0; then
    has_stdout=y
fi

# is_interactive() { [[ $- == *i* ]]; }
is_interactive() { tty -s; }
isinteractive="$?"

. $PENELD/scripts/debug.sh
