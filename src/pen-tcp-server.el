;;; echo-server.el --- -*- lexical-binding: t -*-
;;
;; Copyright (C) 2016-2017 York Zhao 

;; Author: York Zhao <gtdplatform@gmail.com>
;; Created: June 1, 2016
;; Version: 0.1
;; Keywords: TCP, Server, Network, Socket
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3 of the License, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Running "M-x tcp-server-start" will prompt user to enter a port number to
;; listen to.
;;
;;; Code:

(require 'cl-lib)

(defvar tcp-server-clients '()
  "Alist where KEY is a client process and VALUE is the string")

(defvar tcp-server-servers '()
  "Alist where KEY is the port number the server is listening at")

(defvar tcp-server-display-buffer-on-update nil
  "If non-nil, force the process buffer to be visible whenever
new text arrives")
(make-variable-buffer-local 'tcp-server-display-buffer-on-update)

(defun tcp-server-make-process-name (port)
  "Return server name of the process listening on PORT"
  (format "tcp-server:%d" port))

(defun tcp-server-get-process (port)
  "Return the server process that is listening on PORT"
  (get-process (tcp-server-make-process-name port)))

(defun tcp-server-process-buffer (port)
  "Return buffer of the server process that is listening on PORT"
  (process-contact (tcp-server-get-process port) :buffer))

(defun tcp-server-delete-clients (server-proc)
  (let ((server-proc-name (process-contact server-proc :name)))
    (cl-loop for client in tcp-server-clients
             if (string= server-proc-name (process-contact client :name))
             do
             (delete-process client)
             (message "Deleted client process %s" client))
    (setq tcp-server-clients
          (cl-delete-if (lambda (client)
                          (string= (process-contact server-proc :name)
                                   (process-contact client :name)))
                        tcp-server-clients))))

(cl-defun tcp-server-start (port &optional (display-buffer-on-update nil)
                                 (buffer-major-mode 'text-mode))
  "Start a TCP server listening at PORT"
  (interactive
   (list (read-number "Enter the port number to listen to: " 9999)))
  (let* ((proc-name (tcp-server-make-process-name port))
         (buffer-name (format "*%s*" proc-name)))
    (unless (process-status proc-name)
      (make-network-process :name proc-name :buffer buffer-name
                            :family 'ipv4 :service port
                            :sentinel 'tcp-server-sentinel
                            :filter 'tcp-server-filter :server 't)
      (with-current-buffer buffer-name
        (funcall buffer-major-mode)
        (setq tcp-server-display-buffer-on-update display-buffer-on-update))
      (setq tcp-server-clients '()))
    ;; (display-buffer buffer-name)
    ))

(defun tcp-server-stop (port)
  "Stop an emacs TCP server at PORT"
  (interactive
   (list (read-number "Enter the port number the server is listening to: "
                      9999)))
  (let ((server-proc (tcp-server-get-process port)))
    (tcp-server-delete-clients server-proc)
    (delete-process server-proc)))

(defun tcp-server-append-to-proc-buffer (proc string)
  (let ((buffer (process-contact proc :buffer))
        (inhibit-read-only t))
    (and buffer (get-buffer buffer)
         (with-current-buffer buffer
           (when tcp-server-display-buffer-on-update
             (display-buffer buffer))
           (let ((moving (= (point) (point-max))))
             (save-excursion
               (goto-char (point-max))
               (insert string)
               )
             (if moving (goto-char (point-max))))))))

(defun tcp-server-filter (proc string)
  (tcp-eval string))

(defun tcp-eval (string)
  (eval (car (read-from-string (format "(progn %s)" string)))))

(defun tcp-server-sentinel (proc msg)
  (cond
   ((string-match "open from .*\n" msg)
    (push proc tcp-server-clients)
    (tcp-server-log proc "client connected\n")
    )
   ((string= msg "connection broken by remote peer\n")
    (setq tcp-server-clients (cl-delete proc tcp-server-clients))
    (tcp-server-log proc "client has quit\n")
    )
   ((eq (process-status proc) 'closed)
    (tcp-server-delete-clients proc))))

(defun tcp-server-log (client string)
  "If a server buffer exists, write STRING to it for logging purposes."
  (tcp-server-append-to-proc-buffer client
                                    (format "%s %s: %s"
                                            (current-time-string)
                                            client string)))


(provide 'pen-tcp-server)

;;; tcp-server.el ends here
