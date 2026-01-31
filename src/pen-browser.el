;; Just override the emacs function completely
(defun browse-url-default-browser (url &rest args)
  (pen-smart-choose-browser-function url))

(defun pen-emacs-web-browse (url &optional _new-window)
  (let ((br
         (pen-qa
          -e "eww"
          -r "rdrview"
          -w "w3m"
          -b "browsh"
          -B "ebrowsh"
          -I "w3m"
          -f "ff")))

    (pcase br
      ("eww" (eww-browse-url url _new-window))
      ("w3m" (w3m-browse-url url _new-window))
      ;; ("browsh" (nw (cmd "browsh" url) _new-window))
      ("browsh" (browsh url))
      ("ebrowsh" (eval `(pen-use-vterm (pen-term (cmd "browsh" ,url)))))
      ("rdrview" (rdrview url))
      (_ (browse-url-generic url _new-window)))))

(defun pen-smart-choose-browser-function (url &optional _new-window)
  (cond ((minor-mode-p pen-rdrview-minor-mode) (rdrview url))
        ((major-mode-p 'eww-mode) (eww-browse-url url _new-window))
        ((major-mode-p 'w3m-mode) (w3m-browse-url url _new-window))
        (t
         (progn
           (setq url (pen-redirect url))

           (cond ((string-match-p "google.com/url\\?q=" url)
                  (setq url (urldecode (pen-sed "/.*google.com\\/url?q=/{s/^.*google.com\\/url?q=\\([^&]*\\)&.*/\\1/}" url)))))

           (cond
            ;; Pass through `pen-handle-url` first.
            ;; If it is handled by `pen-handle-url`
            ;; then snq will return true. Otherwise, continue matching.
            ((pen-snq (pen-cmd-safe "pen-handle-url" url))
             t)
            ;; ((string-match-p "https?://github.com/.*/issues" url)
            ;;  (let ((res (apply proc args))) res))
            ((string-match "^https?://asciinema.org/a/[a-zA-Z0-9]+/?$" url)
             (pen-tm-asciinema-play url))
            ((string-match-p "https?://gist.github.com/" url)
             (pen-sps (concat "o " (pen-q url))))
            ((and eww-ff-dom-matchers
                  (-reduce (lambda (a b) (or a b))
                           (mapcar (lambda (e) (string-match-p e url))
                                   (or (-filter-not-empty-string eww-ff-dom-matchers)
                                       '(nil)))))
             (pen-snc (pen-cmd-safe "sps" "ff" url)))
            ;; This could be a raw code link such as https://raw.githubusercontent.com/kiwanami/emacs-ctable/master/readme.md
            ;; ((string-match-p "https?://raw.githubusercontent.com/" url)
            ;;  (pen-sps (concat "o " (pen-q url))))
            ((string-match-p "https?://arxiv.org/\\(abs\\|pdf\\)/" url)
             (pen-sps (concat "o " (pen-q url))))
            ((string-match-p "https?://www.youtube.com/" url)
             (pen-sps (concat "ff " (pen-q url))))
            ((string-match-p "https?://.*/.*\\.\\(lhs\\)" url)
             (dump-url-file-and-edit url))
            ((or (string-match-p "stackoverflow.com/[aq]" url)
                 (string-match-p "serverfault.com/[aq]" url)
                 (string-match-p "askubuntu.com/[aq]" url)
                 (string-match-p "superuser.com/[aq]" url)
                 (string-match-p ".stackexchange.com/[aq]" url))
             (sx-from-url url))
            ((or (string-match-p "search\\.google\\.com/search-console" url)
                 (string-match-p "mullikine\\.matomo\\.cloud" url))
             (pen-chrome url))
            ((or (string-match-p "asciinema\\.org/a/" url))
             (nw (concat "o " (pen-q url))))
            ((or (string-match-p "www\\.google\\.com/search\\?" url))
             (let* ((encoded (s-replace "\"" "%22" url))
                    (query (pen-snc "sed \"s/.*q=\\\\([^&]\\\\+\\\\)&.*/\\\\1/\"" encoded))
                    (query (pen-snc "sed \"s/.*q=\\\\([^&]\\\\+\\\\)$/\\\\1/\"" query))
                    (query (s-replace "+" " " query))
                    (query (s-replace "%22" "\"" query))
                    (url (fz-ddgr query)))

               (if (not (string-empty-or-nil-p url))
                   (pen-emacs-web-browse url _new-window))

               ;; If it's a google link, then extract the query and put it through (fz-ddgr query)

               ;; http://www.google.com/search?ie=utf-8&oe=utf-8&q=farming%20technology
               ;; (if (string-empty-or-nil-p (pen-rc-get "w3m_use_chrome_dump"))
               ;;     (if (yn "Enable dom dump for w3m?")
               ;;         (pen-rc-set "w3m_use_chrome_dump" "on")))
               (pen-emacs-web-browse url _new-window)
               ;; (pen-sps (concat "ff " (pen-q url)))
               ))
            ((string-match-p "magnet:\\?xt" url)
             (pen-sps (concat "rt " (pen-q url))))
            ((string-match-p "https?://\\(github\\\).com/[^/]+/?$" url)
             (let* ((author (s-replace-regexp "https?://github.com/" "" url))
                    (author (s-replace-regexp "/$" "" author)))
               (gc (fz-gh-list-user-repos author))))
            ((and (string-match-p "https?://\\(github\\|gitlab\\).com/[^/]+/[^/]+" url)
                  (not (string-match-p "https?://\\(github\\|gitlab\\).com/[^/]+/[^/]+/\\(archive\\|releases\\)" url)))
             (gc url))
            ((string-match-p "https?://.*\\.rss" url)
             (elfeed-add-feed url :save t)
             (elfeed))
            ((string-match-p "https://libraries.io/.*/github.com%2F.*%2F" url)
             (let ((url (concat "http://" (s-replace-regexp "^http.*//libraries.io/[^/]+/" "" url))))
               (gc (urldecode url))))
            ;; ((and
            ;;   eww-racket-doc-only-www
            ;;   (string-match-p "http://racket/" (urldecode url)))
            ;;  (setcar args (pen-cl-sn "fix-racket-doc-url -w" :stdin url :chomp t))
            ;;  (let ((res (apply proc args)))
            ;;    res))
            ((or (string-match-p "^http.*\.deb$" url))
             (wget url)
             (message url))
            (
             ;; Capture groups appear to not work
             (or (string-match-p "^http.*\.tar.gz$" url)
                 (string-match-p "^http.*\.zip$" url)
                 (string-match-p "https?://\\(github\\|gitlab\\).com/[^/]+/[^/]+/\\(archive/.\\)" url))
             (wget url (mu "$DUMP$NOTES/ws/download/"))
             (message url))
            (
             ;; Capture groups appear to not work
             (or (string-match-p "^http.*\\.pdf$" url)
                 (string-match-p "^http.*\\.epub$" url)
                 (string-match-p "^http.*/openreview.net/pdf" url)
                 (string-match-p "^http.*\\.azw3$" url)
                 (string-match-p "/get.php\\?md5=" url)
                 (string-match-p "^http.*\\.djvu$" url))
             (wget url (mu "$DUMP$NOTES/ws/pdf/incoming/"))
             (message url))
            (t
             (pen-emacs-web-browse url _new-window)))))))

;; (setq browse-url-browser-function 'eww-browse-url)
(setq browse-url-browser-function
      'pen-smart-choose-browser-function
      browse-url-generic-program
      (executable-find "pen-copy-thing"))

(defun eww-and-search (url)
  "This is a browser function used by ff-view and, thus, racket to search for something in the address bar and then search the resulting website."
  (pen-b ni eww-and-search)
  ;; (pen-tvipe (sed "s/.*q=//" url))
  (lg-eww url))

(defun reopen-in (br)
  (interactive (list (fz '(eww w3m browsh))))
  (let ((url (get-path nil t)))
    ;;; I think this did infinite loop. Fix. Maybe use pcase
    (pcase br
      ('eww (eww url))
      ('w3m (w3m url))
      ('browsh (browsh url))
      (_ nil))))

(defun reopen-in-eww ()
  (interactive)
  (reopen-in 'eww))

(defun reopen-in-w3m ()
  (interactive)
  (reopen-in 'w3m))

(defun reopen-in-browsh ()
  (interactive)
  (reopen-in 'browsh))

(provide 'pen-browser)
