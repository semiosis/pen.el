(use-package orthodox-christian-new-calendar-holidays :ensure t)

(require 'diary-lib)

(setq diary-file (umn "~/.pen/diary"))
(f-touch diary-file)

(defun diary-edit ()
  (interactive)
  (e diary-file))

(provide 'pen-calendar-diary)
