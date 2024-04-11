(require 'wordnut)
(require 'define-it)

(df spv-wordnut () (pen-spv (concat "wu " (pen-selected-text))) (deactivate-mark))

(defun wordnut--lookup (word &optional category sense)
  "If wn prints something to stdout it means the word is
found. Otherwise we run wn again but with its -grepX options. If
that returns nothing or a list of words, prompt for a word, then
rerun `wordnut--lookup' with the selected word."
  (if (or (null word) (string-match "^\s*$" word)) (user-error "Invalid query"))

  (setq word (string-trim word))
  (let ((progress-reporter
         (make-progress-reporter
          (format "WordNet lookup for `%s'... " (wordnut-u-fix-name word)) 0 2))
        result buf item ipoint)

    (setq result (apply 'wordnut--exec word wordnut-cmd-options))
    (progress-reporter-update progress-reporter 1)

    (if (equal "" result)
        (let (sugg)
          (setq sugg (wordnut--suggestions word))
          (setq word (if (listp sugg) (wordnut--completing word) sugg))
          ;; recursion!
          (wordnut--lookup word category sense))
      ;; else
      (if (setq item (wordnut--h-find wordnut-hs word))
          (setq ipoint (cdr (assoc 'point item))))
      (setq item (wordnut--h-item-new word ipoint category sense))
      (wordnut--h-add wordnut-hs item)

      (setq buf (get-buffer-create wordnut-bufname))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert result))
        (wordnut--format-buffer)
        (setq imenu--index-alist nil)   ; flush imenu cache
        (set-buffer-modified-p nil)
        (unless (eq major-mode 'wordnut-mode) (wordnut-mode))
        (wordnut--headerline)
        (wordnut--moveto item))

      (progress-reporter-update progress-reporter 2)
      (progress-reporter-done progress-reporter)
      (pop-to-buffer buf))))

(defun wordnut-lookup-current-word ()
  (interactive)
  (let (inline)
    (ignore-errors
      (wordnut--history-update-cur wordnut-hs))

    (setq inline (wordnut--lexi-link))
    (if inline
        (wordnut--lookup (car inline) (nth 1 inline) (nth 2 inline))
      (wordnut--lookup (current-word)))))

(defun dict-word (word)
  (interactive (list (pen-thing-at-point)))
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (define-it word)
    (wordnut-lookup-current-word)))

(define-key wordnut-mode-map (kbd "M-9") 'dict-word)

(provide 'pen-wordnut)
