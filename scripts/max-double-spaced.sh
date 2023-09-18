#!/bin/bash
export TTY
# shopt -s nullglob # use for 'for' loops but not for 'ls', 'grep'

sed ':a;N;$!ba;s/\n\n\+/\n\n/g'