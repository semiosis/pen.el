;; (require 'pen-utils)
;; (require 'pen-engine-mode)
;; (require 'go-mode)

(defun clj-rebel-doc (func)
  (interactive (list (read-string-hist "clj-rebel-doc: " (pen-thing-at-point))))
  (pen-sps (pen-cmd "clj-rebel-doc" func)))

(defset pen-doc-funcs '(pen-doc-thing-at-point-immediate
                       pen-type-search-thing-at-point-immediate
                       pen-src-thing-at-point
                       pen-grep-for-thing-select
                       handle-docs
                       clj-rebel-doc))

(defun fz-run-doc-func ()
  (interactive)
  (let ((f (fz pen-doc-funcs nil nil "fz-run-doc-func: ")))
    (if (sor f)
        (call-interactively (intern f)))))
(define-key global-map (kbd "M-7") 'fz-run-doc-func)

(defmacro pen-def-lang-doc-engine (lang)
  (setq lang (str (eval lang)))
  `(defengine ,(intern (concat "google-" lang))
     ,(concat "http://www.google.com/search?ie=utf-8&oe=utf-8&q=" (construct-google-query lang 'lang) "+%s")
     :browser 'eww-browse-url))

(defun search-google-for-doc (&optional symstring lang)
  "Do an I'm feeling lucky lookup for documentation on this thing"
  (interactive (list
                (str (if mark-active
                         (pen-selected-text)
                       (sexp-at-point)))
                (current-lang)))

  (if (not lang)
      (setq lang (current-lang)))

  (if (not symstring)
      (setq symstring (str (sexp-at-point))))

  (if (string-equal lang "fundamental")
      (setq lang (detect-language)))

  (if (string-equal lang "eww")
      (setq lang ""))

  (cond ((string-equal lang "fundamental") (message "%s" symstring))
        (t (progn
             (let ((keywords symstring))
               (if (> (length lang) 0)
                   (setq keywords (concat keywords " " (pen-q lang))))

               (pen-sph (concat "egr +/" (pen-q symstring) " " keywords) "")
               (message "%s" (concat "no doc handler for " lang ". searching google")))))))

(defun google-for-docs (&optional lang query)
  (interactive (list (buffer-language)
                     (str (if mark-active (pen-selected-text) (str (sexp-at-point))))))
  (let* ((lang (or lang (buffer-language)))
         (query (or query (if mark-active (pen-selected-text) (str (sexp-at-point))))))

    (pen-sph (concat "google-for-docs " (pen-q lang) " " (pen-q query)) "")))

;; M-6
(defun doc/lookup-ask (query)
  "docstring"
  (interactive "P"))

(defun pen-doc (&optional thing winfunc)
  "Show doc for thing given. winfunc = 'spv or 'sph elisp function"
  (interactive (list
                (if mark-active
                    (pen-selected-text)
                  (read-string "query:"))
                "spv"))

  (if (not winfunc)
      (setq winfunc 'sph))

  (if (not thing)
      (setq thing (sexp-at-point)))

  (cond
   ((string-equal (preceding-sexp-or-element) "#lang")
    (pen-racket-lang-doc (str thing) winfunc))

   ((derived-mode-p 'haskell-mode)
    (progn (hoogle thing t)))
   
   ((derived-mode-p 'lisp-mode)
    (progn (slime-hyperspec-lookup (str thing))))

   ((derived-mode-p 'racket-mode)
    (progn (pen-tvipe "hi") (pen-racket-doc winfunc thing) (deactivate-mark)))

   ((derived-mode-p 'emacs-lisp-mode)
    (describe-function (intern thing)))

   (t (search-google-for-doc thing))))
(defalias 'pen-doc-ask 'pen-doc)

(defun pen-doc-thing-at-point (arg &optional winfunc)
  "Show doc for thing under pointl. winfunc = 'spv or 'sph elisp function"
  (interactive "P")

  (if (not winfunc)
      (setq winfunc 'sph))

  (cond
   ((string-equal (preceding-sexp-or-element) "#lang")
    (pen-racket-lang-doc (str (sexp-at-point)) winfunc))

   ((derived-mode-p 'racket-mode)
    (progn
      (pen-racket-doc winfunc)
      (deactivate-mark)))

   ((derived-mode-p 'lisp-mode)
    (call-interactively 'slime-documentation))

   ((or (derived-mode-p 'go-mode)
        (derived-mode-p 'go-ts-mode))
    (progn (godoc-at-point (point))))

   ((derived-mode-p 'python-mode)
    (if arg (call-interactively 'pydoc-at-point) (anaconda-mode-show-doc)))

   ((derived-mode-p 'haskell-mode)
    (progn (shut-up (pen-nil (pen-ns "implement hs-doc")))))

   (t (error "No handlers"))))

(defun pen-doc-thing-at-point-list ()
  "Show list of docs for thing under point"
  (interactive)
  (if (string-equal (preceding-sexp-or-element) "#lang")
      (str (racket--cmd/async (racket--repl-session-id) `(doc ,(concat "H:" (str (sexp-at-point))))))
    (cond ((derived-mode-p 'clojure-mode 'cider-repl-mode 'inf-clojure)
           (cider-doc-thing-at-point))
          ((derived-mode-p 'lisp-mode)
           (call-interactively 'slime-documentation))
          ((derived-mode-p 'go-mode)
           (progn (godoc-at-point (point))))
          ((derived-mode-p 'haskell-mode)
           (progn (hoogle (pen-thing-at-point) nil)))
          ((derived-mode-p 'racket-mode)
           (progn (pen-racket-doc) (deactivate-mark)))
          ((derived-mode-p 'text-mode)
           (progn (message "%s" "text mode. probably minibuffer") (describe-thing-at-point)))
          ((derived-mode-p 'emacs-lisp-mode)
           (describe-thing-at-point))
          ((derived-mode-p 'hy-mode) (hy-describe-thing-at-point))
          (t (search-google-for-doc)))))

(defun pen-def-thing-at-point ()
  "Show lisp documentation for the appropriate dialect based on the current mode."
  (interactive)
  (if (string-equal (preceding-sexp-or-element) "#lang")
      (racket--repl-command "doc %s" (concat "H:" (str (sexp-at-point))))
    (cond
     ((or (derived-mode-p 'go-mode)
          (derived-mode-p 'go-ts-mode))
      (progn (spacemacs/jump-to-definition)))

     (t (let ((lang (current-lang t))
              (symstring (pen-thing-at-point)))
          (if (string-equal lang "fundamental")
              (setq lang (detect-language)))

          (cond ((string-equal lang "fundamental") (progn
                                                     (message "%s" symstring)))
                (t (progn
                     (eval `(,(intern (concat "engine/search-google-lucky")) (concat (construct-google-query lang 'lang) (concat "+" (pen-q symstring)))))
                     (message "%s" (concat "no doc handler for " lang ". searching google"))))))))))

(define-key global-map (kbd "M-0") #'pen-doc-thing-at-point-list)

(defun pen-doc-thing-at-point-immediate ()
  (interactive)
  (pen-doc-thing-at-point t))

(defun pen-intero-get-type ()
  (interactive)
  (pen-enable-intero)
  (let ((out (pen-sn "sed -z -e \"s/\\n/ /g\" -e \"s/ \\+/ /g\"" (sed "s/^[^:]\\+ :: //" (intero-get-type-at (beginning-of-thing 'sexp) (end-of-thing 'sexp))))))
    (if (called-interactively-p 'any)
        (xc out)
      out)))



(defun hs-tds-fzf (hs-type)
  (interactive (list (pen-haskell-get-type)))
  (pen-sph (concat "t new " (pen-q "pen-rtcmd hs-type-declarative-search-fzf " (pen-q hs-type)))))



(defun pen-type-search-thing-at-point (&optional  winfunc)
  "Show doc for thing under pointl. winfunc = 'spv or 'sph elisp function"
  (interactive)

  (if (not winfunc)
      (setq winfunc 'sph))

  (cond
   ((derived-mode-p 'haskell-mode)
    (progn
      (call-interactively 'hs-tds-fzf)))
   (t (search-google-for-doc))))

(defun pen-doc-override (&optional lang mode query)
  (interactive (list (buffer-language)
                     (str major-mode)
                     (if mark-active (pen-selected-text) (str (sexp-at-point)))))

  (let* ((lang (or lang (buffer-language)))
         (mode (or mode (str major-mode)))
         (query (or query (if mark-active (pen-selected-text) (str (sexp-at-point)))))
         (docs (pen-sn (pen-cmd "doc-override" query lang mode))))

    (ignore-errors
      (if (bufferp "doc-overide*")
          (with-current-buffer "*doc-override*"
            (kill-buffer-and-window))))
    (if (string-empty-p docs)
        (error "Doc is empty")
      (new-buffer-from-string docs "*doc-override*"))))

(defun pen-src-thing-at-point (&optional  winfunc)
  "Show doc for thing under pointl. winfunc = 'spv or 'sph elisp function"
  (interactive)

  (if (not winfunc)
      (setq winfunc 'sph))

  (cond
   ((derived-mode-p 'haskell-mode)
    (progn (tm/spv (concat "hsdoc " (pen-q (sexp-at-point))))))
   (t (search-google-for-doc))))

(defun pen-type-search-thing-at-point-immediate ()
  (interactive)
  (pen-type-search-thing-at-point t))

(defun pen-doc-thing-at-point-immediate-spv ()
  (interactive)
  (pen-doc-thing-at-point t 'spv))

(defun sps-ead-thing-at-point ()
  (interactive)
  (pen-sph (concat "ead " (pen-q (eatify (str (pen-thing-at-point)))))))

(defun wgrep-thing-at-point (s &optional dir)
  (interactive (list (pen-thing-at-point)))
  (if (derived-mode-p 'grep-mode)
      (call-interactively 'grep-eead-on-results)
    (if dir
        (wgrep (eatify (str s)) dir)
      (if (>= (prefix-numeric-value current-prefix-arg) 4)
          (let ((current-prefix-arg nil))
            (wgrep (eatify (str s)) (projectile-acquire-root)))
        (wgrep (eatify (str s)) (pen-pwd))))))

(defun eatify (pat)
  (if (string-match "^[a-zA-Z_]" pat)
      (setq pat (concat "\\b" pat)))
  (if (string-match "[a-zA-Z_]$" pat)
      (setq pat (concat pat "\\b")))
  pat)

(defun eead-thing-at-point (&optional thing paths-string dir)
  (interactive (list (str (pen-thing-at-point))
                     nil
                     (get-top-level)))
  (let* ((cmd (concat "ead " (pen-q (eatify thing))))
         (cmdnoeat (if paths-string
                       (concat "umn | uniqnosort | ead " (pen-q thing))
                     (concat "ead " (pen-q thing))))
         (slug (slugify cmdnoeat))
         (bufname (concat "*grep:" slug "*"))
         (results (string-or (pen-sn cmd paths-string)
                             (pen-sn cmdnoeat))))

    (with-current-buffer (new-buffer-from-string results
                                                 bufname)
      (cd dir)
      (grep-mode)
      (ivy-wgrep-change-to-wgrep-mode)
      (define-key compilation-button-map (kbd "C-m") 'compile-goto-error)
      (define-key compilation-button-map (kbd "RET") 'compile-goto-error)
      (visual-line-mode -1))))

(define-key global-map (kbd "M-3") #'pen-grep-for-thing-select)

(defun pen-describe-symbol (symbol)
  "A “C-h o” replacement using “helpful”:
   If there's a thing at point, offer that as default search item.

   If a prefix is provided, i.e., “C-u C-h o” then the built-in
   “describe-symbol” command is used.

   ⇨ Pretty docstrings, with links and highlighting.
   ⇨ Source code of symbol.
   ⇨ Callers of function symbol.
   ⇨ Key bindings for function symbol.
   ⇨ Aliases.
   ⇨ Options to enable tracing, dissable, and forget/unbind the symbol!
  "
  (interactive "p")
  (let* ((thing (symbol-at-point))
         (val (completing-read
               (format "Describe symbol (default %s): " thing)
               (vconcat (list thing) obarray)
               (λ (vv)
                (cl-some (λ (x) (funcall (nth 1 x) vv))
                         describe-symbol-backends))
               t nil nil))
         (it (intern val)))

    (if current-prefix-arg
        (funcall #'describe-symbol it)
      (cond
       ((or (functionp it) (macrop it) (commandp it)) (helpful-callable it))
       (t (helpful-symbol it))))))

(provide 'pen-doc)
