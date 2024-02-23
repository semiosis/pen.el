;;; pen-timeout.el --- throttle or debounce elisp functions  -*- lexical-binding: t; -*-

;; Lexical binding is needed:
;; Therefore, to reload: mx:pen-reload-config-file

(require 'timeout)

(defun timeout-unthrottle! (func)
  (timeout-throttle! func 0))

;; This function may run at most once every 2 seconds.
;; It also memoizes, which is good.
;; Throttling this is great, but it's no longer strictly buffer-specific.
;; I need to throttle/cache per-buffer. Per-buffer debounce memoization.
;; OK, so just throw away the value and don't update the buffer, if it bounces, rather than taking the value.
(comment
 (timeout-throttle! 'ph-get-path-string 0.5)
 (timeout-unthrottle! 'ph-get-path-string))

(comment
 (timeout-nil-throttle! 'ph-get-path-string 0.5)
 (timeout-nil-unthrottle! 'ph-get-path-string))

;; DONE ensure this works the same as timeout-throttle!
;; TODO add arg which buffer ph-get-path-string should refer to
(timeout-memo-throttle! 'ph-get-path-string-for-buf 0.5)
(comment
 (timeout-memo-unthrottle! 'ph-get-path-string-for-buf))

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


(defun timeout-nil--throttle-advice (&optional timeout)
  "Return a function that throttles its argument function.

TIMEOUT defaults to 1.0 seconds.  This is intended for use as
function advice.

It will return nil if a timer already exists
"
  (let ((throttle-timer)
        (timeout (or timeout 1.0))
        (result))
    (lambda (orig-fn &rest args)
      "Throttle calls to this function."
      (if (timerp throttle-timer)
          nil
        (prog1
            (setq result (apply orig-fn args))
          (setq throttle-timer
                (run-with-timer
                 timeout nil
                 (lambda ()
                   (cancel-timer throttle-timer)
                   (setq throttle-timer nil)))))))))

(defun timeout-nil-throttle! (func &optional throttle)
  "Throttle FUNC by THROTTLE seconds.

This advises FUNC so that it can run no more than once every
THROTTLE seconds.

THROTTLE defaults to 1.0 seconds.  Using a throttle of 0 resets the
function."
  (if (= throttle 0)
      (advice-remove func 'throttle)
    (advice-add func :around (timeout-nil--throttle-advice throttle)
                '((name . throttle)
                  (depth . -98)))))

(defun timeout-nil-unthrottle! (func)
  (timeout-nil-throttle! func 0))


(defun timeout-memo--throttle-advice (&optional timeout)
  "Return a function that throttles its argument function.
But also updates when the arguments change.

TIMEOUT defaults to 1.0 seconds.  This is intended for use as
function advice."
  (let ((throttle-timer)
        (timeout (or timeout 1.0))
        (result)
        (lastargs))
    (lambda (orig-fn &rest args)
      "Throttle calls to this function."
      (if (and (timerp throttle-timer)
               (eq lastargs args))
          result
        (prog1
            (setq result (apply orig-fn args))
          (setq throttle-timer
                (run-with-timer
                 timeout nil
                 (lambda ()
                   (if (timerp throttle-timer)
                       (cancel-timer throttle-timer))
                   (setq throttle-timer nil))))
          (setq lastargs args))))))

(defun timeout-memo-throttle! (func &optional throttle)
  "Throttle FUNC by THROTTLE seconds.

This advises FUNC so that it can run no more than once every
THROTTLE seconds.

THROTTLE defaults to 1.0 seconds.  Using a throttle of 0 resets the
function."
  (if (= throttle 0)
      (advice-remove func 'throttle)
    (advice-add func :around (timeout-memo--throttle-advice throttle)
                '((name . throttle)
                  (depth . -98)))))

(defun timeout-memo-unthrottle! (func)
  (timeout-memo-throttle! func 0))

(provide 'pen-timeout)
