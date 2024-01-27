(require 'timeout)

(defun timeout-unthrottle! (func)
  (timeout-throttle! func 0))

;; This function may run at most once every 2 seconds.
;; It also memoizes, which is good.
(timeout-throttle! 'ph-get-path-string 2.0)
(timeout-throttle! 'pen-compose-mode-line 1.0)
(timeout-throttle! 'pen-redraw-glossary-buttons-when-window-scrolls-or-file-is-opened 2.0)
(timeout-throttle! 'git-gutter+-refresh 2.0)

(comment
 (timeout-throttle! 'git-gutter+-refresh 2.0)
 (timeout-unthrottle! 'git-gutter+-refresh))

(comment
 (defun test-throttle-fun ()
   (message (vime "strftime(\"%c\")")))
 (timeout-throttle! 'test-throttle-fun 2.0)
 (test-throttle-fun))

(provide 'pen-timeout)
