;;; promise.el --- Promises/A+                       -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2017  chuntaro

;; Author: chuntaro <chuntaro@sakura-games.jp>
;; URL: https://github.com/chuntaro/emacs-promise
;; Package-Requires: ((emacs "25.1"))
;; Version: 1.1
;; Keywords: async promise convenience

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

;; The original JavaScript code is:
;;
;; Copyright (c) 2014 Forbes Lindesay
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.

;;; Commentary:

;; This is a simple implementation of Promises/A+.
;;
;; This implementation ported the following Promises/A+ implementation faithfully.
;; https://github.com/then/promise
;;
;; * The same API as JavaScript version Promise can be used.
;;  * then, catch, resolve, reject, all, race, etc...
;; * supports "thenable"
;; * supports "Inheritance of Promise"
;; * supports "rejection-tracking"
;;
;; Usage:
;; See `promise-examples.el' for details.
;;  https://raw.githubusercontent.com/chuntaro/emacs-promise/master/examples/promise-examples.el
;;  You can check the operation while downloading and running it interactively.
;;
;; (require 'promise)
;;
;; ;; Please be sure to enable it when developing.
;; (promise-rejection-tracking-enable '((all-rejections . t)))
;;
;; (defun do-something-async (delay-sec value)
;;   "Return `Promise' to resolve the value asynchronously."
;;   (promise-new (lambda (resolve _reject)
;;                  (run-at-time delay-sec
;;                               nil
;;                               (lambda ()
;;                                 (funcall resolve value))))))
;;
;; (defun example4 ()
;;   "All processes are asynchronous Promise chain."
;;   (promise-chain (do-something-async 1 33)
;;     (then (lambda (result)
;;             (message "first result: %s" result)
;;             (do-something-async 1 (* result 2))))
;;
;;     (then (lambda (second-result)
;;             (message "second result: %s" second-result)
;;             (do-something-async 1 (* second-result 2))))
;;
;;     (then (lambda (third-result)
;;             (message "third result: %s" third-result)))))

;;; Code:

