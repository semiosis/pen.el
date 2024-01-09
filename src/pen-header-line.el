(require 'mini-header-line)
(require 'minibuffer-header)
(require 'path-headerline-mode)

;; This should simply display some status information about the current buffer.
;; Also, consider adding a date on the far-right - This is a good way to do it.
(defun ph--make-header ()
  ""
  (let* ((ph--full-header (get-path nil t))
         (ph--header (file-name-directory ph--full-header))
         (ph--drop-str "[...]"))
    (if (> (length ph--full-header)
           (window-body-width))
        (if (> (length ph--header)
               (window-body-width))
            (progn
              (concat (ph--with-face ph--drop-str
                                     :background "blue"
                                     :weight 'bold)
                      (ph--with-face (substring ph--header
                                                (+ (- (length ph--header)
                                                      (window-body-width))
                                                   (length ph--drop-str))
                                                (length ph--header))
                                     :weight 'bold)))
          (concat (ph--with-face ph--header
                                 :foreground "#8fb28f"
                                 :weight 'bold)))
      (concat (ph--with-face ph--header
                             :weight 'bold
                             :foreground "#8fb28f")
              (ph--with-face (file-name-nondirectory buffer-file-name)
                             :weight 'bold)))))

(defun ph--display-header ()
  "Display path on headerline."
  (setq header-line-format
        '("" ;; invocation-name
          (:eval (if (ph--make-header)
                     (ph--make-header)
                   "%b")))))

(path-headerline-mode t)
;; (path-headerline-mode -1)

;; mini-header-line-mode
;; places the modeline up the top, just below the tab bar
;; but it has a different format.
;; (mini-header-line-mode t)
;; (mini-header-line-mode -1)

(minibuffer-header-mode t)

(provide 'pen-header-line)
