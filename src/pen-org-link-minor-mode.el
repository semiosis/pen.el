(define-minor-mode org-link-minor-mode
  "Toggle display of org-mode style bracket links in non-org-mode buffers."
  :lighter " org-link"
  :keymap org-link-minor-mode-map
  (let ((lk org-highlight-links)
        org-link-minor-mode-keywords)
    (if (fboundp 'org-activate-links)
        ;; from Org v9.2
        (setq org-link-minor-mode-keywords
              (list
               '(org-activate-links)
               (when (memq 'tag lk) '(org-activate-tags (1 'org-tag prepend)))
               (when (memq 'radio lk) '(org-activate-target-links (1 'org-link t)))
               (when (memq 'date lk) '(org-activate-dates (0 'org-date t)))
               (when (memq 'footnote lk) '(org-activate-footnote-links))))
      (setq org-link-minor-mode-keywords
            (list
             (if (memq 'tag lk) '(org-activate-tags (1 'org-tag prepend)))
             (if (memq 'angle lk) '(org-activate-angle-links (0 'org-link t)))
             (if (memq 'plain lk) '(org-activate-plain-links (0 'org-link t)))
             (if (memq 'bracket lk) '(org-activate-bracket-links (0 'org-link t)))
             (if (memq 'radio lk) '(org-activate-target-links (0 'org-link t)))
             (if (memq 'date lk) '(org-activate-dates (0 'org-date t)))
             (if (memq 'footnote lk) '(org-activate-footnote-links)))))
    (if org-link-minor-mode
        (if (derived-mode-p 'org-mode)
            (progn
              (message "org-mode doesn't need org-link-minor-mode")
              (org-link-minor-mode -1))
          (progn
            (font-lock-add-keywords nil org-link-minor-mode-keywords t)
            (kill-local-variable 'org-mouse-map)
            (setq-local org-mouse-map
                        (let ((map (make-sparse-keymap)))
                          (define-key map [return] 'org-open-at-point)
                          (define-key map [tab] 'org-next-link)
                          (define-key map [backtab] 'org-previous-link)
                          (define-key map [mouse-2] 'org-open-at-point)
                          (define-key map [follow-link] 'mouse-face)
                          map))
            (setq-local font-lock-unfontify-region-function
                        'org-link-minor-mode-unfontify-region)
            (setq-local org-descriptive-links org-descriptive-links)
            (condition-case nil (require 'org-man)
              (error (message "Problems while trying to load feature `org-man'")))
            ;; Set to non-descriptive and then switch to descriptive links
            (setq org-descriptive-links nil)
            (org-toggle-link-display)))
      (unless (derived-mode-p 'org-mode)
        (font-lock-remove-keywords nil org-link-minor-mode-keywords)
        (org-restart-font-lock)
        ;; (remove-from-invisibility-spec '(org-link))
        (kill-local-variable 'org-descriptive-links)
        (kill-local-variable 'org-mouse-map)
        (kill-local-variable 'font-lock-unfontify-region-function)))))
