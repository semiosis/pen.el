;; TRAMP gcloud ssh
(add-to-list 'tramp-methods
  '("gssh"
    (tramp-login-program        "gssh")
    (tramp-login-args           (("%h")))
    (tramp-async-args           (("-q")))
    (tramp-remote-shell         "/bin/sh")
    (tramp-remote-shell-args    ("-c"))
    (tramp-gw-args              (("-o" "GlobalKnownHostsFile=/dev/null")
                                 ("-o" "UserKnownHostsFile=/dev/null")
                                 ("-o" "StrictHostKeyChecking=no")))
    (tramp-default-port         22)))

(require 'git-gutter+)

;; This is buggy sadly
;; (defun git-gutter+-remote-default-directory (dir file)
;;   (let* ((vec (tramp-dissect-file-name file))
;;          (method (aref vec 0))
;;          (user (aref vec 1))
;;          (host (aref vec 2)))
;;     (format "/%s:%s%s:%s" method (if user (concat user "@") "") host dir)))

(defun git-gutter+-refresh ()
  (git-gutter+-clear)
  (let ((file (buffer-file-name)))
    (when (and file (file-exists-p file))
      (if (and nil (file-remote-p file))
          (let* ((repo-root (git-gutter+-root-directory file))
                 (default-directory (git-gutter+-remote-default-directory repo-root file)))
            (git-gutter+-process-diff (git-gutter+-remote-file-path repo-root file)))
        (git-gutter+-process-diff (git-gutter+-local-file-path file))))))

(provide 'pen-tramp)