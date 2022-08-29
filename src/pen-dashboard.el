(require 'dashboard)

(defvar dashboard-init-info
  ;; Check if package.el was loaded and if package loading was enabled
  (if (bound-and-true-p package-alist)
      (format "%d packages loaded in %s"
              (length package-activated-list) (emacs-init-time))
    (if (and (boundp 'straight--profile-cache) (hash-table-p straight--profile-cache))
        (format "%d packages loaded in %s"
                (hash-table-size straight--profile-cache) (emacs-init-time))
      (format "Emacs started in %s" (emacs-init-time))))
  "Init info with packages loaded and init time.")

(provide 'pen-dashboard)