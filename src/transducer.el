;;; transducer.el --- Transducer implementation for elisp  -*- lexical-binding: t; -*-
;;
;; Filename: transducer.el
;; Description: Transducer implemntation for elisp
;; Author: Francis Murillo
;; Maintainer: Francis Murillo
;; Created: Thu Sep  8 19:36:33 2016 (+0800)
;; Version: 0.1.0
;; Package-Requires: ()
;; Last-Updated:
;;           By:
;;     Update #: 0
;; URL:
;; Doc URL:
;; Keywords:
;; Compatibility:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code `':

(eval-when-compile (require 'cl))

;;* Core
(defun transducer-reducer (initial-fn complete-fn step-fn)
  "Create a reducer with an initial seed function INITIAL-FN,
a final function COMPLETE-FN, and a step function STEP-FN."
  (λ (&rest args)
    (let ((arity (length args)))
      (pcase arity
        (0 (funcall initial-fn))
        (1 (apply complete-fn args))
        (2 (apply step-fn args))))))

(defun transducer-wrapped-reducer (initial-fn complete-fn step-fn)
  "Just a wrapper over `transducer-reducer' so that the closure
can be removed with INITIAL-FN, COMPLETE-FN and STEP-FN."
  (λ (reducer)
    (transducer-reducer
     (λ () (funcall initial-fn reducer))
     (λ (result) (funcall complete-fn reducer result))
     (λ (result item) (funcall step-fn reducer result item)))))

(defun transducer-step-reducer (step-fn)
  "Return a reducer with just mainly a STEP-FN and a default
INITIAL-FN and COMPLETE-FN."
  (transducer-wrapped-reducer
   (λ (reducer) (funcall reducer))
   (λ (reducer result) (funcall reducer result))
   (λ (reducer result item) (funcall step-fn reducer result item))))


(defun transducer-list-reducer ()
  "A reducer for lists."
  (transducer-reducer
   (λ () (list))
   (λ (result) result)
   (λ (result item) (append result (list item)))))


(defun transducer-plist-reducer ()
  "A reducer for plists."
  (transducer-reducer
   (λ () (list))
   (λ (result) result)
   (λ (result item)
     (let ((key (car item))
         (value (cdr item)))
       (plist-put result key value)))))


;;* Api
(defun transducer-identity ()
  "An identity reducer."
  (transducer-step-reducer
   (λ (reducer result item) (funcall reducer result item))))

(defun transducer-map (mapper)
  "Map reducer with MAPPER function."
  (transducer-step-reducer
   (λ (reducer result item) (funcall reducer result (funcall mapper item)))))

(defun transducer-map-indexed (mapper)
  "Map reducer with MAPPER function with index and item as arguments."
  (lexical-let ((count 0))
    (transducer-map
     (λ (item)
       (prog1
           (funcall mapper count item)
         (setq count (1+ count)))))))

(defun transducer-filter (filterer)
  "Filter reducer with FILTERER predicate."
  (transducer-step-reducer
   (λ (reducer result item)
     (if (funcall filterer item)
         (funcall reducer result item)
       result))))

(defun transducer-composes (&rest reducers)
  "Compose transducers REDUCERS.
The order is left to right instead of the standard right to left
due to the implementation of transducers in general."
  (λ (reducer)
    (cl-reduce
     (λ ( accumulated-reducer new-reducer)
       (funcall new-reducer accumulated-reducer))
     (reverse reducers)
     :initial-value
     reducer)))


(defun transducer-distinct ()
  "Distinct reducer with EQUALITY predicate."
  (λ (reducer)
    (lexical-let ((cache-table (make-hash-table))
                  (not-found (make-symbol "distinct-not-found")))
      (transducer-reducer
       (λ () (funcall reducer))
       (λ (result) (funcall reducer result))
       (λ (result item)
         (let ((found-item (gethash item cache-table not-found)))
           (if (not (eq found-item not-found))
               result
             (puthash item t cache-table)
             (funcall reducer result item))))))))

(defun transducer-first (firster)
  "First reducer with FIRSTER predicate."
  (transducer-step-reducer
   (λ (reducer result item)
     (if (funcall firster item)
         (transducer-reduced-value
          (funcall reducer result item))
       result))))


(defun transducer-take (n)
  "Get the first N results of a STREAM."
  (lexical-let ((count 0))
    (transducer-step-reducer
     (λ (reducer result item)
       (if (>= count n)
           (transducer-reduced-value result)
         (setq count (1+ count))
         (funcall reducer result item))))))

(defconst transducer--pair-empty 'pair-empty
  "A value indicating a transducer has an empty pair.
Not to be used directly.")

(defun transducer-pair ()
  "A transducer that pairs values together."
  (lexical-let ((head nil))
    (transducer-wrapped-reducer
     (λ (reducer) (setq head transducer--pair-empty) (funcall reducer))
     (λ (reducer result) (setq head nil) (funcall reducer result))
     (λ (reducer result item)
       (if (eq head transducer--pair-empty)
           (prog1
               result
             (setq head item))
         (prog1
             (funcall reducer result (cons head item))
           (setq head transducer--pair-empty)))))))


;;* Reductions
(defconst transducer-transduce-reduced 'transduce-reduced
  "A value signifying that a transducer should stop.")

(defun transducer-reduced-value (value)
  "Create a flag or sentinel to stop a reducer with VALUE."
  (if (transducer-reduced-value-p value)
      (cons transducer-transduce-reduced (cdr value))
    (cons transducer-transduce-reduced value)))

(defun transducer-reduced-value-p (value)
  "Check if the VALUE is reduced."
  (and (consp value)
       (eq (car value) transducer-transduce-reduced)))

(defun transducer-reduced-get-value (reduced)
  "Get the reduced value of a REDUCED."
  (cdr reduced))


;;* Transduce
(defun transducer-transduce (transducer reducer xs)
  "A transduce on a list with TRANSDUCER, REDUCER and a list XS."
  (let* ((reductor (funcall transducer reducer))
      (result (funcall reductor))
      (ys xs))
    (while (not (null ys))
      (setq result (funcall reductor result (car ys))
         ys (cdr ys))
      (when (transducer-reduced-value-p result)
        (setq result (transducer-reduced-get-value result)
           ys nil)))
    (funcall reductor result)))


;;* Stream Transduce
(defconst transducer--stream-step 'stream-step
  "A value stating whether the stream should continue on.
Not to be used directly.")

(defconst transducer--stream-skip 'stream-skip
  "A value stating whether the stream should get another value.
Not to be used directly.")

(defun transducer-transduce-stream (transducer stream)
  "A transduce on a stream with a TRANSDUCER on STREAM."
  (require 'stream)
  (lexical-let* ((reductor
       (funcall transducer
          (transducer-reducer
           (λ () transducer--stream-skip)
           (λ (_) transducer--stream-skip)
           (λ (_ item) item)))))
    (stream
     (λ (&rest args)
       (lexical-let* ((value (apply stream args))
           (state nil)
           (result nil))
         (while (not (eq state transducer--stream-step))
           (cond
            ((stream-start-value-p value)
             (setq value (apply stream args)
                state nil))
            ((stream-stop-value-p value)
             (setq result value
                state transducer--stream-step))
            (t
             (setq result (funcall reductor transducer--stream-skip value)
                state transducer--stream-step)
             (when (transducer-reduced-value-p result)
               (setq result (transducer-reduced-get-value result)
                  stream (stream-stopped)
                  state transducer--stream-step))
             (when (eq result transducer--stream-skip)
               (setq value (apply stream args)
                  state nil)))))
         result)))))


(provide 'transducer)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; transducer.el ends here
