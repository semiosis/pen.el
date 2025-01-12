;;; crossword-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "crossword" "crossword.el" (0 0 0 0))
;;; Generated autoloads from crossword.el

(autoload 'crossword-summary "crossword" "\
Display detailed meta-data of known puzzle files.
This includes progress for partially played puzzles. Data can be
sorted by any column, and individual entries can be deleted.
Puzzles can be played by pressing <RET> on their entry." t nil)

(autoload 'crossword-download "crossword" "\
Download a crossword puzzle from the network.
Optional arg FROM is a download source, expected to be `equal' to
the CAR of an element of `crossword-download-puz-alist'. Optional
arg DATE is expected to be a list of integers '(mm dd yyy).

\(fn &optional FROM DATE)" t nil)

(autoload 'crossword-load "crossword" "\
Find (and play) a local crossword puzzle file.
You probably don't want to use this command unless you have a
file in a non-default directory (see `crossword-save-path') and
want to keep it in its current location. If you've used
`crossword-download' to get a puzzle, it should appear in the
puzzle browser when the download completes." t nil)

(autoload 'crossword "crossword" "\
Entry function for `crossword' mode.
Presents a menu offering to either download a crossword puzzle
from a configured network source, browse puzzles previously
dowloaded, or directly find a puzzle file.

From the puzzle browser one can load a puzzle to play by selecting
it. The browser presents all puzzles' metadata including
completion details of played puzzles." t nil)

(register-definition-prefixes "crossword" '("crossword-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; crossword-autoloads.el ends here
