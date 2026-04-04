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

(eshell-info-banner-update-banner)

(defalias 'banner 'eshell-info-banner)

(require 'em-script)

;; https://www.howardism.org/Technical/Emacs/eshell-fun.html
;; https://www.masteringemacs.org/article/complete-guide-mastering-eshell

(setq epe-fish-path-max-len 40)

(setq eshell-visual-commands
      '("tail" "ssh" "vi" "vim" "screen" "tmux" "top" "htop" "less" "more" "lynx" "links" "ncftp" "mutt" "pine" "tin" "trn" "elm"
        "v"
        "br"))

;; emacs term is too slow for br.
;; But I haven't ironed out all of the vterm issues, so make a eshell/br function that uses in-tty

(setq eshell-prefer-lisp-functions t)
(eshell-vterm-mode -1)
;; (eshell-vterm-mode t)

;; vterm needs some ironing out
;; (eshell-vterm-mode t)
;; (eshell-vterm-mode -1)


;; This has been a good theme. I think I'll stick with it.
;; It also "looks" like eshell to me now
(with-eval-after-load "esh-opt"
  (autoload 'epe-theme-lambda "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        ;; eshell-prompt-function 'epe-theme-lambda
        eshell-prompt-function 'epe-theme-dakrone))


;; mx:eshell-git-prompt-use-theme
;; (eshell-git-prompt-use-theme 'robbyrussell)
;; (eshell-git-prompt-use-theme 'gitradar)
;; (eshell-git-prompt-use-theme 'powerline)
;; (eshell-git-prompt-use-theme 'simple)


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
   ;; eshell-prefer-lisp-functions nil
   eshell-destroy-buffer-when-process-dies t))


;; Eshell would get somewhat confused if I ran the following commands directly through the normal Elisp library, as these need the better handling of ansiterm:
;; (use-package eshell
;;   ;; :init
;;   ;; (add-hook 'eshell-mode-hook
;;   ;;           (lambda ()
;;   ;;             (setq eshell-prefer-lisp-functions t)
;;   ;;             (add-to-list 'eshell-visual-commands "ssh")
;;   ;;             (add-to-list 'eshell-visual-commands "tail")
;;   ;;             (add-to-list 'eshell-visual-commands "top")))
;;   )


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
(setq eshell-prompt-regexp "^[^#$\n]* [#$] ")

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

                ;; (define-key eshell-cmpl-mode-map (kbd "C-c TAB") 'pcomplete-expand-and-complete)
               (define-key eshell-cmpl-mode-map (kbd "C-c TAB") nil)

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
    ;; DONE Make it so the main "*eshell*" buffer is not renamed.
    (let ((eshell-buffer-name
           (concat "*eshell-" (substring (uuidgen-4) 0 8) "*")))
      (eshell arg))
    ;; (rename-buffer (concat "*eshell-" (substring (uuidgen-4) 0 8) "*"))
    ))

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

;; Aliases for shell commands, so eshell prefers these to lisp functions
;; TODO Make these utilise stdin
(loop for c in '(cfind wc) do
      (let* ((cname (sym2str c))
             (fname (str2sym (concat "eshell/" (sym2str c))))
             (comment (concat "Alias to " cname " shell command.")))
        (eval
         `(defun ,fname (&rest args)
            ,comment
            ;; Firstly, fix the arguments
            (setq args (mapcar 'str args))

            (pen-snc (apply 'cmd (cons ,cname args)))))))

;; This fz inserts the results of the command
(loop for c in '(find) do
      (let* ((cname (sym2str c))
             (fname (str2sym (concat "eshell/" (sym2str c))))
             (comment (concat "Alias to " cname " shell command.")))
        (eval
         `(defun ,fname (&rest args)
            ,comment
            ;; Firstly, fix the arguments
            (setq args (mapcar 'str args))

            (let* ((c (apply 'cmd-nice (cons ,cname args)))
                   (results (sor (pen-snc c))))

              (if results
                  (let ((sel (fz results
                                 nil nil
                                 (format-prompt c nil))))
                    (if sel
                        (insert (concat "e " sel))))
                (format "%d results" (length results))
                (format "No results")))))))

;; Because there is a j:df macro in emacs, I
;; define here an eshell function which will be found first
;; TODO Make this display inside of a tabulated list
(defun eshell/df (&rest args)
  "Like the bash `command` function."
  ;; Firstly, fix the arguments
  (setq args (mapcar 'str args))

  (cmd-out-to-tablist-quick (concat (apply 'cmd (cons "df" args)) " | sed 's/Mounted on/Mounted-on/' | sed -E 's/ +/,/g' | sed '1s/%/-percent/g'")
                            t)
  ;; (pen-snc (apply 'cmd (cons "df" args)))
  )

(defun eshell/e (&rest args)
  "Like the bash `command` function."

  (pen-ewhich (car args)))

(defun eshell/command (&rest args)
  "Like the bash `command` function."
  ;; Firstly, fix the arguments
  (setq args (mapcar 'str args))
  
  ;; (pen-snc (eval `(cmd "command" ,@args)))
  ;; (pen-snc (apply 'cmd (cons "command" args)))
  (pen-snc (apply 'cmd (cons "com" args))))

(defun eshell/br (&rest args)
  "broot."
  ;; Firstly, fix the arguments
  (setq args (mapcar 'str args))
  
  ;; (pen-snc (eval `(cmd "command" ,@args)))
  ;; (pen-snc (apply 'cmd (cons "command" args)))
  (pen-snc (apply 'cmd (cons "in-tty" (cons "br" args)))))

(defun eshell/slugify (&rest args)
  "Return the argument(s) as a single slug."
  (slugify (mapconcat 'str args " ")))

(defun eshell/r (&rest args)
  "Ranger."
  (apply 'ranger args))

(defun eshell/d (&rest args)
  "Ranger."
  (apply 'dired (or args '("."))))

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
(advice-add 'eshell-filter-region-remove-trailing-whitespace :around #'ignore-errors-around-advice)

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

(defsetface eshell-normal-file
  '((((class color) (background light))
     (:foreground "#444444" :background "#222222" :weight bold))
    (((class color) (background dark))
     (:foreground "#444444" :background "#222222" :weight bold)))
  "The face used for highlighting regular files.")

;; j:ace-link--eww-collect

(defun pen-eshell-find-file ()
  "This command is really only supposed to be called specifically from clicking ls output in eshell."
  (interactive)
  
  (let ((textprop-path (get-text-property (point) 'file-path))
        (dir (pen-eshell-copy-directory-from-prompt)))

    (if dir
        (setq textprop-path (f-join dir textprop-path)))
    
    (if textprop-path
        (find-file textprop-path)
      (let ((maybe_path
             (ffap-guesser)))

        (if (sor maybe_path)
            (call-interactively 'find-file-at-point)
          (call-interactively 'find-file))))))

;; TODO: Make it so =eshell= makes buttons out of =ls= results
;; Frustratingly, it seems like the global map is not respecting the mouse text properties
(defun eshell-ls-decorated-name (file)
  "Return FILE, possibly decorated."
  ;; (elog "%s" "*ls-files*" file)
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
                 value))

              (t
               'eshell-normal-file))))

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
                                                    help-echo "RET: find file"
                                                    file-path ,(car file))
                                           (car file))
                    (add-text-properties link-start link-end
                                         `(keymap ,map
                                                  mouse-face highlight
                                                  ;; help-echo "mouse-2: visit this file in other window"
                                                  help-echo "RET: find file"
                                                  file-path ,(car file))
                                         (car file))))))

          ;; (define-key map [mouse-down-3] 'dired-mouse-find-file-other-window)
          ;; (define-key map [mouse-down-1] 'pen-find-file)
          ;; RET - this works but I need a non-mouse function

          ;; Ah, interesting. This is what provides the ability to "go to" a file in ls output.
          ;; However, I would like to make it have proper buttons.
          (define-key map [?\r] 'pen-eshell-find-file)
          (define-key map [mouse-1] 'pen-eshell-find-file)

          ;; (define-key map [?\r] 'pen-eshell-go-to-start-of-prompt)
          
          ;; (put-text-property link-start link-end 'keymap map (car file))

          ;; (elog "%s" "*ls-files*" (pps file))
          ;; text
          ;; (elog "%s" "*ls-files*" text)
          text)))
  (car file))

(defalias 'eshell/visual 'eshell-exec-visual)
(defalias 'eshell/term 'eshell-exec-visual)
(defalias 'eshell/vterm 'eshell-vterm-exec-visual)

;; (define-key eshell-map (kbd "C-c TAB") nil)
(define-key eshell-mode-map (kbd "M-a M-r") 'ranger)

;; Because the eshell-bol function alternately goes to the beginning of line and the start of the prompt,
;; I need to adjust this to ensure it gets the input string only from after the prompt
(defun eshell-previous-matching-input-from-input (arg)
  "Search backwards through input history for match for current input.
\(Previous history elements are earlier commands.)
With prefix argument N, search for Nth previous match.
If N is negative, search forwards for the -Nth following match."
  (interactive "p")
  (if (not (memq last-command '(eshell-previous-matching-input-from-input
				                eshell-next-matching-input-from-input)))
      ;; Starting a new search
      (setq eshell-matching-input-from-input-string
	        (buffer-substring (save-excursion
                                (eshell-bol)
                                ;; My addition
                                (if (bolp)
                                    (eshell-bol))
                                (point))
			                  (point))
	        eshell-history-index nil))
  (eshell-previous-matching-input
   (concat "^" (regexp-quote eshell-matching-input-from-input-string))
   arg))

;; Where to put this?
;; (add-to-list 'eshell-modules-list 'eshell-smart)

(defun pen-eshell-visual-command-p (command)
  (cl-letf (((symbol-function 'eshell-interactive-output-p) 'identity)) (eshell-visual-command-p command nil)))


;; j:eshell-execute-pipeline
(defun eshell-parse-pipeline (terms)
  "Parse a pipeline from TERMS, return the appropriate Lisp forms."
  (let* (eshell--sep-terms
         (bigpieces (eshell-separate-commands terms "\\(&&\\|||\\)"
                                              nil 'eshell--sep-terms))
         (bp bigpieces)
         (results (list t))
         final)
    (while bp
      (let ((subterms (car bp)))
        (let* ((pieces (eshell-separate-commands subterms "|"))
               (p pieces))
          (while p
            (let ((cmd (car p)))
              (run-hook-with-args 'eshell-pre-rewrite-command-hook cmd)
              (setq cmd (run-hook-with-args-until-success
                         'eshell-rewrite-command-hook cmd))
              (let ((eshell--cmd cmd))
                (run-hook-with-args 'eshell-post-rewrite-command-hook
                                    'eshell--cmd)
                (setq cmd eshell--cmd))
              (setcar p (funcall eshell-post-rewrite-command-function cmd)))
            (setq p (cdr p)))
          (nconc results
                 (list
                  (if (<= (length pieces) 1)
                      (car pieces)
                    (cl-assert (not eshell-in-pipeline-p))
                    `(eshell-execute-pipeline ',pieces)))))
        (setq bp (cdr bp))))
    ;; `results' might be empty; this happens in the case of
    ;; multi-line input
    (setq results (cdr results)
          results (nreverse results)
          final (car results)
          results (cdr results)
          eshell--sep-terms (nreverse eshell--sep-terms))
    (while results
      (cl-assert (car eshell--sep-terms))
      (setq final (eshell-structure-basic-command
                   'if (string= (car eshell--sep-terms) "&&") "if"
                   `(eshell-protect ,(car results))
                   `(eshell-protect ,final))
            results (cdr results)
            eshell--sep-terms (cdr eshell--sep-terms)))
    final))

;; I made added this option
(setq epe-path-style 'full-no-abbreviate)

;; DONE Just use this
;; But instead of path shrinking, use mnm
(defun epe-theme-dakrone ()
  "A eshell-prompt lambda theme with directory shrinking."
  (setq eshell-prompt-regexp "^[^#\nλ]* λ[#]* ")
  (let* ((pwd-repl-home (lambda (pwd)
                          (let* ((home (expand-file-name (getenv "HOME")))
                                 (home-len (length home)))
                            (if (and
                                 (>= (length pwd) home-len)
                                 (equal home (substring pwd 0 home-len)))
                                (concat "~" (substring pwd home-len))
                              pwd))))
         ;; (shrink-paths (lambda (p-lst)
         ;;                 (if (> (length p-lst) 3) ;; shrink paths deeper than 3 dirs
         ;;                     (concat
         ;;                      (mapconcat (lambda (elm)
         ;;                                   (if (zerop (length elm)) ""
         ;;                                     (substring elm 0 1)))
         ;;                                 (butlast p-lst 3)
         ;;                                 "/")
         ;;                      "/"
         ;;                      (mapconcat (lambda (elm) elm)
         ;;                                 (last p-lst 3)
         ;;                                 "/"))
         ;;                   (mapconcat (lambda (elm) elm)
         ;;                              p-lst
         ;;                              "/"))))
         )
    (concat
     (when (epe-remote-p)
       (epe-colorize-with-face
        (concat (epe-remote-user) "@" (epe-remote-host) " ")
        'epe-remote-face))
     (when (and epe-show-python-info (bound-and-true-p venv-current-name))
       (epe-colorize-with-face (concat "(" venv-current-name ") ") 'epe-venv-face))
     ;; (epe-colorize-with-face (funcall
     ;;                          shrink-paths
     ;;                          (split-string
     ;;                           (funcall pwd-repl-home (eshell/pwd)) "/"))
     ;;                         'epe-dir-face)
     (epe-colorize-with-face
      (mnm (eshell/pwd))
      ;; (funcall
      ;;  shrink-paths
      ;;  (eshell/pwd)
      ;;  ;; (split-string
      ;;  ;;  (funcall pwd-repl-home (eshell/pwd)) "/")
      ;;  )
      'epe-dir-face)
     (when (epe-git-p)
       (concat
        (epe-colorize-with-face ":" 'epe-dir-face)
        (epe-colorize-with-face
         (concat (epe-git-branch)
                 (epe-git-dirty)
                 (epe-git-untracked)
                 (unless (= (epe-git-unpushed-number) 0)
                   (concat ":" (number-to-string (epe-git-unpushed-number)))))
         'epe-git-face)))
     (epe-colorize-with-face " λ" 'epe-symbol-face)
     (epe-colorize-with-face (if (= (user-uid) 0) "#" "") 'epe-sudo-symbol-face)
     " ")))

;; Fix eshell-prompt-regexp
(defun epe-theme-lambda ()
  "A eshell-prompt lambda theme."
  ;; (setq eshell-prompt-regexp "^[^#\nλ]*[#λ] ")
  (setq eshell-prompt-regexp "^[^#\nλ]* λ[#]* ")
  (concat
   (when (epe-remote-p)
     (epe-colorize-with-face
      (concat (epe-remote-user) "@" (epe-remote-host) " ")
      'epe-remote-face))
   (let ((env-current-name (or (bound-and-true-p venv-current-name)
                               (bound-and-true-p conda-env-current-name))))
     (when (and epe-show-python-info (bound-and-true-p env-current-name))
       (epe-colorize-with-face (concat "(" env-current-name ") ") 'epe-venv-face)))
   (let ((f (cond ((eq epe-path-style 'fish) 'epe-fish-path)
                  ((eq epe-path-style 'single) 'epe-abbrev-dir-name)
                  ((eq epe-path-style 'full) 'abbreviate-file-name)
                  ((eq epe-path-style 'full-no-abbreviate) 'identity))))
     (epe-colorize-with-face (funcall f (eshell/pwd)) 'epe-dir-face))
   (when (epe-git-p)
     (concat
      (epe-colorize-with-face ":" 'epe-dir-face)
      (epe-colorize-with-face
       (concat (epe-git-branch)
               (epe-git-dirty)
               (epe-git-untracked)
               (let ((unpushed (epe-git-unpushed-number)))
                 (unless (= unpushed 0)
                   (concat ":" (number-to-string unpushed)))))
       'epe-git-face)))
   (epe-colorize-with-face " λ" 'epe-symbol-face)
   (epe-colorize-with-face (if (= (user-uid) 0) "#" "") 'epe-sudo-symbol-face)
   " "))

;; Implementing this function is not easy for me to think about right now
(defun pen-eshell-go-to-start-of-prompt ()
  (interactive)
  (let* ((init-pos (point))
         (is-at-prompt-line (save-excursion
                              (beginning-of-line)
                              (looking-at-p eshell-prompt-regexp)))
         (is-at-prompt-start-position
          (and
           is-at-prompt-line
           (save-excursion
             (pen-comint-eol)
             (pen-comint-bol)
             (eq init-pos (point)))))
         (is-inside-output
          (and
           (not is-at-prompt-line)
           (save-excursion
             (eshell-previous-prompt 1)
             (< (point) init-pos)))))

    ;; (cmd (if is-at-prompt-line
    ;;          "at-prompt-line")
    ;;      (if is-at-prompt-start-position
    ;;          "at-prompt-start-position")
    ;;      (if is-inside-output
    ;;          "inside-output"))

    (cond
     (is-inside-output
      (eshell-previous-prompt 1))
     ((and is-at-prompt-line
           (not is-at-prompt-start-position))
      (pen-comint-bol)))))

(defun pen-eshell-get-directory-for-line ()
  "The prompt should display the directory. Extract it from the prompt that relates to the cursor position."

  (save-excursion
    (pen-eshell-go-to-start-of-prompt)
    (let ((dir
           (progn
             (beginning-of-line)
             (select-font-lock-face-region)
             (if (selected-p)
                 (pen-selected-text)
               default-directory))))
      (deselect)
      (s-remove-trailing-literal ":" dir))))

(defun pen-eshell-get-command-for-line ()
  "Extract the s-cmd that relates to the cursor position."

  (save-excursion
    (pen-eshell-go-to-start-of-prompt)
    (let ((s-cmd
           (progn
             (pen-copy-line)
             (if (selected-p)
                 (pen-selected-text)))))
      (deselect)
      s-cmd)))

(defun pen-eshell-copy-directory-from-prompt ()
  (interactive)
  (let ((dir (umn (pen-eshell-get-directory-for-line))))
    (if dir
        (xc (f-expand dir)
            nil nil "Directory from prompt"))))

(define-key eshell-mode-map (kbd "M-y d") 'pen-eshell-copy-directory-from-prompt)

(defun pen-eshell-copy-directory-and-command-from-prompt ()
  (interactive)
  (let ((dir (umn (pen-eshell-get-directory-for-line)))
        (c (pen-eshell-get-command-for-line)))
    (if dir
        (setq dir (f-expand dir)))
    (xc (format "cd %s; %s"
                (cmd dir)
                c)
        nil nil "Command from prompt")))

;; This is an analog of bash's M-k
(define-key eshell-mode-map (kbd "M-y k") 'pen-eshell-copy-directory-and-command-from-prompt)

(defun pen-eshell-avy-copy-directory-and-command ()
  (interactive)
  (save-excursion
    (if (and (major-mode-p 'minibuffer-mode)
             (ivy-running-p))
        (call-interactively 'ivy-avy)
      (call-interactively 'avy-goto-char))
    (pen-eshell-copy-directory-and-command-from-prompt)))

(define-key eshell-mode-map (kbd "M-y M-k") 'pen-eshell-avy-copy-directory-and-command)

(defun pen-enable-org-link-font-lock-test ()
  (interactive)

  ;; This isn't currently working:
  ;; (font-lock-add-keywords nil nil t)

  ;; This did nothing:
  ;; (font-lock-add-keywords 'eshell-mode nil t)

  ;; This isn't currently working:
  (let* ((lk org-highlight-links)
         (org-link-minor-mode-keywords
          (list
           (if (memq 'tag lk) '(org-activate-tags (1 'org-tag prepend)))
           (if (memq 'angle lk) '(org-activate-angle-links (0 'org-link t)))
           (if (memq 'plain lk) '(org-activate-plain-links (0 'org-link t)))
           (if (memq 'bracket lk) '(org-activate-bracket-links (0 'org-link t)))
           (if (memq 'radio lk) '(org-activate-target-links (0 'org-link t)))
           (if (memq 'date lk) '(org-activate-dates (0 'org-date t)))
           (if (memq 'footnote lk) '(org-activate-footnote-links)))))

    (font-lock-add-keywords nil org-link-minor-mode-keywords t)
    ;; (font-lock-add-keywords 'eshell-mode org-link-minor-mode-keywords t)
    ))

(define-minor-mode org-link-minor-mode
  "Toggle display of org-mode style bracket links in non-org-mode buffers."
  :lighter " org-link"
  :keymap org-link-minor-mode-map
  (let ((lk org-highlight-links)
        org-link-minor-mode-keywords)
    (if (fboundp 'org-activate-links)
        ;; from Org v9.2
        (setq org-link-minor-mode-keywords
              (list
               '(org-activate-links)
               (when (memq 'tag lk) '(org-activate-tags (1 'org-tag prepend)))
               (when (memq 'radio lk) '(org-activate-target-links (1 'org-link t)))
               (when (memq 'date lk) '(org-activate-dates (0 'org-date t)))
               (when (memq 'footnote lk) '(org-activate-footnote-links))))
      (setq org-link-minor-mode-keywords
            (list
             (if (memq 'tag lk) '(org-activate-tags (1 'org-tag prepend)))
             (if (memq 'angle lk) '(org-activate-angle-links (0 'org-link t)))
             (if (memq 'plain lk) '(org-activate-plain-links (0 'org-link t)))
             (if (memq 'bracket lk) '(org-activate-bracket-links (0 'org-link t)))
             (if (memq 'radio lk) '(org-activate-target-links (0 'org-link t)))
             (if (memq 'date lk) '(org-activate-dates (0 'org-date t)))
             (if (memq 'footnote lk) '(org-activate-footnote-links)))))
    (if org-link-minor-mode
        (if (derived-mode-p 'org-mode)
            (progn
              (message "org-mode doesn't need org-link-minor-mode")
              (org-link-minor-mode -1))
          (progn
            ;; This is the problematic line currently:
            (font-lock-add-keywords nil org-link-minor-mode-keywords t)

            (kill-local-variable 'org-mouse-map)
            (setq-local org-mouse-map
                        (let ((map (make-sparse-keymap)))
                          (define-key map [return] 'org-open-at-point)
                          (define-key map [tab] 'org-next-link)
                          (define-key map [backtab] 'org-previous-link)
                          (define-key map [mouse-2] 'org-open-at-point)
                          (define-key map [follow-link] 'mouse-face)
                          map))
            (setq-local font-lock-unfontify-region-function
                        'org-link-minor-mode-unfontify-region)
            (setq-local org-descriptive-links org-descriptive-links)
            (condition-case nil (require 'org-man)
              (error (message "Problems while trying to load feature `org-man'")))
            ;; Set to non-descriptive and then switch to descriptive links
            (setq org-descriptive-links nil)
            (org-toggle-link-display)))
      (unless (derived-mode-p 'org-mode)
        (font-lock-remove-keywords nil org-link-minor-mode-keywords)
        (org-restart-font-lock)
        (remove-from-invisibility-spec '(org-link))
        (kill-local-variable 'org-descriptive-links)
        (kill-local-variable 'org-mouse-map)
        (kill-local-variable 'font-lock-unfontify-region-function)))))

(defun eshell-ls-dir (dirinfo &optional insert-name root-dir size-width)
  "Output the entries in DIRINFO.
If INSERT-NAME is non-nil, the name of DIRINFO will be output.  If
ROOT-DIR is also non-nil, and a directory name, DIRINFO will be output
relative to that directory."
  (let ((dir (car dirinfo)))
    (if (not (cdr dirinfo))
        (funcall error-func (format "%s: No such file or directory\n" dir))
      (if dir-literal
          (eshell-ls-file dirinfo size-width)
        (if insert-name
            (funcall insert-func
                     (eshell-ls-decorated-name
                      (cons (concat
                             (if root-dir
                                 (file-relative-name dir root-dir)
                               (expand-file-name dir)))
                            (cdr dirinfo))) ":\n"))
        (let ((entries (eshell-directory-files-and-attributes
                        dir nil (and (not (or show-all show-almost-all))
                                     eshell-ls-exclude-hidden
                                     "\\`[^.]") t
                                     ;; Asking for UID and GID as
                                     ;; strings saves another syscall
                                     ;; later when we are going to
                                     ;; display user and group names.
                        (if numeric-uid-gid 'integer 'string))))
          (when (and show-almost-all
                     (not show-all))
            (setq entries
                  (cl-remove-if
                   (lambda (entry)
                     (member (car entry) '("." "..")))
                   entries)))
          (when (and (not (or show-all show-almost-all))
                     eshell-ls-exclude-regexp)
            (while (and entries (string-match eshell-ls-exclude-regexp
                                              (caar entries)))
              (setq entries (cdr entries)))
            (let ((e entries))
              (while (cdr e)
                (if (string-match eshell-ls-exclude-regexp (car (cadr e)))
                    (setcdr e (cddr e))
                  (setq e (cdr e))))))
          (when (or (eq listing-style 'long-listing) show-size)
            (let ((total 0.0))
              (setq size-width 0)
              (dolist (e entries)
                (if (file-attribute-size (cdr e))
                    (setq total (+ total (file-attribute-size (cdr e)))
                          size-width
                          (max size-width
                               (length (eshell-ls-printable-size
                                        (file-attribute-size (cdr e))
                                        (not
                                         ;; If we are under -l, count length
                                         ;; of sizes in bytes, not in blocks.
                                         (eq listing-style 'long-listing))))))))
              (funcall insert-func "total "
                       (eshell-ls-printable-size total t) "\n")))
          (let ((default-directory (expand-file-name dir)))
            (if show-recursive
                (eshell-ls-entries
                 (let ((e entries) (good-entries (list t)))
                   (while e
                     (unless (let ((len (length (caar e))))
                               (and (eq (aref (caar e) 0) ?.)
                                    (or (= len 1)
                                        (and (= len 2)
                                             (eq (aref (caar e) 1) ?.)))))
                       (nconc good-entries (list (car e))))
                     (setq e (cdr e)))
                   (cdr good-entries))
                 nil root-dir)
              (eshell-ls-files (eshell-ls-sort-entries entries)
                               size-width))))))))

(defun eshell-ls-files (files &optional size-width copy-fileinfo)
  "Output a list of FILES.
Each member of FILES is either a string or a cons cell of the form
\(FILE .  ATTRS)."
  ;; Mimic behavior of coreutils ls, which lists a single file per
  ;; line when output is not a tty.  Exceptions: if -x was supplied,
  ;; or if we are the _last_ command in a pipeline.
  ;; FIXME Not really the same since not testing output destination.
  (if (or (and eshell-in-pipeline-p
               (not (eq eshell-in-pipeline-p 'last))
               (not (eq listing-style 'by-lines)))
          (memq listing-style '(long-listing single-column)))
      (dolist (file files)
        (if file
            (eshell-ls-file file size-width copy-fileinfo)))
    (let ((f files)
          last-f
          display-files) ;; ignore
      (while f
        (if (cdar f)
            (setq last-f f
                  f (cdr f))
          (unless nil ;; ignore
            (funcall error-func
                     (format "%s: No such file or directory\n" (caar f))))
          (if (eq f files)
              (setq files (cdr files)
                    f files)
            (if (not (cdr f))
                (progn
                  (setcdr last-f nil)
                  (setq f nil))
              (setcar f (cadr f))
              (setcdr f (cddr f))))))
      (if (not show-size)
          (setq display-files (mapcar #'eshell-ls-annotate files))
        (dolist (file files)
          (let* ((str (eshell-ls-printable-size (file-attribute-size (cdr file)) t))
                 (len (length str)))
            (if (< len size-width)
                (setq str (concat (make-string (- size-width len) ? ) str)))
            (setq file (eshell-ls-annotate file)
                  display-files (cons (cons (concat str " " (car file))
                                            (cdr file))
                                      display-files))))
        (setq display-files (nreverse display-files)))
      (let* ((col-vals
              (if (eq listing-style 'by-columns)
                  (eshell-ls-find-column-lengths display-files)
                (cl-assert (eq listing-style 'by-lines))
                (eshell-ls-find-column-widths display-files)))
             (col-widths (car col-vals))
             (display-files (cdr col-vals))
             (columns (length col-widths))
             (col-index 1)
             need-return)
        (dolist (file display-files)
          (let ((name
                 (if (car file)
                     (if show-size
                         (concat (substring (car file) 0 size-width)
                                 (eshell-ls-decorated-name
                                  (cons (substring (car file) size-width)
                                        (cdr file))))
                       (eshell-ls-decorated-name file))
                   "")))
            (if (< col-index columns)
                (setq need-return
                      (concat need-return name
                              (make-string
                               (max 0 (- (aref col-widths
                                               (1- col-index))
                                         (length name)))
                               ;; This was strange in the original code
                               ;; ?)
                               (string-to-char " ")))
                      col-index (1+ col-index))
              (funcall insert-func need-return name "\n")
              (setq col-index 1 need-return nil))))
        (if need-return
            (funcall insert-func need-return "\n"))))))

(provide 'pen-eshell)
