#!/bin/zsh
export TTY

ids() {
    tmux lsp -a -F '#{session_id}:#{window_id}.#{pane_id}'
    return 0
}

names() {
    tmux lsp -a -F '#{session_name}:#{window_name}.#{pane_index}'
    return 0
}

# :|paste -d',' =(names) - | paste -d' ' - =(ids)

:|paste -d'\t' =(names) - =(ids) | {
if [ -n "$1" ]; then
    sed -n "/^$1[_:]/p"
else
    cat
fi
}
