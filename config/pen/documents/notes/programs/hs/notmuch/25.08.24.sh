cd /root;  "notmuch" "search" "--format=sexp" "--format-version=5" "--sort=newest-first" "tag:inbox" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=sexp" "--format-version=5" "--decrypt=true" "--exclude=false" "'" "thread:00000000000049a8" "and (" "tag:inbox" ")" "'" "#" "<==" "emacs"
cd /root;  "notmuch" "tag" "--batch" "#" "<==" "emacs"
