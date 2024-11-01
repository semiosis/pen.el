cd /root;  "notmuch" "search" "--format=sexp" "--format-version=5" "--sort=newest-first" "tag:inbox" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=sexp" "--format-version=5" "--decrypt=true" "--exclude=false" "'" "thread:0000000000003ffb" "and (" "tag:inbox" ")" "'" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=raw" "--part=3" "--decrypt=true" "id:r1EfiH82KIJtJJMmqe0Y4s2NXgE9J9w6O0XGK3hYvy6RpD69L8Hg7xbKeBPY6ugqcCPlsAb-pbOshRMLiMy_EzDtsT3vAci7x_ee5XzTtqV6nF_SoooFO2_QZvg2Bc8nnCplEBQMTPhCxwABAgA=@t1.msgid.quoramail.com" "#" "<==" "emacs"
cd /root;  "notmuch" "tag" "--batch" "#" "<==" "emacs"
