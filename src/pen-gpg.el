(require 'epa-file)
(setq epg-gpg-program (executable-find "gpg2"))

(setenv "GPG_AGENT_INFO" nil)

(provide 'pen-gpg)