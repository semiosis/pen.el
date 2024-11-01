cd /root/.emacs.d/host/pen.el/docs/theology;  "sqlite3" "--version" "#" "<==" "emacs"
cd /root/.emacs.d/host/pen.el/docs/theology;  "sqlite3" "-interactive" "-init" "/tmp/emacs-esqlite-XQJMAm" "-csv" "-nullvalue" "oNGKjnzWkTna6CWFonq" "/root/bible.db" "#" "<==" "emacs"
cd /root/.emacs.d/host/pen.el/docs/theology;  "sqlite3" "/root/.pen/refs.db" "select \`To Verse\` from refstable where \`From Verse\` = \"1Tim.1.17\" and \`Votes\` > 0 order by cast(\`Votes\` as unsigned) desc" "#" "<==" "bible-get-cross"
