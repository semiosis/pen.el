(require 'python)
(require 'pydoc)

(setq flycheck-python-flake8-executable "flake8")

(define-key python-mode-map (kbd "M-C-i") nil)

(defun pen-python-mode-hook ()
  (interactive)
  (add-to-list 'company-backends 'company-anaconda)
  (add-to-list 'flycheck-disabled-checkers 'python-pylint))

(add-hook 'python-mode-hook 'pen-python-mode-hook t)

(require 'eldoc)
(require 'anaconda-mode) ;; provides anaconda-eldoc-mode

(add-hook 'python-mode-hook 'eldoc-mode)
(setq python-shell-interpreter "ipython3"
      python-shell-interpreter-args "--simple-prompt -i")

(use-package importmagic
  :ensure t
  :config

  (defun make-import-magic-binding ()
    (interactive)
    (importmagic-mode t)
    (importmagic-fix-imports))
  (define-key python-mode-map (kbd "C-c C-l") #'make-import-magic-binding)
  (add-hook 'python-mode-hook 'importmagic-mode)
  (remove-hook 'python-mode-hook 'importmagic-mode))

(remove-hook 'python-mode-hook 'importmagic-mode)

(defun python-version ()
  (interactive)
  (let ((ver (sh-notty "vermin" (selection-or-buffer-string))))
    (if (called-interactively-p)
        (message ver)
      ver)))

(defun py-run-upto-get-type-of-thing (args)
  "Run the code up to the next line, then get the type of the thing under the cursor"
  (interactive "P"))

(setq realgud:pdb-command-name "mypdb")

(require 'epc)

(defun pen-importmagic-fix-imports ()
  (interactive)
  (call-interactively 'importmagic-fix-imports))

(defvar ein:notebook-mode nil)

(defun python-mark-paragraph ()
  (interactive)
  (let ((startpos (point)))
    (if (looking-at "^[^[:space:]]")
        (progn
          (if (not (selection-p))
              (call-interactively 'er/expand-region))
          (call-interactively 'mark-paragraph))
      (progn
        (while (and (not (looking-at "^[^[:space:]]"))
                    (not (looking-at "^$")))
          (call-interactively 'er/expand-region))
        (if (looking-at "^[^[:space:]]")
            (call-interactively 'mark-paragraph))))))

(define-key python-mode-map (kbd "M-h") 'python-mark-paragraph)

(defun sps-python-browse-package (&optional package)
  (interactive (list (sor (fz (pen-sn "python-list-packages")))))
  (if package
      (pen-sps "zsh" nil nil (concat "/usr/local/lib/python3.6/dist-packages/" package))))

(defun python-browse-package (&optional package)
  (interactive (list (sor (fz (pen-sn "python-list-packages")))))
  (if package
      (e (concat "/usr/local/lib/python3.6/dist-packages/" package))))

(defun xpti-with-package (&optional package dir)
  (interactive (list (sor (fz (pen-sn "python-list-packages")))))
  (if package
      (pen-sps (concat "fz-xpti-package " (pen-q package)) nil nil dir)
    (pen-sps "fz-xpti-package" nil nil dir)))
(defalias 'fz-python-start-xpti-on-package 'xpti-with-package)

(defun py-detect-libraries (path)
  (interactive (list (if (string-match "\\.py$" (buffer-file-path))
                         (buffer-file-path)
                       (read-file-name "Path to .py file"))))

  (if (not (string-match "\\.py$" path))
      (setq path nil))

  (if path
      (pen-etv (pen-snc (concat "pip-missing-reqs " (pen-q path))))
    (error "Invalid path")))

(require 'python-pytest)

(provide 'pen-python)
