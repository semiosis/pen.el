relinkify                                                   # Linkify/Clinkify all urls
unlinkify                                                   # Unlinkify/unclinkify all urls
relinkify-all                                               # Linkify/Clinkify all known links (URL, Biblegateway, etc.)
unlinkify-all                                               # Unlinkify/unclinkify all known links (URL, Biblegateway, etc.)
grepfilter "sed 's/./_/g'" "rosie grep -o subs net.any"     # Blank out IP addresses
grepfilter "sed 's/./_/g'" "xurls"                          # Blank out URLs
biblegateway-relinkify
biblegateway-unlinkify
strongs-codes-relinkify
biblegateway-relinkify-canonicalised
