(require 'company-plsense)

;; This tries to run plsense when I open prolog code
;; (add-to-list 'company-backends 'company-plsense)
;; e:/root/.emacs.d/host/pen.el/scripts/prolog/cli-example.pl

(add-hook 'perl-mode-hook 'company-mode)
(add-hook 'cperl-mode-hook 'company-mode)

(defun check-if-prolog ()
  (if (string-equal (pen-detect-language t) "prolog")
      (prolog-mode)))

(add-hook 'perl-mode-hook 'check-if-prolog)

;; There is weird template stuff with new files. Forget it.
(never
 (add-to-list 'load-path "/root/.emacs.d/pde")
 (load "pde-load"))

(provide 'pen-perl)
