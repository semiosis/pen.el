(require 'echo-server)
(require 'pen-workers)

(defun n-workers ()
  (string-to-int (pen-snc "pen-ls-workers")))

(defun pen-open-e-tcp-repl (c)
  (interactive "M")
  (let ((wp (workerp)))

    (sps
     (cmd
      "zrepl" "pen-e" "-D" wp "-e-tcp" c))))

(provide 'pen-tcp-server)
