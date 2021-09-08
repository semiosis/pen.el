(defun tmux-pane-capture (&optional show-buffer)
  (interactive)
  ;; Rather than toggle window margins, remove the window margin width from the start of each line
  (let* ((margin-width (or (car (window-margins))
                           0))
         (wincontents (sn (concat "tm cap-pane -nohist | sed \"s/^.\\{" (str margin-width) "\\}//\""))))

    (if (or (interactive-p)
            show-buffer)
        (let ((frame (make-frame-command)
                     ;; termframe
                     ))
          (with-current-buffer (new-buffer-from-string wincontents)
            (defset-local termframe-local frame)
            (current-buffer)))
      wincontents)))

(provide 'my-tmux)