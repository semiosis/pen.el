relinkify                                                   # Linkify/Clinkify all urls
relinkify -u                                                # Linkify/Clinkify all urls (update)
unlinkify                                                   # Unlinkify/unclinkify all urls
relinkify-all                                               # Linkify/Clinkify all known links (URL, Biblegateway, etc.)
unlinkify-all                                               # Unlinkify/unclinkify all known links (URL, Biblegateway, etc.)
grepfilter "sed 's/./_/g'" "rosie grep -o subs net.any"     # Blank out IP addresses
grepfilter "sed 's/./_/g'" "xurls"                          # Blank out URLs
biblegateway-relinkify
biblegateway-unlinkify
bible-verse-org-reurlify-atomic                             # biblegateway-relinkify (with one grepfilter, not 2)
strongs-codes-relinkify
strongs-codes-unlinkify
blueletterbible-strongs-codes-relinkify
biblegateway-relinkify-canonicalised
bibleorg-relinkify-canonicalised
expand-bible-references-onelinify
