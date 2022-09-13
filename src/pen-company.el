(require 'handle)
(require 'company-try-hard)

;; This is supposed to disable the automatic selection (and disappearance of completions list) of a completion candidate
;; But it doesn't seem to have affected deep tabnine
(setq company-auto-complete nil)
(setq company-auto-complete-chars '())
(setq company-minimum-prefix-length 0)

(defun pen-company-grab-symbol ()
  (buffer-substring (point) (save-excursion (skip-syntax-backward "w_.")
                                            (point))))

(defun pen-company-filetype--prefix ()
  "Grab prefix at point."
  (or (pen-company-grab-symbol)
      'stop))

(defun pen-company-filetype (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))

  (if (not company-mode)
      (company-mode 1))

  (never (let ((results
                (cl-case command
                  (is-interactive (company-begin-backend 'pen-company-filetype))
                  (prefix (pen-company-filetype--prefix))
                  (candidates (pen-company-filetype--candidates arg)))))
           ;; Can't use be user-error. Must be error, to be handled
           (if results
               results
             (error "Cannot complete at point"))))

  (cl-case command
           (is-interactive (company-begin-backend 'pen-company-filetype))
           (prefix (pen-company-filetype--prefix))
           (candidates (pen-company-filetype--candidates arg))))

(defun pen-company-filetype-if-prefix (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (let ((current-prefix-arg nil))
        (progn
          (if (not company-mode)
              (company-mode 1))

          (cl-case command
            (is-interactive (company-begin-backend 'pen-company-filetype))
            (prefix (pen-company-filetype--prefix))
            (candidates (pen-company-filetype--candidates arg)))))
    (error "Fallthrough")))

(defun pen-company-filetype-line (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (pen-company-filetype command arg))

(defun pen-company-filetype-words (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (let ((current-prefix-arg '(64)))
    (pen-company-filetype command arg)))

(defun pen-company-filetype-word (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (let ((current-prefix-arg '(16)))
    (pen-company-filetype command arg)))

(defun pen-company-filetype-long (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (let ((current-prefix-arg '(4)))
    (pen-company-filetype command arg)))

(defset pen-company-all-backends
  '(
    ;; pf-generic-file-type-completion/2
    ;; pf-generic-completion-200-tokens-max/1
    ;; pf-generic-completion-50-tokens/1
    ;; pf-shell-bash-terminal-command-completion/1
    pen-company-filetype-if-prefix
    ;; company-complete

    ;; LSP complete is more important than tabnine
    company-lsp
    
    ;; Continue using tabnine -- it's really good, actually.
    ;; But dodgy.
    company-tabnine

    company-yasnippet
    ;; pen-complete-long
    company-org-block
    company-dabbrev
    
    ;; This is self-referential
    ;; pen-company-filetype
    ))

(setq company-backends pen-company-all-backends)

(defset pen-company-selected-backends '(pen-company-filetype))

;; TODO: Encode where the text came from into the emacs buffer using emacs text properties
(defun pen-company-complete ()
  (interactive)

  (never (let ((company-backends pen-company-all-backends))
           (if (equal (length company-backends) 1)
               (message (str (car company-backends))))

           ;; Try each one until failure, like handle
           ;; Use j:handle--command-execute
           ;; (call-interactively 'company-complete)
           ;; (handle--command-execute (append company-backends (list 'hippie-expand)) current-prefix-arg)
           (handle--command-execute company-backends current-prefix-arg)
           ;; (handle--command-execute (list 'hippie-expand) current-prefix-arg)
           ))
  (call-interactively 'company-try-hard))

(defun pen-company-complete-choose ()
  (interactive)

  (setq pen-company-selected-backends
        (list
         (intern (fz pen-company-all-backends
                     nil nil "pen-company-complete select:"))))
  (setq company-backends (-uniq (cons 'pen-company-filetype-if-prefix (cons (car pen-company-selected-backends) pen-company-all-backends)))))

(defun pen-company-complete-add ()
  (interactive)

  (setq pen-company-selected-backends
        (-uniq
         (cons
          (intern (fz pen-company-all-backends
                      nil nil "pen-company-complete add:"))
          pen-company-selected-backends))))

(defun company-copy-current ()
  "Copy the currently highlighted candidate."
  (interactive)
  (let ((other-window-scroll-buffer)
        (selection (or company-selection 0)))
    (company--electric-do
      (let* ((selected (nth selection company-candidates)))
        (xc selected)))))

;; This ameliorates the problem with company tabnine not allowing you to enter space.
;; However, company still exits.
(setq company-require-match nil)
(setq company-idle-delay 0)
(setq company-show-numbers t)

;; The issue with the space is the backend 'prefix'.
;; To test this, place the cursor after a space and run (company-tabnine--prefix)

;; Can play around with it like this:

;; (company-tabnine-query)
;; (tv company-tabnine--response)

;; Or simply: (company-tabnine--prefix)

(defun company-delete-backward-char-and-retry ()
  (interactive)
  (call-interactively 'delete-backward-char)
  (call-interactively 'company-try-hard)
  ;; (call-interactively 'company-tabnine)
  )

(defun company-self-insert-and-retry ()
  (interactive)
  (call-interactively 'self-insert-command)
  (call-interactively 'company-try-hard)
  ;; (call-interactively 'company-tabnine)
  )

;; This makes TabNine autocomplete a lot more fluid
(defun company-typing-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    res)
  (if (company--active-p)
      ;; (call-interactively 'company-tabnine)
    (call-interactively 'company-try-hard)
    ;; (call-interactively 'company-self-insert-and-retry)
    ))
;; (advice-add 'lispy-tick :around #'company-typing-around-advice)
(advice-add 'lispy-quotes :around #'company-typing-around-advice)
;; (advice-add 'lispy-space :around #'company-typing-around-advice)
(advice-add 'lispy-colon :around #'company-typing-around-advice)

(advice-remove 'lispy-tick #'company-typing-around-advice)
;; (advice-remove 'lispy-quotes #'company-typing-around-advice)
;; (advice-remove 'lispy-space #'company-typing-around-advice)
;; (advice-remove 'lispy-colon #'company-typing-around-advice)

(advice-add 'self-insert-command :around #'company-typing-around-advice)

(advice-add 'company-try-hard :around #'shut-up-around-advice)

;; Doesn't seem to work
(advice-add 'company-complete-quick-access :around #'company-typing-around-advice)

(provide 'pen-company)
