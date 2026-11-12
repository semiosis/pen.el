#!/bin/bash

# https://www.reddit.com/r/commandline/comments/1xu1x8d/comment/19sibg4v9lrr9/

IFS= read -r -d '' script <<HEREDOC
Computer: Hello again.
Computer: I'm listening.
Computer: YO.
HEREDOC

echo -n "> "
ln=1
while read -r line; do
    (
    echo "$script" | sed -n "${ln}p"
    echo -n "> "
    )
    ln="$(( ln + 1 ))"
done
echo exiting.
