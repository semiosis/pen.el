(defun symbol-at-point ()
  "Return the symbol at point, or nil if none is found."
  (let ((thing (thing-at-point 'symbol))
        (thing-str (str (thing-at-point 'symbol))))
    (if thing
        (progn
          (if (or
               (s-contains-p "." thing-str)
               (s-contains-p "·" thing-str))
              (setq thing (fz (append
                               (list thing-str)
                               (s-split "[\\.·]" thing-str)) nil nil "Symbol at point:")))
          (intern thing)))))

(provide 'pen-modifications)
