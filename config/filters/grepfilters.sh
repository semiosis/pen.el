unlinkify                                                   # Unlinkify/unclinkify all urls
relinkify                                                   # Linkify/Clinkify all urls
grepfilter "sed 's/./_/g'" "rosie grep -o subs net.any"     # Blank out IP addresses
grepfilter "sed 's/./_/g'" "xurls"                          # Blank out URLs
