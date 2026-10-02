(require 'language-detection)

(defun language-detection-string-around-advice (proc s)
  (cond ((string-match-p "#\\+BEGIN_SRC" s)
         "orgmode")
        (t (let ((res (apply proc (list s))))
             res))))
(advice-add 'language-detection-string :around #'language-detection-string-around-advice)
;; (advice-remove 'language-detection-string #'language-detection-string-around-advice)

(provide 'pen-language-detection)
