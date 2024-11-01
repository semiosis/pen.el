;;; promise-rejection-tracking.el --- Porting rejection-tracking.js  -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2017  chuntaro

;; Author: chuntaro <chuntaro@sakura-games.jp>
;; URL: https://github.com/chuntaro/emacs-promise
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

;; This implementation ported the following implementation faithfully.
;; https://github.com/then/promise/blob/master/src/rejection-tracking.js

;; TODO: Display easy-to-read backtrace

;;; Code:

(require 'promise-core)

(defun promise--warn (message &rest args)
  (display-warning 'promise (apply #'format-message message args)))

(defvar promise--default-whitelist '(void-function
                                     void-variable
                                     wrong-type-argument
                                     args-out-of-range))

(defvar promise--enabled nil)

(defun promise-rejection-tracking-disable ()
  (setf promise--enabled nil
        promise--on-handle nil
        promise--on-reject nil))

(defun promise-rejection-tracking-enable (&optional options)
  (when promise--enabled (promise-rejection-tracking-disable))
  (setf promise--enabled t)
  (let ((id -1)
        (display-id -1)
        (rejections (make-hash-table)))
    (cl-flet*
        ((rejections (id symbol) (alist-get symbol (gethash id rejections)))
         (rejections-set (id symbol value)
                         (setf (alist-get symbol (gethash id rejections))
                               value))
         (options (sym) (alist-get sym options))

         (on-unhandled (id)
                       (when (or (options 'all-rejections)
                                 (promise--match-whitelist
                                  (rejections id 'error)
                                  (or (options 'whitelist)
                                      promise--default-whitelist)))
                         (rejections-set id 'display-id (cl-incf display-id))
                         (cond
                          ((options 'on-unhandled)
                           (rejections-set id 'logged t)
                           (funcall (options 'on-unhandled)
                                    (rejections id 'display-id)
                                    (rejections id 'error)))
                          (t
                           (rejections-set id 'logged t)
                           (promise--log-error (rejections id 'display-id)
                                               (rejections id 'error))))))
         (on-handled (id)
                     (when (rejections id 'logged)
                       (cond
                        ((options 'on-handled)
                         (funcall (options 'on-handled)
                                  (rejections id 'display-id)
                                  (rejections id 'error)))
                        ((not (rejections id 'on-unhandled))
                         (promise--warn "Promise Rejection Handled (id:%d):"
                                        (rejections id 'display-id))
                         (promise--warn "  This means you can ignore any previous messages of the form \"Possible Unhandled Promise Rejection\" with id %d."
                                        (rejections id 'display-id)))))))
      (setf promise--on-handle
            (lambda (promise)
              (when (and (= (promise-_state promise) 2) ; IS REJECTED
                         (gethash (promise-_rejection-id promise) rejections))
                (if (rejections (promise-_rejection-id promise) 'logged)
                    (on-handled (promise-_rejection-id promise))
                  (cancel-timer (rejections (promise-_rejection-id promise) 'timeout)))
                (remhash (promise-_rejection-id promise) rejections)))
            promise--on-reject
            (lambda (promise err)
              (when (zerop (promise-_deferred-state promise)) ; not yet handled
                (setf (promise-_rejection-id promise) (cl-incf id))
                (puthash (promise-_rejection-id promise)
                         `((display-id . nil)
                           (error . ,err)
                           (timeout . ,(run-at-time
                                        (if (promise--match-whitelist
                                             err promise--default-whitelist)
                                            0.1
                                          2)
                                        nil
                                        (lambda ()
                                          (on-unhandled (promise-_rejection-id promise)))))
                           (logged . nil))
                         rejections)))))))

(defun promise--log-error (id error)
  (promise--warn "Possible Unhandled Promise Rejection (id:%d):" id)
  (display-warning 'promise (prin1-to-string error)))

(defun promise--match-whitelist (error list)
  (cl-some (lambda (cls)
             (eq (or (and (consp error)
                          (car error))
                     error)
                 cls))
           list))

(provide 'promise-rejection-tracking)
;;; promise-rejection-tracking.el ends here
