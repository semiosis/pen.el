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
(add-to-list 'universal-sidecar-sections 'elfeed-score-section)

;; However, if we want the opposite behavior (don't show renames),
;; we'd configure it as shown below.
;; (add-to-list 'universal-sidecar-sections '(buffer-git-status :show-renames t))

;; (add-to-list 'universal-sidecar-sections
;;              '(universal-sidecar-roam-section org-roam-backlinks-section))

(provide 'pen-universal-sidecar)
