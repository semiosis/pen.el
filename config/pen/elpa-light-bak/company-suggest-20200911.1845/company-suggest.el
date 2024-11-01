;;; company-suggest.el --- Company-mode back-end for search engine suggests  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Jürgen Hötzel

;; Author: Jürgen Hötzel <juergen@archlinux.org>
;; URL: https://github.com/juergenhoetzel/company-suggest
;; Package-Version: 20200911.1845
;; Package-Commit: 1c89c9de3852f07ce28b0bedf1fbf56fe6eedcdc
;; Version: 1.0
;; Keywords: completion convenience
;; Package-Requires: ((company "0.9.0") (emacs "25.1"))

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

;; This package provides a company-mode back-end for auto-completing using search engine suggestions.

;;; Code:

(eval-when-compile
  (require 'subr-x))
(require 'company)
(require 'xml)
(require 'mm-url)
(require 'cl-lib)
(require 'thingatpt)
(require 'json)

(defconst company-suggest--json-string-parser
  (if (and (functionp 'json-parse-string)
           (>= emacs-major-version 27))
      (lambda (json-string)
        (json-parse-string
	 json-string
         :object-type 'alist :array-type 'list
         :null-object nil :false-object nil))
    #'json-read-from-string)
  "Function to use to parse JSON strings.")

(defgroup company-suggest '()
  "Customization group for `company-suggest'."
  :link '(url-link "http://github.com/juergenhoetzel/company-suggest")
  :group 'convenience
  :group 'comm)

(defcustom company-suggest-complete-sentence nil
  "When non-nil, use sentence to complete current word."
  :type 'boolean)

(defvar company-suggest-google-url
  "https://suggestqueries.google.com/complete/search?q=%s&client=toolbar")

(defvar company-suggest-wiktionary-url
  "https://en.wiktionary.org/w/api.php?action=opensearch&format=json&formatversion=2&search=%s&namespace=0&limit=10&suggest=true")

(defun company-suggest--google-candidates (callback prefix)
  "Return a list of Google suggestions matching PREFIX."
  (let ((url-request-extra-headers '(("User-Agent" . "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181")))
	(url (format company-suggest-google-url (url-encode-url prefix))))
    (url-retrieve url (lambda (status)
			(when-let ((err (plist-get status :error)))
			  (error "Error retrieving: %s: %s" url err))
			(funcall callback
				 (prog1
				     (cl-remove-if-not (lambda  (s)
							 (string-prefix-p prefix s t))
						       (mapcar (lambda (node)
								 (decode-coding-string  (xml-get-attribute (car (xml-get-children node 'suggestion)) 'data) 'utf-8))
							       (xml-get-children (car (xml-parse-region (point-min) (point-max))) 'CompleteSuggestion)))
				   (kill-buffer))))
		  nil t)))

(defun company-suggest--sentence-at-point ()
  "Return the sentence at point."
  (let* ((current-line (line-number-at-pos))
	 sentence-line
	 (sentence
	  (save-excursion
	    (backward-sentence 1)
	    (setq sentence-line (line-number-at-pos))
	    ;; don't span prefix over following lines
	    (when (thing-at-point 'sentence)
	      (replace-regexp-in-string
	       ".*?\\([[:alnum:]][[:space:][:alnum:]]*\\)"
	       "\\1"
	       (replace-regexp-in-string "\\(.*\\)[ \t\n]*.*" "\\1" (thing-at-point 'sentence)))))))
    (or (if (eq sentence-line current-line) sentence) (thing-at-point 'word)))) ;fallback to word

;;;###autoload
(defun company-suggest-google (command &optional arg &rest ignored)
  "`company-mode' completion backend for Google suggestions."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-suggest-google))
    (prefix (when (derived-mode-p 'text-mode)
	      (if company-suggest-complete-sentence
		  ;; FIXME (thing-at-point 'sentence) doesn't work reliable
		  (company-suggest--sentence-at-point)
		(thing-at-point 'word))))
    (ignore-case t)
    (candidates (cons :async (lambda (callback)
			       (company-suggest--google-candidates callback arg))))))

(defun company-suggest--wiktionary-candidates (callback prefix)
  "Return a list of Wiktionary suggestions matching PREFIX."
  (url-retrieve (format company-suggest-wiktionary-url (url-encode-url prefix))
		(lambda (status)
		  (when-let ((err (plist-get status :error)))
		    (error "Error retrieving: %s: %s" (url-encode-url prefix) err))
		  (when (re-search-forward "^$")
		    (let ((json-array-type 'list)
			  (json-object-type 'hash-table)
			  (json-key-type 'string)
			  (result-string (decode-coding-string (buffer-substring-no-properties  (point) (point-max)) 'utf-8)))
		      ;; FIXME: Error checking
		      (funcall callback (cadr (funcall company-suggest--json-string-parser result-string))))))
		nil t))

;;;###autoload
(defun company-suggest-wiktionary (command &optional arg &rest ignored)
  "`company-mode' completion backend for Wiktionary suggestions."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-suggest-wiktionary))
    (prefix (when (derived-mode-p 'text-mode)
	      (thing-at-point 'word)))
    (candidates (cons :async (lambda (callback) (company-suggest--wiktionary-candidates callback arg))))))

(provide 'company-suggest)
;;; company-suggest.el ends here
