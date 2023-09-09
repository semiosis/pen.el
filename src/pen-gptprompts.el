;; Discover prompts from gptprompts.org
;; https://gptprompts.org/prompts?format=json

(require 'json)

(defun pen-json-string-parser (json-string)
  (json-parse-string json-string
                     :object-type 'alist :array-type 'list
                     :null-object nil :false-object nil))

(defun company-suggest--wiktionary-candidates (callback prefix)
  "Return a list of Wiktionary suggestions matching PREFIX."
  (url-retrieve (format company-suggest-wiktionary-url (url-encode-url prefix))
                (λ (status)
                  (when-let ((err (plist-get status :error)))
                    (error "Error retrieving: %s: %s" (url-encode-url prefix) err))
                  (when (re-search-forward "^$")
                    (let ((json-array-type 'list)
                          (json-object-type 'hash-table)
                          (json-key-type 'string)
                          (result-string (decode-coding-string (buffer-substring-no-properties (point) (point-max)) 'utf-8)))
                      ;; FIXME: Error checking
                      (funcall callback (cadr (funcall pen-json-string-parser result-string))))))
                nil t))

(defun pen-gptprompts-list-prompts ()
  ;; url-found-p
  ;; TODO Add pagination
  ;; https://gptprompts.org/prompts?page=1&format=json
  (ecurl "https://gptprompts.org/prompts?format=json"))

(defun pen-json-test ()
  (let ((json-array-type 'list)
        (json-object-type 'hash-table)
        (json-key-type 'string)
        (result-string (decode-coding-string (buffer-substring-no-properties (point) (point-max)) 'utf-8)))
    (pen-json-string-parser (pen-gptprompts-list-prompts))))

(provide 'pen-gptprompts)