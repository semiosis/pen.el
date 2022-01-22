;;; org-rifle.el - Support for opening a path with rifle

(require 'org)


(org-add-link-type "rifle" 'org-rifle-open)
(add-hook 'org-store-link-functions 'org-rifle-store-link)


(defcustom org-rifle-command 'spv-rifle
  "The Emacs command to be used to display a rifle page."
  :group 'org-link
  :type '(choice (const spv-rifle)))

(setq org-rifle-command 'spv-rifle)

(defun org-rifle-open (path)
  "Visit the manpage on PATH.
PATH should be a topic that can be thrown at the rifle command."
  (funcall org-rifle-command path))

(defun org-rifle-store-link ()
  "Store a link to a manpage."
  (when (memq major-mode '(Rifle-mode woman-mode))
    ;; This is a rifle page, we do make this link
    (let* ((page (org-rifle-get-page-name))
           (link (concat "rifle:" page))
           (description (format "rifle %s" page)))
      (org-store-link-props
       :type "rifle"
       :link link
       :description description))))


(defun org-rifle-get-page-name ()
  "Extract the page name from the buffer name."
  ;; This works for both `Rifle-mode' and `woman-mode'.
  (if (string-match " \\(\\S-+\\)\\*" (buffer-name))
      (match-string 1 (buffer-name))
    (error "Cannot create link to this rifle page")))

(provide 'org-rifle)

;;; org-rifle.el ends here