(require 'promise-es6-extensions)
(require 'promise-done)
(require 'promise-finally)
(require 'promise-rejection-tracking)

;;;###autoload
(defmacro promise-chain (promise &rest body)
  "Extract PROMISE, BODY include then, catch, done and finally.

Extract the following code...

    (promise-chain (promise-new ...)
      (then
       (lambda (value)
         ...))

      (catch
       (lambda (reason)
         ...))

      (done
       (lambda (value)
         ...))

      (finally
       (lambda () ...))

      ;; Anaphoric versions of `then' and `catch'.

      (thena (message \"result -> %s\" result)
             ...)

      (catcha (message \"error: reason -> %s\" reason)
              ...))

as below.

    (let ((promise (promise-new ...)))
      (setf promise (promise-then promise
                                  (lambda (value)
                                    ...)))

      (setf promise (promise-catch promise
                                   (lambda (value)
                                     ...)))

      (setf promise (promise-done promise
                                  (lambda (reason)
                                    ...)))

      (setf promise (promise-finally promise
                                     (lambda ()
                                       ...)))

      (setf promise (promise-then promise
                                  (lambda (result)
                                    (message \"result -> %s\" result)
                                    ...)))

      (setf promise (promise-catch promise
                                   (lambda (reason)
                                     (message \"error: reason -> %s\" reason)
                                     ...)))
      promise)"
  (declare (indent 1) (debug t))
  `(let ((promise ,promise))
     ,@(mapcar (lambda (sexp)
                 (let ((fn (car-safe sexp))
                       (args (cdr-safe sexp)))
                   (cl-case fn
                     (promise-new
                      `(setf promise ,sexp))
                     ((promise-then
                       promise-catch
                       promise-done
                       promise-finally)
                      `(setf promise (,fn promise ,@args)))
                     (catch
                      `(setf promise (promise-catch promise ,@args)))
                     (then
                      `(setf promise (promise-then promise ,@args)))
                     (done
                      `(setf promise (promise-done promise ,@args)))
                     (finally
                      `(setf promise (promise-finally promise ,@args)))
                     (thena
                      `(setf promise (promise-then promise (lambda (result) ,@args))))
                     (catcha
                      `(setf promise (promise-catch promise (lambda (reason) ,@args))))
                     (otherwise
                      sexp))))
               body)
     promise))

;;
;; Promise version of various utility functions
;;

(require 'url-http)

(defun promise:run-at-time (time function &rest args)
  "Return promise to funcall FUNCTION with ARGS at specified TIME.

Arguments:
  - TIME can accept the various formats.  See `run-at-time'.
  - FUNCTION is funcalled with ARGS.

Resolve:
  - The return value from funcalled FUNCTION.

Reject:
  - <Never rejected>"
  (declare (indent 1))
  (promise-new
   (lambda (resolve _reject)
     (run-at-time time nil
                  (lambda ()
                    (funcall resolve (apply function args)))))))

(defun promise:delay (time &optional value)
  "Return promise to delay specified TIME.

Arguments:
  - TIME can accept the various formats.  See `run-at-time'.
  - VALUE is return value when resolved this function.

Resolve:
  - VALUE

Reject:
  - <Never rejected>"
  (declare (indent 1))
  (promise-new
   (lambda (resolve _reject)
     (run-at-time time
                  nil
                  (lambda ()
                    (funcall resolve value))))))

(defun promise:time-out (time &optional reason)
  "Return promise to reject after specified TIME with REASON.

Arguments:
  - TIME an accept various format.  See `run-at-time'.
  - REASON is return value when rejected this function.

Resolve:
  - <Never resolved>

Reject:
  - REASON"
  (declare (indent 1))
  (promise-new
   (lambda (_resolve reject)
     (run-at-time time nil
                  (lambda ()
                    (funcall reject reason))))))

(defun promise:make-process (command)
  "Return promise to make new asynchronous COMMAND.

Arguments:
  - COMMAND is program and shell arguments list of string.

See `promise:make-process-with-handler' for Resolve and Reject sections."
  (funcall #'promise:make-process-with-handler command))

(defun promise:make-process-send-buffer (command buf)
  "Return promise to make new asynchronous COMMAND.

Arguments:
  - COMMAND is program and shell arguments list of string.
  - BUF is buffer, a format that can be accepted by `with-current-buffer'.
    `buffer-string' of BUF is sent with EOF after process has been invoked.

See `promise:make-process-with-handler' for Resolve and Reject sections."
  (funcall #'promise:make-process-with-handler
           command
           (lambda (proc)
             (with-current-buffer buf
               (process-send-region proc (point-min) (point-max))
               (process-send-eof proc)))))

(defun promise:make-process-send-string (command string)
  "Return promise to make new asynchronous COMMAND.

Arguments:
  - COMMAND is program and shell arguments list of string.
  - STRING is sent with EOF after process has been invoked.

See `promise:make-process-with-handler' for Resolve and Reject sections."
  (funcall #'promise:make-process-with-handler
           command
           (lambda (proc)
             (process-send-string proc string)
             (process-send-eof proc))))

(defun promise:make-process-with-handler (command &optional handler merge-stderr)
  "Return promise to make new asynchronous COMMAND.

Arguments:
  - COMMAND is program and shell arguments list of string.
  - HANDLER is function, called with process object after program is invoked.
  - MERGE-STDERR is boolean, whether merge stdout and stderr or not.

Resolve:
  - A list like as (stdout stderr) when process finish with exitcode 0.
    stdout and stderr are string.

Reject:
  - A list like as (event stdout stderr) when process doesn't finish exitcode 0.
    event, stdout and stderr are string.
    The event is documented at https://www.gnu.org/software/emacs/manual/html_node/elisp/Sentinels.html"
  (promise-new
   (lambda (resolve reject)
     (let* ((program (car command))
            (stdout (generate-new-buffer (concat "*" program "-stdout*")))
            (stderr (unless merge-stderr
                      (generate-new-buffer (concat "*" program "-stderr*"))))
            (stderr-pipe (unless merge-stderr
                           (make-pipe-process
                            :name (concat "*" program "-stderr-pipe*")
                            :noquery t
                            ;; use :filter instead of :buffer, to get rid of "Process Finished" lines
                            :filter (lambda (_ output)
                                      (with-current-buffer stderr
                                        (insert output))))))
            (cleanup (lambda ()
                       (kill-buffer stdout)
                       (unless merge-stderr
                         (delete-process stderr-pipe)
                         (kill-buffer stderr)))))
       (condition-case err
           (let ((proc (if merge-stderr
                           (make-process :name program :buffer stdout :command command)
                         (make-process :name program :buffer stdout :command command :stderr stderr-pipe))))
             (set-process-sentinel
              proc
              (lambda (_process event)
                (unwind-protect
                    (let ((stdout-str (with-current-buffer stdout
                                        (buffer-string)))
                          (stderr-str (unless merge-stderr
                                        (with-current-buffer stderr
                                          (buffer-string)))))
                      (if (string= event "finished\n")
                          (funcall resolve (list stdout-str stderr-str))
                        (funcall reject (list event stdout-str stderr-str))))
                  (funcall cleanup))))
             (when handler
               (funcall handler proc)))
         (error (funcall cleanup)
                (signal (car err) (cdr err))))))))

(require 'subr-x)
(defun promise:maybe-message (msg)
  "Display MSG if non-blank."
  (let ((m (string-trim-right msg)))
    (when (not (string-empty-p m))
      (message "%s" m))))

(require 'seq)
(defun promise:make-process-string (command)
  "Return promise to make new asynchronous COMMAND.

Arguments:
  - COMMAND is program and shell arguments list of string.

Resolve:
  - Process stdout as string when process finish with exitcode 0.

Reject:
  - Event as string represented process exit state.
    The event is documented at https://www.gnu.org/software/emacs/manual/html_node/elisp/Sentinels.html"
  (promise-then
   (funcall #'promise:make-process command)
   (lambda (res)
     (seq-let (stdout stderr) res
       (promise:maybe-message (propertize stderr 'face '(:foreground "yellow")))
       stdout))
   (lambda (err)
     (seq-let (event stdout stderr) err
       (promise:maybe-message (propertize stdout 'face '(:foreground "black" :background "white")))
       (promise:maybe-message (propertize stderr 'face '(:foreground "red")))
       (promise-reject event)))))

(defun promise:make-shell-command (script &optional dir)
  "Return promise to make new asynchronous shell SCRIPT.

Arguments:
  - SCRIPT is string, will be passed sh -c.
  - DIR is directory path in which SCRIPT will be executed.

See `promise:make-process-string' for Resolve and Reject sections."
  (let ((default-directory (or dir default-directory)))
    (promise:make-process-string (list shell-file-name shell-command-switch script))))

(defun promise:make-thread (function &rest args)
  "Return promise to make new thread via `make-thread'.

Arguments:
  - FUNCTION is funcalled with ARGS in new thread.

Resolve:
  - Return value from funcalled FUNCTION in the thread.

Reject:
  - Error object while running in the thread."
  (promise-new
   (lambda (resolve reject)
     (if (not (fboundp 'make-thread))
         (error "`promise:make-thread' needs `make-thread' attached to Emacs-26.1 or above")
       (make-thread
        (lambda ()
          (condition-case err
              (funcall resolve (apply function args))
            (error (funcall reject err)))))))))

(defun promise:wrap-message (promise)
  "Return promise to show debug message after PROMISE resolved.

Arguments:
  - PROMISE is any promise object.

Resolve:
  - Return original return value when PROMISE resolved.

Reject:
  - Return original return value when PROMISE rejected."
  (promise-new
   (lambda (resolve reject)
     (promise-then
      promise
      (lambda (res)
        (message "%s: %s"
                 (propertize "Result" 'face '(:foreground "green"))
                 (string-trim-right res))
        (funcall resolve res))
      (lambda (err)
        (message "%s: %s"
                 (propertize "Error" 'face '(:foreground "red"))
                 (string-trim-right err))
        (funcall reject err))))))

(defun promise:url-retrieve (url)
  "Return promise to retrieve response body from URL.

Arguments:
  - URL is either a string or a parsed URL.  See `url-retrieve'.

Resolve:
  - Response body as a string retrieved from the URL.

Reject:
  - Error object while retrieving URL."
  (promise-new
   (lambda (resolve reject)
     (url-retrieve url
                   (lambda (status)
                     ;; All errors are reliably captured and rejected with appropriate values.
                     (if (plist-get status :error)
                         (funcall reject (plist-get status :error))
                       (condition-case err
                           (if (not (url-http-parse-headers))
                               (funcall reject (buffer-string))
                             (search-forward-regexp "\n\\s-*\n" nil t)
                             (funcall resolve (buffer-substring (point) (point-max))))
                         (error (funcall reject err)))))))))

(require 'xml)                          ; for `xml-parse-region'

(defun promise:xml-retrieve (url)
  "Return promise to retrieve XML object parsed from contents from URL.

Arguments:
  - URL is either a string or a parsed URL.  See `url-retrieve'.

Resolve:
  - XML object parsed by `xml-parse-region'.

Reject:
  - Error object while retrieving URL and parsing contents."
  (promise-new
   (lambda (resolve reject)
     (url-retrieve url
                   (lambda (status)
                     ;; All errors are reliably captured and rejected with appropriate values.
                     (if (plist-get status :error)
                         (funcall reject (plist-get status :error))
                       (condition-case err
                           (if (not (url-http-parse-headers))
                               (funcall reject (buffer-string))
                             (search-forward-regexp "\n\\s-*\n" nil t)
                             (funcall resolve (xml-parse-region)))
                         (error (funcall reject err)))))))))

(defun promise:request (url)
  "Return promise to request URL via `request'.

Arguments:
  - URL is a target url as string.

Resolve:
  - Response body as string.

Reject:
  - A string list like as (status-code response-header response-body)"
  (promise:request-with-args url nil))

(defun promise:request-post (url data)
  "Return promise to POST DATA to URL via `request'.

Arguments:
  - URL is a target url as string.
  - DATA is post data alist.

Resolve:
  - Response body as string.

Reject:
  - A string list like as (status-code response-header response-body)"
  (declare (indent 1))
  (promise:request-with-args url `(:type "POST" :data ',data)))

(declare-function request "request.el" (url &rest settings))
(declare-function request-response-status-code "request.el" (response))
(declare-function request-response--raw-header "request.el" (response))
(declare-function request-response-data "request.el" (response))

(defun promise:request-with-args (url arglist)
  "Return promise to request URL via `request' with ARGLIST.

Arguments:
  - URL is a target url as string.

Resolve:
  - Response body as string.

Reject:
  - A string list like as (status-code response-header response-body)"
  (declare (indent 1))

  (require 'request)
  (promise-new
   (lambda (resolve reject)
     (when (plist-get arglist :success)
       (funcall reject "Success callback function is not customizable"))
     (when (plist-get arglist :error)
       (funcall reject "Error callback function is not customizable"))
     (apply #'request url
            :success (cl-function
                      (lambda (&key data &allow-other-keys)
                        (funcall resolve data)))
            :error (cl-function
                    (lambda (&key response &allow-other-keys)
                      (funcall reject
                               (list (request-response-status-code response)
                                     (request-response--raw-header response)
                                     (request-response-data response)))))
            arglist))))

(declare-function async-start "async.el" (start-func &optional finish-func))
(declare-function async-when-done "async.el" (proc &optional _change))

(defun promise:async-start (start-func &optional finish-func)
  "Return promise to eval function in a new Emacs process via `async-start'.

Arguments:
  - START-FUNC is function that will be evaled in new Emacs.
  - FINISH-FUNC is function that will be evaled after START-FUNC evaled.

Resolve:
  - Return value from START-FUNC in the Emacs.

Reject:
  - Error object while evaluating START-FUNC and FINISH-FUNC."
  (require 'async)
  (promise-new
   (lambda (resolve reject)
     (set-process-sentinel (async-start start-func
                                        (lambda (result)
                                          (when finish-func
                                            (funcall finish-func result))
                                          (funcall resolve result)))
                           (lambda (process event)
                             (condition-case reason
                                 (async-when-done process event)
                               (error (funcall reject reason))))))))

(defun promise-wait (timeout promise)
  "Return promise to wait synchronously until PROMISE is resolved or rejected or TIMEOUT.

Arguments:
  - TIMEOUT can accept the various formats.  See `run-at-time'.
  - PROMISE is any promise object.

Resolve:
  - Return (:fullfilled value), value is PROMISE resolved value.

Reject:
  - Return (:rejected reason), reason is PROMISE rejected reason.

Timeout:
  - Return (:timeouted)."
  (declare (indent 1))
  (catch 'done
    (let* (handled
           (timer (run-at-time timeout nil
                               (lambda ()
                                 (unless handled
                                   (setq handled t)
                                   (throw 'done (promise-reject '(:timeouted))))))))
      (promise-then promise
                    (lambda (value)
                      (unless handled
                        (setq handled t)
                        (cancel-timer timer)
                        (throw 'done (promise-resolve `(:fullfilled ,value)))))
                    (lambda (reason)
                      (unless handled
                        (setq handled t)
                        (cancel-timer timer)
                        (throw 'done (promise-reject `(:rejected ,reason))))))
      (while t (accept-process-output)))))

(defun promise-wait-value (promise)
  "Return orignal value form PROMISE return value of `promise-wait'."
  (seq-let (state value) (promise-_value promise)
    (cond
     ((eq :fullfilled state) value)
     ((eq :rejected  state) (error "Rejected: %s" (prin1-to-string value)))
     ((eq :timeouted state) (error "Timeouted: %s" (prin1-to-string value))))))

(defun promise-concurrent--internal (concurrent limit promisefn &optional no-reject-immediately-p)
  "Internal function of `promise-concurrent'.

Arguments:
  - CONCURRENT is limited number of concurrent promises.
  - LIMIT is number of PROMISEFN executions.
  - PROMISEFN is function should return any promise object.
  - If NO-REJECT-IMMEDIATELY-P is non-nil, returned promise is not reject immidiately."
  (declare (indent 2))
  (let ((pipeline (make-vector concurrent nil))
        (results (make-vector limit nil))
        (count -1)
        reasons)
    (dotimes (i concurrent)
      (aset pipeline i
            (promise-new
             (lambda (resolve reject)
               (cl-labels
                ((worker (inx)
                         (if (not (< inx limit))
                             (funcall resolve)
                           (promise-chain (funcall promisefn inx)
                             (then (lambda (res)
                                     (aset results inx res)
                                     (worker (cl-incf count))))
                             (catch (lambda (reason)
                                      (if (not no-reject-immediately-p)
                                          (funcall reject reason)
                                        (push `(,inx ,reason) reasons)
                                        (worker (cl-incf count)))))))))
                (worker (cl-incf count)))))))
    (promise-chain (promise-all pipeline)
      (then (lambda (_)
              (if (not reasons)
                  results
                (promise-reject `(,results ,reasons))))))))

(defun promise-concurrent (concurrent limit promisefn)
  "Return promise to run a limited number of concurrent promises.

This function returns promise which immediately rejected if one
of promises fails.  This behavior corresponds to `promise-all'.
See `promise-concurrent-no-reject-immidiately' with no reject immidiately.

Arguments:
  - CONCURRENT is limited number of concurrent promises.
  - LIMIT is number of PROMISEFN executions.
  - PROMISEFN is function should return any promise object.

Resolve:
  - Return vector includes values resolved for promise with respect to order.

Reject:
  - Return reason for the first rejection."
  (declare (indent 2))
  (funcall #'promise-concurrent--internal concurrent limit promisefn))

(defun promise-concurrent-no-reject-immidiately (concurrent limit promisefn)
  "Return promise to run a limited number of concurrent promises.

This function returns promise which execute the whole promises if
a promise fails.  If all promises are fulfilled, only vectors
with resolved values are returned.  If one of promise is
rejected, the whole promises are executed and the index and
reason rejected as the second return value is returned after the
whole state has been determined.  In this case, the index location
of the first return value is nil.
See `promise-concurrent' with reject immidiately.

Arguments:
  - CONCURRENT is limited number of concurrent promises.
  - LIMIT is number of PROMISEFN executions.
  - PROMISEFN is function should return any promise object.

Resolve:
  - Return vector includes values resolved for promise with respect to order.

Reject:
  - Return (<vector> <list>)
      <vector> includes values resolved for promise with respect to order.
      <list> is list of (index reason)."
  (declare (indent 2))
  (funcall #'promise-concurrent--internal concurrent limit promisefn :no-reject-immediately))

(provide 'promise)
;;; promise.el ends here
