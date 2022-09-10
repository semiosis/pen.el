(require 'hide-mode-line)

(require 'face-remap)

(require 'default-text-scale)

(default-text-scale-mode 1)

(defun disable-truncate-code ()
  (setq print-level nil)
  (setq print-length nil))
(add-hook 'prog-mode-hook 'disable-truncate-code)

(defun kill-buffer-if-not-current (name)
  (ignore-errors
    (if (not (string-equal name (buffer-name)))
        (if (buffer-exists name)
            (progn
              (ignore-errors (kill-buffer name))
              (message (concat "killed buffer " name " because it's slow")))))))

(scroll-bar-mode -1)

(defun toggle-chrome ()
  (interactive)
  (kill-buffer-if-not-current "*aws-instances*")
  (kill-buffer-if-not-current "*docker-containers*")
  (kill-buffer-if-not-current "*docker-images*")
  (kill-buffer-if-not-current "*docker-machines*")
  (if (bound-and-true-p global-display-line-numbers-mode)
      (progn
        (if lsp-mode
            (lsp-headerline-breadcrumb-mode -1))
        (global-display-line-numbers-mode -1)
        (if (ignore-errors (sor header-line-format))
            (setq header-line-format
                  (s-replace-regexp "^    " "" header-line-format)))
        (global-hide-mode-line-mode 1)
        (visual-line-mode -1)
        (setq-default truncate-lines t)
        (setq truncate-lines t)
        (menu-bar-mode -1))
    (progn
      (if lsp-mode
          (lsp-headerline-breadcrumb-mode 1))
      (global-display-line-numbers-mode 1)
      (if (ignore-errors (sor header-line-format))
          (setq header-line-format (concat "    " header-line-format)))
      (global-hide-mode-line-mode -1)
      (visual-line-mode 1)
      (setq-default truncate-lines nil)
      (setq truncate-lines nil)
      (menu-bar-mode 1))))
(defalias 'toggle-minimal-clutter 'toggle-chrome)

;; There's no way to get truncate-lines from being enabled by default.
;; It must be set as default to t for visual-line mode to work.
;; So if I want line wrap, just toggle chrome a couple of times.
(global-display-line-numbers-mode 1)
(global-hide-mode-line-mode -1)
(if (inside-docker-p)
    (menu-bar-mode 1))
(visual-line-mode 1)

(define-key visual-line-mode-map (kbd "<remap>") nil)
(global-set-key (kbd "<S-f4>") 'toggle-chrome)

(provide 'pen-ui)
