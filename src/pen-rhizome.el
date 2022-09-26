;; A database to store prompts and generations

(defun rhizome-last-prompt-data-json ()
  (interactive)

  (let* ((json-pen-last-prompt-data
          ;; Remove everything with no value.
          (-map (lambda (e)
                  (if (not (cdr e))
                      ;; Use the empty string (not ideal)
                      (cons (car e) "")
                    e))
                pen-last-prompt-data))
         (json

          (pen-snc "jq ." (json-encode-alist json-pen-last-prompt-data))))
    (if (interactive-p)
        (tv json :tm_wincmd "nw")
      json)))

(defun rhizome-stash-last-prompt-data ()
  (interactive)

  (rhizome-last-prompt-data-json))

(provide 'pen-rhizome)
