;; These must come after the above block because the prefix is not yet defined
(require 'helm-sys)

(defun e/broot ()
  (interactive)
  (term-sps (concat (pen-cmd "cd" default-directory) "; br")))

(defun broot ()
  (interactive)
  (pen-sps "br" nil nil default-directory))

(defun open-colors ()
  (interactive)
  (pen-sps "open-colors" nil nil default-directory))

(provide 'pen-apps)