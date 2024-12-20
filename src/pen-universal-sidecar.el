(require 'universal-sidecar)
(require 'universal-sidecar-roam)
(require 'universal-sidecar-elfeed-score)
(require 'universal-sidecar-elfeed-related)

;; This sidecar thing just doesn't seem to work very well

;; I should probably use shackle instead
;; Yes, definitely use shackle. Magit log seems to mess with this method
(comment
 (add-to-list 'display-buffer-alist
              '("\\*sidecar\\*"
                (display-buffer-in-side-window)
                (slot . 0)
                (window-width . 0.2)
                (window-height . 0.2)
                (preserve-size t . t)
                (window-parameters . ((no-other-window . t)
                                      (no-delete-other-windows . t))))))
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


    ;; TODO Fix this properly
    (or
    (ignore-errors
      (format-spec universal-sidecar-buffer-name-format (list (cons ?F (or id client)))))
    ""))
    )

(add-to-list 'universal-sidecar-sections 'buffer-git-status)
(remove-from-list 'universal-sidecar-sections 'buffer-git-status)
(add-to-list 'universal-sidecar-sections 'elfeed-score-section)
(remove-from-list 'universal-sidecar-sections 'elfeed-score-section)

;; redisplay-unhighlight-region-function

(universal-sidecar-define-section quote-section (file title)
                                  (
                                   ;; :major-modes org-mode
                                   ;; :predicate (not (buffer-modified-p))
                                   )
  (let ((title (or title
                   (and file
                        (format "Demo: %s" file))
                   "Demo"))
        (quote (seq-random-elt (str2lines (e/cat "$PEN/documents/quotes.txt"))))
        ;; (cmdout (shell-command-to-string "pwd"))
        )
    (universal-sidecar-insert-section quote-section title
      (insert quote)

      ;;;; This has problems currently, asking if I want to kill the temp buffer
      ;; (insert
      ;;  (universal-sidecar-fontify-as org-mode ((org-fold-core-style 'overlays))
      ;;    ;; This is inserted
      ;;    (concat "[[sh:tpop vim /]]")
      ;;    ;; This runs after the above
      ;;    (comment (some-post-processing-of-org-text))))
      )))

;; This appears to be running twice in a row every time the sidecar is opened - fix it.
;; Also, when clicking on buttons in the sidecar,
;; if the button made a tmux popup, the popup was closed because the spinner appeared
(defun sidecar-get-cross-references-for-ref (ref)
  ;; (snc "spin -m verse-xrefs in-pen bible-get-cross-references -olol" ref)
  (snc "in-pen bible-get-cross-references -olol" ref))

(universal-sidecar-define-section bible-section (file title)
                                  (
                                   :major-modes bible-mode
                                                ;; :predicate (not (buffer-modified-p))
                                   )
  (ignore-errors (let* ((ref-tuple (with-current-buffer buffer bible-mode-ref-tuple))
                        (ref (concat (car ref-tuple) " " (cadr ref-tuple) ":" (caddr ref-tuple)))
                        (title (concat ref " cross-references:"))
                        (crossrefs (sidecar-get-cross-references-for-ref ref))
                        (cmdout (shell-command-to-string "pwd")))
                   (universal-sidecar-insert-section bible-section title
                     (insert
                      (universal-sidecar-fontify-as org-mode ((org-fold-core-style 'overlays))
                        ;; This is inserted
                        crossrefs
                        ;; This runs after the above
                        (org-verse-buttonize-buffer)
                        (comment (some-post-processing-of-org-text))))))))

;; Fix this
(comment
 (universal-sidecar-fontify-as org-mode ((org-fold-core-style 'overlays))
   "Hello"
   ;; This runs after the above
   (comment (some-post-processing-of-org-text))))

;; (add-to-list 'universal-sidecar-sections 'quote-section)
;; (add-to-list 'universal-sidecar-sections '(quote-section :file "definitions"))
(add-to-list 'universal-sidecar-sections '(quote-section :title "Quote!"))
(add-to-list 'universal-sidecar-sections '(bible-section :title "Bible!"))
;; (remove-from-list 'universal-sidecar-sections '(bible-section :title "Bible!"))
;; (add-to-list 'universal-sidecar-sections '(quote-section :file "definitions" :title "Random Definition"))

;; However, if we want the opposite behavior (don't show renames),
;; we'd configure it as shown below.
;; (add-to-list 'universal-sidecar-sections '(buffer-git-status :show-renames t))

;; (add-to-list 'universal-sidecar-sections
;;              '(universal-sidecar-roam-section org-roam-backlinks-section))



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

(universal-sidecar-insinuate)
;; This sometimes makes it lag a lot
(comment
 (universal-sidecar-insinuate)
 (universal-sidecar-uninsinuate))


(defun universal-sidecar-on ()
  (interactive)
  (if (not (universal-sidecar-visible-p))
      (universal-sidecar-toggle)))

(defun universal-sidecar-off ()
  (interactive)
  (if (universal-sidecar-visible-p)
      (universal-sidecar-toggle)))

;; [2024-01-24T09:34:24.430461] Error running timer ‘universal-sidecar-refresh-all’: (error "Invalid format character: ‘%F’")
(advice-add 'universal-sidecar-refresh-all :around #'ignore-errors-around-advice)

(provide 'pen-universal-sidecar)
