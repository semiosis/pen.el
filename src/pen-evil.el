(defun evil-enabled ()
  "True if in evil mode."
  (minor-mode-enabled evil-mode))

(defmacro do-in-evil (body)
  "This will execute the emacs lisp in evil-mode. It will switch to evil-mode temporarily if it's not enabled."
  `(let ((inhibit-quit t))
     (try
      (if (not (evil-enabled))
          (progn
            (enable-evil)
            (try
             (progn
               (cond ((eq evil-state 'visual)
                      nil
                      )
                     ((eq evil-state 'normal)
                      (if (selected)
                          (evil-visual-state)))
                     ((eq evil-state 'insert)
                      nil
                      ))
               (with-local-quit (,@body)))
             nil)
            (disable-evil)
            nil)
        (progn (,@body) nil))
      nil)))

(defalias 'progn-evil 'do-in-evil)

(defun toggle-evil ()
  (interactive)
  "Tries Holy Mode + falls back to evil"
  (save-mark-and-excursion
    (if (or (evil-visual-state-p)
            (evil-insert-state-p))
        (call-interactively 'evil-normal-state))
    (call-interactively #'evil-mode)
    (fix-region)))

(defun enable-evil ()
  (interactive)
  (save-mark-and-excursion
    (evil-mode 1)))

(defun disable-evil ()
  (interactive)
  (save-mark-and-excursion
    (evil-mode -1)))



(provide 'pen-evil)