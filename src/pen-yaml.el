;; the elisp library is slower and less reliable than the module
(require 'yaml)

;; pen-yq interfaces with yq to generate yaml
;; TODO Use native elisp

;; (yaml2json (cat "$PROMPTS/analogy.prompt"))
;; (etv (json2yaml (yaml2json (cat "$PROMPTS/translate-to.prompt"))))

;; (etv (ht-get (yaml-parse-string "key1: value1\nkey2: value2") 'key1))

(defun yaml-parse-file (fp)
  (yaml-parse-string (cat fp)))

(defun yaml2json (yaml-in)
  (snc "yq ." yaml-in))

(defun json2yaml (json-in)
  (snc "json2yaml" json-in))

(defun plist2yaml (plist)
  (json2yaml (json-encode-plist plist)))

(provide 'pen-yaml)