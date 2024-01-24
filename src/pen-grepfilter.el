;; e:$EMACSD/pen.el/scripts/grepfilter-transform.els

;; Two types of filters
;; - filters ($EMACSD/pen.el/config/filters.sh)
;;   - extract
;;   - transform

(defun grepfilter-transform (input-fp matches-fp bytepos-fp transformed-fp)
  (interactive (list (read-string "Input fp: ")
                     (read-string "Matches fp: ")
                     (read-string "Bytepos fp: ")
                     (read-string "Transformed fp: ")))

  (let* ((input (e/cat input-fp))
         (matches-list
          (-filter-not-empty-string
           (s-lines (e/cat matches-fp))))
         (transformed-list
          (-filter-not-empty-string
           (s-lines (e/cat transformed-fp))))
         (transformation-list
          (-zip matches-list transformed-list))
         (bytepos-list
          ;; I need a temp buffer to recalculate byte positions
          (with-temp-buffer
            (insert input)
            (beginning-of-buffer)

            (mapcar
             (lambda (s)
               (let* ((bytepos (s-replace-regexp "^[^:]+:[0-9]+:\\([0-9]+\\).*" "\\1" s))
                      (matchstr (s-replace-regexp "^[^:]+:[0-9]+:[0-9]+:\\(.*\\).*" "\\1" s))
                      (len (length matchstr)))

                 (list (byte-position (string-to-number bytepos)) len matchstr)))
             (-filter-not-empty-string
              (s-lines (e/cat bytepos-fp))))))

         ;; (temp
         ;;  (tv (pps bytepos-list)))

         ;; Don't use blanked input - it was a bad idea
         ;; instead, simply make the replacements
         ;; and keep a byte offset as I go.
         (transformed-input
          (with-temp-buffer
            (insert input)
            (beginning-of-buffer)
            (let ((offset 0))
              (cl-loop for bytepos in bytepos-list
                       do
                       (let* ((beg (+ offset
                                      ;; byte-position crashes the whole script if its variable is too big for the function
                                      (car bytepos)))
                              (len (car (cdr bytepos)))
                              (end (+ beg len))
                              (substr (buffer-substring beg end))
                              (replacement (cdr (assoc substr transformation-list)))
                              (diff (- (length replacement) len)))

                         (goto-char beg)
                         (delete-region beg end)
                         (insert replacement)

                         (setq offset (+ offset diff)))))
            (buffer-string)))


         (output
          transformed-input
          ))

    output))

(defun grepfilter (transformer extractor)
  (interactive (list
                (select-filter "Extractor:")
                (select-filter "Transformer:")))

  (pen-region-pipe (cmd "grepfilter" transformer extractor)))

(provide 'pen-grepfilter)
