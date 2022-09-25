(require 'json)

;; Just dont run the json lsp server
(define-derived-mode jsonl-mode json-mode "JSONl"
  "jsonl mode")

(defun json-encode (object)
  "Return a JSON representation of OBJECT as a string.

OBJECT should have a structure like one returned by `json-read'.
If an error is detected during encoding, an error based on
`json-error' is signaled."
  (cond ((eq object t)          (json-encode-keyword object))
        ((eq object json-null)  (json-encode-keyword object))
        ((eq object json-false) (json-encode-keyword object))
        ((stringp object)       (json-encode-string object))
        ((keywordp object)      (json-encode-string
                                 (substring (symbol-name object) 1)))
        ((listp object)         (try (json-encode-list object)
                                     (json-encode-string (str object))))
        ((symbolp object)       (json-encode-string
                                 (symbol-name object)))
        ((numberp object)       (json-encode-number object))
        ((arrayp object)        (json-encode-array object))
        ((hash-table-p object)  (json-encode-hash-table object))
        ;; (t                      (signal 'json-error (list object)))
        (t                      (json-encode-string
                                 (pps object)))))



(provide 'pen-json)
