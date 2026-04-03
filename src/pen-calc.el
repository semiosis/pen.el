(require 'calc)

(defun calc-full-help ()
  (interactive)
  (tpop-fit-vim-string
   (with-output-to-string
     (princ "GNU Emacs Calculator.\n")
     (princ "  By Dave Gillespie.\n")
     (princ (format "  %s\n\n" emacs-copyright))
     (princ (format-message "Type `h s' for a more detailed summary.\n"))
     (princ (format-message
             "Or type `h i' to read the full Calc manual on-line.\n\n"))
     (princ "Basic keys:\n")
     (let* ((calc-full-help-flag t))
       (mapc (lambda (x)
               (princ (format
                       "  %s\n"
                       (substitute-command-keys x))))
	         (nreverse (cdr (reverse (cdr (calc-help))))))
       (mapc (lambda (prefix)
               (let ((msgs (ignore-errors (funcall prefix))))
                 (if (car msgs)
                     (princ
                      (if (eq (nth 2 msgs) ?v)
                          (format-message
                           "\n`v' or `V' prefix (vector/matrix) keys: \n")
                        (if (nth 2 msgs)
                            (format-message
                             "\n`%c' prefix (%s) keys:\n"
                             (nth 2 msgs)
                             (or (cdr (assq (nth 2 msgs)
                                            calc-help-long-names))
                                 (nth 1 msgs)))
                          (format "\n%s-modified keys:\n"
                                  (capitalize (nth 1 msgs)))))))
                 (mapcar (lambda (x)
                           (princ (format
                                   "  %s\n"
                                   (substitute-command-keys x))))
                         (car msgs))))
	         '(calc-inverse-prefix-help
	           calc-hyperbolic-prefix-help
	           calc-inv-hyp-prefix-help
               calc-option-prefix-help
	           calc-a-prefix-help
	           calc-b-prefix-help
	           calc-c-prefix-help
	           calc-d-prefix-help
	           calc-f-prefix-help
	           calc-g-prefix-help
	           calc-h-prefix-help
	           calc-j-prefix-help
	           calc-k-prefix-help
	           calc-l-prefix-help
	           calc-m-prefix-help
	           calc-r-prefix-help
	           calc-s-prefix-help
	           calc-t-prefix-help
	           calc-u-prefix-help
	           calc-v-prefix-help
	           calc-shift-Y-prefix-help
	           calc-shift-Z-prefix-help
	           calc-z-prefix-help)))
     (help-print-return-message))))

(defun calc-help-for-help (arg)
  "You have typed \\`h', the Calc help character.  Type a Help option:

\\`B'  calc-describe-bindings.  Display a table of all key bindings.
\\`H'  calc-full-help.  Display all \\`?' key messages at once.

\\`I'  calc-info.  Read the Calc manual using the Info system.
\\`T'  calc-tutorial.  Read the Calc tutorial using the Info system.
\\`S'  calc-info-summary.  Read the Calc summary using the Info system.

\\`C'  calc-describe-key-briefly.  Look up the command name for a given key.
\\`K'  calc-describe-key.  Look up a key's documentation in the manual.
\\`F'  calc-describe-function.  Look up a function's documentation in the manual.
\\`V'  calc-describe-variable.  Look up a variable's documentation in the manual.

\\`N'  calc-view-news.  Display Calc history of changes.

\\`C-c'  Describe conditions for copying Calc.
\\`C-d'  Describe how you can get a new copy of Calc or report a bug.
\\`C-w'  Describe how there is no warranty for Calc."
  (interactive "P")
  (if calc-dispatch-help
      (let (key)
	(save-window-excursion
	  (describe-function 'calc-help-for-help)
	  (select-window (get-buffer-window "*Help*"))
      (tpop-fit-vim-string (buffer-string))
      (kill-buffer)
	  (while (progn
		       (message "Calc Help options: Help, Info, ...  press SPC, DEL to scroll, C-g to cancel")
		       (memq (setq key (read-event))
			         '(?  ?\C-h ?\C-? ?\C-v ?\M-v)))
	    (condition-case nil
		    (if (memq key '(? ?\C-v))
		        (scroll-up)
		      (scroll-down))
	      (error (beep)))))
	(calc-unread-command key)
	(calc-help-prefix nil))
    (let ((calc-dispatch-help t))
      (calc-help-prefix arg))))


(defun calc-edit-scratch ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (calc)
    (progn
      (if (f-exists-p "/root/notes/ws/calc/scratch.org")
          (find-file "/root/notes/ws/calc/scratch.org")
        (scratch-buffer))
      (calc))))

(defun calc-dispatch-around-advice (proc &rest args)
  (setq current-prefix-arg '(4))        ; C-u
  (let ((res (apply proc args)))
    res))
(advice-add 'calc-dispatch :around #'calc-dispatch-around-advice)
(advice-remove 'calc-dispatch #'calc-dispatch-around-advice)

(provide 'pen-calc)
