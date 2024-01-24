filter-things.sh                                                                    # keep this at the top, so it's the default
filter-org-links
filter-org-links http
xurls | uniqnosort                                                                  # filter urls and strip url parameters
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
rosie grep -o subs net.email                                                        # emails
rosie grep -o subs json.value                                                       # json
rosie-extract-paths
rosie-scrape net.MAC
rosie-scrape date.dashed
rosie-scrape 'findall:{net.any <".com"}'
