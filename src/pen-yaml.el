;; The elisp library is slower and less reliable than the module,
;; so don't use it for loading at the moment.
;; I can still use it to save.
(require 'yaml)

;; pen-yq interfaces with yq to generate yaml
;; TODO Use native elisp

;; (yaml2json (cat "$PROMPTS/analogy.prompt"))
;; (pen-etv (json2yaml (yaml2json (cat "$PROMPTS/translate-to.prompt"))))

;; (pen-etv (ht-get (yaml-parse-string "key1: value1\nkey2: value2") 'key1))

;; (defun yaml-parse-file (fp)
;;   (yaml-parse-string (cat fp)))

(defun yaml2json (yaml-in)
  (pen-snc "yq ." yaml-in))

(defun json2yaml (json-in)
  (pen-snc "json2yaml" json-in))

(defun plist2yaml (plist)
  (json2yaml (json-encode-plist plist)))

(defun pen-load-config ()
  (let* ((path (f-join penconfdir "pen.yaml"))
         (yaml-ht (pen-prompt-file-load path))
         (task-ink (ht-get yaml-ht "task")))))

(provide 'pen-yaml)