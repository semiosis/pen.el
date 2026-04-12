(require 'hl-line)

;; This doesn't seem to work anyway
;; (comment
;;  ;; Disable hl-line-mode for term
;;  (defun hl-line-mode-around-advice (proc &rest args)
;;    (if (and (not (major-mode-p 'term-mode))
;;             (not (major-mode-p 'crossword-mode))
;;             (not (major-mode-p 'ascii-adventures-mode))
;;             (not (major-mode-p 'eshell-mode)))
;;        (let ((res (apply proc args)))
;;          res)))
;;  (advice-add 'global-hl-line-highlight :around #'hl-line-mode-around-advice)
;;  (advice-remove 'global-hl-line-highlight :around #'hl-line-mode-around-advice)
;;  (advice-add 'hl-line-highlight :around #'hl-line-mode-around-advice)
;;  (advice-remove 'hl-line-highlight :around #'hl-line-mode-around-advice))

;; (setq-local hl-line-range-function 'eshell-hl-line-move)
;; (setq-local hl-line-range-function nil)
;; (setq hl-line-range-function 'eshell-hl-line-move)
;; (setq hl-line-range-function nil)

(setq hl-line-range-function 'pen-hl-line-range)
(comment
 (setq hl-line-range-function nil))

(defun pen-hl-line-range ()
  ""
  (let ((pt (point)))
    (ignore-errors
      (save-excursion
        (if eshell-mode
            (cons
             (let ((bol-pt (save-excursion
                             ;; (line-beginning-position)
                             (pen-comint-eol)
                             (pen-comint-bol)
                             (point))))
               (if (eq bol-pt (point-at-bol))
                   pt
                 bol-pt))
             (line-beginning-position 2))
          (cons (line-beginning-position)
                (line-beginning-position 2)))))))

(hl-line-unload-function)
(global-hl-line-mode)

(provide 'pen-hl-line)
