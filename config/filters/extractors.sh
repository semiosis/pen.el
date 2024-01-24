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
pen-scrape | sed '/^$/d'
pen-scrape "\\w+" | sed '/^$/d'
pen-scrape "\\w+" | sort | uniq | sed '/^$/d'                                           # words sorted uniquely
pen-scrape "\\w+" | sort | sed '/^$/d'                                                  # words sorted, just words (non-u)
pen-scrape '[^ ]+' | sed '/^$/d'                                                        # full words - split by whitespace
pen-scrape "\\d+" | sed '/^$/d'                                                         # digits
pen-scrape "\\d+" | sort | uniq | sed '/^$/d'                                           # digits sorted unique
pen-scrape '[A-Z_][A-Z_]+' | sed '/^$/d'                                                # capital words
pen-scrape '[a-zA-Z]+' | sed '/^$/d'                                                    # alphabetical
pen-scrape '[a-zA-Z0-9]+' | sed '/^$/d'                                                 # alphanumeric
pen-scrape '[a-zA-Z0-9_]+' | sed '/^$/d'                                                # word chars alphanumeric underscore
pen-scrape '[a-zA-Z0-9-]+' | sed '/^$/d'                                                # word chars alphanumeric dash
pen-scrape '[0-9.]+' | sed '/^$/d'                                                      # float
pen-scrape '[a-zA-Z0-9-_]+' | sed '/^$/d' | filter-rtc-issue-ids.sh
pen-scrape '[a-zA-Z0-9-_]+' | sed '/^$/d' | filter-nbo-issue-ids.sh
pen-scrape '[a-zA-Z0-9-_]+' | sed '/^$/d' | filter-jira-issue-ids.sh
