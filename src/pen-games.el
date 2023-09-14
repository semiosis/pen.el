(require 'crossword)
(require 'wordel)

(setq crossword-save-path (concat (f-join pen-confdir "documents" "Crosswords") "/"))
(mkdir-p (f-join pen-confdir "documents" "Crosswords"))

(defun crossword ()
  "Entry function for `crossword' mode.
Presents a menu offering to either download a crossword puzzle
from a configured network source, browse puzzles previously
dowloaded, or directly find a puzzle file.

From the puzzle browser one can load a puzzle to play by selecting
it. The browser presents all puzzles' metadata including
completion details of played puzzles."
  (interactive)
  (crossword--recover-game-in-progress)
  (unless (crossword--check-and-create-save-path)
    (user-error "No existing download path configured"))
  (let ((choices
          (list (when (crossword--puzzle-file-list)
                  (cons "Use the local crossword browser" #'crossword-summary))
                (cons "Download a crossword puzzle" #'crossword-download)
                (cons "Directly load a crossword from a local file" #'crossword-load))))
    (funcall (cdr (assoc-string
                    (completing-read "Welcome to Emacs crossword! "
                                     (mapcar (lambda (x) (car x)) choices)
                                     nil t
                                     ;; (caar choices)
                                     )
                    choices)))))

(provide 'pen-games)
