(require 'haskell)
(require 'haskell-mode)
(require 'haskell-hoogle)
(require 'ob-haskell)
(require 'haskell-decl-scan)
(require 'dante)
;; (require 'hasky-stack)
(require 's)

;; This will make ghci work on newer stack. i.e. "stack ghci" should work for emacs with a new stack.
(setq haskell-process-args-stack-ghci '(""))
;; (setq haskell-process-args-stack-ghci '("--ghci-options=-ferror-spans"))
(setq haskell-process-args-ghci '("--ghci-options=-ferror-spans"))
;; This will remove the annoying prompt, but it hides the problem
(setq haskell-process-suggest-restart nil)

(set-language-environment "utf-8")

;; Autoformat
(setq haskell-stylish-on-save t)

(defvar haskell-rosetta-code-dir (pen-umn "$NOTES/ws/haskell"))
(defun haskell-extend-language ()
  (interactive)
  (if (f-directory-p haskell-rosetta-code-dir)
      (let ((lang
             (pen-mu
              (fz
               (-uniq (pen-str2list
                       (concat
                        (pen-snc (concat "cd \"" haskell-rosetta-code-dir "\"; pen-anygrep -E 'pen-scrape \"LANGUAGE [A-Za-z]+\"' | cut -d ' ' -f 2")))))
               nil nil "haskell-extend-language: "))))
        (if (sor lang)
            (progn
              (beginning-of-buffer)
              (insert (concat "{-# LANGUAGE " lang " #-}"))
              (newline))))
    (error (concat haskell-rosetta-code-dir " does not exist"))))

;; (setq haskell-compile-command "ghc -Wall -ferror-spans -fforce-recomp -c %s")
;; (setq haskell-compile-command "stack build --fast --ghc-options=\"-j +RTS -A32M -RTS\"")

(defun pen-haskell-settings ()
  (setq-local indent-line-function #'indent-relative)

  (add-to-list 'flycheck-disabled-checkers 'haskell-stack-ghc)
  (remove-from-list 'flycheck-checkers 'haskell-ghc))

(add-hook 'haskell-mode-hook #'pen-haskell-settings)

(defun hoogle-thing-at-point ()
  (interactive)
  (hoogle (str (thing-at-point 'symbol)) t))

;; For the repl
;; My pen map C-a / (beginning-of-line-or-indentation) disables pen to run this
(defun haskell-repl-go-to-start ()
  (interactive)
  (beginning-of-line)
  (search-forward "λ> "))

(defun haskell-repl-go-to-0 ()
  (interactive)
  (beginning-of-line))

(defun pen-haskell-mode-hook ()
  (interactive)
  (remove-from-list 'company-backends 'company-ghci))
(add-hook 'haskell-mode-hook 'pen-haskell-mode-hook t)

(defun haskell-font-lock-keywords ()
  ;; this has to be a function because it depends on global value of
  ;; `haskell-font-lock-symbols'
  "Generate font lock eywords."
  (let* (;; Bird-style literate scripts start a line of code with
         ;; "^>", otherwise a line of code starts with "^".
         (line-prefix "^\\(?:> ?\\)?")

         (varid "[[:lower:]_][[:alnum:]'_]*")
         ;; We allow ' preceding conids because of DataKinds/PolyKinds
         (conid "'?[[:upper:]][[:alnum:]'_]*")
         (sym "\\s.+")

         ;; Top-level declarations
         (topdecl-var
          (concat line-prefix "\\(" varid "\\(?:\\s-*,\\s-*" varid "\\)*" "\\)"
                  ;; optionally allow for a single newline after identifier
                  "\\(\\s-+\\|\\s-*[\n]\\s-+\\)"
                  ;; A toplevel declaration can be followed by a definition
                  ;; (=), a type (::) or (∷), a guard, or a pattern which can
                  ;; either be a variable, a constructor, a parenthesized
                  ;; thingy, or an integer or a string.
                  "\\(" varid "\\|" conid "\\|::\\|∷\\|=\\||\\|\\s(\\|[0-9\"']\\)"))
         (topdecl-var2
          (concat line-prefix "\\(" varid "\\|" conid "\\)\\s-*`\\(" varid "\\)`"))
         (topdecl-bangpat
          (concat line-prefix "\\(" varid "\\)\\s-*!"))
         (topdecl-sym
          (concat line-prefix "\\(" varid "\\|" conid "\\)\\s-*\\(" sym "\\)"))
         (topdecl-sym2 (concat line-prefix "(\\(" sym "\\))"))

         keywords)

    (setq keywords
          `(;; NOTICE the ordering below is significant
            ;;\\(?:ghci> \\)?
            ("^\\(?:[ \t]*\\(?:ghci> :[a-z]+\\|ghci> \\|:[a-z]+\\)\\|#\\(?:[^\\\n]\\|\\\\\\(?:.\\|\n\\|\\'\\)\\)*\\(?:\n\\|\\'\\)\\)" 0 'font-lock-preprocessor-face t)

            ,@(haskell-font-lock-symbols-keywords)

            ;; Special case for `as', `hiding', `safe' and `qualified', which are
            ;; keywords in import statements but are not otherwise reserved.
            ("\\<import[ \t]+\\(?:\\(safe\\>\\)[ \t]*\\)?\\(?:\\(qualified\\>\\)[ \t]*\\)?\\(?:\"[^\"]*\"[\t ]*\\)?[^ \t\n()]+[ \t]*\\(?:\\(\\<as\\>\\)[ \t]*[^ \t\n()]+[ \t]*\\)?\\(\\<hiding\\>\\)?"
             (1 'haskell-keyword-face nil lax)
             (2 'haskell-keyword-face nil lax)
             (3 'haskell-keyword-face nil lax)
             (4 'haskell-keyword-face nil lax))

            ;; Special case for `foreign import'
            ;; keywords in foreign import statements but are not otherwise reserved.
            ("\\<\\(foreign\\)[ \t]+\\(import\\)[ \t]+\\(?:\\(ccall\\|stdcall\\|cplusplus\\|jvm\\|dotnet\\)[ \t]+\\)?\\(?:\\(safe\\|unsafe\\|interruptible\\)[ \t]+\\)?"
             (1 'haskell-keyword-face nil lax)
             (2 'haskell-keyword-face nil lax)
             (3 'haskell-keyword-face nil lax)
             (4 'haskell-keyword-face nil lax))

            ;; Special case for `foreign export'
            ;; keywords in foreign export statements but are not otherwise reserved.
            ("\\<\\(foreign\\)[ \t]+\\(export\\)[ \t]+\\(?:\\(ccall\\|stdcall\\|cplusplus\\|jvm\\|dotnet\\)[ \t]+\\)?"
             (1 'haskell-keyword-face nil lax)
             (2 'haskell-keyword-face nil lax)
             (3 'haskell-keyword-face nil lax))

            ;; Special case for `type family' and `data family'.
            ;; `family' is only reserved in these contexts.
            ("\\<\\(type-of-of-of\\|data\\)[ \t]+\\(family\\>\\)"
             (1 'haskell-keyword-face nil lax)
             (2 'haskell-keyword-face nil lax))

            ;; Special case for `type role'
            ;; `role' is only reserved in this context.
            ("\\<\\(type-of-of-of\\)[ \t]+\\(role\\>\\)"
             (1 'haskell-keyword-face nil lax)
             (2 'haskell-keyword-face nil lax))

            ;; Toplevel Declarations.
            ;; Place them *before* generic id-and-op highlighting.
            (,topdecl-var  (1 (unless (member (match-string 1) haskell-font-lock-keywords)
                                'haskell-definition-face)))
            (,topdecl-var2 (2 (unless (member (match-string 2) haskell-font-lock-keywords)
                                'haskell-definition-face)))
            (,topdecl-bangpat  (1 (unless (member (match-string 1) haskell-font-lock-keywords)
                                    'haskell-definition-face)))
            (,topdecl-sym  (2 (unless (member (match-string 2) '("\\" "=" "->" "→" "<-" "←" "::" "∷" "," ";" "`"))
                                'haskell-definition-face)))
            (,topdecl-sym2 (1 (unless (member (match-string 1) '("\\" "=" "->" "→" "<-" "←" "::" "∷" "," ";" "`"))
                                'haskell-definition-face)))

            ;; These four are debatable...
            ("(\\(,*\\|->\\))" 0 'haskell-constructor-face)
            ("\\[\\]" 0 'haskell-constructor-face)

            ("`"
             (0 (if (or (elt (syntax-ppss) 3) (elt (syntax-ppss) 4))
                    (parse-partial-sexp (point) (point-max) nil nil (syntax-ppss)
                                        'syntax-table)
                  (when (save-excursion
                          (goto-char (match-beginning 0))
                          (haskell-lexeme-looking-at-backtick))
                    (goto-char (match-end 0))
                    (unless (text-property-not-all (match-beginning 1) (match-end 1) 'face nil)
                      (put-text-property (match-beginning 1) (match-end 1) 'face 'haskell-operator-face))
                    (unless (text-property-not-all (match-beginning 2) (match-end 2) 'face nil)
                      (put-text-property (match-beginning 2) (match-end 2) 'face 'haskell-operator-face))
                    (unless (text-property-not-all (match-beginning 4) (match-end 4) 'face nil)
                      (put-text-property (match-beginning 4) (match-end 4) 'face 'haskell-operator-face))
                    (add-text-properties
                     (match-beginning 0) (match-end 0)
                     '(font-lock-fontified t fontified t font-lock-multiline t))))))

            (,haskell-lexeme-idsym-first-char
             (0 (if (or (elt (syntax-ppss) 3) (elt (syntax-ppss) 4))
                    (parse-partial-sexp (point) (point-max) nil nil (syntax-ppss)
                                        'syntax-table)
                  (when (save-excursion
                          (goto-char (match-beginning 0))
                          (haskell-lexeme-looking-at-qidsym))
                    (goto-char (match-end 0))
                    ;; note that we have to put face ourselves here because font-lock
                    ;; will use match data from the original matcher
                    (haskell-font-lock--put-face-on-type-or-constructor)))))))
    keywords))
(haskell-font-lock-defaults-create)

(defun ghcid ()
  (interactive)
  (let ((path (get-path)))
    (if (string-match-p "\.hs$" path)
        (pen-sps (concat "ghcid " (pen-q path)) "-p 20 -d")
      (message "%s" "not a .hs file"))))

(defun pen-interpreter-import ()
  "Start the interpreter for the current language and import the selected import"
  (interactive)
  (let* ((modules (sor (pen-sn "pen-list-modules -sl")))
         (sel (if modules
                  (fz modules
                      nil nil "pen-interpreter-import modules: ")
                (progn (message "No modules detected")
                       nil)))
         (imp (if sel (car (s-split "\t" sel))))
         (lang (string-or
                (if sel (car (last (s-split "\t" sel))))
                (get-ext-for-mode))))
    (if lang
        (if imp
            (cond ((string-equal lang "hs")
                   (pen-sps (concat "pen-x -sh \"ghci\" -e \">\" -s \"import " imp " \" -c m -i")))
                  ((string-equal lang "py")
                   (if (yes-or-no-p "xpti: Use home directory?")
                       (xpti-with-package imp "~")
                     (xpti-with-package imp)))
                  (t (progn (message (concat "please handle this interpreter: " lang))
                            (j 'pen-interpreter-import))))
          (progn
            (message (pen-ns "No import detected"))
            (cond ((string-equal lang "hs")
                   (pen-sps "ghci"))
                  ((string-equal lang "py")
                   (if (yes-or-no-p "xpti: Use home directory?")
                       (xpti-with-package "~")
                     (xpti-with-package)))
                  (t (progn (message (concat "please handle this interpreter: " lang))
                            (j 'pen-interpreter-import)))))))))

(defun ghcd-info (thing)
  (interactive (list (read-string-hist "ghcd: " (pen-thing-at-point))))
  (let ((info (pen-snc (concat "ghcd " (pen-q thing)))))
    (etv info)))

(use-package dante
  :ensure t
  :after haskell-mode
  :commands 'dante-mode
  :init
  (add-hook 'haskell-mode-hook 'flycheck-mode)
  ;; OR for flymake support:
  (add-hook 'haskell-mode-hook 'flymake-mode)
  (remove-hook 'flymake-diagnostic-functions 'flymake-proc-legacy-flymake)

  (add-hook 'haskell-mode-hook 'dante-mode)
  :config
  (flycheck-add-next-checker 'haskell-dante '(info . haskell-hlint)))

;; Prioritise nix
(setq dante-methods
      '(new-flake-impure new-flake flake-impure flake styx new-impure-nix new-nix nix impure-nix cabal new-build nix-ghci mafia bare-cabal bare-v1-cabal bare-ghci))

(advice-add 'dante-fontify-expression :around #'ignore-errors-passthrough-around-advice)
(advice-add 'dante-info :around #'ignore-errors-around-advice)
(advice-add 'dante-schedule-next :around #'ignore-errors-around-advice)

(defun haskell-repl ()
  (interactive)
  (comint-quick "pen-haskell-repl" (pen-pwd)))

(define-key haskell-indentation-mode-map (kbd "<backtab>") nil)
(define-key haskell-mode-map (kbd "C-c C-c") 'haskell-session-change)
(define-key interactive-haskell-mode-map (kbd "M-.") nil)
(define-key haskell-mode-map (kbd "C-c C-,") nil)
(define-key haskell-mode-map (kbd "C-c ,") 'haskell-add-import)
(define-key haskell-interactive-mode-map (kbd "C-a") 'haskell-repl-go-to-start)
(define-key haskell-interactive-mode-map (kbd "C-c C-a") 'haskell-repl-go-to-0)
;; (define-key global-map (kbd "H-U") 'pen-interpreter-import)

(comment
 (define-key haskell-mode-map (kbd "C-M-@ h e") #'hasky-stack-execute)
 (define-key haskell-mode-map (kbd "C-M-@ h a") #'hasky-stack-package-action)
 (define-key haskell-mode-map (kbd "C-M-@ h n") #'hasky-stack-new))

(defun hoogle-prompt ()
  "Prompt for Hoogle query."
  (let ((def (haskell-ident-at-point)))
    (if (and def (symbolp def)) (setq def (symbol-name def)))
    (list
     (if def
         def
       (read-string "Hoogle query: " nil nil def)))))

;; If lsp files, try haskell-doc-show-type. ie. (haskell-doc-sym-doc "newtype")
(defun pen-haskell-get-type ()
  (interactive)
  (let* ((thing (pen-thing-at-point))
         (si (pen--lsp-get-sideline-text))
         (hd (pen-lsp-get-hover-docs))
         (si (pen-sed "s/ t0/ Any/" (pen-sed "s/ \\[-W.*//" (sor (pen-sed "/:: \\*$/d" si)))))
         (ty
          (sor (s-replace-regexp (concat thing " :: ") "" (or (s-substring (concat thing " ::.*") si)
                                                              ""))
               (s-replace-regexp (concat "_ :: ") "" (or (s-substring (concat "_ ::.*") si)
                                                         ""))
               (haskell-doc-sym-doc thing)
               (sor hd)))
         (ty (s-replace-regexp " `.*" "" ty))
         (ty (s-replace-regexp (concat thing " :: ") "" ty))
         (ty (s-replace-regexp (concat "_ :: ") "" ty))
         ;; (ty (pen-snc (concat "sed -n 's/^" thing " :: \\(.*\\)$/\\1/p'") ty))
         (ty (pen-sed "s/\\[Char\\]/String/" ty)))
    (if (sor ty)
        (if (interactive-p)
            (pen-etv ty)
          ty)
      (progn
        ;; (error (concat "No known type for " thing))
        (message (concat "No known type for " thing))
        nil))))

(defun pen-haskell-hoogle-type ()
  "This is great for looking for functions to fill a hole"
  (interactive)
  (pen-sps (concat "pet pen-zrepl-hdc-type '" (pen-haskell-get-type) "'")))

(defun pen-haskell-get-import-for-package (thing)
  (interactive (list (pen-thing-at-point)))
  (let ((i
         (fz (pen-snc (concat "hs-import-to-package " (pen-q thing)))
             nil nil "pen-haskell-get-import-for-package: ")))
    (if i
        (if (interactive-p)
            (pen-etv i)
          i)
      (progn
        (message "No imports found")
        nil))))
(defalias 'pen-haskell-get-import 'pen-haskell-get-import-for-package)

(defun hs-install-module-under-cursor (thing)
  (interactive (list (pen-thing-at-point)))
  (pen-sps (concat "zrepl stack install " (pen-q (pen-haskell-get-import-for-package thing)))))

(defun hs-download-packages-with-function-type (hs-type)
  (interactive (list (pen-haskell-get-type)))
  (pen-sph (concat "t new " (pen-q "hs-download-packages-with-function-type " (pen-q hs-type)))))

(defun haskell-hdc-thing (thing)
  (interactive (list (pen-thing-at-point)))
  ;; (pen-zrepl (pen-cmd "hdc" thing))

  ;; (pen-e-spv 'haskell-show-hdc-readme)

  (if (string-match "^[^a-zA-Z]+$" thing)
      (setq thing (concat "(" thing ")")))

  (let ((parts (s-split "\\." thing)))
    (if (> (length parts) 1)
        (let ((last (-last-item parts)))
          (if (pen-re-sensitive (string-match "^[a-z]" last))
              (let ((module (s-join "." (-drop-last 1 parts))))
                ;; the last part is a function
                (pen-sps (pen-cmd "pen-x" "-allowtm" "-sh" "hdc" "-e" ">" "-s" thing "-c" "m" "-e" "search: " "-e" ">" "-sl" "0.1"
                                  "-s" (concat ":src " thing)
                                  ;; "-s" (concat ":src " last)
                                  ;; "-s" (concat ":mi " module)
                                  "-c" "m"
                                  "-i")))
            ;; the last part is just part of the module
            (pen-sps (pen-cmd "pen-x" "-allowtm" "-sh" "hdc" "-e" ">" "-s" thing "-c" "m" "-e" "search: " "-e" ">" "-sl" "0.1"
                              "-s" (concat ":md " thing)
                              "-c" "m"
                              "-i"))))
      (if (pen-re-sensitive (not (string-match "^[A-Z]" thing)))
          (pen-sps (pen-cmd "pen-x" "-allowtm" "-sh" "hdc" "-e" ">" "-s" thing "-c" "m" "-e" "search: " "-e" ">" "-sl" "0.1"
                            "-s" (concat ":src " thing)
                            "-c" "m"
                            "-i"))
        (pen-sps (pen-cmd "pen-x" "-allowtm" "-sh" "hdc" "-e" ">" "-s" thing "-c" "m" "-e" "search: " "-e" ">" "-sl" "0.1"
                          "-s" (concat ":md " thing)
                          "-c" "m"
                          "-i"))))))

(defun haskell-show-hdc-readme ()
  (interactive)
  (find-file "/root/repos/haskell-docs-cli/README.md"))

(defun dante-repl ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (pen-sps "dante-repl -bare" nil nil (locate-dominating-file-glob default-directory "*.cabal"))
    (pen-sps "dante-repl" nil nil (locate-dominating-file-glob default-directory "*.cabal"))))

(defun dante-ghcid ()
  (interactive)
  (pen-sps "dante-ghcid"
           "-d" nil (locate-dominating-file-glob default-directory "*.cabal"))
  ;; (pen-sps "cabal v2-repl --builddir=newdist/dante" nil nil (locate-dominating-file-glob default-directory "*.cabal"))
  )

(defun pen-haskell-project-file ()
  (interactive)
  (let* ((dir (locate-dominating-file-glob default-directory "*.cabal"))
         (pfp (car (glob (f-join dir "*.cabal")))))
    (if (interactive-p)
        (e pfp)
      pfp)))

(provide 'pen-haskell)
