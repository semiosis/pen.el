#!/bin/bash

# This is fzf but also finds dotfiles

# This is actually a little slow, but it does OK for deeply nested directories
export FZF_DEFAULT_COMMAND="$(cmd ag --hidden --ignore .git -f -g "")"

/usr/bin/fzf "$@"