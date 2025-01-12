;;; chess-gnuchess.el --- Play against gnuchess!  -*- lexical-binding: t; -*-

;; Copyright (C) 2002-2020  Free Software Foundation, Inc.

;; Author: John Wiegley <johnw@gnu.org>
;; Maintainer: Mario Lang <mlang@delysid.org>
;; Keywords: games, processes

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'chess-common)
(require 'chess-fen)
(require 'chess-pgn)

(defgroup chess-gnuchess nil
  "The publically available chess engine 'gnuchess'."
  :group 'chess-engine
  :link '(custom-manual "(chess)GNU Chess")
  :link '(url-link "http://www.gnu.org/software/chess/"))

(defcustom chess-gnuchess-path (let ((exec-path (cons "/usr/games" exec-path)))
				 (executable-find "gnuchess"))
  "The path to the gnuchess executable."
  :type 'file)

(defvar chess-gnuchess-bad-board nil)
(make-variable-buffer-local 'chess-gnuchess-bad-board)

(defvar chess-gnuchess-regexp-alist
  (list
   (cons (concat "My move is : \\(" chess-algebraic-regexp "\\)")
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'move
		     (chess-engine-convert-algebraic (match-string 1) t)))))
   (cons "Illegal move:"
	 (function
	  (lambda ()
	    (chess-error 'illegal-move))))
   (cons "Board is wrong!"
	 (function
	  (lambda ()
	    ;; gnuchess didn't like the given position, which
	    ;; means it won't play against it unless we send a
	    ;; "go" after the user's move
	    (setq chess-gnuchess-bad-board t))))))

(defun chess-gnuchess-handler (game event &rest args)
  (unless chess-engine-handling-event
    (cond
     ((eq event 'initialize)
      (let ((proc (chess-common-handler game 'initialize "gnuchess")))
	(when (and proc (processp proc)
		   (eq (process-status proc) 'run))
	  (process-send-string proc "nopost\n")
	  (setq chess-engine-process proc
		chess-engine-opponent-name "GnuChess")
	  t)))

     ((eq event 'setup-pos)
      (let ((file (chess-with-temp-file
		      (insert (chess-pos-to-fen (car args)) ?\n))))
	(chess-engine-send nil (format "epdload %s\n" file))))

     ((eq event 'setup-game)
      (if (zerop (chess-game-index (car args)))
	  (chess-gnuchess-handler game 'setup-pos (chess-game-pos game 0))
	(let ((file (chess-with-temp-file
			(chess-insert-pgn (car args)) (insert ?\n))))
	  (chess-engine-send nil (format "pgnload %s\n" file)))))

     ((eq event 'pass)
      (chess-engine-send nil (concat (if (chess-pos-side-to-move
					  (chess-engine-position nil))
					 "white" "black")
				     "\n"))
      (chess-engine-send nil "go\n")
      (setq chess-gnuchess-bad-board nil))

     ((eq event 'move)
      (chess-common-handler game 'move (car args))
      (when chess-gnuchess-bad-board
	(chess-engine-send nil "go\n")
	(setq chess-gnuchess-bad-board nil)))

     (t
      (apply #'chess-common-handler game event args)))))

(provide 'chess-gnuchess)

;;; chess-gnuchess.el ends here
