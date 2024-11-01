cd /;  "gpg2" "--with-colons" "--list-config" "#" "<==" "emacs"
cd /;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--import" "--" "/usr/local/share/emacs/29.1.50/etc/package-keyring.gpg" "#" "<==" "emacs"
cd /;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--output" "/tmp/epg-outputkeWYH7" "--verify" "--" "/tmp/epg-signature8dQzRg" "-" "#" "<==" "emacs"
cd /;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--output" "/tmp/epg-outputt2hDfI" "--verify" "--" "/tmp/epg-signatureo3gDBl" "-" "#" "<==" "emacs"
