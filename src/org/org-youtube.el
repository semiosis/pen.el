;;; org-man.el - Support for links to youtube queries in Org

(require 'org)

;; org-add-link-type removes the youtube: from the start, I think

(org-add-link-type "youtube" 'org-yt-open)
(org-add-link-type "yt" 'org-yt-open)
(add-hook 'org-store-link-functions 'org-yt-store-link)

;; create a function, gr to open youtuber in a tmux split given search terms

;; vim +/"(defun my-youtube (&optional terms)" "$EMACSD/config/my-utils.2.el"
(defcustom org-yt-command 'my-youtube
  "The Emacs command to be used to run a youtube search."
  :group 'org-link
  :type '(choice (const my-youtube) (const w3m)))

(defun org-yt-open (terms)
  "Youtube search for something
TERMS should be a set of query terms that is passed to youtuber."
  (funcall org-yt-command terms))

(defun org-yt-store-link ()
  "Store a link to a youtube search."
  (when (memq major-mode '(eww-mode))
    ;; This is a youtube search page, we do make this link
    (let* ((terms (org-yt-get-page-terms))
           (link (concat "youtube:" terms))
           (description (format "YouTube search for %s" terms)))
      (org-store-link-props
       :type "youtube"
       :link link
       :description description))))

;; This is not necessary. It would get the youtube search title, but we
;; only need the terms for the desription

(defun org-yt-get-page-terms ()
  "Extract the query from the buffer name. Not sure how to do this"
  (if (not nil)
      "youtube-search"
    (error "Cannot create link to this youtube search")))

(provide 'org-youtube)

;;; org-youtube.el ends here