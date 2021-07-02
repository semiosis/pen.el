(require 'tabulated-list)
(require 'tablist)

(defvar pen-prompts-tablist-data-command "oci prompts-details -csv")

(defvar pen-prompts-tablist-meta
  `(pen-prompts-tablist-data-command . ("prompts" t "30 30 20 10 15 15 15 10")))

(provide 'pen-tablist)