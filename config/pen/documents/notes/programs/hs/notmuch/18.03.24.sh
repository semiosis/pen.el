cd /root;  "notmuch" "search" "--format=sexp" "--format-version=5" "--sort=newest-first" "tag:inbox" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=sexp" "--format-version=5" "--decrypt=true" "--exclude=false" "'" "thread:0000000000003f29" "and (" "tag:inbox" ")" "'" "#" "<==" "emacs"
cd /root;  "notmuch" "show" "--format=raw" "--part=3" "--decrypt=true" "id:0107018e4f1f483d-bd5206f6-1639-45df-9be5-deaee72ce30e-000000@eu-central-1.amazonses.com" "#" "<==" "emacs"
cd /root;  "notmuch" "tag" "--batch" "#" "<==" "emacs"
