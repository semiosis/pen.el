cd /root/.pen/documents/church-services;  "gpg2" "--with-colons" "--list-config" "#" "<==" "emacs"
cd /root/.pen/documents/church-services;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--import" "--" "/usr/local/share/emacs/29.1.50/etc/package-keyring.gpg" "#" "<==" "emacs"
cd /root/.pen/documents/church-services;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--output" "/tmp/epg-outputAuNVB5" "--verify" "--" "/tmp/epg-signaturerKVMl2" "-" "#" "<==" "emacs"
cd /root/.pen/documents/church-services;  "gpg2" "--no-tty" "--status-fd" "1" "--yes" "--homedir" "/root/.emacs.d/elpa/gnupg" "--command-fd" "0" "--output" "/tmp/epg-outputqedD0D" "--verify" "--" "/tmp/epg-signatureHHfjDO" "-" "#" "<==" "emacs"