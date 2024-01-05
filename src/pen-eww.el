(require 'eww)

(require 'cl-lib)
(require 'eww-lnum)
(require 'f)
(require 'ace-link)

(require 'helm-eww)
(require 'markdown-preview-eww)

(setq max-specpdl-size 10000)
;; This isn't a great solution
;; https://stackoverflow.com/q/11807128
(setq max-lisp-eval-depth 10000)

;; (setq shr-external-rendering-functions '((pre . eww-tag-pre)))
(setq shr-external-rendering-functions nil)
(setq shr-use-colors nil)

(use-package shr-tag-pre-highlight
  :ensure t
  :after shr
  :config
  (add-to-list 'shr-external-rendering-functions
               '(pre . shr-tag-pre-highlight))
  (when (version< emacs-version "26")
    (with-eval-after-load 'eww
      (advice-add 'eww-display-html :around
                  'eww-display-html--override-shr-external-rendering-functions))))

;; j:slime-add-face
(defun pen-add-face-to-string (face string)
  (declare (indent 1))
  (add-text-properties 0 (length string) (list 'face face) string)
  string)

;; TODO Find a way to simply make the entire pre-block
;; a single colour.
;; Don't use syntax highlighting.
(defun shr-tag-pre-highlight (pre)
  "Highlighting code in PRE."
  (let* ((shr-folding-mode 'none)
         (shr-current-font 'default)
         (code (with-temp-buffer
                 (shr-generic pre)
                 (buffer-string)))
         (mode 'fundamental-mode))
    (shr-ensure-newline)
    (insert
     (pen-add-face-to-string
         'info-code-face
       code))
    (shr-ensure-newline)))

(require 'pen-postrender-sanitize)

;; Handler j:pen-advice-handle-url

;; e:$HOME/local/emacs28/share/emacs/28.0.50/lisp/net/eww.el.gz
;; e:$HOME/local/emacs28/share/emacs/28.0.50/lisp/net/shr.el.gz

(defset pen-url-cache-dir
        (f-join penconfdir
                "url-cache"))
(f-mkdir pen-url-cache-dir)

(defvar eww-racket-doc-only-www nil)
(defset eww-after-render-hook '())

(defset lg-url-cache-enabled t)
(defset lg-url-cache-update nil)

(defvar-local eww-followed-link nil)

(defvar eww-follow-link-after-hook '())
(defvar eww-reload-after-hook '())
(defvar eww-restore-history-after-hook '())

;; Medium articles break with chrome
(defvar eww-use-google-cache nil)
(defvar eww-use-chrome nil)
(defvar eww-use-rdrview nil)
(defvar eww-use-tor nil)
(defvar eww-update-ci nil)
(defvar eww-do-fontify-pre nil)

(setq eww-use-rdrview nil)
(setq browse-url-text-browser "elinks")

(defvar eww-display-html-after-hook '())

(defvar eww-use-google-cache-matchers)
(defvar eww-use-chrome-dom-matchers)
(defvar eww-use-reader-matchers)
(defvar eww-ff-dom-matchers)

(defun lg-list-history ()
  (interactive)
  (let ((l (pen-snc "uniqnosort"
               (pen-sed "s/^.*cache://"
                    (pen-cl-sn "uq -l | tac" :stdin (pen-list2str (pen-hg "eww-display-html"))
                               :chomp t)))))
    (if (interactive-p)
        (pen-etv l)
      l)))

(defun lg-fz-history ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (pen-he "eww-display-html")
    (let ((url (fz
                (lg-list-history)
                nil
                nil
                "eww history: ")))
      (if url
          (lg-eww url)))))

(defun eww-retrieve (url callback cbargs)
  (if (null eww-retrieve-command)
      (url-retrieve url #'eww-render
                    (list url nil (current-buffer)))
    (let ((buffer (generate-new-buffer " *eww retrieve*"))
          (error-buffer (generate-new-buffer " *eww error*")))
      (with-current-buffer buffer
        (set-buffer-multibyte nil)
        (make-process
         :name "*eww fetch*"
         :buffer (current-buffer)
         :stderr error-buffer
         :command (append eww-retrieve-command (list url))
         :sentinel (lambda (process _)
                     (unless (process-live-p process)
                       (when (buffer-live-p error-buffer)
                         (when (get-buffer-process error-buffer)
                           (delete-process (get-buffer-process error-buffer) ))
                         (kill-buffer error-buffer))
                       (when (buffer-live-p buffer)
                         (with-current-buffer buffer
                           (goto-char (point-min))
                           (insert "Content-type: text/html; charset=utf-8\n\n")
                           (apply #'funcall callback nil cbargs)
                           ;; (pen-tv (buffer-string))
                           )))))))))

(defset shr-map
  (let ((map (make-sparse-keymap)))
    (define-key map "a" 'shr-show-alt-text)
    (define-key map "i" 'shr-browse-image)
    (define-key map "z" 'shr-zoom-image)
    (define-key map [?\t] 'shr-next-link)
    (define-key map [?\M-\t] 'shr-previous-link)
    (define-key map [follow-link] 'mouse-face)
    ;; (define-key map [mouse-2] 'shr-browse-url)
    (define-key map [mouse-2] 'lg-eww-follow-link)
    (define-key map [C-down-mouse-1] 'shr-mouse-browse-url-new-window)
    (define-key map "I" 'shr-insert-image)
    (define-key map "w" 'shr-maybe-probe-and-copy-url)
    (define-key map "u" 'shr-maybe-probe-and-copy-url)
    ;; (define-key map "v" 'shr-browse-url)
    (define-key map "v" 'lg-eww-follow-link)
    (define-key map "O" 'shr-save-contents)
    ;; (define-key map "\r" 'shr-browse-url)
    (define-key map "\r" 'lg-eww-follow-link)
    map))

(defun shr-browse-url (&optional external mouse-event new-window)
  "Browse the URL at point using `browse-url'.
If EXTERNAL is non-nil (interactively, the prefix argument), browse
the URL using `browse-url-secondary-browser-function'.
If this function is invoked by a mouse click, it will browse the URL
at the position of the click.  Optional argument MOUSE-EVENT describes
the mouse click event."
  (interactive (list current-prefix-arg last-nonmenu-event))
  (mouse-set-point mouse-event)
  (let ((url (get-text-property (point) 'shr-url)))
    (cond
     ((not url)
      (message "No link under point"))
     ((major-mode-p 'eww-mode)
      (lg-eww-follow-link))
     (external
      (funcall browse-url-secondary-browser-function url)
      (shr--blink-link))
     (t
      (browse-url url (xor new-window browse-url-new-window-flag))))))

(defun orig-eww (url &optional arg buffer)
  "Fetch URL and render the page.
If the input doesn't look like an URL or a domain name, the
word(s) will be searched for via `eww-search-prefix'.

If called with a prefix ARG, use a new buffer instead of reusing
the default EWW buffer.

If BUFFER, the data to be rendered is in that buffer.  In that
case, this function doesn't actually fetch URL.  BUFFER will be
killed after rendering."
  (interactive
   (let ((uris (eww-suggested-uris)))
     (list (pen-read-string (format-prompt "Enter URL or keywords"
                                       (and uris (car uris)))
                        nil 'eww-prompt-history uris)
           (prefix-numeric-value current-prefix-arg))))
  (setq url (eww--dwim-expand-url url))
  (pop-to-buffer-same-window
   (cond
    ((eq arg 4)
     (generate-new-buffer "*eww*"))
    ((eq major-mode 'eww-mode)
     (current-buffer))
    (t
     (get-buffer-create "*eww*"))))
  (eww-setup-buffer)
  ;; Check whether the domain only uses "Highly Restricted" Unicode
  ;; IDNA characters.  If not, transform to punycode to indicate that
  ;; there may be funny business going on.
  (let ((parsed (url-generic-parse-url url)))
    (when (url-host parsed)
      (unless (puny-highly-restrictive-domain-p (url-host parsed))
        (setf (url-host parsed) (puny-encode-domain (url-host parsed)))))
    ;; When the URL is on the form "http://a/../../../g", chop off all
    ;; the leading "/.."s.
    (when (url-filename parsed)
      (while (string-match "\\`/[.][.]/" (url-filename parsed))
        (setf (url-filename parsed) (substring (url-filename parsed) 3))))
    (setq url (url-recreate-url parsed)))
  (plist-put eww-data :url url)
  (plist-put eww-data :title "")
  (eww-update-header-line-format)
  (let ((inhibit-read-only t))
    (insert (format "Loading %s..." url))
    (goto-char (point-min)))
  (let ((url-mime-accept-string eww-accept-content-types))
    (if buffer
        (let ((eww-buffer (current-buffer)))
          (with-current-buffer buffer
            (eww-render nil url nil eww-buffer)))
      (eww-retrieve url #'eww-render
                    (list url nil (current-buffer))))))

(defun eww-open-file (file)
  "Render FILE using EWW."
  (interactive "fFile: ")
  (let* ((url (concat "file://"
                      (and (memq system-type '(windows-nt ms-dos))
                           "/")
                      (expand-file-name file)))
         (bufname (eww-bufname-for-url (slugify url))))
    (if (buffer-exists bufname)
        (switch-to-buffer bufname)
      (orig-eww url
                nil
                ;; The file name may be a non-local Tramp file.  The URL
                ;; library doesn't understand these file names, so use the
                ;; normal Emacs machinery to load the file.
                (with-current-buffer (generate-new-buffer " *eww file*")
                  (set-buffer-multibyte nil)
                  (insert "Content-type: " (or (mailcap-extension-to-mime
                                                (url-file-extension file))
                                               "application/octet-stream")
                          "\n\n")
                  (insert-file-contents file)
                  (current-buffer))))))

(defun eww-bufname-for-url (url)
  (concat "*eww-" (slugify url) "*"))

(defun lg-eww (url &optional use-chrome)
  "Same as 'eww' except it renames the buffer after loading."
  (interactive (list (read-string-hist "LookingGlass url:")))

  (if (not url)
      (setq url '("http://google.com")))

  (let ((bufname (eww-bufname-for-url (slugify url))))
    (if (buffer-exists bufname)
        (switch-to-buffer bufname)
      (progn
        (let ((cb (current-buffer)))
          (with-temp-buffer
            (eww url use-chrome)
            (ignore-errors (rename-buffer bufname) t)))))))

(defun lg-eww-js (url)
  "Same as 'eww' except it renames the buffer after loading."
  (interactive (list (pen-read-string "LG url:")))
  (lg-eww url t))

(defun lg-eww-nojs (url)
  "Same as 'eww' except it renames the buffer after loading."
  (interactive (list (pen-read-string "LG url:")))
  (lg-eww url -1))

(defun lg-eww-browse-url (&rest body)
  "Same as 'eww-browse-url' except it renames the buffer after loading."
  (interactive (list (pen-read-string "LG url:")))

  (if (not body)
      (setq body '("http://google.com")))

  (eval `(eww-browse-url ,@body))

  (ignore-errors (rename-buffer (concat "*eww-" (short-hash (concat (car body) (str (time-to-seconds))))) "*") t)
  (recenter-top))

(defun lg-eww-browse-url-chrome (&rest body)
  "Same as 'eww-browse-url' except it renames the buffer after loading."
  (interactive (list (pen-read-string "LG url:")))

  (setq eww-use-chrome t)

  (if (not body)
      (setq body '("http://google.com")))

  (eval `(eww-browse-url ,@body))
  (ignore-errors (rename-buffer (concat "*eww-" (short-hash (concat (car body) (str (time-to-seconds))))) "*") t)
  (recenter-top))

(defun shr-copy-current-url ()
  (interactive)
  (shr-copy-url (plist-get eww-data :url)))

(defun shr-maybe-probe-and-copy-url (url)
  "Copy the URL under point to the kill ring.
If the URL is already at the front of the kill ring act like
`shr-probe-and-copy-url', otherwise like `shr-copy-url'."
  (interactive (list (or (shr-url-at-point current-prefix-arg)
                         (plist-get eww-data :url))))
  (if (equal url (car kill-ring))
      (shr-probe-and-copy-url url)
    (shr-copy-url url)))

;; This is the entry point to the syntax highlighting
;; Always syntax highlight code. Syntaxh highlighting is not at fault. It's the size of the html docset.
;; This one loads fairly quickly
;; file:///$HOME/.docsets/Haskell.docset/Contents/Resources/Documents/file/Library/Frameworks/GHC.framework/Versions/8.4.3-x86_64/usr/share/doc/ghc-8.4.3/html/libraries/bytestring-0.10.8.2/Data-ByteString-Lazy-Char8.html#//apple_ref/func/putStrLn
(defun eww-tag-pre (dom)
  (let ((shr-folding-mode 'none)
        (shr-current-font 'default))
    (shr-ensure-newline)
    (insert (eww-fontify-pre dom))
    (shr-ensure-newline)))

(defun eww-fontify-pre (dom)
  (with-temp-buffer
    (shr-generic dom)
    (if eww-do-fontify-pre
        (let ((mode (eww-buffer-auto-detect-mode)))
          (when mode
            (eww-fontify-buffer mode))))
    (buffer-string)))

(defun eww-fontify-buffer (mode)
  (delay-mode-hooks (funcall mode))
  (font-lock-default-function mode)
  (font-lock-default-fontify-region (point-min)
                                    (point-max)
                                    nil))

;; This isn't actually inefficient. It runs once per <pre>
(defun eww-buffer-auto-detect-mode ()
  (let* ((map '((ada ada-mode)
                (awk awk-mode)
                (c c-mode)
                (cpp c++-mode)
                (clojure clojure-mode lisp-mode)
                (csharp csharp-mode java-mode)
                (css css-mode)
                (dart dart-mode)
                (delphi delphi-mode)
                (emacslisp emacs-lisp-mode)
                (erlang erlang-mode)
                (fortran fortran-mode)
                (fsharp fsharp-mode)
                (go go-mode)
                (groovy groovy-mode)
                (haskell haskell-mode)
                (html html-mode)
                (java java-mode)
                (javascript javascript-mode)
                (json json-mode javascript-mode)
                (latex latex-mode)
                (lisp lisp-mode)
                (lua lua-mode)
                (matlab matlab-mode octave-mode)
                (objc objc-mode c-mode)
                (perl perl-mode)
                (php php-mode)
                (prolog prolog-mode)
                (python python-mode)
                (r r-mode)
                (ruby ruby-mode)
                (rust rust-mode)
                (scala scala-mode)
                (shell shell-script-mode)
                (smalltalk smalltalk-mode)
                (sql sql-mode)
                (swift swift-mode)
                (visualbasic visual-basic-mode)
                (xml sgml-mode)))
         (language (language-detection-string
                    (buffer-substring-no-properties (point-min) (point-max))))
         (modes (cdr (assoc language map)))
         (mode (cl-loop for mode in modes
                        when (fboundp mode)
                        return mode)))
    (message (format "%s" language))
    (when (fboundp mode)
      mode)))

(defadvice shr-color-check (before unfuck compile activate)
  "Don't let stupid shr change background colors."
  (setq bg (face-background 'default)))

(defun goto-fragment (url)
  (let ((shr-target-id (urldecode (url-target (url-generic-parse-url url))))
        (origp (point)))
    (if shr-target-id
        (progn
          (goto-char (point-min))

          (let ((found-or-exhausted))
            (while (not found-or-exhausted)
              (let ((pnt (next-single-property-change
                          (point) 'shr-target-id)))
                (message (str pnt))

                (if pnt
                    (message (get-text-property pnt 'shr-target-id)))

                (if pnt (goto-char pnt))

                (cond
                 ((not pnt)
                  (progn
                    (setq found-or-exhausted t)))
                 ((string-equal
                   shr-target-id
                   (get-text-property pnt 'shr-target-id))
                  (setq found-or-exhausted pnt)))))

            (if (integerp found-or-exhausted)
                (goto-char found-or-exhausted)
              (progn
                (goto-char origp)
                (error "failed to find fragment"))))))))

(defun goto-link (url)
  (let
      ((shr-target-id (url-target (url-generic-parse-url url))))
    (cond
     (shr-target-id
      (goto-char (point-min))
      (let ((point (next-single-property-change
                    (point-min) 'shr-target-id)))
        (when point
          (goto-char point)))))))

(defun eww-same-page-p (url1 url2)
  "Return non-nil if URL1 and URL2 represent the same page.
Differences in #targets are ignored."
  (let ((obj1 (url-generic-parse-url url1))
	      (obj2 (url-generic-parse-url url2)))
    (setf (url-target obj1) nil)
    (setf (url-target obj2) nil)
    (equal (url-recreate-url obj1) (url-recreate-url obj2))))

(defun insert-invisible-text (text)
  (let ((a text))
    (put-text-property 0 (length text) 'invisible t a)
    (insert a)))

(defun shr-descend (dom)
  (let ((function
         (intern (concat "shr-tag-" (symbol-name (dom-tag dom))) obarray))
        (external (cdr (assq (dom-tag dom) shr-external-rendering-functions)))
        (style (dom-attr dom 'style))
        (shr-stylesheet shr-stylesheet)
        (shr-depth (1+ shr-depth))
        (start (point)))
    (if (> shr-depth (/ max-specpdl-size 15))
        (setq shr-warning "Too deeply nested to render properly; consider increasing `max-specpdl-size'")
      (when style
        (if (string-match "color\\|display\\|border-collapse" style)
            (setq shr-stylesheet (nconc (shr-parse-style style)
                                        shr-stylesheet))
          (setq style nil)))
      (unless (equal (cdr (assq 'display shr-stylesheet)) "none")
        (cond (external
               (funcall external dom))
              ((fboundp function)
               (funcall function dom))
              (t
               (shr-generic dom)))
        (never
         (let ((mid (dom-attr dom 'id))
               (mname (dom-attr dom 'name)))
           (if (or (sor mid)
                   (sor mname))
               (progn
                 (pen-log (concat "shr-target-id: " shr-target-id))
                 (pen-log (concat "id: " mid))
                 (pen-log (concat "name: " mname))))))
        (never
         (when (and shr-target-id
                    (or (equal (dom-attr dom 'id) shr-target-id)
                        (equal (dom-attr dom 'name) shr-target-id)))
           (insert " ")
           (put-text-property start (1+ start) 'shr-target-id shr-target-id)))
        (let ((target (or (sor (dom-attr dom 'id))
                          (sor (dom-attr dom 'name)))))
          (when target
            (insert " ")
            (put-text-property start (1+ start) 'shr-target-id target)))
        ;; If style is set, then this node has set the color.
        (when style
          (shr-colorize-region
           start (point)
           (cdr (assq 'color shr-stylesheet))
           (cdr (assq 'background-color shr-stylesheet))))))))

(defun shr-tag-a (dom)
  (let ((url (dom-attr dom 'href))
        (title (dom-attr dom 'title))
        (start (point))
        shr-start)
    (shr-generic dom)
    (when (and shr-target-id
               (equal (dom-attr dom 'name) shr-target-id)
               (equal (dom-attr dom 'id) shr-target-id))
      ;; We have a zero-length <a name="foo"> element, so just
      ;; insert...  something.
      (when (= start (point))
        (shr-ensure-newline)
        (insert " "))
      (put-text-property start (1+ start) 'shr-target-id shr-target-id))
    (when url
      (shr-urlify (or shr-start start) (shr-expand-url url) title))))

(defun eww-dom-to-xml ()
  (shr-dom-to-xml (plist-get eww-data :dom)))

(defun etv-dom ()
  (interactive)
  (pen-etv (eww-dom-to-xml)))

(defun eww-render (status url &optional point buffer encode use-chrome)
  (if (or (not (lg-url-cache-exists url))
          lg-url-cache-update)
      (pen-url-cache url (buffer-string)))

  ;; It looks like the urlretieve has exactly the output of the following
  ;; curl -i "https:/hoogle.haskell.org/?hoogle=Text.unpack" | vim -
  ;; Therefore I must decode here
  ;; If I actually visit https:/hoogle.haskell.org/?hoogle=Text.unpack
  ;; in Chrome,
  ;; then click on the drop down and scroll to the very end
  ;; I will see that the decoding problems are in Hoogle too

  ;; This fixes a minor issue
  (let ((newhttpdata (s-replace "charset=utf8" "charset=utf-8" (buffer-string))))
    (delete-region
     (point-min)
     (point-max))
    (insert newhttpdata))

  (let* ((headers (eww-parse-headers))
         (content-type
          (mail-header-parse-content-type
           (if (zerop (length (cdr (assoc "content-type" headers))))
               "text/plain"
             (cdr (assoc "content-type" headers)))))
         (charset (intern
                   (downcase
                    (or (cdr (assq 'charset (cdr content-type)))
                        (eww-detect-charset (eww-html-p (car content-type)))
                        "utf-8"))))
         (data-buffer (current-buffer))
         (shr-target-id (url-target (url-generic-parse-url url)))
         last-coding-system-used)
    (let ((redirect (plist-get status :redirect)))
      (when redirect
        (setq url redirect)))
    (with-current-buffer buffer
      ;; Save the https peer status.

      (plist-put eww-data :peer (plist-get status :peer))
      (setq list-buffers-directory url)
      ;; Let the URL library have a handle to the current URL for
      ;; referer purposes.
      (setq url-current-lastloc (url-generic-parse-url url)))
    (unwind-protect
        (progn

          (cond
           ((and eww-use-external-browser-for-content-type
                 (string-match-p eww-use-external-browser-for-content-type
                                 (car content-type)))
            (erase-buffer)
            (insert "<title>Unsupported content type</title>")
            (insert (format "<h1>Content-type %s is unsupported</h1>"
                            (car content-type)))
            (insert (format "<a href=%S>Direct link to the document</a>"
                            url))
            (goto-char (point-min))
            (eww-display-html charset url nil point buffer encode use-chrome))
           ((eww-html-p (car content-type))
            (eww-display-html charset url nil point buffer encode use-chrome))
           ((equal (car content-type) "application/pdf")
            (eww-display-pdf))
           ((string-match-p "\\`image/" (car content-type))
            (eww-display-image buffer))
           (t
            (eww-display-raw buffer (or encode charset 'utf-8))))
          (with-current-buffer buffer
            (plist-put eww-data :url url)
            (eww-update-header-line-format)
            (setq eww-history-position 0)
            (and last-coding-system-used
                 (set-buffer-file-coding-system last-coding-system-used))
            (run-hooks 'eww-after-render-hook)))
      (kill-buffer data-buffer))))

;; eww-after-render-hook

(defun lg-url-cache-slug-fp (url)
  (concat pen-url-cache-dir "/" (slugify (s-replace-regexp "#.*" "" url)) ".txt"))

(defun lg-url-cache-exists (url)
  (setq url (pen-redirect url))

  (and lg-url-cache-enabled
       (or (f-exists-p (lg-url-cache-slug-fp url))
           (f-exists-p (lg-url-cache-slug-fp (google-cachify url))))))

(defun pen-url-cache (url &optional contents)
  (setq url (pen-redirect url))
  (if contents
      (write-to-file contents (lg-url-cache-slug-fp url))
    (cat (lg-url-cache-slug-fp url))))

(advice-add 'pen-url-cache :around #'shut-up-around-advice)

(defun eww-dump-vim (url)
  (interactive (list (get-path)))
  (if (or (major-mode-p 'eww-mode)
          (major-mode-p 'html-mode))
      ;; (term-nsfa (cmd "dump-clean" url))
      (tpop (cmd "dump-clean" url))))

(defun eww-reload-cache-for-page (url)
  (interactive (list (get-path)))
  (if (major-mode-p 'eww-mode)
      (progn
        (let ((current-prefix-arg nil))
          (pen-url-cache-delete url))
        (call-interactively 'pen-eww-reload))))

(defun pen-url-cache-delete (url)
  (interactive (list (get-path)))
  (if (major-mode-p 'eww-mode)
      (f-delete (lg-url-cache-slug-fp url) t)))

(defun pen-sps (&optional cmd nw_args input dir)
  (interactive)

  ;; Only run if available
  (ignore-errors
    (pen-sps cmd nw_args input dir)))

(defun browsh (&rest body)
  (interactive (list (pen-read-string "url:")))

  (if (not body)
      (setq body '("http://google.com")))

  (pen-sps (concat "browsh " (pen-q (car body)))))

(defun eww-open-browsh (path)
  (interactive (list (get-path)))
  (browsh path))

(defun pen-redirect (url)
  (pen-snc "pen-redirect" url))

(defun eww (url &optional use-chrome)
  "Fetch URL and render the page.
If the input doesn't look like an URL or a domain name, the
word(s) will be searched for via `eww-search-prefix'."
  (interactive
   (let* ((uris (eww-suggested-uris))
          (prompt (concat "Enter URL or keywords"
                          (if uris (format " (default %s)" (car uris)) "")
                          ": ")))
     (list (pen-read-string prompt nil nil uris))))

  ;; It works when placed here
  (pen-set-faces)

  (setq url (pen-snc "pen-urldecode | chomp" url))
  (setq url (pen-redirect url))

  (hs "eww-display-html" url)

  (if (re-match-p "^/" url)
      (setq url (concat "file://" url))
    (setq url (eww--dwim-expand-url url)))

  (if (and (not pen-lg-always)
           (lg-url-is-404 url)
           (yn "Try wayback?"))
      (setq url (eww-select-wayback-for-url url)))

  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 16) (pen-lg-display-page url))
   (pen-lg-always (pen-lg-display-page url))
   ((lg-url-is-404 url) (pen-lg-display-page url))
   (t
    (progn
      ;; *eww-racket-doc*
      (if (and (string-match "^\\*.*\\*$" (buffer-name))
               (not (string-match "^\\*eww\\*$" (buffer-name))))
          (pop-to-buffer-same-window
           (if (eq major-mode 'eww-mode)
               (current-buffer)
             (get-buffer-create "*eww*")))
        ;; I can re-enable uniqifiy-buffer  by removing "id :i"
        ;; (id :i uniqify-buffer (pop-to-buffer-same-window (if (eq major-mode 'eww-mode) (current-buffer) (get-buffer-create "*eww*"))))
        (uniqify-buffer
            (pop-to-buffer-same-window
             (if (eq major-mode 'eww-mode)
                 (current-buffer)
               (get-buffer-create "*eww*")))))
      (eww-setup-buffer)
      ;; Check whether the domain only uses "Highly Restricted" Unicode
      ;; IDNA characters.  If not, transform to punycode to indicate that
      ;; there may be funny business going on.
      (let ((parsed (url-generic-parse-url url)))
        (when (url-host parsed)
          (unless (puny-highly-restrictive-domain-p (url-host parsed))
            (setf (url-host parsed) (puny-encode-domain (url-host parsed)))
            (setq url (url-recreate-url parsed)))))
      (plist-put eww-data :url url)
      (plist-put eww-data :title "")
      (eww-update-header-line-format)
      (let ((inhibit-read-only t))
        (insert (format "Loading %s..." url))
        (goto-char (point-min))

        (if (and (lg-url-cache-exists url)
                 (not lg-url-cache-update))
            (let ((b (current-buffer)))
              (with-temp-buffer
                (insert (pen-url-cache url))
                (goto-char (point-min))
                (eww-render nil url (point) b))
              (with-current-buffer b
                (setq header-line-format (propertize (str header-line-format) 'face 'org-bold))))

          ;; (pen-tv (buffer-string))
          (url-retrieve url 'eww-render
                        (list url nil (current-buffer) nil use-chrome))))
      (current-buffer)))))

(defun lg-url-is-404 (url)
  "URL is 404"
  ;; lg-url-is-404
  (let ((info (pen-sn (concat "pen-curl-firefox -s -I " (pen-q url))))
        (html (pen-sn (concat "dom-dump " (pen-q url)))
              ;; (pen-sn (concat "pen-curl-firefox -s " (pen-q url)))
              ))
    (comment
     (pen-sn-true (concat "pen-curl-firefox -s -I " (pen-q url) " | grep -q \"404 Not Found\"")))
    (or (re-match-p "Wikipedia does not have an article with this exact name" html)
        (re-match-p "404 Not Found" info)
        (re-match-p "502 Bad Gateway" info)
        (not (sor info)))))

(defun google-cachify (url)
  (concat "http://webcache.googleusercontent.com/search?q=cache:" (google-uncachify url)))

(defun url-cache-is-404-curl (url)
  "URL cache is 404"
  (lg-url-is-404 (google-cachify url)))

(defun url-cache-is-404 (url)
  "URL cache is 404"
  (not (url-found-p (google-cachify url))))

(defun ecurl (url)
  (with-current-buffer (url-retrieve-synchronously url t t 5)
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point) (point-min))
    (kill-line)
    (let ((result (buffer2string (current-buffer))))
      (kill-buffer)
      result)))

(defun url-found-p (url)
  "Return non-nil if URL is found, i.e. HTTP 200."
  (with-current-buffer (url-retrieve-synchronously url nil t 5)
    (prog1 (eq url-http-response-status 200)
      (kill-buffer))))

(defun eww--dwim-expand-url-around-advice (proc &rest args)
  (let ((url (google-uncachify (car args))))
    (if (and (or
              eww-use-google-cache
              (string-match-p "towardsdatascience" url)
              (string-match-p "medium.com" url)
              (string-match-p "quora.com" url))
             (not (string-match-p "webcache.google" url)))
        (if
            (not (url-cache-is-404 url))
            (setq url (google-cachify url))))
    (let ((res (apply proc (list url))))
      res)))
(advice-add 'eww--dwim-expand-url :around #'eww--dwim-expand-url-around-advice)

(defun google-uncachify (url)
  (pen-sed "s=^http.\\?://webcache\\.googleusercontent\\.com/search?q\\=cache:==" url))

(defun toggle-cached-version ()
  (interactive)
  (let ((url (plist-get eww-data :url)))
    (if url
        (progn
          (if (string-match-p "webcache.google" url)
              (setq url (google-uncachify url))
            (setq url (google-cachify url)))
          (advice-remove 'eww--dwim-expand-url #'eww--dwim-expand-url-around-advice)
          (eww-browse-url url)
          (advice-add 'eww--dwim-expand-url :around #'eww--dwim-expand-url-around-advice)))))

(defun toggle-use-chrome-locally ()
  (interactive)
  (if (not (pen-lvp 'eww-use-chrome))
      (defset-local eww-use-chrome (not eww-use-chrome))
    (setq eww-use-chrome (not eww-use-chrome)))
  (if eww-use-chrome
      (message "Using the Google Chrome DOM locally")
    (message "Using shr.el"))
  (if (major-mode-p 'eww-mode)
      (progn
        (pen-url-cache-delete (get-path))
        (pen-eww-reload)))
  eww-use-chrome)

(defun toggle-use-rdrview ()
  (interactive)
  (setq eww-use-rdrview (not eww-use-rdrview))
  (if eww-use-rdrview
      (message "Using rdrview for easy reading")
    (message "rdrview disabled"))
  (if (major-mode-p 'eww-mode)
      (pen-eww-reload))
  eww-use-rdrview)

(defun toggle-use-tor ()
  (interactive)
  (setq eww-use-tor (not eww-use-tor))
  (if eww-use-tor
      (message "dom-dump will use tor proxy")
    (message "dom-dump is using clear internet"))
  (if (major-mode-p 'eww-mode)
      (pen-eww-reload))
  eww-use-tor)

(defun toggle-update-ci ()
  (interactive)
  (setq eww-update-ci (not eww-update-ci))
  (if eww-update-ci
      (message "dom-dump will update")
    (message "dom-dump is cached"))
  (if (major-mode-p 'eww-mode)
      (pen-eww-reload))
  eww-update-ci)

(defun eww-add-bookmark-manual (uri)
  (interactive (list (pen-read-string "uri:")))
  (eww-read-bookmarks)
  (dolist (bookmark eww-bookmarks)
    (when (equal (plist-get eww-data :url) (plist-get bookmark :url))
      (user-error "Already bookmarked")))
  (let ((title (replace-regexp-in-string "[\n\t\r]" " "
                                         (chomp (pen-sn (concat "ci web title " (e/q uri)))))))
    (setq title (replace-regexp-in-string "\\` +\\| +\\'" "" title))
    (push (list :url uri
                :title title
                :time (current-time-string))
          eww-bookmarks))
  (eww-write-bookmarks)
  (message "Bookmarked %s (%s)" (plist-get eww-data :url)
           (plist-get eww-data :title))
  (call-interactively 'eww-list-bookmarks)
  nil)

(defun eww-bookmark-kill-ask ()
  (interactive)
  (when (y-or-n-p "Delete this bookmark?")
    (call-interactively 'eww-bookmark-kill)))

(defun eww-follow-link (&optional external mouse-event)
  "Browse the URL under point.
If EXTERNAL is single prefix, browse the URL using `shr-external-browser'.
If EXTERNAL is double prefix, browse in new buffer."
  (interactive (list current-prefix-arg last-nonmenu-event))
  (mouse-set-point mouse-event)

  (let* ((url (get-text-property (point) 'shr-url))
         (bufname (eww-bufname-for-url url)))
    (setq eww-followed-link url)
    (cond
     ((not url)
      (message "No link under point"))
     ((string-match "^mailto:" url)
      (browse-url-mail url))
     ((string-match "^https?://asciinema.org/a/[a-zA-Z0-9]+/?$" url)
      (pen-tm-asciinema-play url))
     ((and (consp external) (<= (car external) 4))
      (funcall shr-external-browser url))
     ;; This is a #target url in the same page as the current one.
     ((and (url-target (url-generic-parse-url url))
           (eww-same-page-p url (get-path)))

        (goto-fragment url)
        (never (let ((dom (plist-get eww-data :dom)))
               (eww-save-history)
               (eww-display-html 'utf-8 url dom nil (current-buffer)))))
     (t
      (lg-eww url)))))


(defun rename-eww-buffer-unique (&optional url)
  (interactive)
  (if (not url)
      (setq url (get-path)))
  (ignore-errors (rename-buffer (concat "*eww-" (short-hash (concat url (str (time-to-seconds)))) "*")) t))

(defvar eww-browse-url-after-hook '())
(defun eww-browse-url-after-advice (&rest args)
  "Give the buffer a unique name and recenter to the top"
  (recenter-top)
  (run-hooks 'eww-browse-url-after-hook))
(advice-add 'eww-browse-url :after 'eww-browse-url-after-advice)

(defun eww-follow-link-after-advice (&rest args)
  "Recenter to the top"
  (recenter-top)
  (run-hooks 'eww-follow-link-after-hook))
(advice-add 'eww-follow-link :after 'eww-follow-link-after-advice)

(defun eww-reload-after-advice (&rest args)
  (run-hooks 'eww-reload-after-hook))
(advice-add 'eww-reload :after 'eww-reload-after-advice)
(advice-add 'pen-eww-reload :after 'eww-reload-after-advice)

(defun eww-restore-history-after-advice (&rest args)
  (run-hooks 'eww-restore-history-after-hook))
(advice-add 'eww-restore-history :after 'eww-restore-history-after-advice)

(defun browse-url-can-use-xdg-open ()
  "Return non-nil if the \"xdg-open\" program can be used.
xdg-open is a desktop utility that calls your preferred web browser."
  nil)

(defun lg-eww-save-image (filename)
  "Save an image opened in an *eww* buffer to a file."
  (interactive "G")
  (let ((image (get-text-property (point) 'display)))
    (with-temp-buffer
      (setq buffer-file-name filename)
      (insert
       (plist-get (if (eq (car image) 'image) (cdr image)) :data))
      (save-buffer))))

(defun lg-eww-save-image-auto ()
  "Save an image opened in an *eww* buffer to a file."
  (interactive)
  (let ((image (get-text-property (point) 'display)))
    (with-temp-buffer
      (setq buffer-file-name (org-babel-temp-file "image" ".bin"))
      (insert
       (plist-get (if (eq (car image) 'image) (cdr image)) :data))
      (save-buffer))))

(defun eww-display-html (charset url &optional document point buffer encode use-chrome)
  (hs "eww-display-html" url)

  ;; The decoding issues are present in the original eww too.
  ;; My changes are not responsible for the.

  (unless (fboundp 'libxml-parse-html-region)
    (error "This function requires Emacs to be compiled with libxml2"))
  (unless (buffer-live-p buffer)
    (error "Buffer %s doesn't exist" buffer))

  (setq url-queue nil)

  (let* ((envs (concat ""
                       (if (or
                            eww-update-ci
                            (>= (prefix-numeric-value current-global-prefix-arg) 4))
                           "UPDATE=y " "")
                       (if eww-use-tor "USE_TOR=y " "")))
         (basepath (url-basepath url))
         (html
          (let ((htmlbuild
                 (save-excursion
                   (progn
                     (beginning-of-buffer)
                     (search-forward-regexp "^$")
                     (search-forward-regexp "^.")
                     (beginning-of-line))
                   (decode-coding-string (buffer-substring (point) (point-max)) 'utf-8))))
            (if (and
                 (not (and (numberp use-chrome)
                           (< use-chrome 0)))
                 (or eww-use-chrome
                     use-chrome
                     (or (string-match-p "/grep\\.app" url)
                         (string-match-p "://beta.openai.com/" url)
                         (string-match-p "://clojuredocs.org/" url)
                         ;; https://super.gluebenchmark.com/
                         (string-match-p "://super.gluebenchmark.com/" url)
                         (string-match-p "://groups.google.com/forum/" url)
                         (string-match-p (regexp-quote "://racket/search/index.html?q") url)
                         (string-match-p (regexp-quote "://docs.racket-lang.org/search/") url)
                         ;; [[https://download.racket-lang.org/releases/7.9/doc/local-redirect/index.html][download.racket-lang.org/releases/7.9/doc/local-redirect/index.html]]
                         (string-match-p "://.*\\.racket-lang\\.org/.*\\?doc=" url))))

                (let ((newhtml (shell-command-to-string (concat envs "dom-dump " (shell-quote-argument url)))))
                  (if (string-empty-p newhtml)
                      (progn
                        (setq newhtml (shell-command-to-string (concat envs "upd dom-dump " (shell-quote-argument url))))
                        (if (string-empty-p newhtml)
                            (ns "dom-dump returned empty string"))))
                  (setq htmlbuild newhtml)))

            (if (and eww-use-rdrview
                     (not (string-match-p (regexp-quote "://racket/") url))
                     (not (string-match-p (regexp-quote "://godoc.org/") url))
                     (not (string-match-p (regexp-quote "://docs.racket-lang.org/") url)))

                (setq htmlbuild (pen-cl-sn (concat "rdrextract -u " (pen-q basepath)) :stdin htmlbuild :chomp t)))

            htmlbuild))

         (newdocument
          (or
           document
           (list
            'base (list (cons 'href url))
            (progn
              (save-excursion
                ;; Go to after the http headers
                (progn
                  (beginning-of-buffer)
                  (search-forward-regexp "^$")
                  (search-forward-regexp "^.")
                  (beginning-of-line))
                (save-mark-and-excursion
                  (delete-region (point) (point-max))

                  (if (or
                       (not eww-use-rdrview)
                       (str-match-p "UNREADERABLE" html))
                      (insert (encode-coding-string html 'utf-8))
                    (insert html))))
              (setq encode (or encode charset 'utf-8))
              (condition-case nil
                  (decode-coding-region (point) (point-max) encode)
                (coding-system-error nil))
              (save-excursion
                ;; Remove CRLF before parsing.
                (while (re-search-forward "\r$" nil t)
                  (replace-match "" t t)))
              (libxml-parse-html-region (point) (point-max))))))
         (source (and (null newdocument)
                      (buffer-substring (point) (point-max)))))
    (with-current-buffer buffer
      ;; This enables you to continue browsing using the chrome dom without setting globally
      (if use-chrome
          (defset-local eww-use-chrome use-chrome))
      (setq bidi-paragraph-direction nil)
      (plist-put eww-data :source html)
      (plist-put eww-data :dom newdocument)
      (let ((inhibit-read-only t)
            (inhibit-modification-hooks t)
            (shr-target-id (url-target (url-generic-parse-url url)))
            (shr-external-rendering-functions
             (append
              shr-external-rendering-functions
              '((title . eww-tag-title)
                (form . eww-tag-form)
                (input . eww-tag-input)
                (button . eww-form-submit)
                (textarea . eww-tag-textarea)
                (select . eww-tag-select)
                (link . eww-tag-link)
                (meta . eww-tag-meta)
                (a . eww-tag-a)))))
        (erase-buffer)
        (shr-insert-document newdocument)
        (cond
         (point
          (goto-char point))
         (shr-target-id
          (goto-char (point-min))
          (let ((point (next-single-property-change
                        (point-min) 'shr-target-id)))
            (when point
              (goto-char point))))
         (t
          (goto-char (point-min))
          ;; Don't leave point inside forms, because the normal eww
          ;; commands aren't available there.
          (while (and (not (eobp))
                      (get-text-property (point) 'eww-form))
            (forward-line 1)))))
      (eww-size-text-inputs))))

(defun delete-selected ()
  (interactive)
  (delete-region (point) (mark))
  (deselect))

(defun clean-up-libraries-io ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward "------")
  (forward-line)
  (forward-char)
  (delete-selected)

  (end-of-buffer)

  (cua-set-mark)
  (re-search-backward "^License")
  (previous-line)
  (delete-selected)

  (beginning-of-buffer)

  (toggle-read-only))

(defun clean-up-stackexchange ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward "Ask Question")
  (forward-paragraph)
  (forward-line)
  (delete-selected)
  (toggle-read-only))

(defun clean-up-swiprolog ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (re-search-forward "^Availability")
  (beginning-of-line)
  (delete-selected)
  (toggle-read-only))

(defun clean-up-coinmarketcap ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward "Rank  Name")
  (search-forward "Rank  Name")
  (search-forward "Rank  Name")
  (delete-selected)
  (toggle-read-only))

;; http://gen.lib.rus.ec/search.php?req=lord+of+the+rings&lg_topic=libgen&open=0&view=simple&res=25&phrase=1&column=def
(defun clean-up-libgen ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward-regexp "Search in fields")
  (delete-selected)
  (toggle-read-only))

(defun clean-up-librarylol ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward-regexp "  Title:")
  (delete-selected)
  (toggle-read-only))

(defun clean-up-libgen-result ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward-regexp "  Title:")
  (delete-selected)
  (toggle-read-only))

(defun clean-up-grep-app ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward-regexp "^Showing")
  (search-forward-regexp "^\*")
  (delete-selected)
  (toggle-read-only))

(defun clean-up-wikipedia ()
  (interactive)
  ;; I think this is ok for most articles
  (progn
    (beginning-of-buffer)
    (toggle-read-only)
    (cua-set-mark)
    (forward-paragraph)
    (forward-paragraph)
    (irc-find-next-line-with-diff-char)
    (delete-selected)
    (toggle-read-only)))

(defun clean-up-google-results ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward-regexp "Search Tools")
  (forward-line)
  (forward-line)
  (delete-selected)
  (toggle-read-only))

(defun clean-up-racket-doc ()
  (interactive)
  (save-excursion
    (read-only-mode -1)

    (goto-char (point-min))
    (while (re-search-forward "(\\*\\([^ ]\\)" nil t)

      (backward-char 2)
      (delete-char 1)))

  (toggle-read-only))

(defun clean-up-github-author ()
  (interactive)
  (if (string-match-p "^Repositories$" (buffer-string))
      (progn
        (beginning-of-buffer)
        (toggle-read-only)
        (cua-set-mark)
        (search-forward-regexp "^Repositories")
        (forward-line)
        (forward-char)
        (delete-selected)
        (toggle-read-only))))

(defun clean-up-github-issues ()
  (interactive)
  ;; https://github.com/psf/black/issues/1707
  (if (string-match-p "Jump to bottom" (buffer-string))
      (progn
        (beginning-of-buffer)
        (toggle-read-only)
        (cua-set-mark)
        (search-forward-regexp "^Jump to bottom")
        (forward-line)
        (forward-char)
        (delete-selected)
        (toggle-read-only))))

(defun clean-up-clojuredocs ()
  (interactive)
  (beginning-of-buffer)
  (toggle-read-only)
  (cua-set-mark)
  (search-forward-regexp "Available since")
  (backward-paragraph)
  (backward-paragraph)
  (delete-selected)
  (toggle-read-only))

(defun pen-tor-new-identity ()
  (interactive)
  (pen-sn "sudo /etc/init.d/tor restart")
  (after-sec 2 (if (major-mode-p 'eww-mode)
                   (pen-eww-reload))))

;; https://emacs.stackexchange.com/questions/32644/how-to-concatenate-two-lists
(defvar eww-patchup-url-alist nil)
(add-to-list 'eww-patchup-url-alist '("https?://github.com/[^/]+$" . clean-up-github-author))
(add-to-list 'eww-patchup-url-alist '("https?://github.com/.*/issues/[0-9]+$" . clean-up-github-issues))
(add-to-list 'eww-patchup-url-alist '("://en.wikipedia.org/" . clean-up-wikipedia))
(add-to-list 'eww-patchup-url-alist '("://clojuredocs.org/" . clean-up-clojuredocs))
(add-to-list 'eww-patchup-url-alist '("://coinmarketcap.com/" . clean-up-coinmarketcap))
(add-to-list 'eww-patchup-url-alist '("://www.google.com/search\\?.*q=" . clean-up-google-results))
(add-to-list 'eww-patchup-url-alist '("://docs.racket-lang.org/" . clean-up-racket-doc))
(add-to-list 'eww-patchup-url-alist '("://racket/" . clean-up-racket-doc))
(add-to-list 'eww-patchup-url-alist '(".stackexchange.com/questions/" . clean-up-stackexchange))
(add-to-list 'eww-patchup-url-alist '("://grep.app/" . clean-up-grep-app))
(add-to-list 'eww-patchup-url-alist '("://www.swi-prolog.org/pldoc/man" . clean-up-swiprolog))
(add-to-list 'eww-patchup-url-alist '("://gen.lib.rus.ec/" . clean-up-libgen))
(add-to-list 'eww-patchup-url-alist '("://gen.lib.rus.ec/book/index" . clean-up-libgen-result))
(add-to-list 'eww-patchup-url-alist '("://libraries.io/search" . clean-up-libraries-io))

(defun pen-eww-show-status ()
  (interactive)
  (message
   (concat
    "Finished loading page! [chrome: "
    (if eww-use-chrome "on" "off")
    ", cache: "
    (if (s-matches-p
         "webcache.google"
         (get-path))
        "on"
      "off")
    ", reader: "
    (if eww-use-rdrview "on" "off")
    ", update: "
    (if eww-update-ci "on" "off")
    ", tor: "
    (if eww-use-tor "on" "off")
    "]")))

(defun finished-loading-page ()
  "Needed so that x/expect can automate it"

  (with-writable-buffer
   (with-buffer-region-beg-end
    (eww-sanitize-postrendered beg end)
    (region-erase-trailing-whitespace beg end)))

  (progn-dontstop
   (let ((f (assoc-default (get-path) eww-patchup-url-alist #'string-match)))
     (if f (call-function f)))

   (setq-local imenu-create-index-function #'button-cloud-create-imenu-index)

   (never (my-flyspell-buffer))

   (recenter-top)
   (goto-fragment (get-path))

   (deselect)
   (cond
    ((and (or (equal 0 (length (buffer-string)))
              (re-match-p "502 Bad Gateway" (buffer-string)))
          (not (lg-url-is-404 (get-path))))
     (progn
       (message "Failed to load page, I think")
       (let ((cb (current-buffer)))
         (w3m (get-path))
         (kill-buffer cb))))
    ((and (or (equal 0 (length (buffer-string)))
              (re-match-p "502 Bad Gateway" (buffer-string)))
          (lg-url-is-404 (get-path)))
     (progn
       (let ((cb (current-buffer)))
         (message "Website doesn't exist. Imagining instead")
         (pen-lg-display-page url)
         (kill-buffer cb))))
    (t
     (progn
       ;; Run if exists
       (progn-dontstop
         (pen-run-buttonize-hooks)
         (pen-eww-show-status)))))))

(defun eww-back-url-around-advice (proc &rest args)
  (let ((res (apply proc args)))

    ;; Run if exists
    (ignore-erros
     (pen-run-buttonize-hooks))
    res))
(advice-add 'eww-back-url :around #'eww-back-url-around-advice)

(add-hook 'eww-after-render-hook #'finished-loading-page)
;; (add-hook 'eww-after-render-hook 'pen-set-faces)

(add-hook 'eww-after-render-hook #'finished-loading-page)

(defun eww-display-html-after-advice (&rest args)
  (run-hooks 'eww-display-html-after-hook))
(advice-add 'eww-display-html :after 'eww-display-html-after-advice)

(defun ace-link--eww-collect ()
  "Collect the positions of visible links in the current `eww' buffer."
  (save-excursion
    (save-restriction
      (narrow-to-region
       (window-start)
       (window-end))
      (goto-char (point-min))
      (let (beg end candidates)
        (setq end
              (if (get-text-property (point) 'help-echo)
                  (point)
                (text-property-any
                 (point) (point-max) 'help-echo nil)))
        (while (setq beg (text-property-not-all
                          end (point-max) 'help-echo nil))
          (goto-char beg)
          (setq end (or (text-property-any
                         (point) (point-max) 'help-echo nil)
                        (point-max)))
          (push (cons (buffer-substring-no-properties beg end) beg)
                candidates))
        (nreverse candidates)))))

(defun browse-url-generic-around-advice (proc &rest args)
  (let ((arg (prefix-numeric-value current-prefix-arg))
        (url (car args)))

    (when (= arg 4)
      (let ((res (apply proc args)))
        res))
    (when (= arg 16)
      (setq eww-use-chrome t)
      (lg-eww (car args) eww-use-chrome))
    (when (= arg 1)

      (lg-eww (car args)))))
(advice-add 'browse-url-generic :around #'browse-url-generic-around-advice)
;; (advice-remove 'browse-url-generic #'browse-url-generic-around-advice)

(defun eww-reload-with-ci-cache-on ()
  (interactive)
  (setq eww-update-ci t)
  (call-interactively 'pen-eww-reload))

(defun reload-eww-use-google-cache-matchers ()
  (setq eww-use-google-cache-matchers
        (pen-str2list (chomp (cat (f-join penconfdir "conf" "google-cache-url-patterns.txt"))))))
(reload-eww-use-google-cache-matchers)

(defun reload-eww-use-chrome-dom-matchers ()
  (setq eww-use-chrome-dom-matchers
        (pen-str2list (chomp (cat (f-join penconfdir "conf" "chrome-dom-url-patterns.txt"))))))
(reload-eww-use-chrome-dom-matchers)

(defun reload-eww-use-reader-matchers ()
  (setq eww-use-reader-matchers
        (pen-str2list (chomp (cat (f-join penconfdir "conf" "reader-url-patterns.txt"))))))
(reload-eww-use-reader-matchers)

(defun reload-eww-ff-dom-matchers ()
  (setq eww-ff-dom-matchers
        (pen-str2list
         (cat (f-join penconfdir "conf" "ff-url-patterns.txt")))))
(reload-eww-ff-dom-matchers)

(defun eww-display-html-around-advice (proc &rest args)
  (reload-eww-use-google-cache-matchers)
  (reload-eww-use-chrome-dom-matchers)
  (reload-eww-use-reader-matchers)
  (let ((eww-use-google-cache (-reduce (lambda (a b) (or a b))
                                       (or (mapcar (lambda (e) (re-match-p e (second args)))
                                                   (-filter-not-empty-string eww-use-google-cache-matchers))
                                           '(nil))))
        (match-use-chrome (-reduce (lambda (a b) (or a b))
                                   (or (mapcar (lambda (e) (re-match-p e (second args)))
                                               (-filter-not-empty-string eww-use-chrome-dom-matchers))
                                       '(nil))))
        (eww-use-rdrview (-reduce (lambda (a b) (or a b))
                                  (or (mapcar (lambda (e) (re-match-p e (second args)))
                                              (-filter-not-empty-string eww-use-reader-matchers))
                                      '(nil)))))
    (cond
     (match-use-chrome
      (let ((eww-use-chrome t)
            (eww-update-ci t))
        (let ((res (apply proc args)))
          res)))

     ((string-match-p "thepiratebay" (second args))
      (let ((eww-use-chrome t)
            (eww-use-tor t)
            (eww-update-ci t))
        (message "enable tor")
        (let ((res (apply proc args)))
          res)))
     (t
      (let ((res (apply proc args)))
        res)))))
(advice-add 'eww-display-html :around #'eww-display-html-around-advice)

(defun dump-url-file-and-edit (url)
  (interactive (list (read-string-hist "file url: ")))
  (find-file (pen-snc (pen-cmd "put-url-to-dump" url))))


(defun pen-gh-list-user-repos (user)
  (pen-snc
   (format
    "pen-gh-curl -all -s \"https://api.github.com/users/%s/repos\" | jq -r '.html_url'"
    user)))

(defun fz-gh-list-user-repos (author)
  (interactive (list (read-string-hist "gh-list-user-repos: ")))
  (let ((repo
         ;; TODO Get list from gh-search-user-clone-repo
         (fz (pen-snc (pen-cmd "gh-list-user-repos" author))
             nil nil "gh-list-user-repos select:")))
    repo))

(defun urlencode (url)
  (pen-sn "pen-urlencode | chomp" url))

(defun urldecode (url)
  (pen-sn "pen-urldecode | chomp" url))

;; TODO Add sps to pen.el

(defun wget (url &optional dir)
  (interactive (list (read-string-hist "url: ")))
  (setq dir (umn (or dir "$HOME/downloads/")))
  (cond
   ((string-match-p "^http.*/openreview.net/pdf" url)
    (progn
      (setq fn (concat (slugify url) ".pdf"))
      (pen-nw (concat "CWD=" (pen-q dir) " zrepl -cm -E " (pen-q (concat "wget -c " (pen-q url) " -O " (pen-q fn)))))))
   (t
    (pen-sn (cmd "download-file" url) nil nil nil tl))))

(defun pen-advice-handle-url (proc &rest args)
  (let ((url (car args)))

    (setq url (pen-redirect url))

    (cond ((string-match-p "google.com/url\\?q=" url)
           (setq url (urldecode (pen-sed "/.*google.com\\/url?q=/{s/^.*google.com\\/url?q=\\([^&]*\\)&.*/\\1/}" url)))))

    (cond
     ((pen-snq (pen-cmd "pen-handle-url" url))
      t)
     ((string-match-p "https?://github.com/.*/issues" url)
      (let ((res (apply proc args))) res))
     ((string-match "^https?://asciinema.org/a/[a-zA-Z0-9]+/?$" url)
      (pen-tm-asciinema-play url))
     ((string-match-p "https?://gist.github.com/" url)
      (pen-sps (concat "o " (pen-q url))))
     ((and eww-ff-dom-matchers
       (-reduce (lambda (a b) (or a b))
                (mapcar (lambda (e) (string-match-p e url))
                        (or (-filter-not-empty-string eww-ff-dom-matchers)
                            '(nil)))))
      (pen-snc (pen-cmd "sps" "ff" url)))
     ((string-match-p "https?://raw.githubusercontent.com/" url)
      (pen-sps (concat "o " (pen-q url))))
     ((string-match-p "https?://arxiv.org/\\(abs\\|pdf\\)/" url)
      (pen-sps (concat "o " (pen-q url))))
     ((string-match-p "https?://www.youtube.com/" url)
      (pen-sps (concat "ff " (pen-q url))))
     ((string-match-p "https?://.*/.*\\.\\(lhs\\)" url)
      (dump-url-file-and-edit url))
     ((or (string-match-p "stackoverflow.com/[aq]" url)
          (string-match-p "serverfault.com/[aq]" url)
          (string-match-p "superuser.com/[aq]" url)
          (string-match-p ".stackexchange.com/[aq]" url))
      (sx-from-url url))
     ((or (string-match-p "search\\.google\\.com/search-console" url)
          (string-match-p "mullikine\\.matomo\\.cloud" url))
      (pen-chrome url))
     ((or (string-match-p "asciinema\\.org/a/" url))
      (nw (concat "o " (pen-q url))))
     ((or (string-match-p "www\\.youtube\\.com/watch\\?v=" url)
          (string-match-p "https?://youtu\\.be" url))
      (pen-sps (concat "ff " (pen-q url))))
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
     ((and
       eww-racket-doc-only-www
       (string-match-p "http://racket/" (urldecode url)))
      (setcar args (pen-cl-sn "fix-racket-doc-url -w" :stdin url :chomp t))
      (let ((res (apply proc args)))
        res))
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
     (t (let ((res (apply proc (cons url (cdr args)))))
          res)))))

;; This is needed because so many functions are missing in Pen.el
(advice-add 'pen-advice-handle-url :around #'ignore-errors-around-advice)
;; (advice-remove 'pen-advice-handle-url #'ignore-errors-around-advice)

(advice-remove 'eww-browse-url #'pen-advice-handle-url)
(advice-add 'eww-browse-url :around #'pen-advice-handle-url)

;; Don't do this until I'm sure it works
(advice-remove 'eww #'pen-advice-handle-url)
(advice-add 'eww :around #'pen-advice-handle-url)

(advice-remove 'lg-eww #'pen-advice-handle-url)
(advice-add 'lg-eww :around #'pen-advice-handle-url)

(defun lg-eww-follow-link ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'eww-open-in-new-buffer)
    (call-interactively 'eww-follow-link)))

(comment
 (defun pen-add-to-glossary-file-for-buffer () (interactive))
 (defun pen-glossary-add-link () (interactive)))

(defun eww-reader (url)
  (interactive (list (let ((path (get-path)))
                       (if (re-match-p "^http" path)
                           path
                         (read-string-hist "eww reader url: ")))))
  (if (re-match-p "^http" url)
      (let ((readerurl (pen-cl-sn (concat "rdrview -url " (pen-q url)) :chomp t)))
        (message readerurl)
        (with-temp-buffer
          (eww-open-file readerurl)))))

(defun eww-browse-url (url &optional new-window)
  "Ask the EWW browser to load URL.

Interactively, if the variable `browse-url-new-window-flag' is non-nil,
loads the document in a new buffer tab on the window tab-line.  A non-nil
prefix argument reverses the effect of `browse-url-new-window-flag'.

If `tab-bar-mode' is enabled, then whenever a document would
otherwise be loaded in a new buffer, it is loaded in a new tab
in the tab-bar on an existing frame.  See more options in
`eww-browse-url-new-window-is-tab'.

Non-interactively, this uses the optional second argument NEW-WINDOW
instead of `browse-url-new-window-flag'."
  ;; (message "eww-browse-url")
  (when new-window
    (when (or (eq eww-browse-url-new-window-is-tab t)
              (and (eq eww-browse-url-new-window-is-tab 'tab-bar)
                   tab-bar-mode))
      (let ((tab-bar-new-tab-choice t))
        (tab-new)))
    (pop-to-buffer-same-window
     (generate-new-buffer
      (format "*eww-%s*" (url-host (url-generic-parse-url
                                    (eww--dwim-expand-url url))))))
    (eww-mode))

  (eww url eww-use-chrome))

(defun eww-reload-around-advice (proc &rest args)
  (if (equal current-prefix-arg (list 4))
      (let ((res (apply proc args)))
      res)
    (lg-eww (get-path))))
(advice-add 'eww-reload :around #'eww-reload-around-advice)

(defun eww-summarize-this-page (url)
  (interactive (let* ((p (get-path)))
                 (list p)))

  (if (sor url)
      (mtv (pen-snc (pen-cmd "pen-summarize-page" url)))))

(defun google-this-url-in-this-domain (url domain)
  (interactive (let* ((p (get-path))
                      (d (url-domain (url-generic-parse-url p))))
                 (list p d)))

  (let ((query (concat "site:" (pen-q domain) " " "intext:" (pen-q url))))

    ;; Only run if available
    (ignore-errors
      (eegr query))))

;; Just don't ever redirect
;; This makes google much slower, when
(defun eww-tag-meta-around-advice (proc &rest args)
  (let* ((eww-redirect-level 5)
         (res (apply proc args)))
    res))
(advice-add 'eww-tag-meta :around #'eww-tag-meta-around-advice)

(defun pen-chrome (url &optional smth)
  (interactive (list (read-string-hist "chromium url: ")))
  (pen-cl-sn (pen-cmd "chromium" (pen-q url)) :detach t))

(defun eww-open-in-chrome (url)
  (interactive (list (if (major-mode-p 'eww-mode)
                         (get-path)
                       (read-string-hist "chrome: "))))
  (pen-chrome url))

(advice-add 'font-lock-fontify-keywords-region :around #'ignore-errors-around-advice)

(defun shr-urlify (start url &optional title)
  (if (lg-url-cache-exists url)
      (shr-add-font start (point) 'eww-cached)
    (shr-add-font start (point) 'shr-link))

  (add-text-properties
   start (point)
   (list 'shr-url url
         'button t
         'category 'shr
	       'help-echo (let ((parsed (url-generic-parse-url
                                   (or (ignore-errors
				                                 (decode-coding-string
				                                  (url-unhex-string url)
				                                  'utf-8 t))
				                               url)))
                          iri)
                      (when (url-host parsed)
                        (setf (url-host parsed)
                              (puny-encode-domain (url-host parsed))))
                      (setq iri (url-recreate-url parsed))
		                  (if title
                          (format "%s (%s)" iri title)
                        iri))
	       'follow-link t
         ;; Make separate regions not `eq' so that they'll get
         ;; separate mouse highlights.
	       'mouse-face (list 'highlight)))
  (while (and start
              (< start (point)))
    (let ((next (next-single-property-change start 'keymap nil (point))))
      (if (get-text-property start 'keymap)
          (setq start next)
        (put-text-property start (or next (point)) 'keymap shr-map)))))

(defun eww-add-domain-to-chrome-dom-matches (url)
  (interactive (list (url-domain (url-generic-parse-url (get-path)))))
  (write-to-file
   (pen-snc
    "uniqnosort"
    (concat
     (pen-sn (concat
              (pen-cmd
               "cat"
               (f-join penconfdir "conf" "chrome-dom-url-patterns.txt"))
              " | awk 1"))
     (concat "http.*" url)))
   (f-join penconfdir "conf" "chrome-dom-url-patterns.txt"))
  (reload-eww-use-chrome-dom-matchers)
  (call-interactively 'eww-reload-cache-for-page))

(defun eww-mirror-url (url)
  (interactive (let ((u (cond
                         ((major-mode-p 'eww-mode) (get-path))
                         (t (read-string-hist "mirror url: ")))))
                 (list u)))

  (pen-sps (pen-cmd "my-mirror-site" url)))

(defun eww-select-wayback-for-url (url)
  (interactive (let ((u (cond
                         ((major-mode-p 'eww-mode) (get-path))
                         (t (read-string-hist "wayback url: ")))))
                 (list u)))

  (let ((page (pen-snc "pen-sed -n 's=^https*://\\([^/]*\\)\\(.*\\)=\\2=p'" url))
        (sel (fz (pen-snc (concat (pen-cmd "wayback" url) " | tac"))
                 nil nil "wayback result: ")))

    (if (sor sel)
        (eww (concat sel page)))))

;; Merely overriding this function didn't even override it
;; lexical scope problem, probably
(defun pen-eww-reload ()
  ""
  (interactive)
  (if (major-mode-p 'eww-mode)
      (let ((url (get-path)))
        (kill-buffer)
        (lg-eww url))))

(defun eww-open-medium ()
  (interactive)
  (dolist (url (pen-str2list (scrape "^https://medium\\..*" (lg-list-history))))
    (lg-eww url)
    (sleep 2)))

(defun eww-open-huggingface ()
  (interactive)
  (dolist (url (pen-str2list (scrape "^https://huggingface\\.co.*" (lg-list-history))))
    (lg-eww url)
    (sleep 2)))

(defun eww-open-spacy ()
  (interactive)
  (dolist (url (pen-str2list (scrape "^https://spacy\\.io.*" (lg-list-history))))
    (lg-eww url)
    (sleep 2)))

(defun eww-open-eleutherai ()
  (interactive)
  (dolist (url (pen-str2list (scrape "^https://eleuther\\.ai.*" (lg-list-history))))
    (lg-eww url)
    (sleep 2)))

(defun eww-open-amazon ()
  (interactive)
  (dolist (url (pen-str2list (scrape "^https://aws.amazon\\.com.*" (lg-list-history))))
    (lg-eww url)
    (sleep 2)))

(defun buffer-links ()
  (urls-in-region-or-buffer (pen-textprops-in-region-or-buffer)))
(defalias 'eww-buffer-links 'buffer-links)

(defun eww-crawl (url)
  (interactive (list nil))

  (cond
   (url (lg-eww url))))

;; Mirrors pages from a site
(defun eww-open-all-links (&optional filter recursively)
  (interactive (list (read-string-hist "filter: " (concat "//" (unregexify
                                                                (url-domain url-current-lastloc
                                                                            ;; (get-path nil t)
                                                                            ))))))
  (cl-loop for url in (-filter
                       (eval `(lambda (s) (string-match ,filter s)))
                       (pen-str2list (buffer-links)))
           do (progn
                (lg-eww url)
                (sleep 2))))

(defun eww-open-all-links-recursively (&optional filter)
  (interactive (list (read-string-hist "filter: " (concat "//" (unregexify (url-domain url-current-lastloc))))))
  (eww-open-all-links filter t))

(defun file-from-data (data)
  (let* ((hash (sha1 data))
         (fp (f-join "/tmp" hash)))
    (shut-up (write-to-file data fp))
    fp))

(defun display-graphic-p-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (and (not pen-eww-text-only)
         res)))
(advice-add 'display-graphic-p :around #'display-graphic-p-around-advice)

(defun shr-put-image (spec alt &optional flags)
  "Insert image SPEC with a string ALT.  Return image.
SPEC is either an image data blob, or a list where the first
element is the data blob and the second element is the content-type."

  ;; This runs at initial load and also after, when images later load
  (if (display-graphic-p)
      (let* ((size (cdr (assq 'size flags)))
             (data (if (consp spec)
                       (car spec)
                     spec))
             (content-type (and (consp spec) (cadr spec)))
             (start (point))
             (image (cond ((eq size 'original)
                           (create-image
                            data
                            nil
                            t
                            :ascent 100
                            :format content-type))
                          ((eq content-type
                               'image/svg+xml)
                           (create-image
                            data
                            'svg
                            t
                            :ascent 100))
                          ((eq size 'full)
                           (ignore-errors
                             (shr-rescale-image
                              data
                              content-type
                              (plist-get flags :width)
                              (plist-get flags :height))))
                          (t
                           (ignore-errors
                             (shr-rescale-image
                              data
                              content-type
                              (plist-get flags :width)
                              (plist-get flags :height)))))))
        (when image
          ;; When inserting big-ish pictures, put them at the
          ;; beginning of the line.
          (when (and (> (current-column) 0)
                     (> (car (image-size image t))
                        400))
            (insert "\n"))
          (if (eq size 'original)
              (insert-sliced-image
               image
               (or (lg-generate-alttext
                    (file-from-data data))
                   alt
                   "*")
               nil
               20
               1)
            (insert-image
             image
             (or (lg-generate-alttext
                  (file-from-data data))
                 alt
                 "*")))
          (put-text-property
           start
           (point)
           'image-size
           size)
          (when (and shr-image-animate
                     (cond ((fboundp 'image-multi-frame-p)
                            ;; Only animate multi-frame things that specify a
                            ;; delay; eg animated gifs as oppopen-sed to
                            ;; multi-page tiffs.  FIXME?
                            (cdr (image-multi-frame-p image)))
                           ((fboundp 'image-animated-p)
                            (image-animated-p image))))
            (image-animate image nil 60)))
        image)

    ;; This  gets called most often
    ;; And is also where it gets called after load
    (let ((data (if (consp spec)
                    (car spec)
                  spec)))
      (insert
       (or
        (lg-generate-alttext
         (file-from-data data))
        alt
        ;; ""
        )))))

;; Added "SVG Image"
(defun shr-tag-img (dom &optional url)
  ;; This runs on initial load
  (when (or url
            (and dom
                 (or (> (length (dom-attr dom 'src)) 0)
                     (> (length (dom-attr dom 'srcset)) 0))))
    (when (> (current-column) 0)
      (insert "\n"))
    (let ((alt (dom-attr dom 'alt))
          (width (shr-string-number (dom-attr dom 'width)))
          (height (shr-string-number (dom-attr dom 'height)))
          (url (shr-expand-url (or url (shr--preferred-image dom)))))
      (let ((start (point-marker)))
        (when (zerop (length alt))
          (setq alt "*"))
        (cond
         ((null url)
          ;; After further expansion, there turned out to be no valid
          ;; src in the img after all.
          )
         ((or (member (dom-attr dom 'height) '("0" "1"))
              (member (dom-attr dom 'width) '("0" "1")))
          ;; Ignore zero-sized or single-pixel images.
          )
         ((and (not shr-inhibit-images)
               (string-match "\\`data:" url))
          (let ((image (shr-image-from-data (substring url (match-end 0)))))
            (if image
                (funcall shr-put-image-function image (sor alt)
                         (list :width width :height height))
              (insert alt))))
         ((and (not shr-inhibit-images)
               (string-match "\\`cid:" url))
          (let ((url (substring url (match-end 0)))
                image)
            (if (or (not shr-content-function)
                    (not (setq image (funcall shr-content-function url))))
                (insert alt)
              (funcall shr-put-image-function image (sor alt)
                       (list :width width :height height)))))
         ((or shr-inhibit-images
              (and shr-blocked-images
                   (string-match shr-blocked-images url)))
          (setq shr-start (point))
          (shr-insert alt))
         ((and (not shr-ignore-cache)
               (url-is-cached (shr-encode-url url)))
          (funcall shr-put-image-function (shr-get-image-data url) (sor alt)
                   (list :width width :height height)))
         (t
          (when (and shr-ignore-cache
                     (url-is-cached (shr-encode-url url)))
            (let ((file (url-cache-create-filename (shr-encode-url url))))
              (when (file-exists-p file)
                (delete-file file))))
          (let ((fullalttext
                 ;; (lg-generate-alttext (file-from-data (ecurl url)))

                 ;; This happens at load for the blog logo
                 (lg-generate-alttext url (sor alt))))
            (insert fullalttext)
            (never
             (insert-image
              ;; A placeholder image gets reloaded
              ;; How to keep the alttext, if it's a placeholder image?
              (shr-make-placeholder-image dom)
              (or fullalttext ""))))
          (insert " ")
          ;; This reloaded the image, but there is no need
          ;; Because alttext was used
          ;; Though, perhaps I should use something immediate first 
          (comment
           (url-queue-retrieve
            (shr-encode-url url) #'shr-image-fetched
            (list (current-buffer) start (set-marker (make-marker) (point))
                  (list :width width :height height))
            t
            (not (shr--use-cookies-p url shr-base))))))
        (when (zerop shr-table-depth) ;; We are not in a table.
          (put-text-property start (point) 'keymap shr-image-map)
          (put-text-property start (point) 'shr-alt alt)
          (put-text-property start (point) 'image-url url)
          (put-text-property start (point) 'image-displayer
                             (shr-image-displayer shr-content-function))
          (put-text-property start (point) 'help-echo
                             (shr-fill-text
                              (or (dom-attr dom 'title) alt))))))))

(defun shr-copy-url (url)
  "Copy the URL under point to the kill ring.
With a prefix argument, or if there is no link under point, but
there is an image under point then copy the URL of the image
under point instead."
  (interactive (list (shr-url-at-point current-prefix-arg)))
  (if (not url)
      (message "No URL under point")
    (setq url (url-encode-url url))
    (kill-new url)
    (xc url)
    (message "Copied %s" url)))

(defun shr-browse-image (&optional arg)
  "Browse the image under point.
If COPY-URL (the prefix if called interactively) is non-nil, copy
the URL of the image to the kill buffer instead."
  (interactive "P")
  (let ((url (get-text-property (point) 'image-url)))
    (cond
     ((not url)
      (message "No image under point"))
     ((>= (prefix-numeric-value current-prefix-arg) 8)
      (progn
        (xc url)
        (message "Copied %s" url))
      (never
       (with-temp-buffer
         (insert url)
         (copy-region-as-kill (point-min) (point-max))
         (message "Copied %s" url))))
     ((>= (prefix-numeric-value current-prefix-arg) 4)
      (message "Browsing %s..." url)
      (lg-eww-browse-url url))
     (t
      (message "Browsing %s..." url)
      (pen-snc (pen-cmd "sps" "pen-win" "ie" url))))))

(defun eww-next-image ()
  (interactive)
  (goto-char (next-single-char-property-change (point) 'image-url))
  (if (not (get-text-property (point) 'image-url))
      (goto-char (next-single-char-property-change (point) 'image-url))))

(defun eww-previous-image ()
  (interactive)
  (goto-char (previous-single-char-property-change (point) 'image-url))
  (if (not (get-text-property (point) 'image-url))
      (goto-char (previous-single-char-property-change (point) 'image-url))))

;; This is not needed?
;; (defun eww-setup-buffer ()
;;   (pen-set-faces)
;;   (when (or (plist-get eww-data :url)
;;             (plist-get eww-data :dom))
;;     (eww-save-history))
;;   (let ((inhibit-read-only t))
;;     (remove-overlays)
;;     (erase-buffer))
;;   (setq bidi-paragraph-direction nil)
;;   (unless (eq major-mode 'eww-mode)
;;     (eww-mode)))

(defun url-is-404 (url)
  "URL is 404"
  (pen-sn-true (concat "pen-curl-firefox -s -I " (pen-q url) " | grep -q \"404 Not Found\"")))

(defun test-404 ()
  (if (lg-url-is-404 "https:/www.google.com/search?ie=utf-8&oe=utf-8&q=containers-0.4.0.0")
      "is 404"
    "is not 404"))

(defun eww-open-url-maybe-file (url &optional use-chrome)
  (interactive (list (read-string "url:")))

  (if (f-exists-p (umn url))
      (eww-open-file (umn url))
    (eww url use-chrome)))

(provide 'pen-eww)
