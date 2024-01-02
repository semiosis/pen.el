(setq-default show-trailing-whitespace t)

(require 'whitespace)
(require 'highlight-chars)

;; whitespace-mode can't highlight tabs, at least under my setup

;; (setq whitespace-style '(trailing tabs newline tab-mark newline-mark))

;; (setq whitespace-style '(face tabs))
;; (setq tab-face (make-face 'tab-face))
;; (set-face-background 'tab-face "red")
;; (setq whitespace-tab 'tab-face)
;; (whitespace-mode)

;; (setq whitespace-style '(trailing tabs newline tab-mark newline-mark))
(setq whitespace-style '(trailing tabs tab-mark))
;; (setq whitespace-tab 'underline)
(set-face-foreground 'whitespace-tab "#111111")
(set-face-background 'whitespace-tab "#000000")
(setq whitespace-tab 'whitespace-tab)

;; customise this to change the tab character
; whitespace-display-mappings

;; This makes the » appear but doesn't do the coloring
(global-whitespace-mode -1)
(global-whitespace-mode 1)

;; highlight chars works to highlight tabs
;; I need a combination of both whitespace-mode and highlight-chars to achieve this
;; However, *apparently* it breaks term, so I need to remove the hook from term.

;; [[cg:Highlight-Characters]]
(require 'highlight-chars)
;; (set-face-foreground 'hc-tab "#333333")
;; (set-face-foreground 'hc-tab "#ff3333")
;; (set-face-foreground 'hc-tab "#000000")
;; (set-face-foreground 'hc-tab "#228822")
;; (set-face-background 'hc-tab "#111111")

(set-face-foreground 'hc-tab "#111111")
(set-face-background 'hc-tab "#222222")

;; This broke syntax highlighting everywhere
;; (add-hook 'font-lock-mode-hook 'hc-highlight-tabs)
;; (remove-hook 'font-lock-mode-hook 'hc-highlight-tabs)

;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Font-Lock.html
(defun hc-highlight-tabs-maybe ()
  ;; This only highlights the tabs - it doesn't actually make the »
  ;; I've disabled it, now tabs appear grey, which is OK.
  ;; reenabled it
  (ignore-errors
    (cond
     ((major-mode-p 'fundamental-mode) (hc-highlight-tabs))
     ((derived-mode-p 'prog-mode) (hc-highlight-tabs))
     ((derived-mode-p 'org-mode) (hc-highlight-tabs))
     ((derived-mode-p 'text-mode) (hc-highlight-tabs))))
  t)

(add-hook 'font-lock-mode-hook 'hc-highlight-tabs-maybe)

;; (defun better-whitespace ()
;;   (interactive)
;;   (global-whitespace-mode 0)
;;   ;; I don't care about long lines
;;
;;   (let ((ws-small '(face lines-tail))
;;         (ws-big '(face tabs spaces trailing lines-tail space-before-tab
;;                        newline indentation empty space-after-tab space-mark
;;                        tab-mark newline-mark)))
;;     (if (eq whitespace-style ws-small)
;;         (setq whitespace-style ws-big)
;;       (setq whitespace-style ws-small)))
;;   (global-whitespace-mode 1))
;;
;; (define-key global-map (kbd "C-x t W") 'better-whitespace)

(provide 'pen-whitespace)
