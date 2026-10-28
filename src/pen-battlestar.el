(defun battlestar ()
  (interactive)
  (comint-quick "rl battlestar" user-home-directory))

;; e:rl

(defun edit-battlestar-command-history ()
  (interactive)
  (ff (snc "rl -get-rl-histfile battlestar")))

(defun pen-comint--battlestar--score ()
  (interactive)
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (end-of-buffer)
    (insert "score")
    (comint-send-input)))

(defun pen-comint--battlestar--inven ()
  (interactive)
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (end-of-buffer)
    (insert "inven")
    (comint-send-input)))

(defun pen-comint--battlestar--save ()
  (interactive)
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (end-of-buffer)
    (insert "save")
    (comint-send-input)
    (insert (read-string-hist "Battlestar savegame name: " "test.Bstar"))
    (comint-send-input)))

(defun pen-comint--battlestar--drop ()
  (interactive)
  (pen-comint--battlestar--inven)
  ;; Need this sleep to get the output.
  ;; But I should be using an "expect" system.
  (sleep 0.5)
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (let* ((bufstring (buffer-string))
           (items (-filter-not-empty-string (str2lines (snc "battlestar--scrape-inventory" bufstring))))
           (item (if items
                     (fz items nil nil "Drop item: "))))
      (if item
          (progn
            (end-of-buffer)
            (insert (format "drop %s" item))
            (comint-send-input))
        (message "You aren't carrying anything"))
      ;; (insert (read-string-hist "Battlestar savegame name: " "test.Bstar"))
      ;; (comint-send-input)
      )))

(provide 'pen-battlestar)
