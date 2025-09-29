(setq w3m-session-crash-recovery nil)

(setq w3m-command (executable-find "w3m"))

(define-key w3m-mode-map (kbd "<up>") nil)
(define-key w3m-mode-map (kbd "<down>") nil)
(define-key w3m-mode-map (kbd "<left>") nil)
(define-key w3m-mode-map (kbd "<right>") nil)
(define-key w3m-mode-map (kbd "p") 'w3m-view-previous-page)
(define-key w3m-mode-map (kbd "n") 'w3m-view-this-url)
(define-key w3m-mode-map (kbd "w") 'pen-yank-path)

;; Need to unbind M-l so that global bindings work
(define-key w3m-mode-map (kbd "M-l") nil)

(defface w3m-paragraph '((t (:bold t)))
  "Face used for displaying paragraph text."
  :group 'w3m-face)

(set-face-foreground 'w3m-paragraph "#40f040")
(set-face-background 'w3m-paragraph "#105010")

(defun w3m-fontify-paragraph ()
  "Fontify paragraph text in the buffer containing halfdump."
  (goto-char (point-min))
  ;; (tv (buffer-string))
  (while (search-forward "<p>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</p[ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'w3m-paragraph)))))

;; (remove-hook 'w3m-fontify-before-hook 'w3m-fontify-paragraph)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-paragraph)
(remove-hook 'w3m-fontify-before-hook 'w3m-fontify-paragraph)

(defface w3m-ul '((t (:bold t)))
  "Face used for displaying ul text."
  :group 'w3m-face)

(set-face-foreground 'w3m-ul "#f04040")
(set-face-background 'w3m-ul "#501010")

(defun w3m-fontify-ul ()
  "Fontify ul text in the buffer containing halfdump."
  (goto-char (point-min))
  ;; (tv (buffer-string))
  (while (search-forward "<ul>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (re-search-forward "</ul[ \t\r\f\n]*>" nil t)
	    (delete-region (match-beginning 0) (match-end 0))
	    (w3m-add-face-property start (match-beginning 0) 'w3m-ul)))))

;; (remove-hook 'w3m-fontify-before-hook 'w3m-fontify-ul)
(add-hook 'w3m-fontify-before-hook 'w3m-fontify-ul)
(remove-hook 'w3m-fontify-before-hook 'w3m-fontify-ul)

(defun w3m-show-html-for-fontify ()
  (tv (buffer-string) :tm_wincmd "nw"))

(defun w3m-enable-display-html-for-fontify ()
  (interactive)
  (add-hook 'w3m-fontify-before-hook 'w3m-show-html-for-fontify))

(defun w3m-disable-display-html-for-fontify ()
  (interactive)
  (remove-hook 'w3m-fontify-before-hook 'w3m-show-html-for-fontify))

;; I think the best way to get the interlinear text from biblehub would be to
;; make a "ved" script
;; https://biblehub.com/interlinear/genesis/1-1.htm

;; TODO Add w3m-horizontal-recenter somewhere. It used to be M-l

;; ocif curl "https://biblehub.com/interlinear/genesis/1-1.htm" | elinks-dump | sed -z "s/1\\n\\n/\\n/" | sed "s/   [0-9]\\+$//g" | sed "s/ / /g" | erase-trailing-whitespace | sed -e 's/^\s*//' | sed "s/ \\[e\\]$//" | sed "s/ \\+/ /g" | ved "-m" "V/Click for Chapter\\<CR>ddd/IFrame\\<CR>VGd"

(provide 'pen-w3m)
