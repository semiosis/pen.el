;;; flycheck-julia.el --- Julia support for Flycheck -*- lexical-binding: t -*-

;; Copyright (C) 2017  Guido Kraemer <guido.kraemer@gmx.de>

;; Author: Guido Kraemer <guido.kraemer@gmx.de>
;; URL: https://github.com/gdkrmr/flycheck-julia
;; Package-Version: 20170729.2141
;; Package-Commit: 213b60a5a9a1cb7887260e1d159b5bb27167cbb6
;; Keywords: convenience, tools, languages
;; Version: 0.1.1
;; Package-Requires: ((emacs "24") (flycheck "0.22"))

;; This file is not part of GNU Emacs.

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

;; This Flycheck extension provides a `Lint.jl' integration for flycheck (see
;; URL `https://github.com/tonyhffong/Lint.jl') to check Julia buffers for
;; errors.
;;
;; # Setup
;;
;; Add the following to your init file:
;;
;;      (add-to-list 'load-path "/path/to/directory/containing/flycheck-julia.el/file")
;;      (require 'flycheck-julia)
;;      (flycheck-julia-setup)
;;      (add-to-list 'flycheck-global-modes 'julia-mode)
;;      (add-to-list 'flycheck-global-modes 'ess-julia-mode)
;;
;; # Usage
;;
;; Just use Flycheck as usual in julia-mode buffers. Flycheck will
;; automatically use the `flycheck-julia` syntax checker.
;;

;;; Code:

(require 'json)
(require 'flycheck)

(defgroup flycheck-julia nil
  "flycheck-julia options"
  :prefix "flycheck-julia"
  :group 'flycheck
  :link '(url-link :tag "Github" "https://github.com/gdkrmr/flycheck-julia"))

(defcustom flycheck-julia-executable "julia"
  "The executable used for the julia process."
  :type 'string
  :group 'flycheck-julia)

(defcustom flycheck-julia-port 3423
  "The port used by the julia server."
  :type 'integer
  :group 'flycheck-julia)

;; (defcustom flycheck-julia-max-wait 0.01
;;   "The maximum time to wait for an answer from the server."
;;   :type 'number
;;   :group 'flycheck-julia)

;; This is the variable that is used to receive the data from the server
;; TODO: Find out if this is possible without a global value
(setq flycheck-julia-proc-output "")
(setq flycheck-julia-server-proc nil)

(defun flycheck-julia-server-p ()
  "Check if the Lint server is up, returns the process or nil"
  (processp flycheck-julia-server-proc))

(defun flycheck-julia-server-start ()
  "If not already running, start the Julia server for linting."
  (if (not (flycheck-julia-server-p))
      (setq flycheck-julia-server-proc
            (start-process-shell-command
             "flycheck-julia-server" "*julia-linter*"
             ;; TODO: use pipes or something different than an open port
             ;; TODO: decide how too handle query on exit (set-process-query-on-exit-flag)
             (concat flycheck-julia-executable
                     " -e \'using Lint\; lintserver\("
                     (number-to-string flycheck-julia-port)
                     "\, \"standard-linter-v2\"\)\'")))
    (message "flycheck-julia-server-start: server already running.")))

(defun flycheck-julia-server-stop ()
  "Kill the Julia lint server."
  (interactive)
  (delete-process flycheck-julia-server-proc)
  (setq flycheck-julia-server-proc nil))

(defun flycheck-julia-server-restart ()
  "Kill the Julia lint server and restart it."
  (interactive)
  (flycheck-julia-server-stop)
  (sleep-for 5)
  (flycheck-julia-server-start))

(defun flycheck-julia-start-or-query-server (checker callback)
  "Start a Julia syntax check, start the server if necessary.

CHECKER and CALLBACK are flycheck requirements."

  (when (not (flycheck-julia-server-p)) (flycheck-julia-server-start))
  (flycheck-julia-server-query checker callback))

(defun flycheck-julia-server-query (checker callback)
  "Query a lint.

Query a lint for the current buffer and return the errors as
flycheck objects.

CHECKER is 'julia-linter, this is a flycheck internal."
  (setq flycheck-julia-proc-output "")

  (let* ((filter (lambda (process output)
                   (setq flycheck-julia-proc-output
                         (concat flycheck-julia-proc-output output))))
         ;; This is where the asynchronous magic is supposed to happen:
         ;;
         ;; the returned string can be:
         ;;
         ;; "", i.e the server is not running yet -> not parsed correctly
         ;;
         ;; "[]", there are no errors -> parsed correctly to json
         ;;
         ;; a complete json object -> there are errors/issues in the file,
         ;; everything is fine
         ;;
         ;; an incomplete json object -> the object was not retrieved correctly
         ;;
         ;;Also: this sentinl should only be called if the connection is closed,
         ;; if it gets with a different message, something is wrong
         (sentinel (lambda (process event)
                     (unless (string= event "connection broken by remote peer\n")
                       (message "connection not closed!"))
                     (delete-process process)
                     (if (string= flycheck-julia-proc-output "")
                         (funcall callback 'interrupted)
                       (condition-case nil
                           (funcall callback 'finished
                                    (flycheck-julia-error-parser
                                     (json-read-from-string
                                      flycheck-julia-proc-output)
                                     checker
                                     (current-buffer)))
                         (error (funcall callback 'errored
                                         "there was a parsing error"))))))
         ;; if the server is not running yet, this fails because it cannot
         ;; connect to the server and np will be nil
         (np (ignore-errors (make-network-process :name     "flycheck-julia-client"
                                                  :host     'local
                                                  :service  flycheck-julia-port
                                                  :filter   filter
                                                  :sentinel sentinel)))
         (js (json-encode `(("file"            . ,(if buffer-file-name (buffer-file-name) (buffer-name)))
                            ("code_str"        . ,(buffer-substring-no-properties (point-min) (point-max)))
                            ("ignore_info"     . ,json-false)
                            ("ignore_warnings" . ,json-false)
                            ("show_code"       . t)))))
    ;; return immediately without any errors, leave that to the sentinel
    (if np (process-send-string np js) (funcall callback 'interrupted))))

(defun flycheck-julia-error-parser (errors checker buffer)
  "Parse the error returned from the Julia lint server.

ERRORS is the string returned by the server, it contains a json object.
CHECKER is the julia linter.
BUFFER is the buffer that was checked for errors."

  ;; (message "entered error-parser")
  (mapcar (lambda (it)
            (flycheck-error-new
             :buffer   buffer
             :checker  checker
             :filename (cdr (assoc 'file (cdr (assoc 'location it))))
             ;; Lint.jl returns 0-based line and column numbers
             ;; Lint.jl returns only a line in the format [[l, 0], [l, 80]],
             :line     (1+ (aref (aref (cdr (assoc 'position (cdr (assoc 'location it)))) 0) 0))
             ;; TODO: simply put 0 here?
             :column   (1+ (aref (aref (cdr (assoc 'position (cdr (assoc 'location it)))) 0) 1))
             :message  (cdr (assoc 'excerpt it))
             :level    (intern (cdr (assoc 'severity it)))))
          errors))

(flycheck-define-generic-checker 'julia-linter
  "A source code linter for Julia using Lint.jl."
  :start     #'flycheck-julia-start-or-query-server
  :modes     '(julia-mode ess-julia-mode))

;;;###autoload
(defun flycheck-julia-setup ()
  "Setup Flycheck Julia.

Add `flycheck-julia' to `flycheck-checkers'."
  (interactive)
  (add-to-list 'flycheck-checkers 'julia-linter))

(provide 'flycheck-julia)

;;; flycheck-julia.el ends here
