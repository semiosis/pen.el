(defun company-pen--grab-symbol ()
  (buffer-substring (point) (save-excursion (skip-syntax-backward "w_.")
                                            (point))))

(defun company-pen-filetype--prefix ()
  "Grab prefix at point."
  (or (company-pen--grab-symbol)
      'stop))


(defmacro company-pen-gen (listify)
  ""
  `(let (())))

(defun company-pen-filetype (command &optional arg &rest ignored)
  (interactive (list 'is-interactive))
  (cl-case command
    (is-interactive (company-begin-backend 'company-pen-filetype))
    (prefix (company-pen-filetype--prefix))
    (candidates (company-pen-filetype--candidates arg))))

;; (lambda ,company-pen-generated-symbol (prefix)
;;   (let* ((preceding-text (pen-preceding-text))
;;          (response
;;           (->>
;;            preceding-text
;;            ,s2sfun))
;;          (res
;;           (list response)))
;;     (mapcar (lambda (s) (concat (company-pen-filetype--prefix) s))
;;             res)))

(never
 (company-pen-gen
  (str2lines
   (snc "monotonically-increasing-tuple-permutations.py"
        (car (str2lines response))))))

(provide 'pen-company)