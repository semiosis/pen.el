(require 'w3m)
(require 'w3m-filter)

(setq w3m-session-crash-recovery nil)

;; This means I can have multiple unique w3ms
(setq w3m-fb-mode t)

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

(add-to-list 'w3m-filter-configuration '(t
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

(provide 'pen-w3m)
