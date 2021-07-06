(require 'org-brain)
(require 'pen-support)

(defun org-brain-current-brain ()
  (f-base org-brain-path))

(defun org-brain-parent-name ()
  (mapconcat 'identity
             (org-brain-remove-irrelevant-names-from-path
              (mapcar
               'org-brain-name-from-list-maybe
               (org-brain-parents org-brain--vis-entry)))
             " "))

(defun org-brain-is-index-name (s)
  (or (string-equal s "index")
      (string-equal s "reference")))

(defun org-brain-pf-topic (&optional short)
  "Topic used for pen functions"
  (let ((cn (org-brain-current-name t)))
    (if (and (org-brain-is-index-name cn)
             (not (sor (org-brain-parent-name))))
        (if (org-brain-is-index-name (org-brain-current-brain))
            "general knowledge"
          (org-brain-current-brain))
      (let ((p (org-brain-parent-name)))
        (if (and (sor p)
                 (not short)
                 (not (org-brain-is-index-name p)))
            (concat cn " (" cn " is a subtopic of " p ")")
          cn)))))

;; TODO
;; j:org-brain-asktutor

(provide 'pen-brain)