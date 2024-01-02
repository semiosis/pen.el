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

(provide 'pen-load-manually)
