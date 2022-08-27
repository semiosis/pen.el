#!/usr/bin/env bash

# Don't do this under normal circumstances.
# ( hs "$(basename "$0")" "$@" "#" "<==" "$(ps -o comm= $PPID)" 0</dev/null ) &>/dev/null

# Different pagers may be required by different file types
# But should it matter? No.
# scope should always produces plain text

# This file is old and I should start building a new scope script
# try to utilise this script though.

# ranger supports enhanced previews.  If the option "use_preview_script"
# is set to True and this file exists, this script will be called and its
# output is displayed in ranger.  ANSI color codes are supported.

# NOTES: This script is considered a configuration file.  If you upgrade
# ranger, it will be left untouched. (You must update it yourself.)
# Also, ranger disables STDIN here, so interactive scripts won't work properly

# Meanings of exit codes:
# code | meaning    | action of ranger
# -----+------------+-------------------------------------------
# 0    | success    | success. display stdout as preview
# 1    | no preview | failure. display no preview at all
# 2    | plain text | display the plain content of the file
# 3    | fix width  | success. Don't reload when width changes
# 4    | fix height | success. Don't reload when height changes
# 5    | fix both   | success. Don't ever reload
# 6    | image      | success. display the image $cached points to as an image preview

# exec 2>/dev/null

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    "") { shift; }; ;;
    -t) {
        TEXT_ONLY=y
        shift
    }
    ;;

    *) break;
esac; done

# Meaningful aliases for arguments:
path="$1"    # Full path of the selected file
width="$2"   # Width of the preview pane (number of fitting characters)
height="$3"  # Height of the preview pane (number of fitting characters)
cached="$4"  # Path that should be used to cache image previews

test -f "$path" || exit 1

fp="$path"
fn=$(basename "$fp")
rp="$(realpath "$fp")"
dn=$(dirname "$fp")
ext="${fn##*.}"
mant="${fn%.*}"

export MIRRORD="$HOME/text-mirror"
mirror_path="${MIRRORD}${path}.txt"

if test -p "$fp"; then
    echo "$fp" is a fifo
    exit 0
fi

if ! test "$UPDATE" = y && test -f "$mirror_path" && test -s "$mirror_path"; then
    cat "$mirror_path"
    exit $?
fi

if test -d "$path"; then
    cd "$path"
    ls -g -alR -XGh --group-directories-first
    exit 0
fi

if [ -z "$width" ]; then
    width="$COLUMNS"
    if [ -z "$width" ]; then
        eval `pen-tm-resize`
        LINES=$(tput lines)
        COLUMNS=$(tput cols)

        width="$COLUMNS"
    fi
    maxln=10000    # Stop after $maxln lines.  Can be used like ls | head -n $maxln
else
    maxln=200    # Stop after $maxln lines.  Can be used like ls | head -n $maxln
fi

MIME_TYPE="$(pen-mime "$path")"

extension="$(/usr/bin/printf -- "%s\n" "${path##*.}" | tr "[:upper:]" "[:lower:]")"

is_tty() {
    # If stout is a tty
    [[ -t 1 ]]
}

is_tty && IS_TTY=y

# Functions:
# runs a command and saves its output into $output.  Useful if you need
# the return value AND want to use the output in a pipe
try() {
    output="$(eval '"$@"')";
}

# writes the output of the previously used "try" command
dump() { /usr/bin/printf -- "%s\n" "$output"; }

# a common post-processing function used after most commands
trim() { head -n "$maxln"; }

# This lags when used in search engine
highlight() {
    command cat "$@"
}

bn="$(basename "$fp")"

case "$bn" in
    docker-compose*.yml) {
        echo "plantuml:" | udl
        echo
        cat "$rp" | docker-compose-plantuml --link-graph | awk 1
        echo
        echo
        echo "file contents:" | udl
        echo
        cat "$rp"
        exit 4
    }
    ;;

    *)
esac

