(require 'lispy)
(require 'geiser)
(require 'pen-lisp)
;; (require 'pen-utils)
(require 'pen-doc)
;; (require 'pen-troubleshooting)
(require 'pen-aliases)
(require 'pen-fuzzy-lists)

(defun lispy-gy-emacs-vim-link (arg)
  (interactive "P")
  (if mark-active
      (if (>= (prefix-numeric-value current-prefix-arg) 4)
          (get-emacs-link)
        (get-vim-link))
    (call-interactively 'self-insert-command)))

(defun pen-clojure-eval-eval ()
  (interactive)
  (if (derived-mode-p 'clojure-mode)
      (progn
        (call-interactively 'pen-lisp-e)
        (let* ((sexp (sexp-at-point))
               ;; cadr = second
               (symstr (symbol-name (cadr sexp)))
               ;; caddr = third
               (argvec (third sexp))
               (arglist (pen-vector2list argvec))
               ;; Probably the simplest fix is to remove the &
               ;; Rather than implementing variable arguments
               (arglist (-filter (lambda (s) (not (string-equal "&" s)))
                                 arglist))
               (iarglist (mapcar
                          (lambda (e) `(read-string-hist ,(concat (str e) ": ")))
                          arglist))
               (argrepr (str (third sexp)))
               (argstr (s-substring "\\[\\(.*\\)\\]" argrepr)))
          ;; (tv (str symstr))
          (if (re-match-p "^\\[.*\\]$" argrepr)
              (progn
                (eval
                 `(call-interactively
                   (lambda (,@arglist)
                     (interactive (list ,@iarglist))
                     (let* ((valstr (pen-cmd ,@arglist))
                            (clj (concat "(" ,symstr " " valstr ")")))
                       (cider-nrepl-request:eval clj nil))))))
            (cider-nrepl-request:eval (concat "(" symstr ")") nil))))))

;; J:mount-pensieve
;; (s-substring "\\[\\(.*\\)\\]" (str (caddr (sexp-at-point))))
;; (cider-nrepl-sync-request:eval "(pen-test-interactive-clj \"hello\" \"\" \"\")" nil)
(defun pen-lispy-eval-eval ()
  "Evaluate sexp at point and then evaluate the result as a function."
  (interactive)

  (let ((cpa current-prefix-arg)
        (cgpa current-global-prefix-arg))
    (setq current-prefix-arg nil)
    (setq current-global-prefix-arg nil)
    (if (lispy-left-p)
        (cond
         ((derived-mode-p 'emacs-lisp-mode)
          (let* ((result)
                 (resultsym (save-excursion
                              (lispy-different)
                              (call-interactively 'eval-last-sexp))))
            (if (and (fboundp resultsym) (commandp resultsym))
                (let ((current-prefix-arg cpa)
                      ;; Propagating current-global-prefix-arg doesn't actually work with certain interactive, such as (interactive (list (read-string "kjlfdskf")))
                      (current-global-prefix-arg cgpa))
                  (call-interactively resultsym))
              (progn
                (if (or (functionp resultsym)
                        (macrop resultsym))
                    (setq result
                          (str (eval `(,resultsym))))
                  (setq result (eval-string result)))
                (new-buffer-from-string result)))))
         ((derived-mode-p 'clojure-mode)
          (call-interactively 'pen-clojure-eval-eval))
         (t (error (concat "No eval-eval handler for " (symbol-name major-mode))))))))

(defun lispy-flow (arg)
  "Move inside list ARG times.
Don't enter strings or comments.
Return nil if can't move."
  (interactive "p")
  (lispy--remember)
  (let ((pt (point))
        r)
    (cond
     ((and (lispy-bolp)
           (or (looking-at ";")
               (looking-at "#lang")))
      (setq r (pen-lispy-flow-left arg)))
     ((lispy-left-p)
      (setq r (pen-lispy-flow-left arg)))
     ((lispy-right-p)
      (backward-char)
      (when (setq r (lispy--re-search-in-code lispy-right 'backward arg))
        (forward-char))))
    (or r
        (progn
          (goto-char pt)
          nil))))

; A placeholder
(if (not (symbolp 'get-vim-link))
    (defun get-vim-link ()))
(if (not (symbolp 'get-emacs-link))
    (defun get-emacs-link ()))

(lispy-defverb
 "other"
 (("h" lispy-move-left)
  ("j" lispy-down-slurp)
  ("k" lispy-up-slurp)
  ("l" lispy-move-right)
  ("SPC" lispy-other-space)
  ;; ("g" lispy-goto-mode)
  ))

;; works fine
(lispy-defverb
 "goto"
 (("d" lispy-goto)
  ("l" lispy-goto-local)
  ("r" lispy-goto-recursive)
  ("p" lispy-goto-projectile)
  ("f" lispy-follow)
  ("b" pop-tag-mark)
  ("q" lispy-quit)
  ("j" lispy-goto-def-down)
  ("a" lispy-goto-def-ace)
  ("e" lispy-goto-elisp-commands)
  ;; My addition
  ("Y" get-vim-link)
  ("y" get-emacs-link)))

(defun lispy-ace-paren-invert-prefix (proc &rest args)
  (cond
   ((equal current-prefix-arg (list 4))
    (setq current-prefix-arg nil))

   ;; First check to see if it's on a paren. Otherwise I will get 4 Qs (QQQQ)
   ((and (lispy-left-p) (not current-prefix-arg))
    (setq current-prefix-arg (list 4))))

  (let ((res (apply proc args)))
    res))

(advice-add 'lispy-ace-paren :around #'lispy-ace-paren-invert-prefix)

(defun lispy-ace-paren-global (&optional arg)
  "Jump to an open paren within the current defun.
ARG can extend the bounds beyond the current defun."
  (interactive "p")
  (setq arg 8)
  (lispy--remember)
  (deactivate-mark)
  (let ((avy-keys lispy-avy-keys)
        (bnd (if (eq arg 1)
                 (save-excursion
                   (lispy--out-backward 50)
                   (lispy--bounds-dwim))
               (cons (window-start)
                     (window-end nil t)))))
    (avy-with lispy-ace-paren
      (lispy--avy-do
       lispy-left
       bnd
       (lambda () (not (lispy--in-string-or-comment-p)))
       lispy-avy-style-paren))))

(defun lispy-ace-paren-visible ()
  (interactive)
  (disable-advice-temporarily (lispy-ace-paren)))

(defun add-to-glossary-file-for-buffer () (interactive))
(defun glossary-add-link () (interactive))

;; This is how to set lispy maps.. Do this early in this file, so I can make mappings such as M-t later
(define-key lispy-mode-map (kbd "<backtab>") nil)
(defset lispy-mode-map-special
  (let ((map (make-sparse-keymap)))
    ;; navigation
    (lispy-define-key map "l" 'lispy-right)
    (lispy-define-key map "h" 'lispy-left)
    (lispy-define-key map "f" 'lispy-flow)
    (lispy-define-key map "j" 'lispy-down)
    (lispy-define-key map "k" 'lispy-up)
    (lispy-define-key map "d" 'lispy-different)
    (lispy-define-key map "g" 'lispy-gy-emacs-vim-link)
    (lispy-define-key map "o" 'lispy-other-mode)
    (lispy-define-key map "p" 'lispy-eval-other-window)
    (lispy-define-key map "P" 'lispy-paste)
    (lispy-define-key map "y" 'lispy-occur)
    (lispy-define-key map "z" 'lh-knight/body)
    (lispy-define-key map "E" 'pen-lispy-eval-eval)
    ;; Outline
    (lispy-define-key map "J" 'lispy-outline-next)
    (lispy-define-key map "K" 'lispy-outline-prev)
    (lispy-define-key map "L" 'lispy-outline-goto-child)
    ;; Paredit transformations
    (lispy-define-key map ">" 'lispy-slurp)
    (lispy-define-key map "<" 'lispy-barf)
    (lispy-define-key map "/" 'lispy-splice)
    (lispy-define-key map "r" 'lispy-raise)
    (lispy-define-key map "R" 'lispy-raise-some)
    (lispy-define-key map "+" 'lispy-join)
    ;; more transformations
    (lispy-define-key map "C" 'lispy-convolute)
    (lispy-define-key map "X" 'lispy-convolute-left)
    (lispy-define-key map "w" 'lispy-move-up)
    (lispy-define-key map "s" 'lispy-move-down)
    (lispy-define-key map "O" 'lispy-oneline)
    (lispy-define-key map "M" 'lispy-alt-multiline)
    (lispy-define-key map "S" 'lispy-stringify)
    ;; marking
    (lispy-define-key map "a" 'lispy-ace-symbol
      :override '(cond ((looking-at lispy-outline)
                        (lispy-meta-return))))
    (lispy-define-key map "H" 'egr-thing-at-point-imediately)
    (lispy-define-key map "m" 'lispy-mark-list)
    (lispy-define-key map "e" 'lispy-eval)
    (lispy-define-key map "G" 'go-to-fuzzy-list)
    (lispy-define-key map "g" 'lispy-gy-emacs-vim-link)
    (lispy-define-key map "F" 'add-to-fuzzy-list)
    (lispy-define-key map "D" 'pop-tag-mark)
    (lispy-define-key map "A" 'add-to-glossary-file-for-buffer)
    (lispy-define-key map "L" 'glossary-add-link)
    (lispy-define-key map "_" 'lispy-underscore)
    ;; miscellanea
    (define-key map (kbd "SPC") 'lispy-space)
    (lispy-define-key map "i" 'lispy-tab)
    (lispy-define-key map "I" 'lispy-shifttab)
    (lispy-define-key map "N" 'lispy-narrow)
    (lispy-define-key map "W" 'lispy-widen)
    (lispy-define-key map "c" 'lispy-clone)
    (lispy-define-key map "u" 'lispy-undo)
    (lispy-define-key map "q" 'lispy-ace-paren-global
      :override '(cond ((bound-and-true-p view-mode)
                        (View-quit))))
    (lispy-define-key map "v" 'lispy-ace-paren-global
      :override '(cond ((bound-and-true-p view-mode)
                        (View-quit))))
    (lispy-define-key map "Q" 'lispy-ace-paren-visible
      :override '(cond ((bound-and-true-p view-mode)
                        (View-quit))))
    (lispy-define-key map "V" 'lispy-view)
    (lispy-define-key map "t" 'lispy-teleport
      :override '(cond ((looking-at lispy-outline)
                        (end-of-line))))
    (lispy-define-key map "n" 'lispy-new-copy)
    (lispy-define-key map "b" 'lispy-ace-paren)
    (lispy-define-key map "B" 'lispy-ediff-regions)
    (lispy-define-key map "x" 'lispy-x)
    (lispy-define-key map "Z" 'lispy-edebug-stop)
    (lispy-define-key map "-" 'lispy-ace-subword)
    (lispy-define-key map "." 'lispy-repeat)
    (lispy-define-key map "~" 'lispy-tilde)
    ;; digit argument
    (mapc (lambda (x) (lispy-define-key map (format "%d" x) 'digit-argument))
          (number-sequence 0 9))
    map))

(lispy-set-key-theme '(special lispy c-digits))

(defun pen-racket-eval (&optional str)
  (if (region-active-p)
      (racket-send-region (region-beginning) (region-end))
    (with-temp-buffer
      (insert str)
      (racket-send-region (point-min) (point-max)))))

(defun lispy--eval (e-str)
  "Eval E-STR according to current `major-mode'.
The result is a string."
  (if (string= e-str "")
      ""
    (funcall
     (cond ((memq major-mode lispy-elisp-modes)
            'lispy--eval-elisp)
           ((or (memq major-mode lispy-clojure-modes)
                (memq major-mode '(nrepl-repl-mode
                                   cider-clojure-interaction-mode)))
            (require 'le-clojure)
            'lispy-eval-clojure)
           ((eq major-mode 'scheme-mode)
            (require 'le-scheme)
            'lispy--eval-scheme)
           ((eq major-mode 'lisp-mode)
            (require 'le-lisp)
            'lispy--eval-lisp)
           ((eq major-mode 'hy-mode)
            (require 'le-hy)
            'lispy--eval-hy)
           ((eq major-mode 'python-mode)
            (require 'le-python)
            'lispy--eval-python)
           ((eq major-mode 'julia-mode)
            (require 'le-julia)
            'lispy--eval-julia)
           ((eq major-mode 'ruby-mode)
            'oval-ruby-eval)
           ((eq major-mode 'matlab-mode)
            'matlab-eval)
           ((eq major-mode 'racket-mode)
            'pen-racket-eval)
           (t (error "%s isn't supported currently" major-mode)))
     e-str)))

(setq lispy-avy-style-symbol 'at)

(defun pen-lispy-unconvolute ()
  "The opposite of convolute. Like a demotion, from parent to child."
  (interactive)
  (ekm "f M-? f"))

(defun pen-lisp-expand-contract-selection-right ()
  (interactive)
  (if mark-active
      (cond ((pen-lispy-region-right-p)
             (let ((origmark (mark)))
               ;; expand rightwards
               (let ((pen-lisp-mode nil))
                 (execute-kbd-macro (kbd "j"))
                 (push-mark origmark))))
            (t
             ;; contract rightwards
             (let ((pen-lisp-mode nil))
               (paredit-forward)
               (if (eq (point) (mark))
                   (progn
                     (paredit-forward)
                     (if (lispy-right-p)
                         (call-interactively 'er/expand-region)))
                 (progn
                   (activate-region)
                   (ekm "k j")))
               ;; (execute-kbd-macro (kbd "j"))
               )))
    (let ((pen-lisp-mode nil))
      (ekm "C-q J"))))

(defun pen-lisp-expand-contract-selection-left ()
  (interactive)
  (if mark-active
      (cond ((pen-lispy-region-left-p)
             (let ((origmark (mark)))
               ;; expand leftwards
               (let ((pen-lisp-mode nil))
                 (execute-kbd-macro (kbd "k"))
                 (push-mark origmark))))
            (t
             ;; contract leftwards
             (let ((pen-lisp-mode nil))
               (paredit-backward)
               (if (eq (point) (mark))
                   (progn
                     (paredit-backward)
                     (if (lispy-left-p)
                         (call-interactively 'er/expand-region)))
                 (progn
                   (activate-region)
                   (ekm "j k")))
               ;; (execute-kbd-macro (kbd "k"))
               )))
    (let ((pen-lisp-mode nil)
          (lispy-mode nil))
      (ekm "K"))))

(defun pen-lispy-region-left-p ()
  "If you are on the left side of the region. If the mark is on the right."
  (= (point) (region-beginning)))

(defun pen-lispy-region-right-p ()
  "If you are on the right side of the region. If the mark is on the right."
  (= (point) (region-end)))

(defun pen-lispy-set-point-left ()
  (interactive)
  (when (pen-lispy-region-right-p)
    (exchange-point-and-mark)))

(defun pen-lispy-set-point-right ()
  (interactive)
  (when (pen-lispy-region-left-p)
    (exchange-point-and-mark)))

(defun pen-lispy-slurp-left ()
  (interactive)
  (pen-lispy-set-point-left)
  (lispy-slurp 1))

(defun pen-lispy-slurp-right ()
  (interactive)
  (pen-lispy-set-point-right)
  (lispy-slurp 1))

(defun pen-lispy-flow-left (arg)
  (interactive)
  (if (derived-mode-p 'racket-mode)
      (progn
        (let ((startpos (point)))
          (if (looking-at-p ".\(")
              (forward-char)
            (progn
              (forward-char)
              (lispy--re-search-in-code lispy-left 'forward arg)
              ))
          t))
    (lispy--re-search-in-code lispy-left 'forward arg)))

(defun forward-sexp-start (arg)
  (interactive "p")
  (forward-sexp)
  (special-lispy-beginning-of-defun-noevil arg))

(defun pen-lispy-goto-start (arg)
  (interactive "P")
  (deactivate-mark)
  (execute-kbd-macro (kbd "C-a C-a")))

(defun pen-lispy-mark-symbol (arg)
  (interactive "P")
  (lispy-mark-symbol))

(defun pen-lispy-mark-car (arg)
  "Frustratingly, this can't mark an empty list."
  (interactive "p")

  (pen-lisp-left-noevil arg)
  (call-interactively (lispy-mark-car)))

(defun pen-lispy-mark-list (arg)
  (interactive "p")
  (pen-lisp-right-noevil arg))

(defun pen-lispy-mark-symbol-or-list (arg)
  (interactive "P")
  (if (region-active-p)
      (let ((rstart (region-beginning))
            (rend (region-end)))
        (call-interactively 'pen-lispy-mark-list))
    (call-interactively 'pen-lispy-mark-symbol)))

(require 'smartparens)

(pen-with 'clojure-mode
         (defun cider-doc-thing-at-point ()
           (interactive)
           (cider-doc-lookup (str (symbol-at-point)))))

(require 'evil-lisp-state)

(defun pen-evil-insert-sexp-before-noevil ()
  (interactive "p")
  (evil-lisp-state-insert-sexp-before)
  (turn-off-evil-mode))

(defun pen-evil-insert-sexp-before-noevil ()
  (interactive "p")
  (evil-lisp-state-insert-sexp-after)
  (turn-off-evil-mode))

(defun special-lispy-beginning-of-defun-noevil (arg)
  (interactive "p")
  (turn-off-evil-mode)

  (lispy-left 20)
  (deactivate-mark))

(pen-with 'clojure-mode
          (defun cider-doc-thing-at-point ()
            (interactive)
            (cider-doc-lookup (format "%s" (symbol-at-point)))))

(pen-with 'cider-repl
          (defun cider-doc-thing-at-point ()
            (interactive)
            (cider-doc-lookup (format "%s" (symbol-at-point)))))

(pen-with 'slime
          (define-key slime-mode-map (kbd "M-n") nil)
          (define-key slime-mode-map (kbd "M-p") nil))

(defun slime-check-version (version conn))

(setq lispy-completion-method 'helm)

(defun format-sexp-at-point (formatter)
  "Formats sexp code, if selected or on a starting parenthesis."
  (interactive)
  (message "Formatting sexp")
  (cond ((and (lispy-left-p) (not mark-active))
         (save-excursion
           (ekm "m")
           (pen-region-pipe formatter)))
        (mark-active
         (save-mark-and-excursion
           (pen-region-pipe formatter)))
        (t
         (pen-sn (concat formatter " " (pen-q buffer-file-name))))))

(defun format-clojure-at-point ()
  "Formats clojure code, if selected or on a starting parenthesis."
  (interactive)
  (format-sexp-at-point "cljfmt"))

(defun pen-lispy-format-or-company ()
  (interactive)
  ;; if it's left or right. right because i may have selected the sexp
  (if (or (lispy-left-p)
          (lispy-right-p))
      (cond
       ((derived-mode-p 'racket-mode)
        (format-racket-at-point))
       ((derived-mode-p 'clojure-mode)
        (format-clojure-at-point))
       (t
        (special-lispy-tab)))
    (call-interactively 'pen-company-complete)))

(defun pen-lispy-select-parent-sexp ()
  (interactive)

  (if (derived-mode-p 'cider-repl-mode)
      (let* ((lispy-mode nil)
             (fun (key-binding (kbd "M-h"))))
        (if fun
            (call-interactively fun)
          (message "Nothing bound")))
    (call-interactively 'pen-lisp-left-noevil)
    (call-interactively 'er/expand-region)))

(defun pen-lispy-run-inner-sexp (arg)
  (interactive "p")
  (save-excursion
    (if (not (lispy-left-p))
        (pen-lisp-left-noevil arg))
    (pen-lisp-e)))

(defvar lispy-string-edit-mode-map
       (let ((map (make-sparse-keymap))
             (menu-map (make-sparse-keymap "lispy string")))
         (define-key map (kbd "C-c '") 'lispy-edit-string)
         map))

(define-derived-mode lispy-string-edit-mode text-mode "lispy string"
  "Major mode for editing lisp strings.")

(defun emacs-lisp-edit-string ()
  (interactive)
  (if (and (lispy--buffer-narrowed-p)
           (derived-mode-p 'lispy-string-edit-mode))
      (progn
        (pen-region-pipe "q -f")
        (while (lispy--buffer-narrowed-p)
          (ignore-errors (call-interactively 'recursive-widen)))
        (emacs-lisp-mode))
    (if (lispy--in-string-p)
        (save-mark-and-excursion
          (progn (lispy-mark)
                 (call-interactively 'pen-enter-edit-emacs)
                 (lispy-string-edit-mode)
                 (pen-region-pipe "uq"))))))
(defalias 'lispy-edit-string 'emacs-lisp-edit-string)

(pen-require 'pen-selected)

(defun lispy--prin1-to-string (expr offset mode)
  "Return the string representation of EXPR.
EXPR is indented first, with OFFSET being the column position of
the first character of EXPR.
MODE is the major mode for indenting EXPR."
  (let ((lif lisp-indent-function))
    (with-temp-buffer
      (funcall mode)
      (dotimes (_i offset)
        (insert ?\ ))
      (let ((lisp-indent-function lif))
        (lispy--insert expr))
      (buffer-substring-no-properties
       (+ (point-min) offset)
       (point-max)))))

(defun lispy-quotes (arg)
  "Insert a pair of quotes around the point.

When the region is active, wrap it in quotes instead.
When inside string, if ARG is nil quotes are quoted,
otherwise the whole string is unquoted."
  (interactive "P")
  (let (bnd)
    (cond ((region-active-p)
           (if arg
               (lispy-unstringify)
             ;; (pen-region-pipe "q -f")
             (pen-region-pipe "pen-xa cmd-nice-posix")))
          ((and (setq bnd (lispy--bounds-string))
                (not (= (point) (car bnd))))
           (if arg
               (lispy-unstringify)
             (if (and lispy-close-quotes-at-end-p (looking-at "\""))
                 (forward-char 1)
                 (progn (insert "\\\"\\\""))
                 (backward-char 2))))

          (arg
           (lispy-stringify))

          ((lispy-after-string-p "?\\")
           (self-insert-command 1))

          (t
           (lispy--space-unless "^\\|\\s-\\|\\s(\\|[#]")
           (insert "\"\"")
           (unless (looking-at "\n\\|)\\|}\\|\\]\\|$")
             (just-one-space)
             (backward-char 1))
           (backward-char)))))

(defun toggle-lispy-and-selected ()
  (interactive)
  (call-interactively 'lispy-mode)
  (call-interactively 'selected-minor-mode))

(defun lispy-backward-kill-word (arg)
  "Kill ARG words backward, keeping parens consistent."
  (interactive "p")
  (let (bnd
        (pt (point))
        (last-command (if (eq last-command 'lispy-backward-kill-word)
                          'kill-region
                        last-command)))
    (while (and
            (looking-back "\s" 1)
            (or
             (= (point-at-eol) (point))
             (not (looking-at "[^ ]"))))
      (delete-char -1))
    (lispy-dotimes arg
      (when (lispy--in-comment-p)
        (skip-chars-backward " \n"))
      (if (memq (char-syntax (char-before))
                '(?w ?_ ?\s))
          (if (lispy-looking-back "\\_<\\s_+")
              (delete-region (match-beginning 0)
                             (match-end 0))
            (backward-kill-word 1)
            (when (and (lispy--in-string-p)
                       (not (lispy-looking-back "\\\\\\\\"))
                       (lispy-looking-back "\\\\"))
              (delete-char -1)))
        (delete-region (point) pt)
        (while (not (or (bobp)
                        (memq (char-syntax (char-before))
                              '(?w ?_))))
          (backward-char 1))
        (if (setq bnd (lispy--bounds-string))
            (progn
              (save-restriction
                (if (and (looking-at "\\s-+\"")
                         (eq (match-end 0) (cdr bnd)))
                    (goto-char (1- (cdr bnd)))
                  (when (and (> pt (car bnd))
                             (< pt (cdr bnd)))
                    (goto-char pt)))
                (narrow-to-region (1+ (car bnd)) (point))
                (kill-region (progn
                               (forward-word -1)
                               (when (and (not (lispy-looking-back "\\\\\\\\"))
                                          (lispy-looking-back "\\\\"))
                                 (backward-char))
                               (point))
                             (point-max))
                (widen)))
          (backward-kill-word 1))))))

(advice-add 'lispy-eval :around #'ignore-errors-around-advice)

(define-key lispy-mode-map (kbd "e") nil)
(define-key lispy-mode-map (kbd "[") nil)
(define-key lispy-mode-map (kbd "]") nil)
(define-key lispy-mode-map-lispy (kbd "[") nil)
(define-key lispy-mode-map-lispy (kbd "]") nil)
(define-key lispy-mode-map-lispy (kbd "<backtab>") nil)
(define-key lispy-mode-map (kbd "M-n") nil)
(define-key lispy-mode-map-lispy (kbd "M-n") nil)
(define-key lispy-mode-map (kbd "M-p") nil)
(define-key lispy-mode-map-lispy (kbd "M-p") nil)
(define-key pen-lisp-mode-map (kbd "J") 'pen-lisp-expand-contract-selection-right)
(define-key lispy-mode-map (kbd "J") 'pen-lisp-expand-contract-selection-right)
(define-key pen-lisp-mode-map (kbd "K") 'pen-lisp-expand-contract-selection-left)
(define-key lispy-mode-map (kbd "K") 'pen-lisp-expand-contract-selection-left)
;; This function breaks when at the top level of a sexp
(define-key lispy-mode-map (kbd "M-t") 'paredit-forward-slurp-sexp)
(advice-add 'paredit-forward-slurp-sexp :around #'ignore-errors-around-advice)
(define-key global-map (kbd "C-M-f") #'forward-sexp-start)
(define-key lispy-mode-map (kbd "M-0") #'pen-lispy-goto-start)
(define-key lispy-mode-map (kbd "M-W") #'pen-lispy-mark-symbol)
(define-key lispy-mode-map (kbd "M-j") #'lispy-mark-symbol)
(define-key lispy-mode-map (kbd "M-A") #'pen-lispy-mark-car)
(define-key lispy-mode-map (kbd "M-F") nil)
(define-key lispy-mode-map (kbd "C-M-a") #'special-lispy-beginning-of-defun-noevil)
(define-key lispy-mode-map (kbd "C-M-i") 'pen-lispy-format-or-company)
(define-key lispy-mode-map (kbd "M-h") 'pen-lispy-select-parent-sexp)
(define-key lispy-mode-map (kbd "\"") nil)
(define-key lispy-mode-map (kbd "M-d") nil)
(define-key lispy-mode-map (kbd "S") nil)
(define-key lispy-mode-map (kbd "M-W") #'pen-lispy-run-inner-sexp)
(define-key lispy-mode-map (kbd "M-.") nil)
(define-key lispy-mode-map (kbd "M-k") nil)
(define-key lispy-mode-map (kbd "M-q") nil)
(define-key lispy-mode-map (kbd "M-m") nil)
(define-key lispy-mode-map (kbd "C-c '") 'lispy-edit-string)
(define-key lispy-string-edit-mode-map (kbd "C-c '") 'lispy-edit-string)
(define-key lispy-mode-map (kbd "C-h") 'selected-backspace-delete-and-deselect)
(define-key lispy-mode-map (kbd "M-o") 'toggle-lispy-and-selected)
(define-key pen-map (kbd "C-x M-o") 'toggle-lispy-and-selected)
(define-key lispy-mode-map (kbd "M-RET") nil)
(define-key lispy-mode-map (kbd "M-s [") 'geiser-squarify)

(provide 'pen-lispy)
