(require 'undo-tree)

;; I want to use normal undo for region, not undotree
;; I should use advice around undo for this
(setq undo-tree-enable-undo-in-region nil)
(setq undo-tree-auto-save-history t)
(setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))

(setq undo-tree-visualizer-diff t)
(setq undo-tree-visualizer-timestamps t)

(defmacro save-buffer-state (&rest body)
  "Like save-excursion but for edits."
  `(progn
     (undo-tree-save-state-to-register ?s)
     ,@body
     (undo-tree-restore-state-from-register ?s)
     nil))

(advice-add 'undo-tree-undo :around #'advise-to-save-region)
(advice-remove 'undo-tree-undo #'advise-to-save-region)
(advice-add 'undo :around #'advise-to-save-region)
(advice-remove 'undo #'advise-to-save-region)
(advice-add 'special-lispy-undo :around #'advise-to-save-region)
(advice-remove 'special-lispy-undo #'advise-to-save-region)

(defun undo-tree-undo-around-advice (proc &rest args)
  (if (pen-selected-p)
      (call-interactively 'undo)
    (let ((res (apply proc args)))
      res)))
(advice-add 'undo-tree-undo :around #'undo-tree-undo-around-advice)
(advice-add 'special-lispy-undo :around #'undo-tree-undo-around-advice)

(advice-add 'undo-tree-make-history-save-file-name :around #'shut-up-around-advice)
(advice-add 'undo-tree-save-history :around #'shut-up-around-advice)

;; Disable undo-tree. it's just too slow
(global-undo-tree-mode -1)

(defun undo-tree-save-root (&optional r)
  (if (not r)
      (setq r ?^))
  ;; (require 'undo-tree)
  (undo-tree-save-state-to-register r))

(provide 'pen-undo-tree)