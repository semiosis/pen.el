;;; geiser-connection.el -- talking to a scheme process

;; Copyright (C) 2009, 2010, 2011, 2013, 2021 Jose Antonio Ortega Ruiz

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the Modified BSD License. You should
;; have received a copy of the license along with this program. If
;; not, see <http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5>.

;; Start date: Sat Feb 07, 2009 21:11

;;; Commentary:

;; Connection datatype and functions for managing request queues
;; between emacs and inferior guile processes.


;;; Code:

(require 'geiser-log)
(require 'geiser-syntax)
(require 'geiser-base)
(require 'geiser-impl)

(require 'tq)


;;; Buffer connections:

(defvar-local geiser-con--connection nil)

(defun geiser-con--get-connection (buffer/proc)
  (if (processp buffer/proc)
      (geiser-con--get-connection (process-buffer buffer/proc))
    (with-current-buffer buffer/proc geiser-con--connection)))


;;; Request datatype:

(defun geiser-con--make-request (con str cont &optional sender-buffer)
  (list (cons :id (geiser-con--connection-inc-count con))
        (cons :string str)
        (cons :continuation cont)
        (cons :buffer (or sender-buffer (current-buffer)))
        (cons :connection con)))

(defsubst geiser-con--request-id (req)
  (cdr (assq :id req)))

(defsubst geiser-con--request-string (req)
  (cdr (assq :string req)))

(defsubst geiser-con--request-continuation (req)
  (cdr (assq :continuation req)))

(defsubst geiser-con--request-buffer (req)
  (cdr (assq :buffer req)))

(defsubst geiser-con--request-connection (req)
  (cdr (assq :connection req)))

(defsubst geiser-con--request-deactivate (req)
  (setcdr (assq :continuation req) nil))

(defsubst geiser-con--request-deactivated-p (req)
  (null (cdr (assq :continuation req))))


;;; Connection datatype:

(defun geiser-con--tq-create (process)
  (let ((tq (tq-create process)))
    (set-process-filter process
                        `(lambda (p s) (geiser-con--tq-filter ',tq s)))
    tq))

(defun geiser-con--tq-filter (tq in)
  (when (buffer-live-p (tq-buffer tq))
    (with-current-buffer (tq-buffer tq)
      (if (tq-queue-empty tq)
          (progn (geiser-log--error "Unexpected queue input:\n %s" in)
                 (delete-region (point-min) (point-max)))
        (goto-char (point-max))
        (insert in)
        (goto-char (point-min))
        (when (re-search-forward (tq-queue-head-regexp tq) nil t)
          (unwind-protect
              (funcall (tq-queue-head-fn tq)
                       (tq-queue-head-closure tq)
                       (buffer-substring (point-min) (point)))
            (delete-region (point-min) (point-max))
            (tq-queue-pop tq)))))))

(defun geiser-con--combined-prompt (prompt debug)
  (if debug (format "\\(%s\\)\\|\\(%s\\)" prompt debug) prompt))

(defun geiser-con--connection-eot-re (prompt debug)
  (geiser-con--combined-prompt (format "\n\\(%s\\)" prompt)
                               (and debug (format "\n\\(%s\\)" debug))))

(defun geiser-con--make-connection (proc prompt debug-prompt)
  (list t
        (cons :filter (process-filter proc))
        (cons :tq (geiser-con--tq-create proc))
        (cons :tq-filter (process-filter proc))
        (cons :eot (geiser-con--connection-eot-re prompt debug-prompt))
        (cons :prompt prompt)
        (cons :debug-prompt debug-prompt)
        (cons :is-debugging nil)
        (cons :count 0)
        (cons :completed (make-hash-table :weakness 'value))))

(defsubst geiser-con--connection-process (c)
  (tq-process (cdr (assq :tq c))))

(defsubst geiser-con--connection-filter (c)
  (cdr (assq :filter c)))

(defsubst geiser-con--connection-tq-filter (c)
  (cdr (assq :tq-filter c)))

(defsubst geiser-con--connection-tq (c)
  (cdr (assq :tq c)))

(defsubst geiser-con--connection-eot (c)
  (cdr (assq :eot c)))

(defsubst geiser-con--connection-prompt (c)
  (cdr (assq :prompt c)))

(defsubst geiser-con--connection-debug-prompt (c)
  (cdr (assq :debug-prompt c)))

(defsubst geiser-con--connection-is-debugging (c)
  (cdr (assq :is-debugging c)))

(defsubst geiser-con--connection-set-debugging (c d)
  (setcdr (assq :is-debugging c) d))

(defun geiser-con--connection-update-debugging (c txt)
  (let* ((dp (geiser-con--connection-debug-prompt c))
         (is-d (and (stringp dp) (string-match dp txt))))
    (geiser-con--connection-set-debugging c is-d)
    is-d))

(defsubst geiser-con--connection-completed (c r)
  (geiser-con--request-deactivate r)
  (puthash (geiser-con--request-id r) r (cdr (assoc :completed c))))

(defsubst geiser-con--connection-completed-p (c id)
  (gethash id (cdr (assoc :completed c))))

(defun geiser-con--connection-inc-count (c)
  (let* ((cnt (assoc :count c))
         (new (1+ (cdr cnt))))
    (setcdr cnt new)
    new))

(defun geiser-con--has-entered-debugger (con answer)
  (when-let ((p (car (last (split-string answer "\n" t)))))
    (geiser-con--connection-update-debugging con p))
  (geiser-con--connection-is-debugging con))

(defun geiser-con--connection-eot-p (con txt)
  (and txt
       (string-match-p (geiser-con--connection-eot con) txt)))

(defun geiser-con--connection-close (con)
  (let ((tq (geiser-con--connection-tq con)))
    (and tq (tq-close tq))))

(defvar geiser-con--startup-prompt nil)
(defun geiser-con--startup-prompt (p s)
  (setq geiser-con--startup-prompt
        (concat geiser-con--startup-prompt s))
  nil)

(defun geiser-con--connection-deactivate (c &optional no-wait)
  (when (car c)
    (let* ((tq (geiser-con--connection-tq c))
           (proc (geiser-con--connection-process c))
           (proc-filter (geiser-con--connection-filter c)))
      (unless no-wait
        (while (and (not (tq-queue-empty tq))
                    (accept-process-output proc 0.1))))
      (set-process-filter proc proc-filter)
      (setcar c nil))))

(defun geiser-con--connection-activate (c)
  (when (not (car c))
    (let* ((tq (geiser-con--connection-tq c))
           (proc (geiser-con--connection-process c))
           (tq-filter (geiser-con--connection-tq-filter c)))
      (while (accept-process-output proc 0.01))
      (set-process-filter proc tq-filter)
      (setcar c t))))


;;; Requests handling:

(defun geiser-con--req-form (req answer)
  (let* ((con (geiser-con--request-connection req))
         (debugging (geiser-con--has-entered-debugger con answer)))
    (condition-case err
        (let ((start (string-match "((\\(?:result)?\\|error\\) " answer)))
          (or (and start (car (read-from-string answer start)))
              `((error (key . retort-syntax))
                (output . ,answer)
                (debug . ,debugging))))
      (error `((error (key . geiser-con-error))
               (debug . debugging)
               (output . ,(format "%s\n(%s)"
                                  answer (error-message-string err))))))))

(defun geiser-con--process-completed-request (req answer)
  (let ((cont (geiser-con--request-continuation req))
        (id (geiser-con--request-id req))
        (rstr (geiser-con--request-string req))
        (form (geiser-con--req-form req answer))
        (buffer (or (geiser-con--request-buffer req) (current-buffer)))
        (con (geiser-con--request-connection req)))
    (if (not cont)
        (geiser-log--warn "<%s> Dropping result for request %S: %s"
                          id rstr form)
      (condition-case cerr
          (with-current-buffer buffer
            (funcall cont form)
            (geiser-log--info "<%s>: processed" id))
        (error (geiser-log--error
                "<%s>: continuation failed %S \n\t%s" id rstr cerr))))
    (geiser-con--connection-completed con req)))

(defun geiser-con--connection-add-request (c r)
  (let ((rstr (geiser-con--request-string r)))
    (geiser-log--info "REQUEST: <%s>: %s"
                      (geiser-con--request-id r)
                      rstr)
    (geiser-con--connection-activate c)
    (tq-enqueue (geiser-con--connection-tq c)
                (concat rstr "\n")
                (geiser-con--connection-eot c)
                r
                'geiser-con--process-completed-request
                t)))


;;; Message sending interface:

(defun geiser-con--send-string (con str cont &optional sbuf)
  (let ((req (geiser-con--make-request con str cont sbuf)))
    (geiser-con--connection-add-request con req)
    req))

(defvar geiser-connection-timeout 30000
  "Time limit, in msecs, blocking on synchronous evaluation requests")

(defun geiser-con--interrupt (con)
  "Interrupt any request being currently in process."
  (when-let (proc (and con (geiser-con--connection-process con)))
    (when (process-live-p proc)
      (interrupt-process proc))))

(defun geiser-con--wait (req timeout)
  "Wait for the given request REQ to finish, up to TIMEOUT msecs, returning its result."
  (let* ((con (or (geiser-con--request-connection req)
                  (error "Geiser connection not active")))
         (proc (geiser-con--connection-process con))
         (id (geiser-con--request-id req))
         (timeout (/ (or timeout geiser-connection-timeout) 1000.0))
         (step (/ timeout 10)))
    (with-timeout (timeout (geiser-con--request-deactivate req))
      (condition-case e
          (while (and (geiser-con--connection-process con)
                      (not (geiser-con--connection-completed-p con id)))
            (accept-process-output proc step))
        (error (geiser-con--request-deactivate req))))))

(defun geiser-con--send-string/wait (con str cont &optional timeout sbuf)
  (save-current-buffer
    (let ((proc (and con (geiser-con--connection-process con))))
      (unless proc (error "Geiser connection not active"))
      (let ((req (geiser-con--send-string con str cont sbuf)))
        (geiser-con--wait req timeout)))))


(provide 'geiser-connection)
