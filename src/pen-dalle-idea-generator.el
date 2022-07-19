(defun generate-visual-art-idea ()
  (interactive)
  (etv
   (format "A %s %s of %s"
           (ilist 10 "visual art style"
                  ;; examples
                  "surrealist")
           (ilist 10 "art style"
                  ;; examples
                  "surrealist")
           (ilist 10 "scenes"
                  ;; examples
                  "a cat playing checkers"))))


(etv (ilist 10 "art style"
            ;; examples
            "surrealist"))