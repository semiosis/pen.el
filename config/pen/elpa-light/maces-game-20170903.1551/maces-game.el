;;; maces-game.el --- another anagram game. -*- lexical-binding: t; -*-

;; Copyright (C) 2017, Pawel Bokota

;; Author: Pawel Bokota <pawelb.lnx@gmail.com>
;; Created: 24 Aug 2017
;; URL: https://github.com/pawelbx/anagram-game
;; Version: 0.1
;; Keywords: games, word games, anagram
;; Package-Requires: ((dash "2.12.0") (cl-lib "0.5") (emacs "24"))
;; License: GPL v3

;; This file is not part of GNU Emacs.

;;; Commentary:

;; To play game run the function `maces-game'
;; This game was inspired by the New York Times puzzle game
;; "Spelling Bee." The idea is to create words out of the given
;; seven letters.  You can use each given letter multiple times.  The
;; longer the word you create, the more points you earn.

;;; Installation:

;; (require 'maces-game)

;;; Code:
(require 'dash)
(require 'cl-lib)

(defvar maces-game--state nil "Holds all game state.")
(defconst maces-game--dir (file-name-directory (or load-file-name buffer-file-name)))

(defface maces-game--letters-face
  '((t :inherit font-lock-keyword-face
       :height 1.5))
  "face for shuffled letters"
  :group 'maces-game)

(defface maces-game--guess-face
  '((t :inherit font-lock-constant-face
       :height 1.5))
  "face for user input"
  :group 'maces-game)

(defface maces-game--points-face
  '((t :inherit font-lock-doc-face
       :weight bold
       :height 1.5))
  "face for points"
  :group 'maces-game)

(defface maces-game--message-face
  '((t :inherit font-lock-warning-face
       :weight bold
       :height 1.5))
  "face for messages"
  :group 'maces-game)

(defface maces-game--instruction-face
  '((t :inherit font-lock-builtin-face
       :height 1.1))
  "face for messages"
  :group 'maces-game)

(defun maces-game ()
  "Create a new anagram game."
  (interactive)
  (switch-to-buffer "*maces-game*")
  (maces-game--mode)
  (maces-game--init-game))

(define-derived-mode maces-game--mode special-mode "maces-game"
  (define-key maces-game--mode-map (kbd "SPC") 'maces-game--rotate-letters)
  (define-key maces-game--mode-map (kbd "RET") 'maces-game--check-guess)
  (define-key maces-game--mode-map (kbd "DEL") 'maces-game--delete-letter)
  (define-key maces-game--mode-map (kbd "Q") 'maces-game--quit)
  (mapc 'maces-game--define-letter-key '("a" "b" "c" "d" "e" "f" "g" "h" "i" "j"
                                        "k" "l" "m" "n" "o" "p" "q" "r" "s" "t"
                                        "u" "v" "w" "x" "y" "z")))

(defun maces-game--check-guess()
  "checks if guess if correct"
  (interactive)
  (let* ((guess (maces-game--get-user-input))
         (words (nth 1 maces-game--state)))

    (cond ((member guess (maces-game--get-found))
           (maces-game--set-msg "Already found that word"))
          ((< (length guess) 4)
           (maces-game--set-msg "At least 4 letter needed"))
          ((--first (equal guess it) words)
           (maces-game--add-to-found guess)
           (maces-game--set-msg "Nice!")
           (maces-game--add-points guess))
          (t (maces-game--set-msg "Not Found")))
    (maces-game--clear-user-input)
    (maces-game--render)))

(defun maces-game--quit ()
  "Kill current buffer."
  (interactive)
  (kill-buffer (current-buffer)))


(defun maces-game--add-to-found (word)
  "Add word to found list."
  (setcar (nthcdr 5 maces-game--state) (cons word (maces-game--get-found))))

(defun maces-game--get-found ()
  "Gets words that have been found."
  (nth 5 maces-game--state))

(defun maces-game--get-user-input ()
  "Gets the current user input."
  (nth 2 maces-game--state))

(defun maces-game--clear-user-input ()
  "Clears user input."
  (setcar (nthcdr 2 maces-game--state) ""))

(defun maces-game--set-msg (msg)
  "Set message for user."
  (setcar (nthcdr 4 maces-game--state) msg))

(defun maces-game--get-msg ()
  "Gets current message to user."
  (nth 4 maces-game--state))

(defun maces-game--delete-letter ()
  "Delete letter from guess."
  (interactive)
  (setcar (nthcdr 2 maces-game--state)
          (substring (nth 2 maces-game--state) 0 (1- (length (nth 2 maces-game--state)))))
  (maces-game--render))

(defun maces-game--get-points ()
  "Get current points."
  (nth 3 maces-game--state))

(defun maces-game--add-points (word)
  "Add points dependent of the length of the WORD."
  (let ((points (nthcdr 3 maces-game--state))
        (wlen (length word))
        (num-points (maces-game--get-points)))
    (cond ((<= wlen 6) (setcar points (+ num-points 2)))
          ((<= wlen 10) (setcar points (+ num-points 4)))
          (t (setcar points (+ num-points 6))))))

(defun maces-game--define-letter-key (letter)
  (define-key maces-game--mode-map (kbd letter)
    (lambda ()
      "check if key is valid"
      (interactive)
      (when (maces-game--str-contains? (car (cl-coerce letter 'list)) (car maces-game--state))
        (setcar (nthcdr 2 maces-game--state)
                (concat (nth 2 maces-game--state) letter))
        (maces-game--render)))))

(defun maces-game--init-game ()
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (propertize "Loading Anagrams..." 'face 'maces-game--guess-face))
    (redisplay t))
  (setq maces-game--state (maces-game--generate))
  (maces-game--render))

(defun maces-game--render ()
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (propertize (car maces-game--state) 'face 'maces-game--letters-face))
    (insert (propertize (format "\t\t POINTS: %d" (maces-game--get-points))
                        'face 'maces-game--points-face))
    (insert "\n\n")
    (insert (propertize (maces-game--get-msg) 'face 'maces-game--message-face))
    (insert "\n\n")
    (insert (propertize (concat "Find words from the letters above.\n"
                                "You can use the same letter multiple times in your word.\n"
                                "The longer the word you find, the more points you get.\n"
                                "Try to get to at least 21 points!")))
    (insert "\n\n")
    (insert (propertize (concat "Space to rotate letters\n"
                                "Q to quit\n"
                                "Enter to submit your guess")))
    (insert "\n\n")
    (insert (propertize (nth 2 maces-game--state) 'face 'maces-game--guess-face))))

(defun maces-game--rotate-letters ()
  "Shuffle letters."
  (interactive)
  (setcar maces-game--state (cl-coerce (-rotate 1 (cl-coerce (car maces-game--state) 'list)) 'string))
  (maces-game--render))

(defun maces-game--generate()
  (let* ((words (maces-game--load-words))
         (word (maces-game--generate-letters words))
         (anagrams
          (-filter (lambda (curr-word)
                     (-reduce-from (lambda (mem letter)
                                     (and mem (maces-game--str-contains? letter word)))
                                   t (cl-coerce curr-word 'list)))
                   words)))
    ;; scrambled word, anagrams, user input, points, current msg, found words
    (list (cl-coerce (maces-game--shuffle (delete-dups (cl-coerce word 'list))) 'string)
          anagrams "" 0 "" '())))

(defun maces-game--load-words ()
  (with-current-buffer
      (find-file-noselect (concat maces-game--dir "words.txt"))
    (split-string
     (save-restriction
       (widen)
       (buffer-substring-no-properties
        (point-min)
        (point-max)))
     "\n" t)))

(defun maces-game--generate-letters (words)
  (let ((valid-words (--filter (equal (length (delete-dups (cl-coerce it 'list))) 7) words)))
    (nth (random (length valid-words)) valid-words)))

(defun maces-game--str-contains? (needle s)
  (if (member needle (cl-coerce s 'list)) t nil))

(defun maces-game--shuffle (list)
  (let ((shuff-list (-copy list))
        (i (- (length list) 1)))
    (while (> i 0)
      (let ((j (random (+ i 1)))
            (elem (nth i shuff-list)))
        (setcar (nthcdr i shuff-list) (nth j shuff-list))
        (setcar (nthcdr j shuff-list) elem)
        (setq i (- i 1))))
    shuff-list))

(provide 'maces-game)

;;; maces-game.el ends here
