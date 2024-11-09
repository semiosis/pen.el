(require 'eshell)
(require 'pcomplete-extension)
(require 'eshell-git-prompt)
(require 'eshell-prompt-extras)
(require 'eshell-autojump)
(require 'eshell-z)
(require 'eshell-vterm)
(require 'eshell-up)
(require 'eshell-toggle)
(require 'eshell-syntax-highlighting)
(require 'eshell-outline)
(require 'eshell-info-banner)
(require 'eshell-fringe-status)
(require 'eshell-fixed-prompt)
(require 'eshell-did-you-mean)
(require 'eshell-bookmark)

(setq epe-fish-path-max-len 40)

(with-eval-after-load "esh-opt"
  (autoload 'epe-theme-lambda "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        eshell-prompt-function 'epe-theme-lambda))


;; Not very good.
;; (require 'eshell-vterm)


;; https://github.com/howardabrams/dot-files/blob/master/emacs-eshell.org

(setq eshell-buffer-shorthand t)
;; e:$EMACSD_BUILTIN/pen.el/config/eshellrc.el
(setq eshell-rc-script "~/.emacs.d/pen.el/config/eshellrc.el")

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
;; (eshell/alias "v" "pen-ewhich $1")
;; (eshell/alias "sp" "pen-ewhich $1")
;; (eshell/alias "e" "pen-find-file-create $1")

;; These aliases are made permanent by writing to this file
;; e:$EMACSD/eshell/alias
;; And they no longer need to be run
;; (eshell/alias "emacs" "find-file $1")
;; (eshell/alias "ee" "find-file-other-window $1")
;; (eshell/alias "gd" "magit-diff-unstaged")
;; (eshell/alias "gds" "magit-diff-staged")
;; (eshell/alias "d" "dired $1")

;; This let sexp hung in startup
;; Saving file /root/.emacs.d/eshell/alias...
;; alias has changed since visited or saved.  Save anyway? (y or n)
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
    (delete-char 1)))

(add-hook 'eshell-mode-hook
          '(lambda ()
             (progn
               ;; define-key must go here becasue eshell-mode-map doesn't exist until it's started
               (define-key eshell-mode-map "\C-a" 'eshell-bol)
               (define-key eshell-mode-map (kbd "C-c C-a") 'beginning-of-line)
               (define-key eshell-mode-map "\C-d" 'eshell-delete-char-maybe-quit)
               (define-key eshell-mode-map "\C-r" 'counsel-esh-history)
               (define-key eshell-mode-map [up] 'previous-line)
               (define-key eshell-mode-map [down] 'next-line)
               ;; (define-key eshell-mode-map (kbd "M-r") 'ranger)

               ;; eshell-previous-matching-input
               (define-key eshell-hist-mode-map (kbd "M-r") nil)
               (define-key eshell-hist-mode-map (kbd "M-p") 'eshell-previous-matching-input-from-input)
               (define-key eshell-hist-mode-map (kbd "M-n") 'eshell-next-matching-input-from-input)
               (define-key eshell-hist-mode-map (kbd "<up>") nil)
               (define-key eshell-hist-mode-map (kbd "<down>") nil)
               ;; (define-key eshell-mode-map (kbd "M-r") nil)

               (define-key eshell-mode-map
                           (kbd "M-R") 'eshell-previous-matching-input))))



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
(comment
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
          (sym (or esym (intern-soft command)))))))

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

;; (define-key eshell-mode-map (kbd "C-l") 'eshell/clear)
(define-key eshell-mode-map (kbd "C-l") 'identity-command)

;; This fixes eshell-pcomplete.
;; eshell-bol was going to the very beginning of the line
(defun eshell-bol ()
  (interactive)
  (pen-comint-bol))

;; Custom commands
;; eshell gives higher precedence to functions with eshell/ prefixed.
;; Also, in order to mash arguments, i need &rest args.
;; Otherwise, I might only have the positional args.

(defun eshell/listify (&rest args)
  "Return the argument(s) as a single list."
  (if (> (length args) 1)
      args
    (if (listp (car args))
	      (car args)
      (list (car args)))))

(defun eshell/slugify (&rest args)
  "Return the argument(s) as a single slug."
  (slugify (mapconcat 'str args " ")))

;; (define-key eshell-mode-map (kbd "M-h") 'pen-sph)
;; (define-key eshell-mode-map (kbd "M-h") 'eshell-sph)
(define-key eshell-mode-map (kbd "M-h") 'eshell-sps)

;; e:$EMACSD_BUILTIN/pen.el/config/eshellrc.el
;; It's also possible to define aliases this way:
;; (eshell/alias 'sps "pen-find-file-create $1")
;; j:pen-find-file-create
;; (eshell/alias 'sps "pen-find-file-create $1")
;; (eshell/alias 'sps "pen-sps $1")

(defun eshell-edit-aliases ()
  (interactive)
  (e eshell-aliases-file)
  ;; (eshell-read-aliases-list)
  )


(defun pen-eshell-source-file (fp &rest args)
  (interactive)
  (with-current-buffer (eshell)
    (eshell-source-file p args)))

;; j:eshell-output-filter-functions

(defun eshell-filter-region-remove-trailing-whitespace ()
  (region-erase-trailing-whitespace
   eshell-last-output-start
   (- eshell-last-output-end 1)))

(add-to-list 'eshell-output-filter-functions 'eshell-filter-region-remove-trailing-whitespace t)
;; (remove-from-list 'eshell-output-filter-functions 'eshell-filter-region-remove-trailing-whitespace)

(comment
 (etv (pps (eshell-environment-variables)))
 (etv (pps (eshell-copy-environment))))

(defun eshell-environment-variables ()
  "Return a `process-environment', fully updated.
This involves setting any variable aliases which affect the
environment, as specified in `eshell-variable-aliases-list'."
  (let ((process-environment (eshell-copy-environment)))
    (dolist (var-alias eshell-variable-aliases-list)
      (if (nth 2 var-alias)
	      (setenv (car var-alias)
		          (eshell-stringify
		           (or (eshell-get-variable (car var-alias)) "")))))
    process-environment))

(eshell-copy-environment)

;; v +/"INSIDE_EMACS" "$EMACSD/pen.el/scripts/bible-mode-scripts/ebible"

;; TODO Figure out how to get this working:

(comment
 (defun eshell-copy-environment-around-advice (proc &rest args)
   (let ((res (apply proc args)))

     (tv (append
          '("NOEMACS=y"
            "BORDER=n"
            "ONELINED=y"
            "DECORATED=y"
            "NO_PAGER=y")
          res))

     res))
 (advice-add 'eshell-copy-environment :around #'eshell-copy-environment-around-advice)
 (advice-remove 'eshell-copy-environment #'eshell-copy-environment-around-advice))

;; Make it so ebible works in eshell
(setq eshell-variable-aliases-list
      `(;; for eshell.el
        ("COLUMNS" ,(lambda () (window-body-width nil 'remap)) t t)
        ("LINES" ,(lambda () (window-body-height nil 'remap)) t t)
        ("INSIDE_EMACS" eshell-inside-emacs t)

        ;; for esh-ext.el
        ("PATH" (,(lambda () (string-join (eshell-get-path t) (path-separator)))
                 . ,(lambda (_ value)
                      (eshell-set-path value)
                      value))
         t t)

        ;; for esh-cmd.el
        ("_" ,(lambda (indices quoted)
                (if (not indices)
                    (car (last eshell-last-arguments))
                  (eshell-apply-indices eshell-last-arguments
                                        indices quoted))))
        ("?" (eshell-last-command-status . nil))
        ("$" (eshell-last-command-result . nil))

        ;; for em-alias.el and em-script.el
        ("0" eshell-command-name)
        ("1" ,(lambda () (nth 0 eshell-command-arguments)) nil t)
        ("2" ,(lambda () (nth 1 eshell-command-arguments)) nil t)
        ("3" ,(lambda () (nth 2 eshell-command-arguments)) nil t)
        ("4" ,(lambda () (nth 3 eshell-command-arguments)) nil t)
        ("5" ,(lambda () (nth 4 eshell-command-arguments)) nil t)
        ("6" ,(lambda () (nth 5 eshell-command-arguments)) nil t)
        ("7" ,(lambda () (nth 6 eshell-command-arguments)) nil t)
        ("8" ,(lambda () (nth 7 eshell-command-arguments)) nil t)
        ("9" ,(lambda () (nth 8 eshell-command-arguments)) nil t)
        ("*" (eshell-command-arguments . nil))))

;; TODO: Make it so =eshell= makes buttons out of =ls= results
;; Frustratingly, it seems like the global map is not respecting the mouse text properties
(defun eshell-ls-decorated-name (file)
  "Return FILE, possibly decorated."
  (if eshell-ls-use-colors
      (let ((face
             (cond
              ((not (cdr file))
               'eshell-ls-missing)

              ((stringp (cadr file))
               'eshell-ls-symlink)

              ((eq (cadr file) t)
               'eshell-ls-directory)

              ((not (eshell-ls-filetype-p (cdr file) ?-))
               'eshell-ls-special)

              ((and (/= (user-uid) 0)   ; root can execute anything
                    (eshell-ls-applicable (cdr file) 3
                                          'file-executable-p (car file)))
               'eshell-ls-executable)

              ((not (eshell-ls-applicable (cdr file) 1
                                          'file-readable-p (car file)))
               'eshell-ls-unreadable)

              ((string-match eshell-ls-archive-regexp (car file))
               'eshell-ls-archive)

              ((string-match eshell-ls-backup-regexp (car file))
               'eshell-ls-backup)

              ((string-match eshell-ls-product-regexp (car file))
               'eshell-ls-product)

              ((string-match eshell-ls-clutter-regexp (car file))
               'eshell-ls-clutter)

              ((not (eshell-ls-applicable (cdr file) 2
                                          'file-writable-p (car file)))
               'eshell-ls-readonly)
              (eshell-ls-highlight-alist
               (let ((tests eshell-ls-highlight-alist)
                     value)
                 (while tests
                   (if (funcall (caar tests) (car file) (cdr file))
                       (setq value (cdar tests) tests nil)
                     (setq tests (cdr tests))))
                 value)))))

        (let* ((map (make-sparse-keymap))
               (link-start 0)
               (link-end (length (car file)))

               (text
                (progn
                  (if face
                      (add-text-properties link-start link-end
                                           `(keymap ,map
                                                    font-lock-face ,face
                                                    mouse-face highlight
                                                    ;; help-echo "mouse-2: visit this file in other window"
                                                    help-echo "RET: find file")
                                           (car file))
                    (add-text-properties link-start link-end
                                         `(keymap ,map
                                                  mouse-face highlight
                                                  ;; help-echo "mouse-2: visit this file in other window"
                                                  help-echo "RET: find file")
                                         (car file))))))

          ;; (define-key map [mouse-down-3] 'dired-mouse-find-file-other-window)
          ;; (define-key map [mouse-down-1] 'pen-find-file)
          ;; RET - this works but I need a non-mouse function
          (define-key map [?\r] 'pen-find-file)
          ;; (put-text-property link-start link-end 'keymap map (car file))

          text)))
  (car file))

(provide 'pen-eshell)
