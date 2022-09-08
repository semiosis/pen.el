(require 'handle)
(require 'company-try-hard)

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

    ;; Continue using tabnine -- it's really good, actually
    company-tabnine

    company-yasnippet
    company-lsp
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

(define-key company-active-map (kbd "C-z") #'company-try-hard)

(defun pen-company-complete-choose ()
  (interactive)

  (setq pen-company-selected-backends
        (list
         (intern (fz pen-company-all-backends
                     nil nil "pen-company-complete select:")))))

(defun pen-company-complete-add ()
  (interactive)

  (setq pen-company-selected-backends
        (-uniq
         (cons
          (intern (fz pen-company-all-backends
                      nil nil "pen-company-complete add:"))
          pen-company-selected-backends))))

(provide 'pen-company)
