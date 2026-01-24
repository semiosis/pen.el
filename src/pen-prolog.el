(require 'prolog-ls)
(require 'ob-prolog)

(ignore-errors
  (use-package ediprolog)
  (require 'ediprolog))

(add-hook 'prolog-mode-hook #'lsp)

;; Also see pen-perl.el

;; TODO Start by making functions for constructing prolog databases 

;; =atomic formula= wrote(X,Y)
;; wrote(roger, sam). -> wrote
(defun pro-get-relation-names ()
  (pen-snc "sed -n 's/\\b\\([a-z]\\+\\)([a-z]\\+, \\?[a-z]\\+).*/\\1/p'" (buffer-string)))

;; Permute the atomic formulae with wildcards for querying

(add-hook 'prolog-mode-hook 'ediprolog-consult)

;; =base clause=, which represents a simple fact
(defun pro-get-base-clause-names ()
  (pen-snc "sed -n 's/\\b\\([a-z]\\+\\)([a-z]\\+).*/\\1/p'" (buffer-string)))

(define-key prolog-mode-map (kbd "M-o b") 'prolog-consult-buffer)
(define-key prolog-mode-map (kbd "M-o f") 'prolog-consult-file)
(define-key prolog-mode-map (kbd "M-o r") 'prolog-consult-region)
(define-key prolog-mode-map (kbd "M-o M-d") 'prolog-debug-on)
(define-key prolog-mode-map (kbd "M-o M-n") 'prolog-insert-predicate-template)

(define-key prolog-mode-map (kbd "C-c TAB") 'ediprolog-dwim)
(define-key prolog-mode-map (kbd "M-RET") 'new-line-and-indent)

(define-derived-mode prolog-kb-mode prolog-mode "prolog-kb"
  ""
  ;; (setq mode-name (concat "prolog"))
  ;; (prolog-mode-variables)
  ;; (dolist (ar prolog-align-rules) (add-to-list 'align-rules-list ar))
  ;; (add-hook 'post-self-insert-hook #'prolog-post-self-insert nil t)
  ;; `imenu' entry moved to the appropriate hook for consistency.
  ;; (when prolog-electric-dot-flag
  ;;   (setq-local electric-indent-chars
  ;;               (cons ?\. electric-indent-chars)))

  ;; Load SICStus debugger if suitable
  ;; (if (and (eq prolog-system 'sicstus)
  ;;          (prolog-atleast-version '(3 . 7))
  ;;          prolog-use-sicstus-sd)
  ;;     (prolog-enable-sicstus-sd))

  ;; (prolog-menu)
  )

(provide 'pen-prolog)
