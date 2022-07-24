;; (require 'pen-hydra)

(defset search-functions '() "list of search functions that would usually sit under M-8")

(defun pen-search ()
  (interactive)
  (let ((f (intern (fz search-functions))))
    (if (commandp f)
        (call-interactively f))))

(defun guess-lang-for-search (&optional prompt)
  (if (not prompt)
      (setq prompt "lang: "))
  (let ((lang (cond
               ((derived-mode-p 'sx-question-mode) nil)
               ((derived-mode-p 'term-mode) (buffer-language t t))
               ((derived-mode-p 'org-mode) (get-src-block-language))
               ((derived-mode-p 'eww-mode) (read-string-hist prompt))
               (t (buffer-language)))))
    (cond
     ((string-equal "fundamental" lang) "")
     ((string-equal "text" lang) "")
     (t lang))))
(add-to-list 'search-functions 'guess-lang-for-search)

(defun alphabetize (input)
  (chomp (pen-sn "alphabetize" input)))

(defun googleize (input)
  (chomp (pen-sn "googleize" input)))

(defun eegr (query)
  (interactive (list (read-string-hist "egr: "
                                       (if mark-active
                                           (concat
                                            (pen-q (pen-thing-at-point))
                                            " ")
                                         ""))))
  (engine/search-google query))
(add-to-list 'search-functions 'eegr)

(defun eegh (query)
  (interactive (list (read-string-hist "egh: "
                                       (if mark-active
                                           (concat
                                            (pen-q (pen-thing-at-point))
                                            " ")
                                         ""))))
  (engine/search-github-advanced query))
(add-to-list 'search-functions 'eegh)

(defun egr-thing-at-point (query)
  (interactive (list (read-string-hist "egr (quoted): " (concat (pen-q (pen-thing-at-point)) " "))))
  (pen-nw (concat "egr " query)))
(add-to-list 'search-functions 'egr-thing-at-point)

(defun egr-thing-at-point-imediately (query)
  (interactive (list (pen-q (s-replace "\n" " " (pen-thing-at-point)))))
  (egr-thing-at-point query))
(add-to-list 'search-functions 'egr-thing-at-point-imediately)

(defun egr-thing-at-point-lang (query)
  (interactive (list (read-string-hist "egr (quoted): "
                                       (concat (pen-q (pen-thing-at-point))
                                               " "
                                               (cond
                                                ((derived-mode-p 'org-mode) (get-src-block-language))
                                                ((derived-mode-p 'markdown-mode) (get-src-block-language))
                                                ((derived-mode-p 'eww-mode) (completing-read "lang:" nil nil nil))
                                                (t (buffer-language)))
                                               " "))))
  (egr-thing-at-point query))
(add-to-list 'search-functions 'egr-thing-at-point-imediately)


(defun egr-docs (tool query)
  (interactive (list (read-string-hist "egr-docs tool: ")
                     (read-string-hist "egr-docs query: ")))
  (pen-sps (pen-cmd "egr-docs" tool query)))
(add-to-list 'search-functions 'egr-docs)


(defun egr-thing-at-point-lang-imediately (query)
  (interactive (list (pen-q (s-replace "\n" " " (pen-thing-at-point)))))
  (let ((lang (guess-lang-for-search "egr lang: ")))
    (engine/search-google (concat lang " " query))))
(add-to-list 'search-functions 'egr-thing-at-point-lang-imediately)

(defun eegr-thing-at-point-lang (query)
  (interactive
   (let ((lang
          (guess-lang-for-search "egr lang: ")))
     (list (read-string-hist "egr query: " (concat lang " " (pen-q (s-replace "\n" " " (pen-thing-at-point))) " ")))))
  (engine/search-google query))
(defalias 'eegr-thing-at-point 'eegr-thing-at-point-lang)
(add-to-list 'search-functions 'eegr-thing-at-point-lang)

(defun eegr-maybeselected (query)
  (interactive (let
                   ((s (if mark-active
                           (pen-q (s-replace "\n" " " (pen-selected-text))) 
                         "")))
                 (list (read-string-hist "egr query: " s))))
  (engine/search-google query))
(add-to-list 'search-functions 'eegr-maybeselected)

(defun eegr-thing-at-point-lang-imediately (query)
  (interactive (list (pen-q (s-replace "\n" " " (pen-thing-at-point)))))
  (let ((lang
         (cond
          ((derived-mode-p 'org-mode) (get-src-block-language))
          ((derived-mode-p 'markdown-mode) (get-src-block-language))
          ((derived-mode-p 'eww-mode) (read-string-hist (concat "egr " query " lang: ")))
          ((derived-mode-p 'sx-question-mode) (read-string-hist (concat "egr " query " lang: ")))
          (t (buffer-language)))))
    (engine/search-google (concat lang " " query))))
(add-to-list 'search-functions 'eegr-thing-at-point-lang-imediately)

(defun eegr-thing-at-point-imediately (query)
  (interactive (list (pen-q (s-replace "\n" " " (pen-thing-at-point)))))
  (engine/search-google query))
(add-to-list 'search-functions 'eegr-thing-at-point-imediately)

(defun ead-thing-at-point (query)
  (interactive (list (read-string-hist "ead " (concat (pen-q (pen-thing-at-point)) " "))))
  (pen-nw (concat "ead " query)))
(add-to-list 'search-functions 'ead-thing-at-point)

(defun glimpse-thing-at-point (path query)
  (interactive (list (read-string-hist "gli path: " (file-name-extension (get-path)))
                     (read-string-hist "gli: " (concat (pen-q (pen-thing-at-point)) " "))))
  (if (str-or path)
      (pen-nw (concat "gli -F " (pen-q (concat (unregexify (concat "." path)) "$")) " " query))
    (pen-nw (concat "gli " query))))
(add-to-list 'search-functions 'glimpse-thing-at-point)

(defun glimpse-thing-at-point-immediate (path query)
  (interactive (list (file-name-extension (get-path))
                     (concat (pen-q (pen-thing-at-point)) " ")))
  (if (str-or path)
      (pen-nw (concat "gli -F " (pen-q (concat (unregexify (concat "." path)) "$")) " " query))
    (pen-nw (concat "gli " query))))
(add-to-list 'search-functions 'glimpse-thing-at-point-immediate)

(defun egr-thing-at-point-noquotes (query)
  (interactive (list (read-string-hist "egr (not quoted): " (concat (googleize (pen-thing-at-point)) " "))))
  (pen-sps (concat "egr " query)))
(add-to-list 'search-functions 'egr-thing-at-point-noquotes)

(define-key global-map (kbd "M-8") nil)
(define-key pen-map (kbd "M-8") nil)
(define-key pen-map (kbd "8") nil)

(defun gh-path-search (path contents)
  (interactive (list (read-string-hist "github path: ")
                     (read-string-hist "contents: ")))
  (pen-sps (concat "ff " (pen-q (concat "https://github.com/search?q=" contents "+path%3A" path "&type=Code")))))
(add-to-list 'search-functions 'gh-path-search)

(defun sps-gh-topic-project (topic)
  (interactive (list (read-string-hist "github topic: ")))
  (pen-sps (concat "gh-topic-project " topic)))
(defalias 'sps-github-topic-project-search 'sps-gh-topic-project)
(add-to-list 'search-functions 'sps-github-topic-project-search)

(defun urlencode (url)
  (pen-sn "urlencode | chomp" url))

(defun urldecode (url)
  (pen-sn "urldecode | chomp" url))

(defun google-code-search (pattern &optional path lang)
  (interactive (list (read-string-hist "google code pattern:")
                     (read-string-hist "google code path:")
                     (read-string-hist "google code lang:")))
  (setq pattern (urlencode pattern))
  (setq path (urlencode path))
  (setq lang (urlencode lang))

  (let ((url "https://cs.opensource.google/search?q="))
    (if (not (string-empty-p path)) (setq url (concat url "file:" (urlencode (concat " " path " ")))))
    (if (not (string-empty-p lang)) (setq url (concat url "lang:" (urlencode (concat " " lang " ")))))
    (if (not (string-empty-p pattern)) (setq url (concat url (urlencode (concat " " pattern)))))
    (pen-sps (concat "ff " (pen-q url)))))
(add-to-list 'search-functions 'google-code-search)

(defun grep-app (pattern &optional path repo)
  (interactive
   (let ((path (get-path-nocreate)))
     (if mark-active
         (list (pen-selected-text)
               (if path
                   (file-name-extension path)
                 (read-string-hist "grep.app path:"))
               nil)
       (list (read-string-hist "grep.app pattern:" (pen-thing-at-point))
             (read-string-hist "grep.app path:" ;; (concat (unregexify (concat "." (concat (file-name-extension (buffer-file-name))))) "$")
                               (if path
                                   (concat "." (file-name-extension path))
                                 ""))
             (read-string-hist "grep.app repo:")))))

  (let ((do-literal mark-active))

    (if (and mark-active (s-matches-p "^[a-z0-9]+$" pattern))
        (progn
          (setq do-literal nil)
          (setq pattern (concat "\\b" pattern "\\b"))))

    (if (not pattern)
        (pen-ns "pattern should not be empty"))

    (setq pattern (urlencode pattern))
    (setq path (urlencode path))
    (setq repo (urlencode repo))

    (let ((url "https://grep.app/search?"))
      (if (not (string-empty-p pattern))
          (if do-literal
              (setq url (concat url "q=" pattern "&case=true"))
            (setq url (concat url "q=" pattern "&regexp=true&case=true"))))
      (if (not (string-empty-p path))
          (progn
            (if (not (string-empty-p pattern))
                (setq url (concat url "&")))
            (setq url (concat url "filter[path.pattern][0]=" path))))
      (if (not (string-empty-p repo))
          (progn
            (if (or (not (string-empty-p pattern))
                    (not (string-empty-p path)))
                (setq url (concat url "&")))
            (setq url (concat url "filter[repo.pattern][0]=" repo))))
      (browse-url-generic url))))
(add-to-list 'search-functions 'grep-app)

(defun gh-find-repo-by-topic (topic-query)
  (interactive (list (read-string-hist "github topic:")))
  (let* ((topics (pen-sn (concat "gh-search-topics " (pen-q topic-query) " | cat")))
         (topic (fz topics))
         (repos (pen-sn (concat "gh-list-top-repos-for-topic " (pen-q topic) " | cat")))
         (repo (fz repos))
         (url (sed "s=^=http://github.com/=" repo)))
    (xc url)))
(add-to-list 'search-functions 'gh-find-repo-by-topic)

(defun ieee-search (query)
  (interactive (list (read-string-hist "ieee:")))
  (eww
   (first
    (s-lines (pen-sn (concat "ieee-search " (pen-q query)))))))
(add-to-list 'search-functions 'ieee-search)

(defun protocol-search (query)
  (interactive (list (read-string-hist "protocol:")))
  (eww
   (first
    (s-lines (pen-sn (concat "protocol-search " (pen-q query)))))))
(add-to-list 'search-functions 'protocol-search)

(define-key global-map (kbd "H-G") 'grep-app)
(define-key global-map (kbd "H-M") 'glimpse-thing-at-point-immediate)

(define-key global-map (kbd "M-s e") 'eegr)

(defun eead-in-similar-projects (s)
  "Look for a string in similar projects"
  (interactive (list (read-string-hist (concat "ead-in-similar-projects (" (symbol-name major-mode) "): ") (pen-thing-at-point))))
  (mu
   (cond ((derived-mode-p 'sh-mode)
          (let ((d "$SCRIPTS"))
              (eead pen-str d)))
         (t (let ((d "$MYGIT/mullikine")
                  (e (f-ext (get-path))))
              (eead (eatify s) d (concat "\\." e "$")))))))

(defun ead-in-similar-projects (s)
  "Look for a string in similar projects"
  (interactive (list (read-string-hist (concat "ead-in-similar-projects (" (symbol-name major-mode) "): ") (pen-thing-at-point))))
  (mu
   (cond ((derived-mode-p 'sh-mode)
          (let ((d "$SCRIPTS"))
              (pen-nw (concat
                   (pen-cmd "cd" d)
                   "; "
                   (pen-cmd "ead" s)))))
         (t (let ((d "$MYGIT/mullikine")
                  (e (f-ext (get-path))))
              (pen-nw (concat
                   (pen-cmd "cd" d)
                   "; "
                   (pen-cmd "ead" "-p" (concat "\\." e "$") s))))))))

(provide 'pen-search)