;; Fix the UTF coding system

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
            (mapcar #'(lambda (coding)
                        (cons coding
                              (if (stringp from)
                                  (mapcar #'(lambda (pos)
                                              (cons pos (aref from pos)))
                                          (unencodable-char-position
                                           0 (length from) coding
                                           11 from))
                                (mapcar #'(lambda (pos)
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
        (goto-char (apply #'min (mapcar (lambda (x) (or (car (cadr x)) (point-max)))
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
                       #'(lambda (bufname pos)
                           (when (buffer-live-p (get-buffer bufname))
                             (pop-to-buffer bufname)
                             (goto-char pos))))
                      (func2
                       #'(lambda (bufname pos coding)
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
                        (insert (if (< i 10) (cdr elt) "..."))
                      (if (< i 10)
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
                    (setq i (1+ i))))
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

;; https://www.emacswiki.org/emacs/CopyingWholeLines
(defun copy-line (arg)
  "Copy lines (as many as prefix argument) in the kill ring.
      Ease of use features:
      - Move to start of next line.
      - Appends the copy on sequential calls.
      - Use newline as last char even on the last line of the buffer.
      - If region is active, copy its lines."
  (interactive "p")
  (let ((beg (get-current-line-string-beginning-position))
        (end (get-current-line-string-end-position arg)))
    (when mark-active
      (if (> (point) (mark))
          (setq beg (save-excursion (goto-char (mark)) (get-current-line-string-beginning-position)))
        (setq end (save-excursion (goto-char (mark)) (get-current-line-string-end-position)))))
    (if (eq last-command 'copy-line)
        (kill-append (buffer-substring beg end) (< end beg))
      (kill-ring-save beg end)))
  (kill-append "\n" nil)
  (beginning-of-line (or (and arg (1+ arg)) 2))
  (if (and arg (not (= 1 arg))) (message "%d lines copied" arg)))

(require 'desktop)

;; (setq-default truncate-lines t)
(setq-default visual-line-mode t)
;; Disable this! purcell uses it
(desktop-save-mode 0)

(define-key global-map (kbd "C-M--") 'text-scale-decrease)
(define-key global-map (kbd "C-M-=") 'text-scale-increase)

;; (setq browse-url-generic-program "google-chrome")
;; Make it so xmonad knows to switch to firefox. This would be good for documentation. Or I should just create a firefox wrapper for this.
;; (setq browse-url-generic-program "firefox")
(setq browse-url-generic-program "ff-view")

;; Make sure this is off. It would be annoying. But good for debugging
;; 20:49 < mrblack> My emacs started to open the debugger whenever I use keyboard-quit... anyone know how I can make it stop doing that?
(setq debug-on-quit nil)

(push "^No window numbered .$"     debug-ignored-errors)


(defun next-line-nonvisual (&optional arg try-vscroll)
  (interactive)
  (let ((get-current-line-string-move-visual nil))
    (next-line arg try-vscroll)))

(defun previous-line-nonvisual (&optional arg try-vscroll)
  (interactive)
  (let ((get-current-line-string-move-visual nil))
    (previous-line arg try-vscroll)))

(setq debug-on-error nil)

(define-key global-map (kbd "C-M-@") nil)

(defun save-buffers-kill-emacs (&optional arg)
  "Offer to save each buffer, then kill this Emacs process.
With prefix ARG, silently save all file-visiting buffers without asking.
If there are active processes where `process-query-on-exit-flag'
returns non-nil and `confirm-kill-processes' is non-nil,
asks whether processes should be killed.
Runs the members of `kill-emacs-query-functions' in turn and stops
if any returns nil.  If `confirm-kill-emacs' is non-nil, calls it."
  (interactive "P")
  ;; Don't use save-some-buffers-default-predicate, because we want
  ;; to ask about all the buffers before killing Emacs.
  (save-some-buffers arg t)
  (let ((confirm confirm-kill-emacs))
    (and
     (or (not (memq t (mapcar (function
                               (lambda (buf) (and (buffer-file-name buf)
                                                  (buffer-modified-p buf))))
                              (buffer-list))))
         (progn (setq confirm nil)
                (yes-or-no-p "Modified buffers exist; exit anyway? ")))
     (or (not (fboundp 'process-list))
         ;; process-list is not defined on MSDOS.
         (not confirm-kill-processes)
         (let ((processes (process-list))
               active)
           (while processes
             (and (memq (process-status (car processes)) '(run stop open listen))
                  (process-query-on-exit-flag (car processes))
                  (setq active t))
             (setq processes (cdr processes)))
           (or (not active)
               (with-current-buffer-window
                   (get-buffer-create "*Process List*")
                   `(display-buffer--maybe-at-bottom
                     (dedicated . t)
                     (window-height . fit-window-to-buffer)
                     (preserve-size . (nil . t))
                     (body-function
                      . ,#'(lambda (_window)
                             (list-processes t))))
                   #'(lambda (window _value)
                       (with-selected-window window
                         (unwind-protect
                             (progn
                               (setq confirm nil)
                               (yes-or-no-p "Active processes exist; kill them and exit anyway? "))
                           (when (window-live-p window)
                             (quit-restore-window window 'kill)))))))))
     ;; Query the user for other things, perhaps.
     ;; (message "trying")
     ;; Ignore errors wont work as run-hook-with-args-until-failure is a c function?
     ;; (ignore-errors (run-hook-with-args-until-failure 'kill-emacs-query-functions))
     (try (run-hook-with-args-until-failure 'kill-emacs-query-functions)
          (progn
            (or (null confirm)
                (funcall confirm "Really exit Emacs? "))
            (kill-emacs)))

     ;; (message "made it")
     ;; I want to always make it to this point
     (or (null confirm)
         (funcall confirm "Really exit Emacs? "))
     (kill-emacs))))

(provide 'pen-emacs)