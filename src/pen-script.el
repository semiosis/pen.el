;; Run elisp scripts
;; --script
;; $EMACSD/host/pen.el/scripts/pen-e

;; (pen-eval-string (xc))
(defun runscript (script-path &rest argv)
  (if (f-exists-p script-path)
      (progn
        (let* ((code (cat script-path))
               ;; (code (pen-snc "sed -z 's//^#[^\\n]*\\n//'" code))
               (code (pen-snc "sed -z 's/^#[^\\n]*\\n*//'" code)))
          (pen-eval-string code)
          ;; (tv code)
          ))))

(provide 'pen-script)
