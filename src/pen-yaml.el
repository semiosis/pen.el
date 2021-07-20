;; pen-yq interfaces with yq to generate yaml
;; TODO Use native elisp

;; (yaml2json (cat "/home/shane/source/git/semiosis/prompts/prompts/analogy.prompt"))

(defun yaml2json (yaml-in)
  (snc "yq ." yaml-in))

(defun json2yaml (json-in)
  (snc "json2yaml" json-in))

(provide 'pen-yaml)