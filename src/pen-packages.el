(package-initialize)

(defun pen-slurp-file (f)
  (with-temp-buffer
    (insert-file-contents f)
    (buffer-substring-no-properties
     (point-min)
     (point-max))))

(defun pen-load-list-file (f)
  "split-string splits the file into a list of strings. mapcar intern turns the list of strings into a list of symbols"
  (mapcar 'intern
          (split-string
           (pen-slurp-file f) "\n" t)))

;; Auto install package are installed if they are missing

(defvar package-list nil)

(defun pen-auto-load-packages ()
  (interactive)

  (let ((pl "~/.pen/emacs-packages.txt"))
    (if (f-exists-p pl)
        (progn
          (setq package-list
                (-uniq
                 (append
                  package-list
                  '(markdown-mode)
                  (pen-load-list-file
                   pl))))

          ;; This one requires emacs25
          ;; lsp-javascript-typescript

          ;; fetch the list of packages available
          (unless package-archive-contents
            (package-refresh-contents))

          ;; install the missing packages
          (dolist (package package-list)
            (unless (package-installed-p package)
              (yes (ignore-errors (package-install package)))))))))

(pen-auto-load-packages)

(provide 'pen-packages)