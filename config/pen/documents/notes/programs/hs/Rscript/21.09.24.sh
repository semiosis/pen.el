cd /root/repos/REditorSupport/languageserver;  "Rscript" "-e" "install.packages(c('remotes', 'rcmdcheck'), repos = 'https://cloud.r-project.org')" "#" "<==" "zsh"
cd /root/repos/REditorSupport/languageserver;  "Rscript" "-e" "remotes::install_deps(dependencies = TRUE)" "#" "<==" "zsh"
cd /root/repos/REditorSupport/languageserver;  "Rscript" "-e" "install.packages('languageserver', repos = 'https://cloud.r-project.org')" "#" "<==" "r-install-packa"
cd /root/.pen/documents/notes;  "Rscript" "-e" "install.packages('lubridate', repos = 'https://cloud.r-project.org')" "#" "<==" "r-install-packa"
