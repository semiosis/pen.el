(require 'sqlite-mode)

(defun sqlite-open-refs ()
  (interactive)
  (mu
   (sqlite-mode-open-file "$PEN/refs.db")))

(defun sqlite-open-nasb ()
  (interactive)
  (mu
   (sqlite-mode-open-file "$HOME/repos/aaronjohnsabu1999/bible-databases/DB/NASBBible_Database.db")))

(defun sqlite-open-kjv ()
  (interactive)
  (sqlite-mode-open-file "/root/dump/root/notes/databases/kjv.db"))

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
         (refs (sqlite-select db "select * from bible where verse LIKE \"%Jesus%\"") ))

    (etv refs 'emacs-lisp-mode)

    (sqlite-close db)))

(provide 'pen-sqlite)
