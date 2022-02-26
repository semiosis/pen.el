;; http://github.com/semiosis/creation

(define-derived-mode archaea-description-mode yaml-mode "Archaea"
  "Archaea description mode")

(add-to-list 'auto-mode-alist '("\\.archaea\\'" . archaea-description-mode))

(defvar pen-archaea (make-hash-table :test 'equal)
  "Archaea are supported archaea prompts")

(defvar pen-archaea-failed '())

;; (pen-archaea-file-load "$HOME/source/git/semiosis/archaea/archaea/libertyprime.archaea")
(defun pen-archaea-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-archaea-directory
                       "archaea"
                       (concat (slugify incl-name) ".archaea"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-archaea-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defun pen-list-archaea ()
  (ht-keys pen-archaea))

(defun pen-load-archaea (&optional paths)
  (interactive)

  (setq pen-archaea (make-hash-table :test 'equal))
  (setq pen-archaea-failed '())
  (noupd
   (let ((paths
          (or paths
              (-non-nil
               (mapcar 'sor (glob (concat pen-archaea-directory "/archaea" "/*.archaea")))))))
     (cl-loop for path in paths do
              (message (concat "pen-mode: Loading .archaea file " path))

              (pen-try
               (let* ((yaml-ht (pen-archaea-file-load path))

                      (name (ht-get yaml-ht "name"))
                      (proto (pen--htlist-to-alist (ht-get yaml-ht "proto")))
                      (meta (pen--htlist-to-alist (ht-get yaml-ht "meta")))
                      (actual (pen--htlist-to-alist (ht-get yaml-ht "actual"))))

                 (ht-set yaml-ht "archaea-path" path)

                 (message (concat "pen-mode: Loaded archaea " name))
                 (ht-set pen-archaea name yaml-ht))
               (add-to-list 'pen-archaea-failed path))))
   (if pen-archaea-failed
       (progn
         (message "failed:")
         (message (pen-list2str pen-archaea-failed))
         (message (concat (str (length pen-archaea-failed)) " failed"))))))


;; Load the archetypes, create YAML-based formats for each archetype and each stage of those archetypes

(provide 'pen-creation)