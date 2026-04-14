(advice-add 'eldoc-print-current-symbol-info :around #'ignore-errors-around-advice)

;; TODO Consider adding this here
;; xterm-click -m 5 5
(defun pen-eldoc-display-docs-for-timer ()
  ;; (tv (message "yo"))
  ;; Move off the current cursor position, and then back on
  (when (or eldoc-mode
            (and global-eldoc-mode
                 (eldoc--supported-p)))
    ;; Don't ignore, but also don't full-on signal errors
    (with-demoted-errors "eldoc error: %s"
      (eldoc-print-current-symbol-info))))


(defset pen-mouse-moved-last-pos '())
(defun pen-simulate-mouse-moved-onto-cursor ()
  ;; (simulate-mouse-move 0 0)

  ;; This should only run for modes where it would be useful
  ;; Otherwise it can be annoying
  (if (major-mode-p 'sx-question-mode)
      (if (not (equal pen-mouse-moved-last-pos (pen-tty-cursor-pos)))
          (setq pen-mouse-moved-last-pos (simulate-mouse-move))
        (pen-message-no-echo "Not moving"))))

;; This will slow down emacs a tiny amount
(run-with-idle-timer
 0.3 t
 'pen-simulate-mouse-moved-onto-cursor)

;; (comment
;;  (run-with-idle-timer
;;   0.3 t
;;   'pen-simulate-mouse-moved-onto-cursor))

(defun eldoc-schedule-timer ()
  "Ensure `eldoc-timer' is running.

If the user has changed `eldoc-idle-delay', update the timer to
reflect the change."
  (or (and eldoc-timer
           (memq eldoc-timer timer-idle-list)) ;FIXME: Why?
      (setq eldoc-timer
            (run-with-idle-timer
	         eldoc-idle-delay nil
	         'pen-eldoc-display-docs-for-timer)))

  ;; If user has changed the idle delay, update the timer.
  (cond ((not (= eldoc-idle-delay eldoc-current-idle-delay))
         (setq eldoc-current-idle-delay eldoc-idle-delay)
         (timer-set-idle-time eldoc-timer eldoc-idle-delay t))))



(provide 'pen-eldoc)
