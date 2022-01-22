;;; org-man.el - Support for links to google queries in Org

(require 'org)

;; org-add-link-type removes the google: from the start, I think

(org-add-link-type "google" 'org-g-open)
(org-add-link-type "goo" 'org-g-open)
(org-add-link-type "gl" 'org-g-open)
(org-add-link-type "gr" 'org-g-open)
(org-add-link-type "gg" 'org-g-open)
(add-hook 'org-store-link-functions 'org-g-store-link)

;; create a function, gr to open googler in a tmux split given search terms

;; vim +/"(defun my-google (&optional terms)" "$EMACSD/config/my-utils.2.el"
(defcustom org-g-command 'my-google
  "The Emacs command to be used to run a google search."
  :group 'org-link
  :type '(choice (const my-google) (const w3m)))

(defun org-g-open (terms)
  "Google search for something
TERMS should be a set of query terms that is passed to googler."
  (funcall org-g-command terms))

(defun org-g-store-link ()
  "Store a link to a google search."
  (when (memq major-mode '(eww-mode))
    ;; This is a google search page, we do make this link
    (let* ((terms (org-g-get-page-terms))
           (link (concat "google:" terms))
           (description (format "Google for %s" terms)))
      (org-store-link-props
       :type "google"
       :link link
       :description description))))

;; This is not necessary. It would get the google search title, but we
;; only need the terms for the desription

(defun org-g-get-page-terms ()
  "Extract the query from the buffer name. Not sure how to do this"
  (if (not nil)
      "google-search"
    (error "Cannot create link to this google search")))

(provide 'org-google)

;;; org-google.el ends here