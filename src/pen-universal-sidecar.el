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

;; redisplay-unhighlight-region-function

(universal-sidecar-define-section demo-section (file title)
                                  (
                                   ;; :major-modes org-mode
                                   ;; :predicate (not (buffer-modified-p))
                                   )
  (let ((title (or title
                   (and file
                        (format "Demo: %s" file))
                   "Demo"))
        (cmdout (shell-command-to-string "echo hi")))
    (universal-sidecar-insert-section demo-section title
      (insert cmdout))))

;; (add-to-list 'universal-sidecar-sections 'demo-section)
;; (add-to-list 'universal-sidecar-sections '(demo-section :file "definitions"))
(add-to-list 'universal-sidecar-sections '(demo-section :title "O Demo!"))
;; (add-to-list 'universal-sidecar-sections '(demo-section :file "definitions" :title "Random Definition"))

;; However, if we want the opposite behavior (don't show renames),
;; we'd configure it as shown below.
;; (add-to-list 'universal-sidecar-sections '(buffer-git-status :show-renames t))

;; (add-to-list 'universal-sidecar-sections
;;              '(universal-sidecar-roam-section org-roam-backlinks-section))

(comment
 (universal-sidecar-fontify-as org-mode ((org-fold-core-style 'overlays))
   (some-function-that-generates-org-text)
   (some-post-processing-of-org-text)))

;; (setq-local redisplay-highlight-region-function
;;               #'magit-section--highlight-region)
;; (setq-local redisplay-unhighlight-region-function
;;               #'magit-section--unhighlight-region)

;; For some reason, these were being run in universal sidecar - magit itself set it
;; That's because universal-sidecar uses magit-section
;; (advice-add 'magit-section--highlight-region :around #'ignore-errors-around-advice)
;; (advice-add 'magit-section--unhighlight-region :around #'ignore-errors-around-advice)

;; (advice-add 'magit-diff-update-hunk-region :around #'ignore-errors-around-advice)
;; (advice-remove 'magit-diff-update-hunk-region #'ignore-errors-around-advice)

;; Well, this was breaking
;; (advice-add 'magit-diff-update-hunk-region :around #'ignore-errors-around-advice)
;; (advice-remove 'magit-diff-update-hunk-region #'ignore-errors-around-advice)

;; (universal-sidecar-insinuate)
;; (universal-sidecar-uninsinuate)

(provide 'pen-universal-sidecar)