cd /root/notes;  "cterm-ssh" "-ssh-to-host" "y" "-cwd" "/root/.pen/documents/notes" "-cmd" "tmwr -nopr \"alsamixer\"" "-user" "shane" "#" "<==" "nsfa--pen-cterm"
cd /root/notes;  "cterm-ssh" "-ssh-to-host" "n" "-cwd" "/root/notes/" "-cmd" "tmwr -nopr \"bash\"" "-user" "shane" "#" "<==" "nsfa--pen-cterm"
cd /root/.emacs.d/host/pen.el/scripts;  "cterm-ssh" "-ssh-to-host" "y" "-ssh" "--" "which" "chrome" "#" "<==" "pen-ssh-host"
cd /root/.emacs.d/host/pen.el/scripts;  "cterm-ssh" "-ssh-to-host" "y" "-ssh" "--" "chrome" "https://www.youtube.com/watch?v=V0mQ-GdKoPM" "#" "<==" "pen-ssh-host"
cd /root/.pen/documents/projects/reveal-gospel;  "cterm-ssh" "-ssh-to-host" "y" "-ssh" "--" "hugo" "new" "site" "presentation" "#" "<==" "pen-ssh-host"
cd /root/.pen/documents/projects/reveal-gospel;  "cterm-ssh" "-ssh-to-host" "y" "-ssh" "--" "hugo" "new" "site" "presentation" "#" "<==" "pen-ssh-host"
cd /root/.pen/documents/notes;  "cterm-ssh" "-ssh-to-host" "y" "-ssh" "--" "git" "--version" "#" "<==" "pen-ssh-host"