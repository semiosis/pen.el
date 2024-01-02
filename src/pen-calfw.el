(require 'calfw)
(require 'calfw-org)
(require 'calfw-ical)
;; (require 'calfw-howm)
(require 'calfw-gcal)
(require 'calfw-cal)

;; M-x cfw:open-calendar-buffer

;; I changed it slightly to return the buffer, so I can do this:
;; calr | cat
(defun cfw:open-org-calendar ()
  "Open an org schedule calendar in the new buffer."
  (interactive)
  (save-excursion
    (let* ((source1 (cfw:org-create-source))
           (curr-keymap (if cfw:org-overwrite-default-keybinding cfw:org-custom-map cfw:org-schedule-map))
           (cp (cfw:create-calendar-component-buffer
                :view 'month
                :contents-sources (list source1)
                :custom-map curr-keymap
                :sorter 'cfw:org-schedule-sorter))
           (b (cfw:cp-get-buffer cp)))
      (switch-to-buffer b)
      (when (not org-todo-keywords-for-agenda)
        (message "Warn : open org-agenda buffer first."))
      b)))


(defalias 'cfw-agenda 'cfw:open-org-calendar)

(provide 'pen-calfw)
