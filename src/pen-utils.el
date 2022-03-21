(defun find-thing (thing)
  (interactive)
  (if (stringp thing)
      (setq thing (intern thing)))
  (try (find-function thing)
       (find-variable thing)
       (find-face-definition thing)
       (pen-ns (concat (str thing) " is neither function nor variable"))))
(defalias 'j 'find-thing)
(defalias 'ft 'find-thing)

(defmacro progn-read-only-disable (&rest body)
  `(progn
     (if buffer-read-only
         (progn
           (read-only-mode -1)
           (let ((res
                  ,@body))
             res)
           (read-only-mode 1))
       (progn
         ,@body))))

(defun gl-find-deb (query)
  (interactive (list (read-string-hist "binary name: ")))
  (wget (fz (pen-cl-sn (pen-concat "find-deb " query) :chomp t))))

(defun zcd (dir)
  (interactive (list (read-directory-name "zcd: ")))
  (pen-sps (pen-cmd "zcd" dir)))

(defun byte-pos ()
  (position-bytes (point)))

(defun date-ts ()
  (string-to-number (format-time-string "%s")))

(defun edit-var-elisp (variable &optional buffer frame)
  (interactive
   (let ((v (variable-at-point))
         (enable-recursive-minibuffers t)
         (orig-buffer (current-buffer))
         val)
     (setq val (completing-read
                (if (symbolp v)
                    (format
                     "Describe variable (default %s): " v)
                  "Describe variable: ")
                #'help--symbol-completion-table
                (lambda (vv)
                  ;; In case the variable only exists in the buffer
                  ;; the command we switch back to that buffer before
                  ;; we examine the variable.
                  (with-current-buffer orig-buffer
                    (or (get vv 'variable-documentation)
                        (and (boundp vv) (not (keywordp vv))))))
                t nil nil
                (if (symbolp v) (symbol-name v))))
     (list (if (equal val "")
               v (intern val)))))
  (with-current-buffer
      (new-buffer-from-string (concat "(setq " (symbol-name variable) "\n'" (pp (eval variable)) ")"))
    (emacs-lisp-mode)))
(defalias 'evar 'edit-var-elisp)

;; doesn't work perrfectly. But it's useful.
;; http:/grapevine.net.au$HOMEstriggs/elisp/emacs-homebrew.el
;; Useful custom functions
(defun reselect-last-region ()
  (interactive)
  (let ((start (mark t))
        (end (point)))
    (goto-char start)
    (call-interactively' set-mark-command)
    (goto-char end)))
(defalias 'reselect 'reselect-last-region)
(defalias 'activate-region 'reselect-last-region)

(provide 'pen-utils)
