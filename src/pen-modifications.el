(defun symbol-at-point ()
  "Return the symbol at point, or nil if none is found."
  (let ((thing (thing-at-point 'symbol)))
    (if (or
         (s-contains-p "." thing)
         (s-contains-p "·" thing))
        (setq thing (fz (append
                         (list thing)
                         (s-split "[\\.·]" thing)) nil nil "Symbol at point:")))
    (if thing (intern thing))))

(provide 'pen-modifications)
