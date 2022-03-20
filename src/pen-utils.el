(defun find-thing (thing)
  (interactive)
  (if (stringp thing)
      (setq thing (intern thing)))
  (try (find-function thing)
       (find-variable thing)
       (find-face-definition thing)
       (pen-ns (concat (str thing) " is neither function nor variable"))))
(defalias 'j 'find-thing)
(defalias 'ft 'find-thing)

(defmacro progn-read-only-disable (&rest body)
  `(progn
     (if buffer-read-only
         (progn
           (read-only-mode -1)
           (let ((res
                  ,@body))
             res)
           (read-only-mode 1))
       (progn
         ,@body))))

(defun gl-find-deb (query)
  (interactive (list (read-string-hist "binary name: ")))
  (wget (fz (pen-cl-sn (pen-concat "find-deb " query) :chomp t))))

(defun zcd (dir)
  (interactive (list (read-directory-name "zcd: ")))
  (pen-sps (pen-cmd "zcd" dir)))

(defun byte-pos ()
  (position-bytes (point)))

(defun date-ts ()
  (string-to-number (format-time-string "%s")))

(provide 'pen-utils)