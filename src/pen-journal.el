(require 'org-journal)
(require 'org-journal-tags)
(require 'org-journal-list)

;; a simple org-mode based journaling mode

(setq org-journal-dir (umn "$PEN/journal"))

;; Create new journal entry
;; mx:org-journal-new-entry

;; Open journal to current day
;; cumx:org-journal-new-entry

;; describe-package:org-journal


;; [[mx:cfw:open-diary-calendar]]

;; In calendar view: j m to mark entries in calendar
;;                   j r to view an entry in a new buffer
;;                   j d to view an entry but not switch to it
;;                   j n to add a new entry
;;                   j s w to search all entries of the current week
;;                   j s m to search all entries of the current month
;;                   j s y to search all entries of the current year
;;                   j s f to search all entries of all time
;;                   j s F to search all entries in the future
;;                   [ to go to previous entry
;;                   ] to go to next entry
;; When viewing a journal entry: C-c C-b to view previous entry
;;                               C-c C-f to view next entry

(provide 'pen-journal)
