;;; ob-html-chrome.el --- HTML code blocks converted to PNG using Chrome -*- lexical-binding: t -*-

;; Author: Nik Clayton nik@ngo.org.uk
;; URL: http://github.com/nikclayton/ob-html-chrome
;; Package-Version: 20181219.1042
;; Package-Commit: 7af6e4a24ed0aaf67751bdf752c7ca0ba02bb8d4
;; Version: 1.1
;; Package-Requires: ((emacs "24.4") (f "0.20.0") (s "1.7.0"))
;; Keywords: languages, org, org-babel, chrome, html

;;; Commentary:

;; Org-Babel support for rendering HTML to PNG files using Chrome.
;;
;; This is similar functionality to ob-browser, without the PhantomJS
;; requirement.

;;; Code:
(require 'org)
(require 'ob)
(require 'ob-eval)
(require 'f)
(require 's)

(defcustom org-babel-html-chrome-chrome-executable
  ""
  "Full path to Google Chrome."
  :group 'org-babel
  :safe t
  :type 'string)

;; Treat html-chrome SRC blocks like html SRC blocks for editing
(add-to-list 'org-src-lang-modes (quote ("html-chrome" . html)))

(defvar org-babel-default-header-args:html-chrome
  '((:results . "file") (:exports . "both"))
  "Default arguments to use when evaluating a html-chrome SRC block.")

(defun org-babel-execute:html-chrome (body params)
  "Render the HTML in BODY using PARAMS."
  (unless (f-executable? org-babel-html-chrome-chrome-executable)
    (error "Can not export HTML: `%s' (specified by org-babel-html-chrome-chrome-executable) does not exist or is not executable" org-babel-html-chrome-chrome-executable))
  (let* ((processed-params (org-babel-process-params params))
	 (org-babel-temporary-directory default-directory)
	 (html-file (org-babel-temp-file "ob-html-chrome" ".html"))
	 (url
	  (or (cdr (assoc :url processed-params))
	      (concat "file://" (org-babel-process-file-name html-file))))
	 (out-file-base
	  (or (cdr (assoc :file processed-params)) ; :file arg
	      (nth 4 (org-babel-get-src-block-info)) ; #+NAME of block
	      (s-dashed-words (nth 4 (org-heading-components))))) ; Heading
	 (out-file (concat out-file-base ".png"))
	 (flags (cdr (assoc :flags processed-params)))
	 (cmd (s-join
	       " "
	       `(,(shell-quote-argument
		   org-babel-html-chrome-chrome-executable)
		 ,@'("--headless" "--disable-gpu" "--enable-logging")
		 ,flags
		 ,(format "--screenshot=%s"
			  (org-babel-process-file-name out-file))
		 ,url))))
    (with-temp-file html-file
      (insert body))
    (org-babel-eval cmd "")
    (delete-file html-file)
    out-file))

(defun org-babel-prep-session:html-chrome (session params)
  "Return an error, sessions are not supported."
  (error "ob-html-chrome does not support sessions"))

(provide 'ob-html-chrome)

;;; ob-html-chrome.el ends here
