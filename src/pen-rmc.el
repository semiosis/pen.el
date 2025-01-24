(require 'rmc)

(defun read-multiple-choice--short-answers (prompt choices help-string show-help)
  (let* ((dialog-p (use-dialog-box-p))
         (prompt-choices
          (if (or show-help dialog-p) choices (append choices '((?? "?")))))
         (altered-names (mapcar #'rmc--add-key-description prompt-choices))
         (full-prompt
          (format
           "%s (%s): "
           prompt
           (mapconcat (lambda (e) (cdr e)) altered-names ", ")))
         tchar buf wrong-char answer)
    (save-window-excursion
      (save-excursion
        (if show-help
            (setq buf (rmc--show-help prompt help-string show-help
                                      choices altered-names)))
        (while (not tchar)
          (unless dialog-p
            (message "%s%s"
                     (if wrong-char
                         "Invalid choice.  "
                       "")
                     full-prompt))
          (setq tchar
                (if dialog-p
                    (x-popup-dialog
                     t
                     (cons prompt
                           (mapcar
                            (lambda (elem)
                              (cons (capitalize (cadr elem))
                                    (car elem)))
                            prompt-choices)))
                  (condition-case nil
                      (let ((cursor-in-echo-area t))
                        (read-event))
                    (error nil))))
          (setq answer (lookup-key query-replace-map (vector tchar) t))
          (setq tchar
                (cond
                 ((eq answer 'recenter)
                  (recenter) t)
                 ((eq answer 'scroll-up)
                  (ignore-errors (scroll-up-command)) t)
                 ((eq answer 'scroll-down)
                  (ignore-errors (scroll-down-command)) t)
                 ((eq answer 'scroll-other-window)
                  (ignore-errors (scroll-other-window)) t)
                 ((eq answer 'scroll-other-window-down)
                  (ignore-errors (scroll-other-window-down)) t)
                 ((eq answer 'edit)
                  (save-match-data
                    (save-excursion
                      (message "%s"
                               (substitute-command-keys
                                "Recursive edit; type \\[exit-recursive-edit] to return to help screen"))
                      (recursive-edit))))
                 (t tchar)))
          (when (eq tchar t)
            (setq wrong-char nil
                  tchar nil))
          ;; The user has entered an invalid choice, so display the
          ;; help messages.
          (when (and (not (eq tchar nil))
                     (not (assq tchar choices)))
            (setq wrong-char (not (memq tchar `(?? ,help-char)))
                  tchar nil)
            (when wrong-char
              (ding))
            (setq buf (rmc--show-help prompt help-string show-help
                                      choices altered-names))))))
    (when (buffer-live-p buf)
      (kill-buffer buf))
    (assq tchar choices)))

(defun read-multiple-choice--long-answers (prompt choices)
  (let ((answer
         (completing-read
          (concat prompt " ("
                  (mapconcat #'identity (mapcar #'cadr choices) "/")
                  ") ")
          (mapcar #'cadr choices) nil t)))
    (seq-find (lambda (elem)
                (equal (cadr elem) answer))
              choices)))

(defun test-rmc (type)
  (interactive (list (read-string "Type: ")))
  (pcase (car
          (read-multiple-choice
           (format "Suppress `%s' warnings? " type)
           `((?y ,(format "yes, ignore `%s' warnings completely" type))
             (?n "no, just disable showing them")
             (?q "quit and do nothing"))))
    (?y
     nil)
    (?n
     nil)
    (_ (message "Exiting"))))

(provide 'pen-rmc)
