cd /root/.emacs.d/host/pen.el/src;  "sqlite3" "/root/.pen/refs.db" "select \`From Verse\` from refstable" "#" "<==" "pen-ci"
cd /root/.emacs.d/host/pen.el/src;  "sqlite3" "/root/.pen/refs.db" "select \`To Verse\` from refstable where \`From Verse\` = \".3.5\" and \`Votes\` > 0 order by cast(\`Votes\` as unsigned) desc" "#" "<==" "bible-get-cross"
cd /root/.emacs.d/host/pen.el/src;  "sqlite3" "/root/.pen/refs.db" "select \`To Verse\` from refstable where \`From Verse\` = \".3.4\" and \`Votes\` > 0 order by cast(\`Votes\` as unsigned) desc" "#" "<==" "bible-get-cross"
cd /root/.emacs.d/host/pen.el/src;  "sqlite3" "/root/.pen/refs.db" "select \`To Verse\` from refstable where \`From Verse\` = \".3.3\" and \`Votes\` > 0 order by cast(\`Votes\` as unsigned) desc" "#" "<==" "bible-get-cross"
