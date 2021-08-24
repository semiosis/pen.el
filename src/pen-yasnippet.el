(require 'warnings)

(setq warning-minimum-level :error)
(add-to-list 'warning-suppress-types '(yasnippet backquote-change))

(defun pen-yas-insert-snippet ()
  (interactive)
  (cond
   ((derived-mode-p 'term-mode)
    (pen-yas-insert-snippet-term))
   ((derived-mode-p 'vterm-mode)
    (pen-yas-insert-snippet-vterm))
   (t
    (yas-insert-snippet))))

(defun pen-yas-insert-snippet-term ()
  (interactive)
  ;; Firstly, get off the current term window. It will go haywire with fz
  (let ((s))
    (save-window-excursion
      (switch-to-buffer "*scratch*")
      (let ((b (new-buffer-from-string
                ""
                "yastemp"
                (intern
                 (fz (chomp (pen-sn "find " (pen-q pen-snippets-directory) " -maxdepth 1 -mindepth 1 -type d | sed '/\\.git/d' | sed 's=^.*/=='"))
                     nil nil "yas-insert-snippet-term: ")))))
        (save-window-excursion
          (save-excursion
            (with-current-buffer b
              (switch-to-buffer b)
              (yas-insert-snippet))))
        (setq s (buffer-to-string b))
        (kill-buffer b)))
    (term-send-raw-string s)))

(defun pen-yas-insert-snippet-vterm ()
  (interactive)
  ;; Firstly, get off the current term window. It will go haywire with fz
  (let ((s))
    (save-window-excursion
      (switch-to-buffer "*scratch*")
      (let ((b (new-buffer-from-string
                ""
                "yastemp"
                (intern
                 (fz (chomp (pen-sn "find /home/shane/source/git/mullikine/yas-snippets -maxdepth 1 -mindepth 1 -type d | sed '/\\.git/d' | sed 's=^.*/=='"))
                     nil nil "yas-insert-snippet-term: ")))))
        (save-window-excursion
          (save-excursion
            (with-current-buffer b
              (switch-to-buffer b)
              (yas-insert-snippet))))
        (setq s (buffer-to-string b))
        (kill-buffer b)))
    (vterm-insert s)))

(provide 'pen-yasnippet)