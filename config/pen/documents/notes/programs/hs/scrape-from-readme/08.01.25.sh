cd /root/repos/gansm/finalcut;  "scrape-from-readme" "pip install [a-zA-Z_0-9-]+" "#" "<==" "scrape-install-"
cd /root/repos/gansm/finalcut;  "scrape-from-readme" "\\./gradlew :[:a-zA-Z_0-9-]+" "#" "<==" "scrape-install-"
cd /root/repos/gansm/finalcut;  "scrape-from-readme" "gradle [:a-zA-Z_0-9-]+" "#" "<==" "scrape-install-"
cd /root/repos/gansm/finalcut;  "scrape-from-readme" "bazel build [^ ]+" "#" "<==" "scrape-install-"
cd /root/repos/gansm/finalcut;  "scrape-from-readme" "\\bgo get (-u )?[^ ]+" "#" "<==" "scrape-install-"
