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

;; Why doen't these exist?
(define-key key-translation-map (kbd "<f22>") (kbd "<S-f10>"))
(define-key key-translation-map (kbd "<f23>") (kbd "<S-f11>"))
(define-key key-translation-map (kbd "<f24>") (kbd "<S-f12>"))

(define-key input-decode-map "\e[21;2~" [S-f10])
(define-key input-decode-map "\e[23;2~" [S-f11])
(define-key input-decode-map "\e[24;2~" [S-f12])

(provide 'pen-tty)