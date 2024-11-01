cd /root;  "notmuch" "search" "--format=sexp" "--format-version=5" "--sort=newest-first" "tag:inbox" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=sexp" "--format-version=5" "--decrypt=true" "--exclude=false" "'" "thread:000000000000435b" "and (" "tag:inbox" ")" "'" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=raw" "--part=3" "--decrypt=true" "id:cm.0500073545176.tdlijtdd.npiigjui.r@cmail20.com" "#" "<==" "emacs"
cd /root;  "notmuch" "tag" "--batch" "#" "<==" "emacs"
