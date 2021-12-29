#!/bin/bash

# This is fzf but also finds dotfiles

# This is for finding files and directorys max 2 deep

export FZF_DEFAULT_COMMAND="find -L -maxdepth 2 | sed -u 's=^\./=='"
# export FZF_DEFAULT_COMMAND="$(cmd ag --depth 1 --hidden --ignore .git -f -g "")"

/usr/bin/fzf "$@"