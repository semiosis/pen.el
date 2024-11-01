;;; ob-browser.el --- Render HTML in org-mode blocks.
;; Copyright 2013 Kris Jenkins

;; License: GNU General Public License version 3, or (at your option) any later version
;; Author: Kris Jenkins <krisajenkins@gmail.com>
;; Maintainer: Kris Jenkins <krisajenkins@gmail.com>
;; Keywords: org babel browser phantomjs
;; URL: https://github.com/krisajenkins/ob-browser
;; Created: 24th July 2013
;; Version: 0.1.0
;; Package-Requires: ((org "8"))

;;; Commentary:
;;
;; Render HTML in org-mode blocks.

;;; Code:
(require 'org)
(require 'ob)

(defvar ob-browser-base-dir (file-name-directory load-file-name))

(defgroup ob-browser nil
  "Render HTML in org-mode blocks."
  :group 'org)

;;;###autoload
(defvar org-babel-default-header-args:browser
  '((:results . "file")
    (:exports . "results"))
  "Default arguments for evaluating a browser source block.")

;;;###autoload
(defun org-babel-execute:browser (body params)
  "Execute a browser block."
  (let* ((driving-script (concat ob-browser-base-dir "ob-browser.js"))
	 (out (or (cdr (assoc :out params))
	 	  (error "browser code blocks require a :out header argument")))
	 (cmd (format "phantomjs %s %s" driving-script out)))
    (org-babel-eval cmd body)
    out))

;;;###autoload
(add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)

;;;###autoload
(eval-after-load "org"
  '(add-to-list 'org-src-lang-modes '("browser" . html)))

(provide 'ob-browser)

;;; ob-browser.el ends here
