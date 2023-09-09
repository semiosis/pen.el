;; A database to store prompts and generations

(defun retrieve-last-prompt-data ()  
  (let ((s
         (sor
          (pen-sn
           (concat (cmd "cat" (f-join penconfdir "prompt-hist.el"))
                   " | awk 1 | sed -n '$p'")))))
    (if s
        (eval-string s)
      s)))

(defun rhizome-last-prompt-data-json ()
  (interactive)

  (let* ((json-pen-last-prompt-data
          ;; Remove everything with no value.
          (-map (λ (e)
                  (if (not (cdr e))
                      ;; Use the empty string (not ideal)
                      (cons (car e) "")
                    e))
                (or pen-last-prompt-data
                    (sor
                     (pen-sn
                      (concat (cmd "cat" (f-join penconfdir "prompt-hist.el"))
                              " | awk 1 | sed -n '$p'"))))))
         (json

          (pen-snc "jq ." (json-encode-alist json-pen-last-prompt-data))))
    (if (interactive-p)
        (tv json :tm_wincmd "nw")
      json)))

(defun rhizome-stash-last-prompt-data ()
  (interactive)

  (rhizome-last-prompt-data-json))

(provide 'pen-rhizome)
