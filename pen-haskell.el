(require 'haskell-mode)
(require 'intero)


(defun haskell-extend-language ()
  (interactive)
  (let ((lang
         (mu
          (fz
           (-uniq (str2list
                   (concat
                    (pen-snc "cd \"$NOTES/ws/haskell\"; anygrep -E 'scrape \"LANGUAGE [A-Za-z]+\"' | cut -d ' ' -f 2")
                    ;; (pen-snc "cd \"/home/shane/var/smulliga/source/git/mullikine/glossaries\"; anygrep -E 'scrape \"LANGUAGE [A-Za-z]+\"' | cut -d ' ' -f 2")
                    )))
           nil nil "haskell-extend-language: "))))
    (if (sor lang)
        (progn
          (beginning-of-buffer)
          (insert (concat "{-# LANGUAGE " lang " #-}"))
          (newline)))))


;; (setq haskell-compile-command "ghc -Wall -ferror-spans -fforce-recomp -c %s")
;; (setq haskell-compile-command "stack build --fast --ghc-options=\"-j +RTS -A32M -RTS\"")

(define-key haskell-indentation-mode-map (kbd "<backtab>") nil)

(set-language-environment "utf-8")

;; Autoformat
(custom-set-variables
 '(haskell-stylish-on-save t))

(defun pen-haskell-settings ()
  (setq-local indent-line-function #'indent-relative)

  ;; I couldn't find a way to permanently remove flycheck-haskell
  (add-to-list 'flycheck-disabled-checkers 'haskell-stack-ghc)
  ;; (setq-local flycheck-checker 'lsp)
  (remove-from-list 'flycheck-checkers 'haskell-ghc))

;; Why did this break haskell mode? It didn't. Code further down did
(add-hook 'haskell-mode-hook #'pen-haskell-settings)

;; Don't do it this way ever
;; (add-hook 'haskell-mode-hook #'structured-haskell-mode)
;; (remove-hook 'haskell-mode-hook #'structured-haskell-mode)

;; (add-hook 'haskell-mode-hook #'haskell-session-change)

(define-key haskell-mode-map (kbd "C-c C-c") 'haskell-session-change)

;; (define-key haskell-mode-map (kbd "M-.") 'haskell-mode-jump-to-def)
(define-key interactive-haskell-mode-map (kbd "M-.") nil)

(define-key haskell-mode-map (kbd "C-c C-,") nil)
(define-key haskell-mode-map (kbd "C-c ,") 'haskell-add-import)

(defun hoogle-thing-at-point ()
  (interactive)
  (hoogle (str (thing-at-point 'symbol)) t))

;; If I don't do this, PATH will be screwed and shell subroutines will stop finding things
(if (cl-search "PURCELL" pen-daemon-name)
    (remove-hook 'haskell-mode-hook 'stack-exec-path-mode))


;; Not sure what load-library is for
;; Is this instead of require?
(load-library "ob-haskell")



;; For the repl
;; My pen map C-a / (beginning-of-line-or-indentation) disables pen to run this
(defun haskell-repl-go-to-start ()
  (interactive)
  (beginning-of-line)
  (search-forward "λ> "))
(define-key haskell-interactive-mode-map (kbd "C-a") 'haskell-repl-go-to-start)
(defun haskell-repl-go-to-0 ()
  (interactive)
  (beginning-of-line))
(define-key haskell-interactive-mode-map (kbd "C-c C-a") 'haskell-repl-go-to-0)


(defun pen-haskell-mode-hook ()
  (interactive)
  (remove-from-list 'company-backends 'company-ghci)
  ;; (add-to-list 'company-backends 'intero-company)
  ;; (add-to-list (make-local-variable 'company-backends) 'intero-company)
  )
(add-hook 'haskell-mode-hook 'pen-haskell-mode-hook t)
;; (remove-hook 'haskell-mode-hook 'pen-haskell-mode-hook t)

(defun pen-enable-intero ()
  (interactive)
  (shut-up
    (make-local-variable 'company-backends)
    (add-to-list 'company-backends 'company-ghci)
    (add-to-list 'company-backends 'intero-company)
    (intero-mode 1))
  (message "intero enabled"))

(defun pen-disable-intero ()
  (interactive)
  (shut-up
    (make-local-variable 'company-backends)
    (remove-from-list 'company-backends 'intero-company)
    (remove-from-list 'company-backends 'company-ghci)
    (remove-from-list 'completion-at-point-functions 'intero-completion-at-point)
    (remove-from-list 'completion-at-point-functions 'haskell-completions-completion-at-point)
    (remove-from-list 'completion-at-point-functions 'haskell-completions-sync-repl-completion-at-point)

    ;; (delete 'intero-company company-backends)
    (intero-mode -1))
  (message "intero disabled"))

(defun pen-toggle-intero ()
  (interactive)
  (if intero-mode
      (pen-disable-intero)
    (pen-enable-intero)
      )
  )

;; This will make ghci work on newer stack. i.e. "stack ghci" should work for emacs with a new stack.
(setq haskell-process-args-stack-ghci '(""))
;; (setq haskell-process-args-stack-ghci '("--ghci-options=-ferror-spans"))
(setq haskell-process-args-ghci '("--ghci-options=-ferror-spans"))


;; This will remove the annoying prompt, but it hides the problem
(setq haskell-process-suggest-restart nil)


;; I want this function to actually *save* the type to a variable so I
;; can access it.
;; This isn't the right function
;; (defun haskell-mode-show-type-at (&optional insert-value)
;;   "Show type of the thing at point or within active region asynchronously.
;; This function requires GHCi 8+ or GHCi-ng.

;; \\<haskell-interactive-mode-map>
;; To make this function works sometimes you need to load the file in REPL
;; first using command `haskell-process-load-file' bound to
;; \\[haskell-process-load-file].

;; Optional argument INSERT-VALUE indicates that
;; recieved type signature should be inserted (but only if nothing
;; happened since function invocation)."
;;   (interactive "P")
;;   (let* ((pos (haskell-command-capture-expr-bounds))
;;          (req (haskell-utils-compose-type-at-command pos))
;;          (process (haskell-interactive-process))
;;          (buf (current-buffer))
;;          (pos-reg (cons pos (region-active-p))))
;;     (haskell-process-queue-command
;;      process
;;      (make-haskell-command
;;       :state (list process req buf insert-value pos-reg)
;;       :go
;;       (lambda (state)
;;         (let* ((prc (car state))
;;                (req (nth 1 state)))
;;           (haskell-utils-async-watch-changes)
;;           (haskell-process-send-string prc req)))
;;       :complete
;;       (lambda (state response)
;;         (let* ((init-buffer (nth 2 state))
;;                (insert-value (nth 3 state))
;;                (pos-reg (nth 4 state))
;;                (wrap (cdr pos-reg))
;;                (min-pos (caar pos-reg))
;;                (max-pos (cdar pos-reg))
;;                (sig (haskell-utils-reduce-string response))
;;                (res-type (haskell-utils-repl-response-error-status sig)))

;;           (cl-case res-type
;;             ;; neither popup presentation buffer
;;             ;; nor insert response in error case
;;             ('unknown-command
;;              (message "This command requires GHCi 8+ or GHCi-ng. Please read command description for details."))
;;             ('option-missing
;;              (message "Could not infer type signature. You need to load file first. Also :set +c is required, see customization `haskell-interactive-set-+c'. Please read command description for details."))
;;             ('interactive-error (message "Wrong REPL response: %s" sig))
;;             (otherwise
;;              (if insert-value
;;                  ;; Only insert type signature and do not present it
;;                  (if (= (length haskell-utils-async-post-command-flag) 1)
;;                      (if wrap
;;                          ;; Handle region case
;;                          (progn
;;                            (deactivate-mark)
;;                            (save-excursion
;;                              (delete-region min-pos max-pos)
;;                              (goto-char min-pos)
;;                              (insert (concat "(" sig ")"))))
;;                        ;; Non-region cases
;;                        (haskell-command-insert-type-signature sig))
;;                    ;; Some commands registered, prevent insertion
;;                    (message "Type signature insertion was prevented. These commands were registered: %s"
;;                             (cdr (reverse haskell-utils-async-post-command-flag))))
;;                (progn
;;                  ;; Present the result only when response is valid and not asked
;;                  ;; to insert result
;;                  ;;(message "hi")
;;                  ;;(message (haskell-utils-reduce-string response))
;;                  ;;(bp ds -s haskell-type-at-point (haskell-utils-reduce-string response))
;;                  (haskell-command-echo-or-present response))))

;;             (haskell-utils-async-stop-watching-changes init-buffer))))))))






;; ;; https://wiki.haskell.org/Literate_programming
;; (add-hook 'haskell-mode-hook 'pen-mmm-mode)

;; (mmm-add-classes
;;  '((literate-haskell-bird
;;     :submode text-mode
;;     :front "^[^>]"
;;     :include-front true
;;     :back "^>\\|$"
;;     )
;;    (literate-haskell-latex
;;     :submode literate-haskell-mode
;;     :front "^\\\\begin{code}"
;;     :front-offset (end-of-line 1)
;;     :back "^\\\\end{code}"
;;     :include-back nil
;;     :back-offset (beginning-of-line -1))))

;; (defun pen-mmm-mode ()
;;   ;; go into mmm minor mode when class is given
;;   (make-local-variable 'mmm-global-mode)
;;   (setq mmm-global-mode 'true))

;; (setq mmm-submode-decoration-level 0)



;; I changed this line to add ghci commands. it's the :[a-z] at the start
;; ("^\\(?::[a-z]+\\|#\\(?:[^\\\n]\\|\\\\\\(?:.\\|\n\\|\\'\\)\\)*\\(?:\n\\|\\'\\)\\)" 0 'font-lock-preprocessor-face t)
;; Run this after redefining
;; (haskell-font-lock-defaults-create)
(defun haskell-font-lock-keywords ()
  ;; this has to be a function because it depends on global value of
  ;; `haskell-font-lock-symbols'
  "Generate font lock eywords."
  (let* (;; Bird-style literate scripts start a line of code with
         ;; "^>", otherwise a line of code starts with "^".
         (get-current-line-string-prefix "^\\(?:> ?\\)?")

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


;; TODO Consider setting this to nil for haskell only. Those sideline messages are long
;; (setq lsp-ui-sideline-show-hover t)
;; I will try to minimise them instead



;; This is not actually too slow.
;; haskell-mode itself is slow
;; But Sorting declarations comes from this function
;; (defun haskell-ds-create-imenu-index ())

(require 'haskell-decl-scan)
(defun haskell-ds-create-imenu-index ()
  "Function for finding `imenu' declarations in Haskell mode.
Finds all declarations (classes, variables, imports, instances and
datatypes) in a Haskell file for the `imenu' package."
  ;; Each list has elements of the form `(INDEX-NAME . INDEX-POSITION)'.
  ;; These lists are nested using `(INDEX-TITLE . INDEX-ALIST)'.
  (let* ((bird-literate (haskell-ds-bird-p))
         (index-alist '())
         (index-class-alist '()) ;; Classes
         (index-var-alist '())   ;; Variables
         (index-imp-alist '())   ;; Imports
         (index-inst-alist '())  ;; Instances
         (index-type-alist '())  ;; Datatypes
         ;; Variables for showing progress.
         (bufname (buffer-name))
         (divisor-of-progress (max 1 (/ (buffer-size) 100)))
         ;; The result we wish to return.
         result)
    (goto-char (point-min))
    ;; Loop forwards from the beginning of the buffer through the
    ;; starts of the top-level declarations.
    (while (< (point) (point-max))
      ;; (message "Scanning declarations in %s... (%3d%%)" bufname
      ;;          (/ (- (point) (point-min)) divisor-of-progress))
      ;; Grab the next declaration.
      (setq result (haskell-ds-generic-find-next-decl bird-literate))
      (if result
          ;; If valid, extract the components of the result.
          (let* ((name-posns (car result))
                 (name (car name-posns))
                 (posns (cdr name-posns))
                 (start-pos (car posns))
                 (type-of-of-of (cdr result)))
            ;; Place `(name . start-pos)' in the correct alist.
            (cl-case type
              (variable
               (setq index-var-alist
                     (cl-acons name start-pos index-var-alist)))
              (datatype
               (setq index-type-alist
                     (cl-acons name start-pos index-type-alist)))
              (class
               (setq index-class-alist
                     (cl-acons name start-pos index-class-alist)))
              (import
               (setq index-imp-alist
                     (cl-acons name start-pos index-imp-alist)))
              (instance
               (setq index-inst-alist
                     (cl-acons name start-pos index-inst-alist)))))))
    ;; Now sort all the lists, label them, and place them in one list.
    ;; (message "Sorting declarations in %s..." bufname)
    (when index-type-alist
      (push (cons "Datatypes"
                  (sort index-type-alist 'haskell-ds-imenu-label-cmp))
            index-alist))
    (when index-inst-alist
      (push (cons "Instances"
                  (sort index-inst-alist 'haskell-ds-imenu-label-cmp))
            index-alist))
    (when index-imp-alist
      (push (cons "Imports"
                  (sort index-imp-alist 'haskell-ds-imenu-label-cmp))
            index-alist))
    (when index-class-alist
      (push (cons "Classes"
                  (sort index-class-alist 'haskell-ds-imenu-label-cmp))
            index-alist))
    (when index-var-alist
      (if haskell-decl-scan-bindings-as-variables
          (push (cons "Variables"
                      (sort index-var-alist 'haskell-ds-imenu-label-cmp))
                index-alist)
        (setq index-alist (append index-alist
                                  (sort index-var-alist 'haskell-ds-imenu-label-cmp)))))
    ;; (message "Sorting declarations in %s...done" bufname)
    ;; Return the alist.
    index-alist))

(defun pen-interpreter-import ()
  "Start the interpreter for the current language and import the selected import"
  (interactive)
  (let* ((modules (sor (pen-sn "list-modules -sl")))
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
            ;; (get-ext-for-mode)
            (cond ((string-equal lang "hs")
                   (pen-sps (concat "x -sh \"ghci -norc\" -e \">\" -s \"import " imp " \" -c m -i")))
                  ((string-equal lang "py")
                   (if (yes-or-no-p "xpti: Use home directory?")
                       (xpti-with-package imp "~")
                     (xpti-with-package imp)))
                  (t (progn (message (concat "please handle this interpreter: " lang))
                            (j 'pen-interpreter-import))))
          (progn
            (message (pen-ns "No import detected"))
            (cond ((string-equal lang "hs")
                   (pen-sps "ghci -norc"))
                  ((string-equal lang "py")
                   (if (yes-or-no-p "xpti: Use home directory?")
                       (xpti-with-package "~")
                     (xpti-with-package)))
                  (t (progn (message (concat "please handle this interpreter: " lang))
                            (j 'pen-interpreter-import))))))
      ;; (cond ((derived-mode-p 'haskell-mode) (pen-sps (concat "x -sh \"ghci -norc\" -e \">\" -s \"import " sel " \" -c m -i")))
      ;;       ;; (t (pen-sps (concat "x -sh \"ghci -norc\" -e \">\" -s \"import " sel " \" -c m -i")))
      ;;       )
      )))

(define-key global-map (kbd "H-U") 'pen-interpreter-import)



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



(defun haskell-repl ()
  (interactive)
  (comint-quick "haskell-repl" (pen-pwd)))


(advice-add 'dante-fontify-expression :around #'ignore-errors-passthrough-around-advice)


(advice-add 'dante-info :around #'ignore-errors-around-advice)

(advice-add 'dante-schedule-next :around #'ignore-errors-around-advice)



;; dante-command-line ("nix-shell" "--pure" "--run" "cabal v1-repl  --builddir=dist/dante")􀋉

;; Prioritise stack
;; (setq dante-methods
;;       '(new-flake-impure new-flake flake-impure flake styx stack new-impure-nix new-nix nix impure-nix new-build nix-ghci mafia bare-cabal bare-v1-cabal bare-ghci))

;; Prioritise nix
(setq dante-methods
      '(new-flake-impure new-flake flake-impure flake styx new-impure-nix new-nix nix impure-nix stack new-build nix-ghci mafia bare-cabal bare-v1-cabal bare-ghci))


(require 'hasky-stack)

(define-key haskell-mode-map (kbd "C-M-@ h e") #'hasky-stack-execute)
(define-key haskell-mode-map (kbd "C-M-@ h a") #'hasky-stack-package-action)
(define-key haskell-mode-map (kbd "C-M-@ h n") #'hasky-stack-new)

(provide 'pen-haskell)