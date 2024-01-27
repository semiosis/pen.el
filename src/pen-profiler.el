;; This should be for debugging and profiling

(defun debug-on-entry-from-binding (function)
  "Request FUNCTION to invoke debugger each time it is called.

When called interactively, prompt for FUNCTION in the minibuffer.

This works by modifying the definition of FUNCTION.  If you tell the
debugger to continue, FUNCTION's execution proceeds.  If FUNCTION is a
normal function or a macro written in Lisp, you can also step through
its execution.  FUNCTION can also be a primitive that is not a special
form, in which case stepping is not possible.  Break-on-entry for
primitive functions only works when that function is called from Lisp.

Use \\[cancel-debug-on-entry] to cancel the effect of this command.
Redefining FUNCTION also cancels it."
  (interactive
   (list (key-binding (kbd (format "%s" (key-description (read-key-sequence-vector "Key: ")))))))
  (advice-add function :before #'debug--implement-debug-on-entry
              '((depth . -100)))
  function)


(define-key pen-map (kbd "s-P P") 'profiler-start)
(define-key pen-map (kbd "s-P S") 'profiler-stop)
(define-key pen-map (kbd "s-P R") 'profiler-report)

(define-key pen-map (kbd "s-D D") 'debug-on-entry)
(define-key pen-map (kbd "s-D N") 'debug-on-entry)

(provide 'pen-profiler)
