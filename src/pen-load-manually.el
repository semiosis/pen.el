(if (inside-docker-p)
    (progn
      (add-to-list 'load-path "/root/.emacs.d/manual-packages/bible-mode")

      (require 'bible-mode)
      (load-library "bible-mode")
      (require 'pen-bible-mode)


      (add-to-list 'load-path "/root/.emacs.d/manual-packages/obvious.el")
      (require 'obvious)

      ;; (add-to-list 'load-path "/root/.emacs.d/manual-packages/visual-basic-mode/visual-basic-mode.el")
      ;; (require 'visual-basic-mode)
      ;; (autoload 'visual-basic-mode "visual-basic-mode" "Visual Basic mode." t)
      ;; (push '("\\.\\(?:frm\\|\\(?:ba\\|cl\\|vb\\)s\\)\\'" . visual-basic-mode)
      ;;       auto-mode-alist)
      ;; (push '("\\.\\(?:frm\\|\\(?:ba\\|cl\\|vb\\)s\\|rvb\\)\\'" . visual-basic-mode)
      ;;   auto-mode-alist)

      (add-to-list 'load-path "/root/.emacs.d/manual-packages/problog-mode")
      (require 'problog-mode)

      (add-to-list 'load-path "/root/.emacs.d/manual-packages/clj-refactor.el")
      (require 'clj-refactor)
      
      (add-to-list 'load-path "/root/.emacs.d/manual-packages/cpl-mode")
      (require 'cpl-mode)))


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
