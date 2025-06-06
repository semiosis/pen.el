sttr
q -ftln                                                                             # quote ftln, lines
uq -ftln                                                                            # unquote ftln, lines
q                                                                                   # quote
qne                                                                                 # quote no outside quotes
uq                                                                                  # unquote
urlencode                                                                           # first argument only
urldecode                                                                           # first argument only
org clink
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
hash-crc32
crc-lines
org-quote-lines  # Puts each line in an org quotation
