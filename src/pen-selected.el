(defun pen-turn-on-selected-minor-mode ()
  (interactive)

  (selected-minor-mode -1)
  (selected-region-active-mode -1)
  (selected-minor-mode 1))

(define-globalized-minor-mode
  global-selected-minor-mode selected-minor-mode pen-turn-on-selected-minor-mode)
(global-selected-minor-mode t)

(defmacro pen-bp (&rest body)
  "Pipe string into bash command. Return stdout."
  ;; Remove the last element from a list
  `(pen-sn (concat (pen-quote-args ,@(butlast body))) ,@(last body)))

(defun get-vim-link (&optional editor)
  (interactive)
  (if (not editor)
      (setq editor "v"))
  (defvar uri)
  (defvar vimcmd)
  (setq uri (pen-mnm (get-path t)))

  (setq vimcmd
        (cond ((derived-mode-p 'eww-mode) "ewwlinks")
              ((derived-mode-p 'Info-mode) "emacshelp")
              (t editor)))

  (if mark-active
      (let* ((pat (pen-bp head -n 1 (pen-selected-text)))
             (vimpat
              (if (sel-flush-left-p)
                  (vim-escape (concat "^" pat))
                (vim-escape pat)))
             (link-cmd (concat vimcmd " +/" vimpat " " (pen-q uri))))
        (xc link-cmd)
        (message "%s" link-cmd)
        (deactivate-mark))))

(defun get-emacs-link (&optional editor)
  (interactive)

  (if (and
       (derived-mode-p 'eww-mode)
       (>= (prefix-numeric-value current-prefix-arg) 4)
       mark-active)
      (xc (concat (get-path) "#:~:text=" (urlencode (e/chomp-all (pen-selected-text)))))

      (progn
        (if (not editor)
            (setq editor "sp"))
        (get-vim-link editor))))

(define-key selected-keymap (kbd "J") 'pen-fi-join)

(provide 'pen-selected)