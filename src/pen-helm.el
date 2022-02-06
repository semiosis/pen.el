(require 'helm-buffers)

(defun fz-default-return-query (list &optional prompt)
  (setq prompt (or prompt ":"))
  (helm-comp-read prompt list :must-match 'nil))

(defalias 'pen-helm 'fz-default-return-query)

(provide 'pen-helm)