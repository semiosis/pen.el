cd /root/notes;  "gpg2" "--with-colons" "--list-config" "#" "<==" "emacs"
cd /root/notes;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--output" "/tmp/epg-outputu7fZCL" "--verify" "--" "/tmp/epg-signatureEU74rC" "-" "#" "<==" "emacs"
