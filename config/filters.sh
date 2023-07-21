filter-things.sh                                                                    # keep this at the top, so it's the default
f-irc
sttr
q -ftln                                                                             # quote ftln                                                                                                 # lines
uq -ftln                                                                            # unquote ftln
q                                                                                   # quote
qne                                                                                 # quote no outside quotes
uq                                                                                  # unquote
urlencode                                                                           # first argument only
urldecode                                                                           # first argument only
pen-scrape "[^\"<>]+" | xurls | uniqnosort
sed "s/\\(\\]\\]\\)/\\1\\n/" | sed -n "s/^.*\\(\\[\\[.*\\]\\]\\).*$/\\1/p"          # filter org links
cat-urls.sh
xurls | uniqnosort                                                                  # filter urls and strip url parameters
org clink
get-1-grams.sh
sed "s/\\s\\+/\\n/g" | sed '/^$/d'                                                  # split by whitespace
extract-queries-from-google-url-contained.sh
dedup-prefixes
minimise.sh
unminimise.sh
cat
pen-scrape | sed '/^$/d'
pen-scrape "\\w+" | sed '/^$/d'
pen-scrape "\\w+" | sort | uniq | sed '/^$/d'                                           # words sorted uniquely
pen-scrape "\\w+" | sort | sed '/^$/d'                                                  # words sorted, just words (non-u)
pen-scrape '[^ ]+' | sed '/^$/d'                                                        # full words - split by whitespace
path-candidates.sh | print-line-if-path-exists.sh | uniqnosort                      # filter partial paths files
path-candidates.sh | print-line-if-which.sh | uniqnosort                            # filter partial which
path-candidates.sh | print-line-if-locate.sh | uniqnosort                           # filter partial locate
print-line-if-which.sh                                                              # filter which
pen-scrape "\\d+" | sed '/^$/d'                                                         # digits
pen-scrape "\\d+" | sort | uniq | sed '/^$/d'                                           # digits sorted unique
pen-scrape '[A-Z_][A-Z_]+' | sed '/^$/d'                                                # capital words
pen-scrape '[a-zA-Z]+' | sed '/^$/d'                                                    # alphabetical
pen-scrape '[a-zA-Z0-9]+' | sed '/^$/d'                                                 # alphanumeric
pen-scrape '[a-zA-Z0-9_]+' | sed '/^$/d'                                                # word chars alphanumeric underscore
pen-scrape '[a-zA-Z0-9-]+' | sed '/^$/d'                                                # word chars alphanumeric dash
word-chars-alphanumeric-dash-underscore-dash.sh
pen-scrape '[0-9.]+' | sed '/^$/d'                                                      # float
split-by-non-paths.sh
sort                                                                                # simple only
sort -d                                                                             # dictionary alphanumeric only
sort -h                                                                             # human simple only
uniq                                                                                # simple only
sort | uniq                                                                         # simple
uniqnosort                                                                          # nosort uniq unchanged
uniqnosort-reverse.sh                                                               # nosort uniq reverse unchanged
remove-comment-lines-after-first-line.sh
sed "2,${/^\\x23/d}"                                                                # remove comment lines after first line
sed -n "1p;2,${/^[^\\x23]/p}"
sed "s/\\$/\\\\\\$/g"                                                               # escape dollar
sed '/^$/d'                                                                         # remove empty lines
remove-leading-and-trailing-spaces.sh
first-column-field-1-space                                                          # first   column field 1 space
remove-leading-and-trailing-spaces.sh | print-field.sh -d "[\\t ]*" 2               # second  column field 2 space
remove-leading-and-trailing-spaces.sh | print-field.sh -d "[\\t ]*" 3               # third   column field 3 space
remove-leading-and-trailing-spaces.sh | print-field.sh -d "[\\t ]*" 4               # fourth  column field 4 space
remove-leading-and-trailing-spaces.sh | print-field.sh -d "[\\t ]*" 5               # fifth   column field 5 space
remove-leading-and-trailing-spaces.sh | print-field.sh -d "[\\t ]*" 6               # sixth   column field 6 space
remove-leading-and-trailing-spaces.sh | print-field.sh -d "[\\t ]*" 7               # seventh column field 7 space
remove-leading-and-trailing-spaces.sh | print-field.sh -d ' ' 1                     # first   column field 1 one space
remove-leading-and-trailing-spaces.sh | print-field.sh -d ' ' 2                     # second  column field 2 one space
remove-leading-and-trailing-spaces.sh | print-field.sh -d ' ' 3                     # third   column field 3 one space
remove-leading-and-trailing-spaces.sh | print-field.sh -d ' ' 4                     # fourth  column field 4 one space
remove-leading-and-trailing-spaces.sh | print-field.sh -d ' ' 5                     # fifth   column field 5 one space
remove-leading-and-trailing-spaces.sh | print-field.sh -d ' ' 6                     # sixth   column field 6 one space
remove-leading-and-trailing-spaces.sh | print-field.sh -d ' ' 7                     # seventh column field 7 one space
remove-leading-and-trailing-spaces.sh | print-field.sh -d ',' 1                     # first   column field 1 commas
remove-leading-and-trailing-spaces.sh | print-field.sh -d ',' 2                     # second  column field 2 commas
remove-leading-and-trailing-spaces.sh | print-field.sh -d ',' 3                     # third   column field 3 commas
remove-leading-and-trailing-spaces.sh | print-field.sh -d ',' 4                     # fourth  column field 4 commas
remove-leading-and-trailing-spaces.sh | print-field.sh -d ',' 5                     # fifth   column field 5 commas
remove-leading-and-trailing-spaces.sh | print-field.sh -d ',' 6                     # sixth   column field 6 commas
remove-leading-and-trailing-spaces.sh | print-field.sh -d ',' 7                     # seventh column field 7 commas
remove-leading-and-trailing-spaces.sh | print-field.sh -d " *\\t *" 1               # first   column field 1 tabs
remove-leading-and-trailing-spaces.sh | print-field.sh -d " *\\t *" 2               # second  column field 2 tabs
remove-leading-and-trailing-spaces.sh | print-field.sh -d " *\\t *" 3               # third   column field 3 tabs
remove-leading-and-trailing-spaces.sh | print-field.sh -d " *\\t *" 4               # fourth  column field 4 tabs
remove-leading-and-trailing-spaces.sh | print-field.sh -d " *\\t *" 5               # fifth   column field 5 tabs
remove-leading-and-trailing-spaces.sh | print-field.sh -d " *\\t *" 6               # sixth   column field 6 tabs
remove-leading-and-trailing-spaces.sh | print-field.sh -d " *\\t *" 7               # seventh column field 7 tabs
htmlentities-decode.sh                                                              # decode htmlentities
remove-first-field-print-result.sh ' '
print-line-if-file-exists.sh
print-line-if-path-exists.sh
print-line-if-directory-exists.sh
erase-starting-whitespace                                                           # remove leading whitespace for each line
clean                                                                               # remove leading whitespace for each line
erase-trailing-whitespace                                                           # tail for each line
ew                                                                                  # erase leading and trailing whitespace for each line
remove-starting-and-trailing-whitespace.sh                                          # erase leading and trailing whitespace for each line
sed '/./,$!d'                                                                       # Delete all leading blank lines at top of file (only).
sed -e :a -e "/^\\n*$/{$d;N;};/\\n$/ba"                                             # Delete all trailing blank lines at end of file (only).
sed -e :a -e "/./,$!d;/^\\n*$/{$d;N;};/\\n$/ba"                                     # Delete leading and trailing newlines
remove-leading-and-trailing-newlines.sh
f-efw | remove-leading-and-trailing-newlines.sh                                     # remove all leading and trailing starting and ending whitespace (no chomp)
efs                                                                                 # remove all leading and trailing starting and ending whitespace and chomp
sed "/\\/\\.git\\//d"                                                               # no git
delete-up-to.sh ,
delete-up-to.sh |
delete-up-to.sh ;
delete-up-to.sh ,
unminimise.sh | split-by-non-paths.sh | exact-paths-only.sh                         # paths only
quote.pl
unquote.pl
uq                                                                                  # unquote
asciionly
remove-hash-comments.sh
sed "s/\\s*\\(\\x23.*\\)$/ \\1/"                                                    # remove spaces before hash
( wd="$(pwd)" 0<&-; umn | sed 's/^'$(echo -n -E "$wd" | sedhex)'//' )               # remove leading working directory
pad-lines-equal-length.sh
scrape-file-dirs.sh                                                                 # fn2dn, show dirnames / directories
scrape-files.sh
filter-files-media-only
scrape-files-fast.sh
scrape-dirs.sh
scrape-dirs-fast.sh
scrape-paths-fast.sh
fn2dn                                                                               # u drn
u drn                                                                               # fn2dn
filter-get-git-dirs.sh                                                              # get top level git dir per file/folder path
cut -c -80 -                                                                        # truncate lines to first 80 characters
cut -c 1-10                                                                         # truncate lines to first 10 characters
cut -c 1-6 -                                                                        # truncate lines to first 6 characters
sed -n "/\\bagi\\b/p"
sed "s/\\([0-9]\\+\\)\\([^[0-9]*\\)\\([0-9]\\+\\)/\\3\\2\\1/"                       # swap fg and bg decimal
sed -z 's/^\n\+//'                                                                  # remove starting newlines
sed -z 's/^\s\+//'                                                                  # remove starting whitespace lines
sed -z 's/\n\+$//'                                                                  # remove trailing newlines
sed -z 's/\s\+$//'                                                                  # remove trailing whitespace lines
awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2-                            # sort by line length / length of lines
awk '{ print length, $0 }' | sort -n | cut -d" " -f2-                               # sort by line length / length of lines and subsort equal alphabetically
udl -u                                                                              # underline and capitalize
tac                                                                                 # reverse lines order
xargs -l1 basename
bc                                                                                  # arbitrary precision calculator
pen-scrape '[a-zA-Z0-9-_]+' | sed '/^$/d' | filter-rtc-issue-ids.sh
pen-scrape '[a-zA-Z0-9-_]+' | sed '/^$/d' | filter-nbo-issue-ids.sh
pen-scrape '[a-zA-Z0-9-_]+' | sed '/^$/d' | filter-jira-issue-ids.sh
xargs -l1 ca                                                                        # cat anything
xargs -l1 ia                                                                        # info anything
xargs-l1-header.sh scope.sh                                                         # scope.sh anything
expand -t8                                                                          # expand tabs
sort -nr                                                                            # sort numerically
sort -k1 -nr                                                                        # sort first column numerically
tr '[:lower:]' '[:upper:]'                                                          # uppercase capitalize all caps
s capitalize                                                                        # uppercase capitalize first letter of each word
s capitalize-sentences                                                              # uppercase capitalize first letter of first word
s lowercase-capitalize # lcap
tr '[:upper:]' '[:lower:]'                                                          # lowercase insensitive
awk '{print tolower($0)}')                                                          # lowercase
sed 's/.*/\L&/'                                                                     # GNU sed lowercase
sed 's/^/\t/'                                                                       # indent
sed 's/\/$//'                                                                       # strip trailing directory slash
umn | dirs-only.sh | mnm                                                            # directories only
umn | files-only.sh | mnm                                                           # files only
bash -s                                                                             # execute line of code in bash
sed -n '/^[A-Za-z0-9_-]\+/p' | xargs -l1 sdcv                                       # get definitions for words
dos2unix.py
sum-column.sh -d , -f 4                                                             # fourth column comma
sum-column.sh -d \t -f 4                                                            # fourth column tab
sed 1d                                                                              # remove first line
sed 1,2d                                                                            # remove first 2 lines
head -n -1                                                                          # remove last line
head -n -2                                                                          # remove last 2 lines
dos2unix.sh
path-candidates.sh | print-line-if-path-exists.sh | sed -n '/\.\(bas\|cls\|frm\)/p' # vb files only
consecutive-combinations.py
wrl-get-extensions.sh
wrl-get-mantissa.sh
awk1 | while IFS=$'\n' read -r line; do printf -- "%s\n" "${line%.*}"; done         # remove extensions
sed 's/\(\([0-9]\.\)*[0-9]\+\)/"\1"/g'                                              # quote numbers digits
python -c "import urllib, sys ; print urllib.quote_plus(sys.stdin.read())"          # url safe string
urlsafe
python -c "import sys; print [line for line in sys.stdin]"
htmlentities-encode.sh
slugify
pen-strip-ansi                                                                          # ansi strip
sed 's/[^0-9a-zA-Z]\+/ /g'                                                          # split/show words on line. non-alphanumeric to whitespace
sed 'a\\'                                                                           # Double space
awk '{print; print "";}'                                                            # Double space
sed G                                                                               # Double space
sed '/^$/d;G'                                                                       # Double space but no more
sed 'n;d'                                                                           # Undo double spacing
sed 'G;G'                                                                           # Triple space
sed '/regex/{x;p;x;}'                                                               # insert blank line above matching
sed '/regex/G'                                                                      # insert blank line below matching
sed '/regex/{x;p;x;G;}'                                                             # insert blank line above and below matching
sed '$!N;s/\n/ /'                                                                   # join pairs of lines side-by-side. emulates paste. zip alternate lines
zip-alternate-lines
sed -e :a -e '/\\$/N; s/\\\n//; ta'                                                 # join lines ending in slash. line continuation character
sed -n '/regexp/{g;1!p;};h'                                                         # print the line before the match
sed -n '1~2p'                                                                       # print every odd line
sed -n '2~2p'                                                                       # print every even line
sed '0~2 a\\'                                                                       # Add line after every 2nd line
awk ' {print;} NR % 2 == 0 { print ""; }'                                           # Add line after every 2nd line
awk 'NR%2'                                                                          # print every 2nd line
awk 'NR%10==0'                                                                      # print every 10th line
sed 's/\s\s\+/\n/g' | sed '/^$/d' | sed -n '/[a-zA-Z0-9]/p'                         # split by long adjacent/long/multi-whitespace get meaningful lines. alphanumeric sequences
sed 's/[^0-9a-zA-Z ]\+//g'                                                          # strip non-alphanumeric
sort-by-occurence.sh _                                                              # sort tmux sessions by depth
sort-by-occurence.sh /                                                              # sort paths by depth
sort-by-line-length
perl -e 'print sort { length($b) <=> length($a) } <>'                               # sort by line length
s indent 1
s indent 2
s indent 5
s rs 2                                                                              # duplicate 2. repeat input. twice
s rs 5                                                                              # duplicate 5. repeat input five times
apply-oneliner-snippets.sh
pen-str onelineify
pen-str onelineify-safe
pen-str unonelineify
pen-str unonelineify-safe
ruby -ne 'print $stdin.eof ? $_.strip : $_'                                         # chomp last line of stdin remove final newline
s chomp                                                                             # chomp last line of stdin remove final newline
transpose-words.sh                                                                  # swap rows and columns by words
datamash transpose                                                                  # swap rows and columns by words
datamash rmdup 1 2> /dev/null                                                       # Remove duplicates rows according to the 1st first column
datamash rmdup 2 2> /dev/null                                                       # Remove duplicates rows according to the 2nd second column
datamash base64 1 2> /dev/null                                                      # Base64 of 1st first column
datamash md5 1 2>/dev/null                                                          # md5 of 1st first column
datamash base64 2 2> /dev/null                                                      # Base64 of 2nd second column
datamash md5 2 2> /dev/null                                                         # md5 of 2nd second column
transpose-characters.sh                                                             # transpose character columns and rows
py -is "list_of_lists_to_text(T(o(tf(i()))))"                                       # transpose character columns and rows
datamash reverse                                                                    # reverse field order
tac | datamash reverse | datamash transpose                                         # reverse word field and column order
buffer -s 2k                                                                        # buffer output in 2 kilobyte chunks to make reading easy. easy read stream
haskell-translate.hs
problog-translate.hs
awk '{print $NF}'                                                                   # last field
cat -n                                                                              # enumerate. line numbers
awk '{printf("%010d %s\n", NR, $0)}'                                                # enumerate. line numbers
cut-trim-to-screen-width.sh
perl -pe 's/(\d+)/ 1 + $1 /ge'                                                      # increment all numbers by one
perl -00 -e 'print reverse <>'                                                      # reverses paragraphs
perl -0777 -ne 'print "$.: doubled $_\n" while /\b(\w+)\b\s+\b\1\b/gi'              # look for duplicated words in a line
fold -w 80 -s                                                                       # wrap lines to 80 characters
wrap 80                                                                             # joins all text and then wraps
strip-html-tags.py
tr '\n' '\0'                                                                        # replace newline with NUL
awk 1                                                                               # ensure newline. opposite of chomp
awk '{ print $0; system("")}'                                                       # awk 1 with flush; ensure newline. opposite of chomp
awk1                                                                                # awk 1 with flush; ensure newline. opposite of chomp
scrape-files.sh                                                                     # this is like partial path file only
sed -n '$='                                                                         # count lines
sed = | sed 'N;s/\n/\t/'                                                            # number each line using a tab
sed '/^$/N;/\n$/N;//D'                                                              # delete consecutive blank lines except for the first 2
sed '/foo/ s//bar/g'                                                                # faster substitution shorthand
gawk '{printf "%-80s %-s\n", $0, length}'                                           # show line length at the end of each line
mawk '{printf "%-80s %-s\n", $0, length}'                                           # show line length at the end of each line. fast execute. doesn't handle multi-byte
awk NF=NF FS=                                                                       # 1 space between each character. no trailing
gawk NF=NF FPAT=.                                                                   # 1 space between each character. no trailing
awk '{while(a=substr($0,++b,1))printf b-1?FS a:a}'                                  # 1 space between each character. no trailing. posix
parse-csv-with-fields-containing-comma.awk
sed -e ':loop' -e 's/foo//g' -e 't loop'                                            # repeat until unchanged; recursive
sed ':a;s/foo//g;ta'                                                                # repeat until unchanged; recursive
sed -z '$ s/\n$//'                                                                  # chomp
awk "y {print s} {s=\$0;y=1} END {ORS=\"\"; print s}"                               # chomp
sed 's/\r$//'                                                                       # dos to unix
sed 's/$/\r/'                                                                       # unix to dos
awk '{print NR,$0}'                                                                 # number lines
remove-c-cpp-comments.awk
extract-c-cpp-comments.awk                                                          # not finished
nl                                                                                  # number lines
unbuffer -p cat                                                                     # example
timestampify.pl
timestampify-hr.pl                                                                  # Human readable
tsy                                                                                 # timestampify
tsyh                                                                                # timestampify- Human readable
od -cb                                                                              # into octal human readable
u2l                                                                                 # upper case to lower case
sed -e 's/\(.*\)/\L\1/'                                                             # GNU sed upper case to lower case
sed -r 's/\w+/\u&/g'                                                                # GNU sed camel case sentence \u = upper next character of match
perl -pe 's/\e\[?.*?[\@-~]//g'                                                      # strip all ansi codes
perl -pe 's/\e\[[\d;]*m//g;'                                                        # strip ansi color codes
perl -pe 's/echo( -E)?(?\! -n)/write/g'                                             # turn echo or echo -E into write but not echo -n PCRE negative lookahead
racket -e '(for-each displayln (sort (port->lines) string<?))' 	 `                  # sort alphabetically`
colorise.sh
sed 's/ \+/ /g'                                                                     # single space between chars
sed 's/^\s*\(;[^;].*\)$/;\1/'                                                       # remove starting whitespace for single-; lisp comments and add another ;
s summarize                                                                         # summarize with sumy
sed -E -n '/^(.)(.)(.)\3\2\1$/p'                                                    # 6-letter palindromes
sed -e 's/[\x80-\xFF]/ /g'                                                          # convert extended ASCII to spaces
ssdeep-paths.sh
resolve.sh                                                                          # resolve paths
wc -w                                                                               # word count
wc -l                                                                               # line count
wc -m                                                                               # char count
wc -c                                                                               # byte count
wiki-parser.pl
c ascify
awk '!a[$0]++'                                                                      # uniq deduplicate consecutive
sed '$!N; /^\(.*\)\n\1$/!P; D'                                                      # uniq deduplicate consecutive
perl -ne 'print if ! $a{$_}++'                                                      # uniq deduplicate consecutive
perl -lne 's/\s*$//; print if ! $a{$_}++'                                           # remove whitespace and uniq deduplicate consecutive
xargs -l1 sha                                                                       # sha each line
pv -L 3k                                                                            # rate limit 3k per second
mbuffer -m 1024M                                                                    # buffer 1G
pv -pterbTCB 1G                                                                     # bufer 1G with progress
buffer -m 1024M                                                                     # buffer 1G
buffer -m 1M                                                                        # buffer 1M
buffer -m 10M                                                                       # buffer 10M
qs                                                                                  # same as q -tln
qf                                                                                  # same as q -ftln
sed 'a\\' | wrlp fold -w 60 -s                                                      # double space and wrap to 60
filter-cat-urls                                                                     # filters urls from text and then cats the urls
cut -c 3-                                                                           # remove first 2 characters from each line
vim -es '+:wq! /dev/stdout' /dev/stdin | cat                                        # pipe through vim
sed -E 's_(\\+)_\\\1_g'                                                             # add-one-slash-to-each-slash-set
iff-double-then-single-space.sh                                                     # iff DOUBLE space only then single space
max-double-spaced-no-trailing                                                       # max double space line (no trailing whitespace)
max-double-spaced.sh                                                                # max double space line
sed "s/^\\s\\+$//" | sed ':a;N;$!ba;s/\n\n\+/\n\n/g' # max one empty line
f-efw | compact-newlines.sh                                                         # iff DOUBLE space only then single space, then max double space line. compact. compress
compact-newlines.sh                                                                 # Single space max
wrla open-org                                                                       # url2org
vmac "vi\"x0v$p"                                                                    # contents of first pair of double quotes ""
awk "!($3=\"\")"                                                                    # remove column 3
remove-prefix "`pwd`/"
spaces-to-tabs
awk -F '\t' 'BEGIN {OFS="\t"} {$1=$3=""; print $0}'                                 # remove columns 1 and 3
second-to-last-line                                                                 # 2nd / second to last line. sed 'x;$!d'
grep "pattern1\|pattern2                                                            # either pattern on same line. grep OR
lt-agrep 'pattern1;pattern2'                                                        # both patterns on same line. grep AND
grep -P '^(?=.*pattern1)(?=.*pattern2)'                                             # both patterns on same line. grep AND
awk '/pattern1/ && /pattern2/'                                                      # both patterns on same line. grep AND
sed -e '/pattern1/!d' -e '/pattern2/!d'                                             # both patterns on same line. grep AND
perl -pe's|((.)\2*)|$1=~y///c.$2|eg'                                                # run length encoding
f-file-not-contains "NewSharedInformerFactory"
f-file-contains "NewSharedInformerFactory"
sort -n -t . -k3,3 -k2,2 -k1,1                                                      # sort by date
filter-facts
rosie grep -o subs net.ipv4                                                         # ipv4 address
tr "[\"'()]" ' ' | rosie grep -o subs net.email                                     # email address
rosie grep -o subs net.path                                                         # path fragments
scrape-emails
rosie-ips
rosie grep -o subs net.url_common                                                   # urls
rosie grep -o subs all.things                                                       # extract all the things
rosie match all.things                                                              # color highlight anything
rosie-urls
rosie-urls-context
sort-paths
filter-file-paths-by-dos-line-endings
rosie grep -o subs net.email                                                        # emails
rosie grep -o subs json.value                                                       # json
extract-json-lines
xsv table                                                                           # tabularize
cut -c1-25                                                                          # First 25 chars
sort -u -t, -k1,1                                                                   # uniq on the first column (only uniq if a run)
uniq-first-col ,                                                                    # uniq on the first column comma (only uniq if a run)
uniq-first-col "	"                                                               # uniq on the first column tab (only uniq if a run)
grep -P -i "(?<![●○]) (mullikine|libertyprime|shane)"                               # grep me
sed 's/\s\+/ /g'                                                                    # spacify whitespace
path-lasttwo                                                                        # dir slug
awk '{ if ($1 <= 5000) print $0}'                                                   # filter by magnitude of value in first column
pen-scrape '(?<=")[\w]+'                                                                # Filter the selection by selecting only uppercase words that come directly after a double quote.
sed 's/^"\(.*\)"$/\1/'                                                              # remove surrounding quotes
remove-surrounding-quotes
segment-sentences # This keeps the original line breaks
segment-sentences-linewise
tr '[<\[({]' '[>\])}]')"                                                            # caesar cipher
surround "("                                                                        # parentheses
surround-paren-lines
wrlp surround "("                                                                   # parentheses lines
surround "\""                                                                       # quotes
surround "{"                                                                        # braces
surround "{{"                                                                       # moustache template
surround "<"                                                                        # angle bracket
surround "["                                                                        # bracket
wrlp surround "["                                                                   # bracket lines
sed -n '/stored ds /p'
perl -p -e "s/../../g"                                                              # Use perl like sed
perl -p -e "s/([a-z])/\\\\\$1/g"
fel eval 'echo "$(cat) * 3" | bc'                                                   # triple
math-times 1000
human2bytes
bytes2human
scrape-py '\d+'                                                                     # python regex
csvcut -c "1,8"                                                                     # columns 1 and 8 of csv
csvgrep -c 2 -r .                                                                   # csv rows with non-empty column 2
datamash -g 1 count 1                                                               # Like logtop
blank-duplicate-lines                                                               # Like uniqnosort but it instead blanks out lines which have already been seen
blank-uniq-lines                                                                    # Like uniqnosort but also blanks out lines which are unique
scrape-hex-24
pen-scrape '"([^"]+)"' | uq                                                             # Scrape literal
scrape-string "'"                                                                   # scrape single quoted strings contents
scrape-string '"'                                                                   # scrape double quoted strings contents
snake-case2camel-case
spinal-case2snake-case
kebab-case2snake-case
lisp-case2snake-case
dash-case2snake-case
tr -d '\000'                                                                        # Remove null bytes
remove-null-bytes
filter-verbose-facts
visor-timestamps
awk 'NR>2'                                                                          # remove first 2 lines
filter-prs                                                                          # PR URLs
pysplit / ::-1                                                                      # reverse order of split
pysplit / :-1                                                                       # Remove last element
pyslice / -1                                                                        # Last element
pysplit / 3:                                                                        # Remove first 3 elements
awk '{key=$0; getline; print key ", " $0;}'                                         # combine every 2 lines
awk 'match($1, /lexicon/) { print $0; system("")}'                                  # awk filter by match on first column
filter-match-col -f 1 '^lexicon$'                                                   # awk filter by match on first column
jq -R -c 'fromjson?'                                                                # filter json lines. useful to run this before jq, so jq doesn't panic part way through input
jq -R -c 'fromjson? | select(type == "object")'                                     # filter json lines (only objects). useful to run this before jq, so jq doesn't panic part way through input
jq-select level error                                                               # filter json by key and value
aatc -d "	" -f 1 ts2human                                                         # Make first column timestamps human-readable
pyslice / 1::2                                                                      # every odd element
pyslice / 2::2                                                                      # every even element
pen-scrape "[a-zA-Z_-]+: ?[^ ]+"                                                        # key: value pairs                                                                                           # for quickly scraping logs
pen-scrape "\x23([0-9A-Za-z]{6}|[0-9A-Za-z]{3})\b"                                      # hex
sed -n "/^[A-Za-z]/p"                                                               # glossary headings
sed -n "/^\** [A-Za-z]/p"                                                           # org headings
sed -n "/^\x23* [A-Za-z]/p"                                                         # markdown headings
cut -d - -f1-3                                                                      # keep only first 3 parts
pysplit - :-2                                                                       # remove last two parts
jq-filter-regex msg Sorry
aatr -k -R 2 "\n\n" "tr '[:lower:]' '[:upper:]'"                                    # uppercase 2nd paragraph
partsofspeech
wrlp -E "xargs pl | tail -n 1"                                                      # Last argument of each line
lines-to-paras
text-to-paras                                                                       # pretty print a block of english text
sed '${/^$/d;}'                                                                     # remove last empty line
sed -z -n '/reuter/I p'                                                             # sed case insensitive
sed "s/Abstract:/&\n\n/" | text-to-paras                                            # form at abstract
patm -r "\\[\\[\\\$[^\\]]*\\]" umn                                                  # fix org mode links -- unminimise them
space-to-org-table
spaces-to-org-table
tsv2org-table
ftfy                                                                                # fixes text for you https://pypi.org/project/ftfy/
sed "s/\[[0-9]\+\]//g"                                                              # remove wiki href links [1]
ttp                                                                                 # text-to-paras
tabulate
sed "2q;d"                                                                          # 2nd line nth line                                                                                          # faster than -n
python2to3
wrlp yt-search                                                                      # youtube query to url
filter-text-files-only
filter-out-binary
bird2code                                                                           # https://wiki.haskell.org/Literate_programming
gofmt
pylanguagetool
hugo-fix-results
unslugify
hindent
escape-for-yasnippet
bs "\`\$\\\("                                                                       # Escape for yasnippet
esc "\$"                                                                            # yas escape
awk -- "++c%2"                                                                      # Delete every 2nd (even) line
awk -- "c++%2"                                                                      # Delete every 2nd (odd) line
split-pipe-multiline
acronymise
rosie-extract-paths
gen-qdot
grex                                                                                # generate regex
definition-list-to-formatted-definitions.sh
sps siq
sps awkward
sed -u -z 's/[a-z]/\U&/g'                                                           # to uppercase
sed -u -z 's/[a-z]/\U&/g'                                                           # to lowercase
number-lines-between-hashes                                                         # Number lines between hashes
sed 's/ / /g'                                                                       # No invisible whitespace
cut -d ' ' -f2-                                                                     # Remove first word
tr -s " "                                                                           # squeeze max one space
glob-grep "*.*"                                                                     # file paths with extensions
filter-until-unchanged "sed 's/catcat/cat/'"
lines-to-args                                                                       # newline delimited strings to arguments
camel2snake                                                                         # camel case to snake case
grep-output-get-paths
scrape-irc-channels
sed 's/ / /g'                                                                       # nonbsp
edm -m! ":\%s/^/hi/\\<CR>"                                                          # stream through vim macro
edm -m! ":\%s/.*/(\&)"                                                              # Surround with parens
filter-duckling-times
rosie-scrape net.MAC
rosie-scrape date.dashed
jq -R "[.,input]"                                                                   # consecutive pairs to json
rosie-scrape 'findall:{net.any <".com"}'
hash-crc32
crc-lines
throttle-lines 1
throttle-lines 0.2
org-clink-urls-within
org-unclink | org-clink-urls-within
bb -i '(take 2 *input*)'                                                            # clojure filter
bb -i '*input*'                                                                     # clojure token list
org-unclink
translate-to-english
indent4-to-tabs
indent4-to-checklist
melee-translate
url-basename
tail -c +9                                                                          # skip the first 8 bytes
scrape-crontab
sort-by-frequency
snake-case2spinal-case
frangipanni
sed -e "s/\b\(.\)/\l\1/g" # lowercase (uncapitalize) first letter
sed -e "s/\b\(.\)/\u\1/g" # uppercase first letter
sed 's/^- \[\([^]]\+\)\].*/\1/' # markdown link labels
bb -i '*input*' # bb -i '(clojure.string/split-lines *input*)'
paste -s -d' \n' # join every other line
eng2ipa
awk '{ for (i=NF; i>1; i--) printf("%s ",$i); print $1; }' # reverse words of string
s-reverse-words-of-string
translate-shane-to-emacs-common
emacs-convert-symbols-to-pen
snake-case2words
unsnakecase
scrape-bible-references
