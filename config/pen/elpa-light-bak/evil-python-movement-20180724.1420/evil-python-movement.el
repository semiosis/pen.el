;;; evil-python-movement.el --- Port Neovim's python movement to Evil -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Felipe Lema

;; Author: Felipe Lema <felipelema en mortemale punto org>
;; URL: https://bitbucket.org/FelipeLema/evil-python-movement.el/
;; Package-Version: 20180724.1420
;; Package-Commit: 9936b3b7f8d96415d517c1f3604637889484a637
;; Package-Requires: ((emacs "25.1") (cl-lib "0.5") (dash "2.13.0") (evil "1.0") (s "1.12.0"))

;; Version: 1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; First, I was reading about whether Neovim provided movement tools
;; Python that I didn't know of, when I stumbled with this:
;; https://stackoverflow.com/a/28284564
;; After learning that indeed they existed, they weren't present in
;; Evil.  After opening an issue
;; https://github.com/emacs-evil/evil/issues/1043
;; I was explained that these tools wouldn't be available through
;; Evil.  So, I implemented them myself.

;; TL;DR: this is best explained looking at https://stackoverflow.com/a/28284564
;;        or the unit tests (not yet availaible)

;;; Code:

(require 'dash)
(require 'evil)
(require 'rx)
(require 's)

(defconst evil-python-movement-def-or-class-regex
  `(|
    ;; async_funcdef | funcdef
    (and (? "async" (+ blank)) "def" (+ blank))
    ;; class
    (and "class" (+ blank)))
  "Regex for (func or class)

This is common regex between `evil-python-movement-top-level-def-regex'
and `evil-python-movement-def-regex' and it's not supposed
to be used as-is for matching anything.
See https://docs.python.org/3/reference/grammar.html.")

(defconst evil-python-movement-top-level-def-regex
  (rx
   line-start
   (eval evil-python-movement-def-or-class-regex))
  "Regex for top level def (func or class)

See `evil-python-movement-def-or-class-regex' for more info.")

(defconst evil-python-movement-def-regex
  (rx
   line-start
   (* blank) ;; indent
   (eval evil-python-movement-def-or-class-regex))
  "Regex for def (func or class)

See `evil-python-movement-def-or-class-regex' for more info.")

(defun evil-python-movement-to-regex (regex next-line-func)
  "Call NEXT-LINE-FUNC until line is a match for REGEX.

Assumes line movement
Note: need _partial_ match, not full"
  (funcall next-line-func)
  (let ((at-first-line (save-excursion
			 (beginning-of-line)
			 (bobp)))
	(at-last-line (save-excursion
			(end-of-line)
			(eobp))))
    (if (s-match regex (thing-at-point 'line))
	(point)
      ;; else keep searching (if possible to move)
      (if (not (or at-first-line at-last-line))
	  (evil-python-movement-to-regex regex next-line-func)))))

(defsubst evil-python-movement-backwards-to-top-level-def ()
  "Keep moving previous-line-y until reach previous top level def."
  (evil-python-movement-to-regex evil-python-movement-top-level-def-regex #'evil-previous-line))

(defsubst evil-python-movement-forward-to-top-level-def ()
  "Keep moving next-line-y until reach next top level def."
  (evil-python-movement-to-regex evil-python-movement-top-level-def-regex #'evil-next-line))

(defsubst evil-python-movement-backwards-to-def ()
  "Keep moving previous-line-y until reach previous def."
  (evil-python-movement-to-regex evil-python-movement-def-regex #'evil-previous-line))

(defsubst evil-python-movement-forward-to-def ()
  "Keep moving next-line-y until reach next def."
  (evil-python-movement-to-regex evil-python-movement-def-regex #'evil-next-line))

(defun evil-python-movement-common-python-movement (count noerror new-pos-function mov-name)
  "Try to move to position or report failure.

Try to move to COUNT times to position told by NEW-POS-FUNCTION or report as
MOV-NAME if NOERROR.
Returns new position or nil."
  (catch 'could-not-move
    (when-let ((maybe-new-position
		(-last-item
		 (save-excursion
		   (--map
		    ;; first test if we can move (in this iteration)
		    (if-let ((new-pos (funcall new-pos-function)))
			(goto-char new-pos)
		      ;; else
		      (progn
			(unless noerror
			  (message "Cannot move %s-wise for %n-th time"
				   mov-name it))
			(throw 'could-not-move nil)))
		    (number-sequence 1 count))))))
      (goto-char maybe-new-position))))

;; Evil motion: `[['
;;;###autoload(autoload 'evil-python-movement-lsb-lsb "evil-python-movement" nil t)
(evil-define-motion evil-python-movement-lsb-lsb (count noerror)
  "Mimic Neovim's [[ movement in Python editing.

See https://github.com/noctuid/evil-guide#command-properties.
Based off `evil-forward-char'."
  :jump t
  :type inclusive
  ;; first, test if movable
  (interactive "<c>" (list (evil-kbd-macro-suppress-motion-error)))
  (evil-python-movement-common-python-movement count
					       noerror
					       #'evil-python-movement-backwards-to-top-level-def
					       "[["))

;; Evil motion: `]]'
;;;###autoload(autoload 'evil-python-movement-rsb-rsb "evil-python-movement" nil t)
(evil-define-motion evil-python-movement-rsb-rsb (count noerror)
  "Mimic Neovim's ]] movement in Python editing.

See https://github.com/noctuid/evil-guide#command-properties.
Based off `evil-forward-char'."
  :jump t
  :type inclusive
  ;; first, test if movable
  (interactive "<c>" (list (evil-kbd-macro-suppress-motion-error)))
  (evil-python-movement-common-python-movement
   count noerror
   #'evil-python-movement-forward-to-top-level-def "]]"))

;; Evil motion: `[m'
;;;###autoload(autoload 'evil-python-movement-lsb-m "evil-python-movement" nil t)
(evil-define-motion evil-python-movement-lsb-m (count noerror)
  "Mimic Neovim's [m movement in Python editing.

See https://github.com/noctuid/evil-guide#command-properties.
Based off `evil-forward-char'."
  :jump t
  :type inclusive
  ;; first, test if movable
  (interactive "<c>" (list (evil-kbd-macro-suppress-motion-error)))
  (when-let ((new-pos (save-excursion
			(evil-first-non-blank)
			(let ((p (evil-python-movement-common-python-movement
				  count
				  noerror
				  #'evil-python-movement-backwards-to-def
				  "[m")))
			  p))))
    (goto-char new-pos)))

;; Evil motion: `]m`
;;;###autoload(autoload 'evil-python-movement-rsb-m "evil-python-movement" nil t)
(evil-define-motion evil-python-movement-rsb-m (count noerror)
  "Mimic Neovim's ]m movement in Python editing.

See https://github.com/noctuid/evil-guide#command-properties.
Based off `evil-forward-char'."
  :jump t
  :type inclusive
  ;; first, test if movable
  (interactive "<c>" (list (evil-kbd-macro-suppress-motion-error)))
  (evil-python-movement-common-python-movement
   count
   noerror
   #'evil-python-movement-forward-to-def
   "]m"))

(defun evil-python-movement-py-block-end ()
  "Return the point of end of line of current indent."
  (let ((target-indent (save-excursion
			 (evil-first-non-blank)
			 (length (buffer-substring-no-properties
				  (line-beginning-position)
				  (point))))))
    ;; now, look for end of block
    (cl-loop
     do ;; at least, move from start
     (evil-next-line)
     until (or
	    ;; reached the end of buffer
	    (= (line-end-position) (point-max))
	    ;; indentation changed for new def/class
	    ;; ruling out blank lines
	    (and (not (s-blank-str? (thing-at-point 'line)))
		 (>= target-indent
		     (save-excursion
		       (evil-first-non-blank)
		       (let ((this-line-indent (buffer-substring-no-properties
						(line-beginning-position)
						(point))))
			 (length this-line-indent)))))))
    (cl-loop do (evil-previous-line)
	     until (not (s-blank-str? (thing-at-point 'line))))
    ;; return end-of-line position
    (evil-end-of-line)
    (point)))

(defun evil-python-movement-to-then-to-end-of-block (move-to-fn movement-name noerror)
  "Move to wherever using MOVE-TO-FN, then move to end of block.

Use MOVEMENT-NAME for error message.
NOERROR is non-nil → reported error.
Moves to end of block and end of line."
  (if-let* ((maybe-new-pos (save-excursion
			     (funcall move-to-fn)))
	    (maybe-block-end (progn
			       (goto-char maybe-new-pos)
			       (evil-python-movement-py-block-end))))
      (progn
	(goto-char maybe-block-end)
	(evil-end-of-line)))
  ;; else, report error
  (unless noerror
    (message "Cannot move %s-wise" movement-name)))

;; Evil motion: `[M`
;;;###autoload(autoload 'evil-python-movement-lsb-M "evil-python-movement" nil t)
(evil-define-motion evil-python-movement-lsb-M (count noerror)
  "Mimic Neovim's ]M movement in Python editing.

See https://github.com/noctuid/evil-guide#command-properties.
Based off `evil-forward-char'."
  :jump t
  :type inclusive ;; (-any '(line inclusive exclusive block) )
  (interactive "<c>" (list (evil-kbd-macro-suppress-motion-error)))
  (evil-python-movement-to-then-to-end-of-block
   (lambda ()
     (evil-first-non-blank)
     (evil-python-movement-common-python-movement count
						  noerror
						  #'evil-python-movement-backwards-to-def
						  ;;↓ different logging here is intentional
						  "[M"))
   "[M" noerror))

;; Evil motion: `]M`
;;;###autoload(autoload 'evil-python-movement-rsb-M "evil-python-movement" nil t)
(evil-define-motion evil-python-movement-rsb-M (count noerror)
  :jump t
  :type inclusive ;; (-any '(line inclusive exclusive block) )
  (interactive "<c>" (list (evil-kbd-macro-suppress-motion-error)))
  (evil-python-movement-to-then-to-end-of-block
   (lambda ()
     ;; reposition if necessary (when looking at blank lines)
     (cl-loop until (not (s-blank-str? (thing-at-point 'line)))
	      do (evil-next-line))
     (goto-char (evil-python-movement-py-block-end)))
   "]M" noerror))

;; Evil motion: `[]`
;;;###autoload(autoload 'evil-python-movement-lsb-rsb "evil-python-movement" nil t)
(evil-define-motion evil-python-movement-lsb-rsb (count noerror)
  :jump t
  :type inclusive
  (interactive "<c>" (list (evil-kbd-macro-suppress-motion-error)))
  (evil-python-movement-lsb-lsb count noerror)
  (evil-python-movement-py-block-end))

;; Evil motion: `][`
;;;###autoload(autoload 'evil-python-movement-rsb-lsb "evil-python-movement" nil t)
(evil-define-motion evil-python-movement-rsb-lsb (count noerror)
  :jump t
  :type inclusive
  (interactive "<c>" (list (evil-kbd-macro-suppress-motion-error)))
  (let ((already-at-top-level-def (s-match evil-python-movement-top-level-def-regex
  					   (thing-at-point 'line))
  				  )) ;; *must go to previous top level
    (unless already-at-top-level-def
      (evil-python-movement-lsb-lsb count noerror)))
  (evil-python-movement-py-block-end))


(provide 'evil-python-movement)
;;; evil-python-movement.el ends here
