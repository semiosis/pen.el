(define-derived-mode person-description-mode yaml-mode "Person"
  "Person description mode")

(add-to-list 'auto-mode-alist '("\\.person\\'" . person-description-mode))

(defvar pen-personalities (make-hash-table :test 'equal)
  "Personalities are supported personality prompts")

(defvar pen-personalities-failed '())

(defun pen-personality-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-personalities-directory
                       "personalities"
                       (concat (slugify incl-name) ".person"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-personality-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-load-personalities (&optional paths)
  (interactive)

  (setq pen-personalities (make-hash-table :test 'equal))
  (setq pen-personalities-failed '())
  (noupd
   (eval
    `(let ((paths
            (or ,paths
                (-non-nil
                 (mapcar 'sor (glob (concat pen-personalities-directory "/personalities" "/*.person")))))))
       (cl-loop for path in paths do
                (message (concat "pen-mode: Loading .personalitie file " path))

                (try
                 (let* ((yaml-ht (pen-personality-file-load path))
                        (personality-title (ht-get yaml-ht "full-name")))
                   (ht-set yaml-ht "personality-path" path)
                   (message (concat "pen-mode: Loaded personality " full-name))
                   (ht-set pen-personalities full-name yaml-ht))
                 (add-to-list 'pen-personalities-failed path)))
       (if pen-personalities-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-personalities-failed))
             (message (concat (str (length pen-personalities-failed)) " failed"))))))))

(provide 'pen-personalities)