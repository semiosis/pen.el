(require 'project)
(require 'global-tags)

(comment
 ;; to use GNU Global automagically, regardless of Emacs default configuration
 (add-hook 'ruby-mode-hook #'global-tags-exclusive-backend-mode)
 ;; to use GNU Global automagically, respecting other backends
 (add-hook 'ruby-mode-hook #'global-tags-shared-backend-mode))

(comment
 (add-hook 'c-mode-hook #'global-tags-shared-backend-mode)
 (add-hook 'c-ts-mode-hook #'global-tags-shared-backend-mode))

(add-hook 'c-mode-hook #'global-tags-exclusive-backend-mode)
(add-hook 'c-ts-mode-hook #'global-tags-exclusive-backend-mode)

(comment
 ;; Alternatively, you can manually configure project.el and xref.el, add their
 ;; "recognize this global handled project" to the proper places like so:

 ;; xref (finding definitions, references)
 (add-to-list 'xref-backend-functions 'global-tags-xref-backend)
 ;; project.el (finding files)
 (add-to-list 'project-find-functions 'global-tags-try-project-root)
 ;; configure Imenu
 (add-hook 'ruby-mode-hook #'global-tags-imenu-mode)
 ;; to update database after save
 (add-hook 'c++-mode-hook (lambda ()
                            (add-hook 'after-save-hook
                                      #'global-tags-update-database-with-buffer
                                      nil
                                      t))))

(provide 'pen-global)
