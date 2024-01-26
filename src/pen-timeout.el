(require 'timeout)

;; This function may run at most once every 2 seconds.
;; It also memoizes, which is good.
(timeout-throttle! 'ph-get-path-string 2.0)

(comment
 (defun test-throttle-fun ()
   (message (vime "strftime(\"%c\")")))
 (timeout-throttle! 'test-throttle-fun 2.0)
 (test-throttle-fun))

(provide 'pen-timeout)
