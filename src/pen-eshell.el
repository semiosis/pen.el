(require 'eshell)

;; Not very good.
;; (require 'eshell-vterm)


;; https://github.com/howardabrams/dot-files/blob/master/emacs-eshell.org

;; Reload the aliases file:
;; eshell-read-aliases-list


(setq eshell-buffer-shorthand t)
(setq eshell-rc-script "~/.emacs.d/pen.el/config/eshellrc.el")


;; Scrolling through the output and searching for results that can be copied to the kill ring is a great feature of Eshell. However, instead of running end-of-buffer key-binding, the following setting means any other key will jump back to the prompt:

;; I can never seem to remember that find and chmod behave differently from Emacs than their Unix counterparts, so the last setting will prefer the native implementations.
(use-package eshell
  :init
  (setq ;; eshell-buffer-shorthand t ...  Can't see Bug#19391
   eshell-scroll-to-bottom-on-input 'all
   eshell-error-if-no-glob t
   eshell-hist-ignoredups t
   eshell-save-history-on-exit t
   eshell-prefer-lisp-functions nil
   eshell-destroy-buffer-when-process-dies t))


;; Eshell would get somewhat confused if I ran the following commands directly through the normal Elisp library, as these need the better handling of ansiterm:
(use-package eshell
  :init
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq eshell-prefer-lisp-functions t)
              (add-to-list 'eshell-visual-commands "ssh")
              (add-to-list 'eshell-visual-commands "tail")
              (add-to-list 'eshell-visual-commands "top"))))


(require 'em-alias)

;; Put the aliases outside
;; They're now in $PENELD/config/eshellrc.el
;; (eshell/alias "ff" "find-file $1")
;; (eshell/alias "e" "find-file $1")

(eshell/alias "emacs" "find-file $1")
(eshell/alias "ee" "find-file-other-window $1")

(eshell/alias "gd" "magit-diff-unstaged")
(eshell/alias "gds" "magit-diff-staged")
(eshell/alias "d" "dired $1")

;; The 'ls' executable requires the Gnu version on the Mac
(let ((ls (if (file-exists-p "/usr/local/bin/gls")
              "/usr/local/bin/gls"
            "/bin/ls")))
  (eshell/alias "ll" (concat ls " -AlohG --color=always")))


;; git
;; My gst command is just an alias to magit-status, but using the alias doesn’t pull in the current working directory, so I make it a function, instead:
(defun eshell/gst (&rest args)
  (magit-status (pop args) nil)
  (eshell/echo))   ;; The echo command suppresses output


;; (use-package all-the-icons
;;   (setq eshell-prompt-function
;;         (lambda ()
;;           (format "%s %s\n%s%s%s "
;;                   (all-the-icons-octicon "repo")
;;                   (propertize (cdr (shrink-path-prompt default-directory)) 'face `(:foreground "white"))
;;                   (propertize "❯" 'face `(:foreground "#ff79c6"))
;;                   (propertize "❯" 'face `(:foreground "#f1fa8c"))
;;                   (propertize "❯" 'face `(:foreground "#50fa7b"))))))


(setq eshell-hist-ignoredups t)
(setq eshell-cmpl-cycle-completions nil)
(setq eshell-cmpl-ignore-case t)
(setq eshell-ask-to-save-history (quote always))
(setq eshell-prompt-regexp "❯❯❯ ")

(defun cljr--point-after (&rest actions)
  "Returns POINT after performing ACTIONS.

An action is either the symbol of a function or a two element
list of (fn args) to pass to `apply''"
  (save-excursion
    (dolist (fn-and-args actions)
      (let ((f (if (listp fn-and-args) (car fn-and-args) fn-and-args))
            (args (if (listp fn-and-args) (cdr fn-and-args) nil)))
        (apply f args)))
    (point)))

(defun cljr--end-of-buffer-p ()
  "True if point is at end of buffer"
  (= (point) (cljr--point-after 'end-of-buffer)))

(defun eshell-delete-char-maybe-quit ()
  (interactive)
  (if (cljr--end-of-buffer-p)
      (pen-revert-kill-buffer-and-window)
    (delete-char)))

(add-hook 'eshell-mode-hook
          '(lambda ()
             (progn
               ;; define-key must go here becasue eshell-mode-map doesn't exist until it's started
               (define-key eshell-mode-map "\C-a" 'eshell-bol)
               (define-key eshell-mode-map "\C-d" 'eshell-delete-char-maybe-quit)
               (define-key eshell-mode-map "\C-r" 'counsel-esh-history)
               (define-key eshell-mode-map [up] 'previous-line)
               (define-key eshell-mode-map [down] 'next-line)
               ;; (define-key eshell-mode-map (kbd "M-r") 'ranger)

               ;; eshell-previous-matching-input
               (define-key eshell-hist-mode-map (kbd "M-r") nil)
               ;; (define-key eshell-mode-map (kbd "M-r") nil)

               (define-key eshell-mode-map (kbd "M-R") 'eshell-previous-matching-input))))



(defun pen-close-eshell-window-when-dead () 
  (when (not (one-window-p))
    (delete-window)))

(advice-add 'eshell-life-is-too-much :after 'pen-close-eshell-window-when-dead)


;; This allows me to make overrides, but not to be explicit when calling
(setq eshell-prefer-lisp-functions t)


;; I sadly can't do it this way
;; ----------------------------
;; (defun builtin (command &optional args)
;;   "Insert output from a plain COMMAND, using ARGS.
;; COMMAND may result in either a Lisp function being executed by name,
;; or an external command."
;;   (let* ((esym (eshell-find-alias-function command))
;;          (sym (or esym (intern-soft command))))
;;     (eshell-lisp-command sym args)))

;; (defalias 'ecommand 'eshell-external-command)

;; (defun command (command args)
;;   "Insert output from a plain COMMAND, using ARGS.
;; COMMAND may result in either a Lisp function being executed by name,
;; or an external command."
;;   (let* ((esym (eshell-find-alias-function command))
;;          (sym (or esym (intern-soft command))))
;;     (eshell-lisp-command commands args)))

;; I need to edit this function
;; ----------------------------
(defun eshell-plain-command (command args)
  "Insert output from a plain COMMAND, using ARGS.
COMMAND may result in either a Lisp function being executed by name,
or an external command."

  (cond ((string-match-p command "^builtin$")
         (let* ((command (car args))
                (args (rest args))
                (esym (eshell-find-alias-function command))
                (sym (or esym (intern-soft command))))
           (eshell-lisp-command sym args)))
        ((string-match-p command "^command$")
         (let* ((command (car args))
                (args (rest args))
                (esym (eshell-find-alias-function command))
                (sym (or esym (intern-soft command))))
           (eshell-external-command command args)))
        (t
         (let* ((esym (eshell-find-alias-function command))
                (sym (or esym (intern-soft command))))

           (if (and sym (fboundp sym)
                    (or esym eshell-prefer-lisp-functions
                        (not (eshell-search-path command))))
               (eshell-lisp-command sym args)
             (eshell-external-command command args)))))

  (let* ((esym (eshell-find-alias-function command))
         (sym (or esym (intern-soft command))))))

(defun eshell-unique (&optional arg)
  (interactive "P")
  (progn
    (eshell arg)
    (rename-buffer (concat "*eshell-" (substring (uuidgen-4) 0 8) "*")
                   )))

(defun e/nw (&optional run)
  (interactive)
  (if run
      (call-interactively run)))
(defalias 'enw 'e/nw)

(defun e/sps (&optional run)
  (interactive)
  (split-window-sensibly)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'esps 'e/sps)


(defun e/spv (&optional run)
  (interactive)
  (split-window-horizontally)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'espv 'e/spv)

(defun e/sph (&optional run)
  (interactive)
  (split-window-vertically)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'esph 'e/sph)

(defun eshell-nw ()
  (interactive)
  (e/nw 'eshell-unique)
  ;; (split-window-vertically)
  ;; (other-window 1)
  ;; (shell) ; this is a real terminal
  ;; (eshell)
  )

(defun eshell-sps ()
  (interactive)
  (e/sps 'eshell-unique)
  ;; (split-window-vertically)
  ;; (other-window 1)
  ;; (shell) ; this is a real terminal
  ;; (eshell)
  )

(defun eshell-sph ()
  (interactive)
  (e/sph 'eshell-unique)
  ;; (split-window-vertically)
  ;; (other-window 1)
  ;; (shell) ; this is a real terminal
  ;; (eshell)
  )

(defun eshell-spv ()
  (interactive)
  (e/spv 'eshell-unique)
  ;; (split-window-horizontally)
  ;; (other-window 1)
  ;; (shell) ; shell is zsh or whatever the default shell is
  ;; (eshell)
  )

;; Do the following even work?
(defun eshell-run-command (cmd)
  (interactive (list (read-string-hist "eshell$ ")))
  (eshell)
  (with-current-buffer "*eshell*"
    (eshell-return-to-prompt)
    (eshell-kill-input)
    ;; (kill-line)
    (insert cmd)
    (eshell-send-input)))

;; shell (not eshell)
(defun shell-run-command (cmd)
  (interactive (list (read-string-hist "shell$ ")))
  (shell)
  (with-current-buffer "*shell*"
    (eshell-return-to-prompt)
    (eshell-kill-input)
    ;; (kill-line)
    (insert cmd)
    (eshell-send-input)))

(provide 'pen-eshell)
