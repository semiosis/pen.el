(require 'org)

(org-add-link-type "man" 'org-man-open)
(add-hook 'org-store-link-functions 'org-man-store-link)

(defcustom org-man-command 'man
  "The Emacs command to be used to display a man page."
  :group 'org-link
  :type '(choice (const man) (const woman)))

;; [[sps:cd "$PENCONF/documents/notes"; /usr/bin/man 3 printf]]
;; [[el:(man "printf(3)")]]
;; man:m4
;; [[man:printf 3]] - doesn't work -- good
;; [[man:3 printf]] - is correct

(defun org-man-open (path &rest args)
  "Visit the manpage on PATH.
PATH should be a topic that can be thrown at the man command."
  (eval `(apply org-man-command path ,@args)))

(defun org-man-store-link ()
  "Store a link to a manpage."
  (when (memq major-mode '(Man-mode woman-mode))
    ;; This is a man page, we do make this link
    (let* ((page (org-man-get-page-name))
           (link (concat "man:" page))
           (description (format "Manpage for %s" page)))
      (org-store-link-props
       :type "man"
       :link link
       :description description))))

(defun org-man-get-page-name ()
  "Extract the page name from the buffer name."
  ;; This works for both `Man-mode' and `woman-mode'.
  (if (string-match " \\(\\S-+\\)\\*" (buffer-name))
      (match-string 1 (buffer-name))
    (error "Cannot create link to this man page")))

(provide 'pen-org-man)
