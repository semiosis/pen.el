(defun pen-list-os ()
  (interactive)
  (ilist 20 "distinctive linux distributions including nixos"))

(defun pen-list-generic-os-types ()
  (interactive)
  (ilist 20 "operating systems (including linux, mac, windows)"))

(defun sps-nlsc (os)
  (interactive (list (pen-detect-language-ask)))
  ;; (pen-sps (pen-cmd "pen-eterm" "nlsc" "-nd" os))
  (pen-sps (pen-cmd "nlsc" os)))

(defun sps-nlsh (os)
  (interactive (list (fz (pen-list-os)
                         nil nil "sps-nlsh OS: ")))
  ;; (pen-sps (pen-cmd "pen-eterm" "nlsh" "-nd" os))
  (pen-sps (pen-cmd "nlsh" os)))

;; Automate the entry of first query.
;; Use expect for this.
;; The only trouble with expect around emacs is wide-chars.
(defun sps-nlsu (&optional context query)
  (interactive (list (fz (pen-list-os)
                         nil nil "sps-nlsu context: ")
                     (if (pen-selected-p)
                         (pen-selection))))
  ;; (pen-sps (pen-cmd "pen-eterm" "nlsu" "-nd" context))

  (if query
      (pen-sps (pen-cmd "nlsu" context))))

(defun sps-nlq ()
  (interactive)
  ;; (pen-sps (pen-cmd "pen-eterm" "nlsh" "-nd" os))
  (pen-sps (pen-cmd "nlq")))
(defalias 'nlq 'sps-nlq)

(provide 'pen-nlsh)
