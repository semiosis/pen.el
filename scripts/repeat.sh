#!/bin/bash
export TTY

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    -d) {
        delay="$2"
        shift
        shift
    }
    ;;

    -yn|-ask) {
        do_ask=y
        shift
    }
    ;;

    *) break;
esac; done

CMD="$(cmd-nice "$@")"

check_repeat() {
    if test "$do_ask" = y; then
        echo "$CMD" | mnm | hls blue 1>&2
        yn "Repeat?"
    else
        if [ -n "$delay" ]; then
            sleep "$delay"
        fi
        true
    fi
}

doit() {
    echo "$CMD" | mnm | udl
    eval "$CMD"
}

doit
while check_repeat; do
    doit
done
