;; Inferior mode for "imaginary interpreter" (ii)

;; inf-pen.el provides a REPL buffer connected to a imaginary interpreter subprocess.

;; In your emacs config:

;; (add-to-list 'load-path "~/.emacs.d/vendor/inf-pen")
;; (require 'inf-pen)

;; Usage

;; Run with `M-x inf-pen'

;;; Code:

;; (require 'js)
(require 'comint)

;;;###autoload
(defgroup inf-pen nil
  "Run an ii shell (ii) process in a buffer."
  :group 'inf-pen)

;;;###autoload
(defcustom inf-pen-command "ii"
  "Default ii shell command used.")

;;;###autoload
(defcustom inf-pen-mode-hook nil
  "*Hook for customizing inf-pen mode."
  :type 'hook
  :group 'inf-pen)

(add-hook 'inf-pen-mode-hook 'ansi-color-for-comint-mode-on)

;;;###autoload
(defun inf-pen (cmd &optional dont-switch-p)
  "Major mode for interacting with an inferior ii shell (ii) process.

The following commands are available:
\\{inf-pen-mode-map}

an ii shell process can be fired up with M-x inf-pen.

Customisation: Entry to this mode runs the hooks on comint-mode-hook and
inf-pen-mode-hook (in that order)."
  (interactive (list (read-from-minibuffer "Run ii shell: "
                                           inf-pen-command)))

  (if (not (comint-check-proc "*ii*"))
      (save-excursion (let ((cmdlist (split-string cmd)))
        (set-buffer (apply 'make-comint "ii" (car cmdlist)
                           nil (cdr cmdlist)))
        (inf-pen-mode)
        (setq inf-pen-command cmd) 
        (setq inf-pen-buffer "*ii*")
        ;; (inf-pen-setup-autocompletion)
        )))
  (if (not dont-switch-p)
      (pop-to-buffer "*ii*")))

;;;###autoload
(defun ii-send-region (start end)
  "Send the current region to the inferior ii process."
  (interactive "r")
  (inf-pen inf-pen-command t)
  (comint-send-region inf-pen-buffer start end)
  (comint-send-string inf-pen-buffer "\n"))

;;;###autoload
(defun ii-send-region-and-go (start end)
  "Send the current region to the inferior ii process."
  (interactive "r")
  (inf-pen inf-pen-command t)
  (comint-send-region inf-pen-buffer start end)
  (comint-send-string inf-pen-buffer "\n")
  (switch-to-inf-pen inf-pen-buffer))

;;;###autoload
(defun ii-send-last-sexp-and-go ()
  "Send the previous sexp to the inferior ii process."
  (interactive)
  (ii-send-region-and-go (save-excursion (backward-sexp) (point)) (point)))

;;;###autoload
(defun ii-send-last-sexp ()
  "Send the previous sexp to the inferior ii process."
  (interactive)
  (ii-send-region (save-excursion (backward-sexp) (point)) (point)))

;;;###autoload
(defun ii-send-buffer ()
  "Send the buffer to the inferior ii process."
  (interactive)
  (ii-send-region (point-min) (point-max)))

;;;###autoload
(defun ii-send-buffer-and-go ()
  "Send the buffer to the inferior ii process."
  (interactive)
  (ii-send-region-and-go (point-min) (point-max)))

;;;###autoload
(defun switch-to-inf-pen (eob-p)
  "Switch to the ii process buffer.
With argument, position cursor at end of buffer."
  (interactive "P")
  (if (or (and inf-pen-buffer (get-buffer inf-pen-buffer))
          (ii-interactively-start-process))
      (pop-to-buffer inf-pen-buffer)
    (error "No current process buffer. See variable inf-pen-buffer."))
  (when eob-p
    (push-mark)
    (goto-char (point-max))))

(defvar inf-pen-buffer)

(defvar inf-pen-prompt "\n> \\|\n.+> "
  "String used to match inf-pen prompt.")

(defvar inf-pen--shell-output-buffer "")

(defvar inf-pen--shell-output-filter-in-progress nil)

(defun inf-pen--shell-output-filter (string)
  "This function is used by `inf-pen-get-result-from-inf'.
It watches the inferior process until, the process returns a new prompt,
thus marking the end of execution of code sent by
`inf-pen-get-result-from-inf'.  It stores all the output from the
process in `inf-pen--shell-output-buffer'.  It signals the function
`inf-pen-get-result-from-inf' that the output is ready by setting
`inf-pen--shell-output-filter-in-progress' to nil"
  (setq string (ansi-color-filter-apply string)
	inf-pen--shell-output-buffer (concat inf-pen--shell-output-buffer string))
  (let ((prompt-match-index (string-match inf-pen-prompt inf-pen--shell-output-buffer)))
    (when prompt-match-index
      (setq inf-pen--shell-output-buffer
	    (substring inf-pen--shell-output-buffer
		       0 prompt-match-index))
      (setq inf-pen--shell-output-filter-in-progress nil)))
  "")

(defun inf-pen-get-result-from-inf (code)
  "Helper function to execute the given CODE in inferior ii and return the result."
  (let ((inf-pen--shell-output-buffer nil)
        (inf-pen--shell-output-filter-in-progress t)
        (comint-preoutput-filter-functions '(inf-pen--shell-output-filter))
        (process (get-buffer-process inf-pen-buffer)))
    (with-local-quit
      (comint-send-string process code)
      (comint-send-string process "\n")
      (while inf-pen--shell-output-filter-in-progress
        (accept-process-output process))
      (prog1
          inf-pen--shell-output-buffer
        (setq inf-pen--shell-output-buffer nil)))))

(defun inf-pen-shell-completion-complete-at-point ()
  "Perform completion at point in inferior-ii.
Most of this is borrowed from python.el")

(defun inf-pen-get-completions-at-point (prefix)
  "Get completions for PREFIX using inf-pen."
  (if (equal prefix "") 
      nil
    (split-string (inf-pen-get-result-from-inf (concat "INFMONGO__getCompletions('" prefix "');")) ";")))

;;;###autoload
(defvar inf-pen-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-x\C-e" 'ii-send-last-sexp)
    map))

;;;###autoload
(define-derived-mode inf-pen-mode comint-mode "Inferior ii mode"
  (make-local-variable 'font-lock-defaults)

  (add-to-list (make-local-variable 'comint-dynamic-complete-functions)
               'inf-pen-shell-completion-complete-at-point)

  (use-local-map inf-pen-mode-map))

(defun inf-pen-fz-contacts-sh ()
  (pen-snd "dos2unix | sed -e 1d -e \\$d -e \\$d" (inf-pen-get-result-from-inf "contacts")))

(defun inf-pen-fz-contacts ()
  (interactive)
  (let ((contact
         (chomp (fz (inf-pen-fz-contacts-sh)))))
    contact))

(defun inf-pen-fz-threads-sh ()
  (pen-sn "dos2unix | sed -e 1d -e \\$d" (inf-pen-get-result-from-inf "threads")))

(defun inf-pen-fz-threads ()
  (interactive)
  (let ((contact
         (chomp (fz (inf-pen-fz-threads-sh)))))
    contact))

(defun inf-pen-fz-contacts-and-threads-sh ()
  (pen-sn "sort | uniq"
      (concat (awk1 (inf-pen-fz-contacts-sh))
              (awk1 (inf-pen-fz-threads-sh))
              "Shane Mulligan\n")))

(defun inf-pen-fz-contacts-and-threads ()
  (interactive)
  (chomp (fz (inf-pen-fz-contacts-and-threads-sh))))

(defun start-ii-if-not-started ()
  (interactive)
  (save-window-excursion (inf-pen "ii" nil)))

(defun start-ii-if-not-started-wait ()
  (interactive)
  (save-window-excursion (inf-pen "ii" nil)))

(defun start-ii ()
  (interactive)
  (inf-pen "ii" nil))

(defun inf-pen-history (contact)
  (interactive (list (inf-pen-fz-contacts-and-threads)))

  (let ((history
         (s-replace-regexp "\r+" "" (pen-sn "dos2unix | sed -e 1d" (inf-pen-get-result-from-inf (concat "history " (pen-q contact) " 1000000"))))))
    (with-current-buffer (evipe history)
      (end-of-buffer)
      (beginning-of-line-or-indentation)))
  ;; (let ((contact (inf-pen-fz-contacts)))
  ;;   (evipe )
  ;;   )
  )

;; (defun inf-pen-send (contact message)
;;   (interactive (let ((contact (inf-pen-fz-contacts-and-threads))) (list contact (read-string (concat "Send to " contact ": ")))))

;;   (let ((sentout
;;          ;; (pen-sn "dos2unix | sed -e 1d" (inf-pen-get-result-from-inf (concat "history " (pen-q contact))))
;;          ;; (s-replace-regexp "\r+" "" (pen-sn "dos2unix | sed -e 1d" (inf-pen-get-result-from-inf (concat "message " (pen-q contact) " " message))))
;;          (inf-pen-get-result-from-inf (concat "message " (pen-q contact) " " message))))
;;     (evipe sentout))
;;   ;; (let ((contact (inf-pen-fz-contacts)))
;;   ;;   (evipe )
;;   ;;   )
;;   )

;; (defun inf-pen-send-file (contact fp message)
;;   (interactive (list
;;                 (inf-pen-fz-contacts-and-threads)
;;                 (read-file-name "fp: ")
;;                 (read-string "m: ")))

;;   (let ((sentout
;;          (inf-pen-get-result-from-inf (concat "file " (pen-q contact)
;;                                                  " "
;;                                                  (pen-q fp) " " message))))
;;     (evipe sentout)))

;; (defun s-filter-lines (pred s)
;;   (string-join
;;    (-filter
;;     pred
;;     (split-string s "\n"))
;;    "\n"))

;; (defun extract-name-from-recent-item (s)
;;   ;; (pen-sn "sed \"s/^[^ ]\\+ \\(.*\\) \(.*/\\1/\"" s)
;;   (pen-sed "s/^\\[[0-9]\\+\\] //" (pen-sed "s/ (.*//" s))
;;   ;; (pen-sed "s/^\\[[0-9]\\+\\] //" s))
;;   )

;; (defun filter-unread (input)
;;   (s-filter-lines (lambda (s) (string-match-p "unread" s)) input))

;; (defun inf-pen-recent-contacts-sh (&optional unread)
;;   (extract-name-from-recent-item (if unread
;;                                      (filter-unread (inf-pen-recent-sh))
;;                                    (inf-pen-recent-sh))))

;; (defun inf-pen-recent-contacts (&optional unread)
;;   (interactive)
;;   (evipe (inf-pen-recent-contacts-sh unread)))

;; (evipe (string-join (-filter (lambda (s) (string-match-p "unread" s)) (split-string (inf-pen-recent-sh) "\n")) "\n"))

;; (defun inf-pen-recent-sh ()
;;   (let ((sentout
;;          (s-replace-regexp "\r+" "" (pen-sn "dos2unix | sed -e 1d" (inf-pen-get-result-from-inf (concat "recent 1000000"))))))
;;     sentout))

;; (defun inf-pen-recent ()
;;   (interactive)
;;   (evipe (inf-pen-recent-sh)))

;; (defun inf-pen-reply (contact message)
;;   (interactive (list (fz (inf-pen-recent-contacts-sh)) (read-string "m: ")))

;;   (let ((sentout
;;          (inf-pen-get-result-from-inf (concat "message " (pen-q contact) " " message))))
;;     (evipe sentout)))

(provide 'inf-pen)
;;; inf-pen.el ends here
