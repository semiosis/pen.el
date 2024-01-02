(require 'crossword)
(require 'wordel)
(require 'maces-game)

;; (require 'rubik)

(setq crossword-save-path (concat (f-join pen-confdir "documents" "Crosswords") "/"))
(mkdir-p (f-join pen-confdir "documents" "Crosswords"))

(define-derived-mode crossword-mode fundamental-mode "Crossword"
  "Operate on puz file format crossword puzzles.
\\{crossword-mode-map}"
  (add-hook 'post-command-hook #'crossword--update-faces t t)
  (overwrite-mode)
  ;; This disables hl-line-mode
  (call-interactively 'hl-line-mode)
  (face-remap-add-relative 'default :family "Monospace")
  (advice-add #'self-insert-command
              :around #'crossword--advice-around-self-insert-command)
  (advice-add #'call-interactively
              :around #'crossword--advice-around-call-interactively))

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

;; (defsetface
;;  crossword-grid-face
;;  `((((class color) (background light))
;;     (:foreground ,(xterm-color-256 233)
;;                  ;; :background ,(xterm-color-256 234)
;;                  :inherit 'normal))
;;    (((class color) (background dark))
;;     (:foreground ,(xterm-color-256 233)
;;                  ;; :background ,(xterm-color-256 234)
;;                  :inherit 'normal))
;;    (t (:foreground "red" :background "234" :inherit 'normal)))
;;  "For un-writable squares and grid-lines.")
;; 
;; (defsetface crossword-other-dir-face
;;  '((((class color) (background light))
;;         (:background "darkgrey" :foreground "black" :inherit 'normal))
;;    (((class color) (background dark))
;;     (:background "brightblack" :foreground "black" :inherit 'normal))
;;    (t   (:background "brightblack" :foreground "black" :inherit 'normal)))
;;  "For the current clue and word.")

(defsetface
 crossword-current-face
 `((((class color) (background light))
    (:background
     "lightgreen" :foreground "black" :inherit 'normal))
   (((class color) (background dark))
    (:background ,(xterm-color-256 22)
                 :foreground ,(xterm-color-256 82)
                 :inherit 'normal))
   (t (
       :background ,(xterm-color-256 22)
       :foreground ,(xterm-color-256 82)
       :inherit 'normal)))
 "For the current clue and word.")

(defun captain-bible ()
  (interactive)

  (pen-sn "cb" nil nil nil t))

(provide 'pen-games)