case "$extension" in
    ansi) {
        if is_tty; then
            less -rS "$path" && exit 4
        else
            cat "$path" | strip-ansi && exit 4
        fi
    }
    ;;

    conf|org|txt|xsh|cmake|el|ipynb|url|sql) {
        cat "$path" && exit 4
    }
    ;;

    sqlite3) {
        sqlite3-fullschema "$path" && exit 4
    }
    ;;

    # Archive extensions:
    7z|a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
    rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
        try als "$path" && { dump | trim; exit 0; }
        try acat "$path" && { dump | trim; exit 3; }
        try bsdtar -lf "$path" && { dump | trim; exit 0; }
        exit 1;;
    jpg|png) {
        if test -z TEXT_ONLY; then
            pp_name="$(ps -o comm= $PPID)"

            case "$pp_name" in
                python3) {
                    TEXT_ONLY=y
                }
                ;;

            esac
        fi

        if test "$TEXT_ONLY" = "y"; then
            mediainfo "$path" && exit 4
        else
            img2txt --gamma=0.6 --width="$width" "$path"
        fi

        exit 0
        }
        ;;

    json) {
        cat "$path" | jq . || exit 2
        exit 0
    }
    ;;

    mkv)
        try page mkvinfo "$path" && { dump | trim; exit 0; } || exit 1;;
    o)
        try nm "$path" && { dump | trim; exit 0; } || exit 1;;
    rar)
        try unrar -p- lt "$path" && { dump | trim; exit 0; } || exit 1;;
    # PDF documents:
    pdf) {
        try pdftotext -l 10 -nopgbrk -q "$path" - && \
            { dump | trim | fmt -s -w $width; exit 0; } || exit 1
            }
        ;;
    # BitTorrent Files
    torrent)
        try transmission-show "$path" && { dump | trim; exit 5; } || exit 1;;
    # HTML Pages:
    htm|html|xhtml)
        try w3m    -dump "$path" && { dump | trim | fmt -s -w $width; exit 4; }
        try lynx   -dump "$path" && { dump | trim | fmt -s -w $width; exit 4; }
        try elinks -dump "$path" && { dump | trim | fmt -s -w $width; exit 4; }
        ;; # fall back to highlight/cat if the text browsers fail
esac

# ns -f "$MIME_TYPE"

case "$MIME_TYPE" in
    application/*spreadsheet*) {
        excel2csv "$path" | xargs cat | trim || exit 2
    }
    ;;

    */csv|application/*subrip) {
        cat "$path" | trim | head -n 100 || exit 2
    }
    ;;

    *openxmlformats-officedocument*|application/ms-word|application/*powerpoint|application/msword|application/*officedoc*) {
        try doc2txt "$path" && { dump | trim; exit 5; } || exit 2
    }
    ;;

    application/*excel*) {
        excel2csv "$path" | xargs cat | trim || exit 2
    }
    ;;

    */json) {
        cat "$path" | jq . || exit 2
    }
    ;;

    # Syntax highlight for text files:
    text/* | */xml) {
        pen-wc-nice "$path"
        echo
        cat "$path" | trim || exit 2
    }
    ;;

    # Ascii-previews of images:
    image/*) {
        # Do not even try
        exit 1

        if test -z TEXT_ONLY; then
            pp_name="$(ps -o comm= $PPID)"

            case "$pp_name" in
                python3) {
                    TEXT_ONLY=y
                }
                ;;

            esac
        fi

        if test "$TEXT_ONLY" = "y"; then
            mediainfo "$path" && exit 4
        else
            # export TERM=screen-256color; unbuffer timg "$path"
            img2txt --gamma=0.6 --width="$width" "$path"
        fi

        exit 0
    }
    ;;

    # Image preview for videos, disabled by default:
    # video/*)
    #     ffmpegthumbnailer -i "$path" -o "$cached" -s 0 && exit 6 || exit 1;;
    # Display information about media files:
    video/*|audio/*) {
        exiftool "$path" && exit 5
        # Use sed to remove spaces so the output fits into the narrow window
        try mediainfo "$path" && { dump | trim | sed 's/  \+:/: /;';  exit 5; } || exit 1
    }
    ;;

    *) {
        # Don't do this if the file is huge
        strings "$path";
    }
esac

# Not all of the above endpoints have an exit 0 but they should do. That's why this is
# need.
exit $?
