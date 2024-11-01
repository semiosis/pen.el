;;; git-time-metric.el --- Provide function to record time with gtm ( git time metric )

;; Copyright (C) 2018 Anton Sivolapov
;; This package uses the MIT License.
;; See the LICENSE file.

;; Author: Anton Sivolapov <anton.sivolapov@gmail.com>
;; Version: 1.0
;; Package-Version: 20181116.2011
;; Package-Commit: 287108ed1d6885dc795eb3bad4476aa08c626186
;; Package-Requires: ()
;; Keywords: tools, gtm, productivity, time
;; URL: https://github.com/c301/gtm-emacs-plugin

;;; Commentary:
;;
;; This file provides `git-time-metric-record', which records time with gtm. Essentially it calls `gtm record [options] <file_name>'.
;;
;; Usage:
;;     M-x git-time-metric-record
;;
;;     To automatically record time after saving:
;;     (Choose depending on your favorite mode.)
;;
;; (eval-after-load 'js-mode
;; 	'(add-hook 'js-mode-hook (lambda () (add-hook 'after-save-hook 'git-time-metric-record))))
;;
;; (eval-after-load 'js2-mode
;; 	'(add-hook 'js-mode-hook (lambda () (add-hook 'after-save-hook 'git-time-metric-record))))
;;
;;     Or track all your files:
;;
;; (add-hook 'after-save-hook 'git-time-metric-record)

;;; Code:
(defgroup git-time-metric nil
  "Record time to gtm with ‘git-time-metric-record’."
  :link '(function-link git-time-metric-record)
  :tag "Git Time Metric (gtm)"
  :group 'tools)

(defcustom git-time-metric-executable "gtm"
  "Set gtm executable to use."
  :tag "Git Time Metric (gtm) Executable"
  :type 'string)

(defcustom git-time-metric-executable-options nil
  "Additional options to pass to gtm (e.g. “-status=false”)."
  :tag "Git Time Metric (gtm) Options"
  :type '(repeat string))

;;;###autoload
(defun git-time-metric-record()
  "Record to gtm (git time metric), ie call ‘gtm record <file_name>’."
  (interactive)
  (unless buffer-file-name
    (error "Git Time Metric requires a file-visiting buffer"))

  (let ((gtm (executable-find git-time-metric-executable))
        (options (append (list "record")
                         git-time-metric-executable-options
                         (list buffer-file-name))))
    (unless gtm
      (error "Executable ‘%s’ not found" git-time-metric-executable))
    (apply 'call-process gtm nil "*gtm Errors*" nil options)))

(provide 'git-time-metric)

;;; git-time-metric.el ends here
