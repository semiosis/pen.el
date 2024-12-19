(require 'mini-header-line)
(require 'minibuffer-header)
(require 'path-headerline-mode)
(require 'universal-sidecar)

(defsetface header-line
            '((t :foreground "#773575"
                 :background "#101010"
                 :weight normal
                 ;; :slant italic
                 ;; :underline t
                 ))
            "Header line face."
            :group 'pen-faces)


(defsetface header-line-highlight
            '((t :foreground "#773575"
                 :background "#101010"
                 ;; :inverse-video t
                 :weight normal))
            "Header line highlight face."
            :group 'pen-faces)


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

;; Get the current buffer name, too
(defun ph-get-path-string ()
  (let ((gp (get-path nil t nil t)))
    (if gp
        (str gp)
      "(eq nil (get-path nil t))")))

(defun ph-get-path-string-for-buf (buffer)
  (with-current-buffer buffer
    (let ((gp (get-path nil t nil t)))
      (if gp
          (str gp)
        (concat default-directory "  [j:get-path]")
        ;; "j:get-path"
        ))))

(defun get-battery-power ()
  (interactive)
  (ifietv
   (esed "[^:]*: " ""
         (snc "pen-ci -nd -f -t 20 acpi -b"))))

;; This should simply display some status information about the current buffer.
;; Also, consider adding a date on the far-right - This is a good way to do it.
(defun ph--make-header (&optional nodate buffer nobatt)
  ""
  (setq buffer (or buffer (current-buffer)))

  (let ((fh
         (mnm (ph-get-path-string-for-buf buffer))
         ;; (shrink-path-file (ph-get-path-string-for-buf buffer))
         ))
    (if fh
        (let* ((ph--full-header fh)
               (ph--header fh)
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
            (let ((datestr (str (ph-get-date)))
                  ;; (battstr (str (get-battery-power)))
                  )
              ;; Instead of always using inverse-video, only use inverse-video when in black and white mode
              (concat (ph--with-face ph--header
                                     'header-line-highlight)
                      (propertize " " 'display `(space :align-to (-
                                                                  right
                                                                  ;; For the sidecar margin, so AM/PM isn't covered up
                                                                  ,(if (universal-sidecar-visible-p)
                                                                       1
                                                                     0)
                                                                  ,(length datestr))))
                      ;; (if (not nobatt)
                      ;;     (ph--with-face battstr
                      ;;                    'header-line-highlight)
                      ;;   "")
                      ;; " "
                      (if (not nodate)
                          (ph--with-face datestr
                                         'header-line-highlight)
                        ""))))))))

(defun ph--display-header ()
  "Display path on headerline."

  (cond
   ((derived-mode-p 'tabulated-list-mode)
    nil)
   ((major-mode-p 'universal-sidecar-buffer-mode)
    ;; (path-header-line-off)
    ;; (universal-sidecar-refresh)
    ;; (refresh-frame)
    (setq header-line-format
          '("" ;; invocation-name
            (:eval (if (ph--make-header t)
                       (ph--make-header t)
                     "%b")))))
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


;; This fixed a problem with a disappearing header line
(defun kill-all-local-variables-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (ph--display-header)
    res))
(advice-add 'kill-all-local-variables :around #'kill-all-local-variables-around-advice)
;; (advice-remove 'kill-all-local-variables #'kill-all-local-variables-around-advice)

(provide 'pen-header-line)
