(require 'hide-mode-line)

(require 'face-remap)

(require 'default-text-scale)
(require 'universal-sidecar)

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

(defun toggle-chrome-extras (&optional off on)
  (interactive)

  ;; It seems aesthetically better to toggle the tab-bar with the sidecar
  ;; even though the tab-bar is currently useless
  (cond (off (progn
               (magit-margin-off)
               (universal-sidecar-off)
               (tab-bar-mode -1)
               ))
        (on (progn
              (magit-margin-on)
              (universal-sidecar-on)
              (tab-bar-mode 1)
              ))
        (t
         (if (universal-sidecar-visible-p)
             (progn
               (magit-margin-off)
               (universal-sidecar-off)
               (tab-bar-mode -1)
               )
           (progn
             (magit-margin-on)
             (universal-sidecar-on)
             (tab-bar-mode 1))))))

(defun toggle-chrome ()
  (interactive)
  (let ((gparg (prefix-numeric-value current-prefix-arg))
        (current-prefix-arg nil))
    (cond ((>= gparg 16) nil)
          ((>= gparg 4)
           (if (string-equal "top" (pen-snc "tmux show -g -p pane-border-status | cut -d ' ' -f 2"))
               (pen-snc "pen-tm disable-border-status")
             (pen-snc "pen-tm enable-border-status")))
          (t
           (progn
             (kill-buffer-if-not-current "*aws-instances*")
             (kill-buffer-if-not-current "*docker-containers*")
             (kill-buffer-if-not-current "*docker-images*")
             (kill-buffer-if-not-current "*docker-machines*")
             (if (bound-and-true-p global-display-line-numbers-mode)
                 (progn
                   (if lsp-mode
                       (lsp-headerline-breadcrumb-mode -1))
                   (global-display-line-numbers-mode -1)
                   (if (stringp header-line-format)
                       (setq header-line-format
                             (s-replace-regexp "^    " "" header-line-format)))
                   (global-hide-mode-line-mode 1)
                   ;; (visual-line-mode -1)
                   ;; (setq-default truncate-lines t)
                   ;; (setq truncate-lines t)
                   (menu-bar-mode -1)
                   ;; (tab-bar-mode -1)
                   (pen-snc "tmux set status off")
                   ;; (pen-snc "tmux set status off; tmux set -g pane-border-status off")
                   )
               (progn
                 (if lsp-mode
                     (lsp-headerline-breadcrumb-mode 1))
                 (global-display-line-numbers-mode 1)
                 (if (stringp header-line-format)
                     (setq header-line-format (concat "    " header-line-format)))
                 (global-hide-mode-line-mode -1)
                 ;; (visual-line-mode 1)
                 ;; (setq-default truncate-lines nil)
                 ;; (setq truncate-lines nil)
                 (menu-bar-mode 1)
                 ;; (tab-bar-mode 1)
                 (pen-snc "tmux set status on")
                 ;; (pen-snc "tmux set status on; tmux set -g pane-border-status top")
                 ;; (pen-snc "tmux set status on; tmux set -g pane-border-status bottom")
                 )))))))
(defalias 'toggle-minimal-clutter 'toggle-chrome)

(visual-line-mode 1)
(setq-default truncate-lines nil)
(setq truncate-lines nil)

;; There's no way to get truncate-lines from being enabled by default.
;; It must be set as default to t for visual-line mode to work.
;; So if I want line wrap, just toggle chrome a couple of times.
(global-display-line-numbers-mode 1)
(global-hide-mode-line-mode -1)
(if (inside-docker-p)
    (menu-bar-mode 1))
(visual-line-mode 1)

(define-key visual-line-mode-map (kbd "<remap>") nil)
(global-set-key (kbd "<S-f2>") 'toggle-chrome-extras)
(global-set-key (kbd "<S-f4>") 'toggle-chrome)
(global-set-key (kbd "<S-f5>") 'global-display-line-numbers-mode)
(global-set-key (kbd "<S-f6>") 'toggle-truncate-lines)

(provide 'pen-ui)
