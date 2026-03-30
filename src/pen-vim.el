(use-package vimrc-mode :ensure t)

(defun vimhelp (&optional thing)
  ;; (interactive (list (ask (pen-thing-at-point))))
  (interactive (list (pen-confirm-input (pen-thing-at-point))))
  (setq thing (sor thing))

  ;; (sps (cmd "vimhelp" thing))
  (tpop (cmd "vimhelp" thing)))

(defun pen-go-to-vim-config ()
  (interactive)
  (find-file (f-join user-home-directory ".vimrc")))

(defun vime (input)
  (interactive (list (read-string-hist "vim expression:")))
  (ifi-etv (pen-snc "vime" input)))

(comment
 (vime "\"yo\"")
 (vime "strftime(\"%c\")")
 (vime "getcompletion('', 'filetype')")
 (vime "execute('scriptnames')"))

(provide 'pen-vim)
