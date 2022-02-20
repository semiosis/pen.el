(define-derived-mode tome-description-mode yaml-mode "Tome"
  "Tome description mode")

(add-to-list 'auto-mode-alist '("\\.tome\\'" . tome-description-mode))

(defvar pen-tomes (make-hash-table :test 'equal)
  "Tomes are supported book definitions")

(defvar pen-tomes-failed '())

;; (pen-tome-file-load "/home/shane/source/git/semiosis/tomes/tomes/libertyprime.tome")
(defun pen-tome-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-tomes-directory
                       "tomes"
                       (concat (slugify incl-name) ".tome"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-tome-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-load-tomes (&optional paths)
  (interactive)

  (setq pen-tomes (make-hash-table :test 'equal))
  (setq pen-tomes-failed '())
  (noupd
   (eval
    `(let ((paths
            (or ,paths
                (-non-nil
                 (mapcar 'sor (glob (concat pen-tomes-directory "/tomes" "/*.tome")))))))
       (cl-loop for path in paths do
                (message (concat "pen-mode: Loading .tome file " path))

                (pen-try
                 (let* ((yaml-ht (pen-tome-file-load path))
                        (full-name (ht-get yaml-ht "full-name")))
                   (ht-set yaml-ht "tome-path" path)
                   (message (concat "pen-mode: Loaded tome " full-name))
                   (ht-set pen-tomes full-name yaml-ht))
                 (add-to-list 'pen-tomes-failed path)))
       (if pen-tomes-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-tomes-failed))
             (message (concat (str (length pen-tomes-failed)) " failed"))))))))

(provide 'pen-tomes)