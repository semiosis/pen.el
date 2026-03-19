(require 'w3m)
(require 'w3m-filter)

;; This is a bit ugly and unnecessary.
;; I prefer separate buffers anyway.
(setq w3m-use-tab-line nil)
;; Header line was also unnecessary because I have the regular hear line that contains the url
(setq w3m-use-header-line nil)

(setq w3m-use-header-line-title t)

(setq w3m-session-crash-recovery nil)

;; (setq w3m-display-mode 'plain)
;; (setq w3m-display-mode 'tabbed-frames)
(setq w3m-display-mode 'tabbed)

;; This means I can have multiple unique w3ms
(w3m-fb-mode t)

(setq w3m-command (executable-find "w3m"))

;; Require eww for pen-advice-handle-url
(require 'eww)
(advice-add 'w3m :around #'pen-advice-handle-url)

(advice-add 'w3m-history :around #'advise-to-yes)
(advice-add 'w3m-gohome :around #'advise-to-yes)

(define-key w3m-mode-map (kbd "<up>") nil)
(define-key w3m-mode-map (kbd "<down>") nil)
(define-key w3m-mode-map (kbd "<left>") nil)
(define-key w3m-mode-map (kbd "<right>") nil)
(define-key w3m-mode-map (kbd "p") 'w3m-view-previous-page)
(define-key w3m-mode-map (kbd "n") 'w3m-view-this-url)
(define-key w3m-mode-map (kbd "w") 'pen-yank-path)

;; Need to unbind M-l so that global bindings work
(define-key w3m-mode-map (kbd "M-l") nil)

(defface w3m-paragraph '((t (:bold t)))
  "Face used for displaying paragraph text."
  :group 'w3m-face)

(set-face-foreground 'w3m-paragraph "#40f040")
(set-face-background 'w3m-paragraph "#105010")

(defun w3m-fontify-paragraph ()
  "Fontify paragraph text in the buffer containing halfdump."
  (goto-char (point-min))
  ;; (tv (buffer-string))
  (while (search-forward "<p>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</p[ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'w3m-paragraph)))))

;; Paragraph is removed in halfdump
;; (remove-hook 'w3m-fontify-before-hook 'w3m-fontify-paragraph)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-paragraph)
(remove-hook 'w3m-fontify-before-hook 'w3m-fontify-paragraph)

(defface w3m-ul '((t (:bold t)))
  "Face used for displaying ul text."
  :group 'w3m-face)

(set-face-foreground 'w3m-ul "#f04040")
(set-face-background 'w3m-ul "#501010")

(defun w3m-fontify-ul ()
  "Fontify ul text in the buffer containing halfdump."
  (goto-char (point-min))
  ;; (tv (buffer-string))
  (while (search-forward "<ul>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</ul[ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'w3m-ul)))))

;; (remove-hook 'w3m-fontify-before-hook 'w3m-fontify-ul)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-ul)
(remove-hook 'w3m-fontify-before-hook 'w3m-fontify-ul)

(defun w3m-show-html-for-fontify ()
  (tv (buffer-string) :tm_wincmd "nw"))

(defun w3m-enable-display-html-for-fontify ()
  (interactive)
  (add-hook 'w3m-fontify-before-hook 'w3m-show-html-for-fontify))

(defun w3m-disable-display-html-for-fontify ()
  (interactive)
  (remove-hook 'w3m-fontify-before-hook 'w3m-show-html-for-fontify))

;; Sadly, this happens too late in the process.
;; I need to run rdrview on earlier html

;; Do it at the end of j:w3m-decode-buffer where it has (buffer-string)
(defun w3m-rdrview-for-fontify ()
  (let ((shortened (snc "rdrview -H" (buffer-string))))

    (delete-region (point-min) (point-max))
    (insert shortened)))

;; ;; nadvice - proc is the original function, passed in. do not modify
;; (defun w3m-decode-buffer-around-advice (proc &rest args)
;;   ;; (tv (buffer-string))
;;   
;;   (let ((shortened (snc "rdrview -H" (buffer-string))))
;; 
;;     (delete-region (point-min) (point-max))
;;     (insert shortened))
;;   
;;   (let ((res (apply proc args)))
;;     res))
;; (advice-add 'w3m-decode-buffer :around #'w3m-decode-buffer-around-advice)
;; (advice-remove 'w3m-decode-buffer #'w3m-decode-buffer-around-advice)

(defun w3m-enable-rdrview-for-fontify ()
  (interactive)
  (add-hook 'w3m-fontify-before-hook 'w3m-rdrview-for-fontify))

(defun w3m-disable-rdrview-for-fontify ()
  (interactive)
  (remove-hook 'w3m-fontify-before-hook 'w3m-rdrview-for-fontify))

;; I think the best way to get the interlinear text from biblehub would be to
;; make a "ved" script
;; https://biblehub.com/interlinear/genesis/1-1.htm

;; TODO Add w3m-horizontal-recenter somewhere. It used to be M-l

;; ocif curl "https://biblehub.com/interlinear/genesis/1-1.htm" | elinks-dump | sed -z "s/1\\n\\n/\\n/" | sed "s/   [0-9]\\+$//g" | sed "s/ / /g" | erase-trailing-whitespace | sed -e 's/^\s*//' | sed "s/ \\[e\\]$//" | sed "s/ \\+/ /g" | ved "-m" "V/Click for Chapter\\<CR>ddd/IFrame\\<CR>VGd"

;; Solve this problem, then solve caching w3m:
;; I can only currently memoize functions which return a string.
;; But I want to be able to memoize functions which insert something
;; into the current buffer.


;; To solve this problem I might need to add advice to memoize
;; or to make a memoize-bufferfunc

;; (defun w3m-retrieve-around-advice (proc &rest args)
;;   (with-temp-buffer)
;;   (let ((res (apply proc args)))
;;     (message "w3m-retrieve returned %S" res)
;;     res))
;; (advice-add 'w3m-retrieve :around #'w3m-retrieve-around-advice)
;; (advice-remove 'w3m-retrieve #'w3m-retrieve-around-advice)

;; There has to be something inside url-retrieve
;; that I can memoize
;; Though, memoizing w3m-retrieve should work?
;; (memoize 'w3m-retrieve)
;; (memoize-restore 'w3m-retrieve)

(defun pen-w3m-mouse-major-mode-menu (event)
  (interactive (list
                (get-pos-for-x-popup-menu)))

  (w3m-mouse-major-mode-menu event))

(define-key w3m-mode-map (kbd "<down-mouse-3>") nil)

;; Make a button cloud or something.
;; I want to be able to enable and disable rdrview easily
;; (defset w3m-filter-options)

;; TODO Select filter options here

;; (sh-construct-envs '(("UPDATE" "y")))

;; [[ekbd:M-c]]
;; sp +/"w3m_use_chome_dump" "$EMACSD/pen.el/scripts/w3m"


;; Hmmm.... I need to implement execution priority for the filters
;; so that I can put the google chrome dom dump at the start.

(setq w3m-local-find-file-regexps
      (cons nil
	        (concat "\\."
		            (regexp-opt (append '("htm"
				                          "html"
				                          "shtm"
				                          "shtml"
				                          "xhtm"
				                          "xhtml"
				                          "txt")
				                        (and w3m-markdown-converter '("md"))
				                        (and (w3m-image-type-available-p 'jpeg)
					                         '("jpeg" "jpg"))
				                        (and (w3m-image-type-available-p 'gif)
					                         '("gif"))
				                        (and (w3m-image-type-available-p 'png)
					                         '("png"))
				                        (and (w3m-image-type-available-p 'xbm)
					                         '("xbm"))
				                        (and (w3m-image-type-available-p 'xpm)
					                         '("xpm"))))
                    ;; /root/repos/acg/w3m/w3m-doc/development.html.in
                    ;; I added this bit of regex to accommodate opening files like development.html.in in w3m
                    "\\(\\.[a-zA-Z0-9]+\\)?"
		            "\\'")))

(defun w3m-filter-rdrview (url)
  "Summarize webpage"
  (apply 'call-process-region
         (point-min)
         (point-max)
         "env"
         t t nil
         ;; Need to get this somehow j:w3m-current-base-url
         ;; It wasn't set yet but j:w3m-current-url did exist

         ;; 
         ;; `("-S" ,@(sh-construct-envs-list '(("ENABLE_RDRVIEW" "y"))) "pen-filter-html" "-u" ,(w3m-url-strip-fragment w3m-current-url))

         ;; But now am using the w3m builtin filter system
         `("-S" ,@(sh-construct-envs-list '(("ENABLE_RDRVIEW" "y"))) "pen-filter-html" "-u" ,(w3m-url-strip-fragment url))
         ;; `()
         ))

;; Setting t here would enable rdrview for w3m every time emacs starts
(add-to-list 'w3m-filter-configuration '(;; t
                                         nil
                                         ("Extract readability portion of web page. Operates on all pages" "rdrview")
                                         "\\`https?://" w3m-filter-rdrview))
;; 
;;  ("Strip Google's click-tracking code from link urls" "Google の click-tracking コードをリンクの url から取り除きます")
;;  "\\`https?://[a-z]+\\.google\\." w3m-filter-google-click-tracking)

(comment
 (defun w3m-rendering-half-dump (charset)
   "Run w3m -halfdump on buffer's contents.
CHARSET is used to substitute the `charset' symbols specified in
`w3m-halfdump-command-arguments' with its value."
   (ignore charset)
   (w3m-set-display-ins-del)
   (let* ((coding-system-for-read w3m-output-coding-system)
          (coding-system-for-write (if (eq 'binary w3m-input-coding-system)
                                       w3m-current-coding-system
                                     w3m-input-coding-system))
          (default-process-coding-system
           (cons coding-system-for-read coding-system-for-write)))
     (w3m-process-with-environment w3m-command-environment
       ;; (w3m-filter-html-in-buffer)
       (apply 'call-process-region
              (point-min)
              (point-max)
              (or w3m-halfdump-command w3m-command)
              t t nil
              (w3m-w3m-expand-arguments
               (append w3m-halfdump-command-arguments
                       w3m-halfdump-command-common-arguments
                       ;; Image size conscious rendering
                       (when (member "image" w3m-compile-options)
                         (if (and w3m-treat-image-size
                                  (or (display-images-p)
                                      (and w3m-pixels-per-line
                                           w3m-pixels-per-character)))
                             (list "-o" "display_image=on"
                                   "-ppl" (number-to-string
                                           (or w3m-pixels-per-line
                                               (frame-char-height)))
                                   "-ppc" (number-to-string
                                           (or w3m-pixels-per-character
                                               (frame-char-width))))
                           (list "-o" "display_image=off"))))
               charset))))))

(defun w3m-fontify-h1 ()
  "Fontify h1 text in the buffer containing halfdump."
  (goto-char (point-min))
  (while (re-search-forward "<h1[^>]*>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</h1[ \t\r\f\n]*>" nil t)
	(delete-region (match-beginning 0) (match-end 0))
	(w3m-add-face-property start (match-beginning 0) 'shr-h1)))))

(defun w3m-fontify-h2 ()
  "Fontify h2 text in the buffer containing halfdump."
  (goto-char (point-min))
  (while (re-search-forward "<h2[^>]*>" nil t)
    (let ((start (match-beginning 0)))
      ;; (tv (region2string start (match-end 0)) :tm_wincmd "nw")
      (delete-region start (match-end 0))
      ;; (tv (region2string (point) (+ 1000 (point)))
      ;;     :tm_wincmd "nw")
      (when (re-search-forward "</h2[ \t\r\f\n]*>" nil t)
        ;; (tv (region2string (match-beginning 0) (match-end 0)) :tm_wincmd "nw")
        ;; (tv (region2string start (match-beginning 0)) :tm_wincmd "nw")
	    (delete-region (match-beginning 0) (match-end 0))
        ;; (tv (region2string  start (match-beginning 0)) :tm_wincmd "nw")
	    (w3m-add-face-property start (match-beginning 0) 'shr-h2)))))

(defun w3m-fontify-h3 ()
  "Fontify h3 text in the buffer containing halfdump."
  (goto-char (point-min))
  (while (re-search-forward "<h3[^>]*>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</h3[ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'shr-h3)))))

(defun w3m-fontify-h4 ()
  "Fontify h4 text in the buffer containing halfdump."
  (goto-char (point-min))
  (while (re-search-forward "<h4[^>]*>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</h4[ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'shr-h4)))))

(defun w3m-fontify-h5 ()
  "Fontify h5 text in the buffer containing halfdump."
  (goto-char (point-min))
  (while (re-search-forward "<h5[^>]*>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</h5[ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'shr-h5)))))

(defun w3m-fontify-h6 ()
  "Fontify h6 text in the buffer containing halfdump."
  (goto-char (point-min))
  (while (re-search-forward "<h6[^>]*>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</h6[ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'shr-h6)))))

(defun w3m-fontify-pre ()
  "Fontify pre text in the buffer containing halfdump."
  (goto-char (point-min))
  ;; Want to avoid <pre_int>
  (while (re-search-forward "<pre[^_>]*>" nil t)
    (let ((start (match-beginning 0)))
      ;; (tv (region2string start (match-end 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</pre[_ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'shr-code)))))

(add-hook 'w3m-fontify-before-hook 'w3m-fontify-h1)
(remove-hook 'w3m-fontify-before-hook 'w3m-fontify-h1)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-h2)
(remove-hook 'w3m-fontify-before-hook 'w3m-fontify-h2)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-h3)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-h4)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-h5)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-h6)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-pre)
(remove-hook 'w3m-fontify-before-hook 'w3m-fontify-pre)

(defun w3m-display-width ()
  "Return the maximum width which should display lines within the value."
  (let ((w3m-fill-column (if w3m--ignore-fill-column -1 w3m-fill-column)))
    (- 
     (if (< 0 w3m-fill-column)
         w3m-fill-column
       (+ (if (and w3m-select-buffer-horizontal-window
                   (get-buffer-window w3m-select-buffer-name))
              ;; Show pages as if there is no buffers selection window.
              (frame-width)
            (window-width))
          w3m-fill-column))

     ;; 4
     ;; Adding this, add the display-line-numbers margin width
     (header-line-indent--line-number-width))))

(defun w3m-header-line-insert ()
  "Put the header line into the current buffer."
  (when (and w3m-use-tab
	     w3m-use-header-line
	     w3m-current-url
	     (eq 'w3m-mode major-mode))
    (goto-char (point-min))
    (let ((ct (w3m-arrived-content-type w3m-current-url))
	  (charset (w3m-arrived-content-charset w3m-current-url)))
      (insert (format "Location%s: " (cond ((and ct charset) " [TC]")
					   (ct " [T]")
					   (charset " [C]")
					   (t "")))))
    (w3m-add-face-property (point-min) (point) 'w3m-header-line-title)
    (let ((start (point)))
      (insert (w3m-puny-decode-url
	       (if (string-match "[^\000-\177]" w3m-current-url)
		   w3m-current-url
		 (w3m-url-decode-string w3m-current-url
					w3m-current-coding-system
					"%\\([2-9a-f][0-9a-f]\\)"))))
      (w3m-add-face-property start (point) 'w3m-header-line-content)
      (w3m-add-text-properties
       start (point)
       `(mouse-face highlight keymap ,w3m-header-line-map
		    help-echo "mouse-2 prompts to input URL"))
      (setq start (point))
      (insert-char ?  (max
		               0
                       (- 
		                (- (if (and w3m-select-buffer-horizontal-window
				                    (get-buffer-window w3m-select-buffer-name))
			                   (frame-width)
			                 (window-width))
			               (current-column) 1)
                        (header-line-indent--line-number-width))))
      (w3m-add-face-property start (point) 'w3m-header-line-content)
      (unless (eolp)
	    (insert "\n")))))

;; (defun pen-w3m-save-history ()
;;   (tv (get-path nil t)))

;; w3m-display-hook shouldn't be used because it runs on resize
;; (add-hook 'w3m-display-hook 'pen-w3m-save-history)
;; (remove-hook 'w3m-display-hook 'pen-w3m-save-history)
;; Neither can the fontify hooks be used for the same reason
;; (add-hook 'w3m-fontify-before-hook 'pen-w3m-save-history)
;; (remove-hook 'w3m-fontify-before-hook 'pen-w3m-save-history)

;; Tried:
;; (add-hook 'w3m-arrived-shutdown-functions 'pen-w3m-save-history)
;; (remove-hook 'w3m-arrived-shutdown-functions 'pen-w3m-save-history)

;;
;; Use w3m-arrived-setup-functions

(defun w3m-goto-url-advice (proc &rest args)
  (let ((res (apply proc args)))
    (let ((url (car args)))
      (hs "w3m-goto-url" url))
    ;; (tv (car args))
    res))

(advice-add 'w3m-goto-url :around #'w3m-goto-url-advice)
;; (advice-remove 'w3m-goto-url #'w3m-goto-url-advice)

(require 'pen-metservice)

;; (define-key w3m-mode-map (kbd "W") 'w3m-weather)
(define-key w3m-mode-map (kbd "W") 'get-weather-report)

;; Modify this so that arg can also be given to specify the filter.
;; So arg has a double use.
;; It could simply be the prefix or it could be a filter
(defun w3m-toggle-filtering (arg)
  "Toggle whether to modify html source by the filters before rendering.
With prefix arg, prompt for a single filter to toggle (a function
toggled last will first appear) with completion."
  (interactive "P")
  (if (not arg)
      ;; toggle state for all filters
      (progn
        (setq w3m-use-filter (not w3m-use-filter))
        (message (concat
                  "web page filtering now "
                  (if w3m-use-filter "enabled" "disabled"))))
    ;; the remainder of this function if for the case of toggling
    ;; an individual filter
    (let* ((selection-list (delq nil (mapcar
                                      (lambda (elem)
                                        (when (and (symbolp (nth 3 elem))
                                                   (fboundp (nth 3 elem)))
                                          (symbol-name (nth 3 elem))))
                                      w3m-filter-configuration)))
           (choice
            (let ((e (-elem-index arg selection-list)))
              (if e
                  arg
                (completing-read
                 "Enter filter name: " selection-list nil t
                 (or (car w3m-filter-selection-history)
                     (car selection-list))
                 'w3m-filter-selection-history))))
           (filters w3m-filter-configuration)
           elem
           val)
      (unless (string= "" choice)
        (setq choice (intern choice))
        (while (setq elem (pop filters))
          (when (eq choice (nth 3 elem))
            (setq filters nil)
            (setcar elem (not (car elem)))
            (when (car elem)
              (setq w3m-use-filter t))
            (message "filter `%s' now %s"
                     choice
                     (if (car elem) "enabled" "disabled"))
            (setq val (car elem)))))
      val)))

(defun w3m-filter-enabled-p (f &optional do-msg)
  (let ((filters w3m-filter-configuration)
        elem
        val)
    (while (setq elem (pop filters))
      (when (eq (intern f) (nth 3 elem))
        (setq filters nil)
        ;; (setcar elem (not (car elem)))
        ;; (when (car elem)
        ;;   (setq w3m-use-filter t))
        (if do-msg
            (message "filter `%s' now %s"
                     f
                     (if (car elem) "enabled" "disabled")))
        (setq val (car elem))))
    val))

(defun w3m-toggle-rdrview ()
  (interactive)
  (w3m-toggle-filtering "w3m-filter-rdrview")
  (w3m-reload-this-page)
  (w3m-filter-enabled-p "w3m-filter-rdrview" t))

(define-key w3m-mode-map (kbd "C-c C-d") 'w3m-toggle-rdrview)

;; TODO Use regular link-hint functions but advise the functions use to open the links

(defun w3m-link-hint-copy ()
  "Like what I had in pentadactyl."
  (interactive)
  (avy-with w3m-link-hint-copy
    (link-hint--one :copy)))

(define-key w3m-mode-map (kbd "Fy") 'w3m-link-hint-copy)

(defun w3m-link-hint-open ()
  "Like what I had in pentadactyl."
  (interactive)
  (avy-with w3m-link-hint-open
    (link-hint--one :open)))

(define-key w3m-mode-map (kbd "Fo") 'w3m-link-hint-open)

(defun w3m-link-hint-tv ()
  "Like what I had in pentadactyl."
  (interactive)
  (avy-with w3m-link-hint-tv
    ;; (let* ((browse-url-browser-function (lambda (&rest args) (tv (car args))))
    ;;        (browse-url browse-url-browser-function))
    ;;   (link-hint--one :open))

    (cl-letf (((symbol-function 'link-hint--action)
               (lambda (action link) (tv (plist-get link :args)))))
      (link-hint--one :open))))

(defun w3m-link-hint-get-url ()
  ""
  (interactive)
  (avy-with w3m-link-hint-get-url
    (cl-letf (((symbol-function 'link-hint--action)
               (lambda (action link) (plist-get link :args))))
      (link-hint--one :open))))

(defun w3m-link-hint-new-tab ()
  "Like what I had in pentadactyl."
  (interactive)
  (let ((url (w3m-link-hint-get-url))
        (pen-use-existing-w3m-buffer nil))

    (with-current-buffer "*scratch*"
      (w3m url))))

(define-key w3m-mode-map (kbd "FF") 'w3m-link-hint-new-tab)
(define-key w3m-mode-map (kbd "Ft") 'w3m-link-hint-new-tab)


(defset pen-use-existing-w3m-buffer t "Enabled, this is the default w3m behaviour. Disable it to force a new w3m buffer")

(setq pen-use-existing-w3m-buffer t)

(defun w3m (&optional url new-session interactive-p)
  "Visit World Wide Web pages using the external w3m command.

If no emacs-w3m session already exists: If POINT is at a url
string, visit that. Otherwise, if `w3m-home-page' is defined,
visit that. Otherwise, present a blank page. This behavior can be
over-ridden by setting variable `w3m-quick-start' to nil, in
which case you will always be prompted for a URL.

If an emacs-w3m session already exists: Pop to one of its windows
or frames. You can over-ride this behavior by setting
`w3m-quick-start' to nil, in order to always be prompted for a
URL.

In you have set `w3m-quick-start' to nil, but wish to over-ride
default behavior from the command line, either run this command
with a prefix argument or enter the empty string for the prompt.
In such cases, this command will visit a url at the point or,
lacking that, the URL set in variable `w3m-home-page' or, lacking
that, the \"about:\" page.

Any of five display styles are possible. See `w3m-display-mode'
for a description of those options.

You can also run this command in the batch mode as follows:

  emacs -f w3m http://emacs-w3m.namazu.org/ &

In that case, or if this command is called non-interactively, the
variables `w3m-pop-up-windows' and `w3m-pop-up-frames' will be ignored
(treated as nil) and it will run emacs-w3m at the current (or the
initial) window.

If the optional NEW-SESSION is non-nil, this function creates a new
emacs-w3m buffer.  Besides that, it also makes a new emacs-w3m buffer
if `w3m-make-new-session' is non-nil and a user specifies a url string.

The optional INTERACTIVE-P is for the internal use; it is mainly used
to check whether Emacs calls this function as an interactive command
in the batch mode."
  (interactive
   (let ((url
          ;; Emacs calls a Lisp command interactively even if it is
          ;; in the batch mode.  If the following function returns
          ;; a non-nil value, it means this function is called in
          ;; the batch mode, and we don't treat it as what it is
          ;; called interactively.
          (w3m-examine-command-line-args))
         new)
     (list
      ;; url
      (or url
          (let ((default (or (w3m-url-at-point)
                             (if (w3m-alive-p) 'popup w3m-home-page))))
            (setq new (if current-prefix-arg
                          default
                        (w3m-input-url nil nil default w3m-quick-start
                                       'feeling-searchy 'no-initial)))))
      ;; new-session
      (and w3m-make-new-session
           (w3m-alive-p)
           (not (eq new 'popup)))
      ;; interactive-p
      (not url))))
  (let ((nofetch (eq url 'popup))
        (alived (w3m-alive-p))
        (buffer (unless new-session (w3m-alive-p t)))
        (w3m-pop-up-frames (and interactive-p w3m-pop-up-frames))
        (w3m-pop-up-windows (and interactive-p w3m-pop-up-windows)))
    (unless (and (stringp url)
                 (> (length url) 0))
      (if buffer
          (setq nofetch t)
        ;; This command was possibly be called non-interactively or as
        ;; the batch mode.
        (setq url (or (w3m-examine-command-line-args)
                      ;; Unlikely but this function was called with no url.
                      "about:")
              nofetch nil)))
    (unless (and buffer
                 pen-use-existing-w3m-buffer)
      ;; It means `new-session' is non-nil or there's no emacs-w3m buffer.
      ;; At any rate, we create a new emacs-w3m buffer in this case.
      (setq buffer (w3m-generate-new-buffer "*w3m*")))
    (w3m-popup-buffer buffer)
    (unless nofetch
      ;; `unwind-protect' is needed since a process may be terminated by C-g.
      (unwind-protect
          (let* ((crash (and (not alived)
                             (w3m-session-last-crashed-session)))
                 (last (and (not alived)
                            (not crash)
                            (w3m-session-last-autosave-session))))
            (w3m-goto-url url)
            (when (or crash last)
              (w3m-session-goto-session (or crash last))))
        ;; Delete useless newly created buffer if it is empty.
        (w3m-delete-buffer-if-empty buffer)))))

(defun w3m-goto-url-new-session (url &optional reload charset post-data
                                     referer background)
  "Visit World Wide Web pages in a new buffer.
Open a new tab if you use tabs, i.e., `w3m-display-mode' is set to
`tabbed' or `w3m-use-tab' is set to a non-nil value.

The buffer will get visible if BACKGROUND is nil or there is no other
emacs-w3m buffer regardless of BACKGROUND, otherwise (BACKGROUND is
non-nil) the buffer will be created but not appear to be visible.
BACKGROUND defaults to the value of `w3m-new-session-in-background',
but it could be inverted if called interactively with the prefix arg."
  (interactive
   (list (w3m-input-url "Open URL in new buffer" nil
                        (or (w3m-active-region-or-url-at-point)
                            w3m-new-session-url)
                        nil 'feeling-searchy 'no-initial)
         nil ;; reload
         coding-system-for-read
         nil   ;; post-data
         nil   ;; referer
         nil)) ;; background
  (setq background (when (let (w3m-fb-mode) (ignore w3m-fb-mode)
                              (w3m-list-buffers t))
                     (if (w3m-interactive-p)
                         (if current-prefix-arg
                             (not w3m-new-session-in-background)
                           w3m-new-session-in-background)
                       (or background w3m-new-session-in-background))))
  (let (buffer)
    (if (and
         pen-use-existing-w3m-buffer
         (or (eq 'w3m-mode major-mode)
             (and (setq buffer (w3m-alive-p))
                  (progn (w3m-popup-buffer buffer) t))))
        (progn
          (w3m-history-store-position)
          (setq buffer (w3m-copy-buffer nil "*w3m*" background 'empty t)))
      (setq buffer (w3m-generate-new-buffer "*w3m*")))
    (if background
        (set-buffer buffer)
      (cond ((and w3m-use-tab (eq 'w3m-mode major-mode))
             (switch-to-buffer buffer))
            ((w3m-popup-frame-p) (switch-to-buffer-other-frame buffer))
            ((w3m-popup-window-p) (switch-to-buffer-other-window buffer))
            (t (switch-to-buffer buffer)))
      (w3m-display-progress-message url))
    (w3m-goto-url
     url
     (or reload
         ;; When new URL has `name' portion, (ir. a URI
         ;; "fragment"), we have to goto the base url
         ;; because generated buffer has no content at
         ;; this moment.
         (and
          (w3m-string-match-url-components url)
          (match-beginning 8)
          'redisplay))
     charset post-data referer nil nil background)
    ;; Delete useless newly created buffer if it is empty.
    (w3m-delete-buffer-if-empty buffer)))

;; DONE Make it so w3m-browse-url starts a new session 
(defun w3m-browse-url (url &optional new-session refresh-if-exists)
  "Ask emacs-w3m to browse URL.
When called interactively, URL defaults to the string existing around
the cursor position and looking like a url.  If the prefix argument is
given[1] or NEW-SESSION is non-nil, create a new emacs-w3m session.
If REFRESH-IF-EXISTS is non-nil, refresh the page if it already exists
but is older than the site.

[1] More precisely the prefix argument inverts the boolean logic of
`browse-url-new-window-flag' that defaults to nil."
  (interactive (progn
                 (require 'browse-url)
                 (browse-url-interactive-arg "Emacs-w3m URL: ")))
  (when (stringp url)
    (setq url (w3m-canonicalize-url url))
    (if (or new-session
            (not pen-use-existing-w3m-buffer))
        (w3m-goto-url-new-session url)
      (w3m-goto-url
       url
       ;; Reload the page if it is already visited, older than the site,
       ;; and REFRESH-IF-EXISTS is non-nil.
       (let (buffer)
         (and refresh-if-exists
              (setq buffer (w3m-alive-p t))
              (string-equal url (with-current-buffer buffer w3m-current-url))
              (w3m-time-newer-p (let ((w3m-message-silent t))
                                  (w3m-last-modified url t))
                                (w3m-arrived-last-modified url))))
       nil nil nil nil nil nil t))))

(provide 'pen-w3m)
