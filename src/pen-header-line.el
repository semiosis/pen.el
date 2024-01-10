(require 'mini-header-line)
(require 'minibuffer-header)
(require 'path-headerline-mode)

(defset pen-header-line-path-last-time (e/date))
(defset pen-header-line-path-last-path (get-path nil t))

;; I need this to be memoized and re-queried per-second max
;;

(defun ph-get-path-string ()
  (let ((gd (e/date)))
    (if (not (string-equal gd pen-header-line-path-last-time))
        (let ((gp (get-path nil t)))
          (if gp
              (str gp)
            "get-path=nil")))))

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
                               :inverse-video t))))))

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
