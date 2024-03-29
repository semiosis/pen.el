;; Protoverses create Metaverses
;; A new Metaverse file should be able to be generated from a Protoverse file

(define-derived-mode protoverse-description-mode yaml-mode "protoverse"
  "Protoverse description mode")

(add-to-list 'auto-mode-alist '("\\.protoverse\\'" . protoverse-description-mode))

(define-derived-mode metaverse-description-mode yaml-mode "Metaverse"
  "Metaverse description mode")

(add-to-list 'auto-mode-alist '("\\.verse\\'" . metaverse-description-mode))

(defvar pen-metaverses (make-hash-table :test 'equal)
  "Metaverses are actualised; They have been prompted into existence")

(defvar pen-protoverses (make-hash-table :test 'equal)
  "Protoverses are the seeds of metaverses")

(defvar pen-metaverses-failed '())
(defvar pen-protoverses-failed '())

;; (pen-metaverse-file-load "/home/shane/source/git/semiosis/metaverses/metaverses/mad-teaparty.verse")
(defun pen-metaverse-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-metaverses-directory
                       "metaverses"
                       (concat (slugify incl-name) ".verse"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-metaverse-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-load-metaverses (&optional paths)
  (interactive)

  (setq pen-metaverses (make-hash-table :test 'equal))
  (setq pen-metaverses-failed '())
  (noupd
   (eval
    `(let ((paths
            (or ,paths
                (-non-nil
                 (mapcar 'sor (glob (concat pen-metaverses-directory "/metaverses" "/*.verse")))))))
       (cl-loop for path in paths do
                (message (concat "pen-mode: Loading .metaverse file " path))

                (pen-try
                 (let* ((yaml-ht (pen-metaverse-file-load path))
                        (name (ht-get yaml-ht "name")))
                   (ht-set yaml-ht "metaverse-path" path)
                   (message (concat "pen-mode: Loaded metaverse " name))
                   (ht-set pen-metaverses name yaml-ht))
                 (add-to-list 'pen-metaverses-failed path)))
       (if pen-metaverses-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-metaverses-failed))
             (message (concat (str (length pen-metaverses-failed)) " failed"))))))))

(provide 'pen-metaverses)