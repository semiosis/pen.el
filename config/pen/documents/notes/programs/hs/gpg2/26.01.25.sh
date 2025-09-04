cd /root/notes;  "gpg2" "--with-colons" "--list-config" "#" "<==" "emacs"
cd /root/notes;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--import" "--" "/usr/local/share/emacs/29.4.50/etc/package-keyring.gpg" "#" "<==" "emacs"
cd /root/notes;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--output" "/tmp/epg-outputwbyzub" "--verify" "--" "/tmp/epg-signaturewg1eTz" "-" "#" "<==" "emacs"
cd /root/notes;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--output" "/tmp/epg-output8UusoR" "--verify" "--" "/tmp/epg-signatureUKWlBq" "-" "#" "<==" "emacs"
