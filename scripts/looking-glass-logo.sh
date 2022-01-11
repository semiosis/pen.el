#!/bin/bash
export TTY

IFS= read -r -d '' logo <<HEREDOC
[38;5;69m  [38;5;33mo o o o o o o o o 
[38;5;33mo       o o        o    Looking Glass
[38;5;33mo   o    o o o o   o 
[38;5;33mo  o o   o o o o   o [38;5;84mo           o o o 
[38;5;33mo   o o  o o o o   o [38;5;84mo [38;5;83mo o o o o o o o o 
[38;5;33mo o o o  o o o o   o [38;5;84mo [38;5;83mo o o o o o o o o 
[38;5;33mo o o o  o o o o   o [38;5;84mo [38;5;83mo o o o o [38;5;119mo [38;5;118mo o o 
[38;5;33mo  o o   o o o o  [38;5;39m o [38;5;84mo           o [38;5;119mo [38;5;118mo 
[38;5;33mo   o    o [38;5;39mo o o   o 
[38;5;33mo     [38;5;39m  o o o o o  o         1.0𝑖
[38;5;33m  o [38;5;39mo o o o o o o o 
HEREDOC

echo
printf -- "%s" "$logo"
echo