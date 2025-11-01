(defsetface rdrview-number-face
  '((t ;;:inherit font-lock-constant-face
     :foreground "#B18145"
     :background "#221B29"
     :box (:line-width 2)
     :weight bold))
  "Face used to for rdrview references."
  :group 'verse)

(defconst pen-rdrview-minor-mode-map (make-keymap))
(define-key pen-rdrview-minor-mode-map (kbd "C-c /") #'rdrview-buttonize-buffer)

(define-minor-mode pen-rdrview-minor-mode
  "A minor mode for rdrview."
  :lighter " rdrview"
  :keymap pen-rdrview-minor-mode-map
  (setq-local avy-style 'at-full))

(define-button-type 'rdrview-button
  'action #'rdrview-button
  'follow-link t
  'face 'rdrview-number-face
  'help-echo "Go to reference"
  'help-args "test")

(defun rdrview-button (button)
  "BUTTON reference."
  (let ((refnum (button-get button 'refnum))
        (refurl (button-get button 'refurl)))

    (goto-char (point-min))
    ;; Here go to the URL
    (search-forward-regexp "^References$")
    (search-forward-regexp (format "^ *%d\\." (string-to-int refnum)))))

(defset rdrview-pattern "\\[\\([0-9]+\\)\\]")

;; (search-forward-regexp rdrview-pattern nil t)

(defun rdrview-buttonize-buffer ()
  "Turn all verse into button."
  (interactive)
  (with-writable-buffer
   (if (fboundp 'remove-overlays)
       (remove-overlays))

   (save-excursion
     (goto-char (point-min))
     (while (search-forward-regexp rdrview-pattern nil t)
       (let ((num (match-string-no-properties 1)))
         (make-text-button (match-beginning 0)
                           (match-end 0)
                           :type 'rdrview-button
                           'refnum num))))))

(defun rdrview (url)
  (interactive (let* ((p
                       (if (or (major-mode-p 'eww-mode)
                               (major-mode-p 'w3m-mode))
                           (get-path)
                         (read-string-hist "rdrview url: "))))
                 (list p)))

  (if (sor url)
      (rdrview-pager (pen-snc (pen-cmd-safe "pen-summarize-page" url)))))

(defun rdrview-pager (s)
  (interactive (list (read-string "rdrview contents or file path:")))

  (if (f-exists-p s)
      (setq s (e/cat s)))
  
  (with-current-buffer
      (etv s)
    (pen-rdrview-minor-mode 1)
    (rdrview-buttonize-buffer)
    (org-link-minor-mode 1)))

(provide 'pen-rdrview)
