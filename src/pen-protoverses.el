(define-derived-mode protoverse-description-mode yaml-mode "protoverse"
  "Protoverse description mode")

(add-to-list 'auto-mode-alist '("\\.protoverse\\'" . protoverse-description-mode))

(defvar pen-protoverses (make-hash-table :test 'equal)
  "Protoverses are the seeds of metaverses")

(defvar pen-protoverses-failed '())

(provide 'pen-protoverses)