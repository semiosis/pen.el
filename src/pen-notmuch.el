(require 'el-secretario)
;; (require 'el-secretario-org)
(require 'el-secretario-notmuch)
;; (require 'el-secretario-elfeed)

(require 'notmuch)

(setq notmuch-show-part-button-default-action 'notmuch-show-view-part)

;; It's a buffer-local variable, so you should use setq-default.
(setq-default notmuch-search-oldest-first nil)

(require 'ol-notmuch)
(require 'notmuch-transient)
(require 'notmuch-maildir)
(require 'notmuch-labeler)
(require 'notmuch-bookmarks)
(require 'notmuch-addr)

(with-eval-after-load 'notmuch-address
  (require 'notmuch-addr)
  (notmuch-addr-setup))

(require 'notmuch-address)

(require 'helm-notmuch)
(require 'el-secretario-notmuch)
(require 'counsel-notmuch)
(require 'consult-notmuch)
(require 'notmuch-indicator)

(require 'pen-postrender-sanitize)

;; TODO Set up notmuch instead of mu4e

(comment
 ;; Add mu4e to the load-path:
 (add-to-list 'load-path "/usr/share/emacs/site-lisp/mu4e")
 (require 'mu4e)

 (require 'el-secretario-mu4e)

 (require 'mu4easy)
 (require 'mu4e-views)
 (require 'mu4e-query-fragments)
 (require 'mu4e-overview)
 (require 'mu4e-marker-icons)
 (require 'mu4e-jump-to-list)
 (require 'mu4e-conversation)
 (require 'mu4e-column-faces)
 (require 'mu4e-alert)
 (require 'el-secretario-mu4e))

(require 'bbdb)
;; (require 'org-notmuch)

; configure outgoing SMTP (so you can send messages):
(setq smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 587)

;; TODO Strip unicode from mail headings

;; (defun notmuch-sanitize (str)
;;   "Sanitize control character in STR.

;; This includes newlines, tabs, and other funny characters."
;;   (ascify (replace-regexp-in-string "[[:cntrl:]\x7f\u2028\u2029]+" " " str)))

;; disable the highlighting of read emails etc.
(defun notmuch-search-show-result (result pos)
  "Insert RESULT at POS."
  ;; Ignore excluded matches
  (unless (= (plist-get result :matched) 0)
    (save-excursion
      (goto-char pos)
      (dolist (spec notmuch-search-result-format)
	    (notmuch-search-insert-field (car spec) (cdr spec) result))
      (insert "\n")
      ;; (notmuch-search-color-line pos (point) (plist-get result :tags))
      (put-text-property pos (point) 'notmuch-search-result result))))

;; (defun browse-url-mail-around-advice (proc url &optional new-window)
;;   (comment (let ((res (apply proc (list url new-window))))
;;              res))
;;   (follow-mail-link url))
;; (advice-add 'browse-url-mail :around #'browse-url-mail-around-advice)
;; (advice-remove 'browse-url-mail #'browse-url-mail-around-advice)

;; Not only the headings, but the entire buffer needs sanitization
;; even after loading text/html
(defun notmuch-sanitize (str)
  "Sanitize control character in STR.

This includes newlines, tabs, and other funny characters."

  ;; Removing the variation selector helped a lot!
  ;; unicode FE0F
  ;; unicode 2028
  ;; https://www.cogsci.ed.ac.uk/$HOMErichard/utf-8.cgi?input=0xE2+0x80+0x8B&mode=obytes
  ;; https://www.cogsci.ed.ac.uk/$HOMErichard/utf-8.cgi?input=0xEF+0xB8+0x8F&mode=obytes

  ;; This function may sanitise literal html
  ;; which means if I want to match, say, trailing whitespace,
  ;; I need a post-rendered-html sanitization function
  (--> str
       (replace-regexp-in-string "\n" "<pen-newline>" it)
       (replace-regexp-in-string "\t" "<pen-tab>" it)
       ;; :cntrl: removes newlines
       (replace-regexp-in-string "[[:cntrl:]]+" " " it)
       (replace-regexp-in-string "[\x7f\u2028\u2029\ufe0f\u200a\u200c\ufe0f]+" " " it)
       (replace-regexp-in-string "<pen-newline>" "\n" it)
       (replace-regexp-in-string "<pen-tab>" "\t" it)
       ;; (s-replace-regexp "-- $" "" it)
       ;; (replace-regexp-in-string "[[:cntrl:]\x7f\u2028\u2029]+" " " it)
       ;; (ascify it)
       ))

(defun notmuch-show-fontify-header ()
  (let ((face (cond
               ((looking-at "[Tt]o:")
                'message-header-to)
               ((looking-at "[Bb]?[Cc][Cc]:")
                'message-header-cc)
               ((looking-at "[Ss]ubject:")
                'message-header-subject)
               (t
                'message-header-other))))
    (overlay-put (make-overlay (point) (re-search-forward ":"))
                 'face 'message-header-name)
    (let ((p (point))
          (m (re-search-forward ".*$")))
      ;; (tv (buffer-substring-no-properties p m)
      ;;     :editor "nw -w bvi")
      ;; (if (eq face 'message-header-subject)
      ;;     ;; (progn
      ;;     ;;   (tv (ascify (buffer-substring-no-properties p m))
      ;;     ;;       :editor "bvi"
      ;;     ;;       :tm_wincmd "nw")
      ;;     ;;   (tv (buffer-substring-no-properties p m)
      ;;     ;;       :editor "bvi"
      ;;     ;;       :tm_wincmd "nw"))
      ;;     )
      (overlay-put (make-overlay p m)
                   'face face))))

(defun notmuch-inbox ()
  (interactive)
  (let ((query "tag:inbox"))
    (notmuch-search query)
    ;; Work more on notmuch-tree later
    ;; (notmuch-tree query)
    ))

(defun notmuch-launch ()
  (interactive)

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (notmuch)
    (progn
      (if (major-mode-p 'notmuch-search-mode)
          ;; Refreshing is needed if the buffer were already open
          (notmuch-refresh-this-buffer)
        (notmuch-inbox)))))

(advice-add 'notmuch-launch :around #'notmuch-around-advice)

(define-key global-map (kbd "H-M") 'notmuch-launch)

(comment
 (require 'notmuch-indicator)
 (setq notmuch-indicator-args
       '((:terms "tag:unread and tag:inbox" :label "@")))

 (notmuch-indicator-mode t)

 ;; (setq notmuch-indicator-args
 ;;       '((:terms "tag:unread and tag:inbox" :label "@")
 ;;         (:terms "from:bank and tag:bills" :label "😱")
 ;;         (:terms "--output threads tag:loveletter" :label "💕")))
 )


;; nadvice - proc is the original function, passed in. do not modify
(defun notmuch-around-advice (proc &rest args)
  (if (yn "Pull?")
      (snc "spin gmi pull"))
  (let ((res (apply proc args)))
    res))
(advice-add 'notmuch :around #'notmuch-around-advice)
;; (advice-add 'notmuch-inbox :around #'notmuch-around-advice)
;; (advice-remove 'notmuch-inbox #'notmuch-around-advice)
;; (advice-remove 'notmuch #'notmuch-around-advice)


(define-key notmuch-search-mode-map (kbd "w") 'get-path)
(define-key notmuch-show-mode-map (kbd "w") 'get-path)

(defun notmuch-sanitize-onelinestring (str)
  (--> str
       (s-replace-regexp " $" "" it)
       ;; these are different
       (s-replace-regexp "^​" "" it)
       (s-replace-regexp "^ " "" it)
       (s-replace-regexp " " " " it)))

(defun notmuch-search-insert-field (field format-string result)
  (pcase field
    ((pred functionp)
     (insert (funcall field format-string result)))
    ("date"
     (insert (propertize (format format-string (plist-get result :date_relative))
                         'face 'notmuch-search-date)))
    ("count"
     (insert (propertize (format format-string
                                 (format "[%s/%s]" (plist-get result :matched)
                                         (plist-get result :total)))
                         'face 'notmuch-search-count)))
    ("subject"
     (insert (propertize
              (notmuch-sanitize-onelinestring (format format-string
                                                      (notmuch-sanitize (plist-get result :subject))))
              'face 'notmuch-search-subject)))
    ("authors"
     (notmuch-search-insert-authors format-string
                                    (notmuch-sanitize (plist-get result :authors))))
    ("tags"
     (let ((tags (plist-get result :tags))
           (orig-tags (plist-get result :orig-tags)))
       (insert (format format-string (notmuch-tag-format-tags tags orig-tags)))))))

(defun notmuch-tree-format-field (field format-string msg)
  "Format a FIELD of MSG according to FORMAT-STRING and return string."
  (let* ((headers (plist-get msg :headers))
         (match (plist-get msg :match)))
    (cond
     ((listp field)
      (format format-string (notmuch-tree-format-field-list field msg)))

     ((functionp field)
      (funcall field format-string msg))

     ((string-equal field "date")
      (let ((face (if match
                      'notmuch-tree-match-date-face
                    'notmuch-tree-no-match-date-face)))
        (propertize (format format-string (plist-get msg :date_relative))
                    'face face)))

     ((string-equal field "tree")
      (let ((tree-status (plist-get msg :tree-status))
            (face (if match
                      'notmuch-tree-match-tree-face
                    'notmuch-tree-no-match-tree-face)))

        (propertize (format format-string
                            (mapconcat #'identity (reverse tree-status) ""))
                    'face face)))

     ((string-equal field "subject")
      (let ((bare-subject (notmuch-show-strip-re (plist-get headers :Subject)))
            (previous-subject notmuch-tree-previous-subject)
            (face (if match
                      'notmuch-tree-match-subject-face
                    'notmuch-tree-no-match-subject-face)))

        (setq notmuch-tree-previous-subject bare-subject)
        (propertize (notmuch-sanitize-onelinestring
                     (format format-string
                             (if (string= previous-subject bare-subject)
                                 " ..."
                               bare-subject)))
                    'face face)))

     ((string-equal field "authors")
      (let ((author (notmuch-tree-clean-address (plist-get headers :From)))
            (len (length (format format-string "")))
            (face (if match
                      'notmuch-tree-match-author-face
                    'notmuch-tree-no-match-author-face)))
        (when (> (length author) len)
          (setq author (substring author 0 len)))
        (propertize (format format-string author) 'face face)))

     ((string-equal field "tags")
      (let ((tags (plist-get msg :tags))
            (orig-tags (plist-get msg :orig-tags))
            (face (if match
                      'notmuch-tree-match-tag-face
                    'notmuch-tree-no-match-tag-face)))
        (format format-string (notmuch-tag-format-tags tags orig-tags face)))))))

;; tidy up emails
;; [[notmuch:id:b8sxD45dTuqkG67xfc-SGg@geopod-ismtpd-21][Email from Miami Fruit: Embracing The Holiday Season With Gratitude 🌟]]
;; this also processes the text/html before it is rendered
(defun notmuch-get-bodypart-text-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (notmuch-sanitize
     (notmuch-sanitize-onelinestring res))))
(advice-add 'notmuch-get-bodypart-text :around #'notmuch-get-bodypart-text-around-advice)
;; (advice-remove 'notmuch-get-bodypart-text #'notmuch-get-bodypart-text-around-advice)

(defun notmuch-show-insert-part-text/plain (msg part _content-type _nth depth button)
  ;; For backward compatibility we want to apply the text/plain hook
  ;; to the whole of the part including the part button if there is
  ;; one.
  (let ((start (if button
                   (button-start button)
                 (point))))
    ;; I've added awk1
    ;; This guarantees a trailing newline
    (let ((p (point))
          (ret
           (progn
             (insert (awk1 (notmuch-get-bodypart-text msg part notmuch-show-process-crypto)))
             (save-excursion
               (save-restriction
                 (narrow-to-region start (point-max))
                 (run-hook-with-args 'notmuch-show-insert-text/plain-hook msg depth)))))
          (m (point)))

      (notmuch-sanitize-postrendered p m)
      ret))
  t)

;; this is the rendering of html
(defun notmuch-show--insert-part-text/html-shr (msg part)
  ;; Make sure shr is loaded before we start let-binding its globals
  (require 'shr)
  (let ((dom (let ((process-crypto notmuch-show-process-crypto))
               (with-temp-buffer
                 (insert (notmuch-get-bodypart-text msg part process-crypto))
                 (libxml-parse-html-region (point-min) (point-max)))))
        (shr-content-function
         (lambda (url)
           ;; shr strips the "cid:" part of URL, but doesn't
           ;; URL-decode it (see RFC 2392).
           (let ((cid (url-unhex-string url)))
             (car (notmuch-show--get-cid-content cid))))))
    (let ((p (point))
          (ret (shr-insert-document dom))
          (m (point)))

      (notmuch-sanitize-postrendered p m)
      ret)
    t))

;; notmuch

(define-key notmuch-search-mode-map (kbd "/") 'helm-notmuch)
(define-key notmuch-search-mode-map (kbd "h") 'helm-notmuch)
(define-key notmuch-show-mode-map (kbd "/") 'helm-notmuch)

;; This is taken:
;; (define-key notmuch-show-mode-map (kbd "h") 'helm-notmuch)

(require 'mm-decode)
;; notmuch uses this to open/save pdfs
(defun mm-save-part (handle &optional prompt)
  "Write HANDLE to a file.
PROMPT overrides the default one used to ask user for a file name."
  (let ((filename (or (mail-content-type-get
                       (mm-handle-disposition handle) 'filename)
                      (mail-content-type-get
                       (mm-handle-type handle) 'name)))
        file directory)
    (when filename
      (setq filename (gnus-map-function mm-file-name-rewrite-functions
                                        (file-name-nondirectory filename))))
    (while
        (progn
          (setq file
                (read-file-name
                 (or prompt
                     (format-prompt "Save MIME part to" filename))
                 (or directory mm-default-directory default-directory)
                 (expand-file-name
                  (or filename "")
                  (or directory mm-default-directory default-directory))))
          (cond ((or (not file) (equal file ""))
                 (message "Please enter a file name")
                 t)
                ((and (file-directory-p file)
                      (not filename))
                 (setq directory file)
                 (message "Please enter a non-directory file name")
                 t)
                (t nil)))
      (sit-for 2)
      (discard-input))
    (if (file-directory-p file)
        (setq file (expand-file-name filename file))
      (setq file (expand-file-name
                  file (or mm-default-directory default-directory))))
    (setq mm-default-directory (file-name-directory file))
    (and (or (not (file-exists-p file))
             (yes-or-no-p (format "File %s already exists; overwrite? "
                                  file)))
         (progn
           (mm-save-part-to-file handle file)
           file))))

(setq notmuch-multipart/alternative-discouraged
;; '("text/html" "multipart/related")
      '("text/plain" "multipart/related"))

;; It's not these functions
;; (advice-add 'notmuch-show-goto-message-next :around #'around-advice-disable-false)
;; (advice-add 'notmuch-show-goto-message-previous :around #'around-advice-disable-false)
;; (advice-remove 'notmuch-show-goto-message-next #'around-advice-disable-false)
;; (advice-remove 'notmuch-show-goto-message-previous #'around-advice-disable-false)

;; It's this one
;; (advice-add 'notmuch-show-move-to-message-top :around #'around-advice-disable-false)
;; (advice-add 'notmuch-show-move-to-message-bottom :around #'around-advice-disable-false)
;; (advice-remove 'notmuch-show-move-to-message-top #'around-advice-disable-false)
;; (advice-remove 'notmuch-show-move-to-message-bottom #'around-advice-disable-false)

;; But this one is called originally
;; (advice-add 'notmuch-show-previous-message :around #'around-advice-disable-false)
;; (advice-remove 'notmuch-show-previous-message #'around-advice-disable-false)

;; Not this one
;; (advice-add 'notmuch-show-rewind :around #'around-advice-disable-false)
;; (advice-remove 'notmuch-show-rewind #'around-advice-disable-false)

;; This ensures that the function does not change the
;; position of the point, or the scrolling of the visible window
(defun around-advice-save-excursion (proc &rest args)
  (let ((res
         (save-window-excursion
           (save-excursion
             (apply proc args)))))
    res))
(advice-add 'notmuch-show-imenu-prev-index-position-function :around #'around-advice-save-excursion)
;; (advice-remove 'notmuch-show-imenu-prev-index-position-function #'around-advice-save-excursion)

;; This is the problematic function - it isn't using save-excursion
;; (advice-add 'notmuch-show-imenu-prev-index-position-function :around #'around-advice-disable-false)
;; (advice-remove 'notmuch-show-imenu-prev-index-position-function #'around-advice-disable-false)


(defun nilfunc (&rest args)
  "Completely disabled function"
  (interactive)
  nil)

(defalias 'notmuch-query-get-threads 'nilfunc)
(defalias 'notmuch-query-map-threads 'nilfunc)

(define-key org-agenda-mode-map (kbd "C-c C-m") 'notmuch-search-agenda)

(defun push-button-around-advice (proc &optional pos use-mouse-action)
  (setq pos
        (or pos
            (point)))
  (let
      ((url
        (ignore-errors (get-text-property pos 'shr-url))))
    (if url
        (progn
          (goto-char pos)
          (eww-follow-link))
      (let
          ((res
            (apply proc
                   (list pos use-mouse-action))))
        res))))
(advice-add 'push-button :around #'push-button-around-advice)
;; (advice-remove 'push-button #'push-button-around-advice)

(provide 'pen-notmuch)
