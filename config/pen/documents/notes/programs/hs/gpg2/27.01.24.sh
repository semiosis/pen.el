cd /usr/local/share/info;  "gpg2" "--with-colons" "--list-config" "#" "<==" "emacs"
cd /usr/local/share/info;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--output" "/tmp/epg-outputLJPtxq" "--verify" "--" "/tmp/epg-signaturewv87ui" "-" "#" "<==" "emacs"
