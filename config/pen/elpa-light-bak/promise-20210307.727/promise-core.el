;;; promise-core.el --- This is a simple implementation of Promises/A+.  -*- lexical-binding: t; -*-

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

;; This implementation ported the following Promises/A+ implementation faithfully.
;; https://github.com/then/promise/blob/master/src/core.js
;;
;; This file contains the core Promises/A+ API.
;; (promise-new fn) or (make-instance 'promise-class :fn fn)
;; (promise-then ((this promise-class) &optional on-fulfilled on-rejected))

;;; Code:

(require 'eieio)
(require 'cl-lib)
(eval-when-compile (require 'subr-x))

(defun promise--asap (task)
  (run-at-time 0.001 nil task))

(defun promise--type-of (obj)
  (cond
   ((not (vectorp obj))
    (type-of obj))
   ((cl-struct-p obj)
    ;; Code copied from `cl--describe-class'.
    (cl--class-name (symbol-value (aref obj 0))))
   ((eieio-object-p obj)
    (eieio-object-class obj))
   (t
    'vector)))

(defun promise--is-object (obj)
  (or (cl-struct-p obj)
      (eieio-object-p obj)))

(defsubst promise--find-then-method (obj)
  (cl-find-method #'promise-then '() (list (promise--type-of obj))))

(defun promise--find-then-function (obj)
  (when-let (method (promise--find-then-method obj))
    (cl--generic-method-function method)))

;; States:
;;
;; 0 - pending
;; 1 - fulfilled with _value
;; 2 - rejected with _value
;; 3 - adopted the state of another promise, _value
;;
;; once the state is no longer pending (0) it is immutable

;; to avoid using condition-case inside critical functions, we
;; extract them to here.
(defvar promise--last-error nil)
(defconst promise--is-error (cl-gensym "promise-error"))
(defun promise--get-then (obj)
  (condition-case ex
      (promise--find-then-function obj)
    (error (setf promise--last-error ex)
           promise--is-error)))

(defun promise--try-call-one (fn a)
  (condition-case ex
      (funcall fn a)
    (error (setf promise--last-error ex)
           promise--is-error)))

(defun promise--try-call-two (fn a b)
  (condition-case ex
      (funcall fn a b)
    (error (setf promise--last-error ex)
           promise--is-error)))

(defclass promise-class ()
  ((_deferred-state :accessor promise-_deferred-state :initform 0)
   (_state          :accessor promise-_state          :initform 0)
   (_value          :accessor promise-_value          :initform nil)
   (_deferreds      :accessor promise-_deferreds      :initform nil)
   ;; for rejection-tracking
   (_rejection-id   :accessor promise-_rejection-id   :initform nil)))
(defvar promise--on-handle nil)
(defvar promise--on-reject nil)

(cl-defmethod initialize-instance ((this promise-class) &optional args)
  (cl-call-next-method this)
  (let ((fn (plist-get args :fn)))
    (unless (eq fn #'ignore)
      (promise--do-resolve fn this))))

(defun promise-new (fn)
  (make-instance 'promise-class :fn fn))

(cl-defmethod promise-then ((this promise-class) &optional on-fulfilled on-rejected)
  (if (not (eq (promise--type-of this) 'promise-class))
      (promise--safe-then this on-fulfilled on-rejected)
    (let ((res (promise-new #'ignore)))
      (promise--handle this
                       (promise--handler-new on-fulfilled
                                             on-rejected
                                             res))
      res)))

(defun promise--safe-then (self on-fulfilled on-rejected)
  (make-instance (promise--type-of self)
                 :fn (lambda (resolve reject)
                       (let ((res (promise-new #'ignore)))
                         (promise-then res resolve reject)
                         (promise--handle self
                                          (promise--handler-new on-fulfilled
                                                                on-rejected
                                                                res))))))

(defun promise--handle (self deferred)
  (while (= (promise-_state self) 3)
    (setf self (promise-_value self)))
  (when promise--on-handle
    (funcall promise--on-handle self))
  (if (= (promise-_state self) 0)
      (cond
       ((= (promise-_deferred-state self) 0)
        (setf (promise-_deferred-state self) 1
              (promise-_deferreds self) deferred))
       ((= (promise-_deferred-state self) 1)
        (setf (promise-_deferred-state self) 2
              (promise-_deferreds self) (list (promise-_deferreds self)
                                              deferred)))
       (t
        (setf (promise-_deferreds self) (nconc (promise-_deferreds self)
                                               (list deferred)))))
    (promise--handle-resolved self deferred)))

(defun promise--handle-resolved (self deferred)
  (promise--asap
   (lambda ()
     (let-alist deferred
       (let ((cb (if (= (promise-_state self) 1) .on-fulfilled .on-rejected)))
         (if (not cb)
             (if (= (promise-_state self) 1)
                 (promise--resolve .promise (promise-_value self))
               (promise--reject .promise (promise-_value self)))
           (let ((ret (promise--try-call-one cb (promise-_value self))))
             (if (eq ret promise--is-error)
                 (promise--reject .promise promise--last-error)
               (promise--resolve .promise ret)))))))))

(defun promise--resolve (self new-value)
  "Promise Resolution Procedure.
See: https://github.com/promises-aplus/promises-spec#the-promise-resolution-procedure"
  (cl-block nil
    (when (eq new-value self)
      (cl-return (promise--reject
                  self
                  '(wrong-type-argument
                    "A promise cannot be resolved with itself."))))
    (when (and new-value
               (promise--is-object new-value))
      (let ((then (promise--get-then new-value)))
        (when (eq then promise--is-error)
          (cl-return (promise--reject self promise--last-error)))
        (cond
         ((and (eq then (ignore-errors (promise--find-then-function self)))
               (promise-class-p new-value))
          (setf (promise-_state self) 3
                (promise-_value self) new-value)
          (promise--finale self)
          (cl-return))
         ((functionp then)
          (promise--do-resolve (lambda (resolve reject)
                                 (promise-then new-value resolve reject))
                               self)
          (cl-return)))))
    (setf (promise-_state self) 1
          (promise-_value self) new-value)
    (promise--finale self)))

(defun promise--reject (self new-value)
  (setf (promise-_state self) 2
        (promise-_value self) new-value)
  (when promise--on-reject
    (funcall promise--on-reject self new-value))
  (promise--finale self))

(defun promise--finale (self)
  (when (= (promise-_deferred-state self) 1)
    (promise--handle self (promise-_deferreds self))
    (setf (promise-_deferreds self) nil))
  (when (= (promise-_deferred-state self) 2)
    (dolist (deferred (promise-_deferreds self))
      (promise--handle self deferred))
    (setf (promise-_deferreds self) nil))
  nil)

(defun promise--handler-new (on-fulfilled on-rejected promise)
  `((on-fulfilled . ,(and (functionp on-fulfilled) on-fulfilled))
    (on-rejected . ,(and (functionp on-rejected) on-rejected))
    (promise . ,promise)))

;; Take a potentially misbehaving resolver function and make sure
;; onFulfilled and onRejected are only called once.
;;
;; Makes no guarantees about asynchrony.
(defun promise--do-resolve (fn promise)
  (let* ((done nil)
         (res (promise--try-call-two
               fn
               (lambda (&optional value)
                 (unless done
                   (setf done t)
                   (promise--resolve promise value)))
               (lambda (&optional reason)
                 (unless done
                   (setf done t)
                   (promise--reject promise reason))))))
    (when (and (not done)
               (eq res promise--is-error))
      (setf done t)
      (promise--reject promise promise--last-error))))

(provide 'promise-core)
;;; promise-core.el ends here
