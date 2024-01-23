(require 'mini-header-line)
(require 'minibuffer-header)
(require 'path-headerline-mode)

;; (defset pen-header-line-path-last-time (e/date))
;; (defset pen-header-line-path-last-path (get-path nil t))

;; I need this to be memoized and re-queried per-second max, and also per-buffer

(comment
 (defun ph-get-path-string ()
   (let ((gd (e/date "%F %a %T")))
     (if (not (string-equal gd pen-header-line-path-last-time))
         (let ((gp (get-path nil t)))
           (setq pen-header-line-path-last-path gp)
           (setq pen-header-line-path-last-time gd)
           (str gp)
           "get-path=nil")))))

(defun ph-get-date ()
  (e/date "%F %a %r"))

(defun ph-get-path-string ()
  (let ((gp (get-path nil t)))
    (if gp
        (str gp)
      "(eq nil (get-path nil t))")))

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
      (let ((datestr (str (ph-get-date))))
        (concat (ph--with-face ph--header
                               :inverse-video t)
                (propertize " " 'display `(space :align-to (- right ,(length datestr))))
                (ph--with-face datestr
                               :inverse-video t))))))

(defun ph--display-header ()
  "Display path on headerline."


  (cond ((major-mode-p 'universal-sidecar-buffer-mode)
         (path-header-line-off))
        (t
         (setq header-line-format
               '("" ;; invocation-name
                 (:eval (if (ph--make-header)
                            (ph--make-header)
                          "%b")))))))

;; How do I disable this for universal-sidecar-buffer-mode ?
(path-headerline-mode t)
;; (path-headerline-mode -1)

;; mini-header-line-mode
;; places the modeline up the top, just below the tab bar
;; but it has a different format.
;; (mini-header-line-mode t)
;; (mini-header-line-mode -1)

(minibuffer-header-mode t)

(provide 'pen-header-line)
