#!/bin/bash
export TTY

IFS= read -r -d '' gh <<HEREDOC
Host github.com 
    IdentityFile ~/.ssh/id_rsa
HEREDOC

if ! { test -f ~/.ssh/config && cat ~/.ssh/config | grep -q -P 'Host github.com'; }; then
    pen-x -sh "ssh-keygen -t rsa -N ''" -e Enter -c m -i
    printf -- "%s\n" "$gh" >> ~/.ssh/config
fi
