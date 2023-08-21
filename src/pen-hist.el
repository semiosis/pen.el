(require 's)

;; -- shell

(defun hsqf (cmdname)
  "Run a command from history"
  (interactive (list (read-string-hist "hsqf command:")))
  (let* ((selected-command (fz (pen-mnm (pen-sn (concat "hsqc -ao " cmdname))) nil nil "hsqf past cmd: "))
         (selected-command (pen-sn "hsqf-clean" selected-command))
         (wd (pen-uq (s-replace-regexp "^cd \"\\([^\"]+\\)\".*$" "\\1" selected-command)))
         (pen-cmd (s-replace-regexp (concat "^[^;]*; \\([^ ]+\\).*") "\\1" selected-command)))

    (cond ((string-equal cmd "hsqf")
           (progn
             (setq cmd (s-replace-regexp (concat "^[^;]*; [^ ]+ \\([^ ]+\\).*") "\\1" selected-command))
             (hsqf cmd)))

          (t (sps selected-command)))))

(defun hsqf-gc ()
  (interactive)
  (let ((url (fz (pen-snc "xurls | uniqnosort" (pen-mnm (pen-snc (pen-cmd "hsqc" "gc"))))
                 nil nil "gc: ")))
    (gc url)))

;; -- emacs

(defun hs (name &rest body)
  "Function. Record the arguments into hs before running."
  ;; (eval `(sh/hs ,name ,(mapconcat 'str body " ")))
  (pen-sn (concat "hist-save " (pen-q name) " " (mapconcat 'pen-q (mapcar 'str body) " "))))

(defalias 'pen-str2lines 's-lines)
(defalias 'str2lines 's-lines)

(defun pen-hg (name)
  (pen-str2lines (pen-cl-sn (concat "hist-get " (pen-q name)) :chomp t)))

(defun pen-hist-edit (name)
  (find-file (pen-cl-sn (concat "hist-getfile " (pen-q name)) :chomp t)))
(defalias 'pen-he 'pen-hist-edit)

(defmacro sh/hs (name &rest body)
  `(shell-command (concat "hs " "emacs-" (str ,name) " " (pen-q (str ',@body)))))

(provide 'pen-hist)
