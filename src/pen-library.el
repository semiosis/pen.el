(require 'sx)

(defalias 's-replace-regexp 'replace-regexp-in-string)

(require 'pen-aliases)

(defun pen-f-basename (path)
  ;; (pen-snc (pen-cmd "basename" path))
  (s-replace-regexp ".*/" "" (or path
                                 "")))

(defun f-mant (path)
  ;; (pen-snc (pen-cmd "mant" path))
  (s-replace-regexp "\\..*" "" (pen-f-basename path)))

(defalias 'f-basename 'f-filename)
(defun f-mant (path)
  ;; (pen-snc (pen-cmd "mant" path))
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

(defun save-temp-if-no-file ()
  (interactive)

  (if (not (buffer-file-name))
      (write-file
       (make-temp-file nil nil (concat "." (get-ext-for-mode major-mode))))))

(defun f-realpath (path &optional dir)
  (if path
      (chomp (pen-sn (concat "realpath " (q path) " 2>/dev/null") nil dir))))

(defalias 'major-mode-enabled 'derived-mode-p)

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
(defun get-path (&optional soft no-create-path for-clipboard semantic-path)
  "Get path for buffer. semantic-path means a path suitable for google/nl searching"
  (interactive)

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
                        (mapconcat 'q (dired-get-marked-files) " "))
                       (pen-pwd)))

             ;; This will break on eww
             (if (and (not (eq major-mode 'org-mode))
                      (string-match-p "\\[\\*Org Src" (or (buffer-file-name) "")))
                 (s-replace-regexp "\\[\\*Org Src.*" "" (buffer-file-name)))
             (buffer-file-name)
             (try (buffer-file-path)
                  nil)
             dired-directory
             (progn (if (not no-create-path)
                        (save-temp-if-no-file))
                    (let ((p (full-path)))
                      (if (stringp p)
                          (chomp p)))))))
    (if (interactive-p)
        (xc path)
      path)))

(defun pen-button-get-link (b)
  (cond
   ((eq (button-get b 'face) 'glossary-button-face)
    (concat "[[y:" (button-get-text b) "]]"))
   (t nil)))

(defun pen-clean-up-copy-link (rawlink)
  (setq rawlink (s-replace-regexp "^(\\(.*\\))$" "\\1" rawlink))
  (setq rawlink (s-replace-regexp "^[\"]\\(.*\\)[\"]$" "\\1" rawlink))
  (setq rawlink (s-replace-regexp "^\\([a-z]+\\.[a-z]+\\/\\)" "http://\\1" rawlink)) ;go import
  rawlink)

(defun glossary-button-at-point ()
  (let ((p (point))
        (b (button-at-point)))
    (if (and
         b
         (eq (button-get b 'face) 'glossary-button-face))
        b
      nil))
  (button-at-point))
(defalias 'glossary-button-at-point-p 'glossary-button-at-point)

(defun pen-equals (a b)
  (if (stringp b)
      (string-equal a b)
    (eq a b)))
(defalias 'my-eq 'pen-equals)

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

;; j:my-copy-link-at-point
(defun pen-copy-link-at-point ()
  "Copy the link with the highest priority at the point."
  (interactive)
  (xc
   (try
    ;; (progn (pen-error-if-equals (link-hint--action-at-point :copy) "There is no link supporting the :copy action at the point.")
    ;;        (e/xc))
    (pen-error-if-equals (calibre-copy-org-link) "[[calibre:]]")
    (pen-error-if-equals (pen-button-get-link (glossary-button-at-point)) nil)
    (pen-error-if-equals (pen-clean-up-copy-link (plist-get (link-hint--get-link-at-point) :args)) nil)
    (pen-error-if-equals (chomp (pen-sn "xurls" (str (thing-at-point 'sexp)))) "")
    (pen-error-if-equals (chomp (pen-sn "xurls" (str (thing-at-point 'url)))) "")
    (pen-error-if-equals (chomp (pen-sn "xurls" (str (thing-at-point 'line)))) "")
    "")))

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
              (let ((b (nbfs ,m)))
                (switch-to-buffer b)
                (setq r (read-key ""))
                (kill-buffer b)))
            r))
     code)))

(defun pen-ask (thing &optional prompt)
  (interactive)
  (read-string-hist
   (or prompt
       (concat "pen-ask: "))
   thing))

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
                        (pen-screen-text)
                        :no-select-result no-select-result
                        ;; :no-select-result t
                        ;; (pen-surrounding-text)
                        )))
                   (pf-keyword-extraction/1
                    (pen-screen-text)
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
;; TODO I suppose I should just test for prog-mode
(defun pen-mode-prose-or-code-p ()
  ;; test for prog-mode
  (cond
   (body)))

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

(defalias 'major-mode-p 'derived-mode-p)
(defalias 'major-mode-enabled 'derived-mode-p)
(defalias 'minor-mode-p 'bound-and-true-p)
(defalias 'minor-mode-enabled 'bound-and-true-p)

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

(defmacro dff (&rest body)
  "This defines a 0 arity function with name based on the contents of the function.
It should only really be used to create names for one-liners.
It's really meant for key bindings and which-key, so they should all be interactive."
  ;; The mnm here was killing emacs loading
  (let* ((slugsym (intern
                   (s-replace-regexp
                    "^-" "dff-"
                    (slugify ;; (mnm (pp body))
                     (pp body) t)))))
    `(defun ,slugsym () (interactive) ,@body)))

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
     when (and (not (string-equal "\n" (str (thing-at-point 'line))))
               (not (string-equal " " (str (thing-at-point 'char))))
               (not (string-equal "	" (str (thing-at-point 'char))))
               (= (move-to-column start-col) start-col)
               (/= (char-after (point)) start-ch)
               (/= (char-after (point)) (string-to-char " ")))
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

(defun pen-eipe (input &optional chomp)
  (pen-sn (pen-cmd "pen-tvipe" "pen-eipe") input nil nil nil nil nil nil chomp))

(defun pen-eipec (input)
  (pen-eipe input t))

(defun pen-internet-connected-p ()
  (pen-snq "internet-connected-p"))

(provide 'pen-library)