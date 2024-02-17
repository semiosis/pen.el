;; v +/"hypertext-mode" "$EMACSD/pen.el/src/pen-manage-minor-mode.el"

;; https://dantorop.info/project/emacs-animation/

(defset hypertext-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c l") 'org-toggle-link-display)
    map))

(define-derived-mode hypertext-mode fundamental-mode "Hypertext"
  "Mode for clickable ascii text graphics.
\\{hypertext-mode-map}"
  (setq buffer-read-only t)
  (buffer-disable-undo))

(defun open-hypertext (&optional filename)
  "Create a new untitled buffer from a string."
  (interactive)

  ;; [[el:(open-hypertext "$HOME/notes/ws/ascii-adventures/house.org")]]

  ;; [[el:(etv (pps (org-parser-parse-file (umn "$HOME/notes/ws/ascii-adventures/house.org"))))]]

  (setq filename (umn filename))
  
  (let ((parse (org-parser-parse-file filename)))

    (if (not bufname)
        (setq bufname "*untitled*"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents
            (if (stringp contents)
                (insert contents)
              (insert (str contents))))
        (beginning-of-buffer)
        (if mode (funcall mode))
        (pen-add-ink-change-hook))
      buffer)))

;; Remember
;; | =C-x C-q= | =read-only-mode= | =global-map=

(comment
 (define-key hypertext-mode-map (kbd "C-c l") 'org-toggle-link-display))

(provide 'pen-hypertext)
