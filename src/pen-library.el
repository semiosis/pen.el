(require 'sx)
(require 'async)

(defalias 's-replace-regexp 'replace-regexp-in-string)

(require 'pen-aliases)

(defun pen-f-basename (path)
  (s-replace-regexp ".*/" "" (or path
                                 "")))

(defun f-mant (path)
  (s-replace-regexp "\\..*" "" (pen-f-basename path)))

(defalias 'f-basename 'f-filename)
(defun f-mant (path)
  (s-replace-regexp "\\..*" "" (pen-f-basename path)))

(defalias 'sym2str 'symbol-name)
(defalias 'str2sym 'intern)

;; The semantic path needs to be an association list, and add to that with contrib plugins
;; The semantic path / topic should always be visible or accessible
;; This way, it's easy to correct problems
(defun get-path-semantic ()
  (interactive)
  (cond
   ((derived-mode-p 'org-brain-visualize-mode)
    (org-brain-pf-topic))
   ((pen-is-glossary-file (get-path nil t))
    (pen-get-glossary-topic (get-path nil t)))
   (t (pen-detect-language))))

(defun get-temp-fp ()
  "Create a temp file with appropriate extension, but don't assign to the current buffer"
  (interactive)

  (let ((tf (make-temp-file nil nil (concat "." (get-ext-for-mode major-mode)))))

    (write-to-file (buffer-string) tf)))

(defun save-temp-if-no-file ()
  "Creates a file path for the buffer if the buffer doesn't have one. Otherwise, does nothing."
  (interactive)

  (if (not (buffer-file-name))
      (let ((bn (buffer-name)))
        (if (or (equal bn "*scratch*")
                (equal bn "*Messages*")
                (equal bn "*Warnings*")
                ;; no-create-path
                )
            (let ((nb (new-buffer-from-string (buffer-string))))
              (with-current-buffer nb
                (write-file
                 (make-temp-file nil nil (concat "." (get-ext-for-mode major-mode)))))
              (switch-to-buffer nb))
          (write-file
           (make-temp-file nil nil (concat "." (get-ext-for-mode major-mode))))))))

(defun f-realpath (path &optional dir)
  (if path
      (chomp (pen-sn (concat "realpath " (pen-q path) " 2>/dev/null") nil dir))))

(defalias 'major-mode-enabled 'derived-mode-p)

(defmacro pen-nil (body)
  "Do not return anything."
  ;; body
  `(progn (,@body) nil))

(defun buffer-file-path ()
  (if (derived-mode-p 'eww-mode)
      (or (eww-current-url)
          eww-followed-link)
    (try (f-realpath (or (buffer-file-name)
                         (and (string-match-p "~" (buffer-name))
                              (concat (projectile-project-root) (sed "s/\\.~.*//" (buffer-name))))
                         (error "no file for buffer")))
         nil)))
(defalias 'full-path 'buffer-file-path)

;; This is usually used programmatically to get a single path name
(defun get-path (&optional soft no-create-path for-clipboard semantic-path keep-buffer-name)
  "Get path for buffer. semantic-path means a path suitable for google/nl searching"
  (interactive)

  (let ((bn (current-buffer-name)))
    (setq semantic-path (or
                         semantic-path
                         (>= (prefix-numeric-value current-prefix-arg) 4)))

    "If it's just for the clipboard then we can copy"
    ;; (xc-m (f-realpath (buffer-file-name)))
    (let ((path
           (or (and (eq major-mode 'Info-mode)
                    (if soft
                        (concat "(" (basename Info-current-file) ") " Info-current-node)
                      (concat Info-current-file ".info")))

               (and (major-mode-enabled 'eww-mode)
                    (s-replace-regexp "^file:\/\/" ""
                                      (url-encode-url
                                       (or (eww-current-url)
                                           eww-followed-link))))

               (and (major-mode-enabled 'sx-question-mode)
                    (sx-get-question-url))

               (and (major-mode-enabled 'w3m-mode)
                    w3m-current-url)

               (and (major-mode-enabled 'org-brain-visualize-mode)
                    (org-brain-get-path-for-entry org-brain--vis-entry semantic-path))

               (and (major-mode-enabled 'ranger-mode)
                    (dired-copy-filename-as-kill 0))

               (and (major-mode-enabled 'dired-mode)
                    (sor (and
                          for-clipboard
                          (mapconcat 'pen-q (dired-get-marked-files) " "))
                         (pen-pwd)))

               ;; This will break on eww
               (if (and (not (eq major-mode 'org-mode))
                        (string-match-p "\\[\\*Org Src" (or (buffer-file-name) "")))
                   (s-replace-regexp "\\[\\*Org Src.*" "" (buffer-file-name)))
               (buffer-file-name)
               (try (buffer-file-path)
                    nil)
               dired-directory
               (progn
                 (if (not no-create-path)
                     (progn
                       (save-temp-if-no-file)
                       (if keep-buffer-name
                           (rename-buffer bn))))
                 (let ((p (full-path)))
                   (if (stringp p)
                       (chomp p)))))))
      (if (interactive-p)
          (xc path)
        path))))

(defun pen-button-get-link (pen-b)
  (cond
   ((eq (button-get pen-b 'face) 'glossary-button-face)
    (concat "[[y:" (button-get-text pen-b) "]]"))
   (t nil)))

(defun pen-clean-up-copy-link (rawlink)
  (setq rawlink (s-replace-regexp "^(\\(.*\\))$" "\\1" rawlink))
  (setq rawlink (s-replace-regexp "^[\"]\\(.*\\)[\"]$" "\\1" rawlink))
  (setq rawlink (s-replace-regexp "^\\([a-z]+\\.[a-z]+\\/\\)" "http://\\1" rawlink)) ;go import
  rawlink)

(defun glossary-button-at-point ()
  (let ((p (point))
        (pen-b (button-at-point)))
    (if (and
         pen-b
         (eq (button-get pen-b 'face) 'glossary-button-face))
        pen-b
      nil))
  (button-at-point))
(defalias 'glossary-button-at-point-p 'glossary-button-at-point)

(defun pen-equals (a pen-b)
  (if (stringp pen-b)
      (string-equal a pen-b)
    (eq a pen-b)))
(defalias 'pen-eq 'pen-equals)

(defun pen-error-if-equals (thing badval)
  "error if it equals something, otherwise pass it on"
  (if (pen-equals thing badval)
      (error "pen-error-if-equals received bad value")
    thing))

;; I want a universal semantic path function for Pen.el, that's why these are important
(defun pen-calibre-copy-org-link (&optional cand)
  (interactive (list (calibredb-find-candidate-at-point)))

  (if (not cand)
      (setq cand (calibredb-find-candidate-at-point)))
  (let* ((path (calibredb-getattr (car cand) :file-path))
         (title (calibredb-getattr (car cand) :book-title))
         (link (concat "[[calibre:" title "]]")))
    (if (interactive-p)
        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (xc path)
          (xc link))
      link)))

(defun calibredb-org-link-copy-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (xc)
    res))
(advice-add 'calibredb-org-link-copy :around #'calibredb-org-link-copy-around-advice)
;; (advice-remove 'calibredb-org-link-copy #'calibredb-org-link-copy-around-advice)

;; j:pen-copy-link-at-point
(defun link-at-point ()
  "Copy the link with the highest priority at the point."
  (interactive)
  (try
   ;; (progn (pen-error-if-equals (link-hint--action-at-point :copy) "There is no link supporting the :copy action at the point.")
   ;;        (e/xc))
   (pen-error-if-equals (calibre-copy-org-link) "[[calibre:]]")
   ;; (pen-error-if-equals (calibredb-org-link-copy) "[[calibredb:nil][ nil - nil]]")
   (pen-error-if-equals (pen-button-get-link (glossary-button-at-point)) nil)
   (pen-error-if-equals (pen-clean-up-copy-link (plist-get (link-hint--get-link-at-point) :args)) nil)
   (pen-error-if-equals (chomp (pen-sn "xurls" (str (thing-at-point 'sexp)))) "")
   (pen-error-if-equals (chomp (pen-sn "xurls" (str (thing-at-point 'url)))) "")
   (pen-error-if-equals (chomp (pen-sn "xurls" (str (thing-at-point 'line)))) "")
   ""))

(defun pen-copy-link-at-point ()
  "Copy the link with the highest priority at the point."
  (interactive)
  (xc (link-at-point)))

(defun get-path-for-thing (&optional soft no-create-path for-clipboard semantic-path)
  "Get path for thing at point.
This is like clicking on the thing and then getting its path.
Or it could be an org-link, or hyperlink, say.
semantic-path means a path suitable for google/nl searching"
  (interactive)

  (if (not semantic-path)
      (call-interactively 'pen-copy-link-at-point)
    ;; Haven't decided yet how to get the semantic path of something without being there
    (call-interactively 'pen-copy-link-at-point)))

(defun get-path-nocreate ()
  (get-path nil t))

(defun read-char-picky (prompt chars &optional inherit-input-method seconds)
  "Read characters like in `read-char-exclusive', but if input is
not one of CHARS, return nil.  CHARS may be a list of characters,
single-character strings, or a string of characters."
  (let ((chars (mapcar (λ (x)
                         (if (characterp x) x (string-to-char x)))
                       (append chars nil)))
        (char  (read-char-exclusive prompt inherit-input-method seconds)))
    (when (memq char chars)
      char)))

(defmacro pen-sw (expr &rest body)
  "Switch; cond for strings. Probably should use pcase instead. The syntax is the same"
  (let ((b
         (mapcar
          (λ (e)
            (list
             (list 'string-equal expr (car e))
             (cadr e)))
          body)))
    `(
      cond
      ,@b)))

(defun test-sw ()
  (interactive)
  (etv
   (sw "hello"
     ("hello" "hi"))))

(defmacro pen-qa (&rest body)
  ""
  (let ((m
         (pen-list2str (cl-loop for i from 0 to (- (length body) 1) by 2
                                collect
                                (pp-oneline
                                 (list
                                  (try
                                   (symbol-name
                                    (nth i body))
                                   (str
                                    (nth i body)))
                                  (nth (+ i 1) body))))))
        (code
         (cl-loop for i from 0 to (- (length body) 1) by 2
                  collect
                  (let ((fstone (nth i body))
                        (sndone (nth (+ i 1) body)))
                    (list
                     (string-to-char
                      (string-reverse
                       (symbol-name
                        fstone)))
                     sndone)))))
    (append
     `(case
          (let ((r))
            (save-window-excursion
              (let ((pen-b (nbfs ,m)))
                (switch-to-buffer pen-b)
                (setq r (read-key ""))
                (kill-buffer pen-b)))
            r))
     code)))

(defun pen-ask (thing &optional prompt)
  (interactive)
  (read-string-hist
   (or prompt
       (concat "pen-ask: "))
   thing))

(defalias 'ask 'pen-ask)

(cl-defun pen-topic (&optional short semantic-only &key no-select-result)
  "Determine the topic used for pen functions"
  (interactive)

  (let* ((no-select-result
          (or no-select-result
              (pen-var-value-maybe 'do-pen-batch)))
         (topic
          (cond ((pen-is-glossary-file (buffer-file-path))
                 (get-path-semantic))
                ((derived-mode-p 'org-brain-visualize-mode)
                 (progn (require 'pen-org-brain)
                        (org-brain-pf-topic short)))
                ;; File path is not a good topic
                ;; ((not semantic-only)
                ;;  (let ((current-prefix-arg '(4))) ; C-u
                ;;    ;; Consider getting topic keywords from visible text
                ;;    (get-path nil t)))
                ((not short)
                 (if no-select-result
                     (pen-single-generation
                      (car
                       (pf-keyword-extraction/1
                        (pen-screen-words)
                        :no-select-result no-select-result
                        ;; :no-select-result t
                        ;; (pen-surrounding-text)
                        )))
                   (pf-keyword-extraction/1
                    (pen-screen-words)
                    ;; :no-select-result t
                    ;; (pen-surrounding-text)
                    )))
                (t ""))))

    (setq topic
          (cond
           ((derived-mode-p 'prog-mode)
            (s-join " " (-filter-not-empty-string (list (sor (str (pen-detect-language))) (sor topic)))))
           ((string-equal topic "solidity") "solidity, ethereum")
           (t topic)))

    (if (interactive-p)
        (pen-etv topic)
      topic)))

(defun pen-broader-topic ()
  "Determine the topic used for pen functions"
  (interactive)

  (let ((topic (get-path nil nil nil t)))
    (if (interactive-p)
        (pen-etv topic)
      topic)))

(defun pen-select-function-from-nl (use-case)
  (interactive (list (read-string "pen-select-function-from-nl use-case: ")))
  (let* ((lang ;; (pen-detect-language-ask)
          (read-string-hist "pen-select-function-from-nl lang: "))
         (funs (pf-find-a-function-given-a-use-case/2 lang use-case :no-select-result t))
         (sigs (pf-get-the-signatures-for-a-list-of-functions/2 lang (list2str funs) :no-select-result t)))
    (xc (fz (-zip-lists funs sigs) nil nil "pen-select-function-from-nl: "))))

(defun pen-imagine-awk-linting ()
  (interactive)
  (message "Please wait...")
  (let* ((sel (str (pen-selection)))
         (lines (s-lines sel))
         ;; (l (pen-etv (list2str lines)))
         (lintings
          (list2str
           (cl-loop for l in lines collect
                 (progn
                   (message "%s" (concat "linting " l))
                   (car (pen-single-generation
                         (pf-imagine-an-awk-linter/1 l :no-select-result t :select-only-match))))))))
    (pen-etv lintings)))


;; TODO Make a prompt which detects either prose or code
;; is-code, or is-prose, then prompt twice?

;; Or one prompt which returns prose, code or unknown/other
;; This would be the better prompt

;; It's important to stick to haskell


;; DONE Make a Hyper binding for transforming prose or code using NL
;; This should be super easy.
;; I don't have a cheap version of this yet.
(defun pen-code-p ()
  "prose or code; t if code"
  ;; test for prog-mode
  (major-mode-p 'prog-mode))

(defalias 'pen-mode-prose-or-code-p 'pen-code-p)

;; I need to force this to filter
(comment
 (defun pen-transform ()
   (interactive)
   ;; (save-excursion-and-region-reliably (replace-region (selection)))
   ;; These are actually incompatible

   ;; A current-prefix-arg of 1 seems to be default, so only use it if it's not 1
   (save-excursion-and-region-reliably
    (let ((window-size (or (and (not (equal 1 (prefix-numeric-value current-prefix-arg)))
                                (prefix-numeric-value current-prefix-arg))
                           10)))
      (let ((current-prefix-arg nil))
        ;; TODO detect prose/code
        ;; TODO Make it select the surrounding text so it can be transformed
        (let ((context (if mark-active
                           (pen-selected-text)
                         (pen-surrounding-text window-size t))))
          (pen-filter
           (call-interactively 'pf-transform-code/3))))))))

(defun pen-transform ()
  (interactive)
  ;; pen-mode-prose-or-code-p
  (call-interactively 'pen-transform-code))

(defun pen-transform-code ()
  (interactive)
  ;; TODO Make it so if this function is cancelled, the cursor is returned to the original place.
  ;; That is because this function creates a region selection if nothing is selected.

  ;; A current-prefix-arg of 1 seems to be default, so only use it if it's not 1
  (let ((window-size (or (and (not (equal 1 (prefix-numeric-value current-prefix-arg)))
                              (prefix-numeric-value current-prefix-arg))
                         10)))
    (let ((current-prefix-arg nil))
      ;; TODO detect prose/code
      ;; TODO Make it select the surrounding text so it can be transformed
      (let ((context (if mark-active
                         (pen-selected-text)
                       (pen-surrounding-text window-size t))))
        (replace-region
         (pf-transform-code/3 context nil nil)
         ;; (call-interactively 'pf-transform-code/3)
         )))))

(defun pen-transform-prose ()
  (interactive)
  ;; TODO Make it so if this function is cancelled, the cursor is returned to the original place.
  ;; That is because this function creates a region selection if nothing is selected.

  ;; A current-prefix-arg of 1 seems to be default, so only use it if it's not 1
  (let ((window-size (or (and (not (equal 1 (prefix-numeric-value current-prefix-arg)))
                              (prefix-numeric-value current-prefix-arg))
                         10)))
    (let ((current-prefix-arg nil))
      ;; TODO detect prose/code
      ;; TODO Make it select the surrounding text so it can be transformed
      (let ((context (if mark-active
                         (pen-selected-text)
                       (pen-surrounding-text window-size t))))
        (replace-region
         (pf-transform-prose/2 context)
         ;; (call-interactively 'pf-transform-code/3)
         )))))

(defun pen-insert-snippet-from-lm ()
  (interactive)
  (let ((snippet
         (pf-code-snippet-from-natural-language/2
          (pen-detect-language-ask "pen-insert-snippet-from-lm lang: ")
          (read-string-hist
           "pen-insert-snippet-from-lm nl task: "))))
    (if (interactive-p)
        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (pen-etv snippet)
          (insert snippet))
      snippet)))

(defun pen-autofix-lsp-errors ()
  (interactive)
  (let* ((s (pen-buffer-string-or-selection t))
         (errors
          (if (>= (prefix-numeric-value current-prefix-arg) 4)
              (read-string-hist "pen-autofix-lsp-errors errors: ")
            (pen-list2str (pen-lsp-error-list))))
         (fixed (pf-autofix-code/2
                 errors
                 s)))
    (pen-replace-region fixed)))

(defun pen-start-gui ()
  (interactive)
  (if (pen-has-gui-p)
      (pen-sn "penx" nil nil nil t)
    (error "Display not available")))

(defun xterm (cmd)
  (pen-sn (concat "xt in-pen in-tm " cmd) nil nil nil t))
(defalias 'xt 'xterm)
(defalias 'pen-xt 'xterm)

(defun pen-start-in-xterm ()
  (interactive)
  (if (pen-has-gui-p)
      (pen-sn "xt tm init pin" nil nil nil t)
    (error "Display not available")))

(defmacro never (&rest body)
  "Do not run this code"
  `(if nil
       (progn
         ,@body)))

(defun short-hash (input)
  "Probably a CRC hash of the input."
  (chomp (pen-snc "short-hash" input)))

(defun uniqify-buffer (b)
  "Give the buffer a unique name"
  (with-current-buffer b
    (ignore-errors (let* ((hash (short-hash (str (time-to-seconds))))
                          (new-buffer-name (pcre-replace-string "(\\*?)$" (concat "-" hash "\\1") (current-buffer-name))))
                     (rename-buffer new-buffer-name)))
    b))

(defun pen-local-variable-p (sym)
  (and (variable-p sym)
       (local-variable-p sym)))
(defalias 'pen-lvp 'pen-local-variable-p)

(defun irc-find-line-with-diff-char (&optional step)
  (interactive)
  (if (not step)
      (setq step -1))
  ;; (message "%s" (str step))
  (let ((start-col (current-column))
        (start-ch (char-after (point))))
    (cl-loop
     while (zerop (forward-line step))
     when
     (or
      (cljr--end-of-buffer-p)
      (and (not (string-equal "\n" (str (thing-at-point 'line))))
           (not (string-equal " " (str (thing-at-point 'char))))
           (not (string-equal "	" (str (thing-at-point 'char))))
           (= (move-to-column start-col) start-col)
           (/= (char-after (point)) start-ch)
           (/= (char-after (point)) (string-to-char " "))))
     return t)))

(defun irc-find-prev-line-with-diff-char ()
  (interactive)
  (irc-find-line-with-diff-char -1))

(defun irc-find-next-line-with-diff-char ()
  (interactive)
  (irc-find-line-with-diff-char 1))

(defmacro mtv (o)
  "This might do an etv. It will do an etv if it was called interactively"

  ;; This must be a macro so that when mtv is 'called', it gets its interactive status from the its calling function
  `(if (interactive-p)
       (pen-etv ,o)
     ,o))

(defun buffer-exists (bufname)
  (not (eq nil (get-buffer bufname))))
(defalias 'buffer-match-p 'buffer-exists)

(defmacro pen-b (&rest body)
  "Runs a shell command
Write straight bash within elisp syntax (it looks like emacs-lisp)"
  `(pen-sn (e-cmd ,@body)))

(defmacro echo (&rest body)
  `(pen-b echo ,@body))

(defun e (path)
  (interactive)
  (if path
      (find-file (eval `(echo -n ,path)))))

(defun recursive-widen ()
  "Replacement of widen that will only pop one level of visibility."
  (interactive)
  (let (widen-to)
    (if recursive-narrow-settings
        (progn
          (setq widen-to (pop recursive-narrow-settings))
          (narrow-to-region (car widen-to) (cdr widen-to))
          (recenter))
      (widen))))

(defun delay-kill-buffer (&optional b)
  (let ((buf (or b (current-buffer))))
    (run-with-timer
     2 nil
     (eval
      `(λ ()
         (kill-buffer ,buf))))))

(defun pen-maybe-delay-kill-buffer (&optional b)
  (let ((buf (or b (current-buffer))))
    (with-current-buffer buf
      (if (major-mode-p 'term-mode)
          (progn
            (ignore-errors (term-kill-subjob))
            (delay-kill-buffer b)
            (bury-buffer b))
        (kill-this-buffer)))))

(defun pen-kill-this-buffer-volatile (&optional buffer-name)
  "Kill current buffer, even if it has been modified."
  (interactive)

  ;; Kill the process and bury the buffer
  ;; Use bury buffer
  
  (if buffer-name
      (switch-to-buffer buffer-name))
  (set-buffer-modified-p nil)

  (cond
   ((major-mode-p 'ranger-mode) (ranger-close))
   (t (let ((win (selected-window))
            (isterm (major-mode-p 'term-mode)))
        (pen-maybe-delay-kill-buffer)
        (if (or (and (local-variable-p 'kill-window-when-done)
                     kill-window-when-done)
                isterm)
            (if (eq win (selected-window))
                (try
                 (pen-kill-buffer-and-window t)

                 ;; when killing pet with pen-kill-buffer-immediately
                 ;; pen-kill-buffer-and-window will error. On that case,
                 ;; delete the frame
                 (delete-frame))))))))

(defalias 'pen-kill-buffer-immediately 'pen-kill-this-buffer-volatile)

(defun pen-kill-buffer-and-reopen ()
  (interactive)
  ;; I need goto-point because save-excursion doesn't work with .gz files
  (let ((p (point)))
    (ignore-errors
      (save-mark-and-excursion
        (remove-overlays (point-min) (point-max))
        ;; When it reverts, it may rebuttonize
        (revert-buffer nil t)))

    ;; This is a hack to fix the narrowing bug
    (progn
      (call-interactively 'recursive-widen)
      (remove-overlays (point-min) (point-max)))

    (goto-char p))

  ;; (let ((pos (point)))
  ;;   (save-excursion
  ;;     (with-current-buffer
  ;;         (revert-buffer nil t)))
  ;;   (goto-char pos))

  ;; The following worked when undo-tree was on
  (never
   (if (not (current-path))
       (save-temp-if-no-file))
   (let ((pos (point))
         (path (current-path))
         (pen-b (current-buffer)))
     (if (f-exists-p path)
         (progn
           (kill-buffer pen-b)
           ;; (let ((bb (find-file path)))
           ;;   (etv bb))
           ;; (with-current-buffer
           ;;     (find-file path))
           (with-current-buffer
               (find-file path)
             (goto-char pos)
             ;; (eval '(pen-generate-glossary-buttons-over-buffer nil nil t))

             ;; This is actually necessary
             ;; (eval '(redraw-glossary-buttons-when-window-scrolls-or-file-is-opened))
             (pen-run-buttonize-hooks)

             (message "%s" (concat "killed + reloaded: " (mnm path)))
             ;; (recenter-top-bottom)

             ;; (ekm "C-l C-l")

             ;; This was ok, but it's more seamless to not have it, particularly when I have that position resuming package working
             ;; (recenter-top)
             ))))))

(defun pen-yank-path ()
  (interactive)
  (if (pen-selected-p)
      (with-current-buffer (new-buffer-from-string (selection))
        (pen-guess-major-mode-set)
        (xc (get-path nil nil t))
        (kill-buffer))
    (xc (get-path))))

(defun unslugify (input)
  (pen-snc "unslugify" input))

(defmacro remove-from-list (list-var elt)
  `(set ,list-var (delete ,elt ,(eval list-var))))

(defmacro defset-local (symbol value &optional documentation)
  "Instead of doing a defvar and a setq, do this. [[http://ergoemacs.org/emacs/elisp_defvar_problem.html][ergoemacs.org/emacs/elisp_defvar_problem.html]]
Interestingly, defvar-local does not come into effect until run, but I guess defset-local would, because it has a set."

  `(progn (defvar-local ,symbol ,documentation)
          (setq-local ,symbol ,value)))

(defun pen-list-signatures-for-client ()
  (cl-loop for nm in pen-prompt-functions collect
           (downcase (replace-regexp-in-string " &key.*" ")" (helpful--signature nm)))))

(defun pen-uuid ()
  (uuidgen-4))

(defun pen-shorten-for-uuid (s)
  (substring s 0 8))

(defun pen-uuid-short ()
  (pen-shorten-for-uuid (uuidgen-4)))

(defun pen-prev-prop-change (prop)
  (let ((p (previous-single-property-change (point) prop)))
    (if p
        (goto-char p))))

(defun pen-next-prop-change (prop)
  (let ((p (next-single-property-change (point) prop)))
    (if p
        (goto-char p))))

(defun pen-select-propertised-text (loc prop)
  (interactive (list
                (point)
                (intern (read-string "prop symbol name: "))))

  (let ((val (lax-plist-get (text-properties-at (point)) prop)))
    (goto-char loc)

    (if val
        (let
            ((prev (pen-prev-ink))
             (p (next-single-property-change (point) prop)))
          (if p
              (goto-char p))))))

(defun pen-unfinished-sentence (&optional text)
  (setq text (or text (pen-preceding-text)))
  (pen-sn "pen-str join \" \"" (pen-preceding-sentences text 0)))

(defun e/sps (&optional run)
  (interactive)
  (split-window-sensibly)
  (other-window 1)
  (if run
      (call-interactively run)))
(defalias 'esps 'e/sps)

(defun pen-current-filename-maybe ()
  (sor (pen-f-basename (get-path nil t)) "untitled"))

;; echo hi | pen-eipe -data '{"buttons": [{"label": "Abort", "command": "pen-revert-kill-buffer-and-window", "type": "off-button"},{"label": "Accept", "command": "pen-save-and-kill-buffer-window-and-emacsclient", "type": "on-button"}]}'
(defun pen-eipe (input &optional chomp wintype
                       prompttext
                       helptext
                       overlay-text
                       preoverlay-text
                       data
                       detach)
  "`prompttext` is read-only text at the start of the
buffer which is not included when this function returns"

  (setq wintype (or (sor wintype)
                    "sps"))

  (if (not (sor data))
      (setq data "{\"buttons\": [{\"label\": \"Abort\", \"command\": \"pen-revert-kill-buffer-and-window\", \"type\": \"off-button\"},{\"label\": \"Accept\", \"command\": \"pen-save-and-kill-buffer-window-and-emacsclient\", \"type\": \"on-button\"}]}"))

  (if (display-graphic-p)
      (pen-sn (pen-cmd "xt pen-eipe"
                     "-pt" prompttext
                     "-help" helptext
                     "-ov" overlay-text
                     "-pov" preoverlay-text
                     "-data" data)
            input nil nil detach nil nil nil chomp)
    (pen-sn (pen-cmd "pen-tvipe"
                       "-wintype" wintype
                       "-cl" (pen-cmd "pen-eipe"
                                      "-pt" prompttext
                                      "-help" helptext
                                      "-ov" overlay-text
                                      "-pov" preoverlay-text
                                      "-data" data))
            input nil nil detach nil nil nil chomp)))

(defun pen-eipec (input &optional wintype prompttext helptext overlaytext preoverlaytext data detach)
  (pen-eipe input t wintype prompttext helptext overlaytext preoverlaytext data detach))

(defun pen-internet-connected-p ()
  (pen-snq "internet-connected-p"))

(defalias 'internet-connected-p 'pen-internet-connected-p)

(defvar pen-tutor-common-questions
  '("What is <1:q> used for?"
    "What are some good learning materials"))

(defun pen-tutor-mode-assist (&optional query)
  (interactive (let* ((bl (pen-detect-language t t nil t)))
                 (list
                  (read-string-hist
                   (concat "asktutor (" bl "): ")
                   (pen-thing-at-point)))))
  (let ((bl (pen-detect-language t t nil t)))
    (pf-asktutor bl bl query)))

(defun pen-of-imagination ()
  (interactive)
  (eval
   `(pen-use-vterm
     (pen-sps "pen-of-imagination"))))

(defun switch-to-previous-buffer ()
  (interactive)
  (if (string-equal (current-major-mode-string) "ranger-mode")
      (ranger-close)
    (switch-to-buffer (other-buffer (current-buffer) 1))))

(defmacro pen-with (package &rest body)
  "This attempts to run code dependent on a package and otherwise doesn't run the code."
  `(when (require ,package nil 'noerror)
     ,@body))

(defun pen-trim-max-chars (s n)
  (pen-sn (concat "pen-str trim-max-chars " (str n))
          s))

(defun pen-str-add-trailing-space-if-not-empty (s)
  (if (sor s)
      (concat s " ")
    s))

(defun -uniq-u (l &optional testfun)
  "Return a copy of LIST with all non-unique elements removed."

  (if (not testfun)
      (setq testfun 'equal))

  ;; Here, contents-hash is some kind of symbol which is set

  (setq testfun (define-hash-table-test 'contents-hash testfun 'sxhash-equal))

  (let ((table (make-hash-table :test 'contents-hash)))
    (cl-loop for string in l do
             (puthash string (1+ (gethash string table 0))
                      table))
    (cl-loop for key being the hash-keys of table
             unless (> (gethash key table) 1)
             collect key)))

(defun async-pf (prompt-function callback-fn &rest args)
  (let ((tf (make-temp-file "async-pf-")))
    (async-start-process
     (concat "pen-async-pf-" (str (date-ts)))
     (eval `(pen-nsfa (pen-cmd "pen-run-and-write" tf "unbuffer" "pen" "-u" "--pool" (str prompt-function) ,@args)))
     (eval
      `(λ (proc)
         (apply ',callback-fn (list (chomp (cat ,tf))))
         (f-delete ,tf))))))

(defun pen-container-name ()
  (pen-snc "cat ~/pen_container_name.txt"))

(defalias 'tr 's-replace)

(defmacro lk (call)
  "Create interactive function from function symbol. Create a name for it based on the first arg. Propagate interactive arg"
  (let* ((symname (car call))
         (args (cdr call))
         (newsymname (intern (concat "in-" (symbol-name symname) "-" (slugify (tr "\n" "_" (pen-list2str args)))))))
    `(defun
         ,newsymname
         (arg)
       (interactive "P")
       (call-command-or-function
        ',symname
        ,@args))))

(defun list2string (list)
  "Convert a list to a newline delimited string."
  (mapconcat 'str list "\n"))

(defmacro defshellfilter (&rest body)
  "Define a new string filter function based on a shell command"
  (let* ((base (slugify (list2string body) t))
         (sm (intern (concat "sh/m/" base)))
         (sf (intern (concat "sh/" base)))
         (sfptw (intern (concat "sh/ptw/" base))))
    `(progn (defmacro ,sm
                (&rest body)
              `(pen-bp ,@',body ,@body))
            (defun ,sf
                (&rest body)
              (eval `(pen-bp ,@',body ,@body)))
            ;; This last one is the thing the function returns.
            (defun ,sfptw
                (&rest body)
              (eval `(ptw ',',sf ,@body))))))

(defmacro defshellfilter-new-buffer-mode (mode &rest body)
  (let* ((base (slugify (list2string body) t))
         (sf (intern (concat "sh/" base)))
         (sf-nb (intern (concat "sh/nb/" base))))
    `(progn
       (defshellfilter ,@body)
       (defun ,sf-nb (s)
         (interactive (list (pen-buffer-string-or-selection)))
         (new-buffer-from-string (eval `(,',sf ,s)) nil ,mode)
         s))))
(defmacro defshellfilter-new-buffer (&rest body)
  (let* ((base (slugify (list2string body) t))
         (sf (intern (concat "sh/" base)))
         (sf-nb (intern (concat "sh/nb/" base))))
    `(progn
       (defshellfilter ,@body)
       (defun ,sf-nb (s)
         (interactive (list (pen-buffer-string-or-selection)))
         (new-buffer-from-string-detect-lang (eval `(,',sf ,s)))
         s))))

(defmacro defshellfilter-new-buffer-cmd (cm ext)
  (let* ((base (slugify (list2string cm) t))
         (sf (intern (concat "sh/" base)))
         (sfptw-nb (intern (concat "sh/ptw/nb/" base))))
    `(progn
       (defshellfilter ,@body)
       (defun ,sfptw-nb (s)
         (new-buffer-from-string (eval `(ptw ',',sf ,s)))
         s))))

(defmacro defshellcommand (&rest body)
  "Define a new string output function based on a shell command"
  (let ((sm (intern (concat "sh/m/" (slugify (list2string body) t))))
        (sf (intern (concat "sh/" (slugify (list2string body) t)))))
    `(progn (defmacro ,sm
                (&rest body)
              `(pen-b ,@',body ,@body))
            (defun ,sf
                (&rest body)
              (eval `(pen-b ,@',body ,@body))))))

(defmacro defshellinteractive (&rest body)
  (let ((sf (intern (concat "sh/t/" (slugify (list2string body) t))))
        (sfhist (intern (concat "sh/t/" (slugify (list2string body) t) "-history")))
        (cm (mapconcat 'str body " ")))
    `(defun ,sf (args)
       (interactive (list (read-string "args:" "" ',sfhist)))
       (eval `(pen-sph (concat ,,cm " " ,args))))))


;; Override this to use message-no-echo
(defun toggle-truncate-lines-local (&optional arg)
  "Toggle truncating of long lines for the current buffer.
When truncating is off, long lines are folded.
With prefix argument ARG, truncate long lines if ARG is positive,
otherwise fold them.  Note that in side-by-side windows, this
command has no effect if `truncate-partial-width-windows' is
non-nil."
  (interactive "P")
  (setq truncate-lines
	      (if (null arg)
	          (not truncate-lines)
	        (> (prefix-numeric-value arg) 0)))
  (force-mode-line-update)
  (unless truncate-lines
    (let ((buffer (current-buffer)))
      (walk-windows (λ (window)
		                  (if (eq buffer (window-buffer window))
			                    (set-window-hscroll window 0)))
		                nil t)))
  (pen-message-no-echo "Truncate long lines %s"
	                     (if truncate-lines "enabled" "disabled")))

(defun pen-truncate-lines (on_or_off)
  (if (not on_or_off)
      (progn
        (visual-line-mode 1)
        (setq truncate-lines nil)
        (setq-default truncate-lines nil))
    (progn
      (visual-line-mode -1)
      (setq truncate-lines t)
      (setq-default truncate-lines t))))

(defun tuple-swap (tp)
  (list (car (cdr tp)) (car tp)))

(defun toggle-truncate-lines (arg)
  (interactive "P")
  (pen-truncate-lines (not truncate-lines)))

(defun pen-nsfa (cm &optional dir input)
  (let ((qdir (pen-q dir)))
    (pen-sn (concat
             (if dir (concat " cd " qdir "; "
                             " CWD=" qdir " ")
               "")
             " pen-nsfa -resize -E " (pen-q cm)) input (or dir (cwd)))))

(defun cursor-at-region-start-p ()
  "If the cursor is at the start of the region"
  (and (region-active-p) (= (point) (region-beginning))))

(defun pen-concat (&rest body)
  "Converts to string and concatenates."
  (mapconcat 'str body ""))

(defmacro dk (name binding f)
  `(define-key ,name (kbd ,binding) ,f))

(defmacro uk (name binding)
    `(define-key ,name (kbd ,binding) nil))

(defun yanked ()
  "Simply return the last string that was copied."
  (current-kill 0))

(defun current-major-mode-string ()
  "Get the current major mode as a string."
  (str major-mode))
(defalias 'current-major-mode 'current-major-mode-string)

(defun pen-previous-defun (arg)
  (interactive "P")
  (cond
   ((string= (current-major-mode) "slime-xref-mode") (call-interactively 'slime-xref-prev-line))
   ;; I can't figure out how to bind the fuzzyfinders in pen.el
   ;; ivy uses minibuffer-inactive-mode. Though I should still test for ivy
   ((string= (current-major-mode) "minibuffer-inactive-mode") (call-interactively 'ivy-previous-line-or-history))
   ((string= (current-major-mode) "minibuffer-mode") (call-interactively 'ivy-previous-line-or-history))
   ;; ((string= (current-major-mode) "helm-mode") (call-interactively 'previous-line))
   ((string= (current-major-mode) "selectrum-mode") (call-interactively 'selectrum-previous-candidate))
   ((string= (current-major-mode) "org-mode") (call-interactively 'org-backward-heading-same-level))
   ((string= (current-major-mode) "epa-key-list-mode") (call-interactively 'widget-backward))
   ((string= (current-major-mode) "circe-query-mode") (call-interactively 'lui-previous-input))
   ((string= (current-major-mode) "subed-mode") (call-interactively 'subed-prev))
   ((string= (current-major-mode) "lsp-browser-mode") (call-interactively 'widget-backward))
   ((string= (current-major-mode) "cider-repl-mode") (call-interactively 'cider-repl-previous-input))
   ((string= (current-major-mode) "hackernews-mode") (call-interactively 'hackernews-previous-item))
   ((string= (current-major-mode) "moccur-grep-mode") (call-interactively 'moccur-prev))
   ((string= (current-major-mode) "outline-mode") (try (call-interactively 'outline-backward-same-level)
                                                       (call-interactively 'outline-previous-visible-heading)
                                                       nil))
   ((string= (current-major-mode) "sx-question-mode") (call-interactively 'sx-question-mode-previous-section))
   ((string= (current-major-mode) "imenu-list-major-mode") (call-interactively 'imenu-preview-prev))
   ((string= (current-major-mode) "Man-mode") (call-interactively 'Man-previous-manpage))
   ((string= (current-major-mode) "calibredb-search-mode") (call-interactively 'calibredb-previous-entry))
   ((string= (current-major-mode) "dashboard-mode") (call-interactively 'widget-backward))
   ((string= (current-major-mode) "spacemacs-buffer-mode") (call-interactively 'widget-backward))
   ;; ((string= (current-major-mode) "occur-mode") (call-interactively widget-back'occur-prev))
   ((minor-mode-p lsp-ui-peek-mode) (ekm "<left>"))
   ((string= (current-major-mode) "compilation-mode") (call-interactively 'compilation-previous-error))
   ((string= (current-major-mode) "kubernetes-overview-mode") (call-interactively 'magit-section-backward))
   ((string= (current-major-mode) "sly-mrepl-mode") (call-interactively 'sly-mrepl-previous-input-or-button))
   ((string= (current-major-mode) "treemacs-mode") (call-interactively 'treemacs-previous-neighbour))
   ((string= (current-major-mode) "grep-mode") (call-interactively 'compilation-previous-error))
   ((major-mode-p 'magit-section-mode) (call-interactively 'magit-section-backward-sibling))
   ((string= (current-major-mode) "org-brain-visualize-mode") (call-interactively 'backward-button))
   ((string= (current-major-mode) "elisp-refs-mode") (call-interactively 'backward-button))
   ((string= (current-major-mode) "eshell-mode") (call-interactively 'eshell-previous-input))
   ((string= (current-major-mode) "slime-repl-mode") (call-interactively 'slime-repl-backward-input))
   ((string= (current-major-mode) "org-agenda-mode") (call-interactively 'org-agenda-previous-item))
   ((string=
     (current-major-mode)
     "occur-mode")
    (call-interactively
     (df
      occur-previous-and-display
      (call-interactively
       'occur-prev)
      (call-interactively
       'occur-mode-display-occurrence)
      (ekm "M-l ;")
      (ekm "M-l ;"))))
   ((string= (current-major-mode) "md4rd-mode") (call-interactively 'widget-backward))
   ((string= (current-major-mode) "xref--xref-buffer-mode") (call-interactively 'xref-prev-line))
   ((string= (current-major-mode) "restclient-mode") (call-interactively 'restclient-jump-prev))
   ((string= (current-major-mode) "eww-mode") (call-interactively 'eww-prev-fragment))
   ((string-match "^magit-" (current-major-mode)) (call-interactively 'magit-section-backward-sibling))
   ((string-match "^\*YASnippet Tables" (current-buffer-name)) (progn (call-interactively 'backward-button) (pen-yas-preview-snippet-under-cursor)))
   ((string= (current-major-mode) "mastodon-mode") (call-interactively 'mastodon-tl--previous-tab-item))
   ((minor-mode-p magit-blame-mode) (magit-blame-previous-chunk))
   (t (try
       (let ((start-point (point))
             (end-point))
         (call-interactively 'handle-prevdef)
         (setq end-point (point))
         (if (eq start-point end-point)
             (error "Didn't move")))
       (call-interactively 'previous-line-nonvisual)
       nil))))

(defun pen-next-defun (arg)
  (interactive "P")
  (cond
   ;; I can't figure out how to bind the fuzzyfinders in pen.el
   ;; ivy uses minibuffer-inactive-mode. Though I should still test for ivy
   ((string= (current-major-mode) "slime-xref-mode") (call-interactively 'slime-xref-next-line))
   ((string= (current-major-mode) "minibuffer-mode") (call-interactively 'ivy-next-line-or-history))
   ((string= (current-major-mode) "minibuffer-inactive-mode") (call-interactively 'ivy-next-line-or-history))
   ((string= (current-major-mode) "helm-mode") (call-interactively 'next-line))
   ((string= (current-major-mode) "selectrum-mode") (call-interactively 'selectrum-next-candidate))
   ((string= (current-major-mode) "org-mode") (call-interactively 'org-forward-heading-same-level))
   ((string= (current-major-mode) "epa-key-list-mode") (call-interactively 'widget-forward))
   ((string= (current-major-mode) "lsp-browser-mode") (call-interactively 'widget-forward))
   ((string= (current-major-mode) "circe-query-mode") (call-interactively 'lui-next-input))
   ((string= (current-major-mode) "hackernews-mode") (call-interactively 'hackernews-next-item))
   ((string= (current-major-mode) "cider-repl-mode") (call-interactively 'cider-repl-next-input))
   ((string= (current-major-mode) "subed-mode") (call-interactively 'subed-next))
   ((string= (current-major-mode) "moccur-grep-mode") (call-interactively 'moccur-next))
   ((string= (current-major-mode) "sx-question-mode") (call-interactively 'sx-question-mode-next-section))
   ((string= (current-major-mode) "imenu-list-major-mode") (call-interactively 'imenu-preview-next))
   ((string= (current-major-mode) "Man-mode") (call-interactively 'Man-next-manpage))
   ((string= (current-major-mode) "calibredb-search-mode") (call-interactively 'calibredb-next-entry))
   ;; ((string= (current-major-mode) "outline-mode") (call-interactively 'outline-next-visible-heading))
   ((string= (current-major-mode) "outline-mode") (try (call-interactively 'outline-forward-same-level)
                                                       (call-interactively 'outline-next-visible-heading)
                                                       nil))
   ((string= (current-major-mode) "dashboard-mode") (call-interactively 'widget-forward))
   ((string= (current-major-mode) "spacemacs-buffer-mode") (call-interactively 'widget-forward))
   ;; ((string= (current-major-mode) "occur-mode") (call-interactively 'occur-next))
   ((string= (current-major-mode) "compilation-mode") (call-interactively 'compilation-next-error))
   ((string= (current-major-mode) "sly-mrepl-mode") (call-interactively 'sly-mrepl-next-input-or-button))
   ((string= (current-major-mode) "kubernetes-overview-mode") (call-interactively 'magit-section-forward))
   ((string= (current-major-mode) "treemacs-mode") (call-interactively 'treemacs-next-neighbour))
   ((minor-mode-p lsp-ui-peek-mode) (ekm "<right>"))
   ((string= (current-major-mode) "grep-mode") (call-interactively 'compilation-next-error))
   ((string= (current-major-mode) "org-brain-visualize-mode") (call-interactively 'forward-button))
   ((string= (current-major-mode) "elisp-refs-mode") (call-interactively 'forward-button))
   ((string= (current-major-mode) "eshell-mode") (call-interactively 'eshell-next-input))
   ((string= (current-major-mode) "slime-repl-mode") (call-interactively 'slime-repl-next-input))
   ((string= (current-major-mode) "org-agenda-mode") (call-interactively 'org-agenda-next-item))
   ((string=
     (current-major-mode)
     "occur-mode")
    (call-interactively
     (df
      occur-next-and-display
      (call-interactively
       'occur-next)
      (call-interactively
       'occur-mode-display-occurrence)
      (ekm "M-l ;")
      (ekm "M-l ;"))))
   ((string= (current-major-mode) "md4rd-mode") (call-interactively 'widget-forward))
   ((string= (current-major-mode) "eww-mode") (call-interactively 'eww-next-fragment))
   ((string= (current-major-mode) "xref--xref-buffer-mode") (call-interactively 'xref-next-line))
   ((string= (current-major-mode) "restclient-mode") (call-interactively 'restclient-jump-next))
   ((string= (current-major-mode) "mastodon-mode") (call-interactively 'mastodon-tl--next-tab-item))
   ((minor-mode-p magit-blame-mode) (magit-blame-next-chunk))
   ((string-match "^magit-" (current-major-mode)) (call-interactively 'magit-section-forward-sibling))
   ((string-match "^\*YASnippet Tables" (current-buffer-name)) (progn (call-interactively 'forward-button) (pen-yas-preview-snippet-under-cursor)))
   (t (try
       (let ((start-point (point))
             (end-point))
         (call-interactively 'handle-nextdef)
         (setq end-point (point))
         (if (eq start-point end-point)
             (error "Didn't move")))
       (call-interactively 'next-line-nonvisual)
       nil))))

(defun show-interactive-prefix ()
  (interactive)
  (message (str current-prefix-arg)))

(defun call-interactively-with-default-prefix-and-parameters (func &rest args)
  (setq current-prefix-arg (list 4)) ; C-u
  (call-interactively  func t (apply 'vector args)))

(defun call-interactively-with-prefix-and-parameters (func prefix &rest args)
  (setq current-prefix-arg (list prefix)) ; C-u
  (call-interactively func t (apply 'vector args)))

(defun pen-scroll-up ()
  (interactive)
  (call-interactively-with-prefix-and-parameters 'cua-scroll-down 8))

(defun pen-scroll-down ()
  (interactive)
  (call-interactively-with-prefix-and-parameters 'cua-scroll-up 8))

(if (inside-docker-p)
    (progn
      (global-set-key "\C-n" 'pen-scroll-down)
      (global-set-key "\C-p" 'pen-scroll-up)))

(defun newline-indent ()
  (interactive)
  (delete-horizontal-space)
  (newline)
  (c-indent-line-or-region))

(defun pen-enter-edit-emacs (args)
  "Opens region in a new buffer if a region is selected. If an argument is provided then the C-m falls through."
  (interactive "P")
  (if (region-active-p)
      (cond
       ((>= (prefix-numeric-value current-prefix-arg) 16)
        (sps "unbuffer tm -te -d edit-x-clipboard"))
       ((>= (prefix-numeric-value current-prefix-arg) 4)
        (new-buffer-from-string-or-selected))
       (t (progn (recursive-narrow-or-widen-dwim)
                 (deactivate-mark))))
    (let ((pen nil)
          (global-map org-mode-map))
      (if (eolp)
          (ekm "M-C-m")
        (newline-indent)))))

(defun pen-enter-edit ()
  "Runs 'tvipe' if a region is selected."
  (interactive)
  (if (region-active-p)
      (pen-tvipe (pen-selected-text))
    ;; Disabling =my-mode= isnt enough for custom
    (if (derived-mode-p 'Custom-mode)
        (call-interactively 'Custom-newline)
      ;; Custom-newline
      (let ((pen nil)
            (fun (key-binding (kbd "C-m"))))
        (if fun
            (call-interactively fun)
          (execute-kbd-macro (kbd "C-m")))))))


(defun current-line-string ()
  (thing-at-point 'line t))

(defun urls-in-region-or-buffer (&optional s)
  (let ((mediastring
         (cond
          ((major-mode-p 'eww-mode) (pen-textprops-in-region-or-buffer))
          (t (selection-or-buffer-string)))))
    (sh/ptw/uniqnosort (sh/ptw/xurls mediastring))))

(defun region-or-buffer-string ()
  (interactive)
  (if (or (region-active-p) (eq evil-state 'visual))
      (str (buffer-substring (region-beginning) (region-end)))
    (str (buffer-substring (point-min) (point-max)))))
(defalias 'selection-or-buffer-string 'region-or-buffer-string)

(defun pen-select-current-line ()
  (interactive)
  (move-beginning-of-line nil)
  (set-mark-command nil)
  (move-end-of-line nil)
  (setq deactivate-mark nil))

(defmacro pen-sn-true (cmd &rest sh-notty-args)
  "Returns t if the shell command exists with 0"
  `(let ((result (pen-sn ,cmd ,@sh-notty-args)))
     (string-equal b_exit_code "0")))

(defun deselect-i ()
  (interactive)
  (deactivate-mark))

;; TODO Make this file mirrored elsewhere
(defun switch-to-org-for-this-file ()
  (interactive)
  (let* ((fn (f-filename (get-path nil t)))
         (mant (f-mant fn))
         (nf (concat (slugify mant) ".org")))
    (find-file nf)))

(defun tm-notify (s &optional delay)
  (setq delay (or delay 10))
  ;; (pen-sn (pen-cmd "tm-notify" "-t" (str delay)) (pps s))
  (pen-sn (pen-cmd "ns" "-t" (str delay)) (pps s))
  s)

(defun tm-notifications ()
  (interactive)
  (sps "pen-watch-notifications"))

(defun open (path)
  ;;   "This executes open <path> in a split"
  (interactive (list (read-file-name "path:")))
  (sps (concat "trap '' HUP; o " (q path))))
(defalias 'spv-open 'open)
(defalias 'o 'open)

(defun sps-top ()
  (interactive)
  (sps "zsh-top"))

(defun toggle-truncate-lines (arg)
  (interactive "P")
  (if truncate-lines
      (progn
        (setq truncate-lines nil)
        (setq-default truncate-lines nil)
        (message "%s" "truncate-lines disabled"))
    (progn
      (setq truncate-lines t)
      (setq-default truncate-lines t)
      (message "%s" "truncate-lines enabled"))))

(defmacro unprefix (&rest body)
  ""
  `(let ((current-prefix-arg nil)
         (current-global-prefix-arg nil))
     ,@body))

(provide 'pen-library)
