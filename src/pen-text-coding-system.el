;; Selecting the coding system when emacs breaks was getting very annoying

(defun select-safe-coding-system-interactively (from to codings unsafe
						                                         &optional rejected default)
  "Select interactively a coding system for the region FROM ... TO.
FROM can be a string, as in `write-region'.
CODINGS is the list of base coding systems known to be safe for this region,
  typically obtained with `find-coding-systems-region'.
UNSAFE is a list of coding systems known to be unsafe for this region.
REJECTED is a list of coding systems which were safe but for some reason
  were not recommended in the particular context.
DEFAULT is the coding system to use by default in the query."
  ;; At first, if some defaults are unsafe, record at most 11
  ;; problematic characters and their positions for them by turning
  ;;	(CODING ...)
  ;; into
  ;;	((CODING (POS . CHAR) (POS . CHAR) ...) ...)
  (if unsafe
      (setq unsafe
	          (mapcar #'(λ (coding)
			                  (cons coding
			                        (if (stringp from)
				                          (mapcar #'(λ (pos)
					                                    (cons pos (aref from pos)))
					                                (unencodable-char-position
					                                 0 (length from) coding
					                                 11 from))
				                        (mapcar #'(λ (pos)
					                                  (cons pos (char-after pos)))
					                              (unencodable-char-position
					                               from to coding 11)))))
		                unsafe)))

  (setq codings (sanitize-coding-system-list codings))

  (let ((window-configuration (selected-window-configuration))
	      (bufname (buffer-name))
	      coding-system)
    (save-excursion
      ;; If some defaults are unsafe, make sure the offending
      ;; buffer is displayed.
      (when (and unsafe (not (stringp from)))
	      (pop-to-buffer bufname)
	      (goto-char (apply #'min (mapcar (λ (x) (or (car (cadr x)) (point-max)))
				                                unsafe))))
      ;; Then ask users to select one from CODINGS while showing
      ;; the reason why none of the defaults are not used.
      (with-output-to-temp-buffer "*Warning*"
	      (with-current-buffer standard-output
	        (if (and (null rejected) (null unsafe))
	            (insert "No default coding systems to try for "
		                  (if (stringp from)
			                    (format "string \"%s\"." from)
			                  (format-message "buffer `%s'." bufname)))
	          (insert
	           "These default coding systems were tried to encode"
	           (if (stringp from)
		             (concat " \"" (if (> (length from) 10)
				                           (concat (substring from 0 10) "...\"")
				                         (concat from "\"")))
	             (format-message " text\nin the buffer `%s'" bufname))
	           ":\n")
	          (let ((pos (point))
		              (fill-prefix "  "))
	            (dolist (x (append rejected unsafe))
		            (princ "  ") (princ x))
	            (insert "\n")
	            (fill-region-as-paragraph pos (point)))
	          (when rejected
	            (insert "These safely encode the text in the buffer,
but are not recommended for encoding text in this context,
e.g., for sending an email message.\n ")
	            (dolist (x rejected)
		            (princ " ") (princ x))
	            (insert "\n"))
	          (when unsafe
	            (insert (if rejected "The other coding systems"
			                  "However, each of them")
		                  (substitute-command-keys
		                   " encountered characters it couldn't encode:\n"))
	            (dolist (coding unsafe)
		            (insert (format "  %s cannot encode these:" (car coding)))
		            (let ((interactive 0)
		                  (func1
		                   #'(λ (bufname pos)
			                     (when (buffer-live-p (get-buffer bufname))
			                       (pop-to-buffer bufname)
			                       (goto-char pos))))
		                  (func2
		                   #'(λ (bufname pos coding)
			                     (when (buffer-live-p (get-buffer bufname))
			                       (pop-to-buffer bufname)
			                       (if (< (point) pos)
				                         (goto-char pos)
			                         (forward-char 1)
			                         (search-unencodable-char coding)
			                         (forward-char -1))))))
		              (dolist (elt (cdr coding))
		                (insert " ")
		                (if (stringp from)
			                  (insert (if (< pen-i 10) (cdr elt) "..."))
		                  (if (< pen-i 10)
			                    (insert-text-button
			                     (cdr elt)
			                     :type 'help-xref
			                     'face 'link
			                     'help-echo
			                     "mouse-2, RET: jump to this character"
			                     'help-function func1
			                     'help-args (list bufname (car elt)))
			                  (insert-text-button
			                   "..."
			                   :type 'help-xref
			                   'face 'link
			                   'help-echo
			                   "mouse-2, RET: next unencodable character"
			                   'help-function func2
			                   'help-args (list bufname (car elt)
					                                (car coding)))))
		                (setq pen-i (1+ i))))
		            (insert "\n"))
	            (insert (substitute-command-keys "\

Click on a character (or switch to this window by `\\[other-window]'\n\
and select the characters by RET) to jump to the place it appears,\n\
where `\\[universal-argument] \\[what-cursor-position]' will give information about it.\n"))))
	        (insert (substitute-command-keys "\nSelect \
one of the safe coding systems listed below,\n\
or cancel the writing with \\[keyboard-quit] and edit the buffer\n\
   to remove or modify the problematic characters,\n\
or specify any other coding system (and risk losing\n\
   the problematic characters).\n\n"))
	        (let ((pos (point))
		            (fill-prefix "  "))
	          (dolist (x codings)
	            (princ "  ") (princ x))
	          (insert "\n")
	          (fill-region-as-paragraph pos (point)))))

      ;; Read a coding system.
      ;; (setq coding-system
	    ;; (read-coding-system (format-prompt "Select coding system" default)
	    ;;                     default))
      (setq coding-system default
	          ;; (read-coding-system (format-prompt "Select coding system" default)
	          ;;                     default)
            )
      (setq last-coding-system-specified coding-system))

    (kill-buffer "*Warning*")
    (set-window-configuration window-configuration)
    coding-system))

(advice-add 'select-safe-coding-system-interactively :around #'ignore-errors-around-advice)

(provide 'pen-text-coding-system)