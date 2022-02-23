(define-derived-mode pictograph-description-mode yaml-mode "Pictograph"
  "Pictograph description mode")

(add-to-list 'auto-mode-alist '("\\.pictograph\\'" . pictograph-description-mode))

(defvar pen-pictographs (make-hash-table :test 'equal)
  "Pictographs are supported book definitions")

(defvar pen-pictographs-failed '())

;; (pen-pictograph-file-load "$HOME/source/git/semiosis/pictographs/pictographs/which-owl.pictograph")
(defun pen-pictograph-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-pictographs-directory
                       "pictographs"
                       (concat (slugify incl-name) ".pictograph"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-pictograph-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-load-pictographs (&optional paths)
  (interactive)

  (setq pen-pictographs (make-hash-table :test 'equal))
  (setq pen-pictographs-failed '())
  (noupd
   (eval
    `(let ((paths
            (or ,paths
                (-non-nil
                 (mapcar 'sor (glob (concat pen-pictographs-directory "/pictographs" "/*.pictograph")))))))
       (cl-loop for path in paths do
                (message (concat "pen-mode: Loading .pictograph file " path))

                (pen-try
                 (let* ((yaml-ht (pen-pictograph-file-load path))
                        (title (ht-get yaml-ht "title")))
                   (ht-set yaml-ht "pictograph-path" path)
                   (message (concat "pen-mode: Loaded pictograph " title))
                   (ht-set pen-pictographs title yaml-ht))
                 (add-to-list 'pen-pictographs-failed path)))
       (if pen-pictographs-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-pictographs-failed))
             (message (concat (str (length pen-pictographs-failed)) " failed"))))))))

(provide 'pen-pictographs)