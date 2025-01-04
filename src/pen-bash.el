(require 'sh-script)
(require 'itail)

(defun bash-messages ()
  (interactive)
  ;; (comint-quick (pen-cmd "bash-messages" filter) user-home-directory)

  (itail (f-join user-home-directory "bash-messages.txt")
         0)
  ;; (sps (pen-cmd "bash-messages" filter))
  
  ;; (let ((shell-file-name "/bin/sh"))
  ;;   (start-process-shell-command
  ;;    "bash-messages" nil
  ;;    (pen-cmd "bash-messages" filter)))
  )

(defun insert-program (&optional initial-input)
  (interactive (list (str (thing-at-point 'symbol))))
  (insert (chomp (tpop (concat
                        (if (sor initial-input)
                            (cmd "slmenu" "-i" initial-input)
                          "slmenu")
                        " | cat") nil
                        :width_pc "50%"
                        :height_pc "50%"
                        :x_pos "M+1"
                        :y_pos "M+1"
                        :output_b t))))
(define-key sh-mode-map (kbd "M-0") 'insert-program)
(define-key sh-base-mode-map (kbd "M-0") 'insert-program)
(define-key eshell-mode-map (kbd "M-0") 'insert-program)

(defun bash-goto-excutable-on-path-at-point (&optional scriptname)
  (interactive (list (or (sor (pen-thing-at-point)) (read-string "Scriptname: "))))

  (let ((fp (executable-find scriptname)))
    (if
        (and fp
             (or
              (re-match-p "scripts/" fp)
              (yn (concat "Edit " (e/q (mnm fp))))))
        ;; (pen-edit-fp-on-path scriptname)
        (e fp))))

(provide 'pen-bash)
