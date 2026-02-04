(defun isearch-forward-region-cleanup ()
  "turn off variable, widen"
  (if isearch-for-region
      (widen))
  (setq isearch-for-region nil))

(defvar isearch-for-region nil
  "variable used to indicate we're in region search")

(add-hook 'isearch-mode-end-hook 'isearch-forward-region-cleanup)

;; search-nonincremental-instead

(defvar pen-isearch-max-file-size 1000000)

(defun pen-basic-forward-search (&optional literal-string)
  (interactive (list (read-string-hist "Forward Search literal string: ")))

  (search-forward literal-string))

(defun pen-basic-backward-search (&optional literal-string)
  (interactive (list (read-string-hist "Backward Search literal string: ")))

  (search-backward literal-string))

(defun isearch-forward-region (&optional regexp-p no-recursive-edit)
  "Do an isearch-forward, but narrow to region first."
  (interactive "P\np")
  (if (pen-selected-p)
      (progn
        (narrow-to-region (point) (mark))
        (deactivate-mark)
        (goto-char (point-min))
        (setq isearch-for-region t)
        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (isearch-mode t nil nil (not no-recursive-edit))
          (isearch-mode t (not (null regexp-p)) nil (not no-recursive-edit))))
    (if (> (buffer-size) pen-isearch-max-file-size)
        (call-interactively 'pen-basic-forward-search)
      (call-interactively 'pen-isearch-forward))))

(defun isearch-backward-region (&optional regexp-p no-recursive-edit)
  "Do an isearch-backward, but narrow to region first."
  (interactive "P\np")
  (if (pen-selected-p)
      (progn
        (narrow-to-region (point) (mark))
        (deactivate-mark)
        (goto-char (point-min))
        (setq isearch-for-region t)
        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (isearch-mode t nil nil (not no-recursive-edit))
          (isearch-mode t (not (null regexp-p)) nil (not no-recursive-edit))))
    (if (> (buffer-size) pen-isearch-max-file-size)
        (call-interactively 'pen-basic-backward-search)
      (call-interactively 'pen-isearch-backward))))

(define-key global-map (kbd "C-s") #'isearch-forward-region)
(define-key global-map (kbd "C-r") #'isearch-backward-region)

;; Not sure if works
(defmacro save-region-excursion (&rest body)
  `(pen-with-advice
       (advise-to-save-region)
     ,@body))

(progn
  ;; http://yummymelon.com/devnull/improving-emacs-isearch-usability-with-transient.html
  (require 'transient)
  (transient-define-prefix cc/isearch-menu ()
    "isearch Menu"
    [["Edit Search String"
      ("e"
       "Edit the search string (recursive)"
       isearch-edit-string
       :transient nil)
      ("w"
       "Pull next word or character word from buffer"
       isearch-yank-word-or-char
       :transient nil)
      ("s"
       "Pull next symbol or character from buffer"
       isearch-yank-symbol-or-char
       :transient nil)
      ("l"
       "Pull rest of line from buffer"
       isearch-yank-line
       :transient nil)
      ("y"
       "Pull string from kill ring"
       isearch-yank-kill
       :transient nil)
      ("t"
       "Pull thing from buffer"
       isearch-forward-thing-at-point
       :transient nil)]

     ["Replace"
      ("q"
       "Start ‘query-replace’"
       isearch-query-replace
       :if-nil buffer-read-only
       :transient nil)
      ("x"
       "Start ‘query-replace-regexp’"
       isearch-query-replace-regexp
       :if-nil buffer-read-only
       :transient nil)]]

    [["Toggle"
      ("X"
       "Toggle regexp searching"
       isearch-toggle-regexp
       :transient nil)
      ("S"
       "Toggle symbol searching"
       isearch-toggle-symbol
       :transient nil)
      ("W"
       "Toggle word searching"
       isearch-toggle-word
       :transient nil)
      ("F"
       "Toggle case fold"
       isearch-toggle-case-fold
       :transient nil)
      ("L"
       "Toggle lax whitespace"
       isearch-toggle-lax-whitespace
       :transient nil)]

     ["Misc"
      ("o"
       "occur"
       isearch-occur
       :transient nil)]])

;; (define-key isearch-mode-map (kbd "<f2>") 'cc/isearch-menu)
  )

(provide 'pen-isearch)
