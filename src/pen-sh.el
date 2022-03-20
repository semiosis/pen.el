(defmacro pen-bd (&rest body)
  "Like b, but detach."
  `(shut-up (pen-sn (concat (pen-quote-args ,@body)) nil nil nil t)))

(defmacro pen-be (&rest body)
  "Returns the exit code."
  (defset b_exit_code nil)

  `(progn
     (pen-sn (concat (pen-quote-args ,@body)))
     (string-to-int b_exit_code)))

(defmacro bx-right (&rest body)
  "Evaluate the last argument and use as the last argument to shell script. Use the last lisp argument as the final argument to the preceding bash command."
  `(pen-sn (concat (pen-quote-args ,@(butlast body)) " " (e/q (str ,@(last body))))))
(defalias 'bxr 'bx-right)
(defalias 'pen-bl 'bx-right)

(defmacro pen-bp (&rest body)
  "Pipe string into bash command. Return stdout."
  `(pen-sn (concat (pen-quote-args ,@(butlast body))) ,@(last body)))

(defmacro pen-bq (&rest body)
  "True if exit code = 0."
  `(eq (pen-be ,@body) 0))

(defmacro pen-ble (&rest body)
  "Returns the exit code."
  (defset b_exit_code nil)

  `(progn
     (pen-sn (concat (pen-quote-args ,@(butlast body)) " " (e/q ,@(last body))))
     (string-to-int b_exit_code)))

(defmacro pen-bld (&rest body)
  "Runs and detaches."
  `(pen-sn (pen-ns (concat (pen-quote-args ,@(butlast body)) " " (e/q ,@(last body)))) nil nil nil t))

(defmacro pen-blq (&rest body)
  "Returns the exit code."
  `(eq (pen-ble ,@body) 0))

(defun e (path)
  (interactive)
  (if path
      (find-file (eval `(echo -n ,path)))))

(defmacro b-tty (&rest body)
  `(sh (concat (quote-args ,@body))))

(defmacro b. (&rest body)
  "b but with chomp."
  `(pen-sn (concat (quote-args ,@body) " | chomp")))

(defmacro bd (&rest body)
  "Like b, but detach."
  `(shut-up (pen-sn (concat (quote-args ,@body)) nil nil nil t)))

(defmacro be (&rest body)
  "Returns the exit code."
  (defset b_exit_code nil)

  `(progn
     (pen-sn (concat (quote-args ,@body)))
     (string-to-number b_exit_code)))

(defun sne (cmd)
  "Returns the exit code."
  (defset b_exit_code nil)

  (progn
    (pen-sn cmd)
    (string-to-number b_exit_code)))

(defmacro bld (&rest body)
  "Runs and detaches."
  `(pen-sn (pen-ns (concat (quote-args ,@(butlast body)) " " (pen-q ,@(last body)))) nil nil nil t))

(defmacro bpe (&rest body)
  "Pipe the last argument in. Returns the exit code."
  (defset b_exit_code nil)

  `(progn
     (pen-sn (concat (quote-args ,@(butlast body))) (pen-q ,@(last body)) nil 'b_exit_code)
     (string-to-number b_exit_code)))

(provide 'pen-sh)
