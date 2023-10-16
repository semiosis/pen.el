(require 'markdown-mode)
(setq markdown-command "pandoc")

(setq markdown-fontify-code-blocks-natively t)

(defun md-html-export-to-html ()
  (interactive)
  (md-org-export-to-org)
  (pen-org-publish-current-file))

(defun pen-md-publish-current-file ()
  (interactive)

  (md-html-export-to-html))

(define-key markdown-mode-map (kbd "C-c M-p") #'pen-md-publish-current-file)

(define-key markdown-mode-map (kbd "M-l") nil)
(define-key markdown-mode-map (kbd "M-k") nil)

(use-package markdown-mode
  :custom
  (markdown-hide-markup nil)
  (markdown-bold-underscore t)
  (markdown-italic-underscore t)
  (markdown-header-scaling t)
  (markdown-indent-function t)
  (markdown-enable-math t)
  (markdown-hide-urls nil)
  :custom-face

  :mode "\\.md\\'")

(defun markdown-get-mode-here ()
  (interactive)
  (xc (symbol-name (save-excursion (markdown-get-lang-mode (markdown-code-block-lang))))))

(defun markdown-get-lang-here ()
  (interactive)
  (xc (save-excursion (markdown-code-block-lang))))

(use-package markdown-toc)

(defun markdown-match-inline-generic (regex last &optional faceless recurdepth)
  "Match inline REGEX from the point to LAST.
When FACELESS is non-nil, do not return matches where faces have been applied."
  (if (not recurdepth) (setq recurdepth 0))
  (setq recurdepth (1+ recurdepth))
  (if (> 5 recurdepth)
      (when (re-search-forward regex last t)
        (let ((bounds (markdown-code-block-at-pos (match-beginning 1)))
              (face (and faceless (text-property-not-all
                                   (match-beginning 0) (match-end 0) 'face nil))))
          (cond

           (bounds
            (when (< (goto-char (cl-second bounds)) last)
              (markdown-match-inline-generic regex last faceless recurdepth)))

           (face
            (when (< (goto-char (match-end 0)) last)
              (markdown-match-inline-generic regex last faceless recurdepth)))

           (t
            (<= (match-end 0) last)))))
    nil))

(defun markdown--browse-url-around-advice (proc url)
  (if (ire-match-p "^#" url)
      (let ((fragmentre (tr "-" "." (s-replace "#" "" url))))
        (next-line)
        (beginning-of-line)
        (re-search-forward fragmentre))
    (let ((res (apply proc (list url))))
      res)))
(advice-add 'markdown--browse-url :around #'markdown--browse-url-around-advice)

(defun md-glow-this-buffer ()
  (interactive)
  (let ((fp (get-path-nocreate))
        (s (buffer-string)))
    (if (derived-mode-p 'markdown-mode)
        (if (and (get-path-nocreate)
                 (f-file-p (get-path-nocreate)))
            (sps-pet (cmd "glow" "-f" fp))
          (sps-pet (cmd "glow" "-f") s))
      ;; (nw-term (concat "glow " (pen-q (get-path-nocreate)) " | pen-mnm | vs"))
      (message "not a markdown mode"))))

(advice-add 'markdown-syntax-propertize :around #'ignore-errors-around-advice)

(markdown-update-header-faces nil '(1.0 1.0 1.0 1.0 1.0 1.0))

(provide 'pen-markdown)
