(require 'crossword)
(require 'wordel)
(require 'maces-game)
(require 'snake)


;; This is just so the highlighted current line doesn't interfere with the game border
(defun snake-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (end-of-buffer)
    res))
(advice-add 'snake :around #'snake-around-advice)
;; (advice-remove 'snake #'snake-around-advice)


;; https://web.archive.org/web/20221015212113/https://en.wikipedia.org/wiki/Box-drawing_character
(setq crossword-empty-position-char "▪")
(setq crossword-empty-position-char "⌑")
(setq crossword-empty-position-char "⧯")
(setq crossword-empty-position-char "█")
(setq crossword-empty-position-char "🮘")


(defun crossword--insert-grid (grid-width colophon clean-grid answer-grid clue-list)
  "Insert a beginning grid into a grid buffer.
This includes crossword COLOPHON, status-line, and grid into an
empty buffer, apply text properties to grid positions, and create
variables `crossword--across-clue-list' and
`crossword--down-clue-list'. GRID-WIDTH is an integer taken from
the puzzle file encoding. COLOPHON, CLEAN-GRID, ANSWER-GRID and CLUE-LIST
are substrings of the puzzle file."
  (let* (;; (divider "⏐")
         (divider " ")
         (divider "⦚")
         (block-cell (concat crossword-empty-position-char divider))
         (block-line
           (concat (replace-regexp-in-string
                      "-" block-cell
                      (make-string (+ 1 grid-width) ?-))))
         ;; FIXME: This does not work with lexical binding, so for now the
         ;;        propertizing is done individually with the let*.
         ;; (dolist (var (list 'divider 'block-cell 'crossword-new-line 'block-line))
         ;;   (set var (propertize (symbol-value var) 'face 'crossword-grid-face)))
         (divider    (propertize divider 'face 'crossword-grid-face))
         (block-cell (propertize block-cell 'face 'crossword-grid-face))
         (block-line (propertize block-line 'face 'crossword-grid-face))
         ;; END: FIXME
         (crossword-new-line (concat block-cell "\n" divider block-cell))
         (clue-across 0)
         (clue-down 0)
         start-pos pos)
    (insert " " colophon "\n")
    (decode-coding-region (point-min) (point-max) 'prefer-utf-8-dos)
    (setq start-pos (point))
    (setq crossword--total-count
      (cl-loop with start = 0
               for count from 0
               while (string-match "-" clean-grid start)
               do (setq start (match-end 0))
               finally return count))
    (insert
      (format " Filled:    0%% (  0/%3d) Timer: [off] 00:00\n" crossword--total-count)
      (format " Solved:    0%% (  0/%3d)\n" crossword--total-count)
              " Checked:   0  Errors:   0  Cheats:   0\n\n")
    (setq crossword--completion-percent-pos (+  10 start-pos)
          crossword--timer-state-pos        (+  33 start-pos)
          crossword--timer-value-pos        (+  38 start-pos)
          crossword--solved-percent-pos     (+  54 start-pos)
          crossword--checked-count-pos      (+  79 start-pos)
          crossword--error-count-pos        (+  92 start-pos)
          crossword--cheat-count-pos        (+ 105 start-pos))
    (insert divider block-line)
    (insert crossword-new-line)
    (setq start-pos (point)
          pos start-pos)
    (insert clean-grid)
    (goto-char start-pos)
    (while (not (eobp))
      (forward-char grid-width)
      (insert crossword-new-line))
    (insert block-line)
    (goto-char start-pos)
    (while (search-forward "-" nil t)
       (insert divider))
    (when (and crossword-empty-position-char
               (= 1 (length crossword-empty-position-char)))
      (goto-char start-pos)
      (while (search-forward "." nil t)
        (replace-match block-cell)))
    ;; Identify clue bounds and build data structures for quicker clue navigation
    (goto-char start-pos)
    (while (not (eobp))
      (when (= ?- (char-after pos))
        (cond
         ((/= ?- (char-after (- pos 2))) ; prior position isn't clue square
            (setq clue-across (1+ (max clue-across clue-down)))
            (push
              (list clue-across
                    (pop clue-list)
                    pos
                    (crossword--end-across-clue-pos pos clue-across))
              crossword--across-clue-list)
            (when (crossword--pos-above-is-void pos)
              (setq clue-down clue-across)
              (push
                (list clue-down
                      (pop clue-list)
                      (crossword--list-down-clue-pos pos clue-down))
                crossword--down-clue-list)))
         ((crossword--pos-above-is-void pos) ; position above isn't clue square
            (setq clue-down (1+ (max clue-across clue-down)))
            (push
              (list clue-down
                    (pop clue-list)
                    (crossword--list-down-clue-pos pos clue-down))
              crossword--down-clue-list)))
        (put-text-property pos (1+ pos) 'answer (substring answer-grid 0 1))
        (setq answer-grid (substring answer-grid 1)))
      (goto-char (setq pos (1+ pos))))
    (setq crossword--grid-end (+ 2 (goto-char (point-max))))
    (insert "\n\n Across:\n\n\n\n Down:")
    (goto-char start-pos)
    (setq crossword--across-clue-list (nreverse crossword--across-clue-list))
    (setq crossword--down-clue-list (nreverse crossword--down-clue-list))))



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

(defun crossword-around-advice (proc &rest args)
  (let ((default-directory crossword-save-path))
    (let ((res (apply proc args)))
      res)))
(advice-add 'crossword :around #'crossword-around-advice)
;; (advice-remove 'crossword #'crossword-around-advice)

;; Don't deactivate the menu bar, etc.
(defun crossword--select-frame ()
  "Select the \"Crossword\" frame, possibly creating it."
  (unless (equal (frame-parameter nil 'name) "Crossword")
    (condition-case nil
        (select-frame-by-name "Crossword")
      (error (select-frame
              (make-frame (list '(name   . "Crossword")
                                ;; '(menu-bar-lines .  0)
                                ;; '(tool-bar-lines .  0)
                                ;; '(height .  43)
                                ;; '(width  . 140)
                                )))))))

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
