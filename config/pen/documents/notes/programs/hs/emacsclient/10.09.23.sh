cd /root/notes;  "emacsclient" "-a" "" "-t" "-s" "/root/.emacs.d/server/DEFAULT" "-e" "(progn (read-string \"KILL_FRAME\")(kill-frame))" "#" "<==" "pen-emacsclient"
cd /root/notes;  "emacsclient" "-a" "false" "-e" "t" "-s" "/root/.emacs.d/server/DEFAULT" "#" "<==" "pen-e"
cd /root/notes;  "emacsclient" "-a" "false" "-e" "t" "-s" "/root/.emacs.d/server/DEFAULT" "#" "<==" "pen-e"
cd /root/notes;  "emacsclient" "-a" "" "-t" "-s" "/root/.emacs.d/server/DEFAULT" "-e" "(progn (ignore-errors (message (str (frame-terminal)))(funcall-interactively 'bible-open nil nil \"NASB\" \"Deuteronomy 21\")(recenter-top-bottom)(get-buffer-create \"*scratch*\")))" "#" "<==" "pen-e"
