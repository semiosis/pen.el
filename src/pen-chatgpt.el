(require 'epc)
(defset python-interpreter "/usr/bin/python")

(use-package chatgpt
  :straight (:host github :repo "mullikine/ChatGPT-pen.el" :files ("dist" "*.el"))
  :init
  (require 'python)
  (setq chatgpt-repo-path "/root/.emacs.d/straight/repos/ChatGPT-pen.el/")
  :bind ("C-c q" . chatgpt-query))

(provide 'pen-chatgpt)
