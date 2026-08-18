(require 'rst)

(defalias 'modulo '%)

(defun hex2dec (hex)
  "hex can be one hex num per line"
  (let ((results
         (cl-loop for n in (str2lines hex) collect
                  (string-to-number (pen-snc (concat "echo " n " | math hex2dec"))))))
    (if (eq 1 (length results))
        (car results)
      results)))

(comment
 ;; 1964
 (message "%S" (rst-roman-to-arabic "MCMLXIV"))
 (message "%S" (rst-arabic-to-roman 1999)))

(provide 'pen-math)
