;;; helm-wordnet.el --- Helm interface to local wordnet dictionary  -*- lexical-binding: t; -*-

;; Copyright (C) 2015 helm-wordnet authors

;; Author: Raghav Kumar Gautam <rgautam@apache.com>
;; URL: https://github.com/raghavgautam/helm-wordnet
;; Package-Version: 20160128.1507
;; Package-Commit: a36dbc6fcb570b812870bc1e190f203e0a0042fc
;; Keywords: Dictionary, WordNet, Emacs, Elisp, Helm
;; Package-Requires: ((emacs "24") (helm "1.7.0") (cl-lib "0.5"))

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

;;; Commentary:

;; Look up wordnet dictionary through helm-interface.
;; Default configuration works with WordNet on OSX.
;; For other dictionaries configure: helm-wordnet-prog, helm-wordnet-pre-arg, helm-wordnet-post-arg & helm-wordnet-get-wordlist

;;; Code:
(require 'helm)
(require 'cl-lib)

(defcustom helm-wordnet-follow-delay 1
  "Delay before Dictionary summary pops up."
  :type 'number
  :group 'helm-wordnet)

(defcustom helm-wordnet-wordnet-location
  (car
   (remove nil
	   (cl-mapcar  (lambda (x) (car (file-expand-wildcards x)))
		       (list "/opt/local/share/WordNet*/dict" ;;mac port
			     "/usr/local/Cellar/wordnet/*/dict" ;;homebrew
			     "/usr/share/wordnet*" ;;linux
			     ;;TODO Add suitable paths for other operating system
			     ))))
  "Location of wordnet index files."
  :type 'string
  :group 'helm-wordnet)

(defcustom helm-wordnet-prog "wn"
  "Name of the Wordnet Dictionary program."
  :type 'string
  :group 'helm-wordnet)

(defcustom helm-wordnet-buffer "*Dictionary*"
  "Name of the Wordnet Dictionary program."
  :type 'string
  :group 'helm-wordnet)

(defcustom helm-wordnet-pre-arg ""
  "Argument to Dictionary program after command and before the word."
  :type 'string
  :group 'helm-wordnet)

(defcustom helm-wordnet-post-arg "-over"
  "Argument to Dictionary program after the word."
  :type 'string
  :group 'helm-wordnet)

(defcustom helm-wordnet-get-wordlist 'helm-wordnet-wordnet-wordlist
  "Function for getting list of words in dictionary."
  :type 'symbol-function
  :group 'helm-wordnet)

(defvar helm-wordnet-allwords nil
  "List of all the words available in the Dictionary.")

;;(helm-wordnet-get-candidates)
(defun helm-wordnet-get-candidates ()
  "Fetch Dictionary suggestions and return them as a list."
  (unless (bound-and-true-p helm-wordnet-allwords)
    (setq helm-wordnet-allwords (funcall helm-wordnet-get-wordlist)))
  helm-wordnet-allwords)

(defun helm-wordnet-wordnet-wordlist ()
  "Fetch WordNet suggestions and return them as a list."
  (let* ((all-indexes (directory-files helm-wordnet-wordnet-location t "index\\..*" ))
         (word-indexes (cl-remove-if (lambda (x) (string-match-p "index\\.sense$" x)) all-indexes)))
    (cl-mapcan
     (lambda (x)
       (with-temp-buffer
	 (insert-file-contents x)
	 (goto-char (point-min))
	 (while (re-search-forward "^  .*\n\\| .*" nil t)
	   (replace-match ""))
	 (split-string (buffer-string) "\n" t)))
     word-indexes)))

;;(helm-wordnet-persistent-action "test")
(defun helm-wordnet-persistent-action (word)
  "Display meaning of WORD."
  (let ((buf (get-buffer-create helm-wordnet-buffer)))
    (with-current-buffer buf
      (setq show-trailing-whitespace nil)
      (read-only-mode -1)
      (erase-buffer)
      (setq cursor-type nil
	    word-wrap t)
      (insert (shell-command-to-string (format "%s %s %s %s" helm-wordnet-prog helm-wordnet-pre-arg word helm-wordnet-post-arg)))
      (read-only-mode 1)
      (display-buffer buf))))

(defvar helm-wordnet-suggest-source
  (helm-build-sync-source "Dictionary Suggest"
    :candidates #'helm-wordnet-get-candidates
    :action '(("Dictionary" . helm-wordnet-persistent-action))
    :persistent-action #'helm-wordnet-persistent-action
    :pattern-transformer #'downcase
    :follow 1
    :follow-delay helm-wordnet-follow-delay
    :requires-pattern 1))

;;;###autoload
(defun helm-wordnet-suggest ()
  "Preconfigured `helm' for Dictionary lookup with Dictionary suggest."
  (interactive)
  (helm :sources 'helm-wordnet-suggest-source
	:buffer "*helm dictionary*"
	:input (thing-at-point 'word)))

(defalias 'helm-wordnet 'helm-wordnet-suggest)

(provide 'helm-wordnet)
;;; helm-wordnet.el ends here
