;; Some things should not be loaded
(pen-require 'pen-selected)

(require 'evil-surround)
(global-evil-surround-mode 1)
(require 'auto-highlight-symbol)

(defun pen-copy-line (&optional arg)
  "arg is C-u, if provided"
  (interactive "P")
  (if (region-active-p)
      (progn
        (execute-kbd-macro (kbd "M-w"))
        (pen-ns (yanked) t)
        (deactivate-mark))
    (progn
      (if (equal current-prefix-arg nil) ;; No C-u
          (progn
            (end-of-line)
            (call-interactively 'cua-set-mark)
            (beginning-of-line-or-indentation)
            (beginning-of-line-or-indentation)
            (call-interactively 'cua-exchange-point-and-mark))
        (progn
          (pen-comint-bol)
          (cua-set-mark)
          (end-of-line))))))

(defun pen-copy-line-evil-normal ()
  (interactive)
  (if (region-active-p)
      (progn
        (execute-kbd-macro (kbd "y"))
        (deactivate-mark))
    (progn
      (end-of-line)
      (execute-kbd-macro (kbd "v ^ y"))
      (end-of-line)
      (execute-kbd-macro (kbd "v ^")))))

(defun pen-vim-star ()
  "This is vim's * operator."
  (interactive)
  (if (region-active-p)
      (progn
        (ahs-forward)
        (ahs-backward))))

(defun CP (new-file-name)
  "Creates a copy of the file connected to the current buffer's file with the new name new-file-name."
  (interactive)
  (let ((lcmd `(b cp -a ,(buffer-file-path) ,(concat (buffer-file-dir) "/" new-file-name))))
    (eval lcmd)
    (message (str lcmd))))

(defun evil-enabled ()
  "True if in evil mode. Spacemacs agnostic."
  ;; Keep in mind that evil-mode is enabled when emacs is in holy mode. I have to also check if we are spacemacs

  ;; Keep this, even for pen. Otherwise selected will break on the host
  (if (fboundp 'spacemacs/toggle-holy-mode-p)
      (not (spacemacs/toggle-holy-mode-p))
    (minor-mode-enabled evil-mode)))

(defmacro do-in-evil (body)
  "This will execute the emacs lisp in evil-mode. It will switch to evil-mode temporarily if it's not enabled."
  `(let ((inhibit-quit t))
     (try
      (if (not (evil-enabled))
          (progn
            (pen-enable-evil)
            (try
             (progn
               (cond ((eq evil-state 'visual)
                      nil)
                     ((eq evil-state 'normal)
                      (if mark-active
                          (evil-visual-state)))
                     ((eq evil-state 'insert)
                      nil
                      ))
               (with-local-quit (,@body)))
             nil)
            (pen-disable-evil)
            nil)
        (progn (,@body) nil))
      nil)))

(defalias 'progn-evil 'do-in-evil)

(defun pen-toggle-evil ()
  (interactive)
  "Tries Holy Mode + falls back to evil"
  (save-mark-and-excursion
    (if (or (evil-visual-state-p)
            (evil-insert-state-p))
        (call-interactively 'evil-normal-state))
    (call-interactively #'evil-mode)
    (fix-region)))

(defun pen-enable-evil ()
  (interactive)
  (save-mark-and-excursion
    (evil-mode 1)))

(defun pen-disable-evil ()
  (interactive)
  (save-mark-and-excursion
    (evil-mode -1)))

(defalias 'evil-goto-last-line 'evil-goto-line)

;; These should be complete if in insert mode

(defun evil-ex-normal ()
  (interactive)
  (evil-normal-state)
  (evil-ex))

(defun evil-eval-expression ()
     (interactive)
     (eval-expression))

(defun pen-c-g-test ()
  "test catching control-g"
  (interactive)
  (let ((inhibit-quit t))
    (unless (with-local-quit
              (y-or-n-p "arg you gonna type C-g?")
              t)
      (progn
        (message "you hit C-g")
        (setq quit-flag nil)))))

;; Beep minibuffer
(defun pen-enter-evil-ex ()
  (interactive)
  (if (region-active-p)
      (do-in-evil
       (evil-ex "'<,'>"))
    (do-in-evil
     (evil-ex ""))))

(defmacro insert-map (KEYS fun)
  (setq fun (eval fun))
  ;; An insert mapping creates a function that goes to normal
  `(progn (defun ,(intern (concat "pen-evil-" (symbol-name fun) "-normal")) ()
            (interactive)
            (evil-normal-state)
            (deactivate-mark)
            (call-interactively ',fun))
          (define-key evil-insert-state-map (kbd ,KEYS) ',(intern (pen-concat "pen-evil-" (symbol-name fun) "-normal")))))

(defmacro normal-map (KEYS fun)
  (setq fun (eval fun))
  ;; A normal mapping creates a function that unmarks
  `(progn (defun ,(intern (concat "pen-evil-" (symbol-name fun) "-unmark")) ()
            (interactive)
            ;; Why was this deactivated?
            (if (evil-visual-state-p)
                (deactivate-mark))
            (call-interactively ',fun))
          (define-key evil-normal-state-map (kbd ,KEYS) ',(intern (pen-concat "pen-evil-" (symbol-name fun) "-unmark")))))

(defmacro visual-map (KEYS fun)
  (setq fun (eval fun))
  ;; A normal mapping creates a function that unmarks
  `(progn (defun ,(intern (concat "pen-evil-" (symbol-name fun) "-visual")) ()
            (interactive)
            (call-interactively ',fun))
          (define-key evil-visual-state-map (kbd ,KEYS) ',(intern (pen-concat "pen-evil-" (symbol-name fun) "-visual")))))

(evil-define-motion evil-visual-corner-start ()
  "Put the cursor at the top left part of the block"
  (let* ((point (point))
         (mark (or (mark t) point)))

    (if (> point mark)
        ;; (and (eq evil-visual-selection 'line) (> point mark))
        (evil-visual-exchange-corners))))

(defmacro visual-to-normal-map (KEYS fun)
  (setq fun (eval fun))
  ;; A normal mapping creates a function that unmarks
  `(progn (defun ,(intern (concat "pen-evil-" (symbol-name fun) "-visual")) ()
            (interactive)
            (let* ((point (point))
                   (mark (or (mark t) point)))

              (if (and (eq evil-visual-selection 'line) (> point mark))
                  (progn
                    (evil-normal-state)
                    (evil-backward-char 1))
                (evil-normal-state))

              (call-interactively ',fun)
              (define-key evil-visual-state-map (kbd ,KEYS) ',(intern (pen-concat "pen-evil-" (symbol-name fun) "-visual")))))))

(defmacro pen-truly-evil-binding (KEYS fun)
  "This creates 2 new vim-like functions for both insert and a normal mode on a given keybinding."
  `(progn
     (normal-map ,KEYS ,fun)
     (insert-map ,KEYS ,fun)
     (visual-to-normal-map ,KEYS ,fun)))

(defmacro pen-truly-selective-binding (KEYS fun)
  "This binds both selected and evil visual mode keybindings"
  `(progn
     ;; Do visual maps even work?
     (visual-map ,(pen-sed "s/\\b\\w\\+\\b/M-&/g" KEYS)
                 ,fun)
     (define-key selected-keymap (kbd ,KEYS) ,fun)))

(defmacro pen-truly-evil-ekm (KEYS)
  (let ((ekm-name (bp slugify KEYS)))
    `(progn
       (pen-truly-evil-binding "M-:" 'eval-expression)
       )))

(pen-truly-selective-binding "P" (df pb-region () (bp-tty pb (pen-selected-text)) (deactivate-mark)))

(defun spv-egr (query)
  (interactive (list (or (pen-selected-text)
                         (read-string "egr:"))))
  (pen-spv
   (concat "egr " query))
  (deactivate-mark))
(defalias 'egr 'spv-egr)

(df spv-sx-code () (pen-spv (concat "sx " (buffer-language) " " (pen-selected-text))) (deactivate-mark))

(defun pen-evil-insert-normal-kbd (binding)
  "Annoyingly, this must be called with a complete mapping. Can't simply press d once."
  (interactive)
  (evil-normal-state)
  (tm/send-keys-literal binding))

(eval-after-load 'evil-vars
  '(define-key evil-ex-completion-map (kbd "C-m") 'exit-minibuffer))

(defun evil-mark-from-point-to-end-of-line ()
  "Marks everything from point to end of line"
  (interactive)
  (set-mark (line-end-position))
  (activate-mark))

(defun evil-visual-copy ()
  "Marks everything from point to end of line"
  (interactive)
  (call-interactively 'evil-yank)
  (chomp (pen-ns (clipboard))))

(defun magit-dp (arg)
  "Uses magit to diff the revisions of this file"
  (interactive "P")
  (cond
   ((equal current-prefix-arg nil)      ; no C-u
    (magit-ediff-show-commit "HEAD^!"))
   (t                                   ; all other cases, prompt
    (list
     (magit-ediff-show-commit (concat "HEAD~" (number-to-string current-prefix-arg)))))))

(defun git-dp (arg)
  "Uses vimdiff to diff the revisions of this file"
  (interactive "P")
  (if
      (equal current-prefix-arg nil)    ; no C-u
      (pen-nw (concat "git-dp.sh" " " buffer-file-name))
    (pen-nw (concat "git-dp.sh" " " buffer-file-name " " (number-to-string current-prefix-arg)))))

(defun describe-this-file ()
  (interactive)
  (pen-spv (pen-concat "ct describe-file " (pen-q buffer-file-name) " | v")))

(defun pen-evil-ge ()
  (interactive)
  (bld ge -e -v (pen-selected-text)))

(defun pen-expand-lines ()
  (interactive)
  (let ((hippie-expand-try-functions-list
         '(try-expand-line-all-buffers)))
    (call-interactively 'hippie-expand)))

(defun pen-rename-file-and-buffer (newname cp)
  "Rename current buffer and if the buffer is visiting a file, rename it too."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if cp
        (if (and filename (file-exists-p filename))
            (let* ((containing-dir (file-name-directory newname)))
            (if containing-dir (make-directory containing-dir t))
            (copy-file filename newname t)
            (find-file newname)))
      (if (not (and filename (file-exists-p filename)))
            (rename-buffer newname)

          (let* ((containing-dir (file-name-directory newname)))
            (if containing-dir (make-directory containing-dir t))
            (cond
             ((vc-backend filename) (vc-rename-file filename newname))
             (t
              (rename-file filename newname t)
              (set-visited-file-name newname t t))))))))

(evil-define-command evil-rename (file &optional bang)
  "Rename FILE."
  :repeat nil
  (interactive "<f><!>")
  ;; Interactive sets 'bang' to 't' or 'nil'
  (save-buffer)
  ;; (error "Whoops!")

  (if bang
      (progn
        ;; overwrite
        (pen-rename-file-and-buffer file))
    (progn
      ;; do not overwrite
      (if (not (file-exists-p file))
          (pen-rename-file-and-buffer file)
        (message (concat "Aborted. File exists: " file))))))

(evil-ex-define-cmd "Rename" 'evil-rename)

(evil-define-command evil-open (fp &optional bang)
  "Open FILE."
  :repeat nil
  (interactive "<f><!>")

  (if (not fp)
      (setq fp (xc)))

  (setq eww-no-external-handler nil)
  (cond
   ((string-match "^http" fp) (eww fp))
   ((string-match "\\.html$" fp) (eww-open-file fp))
   (t (find-file (tv fp)))))

(evil-ex-define-cmd "O" 'evil-open)

(evil-define-command evil-dired (dir &optional bang)
  "Open DIR with dired."
  :repeat nil
  (interactive "<f><!>")

  (if (not dir)
      (setq dir (xc)))

  (let ((path
         (cond ((f-file-p dir) (setq path (f-dirname dir)))
               ((f-directory-p dir) dir)
               (t nil))))
    (if path
        (dired path))))

(evil-ex-define-cmd "Dired" 'evil-dired)

(evil-define-command evil-cp (file &optional bang)
  "Cp FILE."
  :repeat nil
  (interactive "<f><!>")
  ;; Interactive sets 'bang' to 't' or 'nil'
  (save-buffer)
  ;; (error "Whoops!")

  (if bang
      (progn
        ;; overwrite
        (pen-rename-file-and-buffer file t))
    (progn
      ;; do not overwrite
      (if (not (file-exists-p file))
          (pen-rename-file-and-buffer file t)
        (message (concat "Aborted. File exists: " file))))))
(evil-ex-define-cmd "CP" 'evil-cp)

(evil-define-command evil-vw (fp &optional bang)
  "Edit FP on path."
  :repeat nil
  (interactive "<f><!>")
  ;; Interactive sets 'bang' to 't' or 'nil'

  ;; If bang then just edit fp which is here.
  (if bang
      (find-fp fp)
    (pen-edit-fp-on-path fp)))
(evil-ex-define-cmd "vw" 'evil-vw)
(evil-ex-define-cmd "ew" 'evil-vw)

(evil-define-command evil-bd (&optional bang)
  "Kill buffer."
  :repeat nil
  (interactive "<!>")

  (if bang
      (kill-buffer)
    (pen-kill-buffer-immediately)))
(evil-ex-define-cmd "bd" 'evil-bd)

(evil-define-command evil-other-file ()
  "Go to other file."
  :repeat nil
  (interactive)
  (call-interactively 'ff-get-other-file))
(evil-ex-define-cmd "A" 'evil-other-file)

(advice-remove 'evil-ex-execute #'evil-ex-execute-around-advice)

(defun evil-ex-execute (result)
  "Execute RESULT as an ex command on `evil-ex-current-buffer'."
  (when (zerop (length result))
    (setq result evil-ex-previous-command))
  (setq result (pen-umn result))
  (evil-ex-update nil nil nil result)
  (unless (zerop (length result))
    (if evil-ex-expression
        (eval evil-ex-expression)
      (user-error "Ex: syntax error"))))

(if nil (progn
          (advice-add 'evil-forward-word-begin :after #'pen-doc-thing-at-point)
          (advice-add 'evil-backward-word-begin :after #'pen-doc-thing-at-point)
          (advice-add 'evil-next-line :after #'pen-doc-thing-at-point)
          (advice-add 'evil-previous-line :after #'pen-doc-thing-at-point)
          (advice-add 'evil-end-of-line :after #'pen-doc-thing-at-point)
          ))

(if nil (progn
          (advice-remove 'evil-forward-word-begin #'pen-doc-thing-at-point)
          (advice-remove 'evil-backward-word-begin #'pen-doc-thing-at-point)
          (advice-remove 'evil-next-line #'pen-doc-thing-at-point)
          (advice-remove 'evil-previous-line #'pen-doc-thing-at-point)
          (advice-remove 'evil-end-of-line #'pen-doc-thing-at-point)))

(setq evil-digraphs-table-user '(((?N ?N) . ?\x2115)
                                 ((?Z ?Z) . ?\x2124)
                                 ((?R ?R) . ?\x211D)
                                 ((?^ ?_) . ?\x304)
                                 ((?. ?o) . ?\x25cc)
                                 ;; 𝑥
                                 ((?x ?m) . ?\x1D465)
                                 ;; 𝑖
                                 ((?i ?m) . ?\x1D456)
                                 ((?  ? ) . ?\x00a0)
                                 ((?| ?=) . ?\x22a7)
                                 ((?| ?-) . ?\x22a2)
                                 ((?| ?>) . ?\x21a6)
                                 ;; looking glass
                                 ((?l ?g) . ?\x1F50D)
                                 ;; huggingface
                                 ((?h ?f) . ?\x1F917)
                                 ;; spacy (ringed planet)
                                 ((?s ?y) . ?\x1fa90)

                                 ;; 𔒯 janus
                                 ((?j ?n) . ?\x144AF)

                                 ;; ⇌ reversible
                                 ((?r ?v) . ?\x21CC)

                                 ;; 🖊 pen
                                 ((?p ?n) . ?\x1F58A)

                                 ;; ⚔ swords
                                 ((?s ?w) . ?\x2694)

                                 ;; ⚔ surreptitious strawberry
                                 ((?s ?t) . ?\x1f353)

                                 ;; ࿋ trichotomy
                                 ((?s ?f) . ?\x0FCB)

                                 ;; 💡 lightbulb
                                 ((?l ?b) . ?\x1F4A1)

                                 ;; 🐈 cat
                                 ((?c ?a) . ?\x1F408)

                                 ;; 👍
                                 ((?l ?i) . ?\x1F44D)

                                 ;; 👎
                                 ((?d ?l) . ?\x1F44E)

                                 ;; ☕
                                 ((?c ?o) . ?\x2615)

                                 ((?r ?e) . ?\x211D)))

(defun evil-get-register (register &optional noerror)
  "Return contents of REGISTER.
Signal an error if empty, unless NOERROR is non-nil.

The following special registers are supported.
  \"  the unnamed register
  *  the clipboard contents
  +  the clipboard contents
  <C-w> the word at point (ex mode only)
  <C-a> the WORD at point (ex mode only)
  <C-o> the symbol at point (ex mode only)
  <C-f> the current file at point (ex mode only)
  %  the current file name (read only)
  #  the alternate file name (read only)
  /  the last search pattern (read only)
  :  the last command line (read only)
  .  the last inserted text (read only)
  -  the last small (less than a line) delete
  _  the black hole register
  =  the expression register (read only)"
  (condition-case err
      (when (characterp register)
        (or (cond
             ((eq register ?\")
              (current-kill 0))
             ((and (<= ?1 register) (<= register ?9))
              (let ((reg (- register ?1)))
                (and (< reg (length kill-ring))
                     (current-kill reg t))))
             ((memq register '(?* ?+))
              (pen-clipboard-string))
             ((eq register ?\C-W)
              (unless (evil-ex-p)
                (user-error "Register <C-w> only available in ex state"))
              (with-current-buffer evil-ex-current-buffer
                (thing-at-point 'evil-word)))
             ((eq register ?\C-A)
              (unless (evil-ex-p)
                (user-error "Register <C-a> only available in ex state"))
              (with-current-buffer evil-ex-current-buffer
                (thing-at-point 'evil-WORD)))
             ((eq register ?\C-O)
              (unless (evil-ex-p)
                (user-error "Register <C-o> only available in ex state"))
              (with-current-buffer evil-ex-current-buffer
                (thing-at-point 'evil-symbol)))
             ((eq register ?\C-F)
              (unless (evil-ex-p)
                (user-error "Register <C-f> only available in ex state"))
              (with-current-buffer evil-ex-current-buffer
                (thing-at-point 'filename)))
             ((eq register ?%)
              (or (buffer-file-name (and (evil-ex-p)
                                         (minibufferp)
                                         evil-ex-current-buffer))
                  (user-error "No file name")))
             ((= register ?#)
              (or (with-current-buffer (other-buffer) (buffer-file-name))
                  (user-error "No file name")))
             ((eq register ?/)
              (or (car-safe
                   (or (and (boundp 'evil-search-module)
                            (eq evil-search-module 'evil-search)
                            evil-ex-search-history)
                       (and isearch-regexp regexp-search-ring)
                       search-ring))
                  (user-error "No previous regular expression")))
             ((eq register ?:)
              (or (car-safe evil-ex-history)
                  (user-error "No previous command line")))
             ((eq register ?.)
              evil-last-insertion)
             ((eq register ?-)
              evil-last-small-deletion)
             ((eq register ?=)
              (let* ((enable-recursive-minibuffers t)
                     (result (eval (car (read-from-string (read-string "="))))))
                (cond
                 ((or (stringp result)
                      (numberp result)
                      (symbolp result))
                  (prin1-to-string result))
                 ((sequencep result)
                  (mapconcat #'prin1-to-string result "\n"))
                 (t (user-error "Using %s as a string" (type-of-of-of-of result))))))
             ((eq register ?_)          ; the black hole register
              "")
             (t
              (setq register (downcase register))
              (get-register register)))
            (user-error "Register `%c' is empty" register)))
    (error (unless err (signal (car err) (cdr err))))))

(require 'helm-projectile)

(defun evil-command-window-close ()
  "Like evil-command-window-execute but runs an empty command and closes the window gracefully."
  (interactive)
  (let ((execute-fn evil-command-window-execute-fn)
        (command-window (get-buffer-window)))
    (select-window (previous-window))
    (unless (equal evil-command-window-current-buffer (current-buffer))
      (user-error "Originating buffer is no longer active"))
    (kill-buffer "*Command Line*")
    (delete-window command-window)
    (funcall execute-fn "")
    (setq evil-command-window-current-buffer nil)))

;; C++ stuff
(evil-define-key 'normal c++-mode-map (kbd ", v f") 'mark-defun)

(ignore-errors (ad-remove-advice 'set-window-buffer 'before 'evil))

(defadvice set-window-buffer (before evil)
  "Initialize Evil in the displayed buffer."
  (ignore-errors
    (when evil-mode
      (when (and
             (ad-get-arg 1)
             (get-buffer (ad-get-arg 1)))
        (with-current-buffer (ad-get-arg 1)
          (unless evil-local-mode
            (evil-local-mode 1)))))))

(ad-update 'set-window-buffer)

(defun fix-region ()
  (interactive)
  (with-current-buffer (nbfs "test")
    (if (not (and (region-active-p)
                mark-active))
      (progn
        (evil-active-region 1)
        (deactivate-mark)))
    (kill-buffer)))

(defun evil-global-marker-p (char)
  "Whether CHAR denotes a global marker."
  (or (and (>= char ?a) (<= char ?z))
      (assq char (default-value 'evil-markers-alist))))

(evil-define-command evil-ead (pattern)
  "Ead pattern."
  :repeat nil
  (interactive "<f>")
  (ead pattern))

(evil-ex-define-cmd "Ead" 'evil-ead)
(evil-ex-define-cmd "ead" 'evil-ead)

(provide 'pen-evil)
