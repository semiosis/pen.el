;;; ob-sagemath.el --- org-babel functions for SageMath evaluation -*- lexical-binding: t -*-

;; Copyright (C) 2016 - 2017 Sho Takemori.

;; Author: Sho Takemori <stakemorii@gmail.com>
;; URL: https://github.com/stakemori/ob-sagemath
;; Package-Requires: ((sage-shell-mode "0.0.8") (s "1.8.0") (emacs "24"))
;; Version: 0.4
;; Keywords: SageMath, org-babel

;;; License:
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; org-babel integration with SageMath using sage-shell-mode. Visit
;; https://github.com/stakemori/ob-sagemath for more information.


;;; Code:
(require 'org)
(require 'sage-shell-mode)
(require 'ob-python)
(require 's)
(add-to-list 'org-babel-tangle-lang-exts '("sage" . "sage"))
(add-to-list 'org-src-lang-modes '("sage" . sage-shell:sage))

(defgroup ob-sagemath
  nil "Group for ob-sagemath"
  :group 'org-babel)

(defcustom ob-sagemath-output-display-function #'display-buffer
  "Function for displaying buffer for the standard output when using :results value"
  :group 'ob-sagemath
  :type 'function)

(defvar org-babel-header-args:sage
  '((tolatex . :any)
    (latexwrap . :any)
    (latexnewline . :any))
  "SageMath specific header arguments")

(defvar ob-sagemath--python-script-dir
  (if load-file-name
      (file-name-directory load-file-name)
    default-directory))

(defvar ob-sagemath--script-name "_emacs_ob_sagemath")

(defvar ob-sagemath--imported-p nil)
(make-variable-buffer-local 'ob-sagemath--imported-p)

(defun ob-sagemath--python-name (f)
  (format "%s.%s" ob-sagemath--script-name f))

(defun ob-sagemath--import-script ()
  "Assumes `sage-shell:process-buffer' is already set."
  (sage-shell:with-current-buffer-safe sage-shell:process-buffer
    (unless ob-sagemath--imported-p
      (sage-shell:send-command
       (s-join "; "
               (list
                (format "sys.path.append('%s')"
                        ob-sagemath--python-script-dir)
                (format "import emacs_ob_sagemath as %s"
                        ob-sagemath--script-name)))
       nil nil t)
      (setq ob-sagemath--imported-p t))))

(defun ob-sagemath--cache-current-p (info params)
  (let ((cache (cdr (assoc :cache params))))
    (when (and cache (string= "yes" cache))
      (let ((new-hash (org-babel-sha1-hash info)))
        (and new-hash
             (equal new-hash (org-babel-current-result-hash)))))))

(defvar ob-sagemath--last-success-state t)
(cl-defstruct ob-sagemath--res-info
  result success output)

(defun ob-sagemath--last-res-info (output params)
  (let* ((res-params (assoc-default :result-params params))
         (suc-str (substring-no-properties output -2 -1))
         ;; Remove success state and the final new line
         (out-str (substring-no-properties output 0 -2))
         (success (setq ob-sagemath--last-success-state
                        (cond ((string= suc-str "0")
                               t)
                              ((string= suc-str "1")
                               nil)
                              (t (error "Invalid output:\n%s" output))))))
    (let ((res (if (member "value" res-params)
                   (sage-shell:send-command-to-string
                    (format "%s('%s')"
                            (ob-sagemath--python-name "print_last_result")
                            ob-sagemath--script-name))
                 out-str)))
      (unless (s-blank? res)
        (setq res (substring res 0 -1)))
      (when success
        (setq res (ob-sagemath--latex-filter res params)))
      (cond ((member "value" res-params)
             (make-ob-sagemath--res-info
              :success success
              :output out-str
              :result res))
            (t (make-ob-sagemath--res-info
                :success success
                :result res))))))


(defun ob-sagemath--latex-filter (s params)
  (when (or (assoc :tolatex params)
            (string=
             (s-trim (sage-shell:send-command-to-string
                      (ob-sagemath--python-name "print_last_latex()")))
             "True"))
    (let ((newline (assoc-default :latexnewline params)))
      (when newline
        (setq s (s-replace "\n" newline s))))
    (let ((wrap (assoc-default :latexwrap params)))
      (when (and wrap (consp wrap))
        (setq s (format "%s%s%s" (car wrap) s (cdr wrap))))))
  s)

;;;###autoload
(defun ob-sagemath-execute-async (arg)
  "Execute current src code block. With prefix argument, evaluate all code in a
buffer."
  (interactive "p")
  (cl-case arg
    (1 (ob-sagemath-execute-async-1))
    (4 (ob-sagemath-execute-buffer-async))))

(defun ob-sagemath-execute-async-1 ()
  (let* ((org-element--cache nil)       ; Avoid using cache.
         (info (org-babel-get-src-block-info))
         (language (car info))
         (body (nth 1 info))
         (params (nth 2 info)))
    (cond ((and language body
                ;; To avoid byte-compiler warning
                ;; with-no-warnings doesn't work in Emacs 25.1
                (null org-element--cache)

                (ob-sagemath--cache-current-p info params))
           ;; If result is cached, call sync version.
           (org-babel-execute-src-block nil info params))
          ((member language '("sage" "sage-shell"))
           (ob-sagemath--execute1 body params))
          (t (call-interactively #'org-ctrl-c-ctrl-c)))))

(defun ob-sagemath--init (session sync)
  (unless (and (sage-shell:sage-executable)
               (executable-find (sage-shell:sage-executable)))
    (error sage-shell:exec-path-error-msg))
  (let ((cmd (sage-shell:sage-executable)))
    (cond ((string= session "none")
           (error
            (concat
             "ob-sagemath currently only supports evaluation using a session."
             " Make sure your src block has a :session param.")))
          ((stringp session)
           (setq sage-shell:process-buffer
                 (sage-shell:run cmd nil
                                 :switch-function 'no-switch
                                 :buffer-name (format "*Sage<%s>*" session))))
          (t (setq sage-shell:process-buffer
                   (sage-shell:run cmd nil
                                   :switch-function 'no-switch)))))

  (unless sync
    (org-babel-remove-result)
    (message "Evaluating code block ...")))

(defun ob-sagemath--execute1 (body params)
  (let* ((pt (point))
         (buf (current-buffer))
         (marker (make-marker))
         (marker (set-marker marker pt)))
    (ob-sagemath--eval
     body params
     :callback (lambda (res-info)
                 (ob-sagemath--define-exec-sage-async
                  res-info params buf marker)))))

(defun ob-sagemath--define-exec-sage-async (res-info params buf marker)
  (unwind-protect
      (progn
        (defun org-babel-execute:sage (_body _params)
          (ob-sagemath--res-info-to-result res-info params))
        (with-current-buffer buf
          (save-excursion
            (goto-char marker)
            (call-interactively #'org-babel-execute-src-block)
            (ob-sagemath--exec-callback res-info params))))
    (fset 'org-babel-execute:sage #'ob-sagemath--execute-sync)))

(defun ob-sagemath--exec-callback (res-info params)
  (let ((success-p (ob-sagemath--res-info-success res-info))
        (result (ob-sagemath--res-info-result res-info))
        (output (ob-sagemath--res-info-output res-info)))
    (unless success-p
      (ob-sagemath--failure-callback
       (cond ((member "value" (assoc-default :result-params params))
              output)
             (t result))))
    (when (and output (not (string= output "")))
      (funcall
       ob-sagemath-output-display-function
       (ob-sagemath--make-output-buffer output)))))

(defun ob-sagemath--res-info-to-result (res-info params)
  (let ((success-p (ob-sagemath--res-info-success res-info))
        (result (ob-sagemath--res-info-result res-info))
        (res-params (assoc-default :result-params params)))
    (cond (success-p
           (cond ((assq :file params) nil)
                 ((member "file" res-params)
                  (s-trim result))
                 ((member "table" res-params)
                  (ob-sagemath-table-or-string (s-trim result) params))
                 (t result)))
          ;; Return the empty string when it fails.
          (t ""))))

(defun ob-sagemath--execute-sync (body params)
  (ob-sagemath--eval
   body params
   :sync t
   :callback (lambda (res-info)
               (prog1
                   (ob-sagemath--res-info-to-result res-info params)
                 (ob-sagemath--exec-callback res-info params)))))
;;;###autoload
(defun org-babel-execute:sage (body params)
  (ob-sagemath--execute-sync body params))

(cl-defun ob-sagemath--eval (body params &key sync callback)
  "CALLBACK will be called when evaluation is done with argument RES-INFO."
  (let ((session (cdr (assoc :session params)))
        (raw-code (org-babel-expand-body:generic
                   (encode-coding-string body 'utf-8)
                   params (org-babel-variable-assignments:python params)))
        (buf (current-buffer))
	(coding-system-for-write 'utf-8))

    (ob-sagemath--init session sync)

    (when sync
      (while (not (sage-shell:output-finished-p))
        (accept-process-output
         (get-buffer-process sage-shell:process-buffer) 0.3)
        (sleep-for 0.3)))

    (with-current-buffer sage-shell:process-buffer
      (cond
       (sync (ob-sagemath--import-script)
             (let* ((raw-output (sage-shell:send-command-to-string
                                 (ob-sagemath--code raw-code params buf)))
                    (res-info (ob-sagemath--last-res-info raw-output params)))
               (sage-shell:clear-command-cache)
               (funcall callback res-info)))
       (t (sage-shell:after-output-finished
            ;; Import a Python script if necessary.
            (ob-sagemath--import-script)

            (sage-shell:change-mode-line-process t "eval")
            (sage-shell:run-cell-raw-output
             (ob-sagemath--code raw-code params buf)
             :callback (lambda (raw-output)
                         (condition-case err-var
                             (progn
                               (sage-shell:change-mode-line-process nil)
                               (sage-shell:clear-command-cache)
                               (funcall callback
                                        (ob-sagemath--last-res-info raw-output params)))

                           (error
                            (sage-shell:change-mode-line-process nil)
                            (signal (car err-var)
                                    (cdr err-var))))))))))))


(defvar ob-sagemath-output-buffer-name "*Ob-SageMath-Output*")
(defun ob-sagemath--make-output-buffer (output)
  (let ((inhibit-read-only t)
        (view-read-only nil)
        (buf (get-buffer-create ob-sagemath-output-buffer-name)))
    (with-current-buffer buf
      (erase-buffer)
      (insert output)
      (view-mode 1))
    ;; Return the buffer
    buf))

(defvar ob-sagemath-error-buffer-name "*Ob-SageMath-Error*")
(defvar ob-sagemath--error-regexp
  (rx symbol-start
      (or "ArithmeticError" "AssertionError" "AttributeError"
          "BaseException" "BufferError" "BytesWarning" "DeprecationWarning"
          "EOFError" "EnvironmentError" "Exception" "FloatingPointError"
          "FutureWarning" "GeneratorExit" "IOError" "ImportError"
          "ImportWarning" "IndentationError" "IndexError" "KeyError"
          "KeyboardInterrupt" "LookupError" "MemoryError" "NameError"
          "NotImplementedError" "OSError" "OverflowError"
          "PendingDeprecationWarning" "ReferenceError" "RuntimeError"
          "RuntimeWarning" "StandardError" "StopIteration" "SyntaxError"
          "SyntaxWarning" "SystemError" "SystemExit" "TabError" "TypeError"
          "UnboundLocalError" "UnicodeDecodeError" "UnicodeEncodeError"
          "UnicodeError" "UnicodeTranslateError" "UnicodeWarning"
          "UserWarning" "ValueError" "Warning" "ZeroDivisionError")
      symbol-end))

(defvar ob-sagemath--error-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\" "w" table)
    (modify-syntax-entry ?\' "w" table)
    table))

(define-derived-mode ob-sagemath-error-mode nil "ObSageMathError"
  "Major mode for display errors."
  (set-syntax-table ob-sagemath--error-syntax-table)
  (setq font-lock-defaults
        (list (list (cons ob-sagemath--error-regexp 'font-lock-warning-face))
              nil nil nil 'beginning-of-line)))

(defun ob-sagemath--failure-callback (output)
  (let ((inhibit-read-only t)
        (view-read-only nil)
        (buf (get-buffer-create ob-sagemath-error-buffer-name)))
    (with-current-buffer buf
      (erase-buffer)
      (insert output)
      (ob-sagemath-error-mode)
      (unless view-mode (view-mode)))
    (pop-to-buffer buf)
    (message "An error raised in the SageMath process.")))


(defun ob-sagemath--escape-code (raw-code)
  (setq raw-code (replace-regexp-in-string (rx "\\") "\\\\" raw-code nil t)
        raw-code (replace-regexp-in-string (rx "\"") "\\\"" raw-code nil t))
  (replace-regexp-in-string (rx "\n") "\\n" raw-code nil t))

(defun ob-sagemath--code (raw-code params buf)
  "Return code for evaluatation."
  (let ((tmp-file (sage-shell-edit:temp-file "sage")))
    (with-temp-buffer
      (insert raw-code)
      (sage-shell-edit:write-region-to-file
       (point-min)
       (point-max)
       tmp-file))
    (format "%s(\"%s\", filename=%s, latex=%s, latex_formatter=%s)"
            (ob-sagemath--python-name "read_file_and_run_cell")
            tmp-file
            (ob-sagemath--result-file-name params buf)
            (ob-sagemath--latex-arg params)
            (ob-sagemath--latex-fmttr params))))

(defun ob-sagemath--latex-arg (params)
  (let* ((tolatex-cons (assoc :tolatex params))
         (tolatex (cdr tolatex-cons)))
    (cond
     ((or (null tolatex-cons)
          (and tolatex-cons
               (string= tolatex "no")))
      "False")
     (t "True"))))

(defun ob-sagemath--latex-fmttr (params)
  (let ((tolatex (assoc-default :tolatex params)))
    (cond
     ((or (string= tolatex "yes")
          (string= tolatex "no")) "None")
     (tolatex tolatex)
     (t "None"))))

(defun ob-sagemath--result-file-name (params buf)
  "Return png file name."
  (sage-shell:aif (assoc-default :file params)
      (format "\"%s\""
              (with-current-buffer buf
                (expand-file-name it default-directory)))
    "None"))

(defsubst ob-sagemath--table-dpt-lv ()
  "Return depth in parens when the point is not in string"
  (let ((ppss (syntax-ppss)))
    (and (not (nth 3 ppss))
         (car ppss))))

(defun ob-sagemath-table-or-string (res params)
  (with-temp-buffer
    (insert res)
    (goto-char (point-min))
    (cond ((and (looking-at (rx (or "((" "([" "[(" "[[")))
                ;; When res is not a list of lists/tuples return res
                (save-excursion
                  (and (ignore-errors (forward-list 1))
                       (string-match-p
                        (rx bol (0+ whitespace) eol)
                        (buffer-substring-no-properties (point) (point-max))))))
           (forward-char 1)
           (let ((res (with-syntax-table sage-shell-mode-syntax-table
                        (cl-loop while (re-search-forward
                                        (rx (or "(" "[")) nil t)
                                 when (save-excursion
                                        (forward-char -1)
                                        (equal (ob-sagemath--table-dpt-lv)
                                               1))
                                 collect
                                 (ob-sagemath-table-or-string--1
                                  (point)
                                  (progn (forward-char -1)
                                         (forward-list) (1- (point))))))))
             (let ((colnames (cdr (assoc :colnames params))))
               (cond ((equal colnames "yes")
                      (append (list (car res) 'hline) (cdr res)))
                     ((and colnames (listp colnames))
                      (append (list colnames 'hline) res))
                     (t res)))))
          (t res))))

(defun ob-sagemath-table-or-string--1 (beg end)
  (let ((start beg))
    (goto-char beg)
    (append
     (cl-loop while (re-search-forward "," end t)
              when (equal (ob-sagemath--table-dpt-lv) 2)
              collect (prog1
                          (ob-sagemath--string-unqote
                           (s-trim
                            (buffer-substring-no-properties
                             start (- (point) 1))))
                        (setq start (point))))
     (list (ob-sagemath--string-unqote
            (s-trim (buffer-substring-no-properties start end)))))))

(defun ob-sagemath--string-unqote (s)
  (sage-shell:->>
   (cond ((string-match (rx bol (group (or (1+ "'") (1+ "\""))) (1+ nonl))
                        s)
          (let ((ln (length (match-string 1 s))))
            (substring s ln (- (length s) ln))))
         (t s))
   (s-replace "\\\\" "\\")))

(defun ob-sagemath--code-block-markers ()
  (let ((markers nil)
        (mrkr nil))
    (org-save-outline-visibility t
      (org-babel-map-executables nil
        (setq mrkr (make-marker))
        (set-marker mrkr (save-excursion (forward-line 1) (point)))
        (push mrkr markers)))
    (reverse markers)))

(defun ob-sagemath-execute-buffer-async ()
  (interactive)
  (setq ob-sagemath--last-success-state t)
  (let ((markers (ob-sagemath--code-block-markers))
        (buf (current-buffer)))
    (save-excursion
      (ob-sagemath--execute-markers markers buf))))


(defun ob-sagemath--execute-markers (markers buf)
  (cond ((null markers)
         (message "Every code block in this buffer has been evaluated."))
        (ob-sagemath--last-success-state
         (with-current-buffer buf
           (save-excursion
             (goto-char (car markers))
             (ob-sagemath-execute-async-1))
           (cond ((and sage-shell:process-buffer
                       (buffer-live-p sage-shell:process-buffer))
                  (sage-shell:after-output-finished
                    (sage-shell:after-redirect-finished
                      (ob-sagemath--execute-markers (cdr markers) buf))))
                 (t (ob-sagemath--execute-markers (cdr markers) buf)))))
        (t (setq ob-sagemath--last-success-state t))))

(provide 'ob-sagemath)
;;; ob-sagemath.el ends here
