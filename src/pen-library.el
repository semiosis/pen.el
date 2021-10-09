(require 'sx)

(defalias 's-replace-regexp 'replace-regexp-in-string)

;; (defun f-basename (path)
;;   ;; (pen-snc (pen-cmd "basename" path))
;;   (s-replace-regexp ".*/" "" path))
(defalias 'f-basename 'f-filename)

(defun f-mant (path)
  ;; (pen-snc (pen-cmd "mant" path))
  (s-replace-regexp "\\..*" "" (f-basename path)))

;; The semantic path needs to be an association list, and add to that with contrib plugins
;; The semantic path / topic should always be visible or accessible
;; This way, it's easy to correct problems
(defun get-path-semantic ()
  (interactive)
  (cond
   ((derived-mode-p 'org-brain-visualize-mode)
    (org-brain-pf-topic))
   ((pen-is-glossary-file (get-path))
    (pen-get-glossary-topic (get-path)))
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
                 (progn (require 'my-org-brain)
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
                        (pen-words 40 (pen-selection-or-surrounding-context 10))
                        :no-select-result no-select-result
                        ;; :no-select-result t
                        ;; (pen-surrounding-text)
                        )))
                   (pf-keyword-extraction/1
                    (pen-words 40 (pen-selection-or-surrounding-context 10))
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
         ;; (l (tv (list2str lines)))
         (lintings
          (list2str
           (cl-loop for l in lines collect
                 (progn
                   (message "%s" (concat "linting " l))
                   (car (pen-single-generation
                         (pf-imagine-an-awk-linter/1 l :no-select-result t :select-only-match))))))))
    (etv lintings)))


;; TODO Make a prompt which detects either prose or code
;; is-code, or is-prose, then prompt twice?

;; Or one prompt which returns prose, code or unknown/other
;; This would be the better prompt

;; It's important to stick to haskell


;; TODO Make a Hyper binding for transforming prose or code using NL
;; This should be super easy.
(defun pen-mode-prose-or-code-p ()
  
  (cond
   (body)))


(defun pen-transform ()
  (interactive)
  ;; TODO detect prose/code
  ;; TODO Make it select the surrounding text so it can be transformed
  (let ((context (pen-surrounding-context 5)))
    (pf-transform-code/3 context)))

(provide 'pen-library)