(require 'mini-header-line)
(require 'minibuffer-header)
(require 'path-headerline-mode)

(defun ph-get-path-string ()
  (str (get-path nil t)))

;; This should simply display some status information about the current buffer.
;; Also, consider adding a date on the far-right - This is a good way to do it.
(defun ph--make-header ()
  ""
  (let* ((ph--full-header (ph-get-path-string))
         (ph--header (ph-get-path-string))
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
      (let ((datestr (str (e/date))))
        (concat (ph--with-face ph--header
                               :inverse-video t)
                (propertize " " 'display `(space :align-to (- right ,(length datestr))))
                (ph--with-face datestr
                               :weight 'bold))))))

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
