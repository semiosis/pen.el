(require 'chess)

(setq chess-images-separate-frame nil)

(defun chess-images-handler-around-advice (proc &rest args)
  (cl-letf (((symbol-function 'display-graphic-p) #'ignore))
    (let ((res (apply proc args)))
      res)))
(advice-add 'chess-images-handler :around #'chess-images-handler-around-advice)
;; (advice-remove 'chess-images-handler #'chess-images-handler-around-advice)

(provide 'pen-chess)
