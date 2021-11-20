;; Pen thin client for emacs
;; This communicates with a Pen.el docker container for basic prompt functions with no interactivity

(defun pen-client-generate-functions ()
  (interactive)

  (let* ((fn-names (pen-str2list (pen-snc "penl")))))

  (loop for )

  )

(provide 'pen-client)