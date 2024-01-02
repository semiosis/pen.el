(define-derived-mode client-menu-mode process-menu-mode "Client Menu"
  "Major mode for listing the currently connected client processes."
  (remove-hook 'tabulated-list-revert-hook #'list-processes--refresh t)
  (add-hook 'tabulated-list-revert-hook #'server-list-clients--refresh nil t))

(defun server-list-clients (&optional query-only buffer)
  "Display a list of all clients of this emacs session.
If optional argument QUERY-ONLY is non-nil, only processes with
the query-on-exit flag set are listed.
Any process listed as exited or signaled is actually eliminated
after the listing is made.
Optional argument BUFFER specifies a buffer to use, instead of
\"*Client List*\".
The return value is always nil."
  (interactive)
  (or (fboundp 'process-list)
      (error "Asynchronous subprocesses are not supported on this system"))
  (unless (bufferp buffer)
    (setq buffer (get-buffer-create "*Client Process List*")))
  (with-current-buffer buffer
    (client-menu-mode)
    (setq process-menu-query-only query-only)
    (server-list-clients--refresh)
    (tabulated-list-print))
  (display-buffer buffer)
  nil)

(defalias #'list-clients #'server-list-clients)

(defun server-client-buffer (client)
  "Return buffer with client in `server-buffer-clients'."
  (catch :found
    (dolist (buf (buffer-list))
      (if (memq client (with-current-buffer buf server-buffer-clients))
          (throw :found buf)))))

(defun server-list-clients--refresh ()
  "Recompute the list of client processes for the Client List buffer.
Also, delete any process that is exited or signaled."
  (setq tabulated-list-entries nil)
  (dolist (p server-clients)
    (cond ((memq (process-status p) '(exit signal closed))
       (delete-process p))
      ((or (not process-menu-query-only)
           (process-query-on-exit-flag p))
       (let* ((buf (server-client-buffer p))
          (type (process-type p))
          (name (process-name p))
          (status (symbol-name (process-status p)))
          (buf-label (if (buffer-live-p buf)
                 `(,(buffer-name buf)
                   face link
                   help-echo ,(format-message
                           "Visit buffer `%s'"
                           (buffer-name buf))
                   follow-link t
                   process-buffer ,buf
                   action process-menu-visit-buffer)
                   "--"))
          (tty (or (process-tty-name p) "--"))
          (cmd
           (if (memq type '(network serial))
               (let ((contact (process-contact p t)))
             (if (eq type 'network)
                 (format "(%s %s)"
                     (if (plist-get contact :type)
                     "datagram"
                       "network")
                     (if (plist-get contact :server)
                     (format "server on %s"
                         (or
                          (plist-get contact :host)
                          (plist-get contact :local)))
                       (format "connection to %s"
                           (plist-get contact :host))))
               (format "(serial port %s%s)"
                   (or (plist-get contact :port) "?")
                   (let ((speed (plist-get contact :speed)))
                     (if speed
                     (format " at %s b/s" speed)
                       "")))))
             (mapconcat 'identity (process-command p) " "))))
         (push (list p (vector name status buf-label tty cmd))
               tabulated-list-entries))))))

(provide 'pen-clients)
