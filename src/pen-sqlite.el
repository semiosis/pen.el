(require 'sqlite-mode)

(defun sqlite-test-cross-refs ()
  (interactive)
  
  (let* ((db
          (sqlite-open "/root/.pen/refs.db"))
         (refs (sqlite-select db "select `To Verse` from refstable where `From Verse` = \"Jer.10.14\" and `Votes` > 0 order by cast(`Votes` as unsigned) desc") ))

    (etv refs 'emacs-lisp-mode)

    (sqlite-close db)))

(defun sqlite-test-cross-refs ()
  (interactive)
  
  (let* ((db
          (sqlite-open "/root/repos/aaronjohnsabu1999/bible-databases/DB/NASBBible_Database.db"))
         (refs (sqlite-select db "select `To Verse` from refstable where `From Verse` = \"Jer.10.14\" and `Votes` > 0 order by cast(`Votes` as unsigned) desc") ))

    (etv refs 'emacs-lisp-mode)

    (sqlite-close db)))

(provide 'pen-sqlite)
