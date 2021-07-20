;; pen-yq interfaces with yq to generate yaml
;; TODO Use native elisp

(defun json2yaml (json-in)
  (snc "json2yaml" json-in))

(provide 'pen-yq)