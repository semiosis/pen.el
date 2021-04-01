(defun pen-topic (&optional short)
  "Determine the topic used for pen functions"
  (interactive)

  (let ((topic
         (cond ((major-mode-p 'org-brain-visualize-mode)
                (progn (require 'my-org-brain)
                       (org-brain-pf-topic short)))
               (t
                (let ((current-prefix-arg '(4))) ; C-u
                  ;; Consider getting topic keywords from visible text
                  (get-path))))))
    (if (interactive-p)
        (etv topic)
      topic)))

(defun pen-broader-topic ()
  "Determine the topic used for pen functions"
  (interactive)

  (let ((topic
         (cond ((major-mode-p 'org-brain-visualize-mode)
                (progn (require 'my-org-brain)
                       (org-brain-pf-topic short)))
               (t
                (let ((current-prefix-arg '(4))) ; C-u
                  (get-path))))))
    (if (interactive-p)
        (etv topic)
      topic)))

(provide 'pen-library)