;; Pen thin client for emacs
;; This communicates with a Pen.el docker container for basic prompt functions with no interactivity

(require 'pp)

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun pp-oneline (l)
  (chomp (replace-regexp-in-string "\n +" " " (pp l))))

(defun pen-client-generate-functions ()
  (interactive)

  (let* (
         ;; (fn-names (pen-str2list (pen-snc "penl")))
         (sig-sexps (eval-string
                     (concat
                      "'"
                      (pen-snc (cmd "pene" "(pen-list-signatures-for-client)"))))))

    (etv
     (cl-loop
      for s in sig-sexps collect
      (let ((fn-name
             (replace-regexp-in-string "(\\([^ )]*\\).*" "\\1" (pp-oneline s)))
            (args
             (replace-regexp-in-string "^[^ ]*" "" (pp-oneline s))))
        args)))
    ;; (etv sig-sexps)
    ))

(provide 'pen-client)