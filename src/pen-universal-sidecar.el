(require 'universal-sidecar)
(require 'universal-sidecar-roam)
(require 'universal-sidecar-elfeed-score)
(require 'universal-sidecar-elfeed-related)

;; This sidecar thing just doesn't seem to work very well

;; I should probably use shackle instead
(add-to-list 'display-buffer-alist
             '("\\*sidecar\\*"
               (display-buffer-in-side-window)
               (slot . 0)
               (window-width . 0.2)
               (window-height . 0.2)
               (preserve-size t . t)
               (window-parameters . ((no-other-window . t)
                                     (no-delete-other-windows . t)))))

(setq universal-sidecar-buffer-name-format
      '"*sidecar* (%F)")

;; This is to make it work inside a terminal as well
(defun universal-sidecar-get-name (&optional frame)
  "Get the name of the sidecar buffer for FRAME.

If FRAME is nil, use `selected-frame'."
  (let* ((frame (or frame (selected-frame)))
         (id (frame-parameter frame 'window-id))
         (client (frame-parameter frame 'client)))
    ;; (tv (frame-parameters frame))
    (format-spec universal-sidecar-buffer-name-format (list (cons ?F
                                                                  (or id
                                                                      client))))))

(add-to-list 'universal-sidecar-sections 'buffer-git-status)
(remove-from-list 'universal-sidecar-sections 'buffer-git-status)
(add-to-list 'universal-sidecar-sections 'elfeed-score-section)
(remove-from-list 'universal-sidecar-sections 'elfeed-score-section)

(universal-sidecar-define-section fortune-section (file title)
                                  (:major-modes org-mode
                                   :predicate (not (buffer-modified-p)))
  (let ((title (or title
                   (and file
                        (format "Fortune: %s" file))
                   "Fortune"))
        (fortune (shell-command-to-string (format "fortune%s"
                                                  (if file
                                                      (format " %s" file)
                                                    "")))))
    (universal-sidecar-insert-section fortune-section title
      (insert fortune))))

;; (add-to-list 'universal-sidecar-sections 'fortune-section)
;; (add-to-list 'universal-sidecar-sections '(fortune-section :file "definitions"))
(add-to-list 'universal-sidecar-sections '(fortune-section :title "O Fortuna!"))
;; (add-to-list 'universal-sidecar-sections '(fortune-section :file "definitions" :title "Random Definition"))

;; However, if we want the opposite behavior (don't show renames),
;; we'd configure it as shown below.
;; (add-to-list 'universal-sidecar-sections '(buffer-git-status :show-renames t))

;; (add-to-list 'universal-sidecar-sections
;;              '(universal-sidecar-roam-section org-roam-backlinks-section))

(comment
 (universal-sidecar-fontify-as org-mode ((org-fold-core-style 'overlays))
   (some-function-that-generates-org-text)
   (some-post-processing-of-org-text)))

(provide 'pen-universal-sidecar)
