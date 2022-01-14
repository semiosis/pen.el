;; (add-hook 'buffer-list-update-hook
;;           '(lambda ()
;;              (unless (display-graphic-p)
;;                (if (equal major-mode 'org-mode)
;;                    (progn
;;                      (define-key input-decode-map "\e[1;5D" [M-left])
;;                      (define-key input-decode-map "\e[1;5C" [M-right]))
;;                  (define-key input-decode-map "\e[1;5D" [C-left])
;;                  (define-key input-decode-map "\e[1;5C" [C-right])))))

;; These appear to get overridden later
;; Therefore put it in an even better map, the translation map
;; Complete this list
;; (define-key global-map (kbd "<f13>") (kbd "<S-f1>"))
;; (define-key global-map (kbd "<f14>") (kbd "<S-f2>"))
;; (define-key global-map (kbd "<f15>") (kbd "<S-f3>"))
;; (define-key global-map (kbd "<f16>") (kbd "<S-f4>"))
;; (define-key global-map (kbd "<f17>") (kbd "<S-f5>"))
;; (define-key global-map (kbd "<f18>") (kbd "<S-f6>"))
;; (define-key global-map (kbd "<f19>") (kbd "<S-f7>"))
;; (define-key global-map (kbd "<f20>") (kbd "<S-f8>"))
;; (define-key global-map (kbd "<f21>") (kbd "<S-f9>"))
(define-key key-translation-map (kbd "<f13>") (kbd "<S-f1>"))
(define-key key-translation-map (kbd "<f14>") (kbd "<S-f2>"))
(define-key key-translation-map (kbd "<f15>") (kbd "<S-f3>"))
(define-key key-translation-map (kbd "<f16>") (kbd "<S-f4>"))
(define-key key-translation-map (kbd "<f17>") (kbd "<S-f5>"))
(define-key key-translation-map (kbd "<f18>") (kbd "<S-f6>"))
(define-key key-translation-map (kbd "<f19>") (kbd "<S-f7>"))
(define-key key-translation-map (kbd "<f20>") (kbd "<S-f8>"))
(define-key key-translation-map (kbd "<f21>") (kbd "<S-f9>"))

;; https://www.emacswiki.org/emacs/TheMysteriousCaseOfShiftedFunctionKeys

(global-set-key [S-f10] 'help-with-tutorial)

(progn
  ;; Not sure if these are necessary
  (define-key input-decode-map (kbd "<S-f10>") nil)
  (define-key function-key-map (kbd "<S-f10>") nil)
  (define-key key-translation-map (kbd "<S-f10>") nil)
  (define-key key-translation-map (kbd "<S-f11>") nil)
  (define-key key-translation-map (kbd "<S-f12>") nil)

  (define-key function-key-map (kbd "<f22>") (kbd "<S-f10>"))
  (define-key function-key-map (kbd "<f23>") (kbd "<S-f11>"))
  (define-key function-key-map (kbd "<f24>") (kbd "<S-f12>")))

(define-key input-decode-map (kbd "<f22>") (kbd "<S-f10>"))
(define-key input-decode-map (kbd "<f23>") (kbd "<S-f11>"))
(define-key input-decode-map (kbd "<f24>") (kbd "<S-f12>"))

;; Why doen't these exist?
;; I needed my new infocomp definitions. They exist now
(define-key key-translation-map (kbd "<f22>") (kbd "<S-f10>"))
(define-key key-translation-map (kbd "<f23>") (kbd "<S-f11>"))
(define-key key-translation-map (kbd "<f24>") (kbd "<S-f12>"))

(defun yank-function-from-binding (sequence)
  "Copies the function name associated with a key binding after entering it"
  (interactive (list (format "%s" (key-description (read-key-sequence-vector "Key: ")))))
  (let* ((fun (str (key-binding (kbd sequence)))))
    (xc fun)
    (message "%s" (concat "copied: " fun))))

(defun test-yank-function-from-binding ()
  (yank-function-from-binding "\e[21;2~")
  (yank-function-from-binding "[S-f10]")
  (yank-function-from-binding "<S-f10>")
  (yank-function-from-binding "<f10>"))

(defun pen-add-keys ()
  (interactive)
  (define-key input-decode-map "[21;2~" [S-f10])
  (define-key input-decode-map [S-f10] nil)
  (define-key input-decode-map "\e[21;2~" [S-f10])
  (define-key global-map "\e[21;2~" [S-f10])

  ;; For some reason, this is actually mapping to f10 from emacs
  (define-key input-decode-map (kbd "<esc>[21;2~") [S-f10])
  ;; (define-key input-decode-map (kbd "<esc>[21;2~") [f1])

  (define-key input-decode-map "\e[21;2~" [S-f10])
  (define-key input-decode-map "\e[23;2~" [S-f11])
  (define-key input-decode-map "\e[24;2~" [S-f12])
  (define-key input-decode-map "<esc>[1;4S" [S-M-f4])
  ;; This worked
  (define-key input-decode-map "\e[1;4S" [S-M-f4])
  (define-key input-decode-map "<esc>[1;4s" [S-M-f4])
  (define-key input-decode-map "\e[1;4s" [S-M-f4]))

(pen-add-keys)
(add-hook 'window-setup-hook 'pen-add-keys)

;; (add-hook 'after-init-hook 'pen-add-keys)
;; This is also needed
;; (add-hook 'window-setup-hook 'pen-add-keys)

(provide 'pen-tty)