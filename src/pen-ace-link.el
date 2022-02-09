(require 'ace-link)
(require 'pen-buttons)

(defun ace-link-copy-button-link ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (buttons-collect))
     (avy--style-fn avy-style)))
  (let* ((b (button-at-point))
         (lambda (pen-button-get-link b)))
    (if l
        (xc l))))

(advice-add 'ace-link-copy-button-link :around #'ignore-errors-around-advice)

(defun ace-link-button ()
  (interactive)
  (let ((pt (avy-with ace-link-help
              (avy-process
               (mapcar #'cdr (buttons-collect))
               (avy--style-fn avy-style)))))
    (ace-link--help-action pt)))

(defun ace-link-button-or-org ()
  (interactive)
  (let ((pt (avy-with ace-link-help
              (avy-process
               (mapcar #'cdr (-uniq
                              (append
                               (buttons-collect)
                               (ace-link--org-collect))))
               (avy--style-fn avy-style)))))
    (try
     (ace-link--org-action pt)
     (push-button))))

(defun ace-link ()
  "Call the ace link function for the current `major-mode'"
  (interactive)
  (or
   (cond ((eq major-mode 'Info-mode)
          (ace-link-info))
         ((string-equal "*button cloud*" (buffer-name))
          (ace-link-click-button))
         ((eq major-mode 'dockerfile-mode)
          (ace-link-click-button))
         ((member major-mode '(help-mode package-menu-mode geiser-doc-mode elbank-report-mode
                                         org-brain-visualize-mode
                                         elbank-overview-mode slime-trace-dialog-mode helpful-mode))
          (ace-link-button-or-org))
         ((eq major-mode 'markdown-mode)
          (ace-link-markdown))

         ((or
           (derived-mode-p 'go-mode)
           (derived-mode-p 'c++-mode))
          (ace-link-click-button))
         ((bound-and-true-p org-link-minor-mode)
          (ace-link-org))
         ((eq major-mode 'emacs-lisp-mode)
          (ace-link-org))
         ((eq major-mode 'Man-mode)
          (ace-link-goto-button))
         ((eq major-mode 'special-mode)
          (ace-link-click-widget))
         ((eq major-mode 'woman-mode)
          (ace-link-woman))
         ((eq major-mode 'eww-mode)
          (ace-link-eww))
         ((eq major-mode 'w3m-mode)
          (ace-link-w3m))
         ((or (member major-mode '(compilation-mode grep-mode))
              (bound-and-true-p compilation-shell-minor-mode))
          (ace-link-compilation))
         ((eq major-mode 'gnus-article-mode)
          (ace-link-gnus))
         ((or (memq major-mode '(org-mode erc-mode elfeed-show-mode term-mode))
              (derived-mode-p '(org-mode erc-mode elfeed-show-mode term-mode)))
          (ace-link-org))

         ((derived-mode-p 'text-mode)
          (or
           (ace-link-glossary-button)
           (ace-link-help)
           (ace-link-org)))
         ((eq major-mode 'org-agenda-mode)
          (ace-link-org-agenda))
         ((eq major-mode 'Custom-mode)
          (ace-link-custom))
         ((eq major-mode 'sldb-mode)
          (ace-link-sldb))
         ((eq major-mode 'slime-xref-mode)
          (ace-link-slime-xref))
         ((eq major-mode 'slime-inspector-mode)
          (ace-link-slime-inspector))
         ((eq major-mode 'indium-inspector-mode)
          (ace-link-indium-inspector))
         ((eq major-mode 'indium-debugger-frames-mode)
          (ace-link-indium-debugger-frames))
         ((and ace-link-fallback-function
               (funcall ace-link-fallback-function)))
         (t
          (ace-link-button)))))

(defun ace-link--help-collect ()
  "Collect the positions of visible links in the current `help-mode' buffer."
  (let ((skip (text-property-any
               (window-start) (window-end) 'button nil))
        candidates)
    (save-excursion
      (while (and skip (setq skip (text-property-not-all
                                   skip (window-end) 'button nil)))
        (goto-char skip)
        (push (cons (button-label (button-at skip)) skip) candidates)
        (setq skip (text-property-any (point) (window-end)
                                      'button nil))))
    (nreverse candidates)))

(defun ace-link--help-collect-brain ()
  "Collect the positions of visible links in the current `help-mode' buffer."
  (let ((skip (text-property-any
               (window-start) (window-end) 'button nil))
        candidates)
    (save-excursion
      (while (and skip (setq skip (text-property-not-all
                                   skip (window-end) 'button nil)))
        (goto-char skip)
        (push (cons (button-label (button-at skip)) skip) candidates)
        (setq skip (text-property-any (point) (window-end)
                                      'button nil))))
    (nreverse candidates)))

(defun ace-link--markdown-collect ()
  (let ((end (window-end))
        res)
    (save-excursion
      (goto-char (window-start))
      (while ;; (markdown-next-link)
        (re-search-forward (markdown-make-regex-link-generic) end t)
        (push
         (cons
          (buffer-substring-no-properties
           (match-beginning 0)
           (match-end 0))
          (match-beginning 0))
         res))
      (nreverse res))))

(defun ace-link--markdown-action (pt)
  (when (numberp pt)
    (goto-char pt)
    (call-interactively 'markdown-follow-thing-at-point)))

(defun ace-link-markdown ()
  "Open a visible link in a `markdown-mode' buffer."
  (interactive)
  (let ((pt (avy-with ace-link-markdown
              (avy-process
               (mapcar #'cdr (ace-link--markdown-collect))
               (avy--style-fn avy-style)))))
    (ace-link--markdown-action pt)))

(define-key pen-map (kbd "M-j M-y") 'ace-link-copy-button-link)
(define-key pen-map (kbd "M-j y") 'ace-link-copy-button-link)

(provide 'pen-ace-link)