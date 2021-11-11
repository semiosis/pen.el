(defun hs (name &rest body)
  "Function. Record the arguments into hs before running."
  ;; (eval `(sh/hs ,name ,(mapconcat 'str body " ")))
  (pen-sn (concat "hist-save " (pen-q name) " " (mapconcat 'pen-q (mapcar 'str body) " "))))

(defun hg (name)
  (str2lines (pen-cl-sn (concat "hist-get " (pen-q name)) :chomp t)))

(defun hist-edit (name)
  (find-file (pen-cl-sn (concat "hist-getfile " (pen-q name)) :chomp t)))
(defalias 'he 'hist-edit)

(defmacro sh/hs (name &rest body)
  `(shell-command (concat "hs " "emacs-" (str ,name) " " (pen-q (str ',@body)))))

(provide 'pen-hist)