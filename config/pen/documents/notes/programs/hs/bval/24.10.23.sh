cd /root/notes;  "bval" "cat $PENCONF/documents/notes/ws/lists/peniel/promises.org | awk1 | while read line; do
    odn scope.sh \"$line\" | awk 1
done | cif scrape-bible-references -v | {
    sed \"/Exodus 5:6-8/d\" \` # Remove some passages from the website which are extraneous \`
} | cif bible-show-verses \"$CMD\"" "#" "<==" "pen-ci"
cd /root/notes;  "bval" "cat $PENCONF/documents/notes/ws/lists/peniel/promises.org | awk1 | while read line; do
    odn scope.sh \"$line\" | awk 1
done | cif scrape-bible-references -v | {
    sed \"/Exodus 5:6-8/d\" \` # Remove some passages from the website which are extraneous \`
} | cif bible-show-verses \"$CMD\"" "#" "<==" "pen-ci"
cd /root/notes;  "bval" "cat $PENCONF/documents/notes/ws/lists/peniel/promises.org | awk1 | while read line; do
    odn scope.sh \"$line\" | awk 1
done | cif scrape-bible-references -v | {
    sed \"/Exodus 5:6-8/d\" \` # Remove some passages from the website which are extraneous \`
} | cif bible-show-verses \"$CMD\"" "#" "<==" "pen-ci"
