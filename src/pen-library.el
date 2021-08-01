(require 'sx)

(defalias 's-replace-regexp 'replace-regexp-in-string)

(defun f-basename (path)
  (pen-snc (cmd "basename" path)))

(defun f-mant (path)
  (pen-snc (cmd "mant" path)))

;; The semantic path needs to be an association list, and add to that with contrib plugins
(defun get-path-semantic ()
  (interactive)
  (cond
   ((derived-mode-p 'org-brain-visualize-mode)
    (org-brain-pf-topic))
   ((is-glossary-file (f-basename (get-path)))
    (f-mant (f-basename (get-path))))
   (t (buffer-language))))

(defun save-temp-if-no-file ()
  (interactive)

  (if (not (buffer-file-name))
      (write-file
       (make-temp-file nil nil (concat "." (get-ext-for-mode major-mode))))))

(defun f-realpath (path &optional dir)
  (if path
      (chomp (pen-sn (concat "realpath " (q path) " 2>/dev/null") nil dir))))

(defun buffer-file-path ()
  (if (major-mode-enabled 'eww-mode)
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
                  (string-or (and
                              for-clipboard
                              (mapconcat 'q (dired-get-marked-files) " "))
                             (my/pwd)))

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

(defun pen-topic (&optional short)
  "Determine the topic used for pen functions"
  (interactive)

  (let ((topic
         (cond ((is-glossary-file)
                (s-replace-regexp "\\..*" "" (f-basename (buffer-file-path))))
               ((derived-mode-p 'org-brain-visualize-mode)
                (progn (require 'my-org-brain)
                       (org-brain-pf-topic short)))
               (t
                (let ((current-prefix-arg '(4))) ; C-u
                  ;; Consider getting topic keywords from visible text
                  (get-path))))))
    (if (interactive-p)
        (etv topic)
      topic)))

(defun pen-broader-topic ()
  "Determine the topic used for pen functions"
  (interactive)

  (let ((topic (get-path nil nil nil t)))
    (if (interactive-p)
        (etv topic)
      topic)))

(provide 'pen-library)