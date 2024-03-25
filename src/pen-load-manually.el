(if (inside-docker-p)
    (progn
      (add-to-list 'load-path "/root/.emacs.d/manual-packages/bible-mode")

      (require 'bible-mode)
      (load-library "bible-mode")
      (require 'pen-bible-mode)


      (add-to-list 'load-path "/root/.emacs.d/manual-packages/obvious.el")
      (require 'obvious)

      (add-to-list 'load-path "/root/.emacs.d/manual-packages/problog-mode")
      (require 'problog-mode)))


;; e:$EMACSD_BUILTIN/straight/repos/org-verse
;; e:$EMACSD_BUILTIN/straight/build/org-verse
(require 'doct)
(comment
 (use-package org-verse
   :straight (:host github :repo "DarkBuffalo/org-verse")
   :init
   (setq org-verse-directory "~/notes"
         org-verse-db-table-name "biblefr")))

(provide 'pen-load-manually)
