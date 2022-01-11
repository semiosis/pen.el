(require 'wgrep)

(defun goto-function-from-binding (sequence)
  "Go to the function name associated with a key binding after entering it"
  (interactive (list (format "%s" (key-description (read-key-sequence-vector "Key: ")))))
  (find-function (key-binding (kbd sequence))))

(defun get-map-for-key-binding (sequence)
  "This works"
  (interactive (list (format "%s" (key-description (read-key-sequence-vector "Key: ")))))
  (xc (symbol-name (help--binding-locus (kbd sequence) nil))))

(defmacro pen-macro-unminimise (&rest body)
  "This unminimises the code"
  (let* ((codestring (pp-to-string body))
         (ucodestring (pen-umn codestring))
         (newcode (pen-eval-string (concat "'" ucodestring))))
    `(progn ,@newcode)))
(defalias 'pen-mu 'pen-macro-unminimise)

(defmacro pen-macro-minimise (&rest body)
  "This minimises the code"
  (let* ((codestring (pp-to-string body))
         (mcodestring (pen-mnm codestring))
         (newcode (pen-eval-string (concat "'" mcodestring))))
    `(progn ,@newcode)))
(defalias 'pen-mm 'pen-macro-minimise)

(defun pen-ead-binding ()
  "ead binding in config dir"
  (interactive)
  (let* ((sequence (format "%s" (key-description (read-key-sequence-vector "Key: "))))
         (fun (key-binding (kbd sequence))))
    (if (fboundp fun)
        (wgrep (concat "\\b" (str fun) "\\b") (pen-mu "$HOME/.emacs.d/host/pen.el"))
      (message (concat "Aborting: Function " (pen-q (str fun)) " doesn't exit")))))

(defun copy-keybinding-as-table-row ()
  (interactive)
  (let ((sequence (format "%s" (key-description (read-key-sequence-vector "Key: ")))))
    (xc sequence)
    (message "%s" (concat "copied: " sequence))))

(cl-defun copy-keybinding-as-table-row-or-macro-string (sequence)
  (interactive (list (format "%s" (key-description (read-key-sequence-vector "Key: ")))))
  (let ((arg (prefix-numeric-value current-prefix-arg)))
    (cond
     ((>= arg 8) (progn
                   (setq current-prefix-arg nil)
                   (copy-keybinding-as-elisp sequence)))
     ((>= arg 4) (xc sequence))
     (t (xc (concat "| =" sequence "= | =" (str (key-binding (kbd sequence))) "= | =" (str (sym2str (help--binding-locus (kbd sequence) nil))) "="))))))

(defun record-keyboard-macro-string (sequence)
  "Copies the key binding after entering it"
  (interactive (list (format "%s" (key-description (read-key-sequence-vector "Key: ")))))

  (let ((arg (prefix-numeric-value current-prefix-arg)))
    (cond
     ((>= arg 8) (progn
                   (setq current-prefix-arg nil)
                   (copy-keybinding-as-elisp sequence)))
     ((>= arg 4) (progn
                   (setq current-prefix-arg nil)
                   (copy-keybinding-as-table-row-or-macro-string sequence)))
     (t (progn
        (xc sequence)
        (message "%s" (concat "copied: " sequence)))))))

(cl-defun copy-keybinding-as-elisp (sequence)
  (interactive (list (format "%s" (key-description (read-key-sequence-vector "Key: ")))))
  (let* ((arg (prefix-numeric-value current-prefix-arg))
         (mapstr (str (symbol-name (help--binding-locus (kbd sequence) nil))))
         (funstr (str (key-binding (kbd sequence)))))
    (xc (concat "(define-key " mapstr " (kbd " (pen-q sequence) ") '" funstr ")"))))

(defun pen-sh-wgrep (pattern &optional wd)
  (interactive (list (read-string-hist "ead pattern: ")
                     (read-directory-name "ead dir: ")))
  (e/nw (concat "set -x; cd " (pen-q wd) "; ead " (pen-q (concat "\\b" pattern "\\b")) " || pak")))

(defun pen-wgrep (pattern &optional wd path-re)
  (interactive (list (read-string-hist "ead pattern: ")
                     (read-directory-name "ead dir: ")))

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (pen-sh-wgrep pattern wd)
    (progn
      (if (not wd)
          (setq wd (pen-pwd)))
      (setq wd (pen-umn wd))
      (with-current-buffer
          ;; How can I use pen-mnm but only on the file paths? -- I want to be able to filter on a column only
          (let ((globstr (if (sor path-re)
                             (concat "-p " (pen-q path-re) " "))))
            (new-buffer-from-string (ignore-errors (pen-sn (concat "ead " globstr (pen-q pattern) " | pen-mnm | cat") nil wd))))
        (grep-mode)))))
(defalias 'wgrep 'pen-wgrep)

(provide 'pen-help)