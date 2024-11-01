;;; ob-mongo.el --- Execute mongodb queries within org-mode blocks.
;; Copyright 2013 Kris Jenkins

;; License: GNU General Public License version 3, or (at your option) any later version
;; Author: Kris Jenkins <krisajenkins@gmail.com>
;; Maintainer: Kris Jenkins <krisajenkins@gmail.com>
;; Keywords: org babel mongo mongodb
;; Package-Version: 20170720.1919
;; Package-Commit: 371bf19c7c10eab2f86424f8db8ab685997eb5aa
;; URL: https://github.com/krisajenkins/ob-mongo
;; Created: 17th July 2013
;; Version: 0.1.0
;; Package-Requires: ((org "8"))

;;; Commentary:
;;
;; Execute mongodb queries within org-mode blocks.

;;; Code:
(require 'org)
(require 'ob)

(defgroup ob-mongo nil
  "org-mode blocks for MongoDB."
  :group 'org)

(defcustom ob-mongo:default-db nil
  "Default mongo database."
  :group 'ob-mongo
  :type 'string)

(defcustom ob-mongo:default-host nil
  "Default mongo host."
  :group 'ob-mongo
  :type 'string)

(defcustom ob-mongo:default-port nil
  "Default mongo port."
  :group 'ob-mongo
  :type 'integer)

(defcustom ob-mongo:default-user nil
  "Default mongo user."
  :group 'ob-mongo
  :type 'string)

(defcustom ob-mongo:default-password nil
  "Default mongo password."
  :group 'ob-mongo
  :type 'string)

(defcustom ob-mongo:default-mongo-executable "mongo"
  "Default mongo executable."
  :group 'ob-mongo
  :type 'string)

(defun ob-mongo--make-command (params)
  (let ((pdefs `((:mongoexec ,ob-mongo:default-mongo-executable)
                 (quiet "--quiet")
                 (:host , ob-mongo:default-host "--host")
                 (:port ,ob-mongo:default-port "--port")
                 (:password ,ob-mongo:default-password "--password")
                 (:user ,ob-mongo:default-user "--username")
                 (:db ,ob-mongo:default-db))))
    (mapconcat (lambda (pdef)
                 (let ((opt (or (nth 2 pdef) ""))
                       (val (or (cdr (assoc (car pdef) params))
                                (nth 1 pdef))))
                   (cond ((not opt) (format "%s" val))
                         (val (format "%s %s" opt val))
                         (t ""))))
               pdefs " ")))

;;;###autoload
(defun org-babel-execute:mongo (body params)
  "org-babel mongo hook."
  (unless (assoc :db params)
    (user-error "The required parameter :db is missing."))
  (org-babel-eval (ob-mongo--make-command params) body))

;;;###autoload
(eval-after-load "org"
  '(add-to-list 'org-src-lang-modes '("mongo" . js)))

(provide 'ob-mongo)

;;; ob-mongo.el ends here
