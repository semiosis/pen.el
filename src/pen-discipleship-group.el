(defun d-group-memorize-scripture ()
  (interactive)
  (dired (umn "$PEN/documents/notes/ws/discipleship-group/memorization")))

(defun d-group-hear-journal ()
  (interactive)
  (dired (umn "$PEN/documents/notes/ws/discipleship-group/hear-journal")))

(defun d-group-hear-preparation ()
  (interactive)
  (dired (umn "$PEN/documents/notes/ws/discipleship-group/preparation")))

;; [[brain:agenda/Church::Discipleship group <2023-12-29 Fri 12:00 +1w>]]
(defun d-group-agenda ()
  (interactive)
  (org-link-open-from-string "[[brain:agenda/Church::Discipleship group <2023-12-29 Fri 12:00 +1w>]]"))

(provide 'pen-discipleship-group)
