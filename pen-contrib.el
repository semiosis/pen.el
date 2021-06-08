;; This is for everything outside of core pen stuff
;; i.e. applications built on pen.el

(defvar pen-tutor-common-questions
  '("What is <1:q> used for?"
    "What are some good learning materials"))

(defun pen-tutor-mode-assist (query)
  (interactive (let* ((bl (buffer-language t t)))
                 (list
                  (read-string-hist
                   (concat "asktutor (" bl "): ")
                   (my/thing-at-point)))))
  (pen-pf-asktutor bl bl query))

;; v:pen-ask-documentation 
(defun pen-ask-documentation ()

  )

(provide 'pen-contrib)