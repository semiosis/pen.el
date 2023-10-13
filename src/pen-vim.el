(require 'vimrc-mode)

(defun pen-go-to-vim-config ()
  (interactive)
  (find-file (f-join user-home-directory ".vimrc")))

(provide 'pen-vim)
