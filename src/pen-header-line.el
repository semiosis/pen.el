(require 'mini-header-line)
(require 'minibuffer-header)
(require 'path-headerline-mode)
(require 'universal-sidecar)
(require 'display-line-numbers)

;; This is extremely frequent
;; header-line-indent--watch-line-number-width is from display-line-numbers:
(defun header-line-indent--watch-line-number-width (_window)
  (let ((width (header-line-indent--line-number-width)))
    ;; (message (e/date))
    (setq header-line-indent-width width)
    (unless (= (length header-line-indent) width)
      (setq header-line-indent (make-string width ?\s)))))

;; header-line-indent--window-scroll-function is from display-line-numbers:
(defun header-line-indent--window-scroll-function (window _start)
  (let ((width (with-selected-window window
                 (truncate (line-number-display-width 'columns)))))
    ;; (message (e/date))
    (setq header-line-indent-width width)
    (unless (= (length header-line-indent) width)
      (setq header-line-indent (make-string width ?\s)))))

;; header-line-indent--line-number-width is from display-line-numbers:
(defun header-line-indent--line-number-width ()
  "Return the width taken by `display-line-numbers' in the current buffer."
  ;; line-number-display-width returns the value for the selected
  ;; window, which might not be the window in which the current buffer
  ;; is displayed.
  (if (not display-line-numbers)
      0
    (let ((cbuf-window (get-buffer-window (current-buffer) t)))
      (if (window-live-p cbuf-window)
          (with-selected-window cbuf-window
            (truncate
             (line-number-display-width 'columns)))
        4))))

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

  ;; This makes emacs go very slowly. So only use sparingly
  ;; (spl "ph--display-header" (buffer-name))

  ;; (sh/pen-log-view "ph--display-header")

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
                  (ca (ignore-errors (lsp-code-actions-at-point)))
                  ;; (battstr (str (get-battery-power)))
                  )
              ;; Instead of always using inverse-video, only use inverse-video when in black and white mode
              (concat
               ;; For (header-line-indent-mode), but don't use it
               ;; header-line-indent-mode is useful for tabulated-list-mode
               ;; (propertize "_" 'display
               ;;             `(space :align-to (+ header-line-indent-width 0)))
               (ph--with-face ph--header
                              'header-line-highlight)
               (propertize " " 'display `(space :align-to (-
                                                           right
                                                           ;; For the sidecar margin, so AM/PM isn't covered up
                                                           ,(if (universal-sidecar-visible-p)
                                                                1
                                                              0)
                                                           ,(length datestr))))

               ;; (if (ca (concat "[" (str (length ca)) " code actions]"))
               ;;     "")
               
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

  ;; This made emacs hang
  ;; (spl "ph--display-header" (buffer-name))

  (cond
   ((derived-mode-p 'tabulated-list-mode)
    nil)
   ((derived-mode-p 'calibredb-search-mode)
    nil)
   ((derived-mode-p 'calc-mode)
    nil)
   ((or (derived-mode-p 'calc-trail-mode)
        (string-equal "*Calc Trail*" (buffer-name)))
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
