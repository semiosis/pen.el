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

(define-key yaml-mode-map (kbd "C-c e") 'yaml-get-value-from-this-file)
(define-key yaml-ts-mode-map (kbd "C-c e") 'yaml-get-value-from-this-file)

(defun sh/yaml-get-value-from-this-file ()
  (interactive)
  (if (and (major-mode-p 'yaml-mode)
           (f-file-p (buffer-file-name)))
      (xc
       (pen-sn
        (concat
         (pen-cmd "yaml-get-value"
                  (buffer-file-name)))))))

;; ."last-prompt-data".PEN_RESULTS

(defun yaml-get-value-from-this-file ()
  (interactive)
  (if (and (or (major-mode-p 'yaml-mode)
               (major-mode-p 'yaml-ts-mode))
           ;; (f-file-p (buffer-file-name))
           )
      (let ((key (fz (pen-sn "yq . | jq-showschema-keys" (buffer-string))
                     nil nil "Key: ")))
        (if (sor key)
            (let ((s (pen-snc (pen-cmd "yq" "-r" (concat key " // empty")) (buffer-string))))
              (with-current-buffer
                  (esps (pen-lm (nbfs s)))
                (if (re-match-p "^\\[.*\\]$" s)
                    (json-mode))
                (mark-whole-buffer)))))))

(provide 'pen-yaml)
