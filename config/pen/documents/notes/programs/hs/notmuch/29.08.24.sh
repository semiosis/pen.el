cd /root;  "notmuch" "search" "--format=sexp" "--format-version=5" "--sort=newest-first" "tag:inbox" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=sexp" "--format-version=5" "--decrypt=true" "--exclude=false" "'" "thread:00000000000049b5" "and (" "tag:inbox" ")" "'" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=raw" "--part=3" "--decrypt=true" "id:010f01918b16e5cd-b5be2ee5-91d3-4689-a9ae-afce6eec45e0-000000@us-east-2.amazonses.com" "#" "<==" "emacs"
cd /root;  "notmuch" "tag" "--batch" "#" "<==" "emacs"
