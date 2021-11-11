;; 🔍 Looking-glass
;; “Where should I go?" -Alice. "That depends on where you want to end up." - The Cheshire Cat.”

;; Looking-glass web-browser (based on eww)

;; If a url is 404, then use the imaginary web-browser.
;; If a url is real then go to that.

;; When running an imaginary web search, optionally say which ones are real

(require 'eww)

(require 'eww)
(require 'cl-lib)
(require 'eww-lnum)
(require 'pen-asciinema)

(defun pen-uniqify-buffer (b)
  "Give the buffer a unique name"
  (with-current-buffer b
    (ignore-errors (let* ((hash (short-hash (str (time-to-seconds))))
                          (new-buffer-name (pcre-replace-string "(\\*?)$" (concat "-" hash "\\1") (current-buffer-name))))
                     (rename-buffer new-buffer-name)))
    b))

;; e:$HOME/local/emacs28/share/emacs/28.0.50/lisp/net/eww.el.gz
;; e:$HOME/local/emacs28/share/emacs/28.0.50/lisp/net/shr.el.gz

(defset shr-map
  (let ((map (make-sparse-keymap)))
    (define-key map "a" 'shr-show-alt-text)
    (define-key map "i" 'shr-browse-image)
    (define-key map "z" 'shr-zoom-image)
    (define-key map [?\t] 'shr-next-link)
    (define-key map [?\M-\t] 'shr-previous-link)
    (define-key map [follow-link] 'mouse-face)
    ;; (define-key map [mouse-2] 'shr-browse-url)
    (define-key map [mouse-2] 'pen-eww-follow-link)
    (define-key map [C-down-mouse-1] 'shr-mouse-browse-url-new-window)
    (define-key map "I" 'shr-insert-image)
    (define-key map "w" 'shr-maybe-probe-and-copy-url)
    (define-key map "u" 'shr-maybe-probe-and-copy-url)
    ;; (define-key map "v" 'shr-browse-url)
    (define-key map "v" 'pen-eww-follow-link)
    (define-key map "O" 'shr-save-contents)
    ;; (define-key map "\r" 'shr-browse-url)
    (define-key map "\r" 'pen-eww-follow-link)
    map))

;; Frustratingly, I had to add the handler for eww-mode here. The above overriding of mouse action in shr-map didn't work
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
      (pen-eww-follow-link))
     (external
      (funcall browse-url-secondary-browser-function url)
      (shr--blink-link))
     (t
      (browse-url url (xor new-window browse-url-new-window-flag))))))

;; original eww -- has the buffer argument. use for when opening html files
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
     (list (read-string (format-prompt "Enter URL or keywords"
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

(setq max-specpdl-size 10000)
;; This isn't a great solution
;; https://stackoverflow.com/q/11807128
(setq max-lisp-eval-depth 10000)

;; Biesect this to find what is breaking https://www.zdnet.com/article/canonical-introduces-high-availability-micro-kubernetes/
;; After bisecting, I didn't find any problems, apart from it being a little slow.

;; It's interesting that eww non-deterministically works
;; Perhaps I should completely bypass the emacs DOM and use something like curl

(defvar eww-racket-doc-only-www nil)

(defset eww-after-render-hook '())

;; https appears to not work. But it works in vanilla emacs

(defun short-hash (input)
  "Probably a CRC hash of the input."
  (chomp (bp short-hash input)))

(defun eww-bufname-for-url (url)
  (concat "*eww-" (slugify url) "*"))

;; This should really be advice.
;; A method such as this is probably never necessary
;; If adding advice doesn't work, I should try to add advice to the function that names the buffer
(defun pen-eww (url &optional use-chrome)
  "Same as 'eww' except it renames the buffer after loading."
  (interactive (list (read-string "url:")))

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

(defun pen-eww-js (url)
  "Same as 'eww' except it renames the buffer after loading."
  (interactive (list (read-string "url:")))
  (pen-eww url t))

(defun pen-eww-nojs (url)
  "Same as 'eww' except it renames the buffer after loading."
  (interactive (list (read-string "url:")))
  (pen-eww url -1))

;; advice exists now, so this is deprecated
;; vim +/":after '(defun eww-browse-url-after (&rest args)" "$MYGIT/config/emacs/config/my-advice.el"
(defun pen-eww-browse-url (&rest body)
  "Same as 'eww-browse-url' except it renames the buffer after loading."
  ;; I also want to recenter
  (interactive (list (read-string "url:")))

  (if (not body)
      (setq body '("http://google.com")))

  (eval `(eww-browse-url ,@body))
  ;; This isn't doing its job
  ;; When the page doesn't load, g still doesn't work
  (ignore-errors (rename-buffer (concat "*eww-" (short-hash (concat (car body) (str (time-to-seconds))))) "*") t)
  (recenter-top))

(defun pen-eww-browse-url-chrome (&rest body)
  "Same as 'eww-browse-url' except it renames the buffer after loading."
  ;; I also want to recenter
  (interactive (list (read-string "url:")))

  (setq eww-use-chrome t)

  (if (not body)
      (setq body '("http://google.com")))

  (eval `(eww-browse-url ,@body))
  (ignore-errors (rename-buffer (concat "*eww-" (short-hash (concat (car body) (str (time-to-seconds))))) "*") t)
  (recenter-top))

;; (define-key eww-link-keymap (kbd "C-m") #'eww-follow-link)


(defun shr-copy-current-url ()
  (interactive)
  (shr-copy-url (plist-get eww-data :url)))

(define-key eww-link-keymap (kbd "W") #'shr-copy-current-url)

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
;; file:////home/shane/.docsets/Haskell.docset/Contents/Resources/Documents/file/Library/Frameworks/GHC.framework/Versions/8.4.3-x86_64/usr/share/doc/ghc-8.4.3/html/libraries/bytestring-0.10.8.2/Data-ByteString-Lazy-Char8.html#//apple_ref/func/putStrLn
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

(define-key image-map (kbd "r") nil)

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

;; entrypoint
(setq shr-external-rendering-functions '((pre . eww-tag-pre)))

;; Do not let websites set the background
(setq shr-use-colors nil)

(defadvice shr-color-check (before unfuck compile activate)
  "Don't let stupid shr change background colors."
  (setq bg (face-background 'default)))


;; This much works
;; (url-target (url-generic-parse-url (get-path)))
;; For cached pages, shr-target-id does not exist
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

(define-key eww-mode-map (kbd ",") (lm (call-interactively 'eww-lnum-universal)))
(define-key eww-mode-map (kbd ".") (lm (call-interactively 'eww-lnum-follow)))

(defun insert-invisible-text (text)
  (let ((a text))
    (put-text-property 0 (length text) 'invisible t a)
    (insert a)))

(defun shr-descend (dom)
  (let ((function
         (intern (concat "shr-tag-" (symbol-name (dom-tag dom))) obarray))
        ;; Allow other packages to override (or provide) rendering
        ;; of elements.
        (external (cdr (assq (dom-tag dom) shr-external-rendering-functions)))
        (style (dom-attr dom 'style))
        (shr-stylesheet shr-stylesheet)
        (shr-depth (1+ shr-depth))
        (start (point)))
    ;; (message (concat "start: " (str start)))
    ;; shr uses many frames per nested node.
    (if (> shr-depth (/ max-specpdl-size 15))
        (setq shr-warning "Too deeply nested to render properly; consider increasing `max-specpdl-size'")
      (when style
        (if (string-match "color\\|display\\|border-collapse" style)
            (setq shr-stylesheet (nconc (shr-parse-style style)
                                        shr-stylesheet))
          (setq style nil)))
      ;; If we have a display:none, then just ignore this part of the DOM.
      (unless (equal (cdr (assq 'display shr-stylesheet)) "none")
        ;; We don't use shr-indirect-call here, since shr-descend is
        ;; the central bit of shr.el, and should be as fast as
        ;; possible.  Having one more level of indirection with its
        ;; negative effect on performance is deemed unjustified in
        ;; this case.
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
                 (message (concat "shr-target-id: " shr-target-id))
                 (message (concat "id: " mid))
                 (message (concat "name: " mname))
                 ))))
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

;; This solves a urldecode problem, though it is from emacs 26. I may need to upgrade this
(defun tvipe-dom ()
  (interactive)
  (tvipe (eww-dom-to-xml)))

;; Added use-chrome
(defun eww-render (status url &optional point buffer encode use-chrome)
  ;; (message "eww-render")

  ;; (call-interactively 'tm-edit-v-in-nw)
  (if (or (not (my-url-cache-exists url))
          my-url-cache-update)
      (my-url-cache url (buffer-string)))

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
      ;; Make buffer listings more informative.
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
            ;; (call-interactively 'tm-edit-v-in-nw)
            ;; (qtv (pps eww-data))
	          (eww-display-html charset url nil point buffer encode use-chrome))
	         ((equal (car content-type) "application/pdf")
	          (eww-display-pdf))
	         ((string-match-p "\\`image/" (car content-type))
	          (eww-display-image buffer))
	         (t
	          (eww-display-raw buffer (or encode charset 'utf-8))
            ))
	        (with-current-buffer buffer
	          (plist-put eww-data :url url)
	          (eww-update-header-line-format)
	          (setq eww-history-position 0)
	          (and last-coding-system-used
		             (set-buffer-file-coding-system last-coding-system-used))
	          (run-hooks 'eww-after-render-hook)))
      ;; (pen-etv (str data-buffer))
      ;; (pen-etv (buffer-name))
      (kill-buffer data-buffer))))


(mu (defset my-url-cache-dir "$NOTES/programs/my-url-cache"))

;; (my-url-cache-slug-fp "http://localhost/")
(defun my-url-cache-slug-fp (url)
  (concat my-url-cache-dir "/" (slugify (s-replace-regexp "#.*" "" url)) ".txt")
  ;; (concat my-url-cache-dir "/" (slugify url) ".txt")
  )

(defset my-url-cache-enabled t)
(defset my-url-cache-update nil)

;; (my-url-cache-exists "https://www.unisonweb.org/docs/")
(defun my-url-cache-exists (url)
  (setq url (my-redirect url))
  (and my-url-cache-enabled
       (or (f-exists-p (my-url-cache-slug-fp url))
           (f-exists-p (my-url-cache-slug-fp (google-cachify url))))))

(defun my-url-cache (url &optional contents)
  (setq url (my-redirect url))
  (if contents
      (write-to-file contents (my-url-cache-slug-fp url))
    (cat (my-url-cache-slug-fp url))))

(defun eww-reload-cache-for-page (url)
  (interactive (list (get-path)))
  (if (major-mode-p 'eww-mode)
      (progn
        (my-url-cache-delete url)
        (call-interactively 'my-eww-reload))))

(defun my-url-cache-delete (url)
  (interactive (list (get-path)))
  (if (major-mode-p 'eww-mode)
      (f-delete (my-url-cache-slug-fp url) t)))

(defun eww-open-browsh (path)
  (interactive (list (get-path)))
  (browsh path))

(defun my-redirect (url)
  (pen-snc "my-redirect" url))

(defun eww (url &optional use-chrome)
  "Fetch URL and render the page.
If the input doesn't look like an URL or a domain name, the
word(s) will be searched for via `eww-search-prefix'."
  (interactive
   (let* ((uris (eww-suggested-uris))
          (prompt (concat "Enter URL or keywords"
                          (if uris (format " (default %s)" (car uris)) "")
                          ": ")))
     (list (read-string prompt nil nil uris))))
  (setq url (bp urldecode | s chomp url))
  (setq url (my-redirect url))

  (hs "eww-display-html" url)

  (if (re-match-p "^/" url)
      (setq url (concat "file://" url))
    (setq url (eww--dwim-expand-url url)))

  ;; *eww-racket-doc*
  (if (and (string-match "^\\*.*\\*$" (buffer-name))
           (not (string-match "^\\*eww\\*$" (buffer-name))))
      (pop-to-buffer-same-window
       (if (eq major-mode 'eww-mode)
           (current-buffer)
         (get-buffer-create "*eww*")))
    (pen-uniqify-buffer (pop-to-buffer-same-window
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
    ;; This asynchronously fetches and renders the html in the buffer
    ;; (url-retrieve "https://moultano.wordpress.com/2013/08/09/logs-tails-long-tails/" 'eww-render (list "https://moultano.wordpress.com/2013/08/09/logs-tails-long-tails/" nil (current-buffer)))
    ;; (insert (cl-sn (concat "odn curl -s " (pen-q url)) :chomp t))
    ;; (eww-render )

    (if (and (my-url-cache-exists url)
             (not my-url-cache-update))
        ;; I need to clean the buffer first
        (let ((b (current-buffer)))
          ;; (message url)
          (with-temp-buffer
            (insert (my-url-cache url))
            (goto-char (point-min))
            ;; nil for status is OK
            ;; (call-interactively 'tm-edit-v-in-nw)
            ;; (sleep 1)
            ;; (pen-etv (buffer-string))
            (eww-render nil url (point) b))
          (with-current-buffer b
            (setq header-line-format (propertize (str header-line-format) 'face 'org-bold))))

      ;; eww-render just takes a status and
      (url-retrieve url 'eww-render
                    (list url nil (current-buffer) nil use-chrome)
                    ;; (list url nil (current-buffer))
                    )))
  (never
   (url-retrieve url (lambda (a b c d e f)
                       (call-interactively 'tm-edit-v-in-nw))
                 (list url nil (current-buffer) nil use-chrome)
                 ;; (list url nil (current-buffer))
                 ))
  (current-buffer))

;; nadvice - proc is the original function, passed in. do not modify
;; (defun eww-around-advice (proc &rest args)
;;   (ignore-errors
;;     (let ((res (apply proc args)))
;;       (deselect)
;;       res)))
;; (advice-add 'eww :around #'eww-around-advice)
;; (advice-remove 'eww #'eww-around-advice)

(defun dom-to-str () (
                      (format "%S" (plist-get eww-data :dom))))

;; ;; (sh-notty "exit 1")
;; (sh-notty "false")
;; (sh-notty "true")
;; (message (str b_exit_code))

;; (sh-notty-if "true" (message "yo") nil)
;; (sh-notty-if "false" (message "yo") (message "not yo"))


;; (defmacro url-is-404 (url)
;;   "URL is 404"
;;   `(sh-notty-true (concat "pen-curl-firefox -s -I " (pen-q ,url) " | grep -q \"404 Not Found\"")))

(defun google-cachify (url)
  (concat "http://webcache.googleusercontent.com/search?q=cache:" (google-uncachify url)))

(defun url-cache-is-404-curl (url)
  "URL cache is 404"
  (url-is-404 (google-cachify url)))

(defun url-cache-is-404 (url)
  "URL cache is 404"
  (not (url-found-p (google-cachify url))))

(memoize-restore 'url-is-404)
(memoize 'url-is-404)
(memoize-restore 'url-cache-is-404)
(memoize 'url-cache-is-404)

;; (url-cache-is-404 "https://towardsdatascience.com/understanding-bigbird-is-it-another-")
;; (url-cache-is-404 "https://towardsdatascience.com/textrank-for-keyword-extraction-by-python-c0bae21bcec0?gi=4f2950362674")


(defun ecurl (url)
  (with-current-buffer (url-retrieve-synchronously url t t 5)
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point) (point-min))
    (kill-line)
    (let ((result (buffer2string (current-buffer))))
      (kill-buffer)
      result)))

(defun load-tetris-update ()
  (with-current-buffer (new-buffer-from-string (ecurl "http://git.savannah.gnu.org/cgit/emacs.git/plain/lisp/play/gamegrid.el"))
    (eval-buffer (current-buffer))
    (kill-buffer)))

(defun url-found-p (url)
  "Return non-nil if URL is found, i.e. HTTP 200."
  (with-current-buffer (url-retrieve-synchronously url nil t 5)
    (prog1 (eq url-http-response-status 200)
      (kill-buffer))))

;; (url-is-404 "https://medium.com/riselab/functional-rl-with-keras-and-tensorflow-eager-7973f81d6345")
;; (url-cache-is-404 "https://medium.com/riselab/functional-rl-with-keras-and-tensorflow-eager-7973f81d6345")
;; (url-is-404 "https://www.cryptocompare.com/coins/nas/overview")
;; (url-is-404 "https://news.ycombinator.com/")
;; (url-cache-is-404 "https://news.ycombinator.com/")



;; This makes it so for certain urls, the google cache is loaded instead
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
;; (advice-remove 'eww--dwim-expand-url #'eww--dwim-expand-url-around-advice)

;; OK Up to here

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

(defun my-local-variable-p (sym)
  (and (variable-p sym)
       (local-variable-p sym)))
(defalias 'lvp 'my-local-variable-p)

(defun toggle-use-chrome-locally ()
  (interactive)
  (if (not (lvp 'eww-use-chrome))
      (defset-local eww-use-chrome (not eww-use-chrome))
    (setq eww-use-chrome (not eww-use-chrome)))
  (if eww-use-chrome
      (message "Using the Google Chrome DOM locally")
    (message "Using shr.el"))
  (if (major-mode-p 'eww-mode)
      (progn
        (my-url-cache-delete (get-path))
        (my-eww-reload)))
  eww-use-chrome)

(defun toggle-use-rdrview ()
  (interactive)
  (setq eww-use-rdrview (not eww-use-rdrview))
  (if eww-use-rdrview
      (message "Using rdrview for easy reading")
    (message "rdrview disabled"))
  (if (major-mode-p 'eww-mode)
      (my-eww-reload))
  eww-use-rdrview)

(defun toggle-use-tor ()
  (interactive)
  (setq eww-use-tor (not eww-use-tor))
  (if eww-use-tor
      (message "dom-dump will use tor proxy")
    (message "dom-dump is using clear internet"))
  (if (major-mode-p 'eww-mode)
      (my-eww-reload))
  eww-use-tor)

(defun toggle-update-ci ()
  (interactive)
  (setq eww-update-ci (not eww-update-ci))
  (if eww-update-ci
      (message "dom-dump will update")
    (message "dom-dump is cached"))
  (if (major-mode-p 'eww-mode)
      (my-eww-reload))
  eww-update-ci)

;; (defun toggle-no-external-handler ()
;;   (interactive)
;;   (setq eww-no-external-handler (not eww-no-external-handler))
;;   (if eww-no-external-handler
;;       (message "Disallow external handler for URL.")
;;     (message "Allow external handler for URL."))
;;   ;; (if (major-mode-p 'eww-mode)
;;   ;;     (my-eww-reload))
;;   eww-no-external-handler)


(defun fun (path)
  (interactive (list (read-string "path:")))
  "docstring"

  (if (string-empty-p path) (setq path "defaultval"))

  (let ((result (e/chomp (sh-notty (concat "ci yt-list-playlist-urls " (e/q path))))))
    (if (called-interactively-p 'any)
        ;; (message result)
        (new-buffer-from-string result)
      result)))

(defun eww-add-bookmark-manual (uri)
  (interactive (list (read-string "uri:")))
  (eww-read-bookmarks)
  (dolist (bookmark eww-bookmarks)
    (when (equal (plist-get eww-data :url) (plist-get bookmark :url))
      (user-error "Already bookmarked")))
  (let ((title (replace-regexp-in-string "[\n\t\r]" " "
                                         (e/chomp (sh-notty (concat "ci web title " (e/q uri)))))))
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

(defvar-local eww-followed-link nil)

(defun eww-follow-link (&optional external mouse-event)
  "Browse the URL under point.
If EXTERNAL is single prefix, browse the URL using `shr-external-browser'.
If EXTERNAL is double prefix, browse in new buffer."
  (interactive (list current-prefix-arg last-nonmenu-event))
  (mouse-set-point mouse-event)

  (let* ((url (get-text-property (point) 'shr-url))
         (bufname (eww-bufname-for-url url)))
    ;; (pen-etv (list2str
    ;;      (list (url-generic-parse-url url)
    ;;            ;; (plist-get eww-data :url)
    ;;            (get-path))))
    (setq eww-followed-link url)
    (cond
     ((not url)
      (message "No link under point"))
     ((string-match "^mailto:" url)
      (browse-url-mail url))
     ((string-match "^https?://asciinema.org/a/[a-zA-Z0-9]+$" url)
      (pen-tm-asciinema-play url))
     ((and (consp external) (<= (car external) 4))
      (funcall shr-external-browser url))
     ;; This is a #target url in the same page as the current one.
     ((and (url-target (url-generic-parse-url url))
           (eww-same-page-p url ;; (plist-get eww-data :url)
                            (get-path)))

      ;; (let ((fragment (url-target (url-generic-parse-url url)))))
      (goto-fragment url)
      (never (let ((dom (plist-get eww-data :dom)))
               (eww-save-history)
               (eww-display-html 'utf-8 url dom nil (current-buffer)))))
     (t
      ;; (eww-browse-url url external)
      (pen-eww url)))))

(define-key eww-bookmark-mode-map (kbd "b") 'eww-add-bookmark-manual)
(define-key eww-bookmark-mode-map (kbd "k") 'eww-bookmark-kill-ask)
(define-key eww-bookmark-mode-map (kbd "C-k") 'eww-bookmark-kill-ask)
(define-key eww-bookmark-mode-map (kbd "n") 'next-defun)
(define-key eww-bookmark-mode-map (kbd "p") 'previous-defun)
(define-key eww-mode-map (kbd "w") 'pen-yank-path)
(define-key eww-mode-map (kbd "Y") 'new-buffer-from-selection-detect-language)
(define-key eww-mode-map (kbd "k") 'toggle-cached-version)

;; (define-key eww-mode-map (kbd "m") 'toggle-use-chrome)
;; (define-key eww-mode-map (kbd "e") 'toggle-no-external-handler)
;; (define-key eww-mode-map (kbd "i") 'toggle-update-ci)
;; (define-key eww-mode-map (kbd "T") 'toggle-use-tor)
;; (define-key eww-mode-map (kbd "P") 'toggle-use-rdrview)

;; (define-key eww-mode-map (kbd "c") nil)
;; (define-key eww-mode-map (kbd "m") nil)
;; (define-key eww-mode-map (kbd "e") nil)
;; (define-key eww-mode-map (kbd "i") nil)
;; (define-key eww-mode-map (kbd "T") nil)
;; (define-key eww-mode-map (kbd "P") nil)

;; Reader doesnt work anyway
(define-key eww-mode-map (kbd "R") 'toggle-use-rdrview)
;; (define-key eww-mode-map (kbd "I") 'tor-new-identity)
;; (define-key eww-mode-map (kbd "I") nil)

(define-key eww-mode-map (kbd "C") 'eww-reload-with-ci-cache-on)



(defun rename-eww-buffer-unique (&optional url)
  (interactive)
  (if (not url)
      (setq url (get-path)))
  (ignore-errors (rename-buffer (concat "*eww-" (short-hash (concat url (str (time-to-seconds)))) "*")) t))




(defvar eww-browse-url-after-hook '())
(defun eww-browse-url-after-advice (&rest args)
  "Give the buffer a unique name and recenter to the top"
  ;; We may know the URL before it's loaded
  ;; (rename-eww-buffer-unique (car args))
  (recenter-top)
  (run-hooks 'eww-browse-url-after-hook))
(advice-add 'eww-browse-url :after 'eww-browse-url-after-advice)



(defvar eww-follow-link-after-hook '())
(defun eww-follow-link-after-advice (&rest args)
  "Recenter to the top"
  (recenter-top)
  (run-hooks 'eww-follow-link-after-hook))
(advice-add 'eww-follow-link :after 'eww-follow-link-after-advice)



(defvar eww-reload-after-hook '())
(defun eww-reload-after-advice (&rest args)
  (run-hooks 'eww-reload-after-hook))
(advice-add 'eww-reload :after 'eww-reload-after-advice)
(advice-add 'my-eww-reload :after 'eww-reload-after-advice)
;; (add-hook 'eww-reload-after-hook (lm (rename-eww-buffer-unique)) t)
;; (remove-hook 'eww-reload-after-hook (lm (rename-eww-buffer-unique)) t)



(defvar eww-restore-history-after-hook '())
(defun eww-restore-history-after-advice (&rest args)
  (run-hooks 'eww-restore-history-after-hook))
(advice-add 'eww-restore-history :after 'eww-restore-history-after-advice)
;; (add-hook 'eww-restore-history-after-hook (lm (rename-eww-buffer-unique)) t)
;; (remove-hook 'eww-restore-history-after-hook (lm (rename-eww-buffer-unique)) t)


;; sp +/"(defun browse-url-default-browser (url &rest args)" "$HOME/local/emacs26/share/emacs/26.2/lisp/net/browse-url.el.gz"
(defun browse-url-can-use-xdg-open ()
  "Return non-nil if the \"xdg-open\" program can be used.
xdg-open is a desktop utility that calls your preferred web browser."
  ;; The exact set of situations where xdg-open works is complicated,
  ;; and it would be a pain to duplicate xdg-open's situation-specific
  ;; code here, as the code is a moving target.  So assume that
  ;; xdg-open will work if there is a graphical display; this should
  ;; be good enough for platforms Emacs is likely to be running on.
  ;; (and (or (getenv "DISPLAY") (getenv "WAYLAND_DISPLAY"))
  ;;      (executable-find "xdg-open"))
  nil)

;; browse-url-default-browser is not responsible for eww opening pdf
;; In fact, I don't think it is xdg-open at all


(defun my-eww-save-image (filename)
  "Save an image opened in an *eww* buffer to a file."
  (interactive "G")
  (let ((image (get-text-property (point) 'display)))
    (with-temp-buffer
      (setq buffer-file-name filename)
      (insert
       (plist-get (if (eq (car image) 'image) (cdr image)) :data))
      (save-buffer))))

(defun my-eww-save-image-auto ()
  "Save an image opened in an *eww* buffer to a file."
  (interactive)
  (let ((image (get-text-property (point) 'display)))
    (with-temp-buffer
      (setq buffer-file-name (org-babel-temp-file "image" ".bin"))
      (insert
       (plist-get (if (eq (car image) 'image) (cdr image)) :data))
      (save-buffer))))


(defun shr-put-image (spec alt &optional flags)
  "Insert image SPEC with a string ALT.  Return image.
SPEC is either an image data blob, or a list where the first
element is the data blob and the second element is the content-type."
  (if (display-graphic-p)
      (let* ((size (cdr (assq 'size flags)))
             (data (if (consp spec)
                       (car spec)
                     spec))
             (content-type (and (consp spec)
                                (cadr spec)))
             (start (point))
             (image (cond
                     ((eq size 'original)
                      (create-image data nil t :ascent 100
                                    :format content-type))
                     ((eq content-type 'image/svg+xml)
                      (create-image data 'svg t :ascent 100))
                     ((eq size 'full)
                      (ignore-errors
                        (shr-rescale-image data content-type
                                           (plist-get flags :width)
                                           (plist-get flags :height))))
                     (t
                      (ignore-errors
                        (shr-rescale-image data content-type
                                           (plist-get flags :width)
                                           (plist-get flags :height)))))))
        (when image
          ;; When inserting big-ish pictures, put them at the
          ;; beginning of the line.
          (when (and (> (current-column) 0)
                     (> (car (image-size image t)) 400))
            (insert "\n"))
          (if (eq size 'original)
              (insert-sliced-image image (or alt "*") nil 20 1)
            (insert-image image (or alt "*")))
          (put-text-property start (point) 'image-size size)
          (when (and shr-image-animate
                     (cond ((fboundp 'image-multi-frame-p)
                            ;; Only animate multi-frame things that specify a
                            ;; delay; eg animated gifs as opposed to
                            ;; multi-page tiffs.  FIXME?
                            (cdr (image-multi-frame-p image)))
                           ((fboundp 'image-animated-p)
                            (image-animated-p image))))
            (image-animate image nil 60)))
        image)
    (insert (or alt ""))))


;; Medium articles break with chrome
;; This shouldn't be the default. It's really slow
(defvar eww-use-google-cache nil)
(defvar eww-use-chrome nil)
(defvar eww-use-rdrview nil)
(defvar eww-use-tor nil)
(defvar eww-update-ci nil)
(defvar eww-do-fontify-pre nil)
;; (defvar eww-no-external-handler nil)

;; (setq eww-no-external-handler nil)
;; nil by default
(setq eww-use-rdrview nil)
;; (setq eww-use-rdrview nil)


(setq browse-url-text-browser "elinks")





;; emacs 27 may have broken this
;; my customisations still work for other sites apart from tpb, though
;; but tpb works in elinks -js

;; This is more reliable with javascript websites, but doesn't do helm hub. it also leave artifacts. Probably due to encoding'
(defun eww-display-html (charset url &optional document point buffer encode use-chrome)
  (hs "eww-display-html" url)

  (unless (fboundp 'libxml-parse-html-region)
    (error "This function requires Emacs to be compiled with libxml2"))
  (unless (buffer-live-p buffer)
    (error "Buffer %s doesn't exist" buffer))
  ;; There should be a better way to abort loading images
  ;; asynchronously.
  (setq url-queue nil)
  ;; If document exists then the html is already parsed into a DOM
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
                   ;; The url is not in the header
                   ;; (pen-etv (buffer-string))
                   ;; Go to after the http headers
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
                ;; (sn (concat "dom-dump  " (pen-q url)))
                (let ((newhtml (shell-command-to-string (concat envs "dom-dump " (shell-quote-argument url)))))
                  (if (string-empty-p newhtml)
                      (progn
                        (setq newhtml (shell-command-to-string (concat envs "upd dom-dump " (shell-quote-argument url))))
                        (if (string-empty-p newhtml)
                            (ns "dom-dump returned empty string"))))
                  (setq htmlbuild newhtml))
              ;; (progn
              ;;   ;; This actually works, but I also want to COMPLETELY circumvent the call to url-http
              ;;   ;; (shell-command-to-string (concat envs "curl " (shell-quote-argument url)))
              ;;   ;; But i need the http header too so I don't know if I can
              ;;   "")
              ;; empty string allowed emacs to get the dom
              ;; ""
              )

            (if (and eww-use-rdrview
                     (not (string-match-p (regexp-quote "://racket/") url))
                     (not (string-match-p (regexp-quote "://godoc.org/") url))
                     (not (string-match-p (regexp-quote "://docs.racket-lang.org/") url)))
                ;; TODO Ensure that the <title> remains. eww needs this
                (setq htmlbuild (cl-sn (concat "rdrextract -u " (pen-q basepath)) :stdin htmlbuild :chomp t)))

            htmlbuild))
         (newdocument
          (or
           ;; This check isn't ideal as the eww-display-html will still redisplay the buffer
           ;; Therefore, I should override eww-follow-link to find the fragment identifier
           document ;; nil ;; document
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
                  ;; This was creating strange artifacts in rdrview
                  ;; It's still doing it. But it's dependent on the page.
                  ;; (insert (encode-coding-string html 'utf-8))
                  ;; This page needs it disabled for reader mode
                  ;; http://webcache.googleusercontent.com/search?q=cache:https://medium.com/datadriveninvestor/rake-rapid-automatic-keyword-extraction-algorithm-f4ec17b2886c
                  (if (or (not eww-use-rdrview)
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
              ;; Need to remove everything from doctype html downwards
              ;; (tvd (buffer-contents))
              ;; (tvd (buffer-substring (point) (point-max)))
              ;; (tvd (buffer-contents))
              (libxml-parse-html-region (point) (point-max))))))
         (source (and (null newdocument)
                      (buffer-substring (point) (point-max)))))
    (with-current-buffer buffer
      ;; This enables you to continue browsing using the chrome dom without setting globally
      (if use-chrome
          (defset-local eww-use-chrome use-chrome))
      (setq bidi-paragraph-direction nil)
      ;; (plist-put eww-data :source source)
      ;; (new-buffer-from-string (sn (concat "dom-dump " (pen-q "http://google.com"))))
      (plist-put eww-data :source html)
      ;; (plist-put eww-data :source (tvipe source))
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

;; nadvice - proc is the original function, passed in. do not modify
;; (defun display-html-around-advice (proc &rest args)
;;   (ignore-errors
;;     (let ((res (apply proc args)))
;;       (deselect)
;;       res)))
;; (advice-add 'display-html :around #'display-html-around-advice)
;; (advice-remove 'display-html #'display-html-around-advice)

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
    ;; (search-forward-regexp "^Showing")
    ;; (search-forward-regexp "^\*")
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
    ;; (pcre-replace-string "\\(\\*([^ ])" "\\(\\1" nil (point-min) (point-max))

    (read-only-mode -1)

    (goto-char (point-min))
    (while (re-search-forward "(\\*\\([^ ]\\)" nil t)

      (backward-char 2)
      (delete-char 1)
      ;; (replace-match "(\\1")
      ;; (replace-match "(\\1")
      ))

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

(defun tor-new-identity ()
  (interactive)
  (sn "sudo /etc/init.d/tor restart")
  (after-sec 2 (if (major-mode-p 'eww-mode)
                   (my-eww-reload))))

;; https://emacs.stackexchange.com/questions/32644/how-to-concatenate-two-lists
(defvar eww-patchup-url-alist nil)
;; (setq eww-patchup-url-alist nil)
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
;; (add-to-list 'eww-patchup-url-alist '("://library.lol/main/" . clean-up-librarylol))
(add-to-list 'eww-patchup-url-alist '("://libraries.io/search" . clean-up-libraries-io))

;; (defun eww-display-cleanup-function ()
;;   (interactive)

;;   ;; string-match is the test function. it lets you look for a key using a regex test
;;   (assoc-default (get-path) eww-patchup-url-alist #'string-match)

;;   ;; (-filter (lambda (k)
;;   ;;            )
;;   ;;          eww-patchup-url-alist)
;;   )



;; vim +/"x -cd \"\$(pwd)\" -sh \"eww \\"\$url\\"\" -e \"Finished loading page!\" -c s -s \"\$query\" -c m -i" "$HOME/scripts/xs"

(defun my-eww-show-status ()
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
    ;; ", no-external: "
    ;; (if eww-no-external-handler "on" "off")
    "]")))

;; (defun eww-minimise-text ()
;;   (interactive)
;;   (progn
;;     (toggle-read-only)
;;     (cfilter "mnm-text")
;;     (toggle-read-only)))

;; (add-hook 'eww-after-render-hook 'eww-readable)
(defun finished-loading-page ()
  "Needed so that x/expect can automate it"

  ;; Clean up some pages
  (ignore-errors
    (let ((f (assoc-default (get-path) eww-patchup-url-alist #'string-match)))
      (if f (call-function f))))
  ;; (eww-minimise-text)

  (setq-local imenu-create-index-function #'button-cloud-create-imenu-index)

  (my-flyspell-buffer)

  ;; enable this by default
  ;; (eww-readable)
  ;; (rename-eww-buffer-unique)
  (ignore-errors (recenter-top))
  (ignore-errors (goto-fragment (get-path)))
  ;; This works
  (deselect)
  (if (equal 0 (length (buffer-string)))
      (message "Failed to load page, I think")
    ;; Try again
    )
  ;; (message "generating glossary buttons")
  ;; (redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
  (run-buttonize-hooks)
  (my-eww-show-status))

(defun eww-back-url-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    ;; (redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
    (run-buttonize-hooks)
    res))
(advice-add 'eww-back-url :around #'eww-back-url-around-advice)
;; (advice-remove 'eww-back-url #'eww-back-url-around-advice)

;; (defun set-imenu-function-to-buttons (&rest args)
;;   (setq-local imenu-create-index-function #'button-cloud-create-imenu-index))

;; (advice-add 'eww-display-html :after 'set-imenu-function-to-buttons)
;; (advice-remove 'eww-display-html 'set-imenu-function-to-buttons)


(add-hook 'eww-after-render-hook #'finished-loading-page)
;; (remove-hook 'eww-after-render-hook #'finished-loading-page)

(defvar eww-display-html-after-hook '())
(defun eww-display-html-after-advice (&rest args)
  (run-hooks 'eww-display-html-after-hook))
(advice-add 'eww-display-html :after 'eww-display-html-after-advice)

;; (add-hook 'eww-display-html-after-hook #'finished-loading-page)
;; (remove-hook 'eww-display-html-after-hook #'finished-loading-page)

;; (remove-hook 'eww-after-render-hook #'finished-loading-page)

;; (defvar eww-display-html-after-hook '())
;; (defun eww-display-html-after-advice (&rest args)
;;   (run-hooks 'eww-display-html-after-hook))
;; (advice-add 'eww-display-html :after 'eww-display-html-after-advice)
;; (add-hook 'eww-display-html-after-hook #'finished-loading-page)
;; (remove-hook 'eww-display-html-after-hook #'finished-loading-page)


;; (setq eww-after-render-hook '())

;; (add-hook 'eww-after-render-hook #'glossary-add-relevant-glossaries)
;; (remove-hook 'eww-after-render-hook #'glossary-add-relevant-glossaries)
;; (add-hook 'eww-after-render-hook #'redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
;; (remove-hook 'eww-after-render-hook #'redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
;; (remove-hook 'eww-after-render-hook #'finished-loading-page)

;; (remove-hook 'eww-after-render-hook (lm (message "Finished loading page!")))




;; nadvice - proc is the original function, passed in. do not modify
;; (defun eww-display-html-around-advice (proc &rest args)
;;   (let ((f (assoc-default (get-path) eww-patchup-url-alist #'string-match)))
;;     (if f (call-function f))))
;; (advice-add 'eww-display-html :around #'eww-display-html-around-advice)
;; (advice-remove 'eww-display-html #'eww-display-html-around-advice)


(require 'ace-link)
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
    ;; Default (no prefix) -- do not use google chrome
    ;; (setq eww-use-chrome nil)
    ;; (if (or (string-match-p "/grep\\.app" url)
    ;;         (string-match-p "://clojuredocs.org/" url))
    ;;     (setq eww-use-chrome t))

    (when (= arg 4)
      ;; once
      (let ((res (apply proc args)))
        res))
    (when (= arg 16)
      ;; twice -- use google chrome
      (setq eww-use-chrome t)
      (pen-eww (car args) eww-use-chrome))
    (when (= arg 1)

      (pen-eww (car args)))))
(advice-add 'browse-url-generic :around #'browse-url-generic-around-advice)
;; (advice-remove 'browse-url-generic #'browse-url-generic-around-advice)

;; (defun browse-url-generic (url &optional _new-window)
;;   ;; new-window ignored
;;   "Ask the WWW browser defined by `browse-url-generic-program' to load URL.
;; Default to the URL around or before point.  A fresh copy of the
;; browser is started up in a new process with possible additional arguments
;; `browse-url-generic-args'.  This is appropriate for browsers which
;; don't offer a form of remote control."
;;   (interactive (browse-url-interactive-arg "URL: "))
;;   (if (not browse-url-generic-program)
;;       (error "No browser defined (`browse-url-generic-program')"))
;;   (apply 'call-process browse-url-generic-program nil
;;          0 nil
;;          (append browse-url-generic-args (list url))))


(defun eww-reload-with-ci-cache-on ()
  (interactive)
  (setq eww-update-ci t)
  (call-interactively 'my-eww-reload))

(defvar eww-use-google-cache-matchers)
(defun reload-eww-use-google-cache-matchers ()
  (setq eww-use-google-cache-matchers
        (str2list (chomp (cat "$NOTES/programs/eww/google-cache-url-patterns.txt")))))
(reload-eww-use-google-cache-matchers)

(defvar eww-use-chrome-dom-matchers)
(defun reload-eww-use-chrome-dom-matchers ()
  (setq eww-use-chrome-dom-matchers
        (str2list (chomp (cat "$NOTES/programs/eww/chrome-dom-url-patterns.txt")))))
(reload-eww-use-chrome-dom-matchers)

(defvar eww-use-reader-matchers)
(defun reload-eww-use-reader-matchers ()
  (setq eww-use-reader-matchers
        (str2list (chomp (cat "$NOTES/programs/eww/reader-url-patterns.txt")))))
(reload-eww-use-reader-matchers)

(defvar eww-ff-dom-matchers)
(defun reload-eww-ff-dom-matchers ()
  (setq eww-ff-dom-matchers
        (str2list (cat "$NOTES/programs/eww/ff-url-patterns.txt"))))
(reload-eww-ff-dom-matchers)

(defun eww-display-html-around-advice (proc &rest args)
  (reload-eww-use-google-cache-matchers)
  (reload-eww-use-chrome-dom-matchers)
  (reload-eww-use-reader-matchers)
  (let ((eww-use-google-cache (-reduce (lambda (a b) (or a b))
                                   (mapcar (lambda (e) (re-match-p e (second args)))
                                           eww-use-google-cache-matchers)))
        (match-use-chrome (-reduce (lambda (a b) (or a b))
                                   (mapcar (lambda (e) (re-match-p e (second args)))
                                           eww-use-chrome-dom-matchers)))
        (eww-use-rdrview (-reduce (lambda (a b) (or a b))
                                   (mapcar (lambda (e) (re-match-p e (second args)))
                                           eww-use-reader-matchers))))
    (cond
     (match-use-chrome
      ;; (or (string-match-p "semgrep.dev" (second args))
      ;;     (string-match-p "quora" (second args))
      ;;     (string-match-p "hub.docker.com" (second args)))
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
;; (advice-remove 'eww-display-html #'eww-display-html-around-advice)


(defun dump-url-file-and-edit (url)
  (interactive (list (read-string-hist "file url: ")))
  (e (pen-snc (pen-cmd "put-url-to-dump" url))))


(defun advice-handle-url (proc &rest args)
  ;; (pen-etv args)
  ;; args is the first arg, but the 2nd arg could be something else, and is optional
  (let ((url (car args)))
    (setq url (my-redirect url))

    (cond ((string-match-p "google.com/url\\?q=" url)
           (setq url (urldecode (pen-sed "/.*google.com\\/url?q=/{s/^.*google.com\\/url?q=\\([^&]*\\)&.*/\\1/}" url)))))
    (cond ((string-match-p "https?://github.com/.*/issues" url)
           (let ((res (apply proc args))) res))
          ((string-match-p "https?://gist.github.com/" url)
           ;; (let ((res (apply proc args))) res)
           (sps (concat "o " (pen-q url))))
          ((-reduce (lambda (a b) (or a b))
                    (mapcar (lambda (e) (string-match-p e url))
                            eww-ff-dom-matchers))
           (pen-snc (pen-cmd "sps" "ff" url))
           ;; (let ((eww-use-chrome t)
           ;;       (eww-update-ci t))
           ;;   (let ((res (apply proc args)))
           ;;     res))
           )
          ((string-match-p "https?://raw.githubusercontent.com/" url)
           ;; (let ((res (apply proc args))) res)
           (sps (concat "o " (pen-q url))))
          ((string-match-p "https?://arxiv.org/\\(abs\\|pdf\\)/" url)
           ;; (let ((res (apply proc args))) res)
           (sps (concat "o " (pen-q url))))
          ((string-match-p "https?://www.youtube.com/" url)
           ;; (let ((res (apply proc args))) res)
           (sps (concat "ff " (pen-q url))))
          ((string-match-p "https?://.*/.*\\.\\(lhs\\)" url)
           ;; (let ((res (apply proc args))) res)
           (dump-url-file-and-edit url))
          ;; (eww-no-external-handler
          ;;  (let ((res (apply proc args))) res))
          ;; https://asciinema.org/a/bkRoTCAemqhrGc2fEVGSkT2dL
          ((or (string-match-p "stackoverflow.com/[aq]" url)
               (string-match-p "serverfault.com/[aq]" url)
               (string-match-p "superuser.com/[aq]" url)
               (string-match-p ".stackexchange.com/[aq]" url))
           (sx-from-url url))
          ((or (string-match-p "search\\.google\\.com/search-console" url)
               (string-match-p "mullikine\\.matomo\\.cloud" url))
           (chrome url))
          ((or (string-match-p "asciinema\\.org/a/" url))
           (nw (concat "o " (pen-q url))))
          ((or (string-match-p "www\\.youtube\\.com/watch\\?v=" url)
               (string-match-p "https?://youtu\\.be" url))
           (sps (concat "ff " (pen-q url))))
          ;; http://magnet:?xt=urn:btih:1F79DEEC4D37130E411162E3D284CFE40E9A59C4&dn=The Case for Christ (2017) 720p BrRip x264 - VPPV&tr=udp://tracker.coppersurfer.tk:6969/announce&tr=udp://9.rarbg.to:2920/announce&tr=udp://tracker.opentrackr.org:1337&tr=udp://tracker.internetwarriors.net:1337/announce&tr=udp://tracker.leechers-paradise.org:6969/announce&tr=udp://tracker.coppersurfer.tk:6969/announce&tr=udp://tracker.pirateparty.gr:6969/announce&tr=udp://tracker.cyberia.is:6969/announce
          ((string-match-p "magnet:\\?xt" url)
           (sps (concat "rt " (pen-q url))))
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
           (setcar args (cl-sn "fix-racket-doc-url -w" :stdin url :chomp t))
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
           ;; /home/shane/dump/home/shane/notes/ws/pdf/incoming
           ;; http://93.174.95.29/main/1000/b14e74047c58550bc36b25c79fba24ff/Graham%20Hutton%20-%20Programming%20in%20Haskell-Cambridge%20University%20Press%20%282007%29.pdf
           ;; Download the pdf
           ;; (my/copy url)
           (wget url (mu "$DUMP$NOTES/ws/download/"))
           ;; (mu (nw (concat "CWD=" (pen-q "$DUMP$NOTES/ws/pdf/incoming/") " zrepl -cm -E " (pen-q "wget -c " (pen-q url)))))
           ;; (my/copy url)
           (message url)
           ;; (let ((url (concat "http://" (s-replace-regexp "^http.*//libraries.io/[^/]+/" "" url))))
           ;;   (sh/gc (urldecode url)))
           )
          (
           ;; Capture groups appear to not work
           (or (string-match-p "^http.*\\.pdf$" url)
               (string-match-p "^http.*\\.epub$" url)
               (string-match-p "^http.*/openreview.net/pdf" url)
               (string-match-p "^http.*\\.azw3$" url)
               (string-match-p "^http.*\\.djvu$" url))
           ;; /home/shane/dump/home/shane/notes/ws/pdf/incoming
           ;; http://93.174.95.29/main/1000/b14e74047c58550bc36b25c79fba24ff/Graham%20Hutton%20-%20Programming%20in%20Haskell-Cambridge%20University%20Press%20%282007%29.pdf
           ;; Download the pdf
           ;; (my/copy url)
           (wget url (mu "$DUMP$NOTES/ws/pdf/incoming/"))
           (message url))
          (t (let ((res (apply proc (cons url (cdr args)))))
               res)))))

(advice-add 'eww-browse-url :around #'advice-handle-url)

(advice-add 'eww :around #'advice-handle-url)
(advice-add 'pen-eww :around #'advice-handle-url)

(define-key eww-mode-map (kbd "C-g") nil)
(define-key eww-mode-map (kbd "C-t") 'my-eww-show-status)

(defun pen-eww-follow-link ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'eww-open-in-new-buffer)
    (call-interactively 'eww-follow-link)))

;; (defalias 'name 'definition)
;; shr-browse-url

;; (define-key eww-mode-map (kbd "C-m") 'pen-eww-follow-link)
(define-key eww-mode-map (kbd "C-m") nil)
(define-key eww-link-keymap (kbd "C-m") 'pen-eww-follow-link)

;; does this fix ssl?
;; https://emacs.stackexchange.com/questions/54226/accessing-https-sites-with-mac-emacs-26-3
;; (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

;; (defun pen-add-to-glossary-file-for-buffer () (interactive))

(defun glossary-add-link () (interactive))
(define-key eww-mode-map (kbd "L") 'glossary-add-link)
(define-key eww-mode-map (kbd "A") 'pen-add-to-glossary-file-for-buffer)

(defun eww-reader (url)
  (interactive (list (let ((path (get-path)))
                       (if (re-match-p "^http" path)
                           path
                         (read-string-hist "eww reader url: ")))))
  (if (re-match-p "^http" url)
      (let ((readerurl (cl-sn (concat "rdrview -url " (pen-q url)) :chomp t)))
        (message readerurl)
        (with-temp-buffer
          (eww-open-file readerurl)))))

(define-key eww-mode-map (kbd "e") 'eww-reader)

(define-key global-map (kbd "H-e") 'eww-fz-history)

(define-key eww-mode-map (kbd "M-9") #'dict-word)
(define-key eww-mode-map (kbd "m") #'toggle-use-chrome-locally)


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
    (pen-eww (get-path))))
(advice-add 'eww-reload :around #'eww-reload-around-advice)

;; TODO Make an eww binding to search the current domain for a string
;; TODO Make an eww binding to search the current domain for the current URL (to find, perhaps, a catalog)
;; site:nlp.stanford.edu intext:projects/socialsent

(defun eww-summarize-this-page (url)
  (interactive (let* ((p (get-path)))
                 (list p)))

  (if (sor url)
      (mtv (pen-snc (pen-cmd "summarize-page" url)))))

(defun google-this-url-in-this-domain (url domain)
  (interactive (let* ((p (get-path))
                      (d (url-domain (url-generic-parse-url p))))
                 (list p d)))

  (let ((query (concat "site:" (pen-q domain) " " "intext:" (pen-q url))))
    (eegr query)))

;; Just don't ever redirect
;; This makes google much slower, when
(defun eww-tag-meta-around-advice (proc &rest args)
  (let* ((eww-redirect-level 5)
         (res (apply proc args)))
    res))
(advice-add 'eww-tag-meta :around #'eww-tag-meta-around-advice)


(defun eww-open-in-chrome (url)
  (interactive (list (if (major-mode-p 'eww-mode)
                         (get-path)
                       (read-string-hist "chrome: "))))
  (chrome url))


(require 'eww)
(require 'my-mode)
(define-key eww-mode-map (kbd "M-*") 'my/evil-star-maybe)


(advice-add 'font-lock-fontify-keywords-region :around #'ignore-errors-around-advice)

(define-key eww-link-keymap (kbd "i") nil)

(define-key eww-mode-map (kbd "g") 'my-eww-reload)
(define-key eww-mode-map (kbd "m") 'toggle-use-chrome-locally)

(define-key eww-mode-map (kbd "M-P") 'handle-preverr)
(define-key eww-mode-map (kbd "M-N") 'handle-nexterr)

(define-key eww-mode-map (kbd "c") 'eww-open-in-chrome)
(define-key eww-mode-map (kbd "i") 'eww-open-in-chrome)

(defun shr-urlify (start url &optional title)
  (if (my-url-cache-exists url)
      ;; (shr-add-font start (point) 'shr-link)
      ;; link-visited
      (shr-add-font start (point) 'eww-cached)
    (shr-add-font start (point) 'shr-link))

  (add-text-properties
   start (point)
   (list 'shr-url url
         'button t
         'category 'shr                 ; For button.el button buffers.
	       'help-echo (let ((parsed (url-generic-parse-url
                                   (or (ignore-errors
				                                 (decode-coding-string
				                                  (url-unhex-string url)
				                                  'utf-8 t))
				                               url)))
                          iri)
                      ;; If we have an IDNA domain, then show the
                      ;; decoded version in the mouseover to let the
                      ;; user know that there's something possibly
                      ;; fishy.
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
  ;; Don't overwrite any keymaps that are already in the buffer (i.e.,
  ;; image keymaps).
  (while (and start
              (< start (point)))
    (let ((next (next-single-property-change start 'keymap nil (point))))
      (if (get-text-property start 'keymap)
          (setq start next)
        (put-text-property start (or next (point)) 'keymap shr-map)))))

(defun eww-add-domain-to-chrome-dom-matches (url)
  (interactive (list (url-domain (url-generic-parse-url (get-path)))))
  (mu
   (write-to-file
    (pen-snc "uniqnosort"
         (concat (sn "cat \"$NOTES/programs/eww/chrome-dom-url-patterns.txt\" | awk 1")
                 (concat "http.*" url)))
    "$NOTES/programs/eww/chrome-dom-url-patterns.txt"))
  (reload-eww-use-chrome-dom-matchers)
  (call-interactively 'eww-reload-cache-for-page))

(defun eww-mirror-url (url)
  (interactive (let ((u (cond
                         ((major-mode-p 'eww-mode) (get-path))
                         (t (read-string-hist "mirror url: ")))))
                 (list u)))

  (sps (pen-cmd "my-mirror-site" url)))

(defun eww-select-wayback-for-url (url)
  (interactive (let ((u (cond
                         ((major-mode-p 'eww-mode) (get-path))
                         (t (read-string-hist "wayback url: ")))))
                 (list u)))

  (let ((page (pen-snc "sed -n 's=^https*://\\([^/]*\\)\\(.*\\)=\\2=p'" url))
        (sel (fz (pen-snc (concat (pen-cmd "wayback" url) " | tac"))
                 nil nil "wayback result: ")))

    (if (sor sel)
        (eww (concat sel page)))))

(define-key eww-mode-map (kbd "y") 'eww-select-wayback-for-url)

(defun eww-edit-histvar ()
  (interactive)
  (never
   ;; Too slow
   (edit-var-elisp 'histvar-fz-eww-history-)))

;; Merely overriding this function didn't even override it
;; lexical scope problem, probably
(defun my-eww-reload ()
  ""
  (interactive)
  (if (major-mode-p 'eww-mode)
      (let ((url (get-path)))
        (kill-buffer)
        (pen-eww url))))
(define-key eww-mode-map (kbd "g") 'my-eww-reload)

(defun eww-open-medium ()
  (interactive)
  (dolist (url (str2list (scrape "^https://medium\\..*" (eww-list-history))))
    (pen-eww url)
    (sleep 2)))

(defun eww-open-huggingface ()
  (interactive)
  (dolist (url (str2list (scrape "^https://huggingface\\.co.*" (eww-list-history))))
    (pen-eww url)
    (sleep 2)))

(defun eww-open-spacy ()
  (interactive)
  (dolist (url (str2list (scrape "^https://spacy\\.io.*" (eww-list-history))))
    (pen-eww url)
    (sleep 2)))

(defun eww-open-eleutherai ()
  (interactive)
  (dolist (url (str2list (scrape "^https://eleuther\\.ai.*" (eww-list-history))))
    (pen-eww url)
    (sleep 2)))

(defun eww-open-amazon ()
  (interactive)
  (dolist (url (str2list (scrape "^https://aws.amazon\\.com.*" (eww-list-history))))
    (pen-eww url)
    (sleep 2)))

(defun buffer-links ()
  (urls-in-region-or-buffer (textprops-in-region-or-buffer)))
(defalias 'eww-buffer-links 'buffer-links)

(defun eww-crawl (url)
  (interactive (list nil))

  (cond
   (url (pen-eww url))))

(defun eww-open-all-links ()
  (interactive)
  (cl-loop for url in (str2list (buffer-links))
        do (progn
             (pen-eww url)
             (sleep 2))))

(define-key eww-mode-map (kbd "C-c C-o") 'eww-follow-link)

(define-key eww-mode-map (kbd "M-e") 'eww-reload-cache-for-page)

(defun lg-render (url ascii)
  (interactive)
  (let ((firstline (pen-snc))))
  (pen-one (pf-generate-html-from-ascii-browser/2 url ascii)))

(provide 'pen-looking-glass)