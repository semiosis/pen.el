;; pen-yq interfaces with yq to generate yaml
;; TODO Use native elisp

(defun yaml2json (yaml-in)
  (snc "yq ." yaml-in))

(defun json2yaml (json-in)
  (snc "json2yaml" json-in))

(provide 'pen-yaml)