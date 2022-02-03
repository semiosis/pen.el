(defun pen-list-os ()
  (interactive)
  (ilist 20 "distinctive linux distributions including nixos"))

(defun sps-nlsc (os)
  (interactive (list (pen-detect-language-ask)))
  ;; (pen-sps (pen-cmd "pen-eterm" "nlsc" "-nd" os))
  (pen-sps (pen-cmd "nlsc" os)))

(defun sps-nlsh (os)
  (interactive (list (fz (pen-list-os)
                         nil nil "sps-nlsh OS: ")))
  ;; (pen-sps (pen-cmd "pen-eterm" "nlsh" "-nd" os))
  (pen-sps (pen-cmd "nlsh" os)))

(provide 'pen-nlsh)