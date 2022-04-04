(require 'imenu-anywhere)

(require 'dired-imenu)
(require 'go-imenu)
(require 'yaml-imenu)
(require 'imenu-list)

(setq imenu-auto-rescan t)

(defun pen-merge-imenu ()
  (interactive)
  (let ((mode-imenu (imenu-default-create-index-function))
        (custom-imenu (imenu--generic-function imenu-generic-expression)))
    (append mode-imenu custom-imenu)))

(add-hook 'python-mode-hook
          (lambda ()
            (add-to-list
             'imenu-generic-expression
             ;; menu title, regex, index
             ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Imenu.html
             '("Sections" "^#### \\[ \\(.*\\) \\]$" 1))
            (imenu-add-to-menubar "Position")
            (setq imenu-create-index-function 'pen-merge-imenu)))

(add-hook 'sx-question-mode
          (lambda ()
            (add-to-list
             'imenu-generic-expression
             ;; menu title, regex, index
             ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Imenu.html
             '("Accepted Answer" "^Accepted Answer$" 1))
            (imenu-add-to-menubar "Position")
            (setq imenu-create-index-function 'pen-merge-imenu)))

(add-hook 'Custom-mode-hook
          (lambda ()
            (add-to-list
             'imenu-generic-expression
             '("*" "^\\(Show Value [a-z-]*\\|Hide [a-z-]*\\)" 1))
            (imenu-add-to-menubar "Position")
            (setq imenu-create-index-function 'pen-merge-imenu)))

(defvar camdez/markdown-imenu-generic-expression
  '((nil "^#\\s-+\\(.+\\)$" 1)))

(defun camdez/markdown-imenu-configure ()
  (interactive)
  (setq imenu-generic-expression camdez/markdown-imenu-generic-expression))

(add-hook 'markdown-mode-hook 'camdez/markdown-imenu-configure)

(defset sx-question-imenu-generic-expression
  '(;; ("*Ans*" "^\\(Answer\\)$" 1)
    ("" "^\\(Accepted Answer\\| Comments\\|Answer\\)$" 1)))

;; ((nil "^\\s-*(def\\(un\\|subst\\|macro\\|advice\\)\\n\\s-+\\([-A-Za-z0-9+]+\\)" 2)
;;  ("*Vars*" "^\\s-*(def\\(var\\|const\\)\\n\\s-+\\([-A-Za-z0-9+]+\\)" 2)
;;  ("*Types*" "^\\s-*\\n(def\\(type-of-of-of\\|struct\\|class\\|ine-condition\\)\\n\\s-+\\([-A-Za-z0-9+]+\\)" 2))

(defun sx-question-imenu-configure ()
  (interactive)
  (setq imenu-generic-expression sx-question-imenu-generic-expression))
(add-hook 'sx-question-mode-hook 'sx-question-imenu-configure)

(imenu-list-minor-mode 1)

(defun imenu-preview-prev ()
  (interactive)
  (previous-line)
  (imenu-list-display-entry))

(defun imenu-preview-next ()
  (interactive)
  (next-line)
  (imenu-list-display-entry))

(defun buffer-currently-visible (buffer-name)
  (-contains? (mapcar 'buffer-name (mapcar 'window-buffer (window-list))) buffer-name))

(defun pen-toggle-show-imenu-list ()
  (interactive)
  (let ((cb (current-buffer)))
    (call-interactively 'imenu-list-minor-mode)

    (if imenu-list-minor-mode
        (imenu-list))
    (switch-to-buffer cb)))

(defun button-cloud-create-imenu-index ()
  (mapcar (lambda (e)
            (cons (car e) (set-marker (make-marker) (cdr e)))
            ;; e
            )

          (let ((face
                 (cond
                  ((>= (prefix-numeric-value current-prefix-arg) 16) 'glossary-candidate-button-face)
                  ((>= (prefix-numeric-value current-prefix-arg) 4) 'glossary-button-face)
                  (t nil))))
            (buttons-collect face))))

(defun helm-imenu ()
  "Preconfigured `helm' for `imenu'."
  (interactive)
  (require 'which-func)
  (unless helm-source-imenu
    (setq helm-source-imenu
          (helm-make-source "Imenu" 'helm-imenu-source
            :fuzzy-match helm-imenu-fuzzy-match)))
  (let* ((imenu-auto-rescan t)
         (helm-highlight-matches-around-point-max-lines 'never)
         (str (thing-at-point 'symbol))
         (init-reg (and str (concat "\\_<" (regexp-quote str) "\\_>")))
         (helm-execute-action-at-once-if-one
          helm-imenu-execute-action-at-once-if-one))
    (helm
     :sources 'helm-source-imenu
     :helm-full-frame t
     :default "*$&%(@#^$&%"
     :preselect nil
     :buffer "*helm imenu*")))

(defun helm-imenu-filter-correct-candidates (candidates)
  (-filter
   (lambda (e)
     (and
      (sequencep (car e))
      (or (bufferp (cdr e))
          (stringp (cdr e)))))
   candidates))

(defun helm-imenu-transformer (candidates)
  (cl-loop for (k . v) in
           candidates
           for bufname = (buffer-name
                          (pcase v
                            ((pred overlayp) (overlay-buffer v))
                            ((or (pred markerp) (pred integerp))
                             (marker-buffer v))))
           for types = (or (helm-imenu--get-prop k)
                           (list (if (with-current-buffer bufname
                                       (derived-mode-p 'prog-mode))
                                     "Function"
                                   "Top level")
                                 k))
           for disp1 = (mapconcat
                        (lambda (x)
                          (propertize
                           x 'face
                           (cl-loop for (p . f) in helm-imenu-type-faces
                                    when (string-match p x) return f
                                    finally return 'default)))
                        types helm-imenu-delimiter)
           for disp = (propertize disp1 'help-echo bufname 'types types)
           collect
           (cons disp (cons k v))))

(defun imenu--truncate-items (menulist)
  "Truncate all strings in MENULIST to `imenu-max-item-length'."
  (mapc (lambda (item)
	        (when (and (numberp imenu-max-item-length)
		                 (> (length (car item)) imenu-max-item-length))
	          (setcar item (substring (car item) 0 imenu-max-item-length)))
	        (when (imenu--subalist-p item)
	          (imenu--truncate-items (cdr item))))
	      (helm-imenu-filter-correct-candidates menulist)))

(defun pen-helm-imenu ()
  (interactive)
  (cond
   ((pen-is-glossary-file (get-path nil t))
    (call-interactively 'helm-imenu))
   ((eq major-mode 'help-mode) (call-interactively 'button-imenu))
   ((derived-mode-p 'Info-mode)
    (if (>= (prefix-numeric-value current-prefix-arg) 4)
        (try (call-interactively 'info-buttons-imenu)
             (call-interactively 'Info-menu))
      (try (call-interactively 'Info-menu)
           (call-interactively 'info-buttons-imenu))))
   ((derived-mode-p 'eww-mode)
    (if (>= (prefix-numeric-value current-prefix-arg) 4)
        (let ((current-prefix-arg nil))
          (call-interactively 'button-imenu))
      (call-interactively 'eww-imenu)))
   (t (call-interactively 'helm-imenu))))

(defun ace-to-imenu (tps)
  (-filter 'sequencep
           (mapcar
            (lambda (tp)
              (cons (car tp)
                    (byte-to-marker (cdr tp))))
            tps)))
(defun prev-prop-change (prop)
  (let ((p (previous-single-property-change (point) prop)))
    (if p
        (goto-char p))))

(defun next-prop-change (prop)
  (let ((p (next-single-property-change (point) prop)))
    (if p
        (goto-char p))))

(defun eww-next-fragment ()
  (interactive)
  (next-prop-change 'shr-target-id))

(defun eww-prev-fragment ()
  (interactive)
  (prev-prop-change 'shr-target-id))

(defun eww-get-fragment-name ()
  (let ((target (chomp (or (sor (get-text-property (point) 'shr-target-id)) "")))
        (thing
         (str (chomp (or (sor (swiper--line-at-point (point))) "")))))

    (if (and (sor target) (sor thing))
        (concat
         ""
         (chomp (or (sor target) ""))
         ;; "\n\t\t\t\t"
         "\t"
         (chomp (or (sor thing) "")))
      "")))

(defun eww-collect-imenu (&optional min max)
  "Collect the positions of fragment identifiers in the current eww buffer."
  (setq min (or min (point-min)))
  (setq max (or max (point-max)))

  (let ((end max)
        points)
    (save-excursion
      (goto-char min)
      (when (ignore-errors
              (eww-next-fragment)
              t)
        (let ((n (eww-get-fragment-name)))
          (push `(,n . ,(point)) points))
        (eww-next-fragment)
        (while (and (< (point) end)
                    (> (point) (cdar points)))
          (let ((n (eww-get-fragment-name)))
            (push `(,n . ,(point)) points))
          (eww-next-fragment))
        (nreverse points)))))

(defun info-collect-imenu (&optional min max)
  "Collect the positions of visible links in the current `Info-mode' buffer."
  (setq min (or min (point-min)))
  (setq max (or max (point-max)))

  (let ((end max)
        points)
    (save-excursion
      (goto-char min)
      (when (ignore-errors (Info-next-reference) t)
        (push (ace-link--info-current) points)
        (Info-next-reference)
        (while (and (< (point) end)
                    (> (point) (cdar points)))
          (push (ace-link--info-current) points)
          (Info-next-reference))
        (nreverse points)))))

(defun info-buttons-imenu ()
  "Different from Info-menu which lists the headings only."
  (interactive)

  (let* ((imenu-create-index-function (eval `(lambda () (info-collect-imenu ,(point-min) ,(point-max))))))
    (helm-imenu)))

(defun eww-imenu ()
  (interactive)

  (let* ((imenu-create-index-function (eval `(lambda () (eww-collect-imenu ,(point-min) ,(point-max))))))
    (helm-imenu)))

(add-hook 'Info-mode-hook (lambda () (setq-local imenu-create-index-function #'info-collect-imenu)))
(remove-hook 'Info-mode-hook (lambda () (setq-local imenu-create-index-function #'info-collect-imenu)))

(advice-add 'imenu-list-update :around #'ignore-errors-around-advice)

(define-key global-map (kbd "H-L") 'pen-toggle-show-imenu-list)
(define-key imenu-list-major-mode-map (kbd "n") 'imenu-preview-next)
(define-key imenu-list-major-mode-map (kbd "p") 'imenu-preview-prev)
(define-key Info-mode-map (kbd "M-l M-k m") 'info-imenu)
(define-key eww-mode-map (kbd "M-l M-k m") 'eww-imenu)

(provide 'pen-imenu)