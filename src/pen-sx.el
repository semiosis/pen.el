(require 'sx)
;; for sx-question-mode-map and other symbols
(require 'sx-time)
(require 'my-lists)
(require 'sx-compose)
(require 'sx-favorites)
(require 'sx-auth)
(require 'sx-user)
(require 'sx-site)
(require 'sx-load)
(require 'sx-button)
(require 'sx-interaction)
(require 'sx-question-list)
(require 'sx-tag)
(require 'sx-method)
(require 'sx-encoding)
(require 'sx-tab)
(require 'sx-question-print)
(require 'sx-notify)
(require 'sx-cache)
(require 'sx-filter)
(require 'sx-search)
(require 'sx-request)
(require 'sx-switchto)
(require 'sx-question)
(require 'sx-inbox)
(require 'sx-networks)
(require 'sx-babel)
(require 'sx-question-mode)

(defun sx-get-url-from-query (query)
  ;; The grep -v is to remove non-english sites
  (fz (or (-filter-not-empty-string (pen-str2lines (pen-sn (concat "gl " (pen-q query) " | grep -P \"(stackoverflow|stackexchange|serverfault).*/questions/[0-9]\" | grep -v \"\\\\.stackoverflow.com\""))))
              (-filter-not-empty-string (pen-str2lines (pen-sn (concat "gl stackoverflow " (pen-q query) " | grep -P \"(stackoverflow|stackexchange|serverfault).*/questions/[0-9]\" | grep -v \"\\\\.stackoverflow.com\"")))))
      nil nil (concat "sx " query ": ") nil t))

;; TODO Make this function use sx-get-appropriate-site-and-id-from-url
(defun sx-get-appropriate-site-and-id (query)
  (let* ((site (sx-get-url-from-query query))
         (question (s-replace-regexp ".*//[^/]+/\\(questions\\|q\\)/[0-9]+/\\([a-z0-9-]+\\).*" "\\2" site))
         (id (s-replace-regexp ".*//[^/]+/\\(questions\\|q\\)/\\([0-9]+\\)" "\\2" site))
         (allsxsites (sx-site-get-api-tokens))
         (suggested
          (cond ((string-match-p "stackoverflow.com" site)
                 "stackoverflow")
                ((string-match-p "serverfault.com" site)
                 "serverfault")
                ((string-match-p "superuser.com" site)
                 "superuser")
                ((string-match-p ".stackexchange.com" site)
                 (s-replace-regexp (concat "^.*//\\([^.]+\\).*") "\\1" site))
                (t
                 "stackoverflow"))))
    (if (string-match-p "/" question)
        (setq question nil))
    ;; Ensure that it's inside allsxsites
    (if (-contains? allsxsites suggested)
        (list suggested question id)
      (list "stackoverflow" query id))))

(defun sx-get-appropriate-site-and-id-from-url (url)
  (let* ((question (s-replace-regexp ".*//[^/]+/\\(questions\\|q\\)/[0-9]+/\\([a-z0-9-]+\\).*" "\\2" url))
         (id (s-replace-regexp ".*//[^/]+/\\(questions\\|q\\)/\\([0-9]+\\)" "\\2" url))
         (allsxsites (sx-site-get-api-tokens))
         (suggested
          (cond ((string-match-p "stackoverflwo.com" url)
                 "stackoverflow")
                ((string-match-p "serverfault.com" url)
                 "serverfault")
                ((string-match-p "superuser.com" url)
                 "superuser")
                ((string-match-p ".stackexchange.com" url)
                 (s-replace-regexp (concat "^.*//\\([^.]+\\).*") "\\1" url))
                (t
                 "stackoverflow"))))
    (if (string-match-p "/" question)
        (setq question nil))
    (if (-contains? allsxsites suggested)
        (list suggested question id))))

(defun sx-search-quickly (query)
  (interactive (list (selection)))
  (cl-multiple-value-bind (site question id)
      (sx-get-appropriate-site-and-id query)

    (sx-display-question (sx-question-get-question site (string-to-number id)))
    (delete-other-windows)))

(defun sx-search-lang (query)
  (interactive
   (let* ((l (guess-lang-for-search
              "sx lang: "))
          (sel (selection))
          (cand
           (cond
            ((and (sor sel) (sor l)) (concat sel " " l))
            ((sor sel) sel)
            ((sor l) (concat l " "))
            (t ""))))
     (list
      (read-string-hist
       "sx query: "
       cand))))
  (sx-search-quickly query))

(defun sx-search-immediately-lang (query)
  (interactive
   (let* ((l (guess-lang-for-search
              "sx lang: "))
          (sel (selection))
          (cand
           (cond
            ((and (sor sel) (sor l)) (concat sel " " l))
            ((sor sel) sel)
            ((sor l) (concat l " "))
            (t ""))))
     (list
      (if (not (sor cand))
          (read-string-hist
           "sx query: "
           cand)
        cand))))
  (sx-search-quickly query))


;; (sx-from-url "https://stackoverflow.com/q/4980146")
;; (sx-from-url "https://stackoverflow.com/questions/4980146/how-can-i-combine-a-switch-case-and-regex-in-python")
;; (sx-get-appropriate-site-and-id-from-url "https://stackoverflow.com/q/4980146")

(defun sx-from-url (url)
  (interactive (list (read-string-hist "sx url: " (thing-at-point 'url))))
  (if (re-match-p "/a/[0-9]" url)
      (setq url (chomp (pen-sn "fi-curl-get-redirect-maybe" url))))
  (if (and (not (re-match-p "^https?://" url))
           (re-match-p "^[a-z]" url))
      (setq url (concat "^http://" url)))
  (cl-multiple-value-bind (site question id)
      (sx-get-appropriate-site-and-id-from-url url)
    (sx-display-question (sx-question-get-question site (string-to-number id)))
    (delete-other-windows)))

(define-key global-map (kbd "H-K") 'sx-search-quickly)
(define-key global-map (kbd "H-k") 'sx-search-lang)

(define-key sx-question-mode-map (kbd "<up>") 'previous-line-nonvisual)
(define-key sx-question-mode-map (kbd "<down>") 'next-line-nonvisual)

(defsetface sx-question-mode-code-block-face
  '((t :foreground "#3f5fa7"
       :background "#2e2e2e"
       :weight bold
       :underline nil))
  "Face for sx code block buttons.")

(define-button-type 'sx-question-mode-code-block
  'action    #'sx-button-edit-this
  'face      'sx-question-mode-code-block-face
  ;; This will disable mouse clicks opening the code blocks in sx 
  'mouse-action 'identity
  :supertype 'sx-button)

(defun sx-get-question-url ()
  (if (major-mode-p 'sx-question-mode)
      (let ((current-prefix-arg nil))
        (save-excursion
          (beginning-of-buffer)
          (call-interactively 'forward-button)
          (get-text-property (point) 'sx-button-copy)
          ;; (call-interactively 'sx-button-copy)
          ))))

(defun sx-copy-question-url ()
  (interactive)
  (xc (sx-get-question-url)))

(define-key sx-question-mode-map (kbd "w") 'sx-copy-question-url)

(defun sx-button-copy-around-advice (proc &rest args)
  (if (and (>= (prefix-numeric-value current-prefix-arg) 4)
           (major-mode-p 'sx-question-mode))
      (sx-copy-question-url)
      (let ((res (apply proc args)))
        res)))
(advice-add 'sx-button-copy :around #'sx-button-copy-around-advice)

(defun sx-move-to-accepted-answer ()
  (interactive)
  (if (string-match "^Accepted Answer$" (buffer-string))
      (progn
        (re-search-forward "^Accepted Answer$")
        (beginning-of-line))))

(defun sx-button-edit-this (text-or-marker &optional majormode)
  "Open a temp buffer populated with the string TEXT-OR-MARKER using MAJORMODE.
When given a marker (or interactively), use the 'sx-button-copy
and the 'sx-mode text-properties under the marker. These are
usually part of a code-block."
  (interactive (list (point-marker)))
  ;; Buttons receive markers.
  (when (markerp text-or-marker)
    (setq majormode (get-text-property text-or-marker 'sx-mode))
    (unless (setq text-or-marker
                  (get-text-property text-or-marker 'sx-button-copy))
      (sx-message "Nothing of interest here.")))
  (with-current-buffer (pop-to-buffer-same-window (generate-new-buffer
                                                   "*sx temp buffer*"))
    (insert text-or-marker)
    (if majormode
        (funcall majormode)
      (detect-language-set-mode))))

(defvar sx-question-mode--erase-and-print-question-after-hook '())
(defun sx-question-mode--erase-and-print-question-after-advice (&rest args)
  (run-hooks 'sx-question-mode--erase-and-print-question-after-hook))
(advice-add 'sx-question-mode--erase-and-print-question :after 'sx-question-mode--erase-and-print-question-after-advice)
(add-hook 'sx-question-mode--erase-and-print-question-after-hook 'run-buttonize-hooks)
(add-hook 'sx-question-mode--erase-and-print-question-after-hook 'sx-move-to-accepted-answer)

(define-key sx-question-mode-map (kbd "M-G") 'sx-google-instead)

(setq sx-question-mode-display-buffer-function 'pop-to-buffer)
(setq sx-question-mode-display-buffer-function 'pop-to-buffer-same-window)





(defun pen-sx-explain-error ()
  (interactive)
  (let ((error (lsp-ui-pen-diagnostics)))
    (if (sor error)
        (sx-search-lang error))))


(provide 'pen-sx)