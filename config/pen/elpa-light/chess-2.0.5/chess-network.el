;;; chess-network.el --- Play against an opponent over the network  -*- lexical-binding: t; -*-

;; Copyright (C) 2002-2020  Free Software Foundation, Inc.

;; Author: John Wiegley <johnw@gnu.org>
;; Maintainer: Mario Lang <mlang@delysid.org>
;; Keywords: games

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

(defvar chess-network-regexp-alist
  (list
   (cons (concat chess-algebraic-regexp "$")
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'move
		     (chess-engine-convert-algebraic (match-string 0))))))
   (cons "chess match\\(\\s-+\\(.+\\)\\)?$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'match
		     (match-string 2)))))
   (cons "fen\\s-+\\(.+\\)"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'setup-pos
		     (chess-engine-convert-fen (match-string 1))))))
   (cons "pgn\\s-+\\(.+\\)"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'setup-game
		     (chess-engine-convert-pgn
		      (chess-network-parse-multiline (match-string 1)))))))
   (cons "pass$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'pass))))
   (cons "quit$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'quit))))
   (cons "resign$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'resign))))
   (cons "draw$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'draw))))
   (cons "abort$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'abort))))
   (cons "takeback\\s-+\\([0-9]+\\)$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'undo
		     (string-to-number (match-string 1))))))
   (cons "accept\\(\\s-+\\(.+\\)\\)?$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'accept
		     (match-string 2)))))
   (cons "decline$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'decline))))
   (cons "retract$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'retract))))
   (cons "illegal$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'illegal))))
   (cons "flag$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'call-flag))))
   (cons "forfeit$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'flag-fell))))
   (cons "kibitz\\s-+\\(.+\\)$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'kibitz
		     (chess-network-parse-multiline (match-string 1))))))
   (cons "chat\\s-+\\(.+\\)$"
	 (function
	  (lambda ()
	    (funcall chess-engine-response-handler 'chat
		     (chess-network-parse-multiline (match-string 1))))))))

(chess-message-catalog 'english
  '((network-starting  . "Starting network client/server...")
    (network-waiting   . "Now waiting for your opponent to connect...")
    (takeback-sent     . "Sent request to undo %d ply(s) to your opponent")))

(defun chess-network-flatten-multiline (str)
  (while (string-match "\n" str)
    (setq str (replace-match "\C-k" t t str)))
  str)

(defun chess-network-parse-multiline (str)
  (while (string-match "\C-k" str)
    (setq str (replace-match "\n" t t str)))
  str)

(defvar chess-network-kind)
(make-variable-buffer-local 'chess-network-kind)

(defvar chess-full-name)

(defun chess-network-handler (game event &rest args)
  "Initialize the network chess engine."
  (unless chess-engine-handling-event
    (cond
     ((eq event 'initialize)
      (let* ((cursor-in-echo-area t)
	     (which (read-char "Are you the c)lient or s)erver? "))
	     proc)
	(chess-message 'network-starting)
	(setq proc
	      (if (eq which ?s)
		  (if (fboundp 'open-network-stream-server)
		      (open-network-stream-server "*chess-network*"
						  (current-buffer)
						  (string-to-number
						   (read-string "Port: ")))
		    (start-process "*chess-network*"
				   (current-buffer) (executable-find "nc")
				   "-l" "-p" (read-string "Port: ")))
		(open-network-stream "*chess-network*" (current-buffer)
				     (read-string "Host: ")
				     (read-string "Port: "))))
	(setq chess-engine-process proc
	      chess-network-kind (if (eq which ?s) 'server 'client))
	t))

     ((eq event 'ready)			; don't set active yet
      (chess-game-run-hooks game 'announce-autosave)
      (if (eq chess-network-kind 'server)
	  (chess-message 'network-waiting)
	(chess-network-handler game 'match)))

     ((eq event 'setup-pos)
      (chess-engine-send nil (format "fen %s\n"
				     (chess-pos-to-fen (car args)))))

     ((eq event 'setup-game)
      (chess-engine-send nil (format "pgn %s\n"
				     (chess-network-flatten-multiline
				      (chess-game-to-pgn (car args) nil t)))))

     ((eq event 'pass)
      (chess-engine-send nil "pass\n"))

     ((eq event 'busy)
      (chess-engine-send nil "playing\n"))

     ((eq event 'match)
      (setq chess-engine-pending-offer 'match)
      (chess-engine-send nil (format "chess match %s\n" chess-full-name)))

     ((eq event 'draw)
      (if chess-engine-pending-offer
	  (chess-engine-command nil 'retract))
      (setq chess-engine-pending-offer 'draw)
      (chess-engine-send nil "draw\n"))

     ((eq event 'abort)
      (if chess-engine-pending-offer
	  (chess-engine-command nil 'retract))
      (setq chess-engine-pending-offer 'abort)
      (chess-engine-send nil "abort\n"))

     ((eq event 'undo)
      (if chess-engine-pending-offer
	  (chess-engine-command nil 'retract))
      (setq chess-engine-pending-offer 'undo
	    chess-engine-pending-arg (car args))

      (chess-engine-send nil (format "takeback %d\n" (car args)))
      (chess-message 'takeback-sent (car args)))

     ((eq event 'accept)
      (chess-engine-send nil (if (car args)
				 (format "accept %s\n" (car args))
			       "accept\n")))

     ((eq event 'decline)
      (chess-engine-send nil "decline\n"))

     ((eq event 'retract)
      (chess-engine-send nil "retract\n"))

     ((eq event 'illegal)
      (chess-engine-send nil "illegal\n"))

     ((eq event 'call-flag)
      (chess-engine-send nil "flag\n"))

     ((eq event 'kibitz)
      (chess-engine-send nil (format "kibitz %s\n"
				     (chess-network-flatten-multiline
				      (car args)))))

     ((eq event 'chat)
      (chess-engine-send nil (format "chat %s\n"
				     (chess-network-flatten-multiline
				      (car args)))))

     ((eq event 'set-index)
      (chess-engine-send nil (format "index %d\n" (car args))))

     ((eq event 'flag-fell)
      (chess-engine-send nil "forfeit\n")
      (chess-common-handler game 'flag-fell))

     (t
      (apply #'chess-common-handler game event args)))))

(provide 'chess-network)

;;; chess-network.el ends here
