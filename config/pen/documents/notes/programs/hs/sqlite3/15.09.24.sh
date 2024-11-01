cd /;  "sqlite3" "/root/.pen/refs.db" "select \`To Verse\` from refstable where \`From Verse\` = \"Rev.19.11\" and \`Votes\` > 0 order by cast(\`Votes\` as unsigned) desc" "#" "<==" "bible-get-cross"
