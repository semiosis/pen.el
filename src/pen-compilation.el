; from enberg on #emacs
(setq compilation-finish-function
  (lambda (buf str)
    (if (and (null (string-match ".*exited abnormally.*" str))
             (null (string-match ".*recipe for target.*failed.*" str)))
        ;;no errors, make the compilation window go away in a few seconds
        (progn
          (run-at-time
           "2 sec" nil 'delete-windows-on
           (get-buffer-create "*compilation*"))
          (message "No Compilation Errors!")))))

(setq compilation-finish-function nil)

;; TODO Blog about fixing glimpse.el
(defun compile-internal (command done name unk1 unk2)
  (compilation-start command
                     'grep-mode (lambda (n) name)))

(defun compilation-find-file-projectile-find-compilation-buffer (orig-fun marker filename directory &rest formats)
  "Try to find a buffer for FILENAME, if we cannot find it,
fallback to the original function."
  (setq filename (pen-umn filename))
  (when (and (not (file-exists-p (expand-file-name filename)))
             (projectile-project-p))
    (let* ((root (projectile-project-root))
           (dirs (cons "" (projectile-current-project-dirs)))
           (new-filename (car (cl-remove-if-not
                               #'file-exists-p
                               (mapcar
                                (lambda (f)
                                  (expand-file-name
                                   filename
                                   (expand-file-name f root)))
                                dirs)))))
      (when new-filename
        (setq filename new-filename))))

  (apply orig-fun `(,marker ,filename ,directory ,@formats)))

(provide 'pen-compilation)
