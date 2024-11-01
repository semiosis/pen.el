;;; geiser-kawa-util.el --- utility functions for `geiser-kawa' -*- lexical-binding:t -*-

;; Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>

;; SPDX-License-Identifier: BSD-3-Clause

;;; Commentary:
;; Some general utility functions used by the `geiser-kawa' package.

(require 'subr-x)
(require 'geiser-syntax)
(require 'geiser-eval)
(require 'geiser-kawa-globals)
(require 'geiser-repl)

;; Utility functions used by other parts of `geiser-kawa'.

;;; Code:

(defun geiser-kawa-util--eval (sexp-or-str)
  "Eval `sexp-or-str' in Kawa.
1. `sexp-or-str' is wrapped by:
   (geiser:eval ...)
2. Resulting string is passed to `geiser-eval--send/wait' for
   evaluation
Argument SEXP-OR-STR is code to be evaluated by the `geiser:eval'
procedure in Kawa.  It can be either a `list' or a `string'."
  ;; Check type of `sexp-or-str'. If type is not supported Kawa would
  ;; receive `nil' as form to evaluate, which would raise a seemingly
  ;; wierd error:
  ;; unbound location: nil
  ;;   at gnu.mapping.DynamicLocation.get(DynamicLocation.java:36)
  ;;   ...
  (let ((valid-types '(string cons))
        (sexp-or-str-type (type-of sexp-or-str)))
    (unless (member sexp-or-str-type
                    valid-types)
      (error "Wrong type argument: Type of `sexp-or-str' is `%s'.  \
Valid types for `sexp-or-str' can only be %S"
             sexp-or-str-type
             valid-types)))

  (let* ((code-as-str (cond ((equal (type-of sexp-or-str)
                                    'string)
                             sexp-or-str)
                            ((equal (type-of sexp-or-str)
                                    'cons)
                             (format "%S" sexp-or-str))))
         (question (format
                    "(geiser:eval (interaction-environment) %S)"
                    code-as-str)))
    (geiser-eval--send/wait question)))

(defun geiser-kawa-util--retort-result (ret)
  "This function skips the reading `geiser-eval--retort-result' does.
Differently from `geiser-eval--retort-result', this function doesn't
have a variable binding depth limit.  We use this when we need to read
strings longer than what `geiser-eval--retort-result' allows.
Drawback is that `RET' must be valid elisp, while
`geiser-eval--retort-result' uses an elisp implementation of a scheme
reader."
  (car (read-from-string (cadr (assoc 'result ret)))))

(defun geiser-kawa-util--eval-get-result (sexp-or-str
                                          &optional retort-result)
  "Alternative to `geiser-eval--send/result' with custom behavior.
- `sexp-or-str' is wrapped by:
  (geiser:eval (interaction-environment) ...)
- An error is signalled if a Throwable has been raised while running
  in Kawa.
Argument SEXP-OR-STR is code to be evaluated in Kawa.  It can be either
a `list' or a `string'.
Optional argument RETORT-RESULT determines if Kawa's answer should be
read as an elisp object by `geiser-kawa-util--retort-result'."
  (let ((answer (geiser-kawa-util--eval sexp-or-str)))
    (if (assoc 'error answer)
        (signal 'peculiar-error
                (list (string-trim
                       (car (split-string (geiser-eval--retort-output
                                           answer)
                                          "\t")))))
      ;; from: ((result "<actual-result>") (output . ...))
      ;; to either:
      ;; - `retort-result' is non-nil: <actual-result>
      ;; - `retort-result' is nil: "<actual-result>"
      (if retort-result
          (geiser-kawa-util--retort-result answer)
        (cadr (car answer))))))

(defun geiser-kawa-util--repl-point-after-prompt ()
  "If in a Kawa REPL buffer, get point after prompt."
  (save-excursion
    (and (string-prefix-p
          (geiser-repl-buffer-name 'kawa)
          (buffer-name))
         (re-search-backward geiser-kawa--prompt-regexp nil t)
         (re-search-forward geiser-kawa--prompt-regexp nil t))))

(defun geiser-kawa-util--point-is-at-toplevel-p ()
  "Return non-nil if point is at toplevel (not inside a sexp)."
  (equal (point)
         (save-excursion
           (geiser-syntax--pop-to-top)
           (point))))

(provide 'geiser-kawa-util)

;;; geiser-kawa-util.el ends here
