(defcustom pen-interpreters-directory (f-join user-emacs-directory "interpreters")
  "Personal interpreter respository"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

;; Personal interpreters repository
(let ((hostinterpretersdir (f-join user-emacs-directory "host" "interpreters")))
  (if (f-directory-p (f-join hostinterpretersdir "interpreters"))
      (setq pen-interpreters-directory hostinterpretersdir)
    (setq pen-interpreters-directory (f-join user-emacs-directory "interpreters"))))

(defun pen-ii-file-load (fp)
  (let* ((yaml-ht (yamlmod-read-file fp))
         (incl-name (sor (ht-get yaml-ht "include")))
         (incl-fp (if (sor incl-name)
                      (f-join
                       pen-interpreters-directory
                       "interpreters"
                       (concat (slugify incl-name) ".ii"))))
         (incl-yaml (if (and (sor incl-name)
                             (f-file-p incl-fp))
                        (pen-ii-file-load incl-fp))))
    (if incl-yaml
        (setq yaml-ht
              (ht-merge incl-yaml
                        ;; The last is overriding
                        yaml-ht)))
    yaml-ht))

(defvar pen-interpreters (make-hash-table :test 'equal)
  "pen-interpreters are specialised prompts ")
(defvar pen-interpreters-failed '())

;; TODO Obsolete this function and merge with prompts
(defun pen-load-interpreters (&optional paths)
  (interactive)

  (setq pen-interpreters (make-hash-table :test 'equal))
  (setq pen-interpreters-failed '())
  (noupd
   (eval
    `(let ((paths
            (or ,paths
                (-non-nil
                 (mapcar 'sor (glob (concat pen-interpreters-directory "/interpreters" "/*.ii")))))))
       (loop for path in paths do
                (message (concat "pen-mode: Loading .ii file " path))

                ;; Do a recursive interpreter merge from includes
                ;; ht-merge

                ;; results in a hash table
                (try
                 (let* ((yaml-ht (pen-ii-file-load path))

                        ;; function
                        (language (ht-get yaml-ht "language"))
                        (task (ht-get yaml-ht "task"))
                        (title (pen-expand-template-keyvals
                                (or (ht-get yaml-ht "title")
                                    (sor task)
                                    (and (sor language)
                                         (concat "Imagine a " language " interpreter")))
                                `(("language" . ,language)))))
                   (ht-set yaml-ht "path" path)
                   (message (concat "pen-mode: Loaded interpreter " title))
                   (ht-set pen-interpreters title yaml-ht))
                 (add-to-list 'pen-interpreters-failed path)))
       (if pen-interpreters-failed
           (progn
             (message "failed:")
             (message (pen-list2str pen-interpreters-failed))
             (message (concat (str (length pen-interpreters-failed)) " failed"))))))))

