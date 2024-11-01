;;; helm-sql-connect.el --- Choose a database to connect to via Helm.
;; Copyright 2017 Eric Hansen
;;
;; Author: Eric Hansen <hansen.c.eric@gmail.com>
;; Maintainer: Eric Hansen <hansen.c.eric@gmail.com>
;; Keywords: tools convenience comm
;; Package-Version: 20170319.1251
;; Package-Commit: 5aead55b6f8636140945714d8c332b287ab9ef10
;; URL: https://github.com/eric-hansen/helm-sql-connect
;; Created: 1st March 2017
;; Version: 0.0.1
;; Package-Requires: ((helm "0.0.0"))

;;; Commentary:
;;
;; Provides the command `helm-sql-connect', which uses helm to prompt
;; for and connect to a database connection in `sql-connection-alist'.

;;; Code:

(require 'sql)
(require 'helm)

(defun helm-sql-connect-to ()
  "Populate helm buffer with connection string names from a populated `sql-connection-alist'."
  (with-helm-current-buffer
    (mapcar 'car sql-connection-alist)))

(defvar helm-sql-connect-pool
  '((name . "SQL Connections")
    (candidates . helm-sql-connect-to)
    (action . #'sql-connect)))

;;;###autoload
(defun helm-sql-connect ()
  "Helm directive to call when wanting to list SQL connections to connect to."
  (interactive)
  (helm :sources '(helm-sql-connection-pool)
        :buffer "*helm-sql-connect*"))

(provide 'helm-sql-connect)

;;; helm-sql-connect.el ends here
