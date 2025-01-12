(require 'sqlite-mode)
(advice-add 'sqlite-close :around #'ignore-errors-around-advice)

;; Now I can copy the path and open a zsh while browsing a database
(defun sqlite-mode-open-file-around-advice (proc file)
  (let ((res (apply proc (list file))))
    (setq-local sqlite--db-file file)
    (setq-local default-directory (f-dirname (f-realpath file)))
    res))
(advice-add 'sqlite-mode-open-file :around #'sqlite-mode-open-file-around-advice)
;; (advice-remove 'sqlite-mode-open-file #'sqlite-mode-open-file-around-advice)

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

(defun sqlite-test-nasb ()
  (interactive)
  
  (let* ((db
          (sqlite-open "/root/repos/aaronjohnsabu1999/bible-databases/DB/NASBBible_Database.db"))
         (refs (sqlite-select db "select * from bible where verse LIKE \"%Jesus%\"")))

    (etv refs 'emacs-lisp-mode)

    (sqlite-close db)))

(defun sqlite-copy-path ()
  (interactive)
  (xc sqlite--db-path))

(define-key sqlite-mode-map (kbd "w") 'sqlite-copy-path)

(provide 'pen-sqlite)
