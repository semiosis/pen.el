(defset hkey-init nil)
(require 'hyperbole)

;; (defun hkey-initialize-around-advice (proc &rest args)
;;                                         ; bypass function entirely and use my own
;;                                         ; proc
;;   (let ((res (apply 'pen-hkey-initialize args)))
;;     res))
;; (advice-add 'hkey-initialize :around #'hkey-initialize-around-advice)

;; hkey-either "Execute `action-key' or with non-nil ARG execute `assist-key'."
;; Invoke the Action Key. With C-u, Invoke the Assist Key

;; I want H-W to be used by prog.el instead
(hkey-global-set-key (kbd"H-W m") 'hkey-either)
(hkey-global-set-key (kbd"H-W 1") 'action-key)
(hkey-global-set-key (kbd"H-W 2") 'assist-key)
(hkey-global-set-key (kbd"H-W a") 'hkey-help)
(hkey-global-set-key (kbd "H-W h") 'hyperbole)
(hkey-global-set-key (kbd "H-W o") 'hkey-operate)

;; (hkey-global-set-key (kbd "H-f") 'hyperbole)
;; (hkey-global-set-key (kbd "H-f") nil)

;; (hkey-maybe-global-set-key (kbd "\M-o") 'hkey-operate)
;; (hkey-maybe-global-set-key (kbd "\C-c@") 'hycontrol-windows-grid t)


(defun pen-hui-act ()
  (interactive)
  (try
   ;; explicit
   (call-interactively 'hui:ebut-act)

   ;; This is implicit
   (call-interactively 'hui:hbut-act)
   ))

; <(say hi)>

(hkey-global-set-key (kbd "H-W g") 'pen-hui-act t)
(hkey-global-set-key (kbd "H-W E") 'hui:ebut-create)
(hkey-global-set-key (kbd "H-W e") 'hui:ebut-act)
(hkey-global-set-key (kbd "H-W i") 'hui:hbut-act)
(hkey-maybe-global-set-key (kbd "H-W c") 'hui:ebut-create t)
(hkey-maybe-global-set-key (kbd "H-W d") 'hui:ebut-delete t)
(hkey-maybe-global-set-key (kbd "H-W s") 'hui:ebut-rename t)
(hkey-maybe-global-set-key (kbd "H-W r") 'hui-select-thing)
;; (hkey-maybe-global-set-key (kbd "\C-c\\") 'hycontrol-enable-windows-mode)
(hkey-maybe-global-set-key (kbd "H-W w") 'hui-search-web)
(hkey-maybe-global-set-key (kbd "H-W ,") 'hui-select-goto-matching-delimiter t)
;; (pen-hkey-initialize)

;; (define-key global-map (kbd "H-W") 'hyperbole)


;; TODO Finish this. Low priority
(defun pen-hyperbole-list-implicit-buttons (&optional arg)
  "Pretty print the attributes of a button or buttons.
Return number of buttons reported on or nil if none."
  (let* ((but (hbut:at-p))
         (curr-key (and but (hattr:get but 'lbl-key)))
         (key-src (or (and but (hattr:get but 'loc)) (hbut:key-src)))
         (lbl-lst (if curr-key (list (ebut:key-to-label curr-key))))
         (key-buf (current-buffer))
         (buf-name (hypb:help-buf-name))
         (attribs)
         ;; Ensure these do not invoke with-output-to-temp-buffer a second time.
         (temp-buffer-show-hook)
         (temp-buffer-show-function))
    (if lbl-lst
        (progn
          (with-help-window buf-name
            (princ hbut:source-prefix)
            (prin1 key-src)
            (terpri)
            (terpri)
            (mapcar
             (lambda (lbl)
               (if (setq attribs (hattr:list but))
                   (progn
                     (princ (if (ibut:is-p but)
                                lbl
                              (concat ebut:start lbl ebut:end)))
                     (terpri)
                     (let ((doc (actype:doc but (= 1 (length lbl-lst)))))
                       (if doc
                           (progn
                             (princ "  ")
                             (princ doc)
                             (terpri))))
                     (hattr:report
                      attribs)
                     (terpri))))
             lbl-lst))
          (length lbl-lst)))))

(provide 'pen-hyperbole)
