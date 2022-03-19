(load "/root/repos/pen-emacsd/straight.el/straight.el")
(require 'straight)

(defvar bootstrap-version)

(let ((bootstrap-file
       (let ((fp (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory)))
         (pen-snc (pen-cmd "sed" "-i" "s=(load (expand-file-name (concat straight.el \"c\")=(load (expand-file-name (concat straight.el)=" fp))
         fp))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      ;; I needed to also enable emacs-lisp-mode because I have a failsafe advice thing
      (emacs-lisp-mode)
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(use-package shelldon
  :straight (shelldon :type git
			                :host github
			                :repo "Overdr0ne/shelldon"
			                :branch "master"))


(straight-use-package '(apheleia :host github :repo "raxod502/apheleia"))
(apheleia-global-mode +1)


;; Gumshoe: a spatial Point movement tracker
(use-package gumshoe
  :straight (gumshoe :type git
                     :host github
                     :repo "Overdr0ne/gumshoe"
                     :branch "master")
  :config
  ;; The minor mode must be enabled to begin tracking
  (global-gumshoe-mode 1))
(advice-add 'gumshoe-log-current-position :around #'ignore-errors-around-advice)

;; Gumshoe requires this:
(defalias 'math-pow 'expt)

(provide 'pen-straight)