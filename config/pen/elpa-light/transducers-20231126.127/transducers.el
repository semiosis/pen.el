;;; transducers.el --- Ergonomic, efficient data processing -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Colin Woodbury
;;
;; Author: Colin Woodbury <colin@fosskers.ca>
;; Maintainer: Colin Woodbury <colin@fosskers.ca>
;; Created: July 26, 2023
;; Modified: November 26, 2023
;; Version: 1.0.0
;; Keywords: lisp
;; Homepage: https://git.sr.ht/~fosskers/transducers.el
;; Package-Requires: ((emacs "28.1"))
;; SPDX-License-Identifier: LGPL-3.0-or-later
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Transducers are an ergonomic and extremely memory-efficient way to process a
;; data source. Here "data source" means simple collections like Lists or
;; Vectors, but also potentially large files or generators of infinite data.
;;
;; Transducers...
;;
;; - allow the chaining of operations like map and filter without allocating
;;   memory between each step.
;; - aren't tied to any specific data type; they need only be implemented once.
;; - vastly simplify "data transformation code".
;; - have nothing to do with "lazy evaluation".
;; - are a joy to use!
;;
;; See the README for examples.
;;
;; **Usage Note**
;;
;; This library uses the `read-symbol-shorthands' feature introduced in Emacs
;; 28. While browsing the code it may appear as if most of the functions are
;; prefixed by `t-', but in fact the symbols are exported with the full prefix
;; `transducers-'. Every user is then free to abbreviate the function symbols as
;; they wish in their own files, just like import systems in other languages
;; allow.
;;
;; To enable this abbreviation in your own Emacs Lisp files, interactively call
;; either `add-file-local-variable-prop-line' or `add-file-local-variable' and
;; set `read-symbol-shorthands' to a value like (("t-" . "transducers-")). You
;; can see an example of this at the bottom of this file (transducers.el).
;;
;;; Code:

(require 'cl-lib)
(require 'ring)

;; --- Utilities --- ;;

(defconst t-done 't--done
  "The signal that a generator source has finished generating values.")

(cl-defstruct (t-reduced (:copier nil))
  "A wrapper that signals that reduction has completed."
  val)

(cl-defstruct (t-generator (:copier nil) (:predicate nil))
  "A wrapper around a function that can potentially yield endless values."
  (func nil :read-only t))

(cl-defstruct (t-filepath (:copier nil) (:predicate nil))
  "A wrapper around a string that denotes some filepath."
  path)

(cl-defstruct (t-buffer (:copier nil) (:predicate nil))
  "A wrapper around a buffer name."
  name)

(cl-defstruct (t-plist (:copier nil) (:predicate nil))
  (list nil :read-only t :type list))

(defun t-ensure-function (arg)
  "Is some ARG a function?"
  (cond ((functionp arg) arg)
        ((symbolp arg) (t-ensure-function (symbol-function arg)))
        (t (error "Argument is not a function: %s" arg))))

(defun t-comp (function &rest functions)
  "FUNCTION composition.

Any number of FUNCTIONS can be given. You're free to pass either
lambdas or named functions by their symbol."
  (cl-reduce (lambda (f g)
               (let ((f (t-ensure-function f))
                     (g (t-ensure-function g)))
                 (lambda (&rest arguments) (funcall f (apply g arguments)))))
             functions
             :initial-value function))

(defun t--ensure-reduced (x)
  "Ensure that X is reduced."
  (if (t-reduced-p x)
      x
    (make-transducers-reduced :val x)))

(defun t--preserving-reduced (reducer)
  "Given a REDUCER, wraps a reduced value twice.
This is because reducing functions (like
`t--list-reduce') unwraps them. `t-concatenate' is a
good example: it re-uses its reducer on its input using
list-reduce. If that reduction finishes early and returns a
reduced value, `t--list-reduce' would unreduce' that
value and try to continue the transducing process."
  (lambda (a b)
    (let ((result (funcall reducer a b)))
      (if (t-reduced-p result)
          (make-transducers-reduced :val result)
        result))))

;; --- Entry Functions --- ;;

(cl-defgeneric t-transduce (xform f source)
  "The entry-point for processing some data source via transductions.

Given a composition of transducer functions (the XFORM), a
reducer function F, a concrete data SOURCE, and any number
of additional SOURCES, perform a full, strict transduction.")

(cl-defmethod t-transduce (xform f (source list))
  "Transduce over lists.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete list SOURCE, perform a full,
strict transduction."
  (t--list-transduce xform f source))

(cl-defmethod t-transduce (xform f (source array))
  "Transduce over arrays.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete array SOURCE, perform a full,
strict transduction."
  (t--array-transduce xform f source))

(cl-defmethod t-transduce (xform f (source t-generator))
  "Transduce over generators.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete generator SOURCE, perform a
full, strict transduction."
  (t--generator-transduce xform f source))

(cl-defmethod t-transduce (xform f (source t-filepath))
  "Transduce over the lines of a file.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete filepath SOURCE, perform a
full, strict transduction."
  (t--filepath-transduce xform f source))

(cl-defmethod t-transduce (xform f (source t-buffer))
  "Transduce over a buffer.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete buffer SOURCE, perform a full,
strict transduction.

The buffer can be a buffer object or just a buffer name."
  (t--buffer-transduce xform f source))

(cl-defmethod t-transduce (xform f (source hash-table))
  "Transduce over a Hash Table.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete plist SOURCE, perform a full,
strict transduction.

Yields key-value pairs as cons cells."
  (t--hash-table-transduce xform f source))

(cl-defmethod t-transduce (xform f (source t-plist))
  "Transduce over a Property List (plist).

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete plist SOURCE, perform a full,
strict transduction.

Yields key-value pairs as cons cells."
  (t--plist-transduce xform f source))

(defun t--list-transduce (xform f coll)
  "Transduce over lists.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete list COLL, perform a full,
strict transduction."
  (let* ((init   (funcall f))
         (xf     (funcall xform f))
         (result (t--list-reduce xf init coll)))
    (funcall xf result)))

(defun t--list-reduce (f identity coll)
  "Reduce over lists.

F is the transducer/reducer composition, IDENTITY the result of
applying the reducer without arguments (thus achieving an
\"element\" or \"zero\" value), and COLL is our guaranteed source
list."
  (cl-labels ((recurse (acc items)
                (if (null items)
                    acc
                  (let ((v (funcall f acc (car items))))
                    (if (t-reduced-p v)
                        (t-reduced-val v)
                      (recurse v (cdr items)))))))
    (recurse identity coll)))

(defun t--array-transduce (xform f coll)
  "Transduce over arrays.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete array COLL, perform a full,
strict transduction."
  (let* ((init   (funcall f))
         (xf     (funcall xform f))
         (result (t--array-reduce xf init coll)))
    (funcall xf result)))

(defun t--array-reduce (f identity arr)
  "Reduce over arrays.

F is the transducer/reducer composition, IDENTITY the result of
applying the reducer without arguments (thus achieving an
\"element\" or \"zero\" value), and ARR is our guaranteed source
array."
  (let ((len (length arr)))
    (cl-labels ((recurse (acc i)
                  (if (= i len)
                      acc
                    (let ((acc (funcall f acc (aref arr i))))
                      (if (t-reduced-p acc)
                          (t-reduced-val acc)
                        (recurse acc (1+ i)))))))
      (recurse identity 0))))

(defun t--generator-transduce (xform f coll)
  "Transduce over generators.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete generator COLL, perform a
full, strict transduction."
  (let* ((init   (funcall f))
         (xf     (funcall xform f))
         (result (t--generator-reduce xf init coll)))
    (funcall xf result)))

(defun t--generator-reduce (f identity gen)
  "Reduce over a generator.

F is the transducer/reducer composition, IDENTITY the result of
applying the reducer without arguments (thus achieving an
\"element\" or \"zero\" value), and GEN is our guaranteed source
array."
  (cl-labels ((recurse (acc)
                (let ((val (funcall (t-generator-func gen))))
                  (if (eq t-done val)
                      acc
                    (let ((acc (funcall f acc val)))
                      (if (t-reduced-p acc)
                          (t-reduced-val acc)
                        (recurse acc)))))))
    (recurse identity)))

(defun t--filepath-transduce (xform f file)
  "Transduce over the lines of a file.

Given a composition of transducer functions (the XFORM), a
reducer function F, a concrete filepath FILE, perform a full,
strict transduction."
  (let* ((init   (funcall f))
         (xf     (funcall xform f))
         (result (t--filepath-reduce xf init file)))
    (funcall xf result)))

(defun t--filepath-reduce (f identity file)
  "Reduce over a filepath.

F is the transducer/reducer composition, IDENTITY the result of
applying the reducer without arguments (thus achieving an
\"element\" or \"zero\" value), and FILE is our guaranteed source
file."
  (let ((path (t-filepath-path file)))
    (with-temp-buffer
      (cl-labels ((recurse (acc start)
                    (goto-char (point-max))
                    (insert-file-contents path nil start (+ start 100) nil)
                    (let* ((line  (buffer-substring-no-properties (point-min) (point-max)))
                           (nlpos (string-match-p "\n" line)))
                      (cond
                       ;; There was nothing left to read from the underlying file.
                       ((string= line "") acc)
                       ;; A newline character was found in the current line, so we
                       ;; extract only that section and leave the remainder in the
                       ;; temporary buffer for the next iteration.
                       (nlpos (let* ((beg  (point-min))
                                     (line (buffer-substring-no-properties beg (1+ nlpos))))
                                (delete-region beg (+ 2 nlpos))  ; Also deletes the newline.
                                (let ((acc (funcall f acc line)))
                                  (if (t-reduced-p acc)
                                      (t-reduced-val acc)
                                    (recurse acc (+ start 100))))))
                       (t (recurse acc (+ start 100)))))))
        (recurse identity 0)))))

(defun t--buffer-transduce (xform f buffer)
  "Transduce over a buffer.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete BUFFER, perform a full, strict
transduction."
  (let* ((init   (funcall f))
         (xf     (funcall xform f))
         (result (t--buffer-reduce xf init buffer)))
    (funcall xf result)))

(defun t--buffer-reduce (f identity buffer)
  "Reduce over a buffer.

F is the transducer/reducer composition, IDENTITY the result of
applying the reducer without arguments (thus achieving an
\"element\" or \"zero\" value), and BUFFER is our guaranteed
source buffer."
  (with-current-buffer (t-buffer-name buffer)
    (let ((eof (point-max)))
      (goto-char (point-min))
      (cl-labels ((recurse (acc)
                    (if (= eof (point))
                        acc
                      (let* ((start (line-beginning-position))
                             (end   (line-end-position))
                             (line  (buffer-substring-no-properties start end))
                             (acc   (funcall f acc line)))
                        (if (t-reduced-p acc)
                            (t-reduced-val acc)
                          (progn (forward-line 1)
                                 (recurse acc)))))))
        (recurse identity)))))

(defun t--plist-transduce (xform f coll)
  "Transduce over a Property List.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete COLL, perform a full, strict
transduction."
  (let* ((init   (funcall f))
         (xf     (funcall xform f))
         (result (t--plist-reduce xf init coll)))
    (funcall xf result)))

(defun t--plist-reduce (f identity lst)
  "Reduce over a Property List.

F is the transducer/reducer composition, IDENTITY the result of
applying the reducer without arguments (thus achieving an
\"element\" or \"zero\" value), and LST is our guaranteed source
plist."
  (cl-labels ((recurse (acc items)
                (cond ((null items) acc)
                      ((null (cdr items)) (error "Imbalanced plist. Last key: %s" (car items)))
                      (t (let ((v (funcall f acc (cons (car items) (cl-second items)))))
                           (if (t-reduced-p v)
                               (t-reduced-val v)
                             (recurse v (cdr (cdr items)))))))))
    (recurse identity (t-plist-list lst))))

;; (t-transduce #'t-pass #'t-cons (t-plist `(:a 1 :b 2 :c 3)))
;; (t-transduce (t-map #'car) #'t-cons (t-plist `(:a 1 :b 2 :c 3)))
;; (t-transduce (t-map #'cdr) #'+ (t-plist `(:a 1 :b 2 :c)))  ;; Imbalanced plist for testing.

(defun t--hash-table-transduce (xform f coll)
  "Transduce over a Hash Table.

Given a composition of transducer functions (the XFORM), a
reducer function F, and a concrete COLL, perform a full, strict
transduction."
  (let* ((init   (funcall f))
         (xf     (funcall xform f))
         (result (t--hash-table-reduce xf init coll)))
    (funcall xf result)))

(defun t--hash-table-reduce (f identity ht)
  "Reduce over a Hash Table.

F is the transducer/reducer composition, IDENTITY the result of
applying the reducer without arguments (thus achieving an
\"element\" or \"zero\" value), and HT is our guaranteed source
Hash Table."
  (catch 'stop
    (let ((acc identity))
      (maphash (lambda (key value)
                 (let ((res (funcall f acc (cons key value))))
                   (if (t-reduced-p res)
                       (throw 'stop (t-reduced-val res))
                     (setq acc res))))
               ht)
      acc)))

;; --- Transducers --- ;;

(defun t-pass (reducer)
  "Transducer: Just pass along each value of the transduction.

Same in intent with applying `t-map' to `identity', but this
should be slightly more efficient. It is at least shorter to
type.

This function is expected to be passed \"bare\" to `t-transduce',
so there is no need for the caller to manually pass a REDUCER."
  (lambda (result &rest inputs)
    (if inputs (apply reducer result inputs)
      (funcall reducer result))))

;; (t-transduce #'t-pass #'+ '(1 2 3))

(defun t-map (f)
  "Transducer: Apply a function F to all elements of the transduction."
  (lambda (reducer)
    (lambda (result &rest inputs)
      (if inputs (funcall reducer result (apply f inputs))
        (funcall reducer result)))))

;; (t-transduce (t-map (lambda (n) (+ 1 n))) #'+ '(1 2 3))
;; (t-transduce (t-map #'*) #'+ '(1 2 3) '(4 5 6 7))

(defun t-filter (pred)
  "Transducer: Only keep elements from the transduction that satisfy PRED."
  (lambda (reducer)
    (lambda (result &rest inputs)
      (if inputs
          (if (apply pred inputs)
              (apply reducer result inputs)
            result)
        (funcall reducer result)))))

(defun t-filter-map (f)
  "Transducer: Filter all non-nil results of the application of F."
  (lambda (reducer)
    (lambda (result &rest inputs)
      (if inputs (let ((x (apply f inputs)))
                   (if x (funcall reducer result x)
                     result))
        (funcall reducer result)))))

;; (t-transduce (t-filter-map #'car) #'t-cons '(() (2 3) () (5 6) () (8 9)))

(defun t-drop (n)
  "Transducer: Drop the first N elements of the transduction."
  (lambda (reducer)
    (let ((new-n (1+ n)))
      (lambda (result &rest inputs)
        (if inputs (progn (setq new-n (1- new-n))
                          (if (> new-n 0)
                              result
                            (apply reducer result inputs)))
          (funcall reducer result))))))

;; (t-transduce (t-drop 3) #'t-cons '(1 2 3 4 5))

(defun t-drop-while (pred)
  "Transducer: Drop elements from the front of the transduction that satisfy PRED."
  (lambda (reducer)
    (let ((drop? t))
      (lambda (result &rest inputs)
        (if inputs (if (and drop? (apply pred inputs))
                       result
                     (progn (setq drop? nil)
                            (apply reducer result inputs)))
          (funcall reducer result))))))

;; (t-transduce (t-drop-while #'cl-evenp) #'t-cons '(2 4 6 7 8 9))

(defun t-take (n)
  "Transducer: Keep only the first N elements of the transduction."
  (lambda (reducer)
    (let ((new-n n))
      (lambda (result &rest inputs)
        (if inputs (let ((result (if (> new-n 0)
                                     (apply reducer result inputs)
                                   result)))
                     (setq new-n (1- new-n))
                     (if (<= new-n 0)
                         (t--ensure-reduced result)
                       result))
          (funcall reducer result))))))

;; (t-transduce (t-take 3) #'t-cons '(1 2 3 4 5))
;; (t-transduce (t-take 0) #'t-cons '(1 2 3 4 5))

(defun t-take-while (pred)
  "Transducer: Keep only elements which satisfy PRED.
Stops the transduction as soon as any element fails the test."
  (lambda (reducer)
    (lambda (result &rest inputs)
      (if inputs (if (not (apply pred inputs))
                     (make-transducers-reduced :val result)
                   (apply reducer result inputs))
        (funcall reducer result)))))

;; (t-transduce (t-take-while #'cl-evenp) #'t-cons '(2 4 6 8 9 2))

(defun t-uncons (reducer)
  "Transducer: Split up a transduction of cons cells.

This function is expected to be passed \"bare\" to `t-transduce',
so there is no need for the caller to manually pass a REDUCER."
  (lambda (result &rest inputs)
    (if inputs (let* ((input (car inputs))
                      (res (funcall reducer result (car input))))
                 (if (t-reduced-p res)
                     res
                   (funcall reducer res (cdr input))))
      (funcall reducer result))))

;; (t-transduce #'t-uncons #'t-cons (t-plist '(:a 1 :b 2 :c 3)))
;; (t-transduce (t-comp (t-map (lambda (pair) (cons (car pair) (1+ (cdr pair)))))
;;                      #'t-uncons)
;;              #'t-cons (t-plist '(:a 1 :b 2 :c 3)))

(defun t-concatenate (reducer)
  "Transducer: Concatenate all the sublists in the transduction.

This function is expected to be passed \"bare\" to `t-transduce',
so there is no need for the caller to manually pass a REDUCER."
  (let ((preserving-reducer (t--preserving-reduced reducer)))
    (lambda (result &optional inputs)
      (if inputs (t--list-reduce preserving-reducer result inputs)
        (funcall reducer result)))))

;; (t-transduce #'t-concatenate #'t-cons '((1 2 3) (4 5 6) (7 8 9)))

(defun t-flatten (reducer)
  "Transducer: Entirely flatten all lists in the transduction.

This function is expected to be passed \"bare\" to `t-transduce',
so there is no need for the caller to manually pass a REDUCER."
  (lambda (result &rest inputs)
    ;; FIXME 2023-08-01 Only considers the first input element.
    (if inputs (let ((input (car inputs)))
                 ;; FIXME 2023-08-01 Why is this only considering lists?
                 (if (listp input)
                     (t--list-reduce (t--preserving-reduced (t-flatten reducer)) result input)
                   (funcall reducer result input)))
      (funcall reducer result))))

;; (t-transduce #'t-flatten #'t-cons '((1 2 3) 0 (4 (5) 6) 0 (7 8 9) 0))

(defun t-segment (n)
  "Transducer: Partition the input into lists of N items.

 If the input stops, flush any accumulated state, which may be
shorter than N."
  (unless (> n 0)
    (error "t-segment: The arguments to segment must be a positive integer"))
  (lambda (reducer)
    (let ((i 0)
          (collect '()))
      (lambda (result &rest inputs)
        (cond (inputs
               ;; FIXME 2023-08-02 Only the first input is considered.
               (setf collect (cons (car inputs) collect))
               (setf i (1+ i))
               (if (< i n)
                   result
                 (let ((next-input (reverse collect)))
                   (setf i 0)
                   (setf collect '())
                   (funcall reducer result next-input))))
              (t (let ((result (if (zerop i)
                                   result
                                 (funcall reducer result (reverse collect)))))
                   (setf i 0)
                   (if (t-reduced-p result)
                       (funcall reducer (t-reduced-val result))
                     (funcall reducer result)))))))))

;; (t-transduce (t-segment 3) #'t-cons '(1 2 3 4 5))

(defun t-group-by (f)
  "Transducer: Group the input stream into sublists via some function F.

The cutoff criterion is whether the return value of F changes
between two consecutive elements of the transduction."
  (lambda (reducer)
    (let ((prev 'nothing)
          (collect '()))
      (lambda (result &rest inputs)
        (if inputs (let* ((input (car inputs)) ;; FIXME Only considers the first input.
                          (fout (funcall f input)))
                     (if (or (equal fout prev) (eq prev 'nothing))
                         (progn (setf prev fout)
                                (setf collect (cons input collect))
                                result)
                       (let ((next-input (reverse collect)))
                         (setf prev fout)
                         (setf collect (list input))
                         (funcall reducer result next-input))))
          (let ((result (if (null collect)
                            result
                          (funcall reducer result (reverse collect)))))
            (setf collect '())
            (if (t-reduced-p result)
                (funcall reducer (t-reduced-val result))
              (funcall reducer result))))))))

;; (t-transduce (t-group-by #'cl-evenp) #'t-cons '(2 4 6 7 9 1 2 4 6 3))

(defun t-intersperse (elem)
  "Transducer: Insert an ELEM between each value of the transduction."
  (lambda (reducer)
    (let ((send-elem? nil))
      (lambda (result &rest inputs)
        (if inputs (if send-elem?
                       (let ((result (funcall reducer result elem)))
                         (if (t-reduced-p result)
                             result
                           (funcall reducer result (car inputs))))
                     (progn (setf send-elem? t)
                            (funcall reducer result (car inputs))))
          (funcall reducer result))))))

;; (t-transduce (t-intersperse 0) #'t-cons '(1 2 3))

(defun t-enumerate (reducer)
  "Transducer: Index every value passed through the transduction into a cons pair.

Starts at 0.

This function is expected to be passed \"bare\" to `t-transduce',
so there is no need for the caller to manually pass a REDUCER."
  (let ((n 0))
    (lambda (result &rest inputs)
      (if inputs (let ((input (cons n (car inputs))))
                   (setf n (1+ n))
                   (funcall reducer result input))
        (funcall reducer result)))))

;; (t-transduce #'t-enumerate #'t-cons '("a" "b" "c"))

(defun t-log (logger)
  "Transducer: Call some LOGGER function for each step of the transduction.

The LOGGER must accept the running results and the current
\(potentially multiple) elements as input. The original results of
the transduction are passed through as-is."
  (lambda (reducer)
    (lambda (result &rest inputs)
      (if inputs (progn (apply logger result inputs)
                        (apply reducer result inputs))
        (funcall reducer result)))))

;; (t-transduce (t-log (lambda (_ n) (message "Got: %d" n))) #'t-cons '(1 2 3 4 5))

(defun t-window (n)
  "Transducer: Yield N-length windows of overlapping values.

This is different from `t-segment' which yields non-overlapping
windows. If there were fewer items in the input than N, then this
yields nothing."
  (unless (> n 0)
    (error "t-window: The arguments to window must be a positive integer"))
  (lambda (reducer)
    (let ((i 0)
          (q (make-ring n)))
      (lambda (result &rest inputs)
        (cond (inputs
               (ring-insert-at-beginning q (car inputs))
               (setf i (1+ i))
               (if (< i n) result
                 (funcall reducer result (ring-elements q))))
              (t (funcall reducer result)))))))

;; (t-transduce (t-window 3) #'t-cons '(1 2 3 4 5))

(defun t-unique (reducer)
  "Transducer: Only allow values to pass through the transduction once each.

Stateful; this uses a set internally so could get quite heavy if
you're not careful.

This function is expected to be passed \"bare\" to `t-transduce',
so there is no need for the caller to manually pass a REDUCER."
  (let ((seen (make-hash-table :test #'equal)))
    (lambda (result &rest inputs)
      (if inputs (if (gethash (car inputs) seen) ;; FIXME Only considers first input.
                     result
                   (progn (puthash (car inputs) t seen)
                          (funcall reducer result (car inputs))))
        (funcall reducer result)))))

;; (t-transduce #'t-unique #'t-cons '(1 2 1 3 2 1 2 "abc"))

(defun t-dedup (reducer)
  "Transducer: Remove adjacent duplicates from the transduction.

This function is expected to be passed \"bare\" to `t-transduce',
so there is no need for the caller to manually pass a REDUCER."
  (let ((prev 'nothing))
    (lambda (result &rest inputs)
      (if inputs (let ((input (car inputs)))
                   (if (equal prev input)
                       result
                     (progn (setf prev input)
                            (funcall reducer result input))))
        (funcall reducer result)))))

;; (t-transduce #'t-dedup #'t-cons '(1 1 1 2 2 2 3 3 3 4 3 3))

(defun t-step (n)
  "Transducer: Only yield every Nth element of the transduction.

The first element of the transduction is always included."
  (when (< n 1)
    (error "t-step: The argument to skip must be greater than 0"))
  (lambda (reducer)
    (let ((curr 1))
      (lambda (result &rest inputs)
        (if inputs (if (= 1 curr)
                       (progn (setf curr n)
                              (apply reducer result inputs))
                     (progn (setf curr (1- curr))
                            result))
          (funcall reducer result))))))

;; (t-transduce (t-step 2) #'t-cons '(1 2 3 4 5 6 7 8 9))

(defun t-scan (f seed)
  "Transducer: Build up values from the results of previous applications of F.

The function F must accept at least two arguments: the previous
result of F and any current transducer elements. For the very
first application, the given SEED value is used as the initial
\"previous\"."
  (lambda (reducer)
    (let ((prev seed))
      (lambda (result &rest inputs)
        (if inputs (let* ((old prev)
                          (result (funcall reducer result old)))
                     (if (t-reduced-p result) result
                       (let ((new (apply f prev inputs)))
                         (setf prev new)
                         result)))
          (let ((result (funcall reducer result prev)))
            (if (t-reduced-p result)
                (funcall reducer (t-reduced-val result))
              (funcall reducer result))))))))

;; (t-transduce (t-scan #'+ 0) #'t-cons '(1 2 3 4))
;; (t-transduce (t-comp (t-scan #'+ 0) (t-take 2)) #'t-cons '(1 2 3 4))

(defun t-from-csv (reducer)
  "Transducer: Interpret the data stream as CSV data.

The first item found is assumed to be the header list, and it
will be used to construct useable hashmaps for all subsequent
items.

Note: This function makes no attempt to convert types from the
original parsed strings. If you want numbers, you will need to
further parse them yourself with something like
`read-from-string'.

This function is expected to be passed \"bare\" to `t-transduce',
so there is no need for the caller to manually pass a REDUCER."
  (let ((headers nil))
    (lambda (result &rest inputs)
      (if inputs (let ((items (t--split-csv-line (car inputs))))
                   (if headers (funcall reducer result (t--zipmap headers items))
                     (progn (setq headers items)
                            result)))
        (funcall reducer result)))))

;; (t-transduce (t-comp #'t-csv
;;                      (t-map (lambda (hm) (gethash "Name" hm))))
;;              #'t-cons (t-buffer-read "foo.csv"))

(defun t--split-csv-line (line)
  "Split a LINE of CSV data in a sane way.

This removes any extra whitespace that might be hanging around
between elements."
  (split-string line "," nil "[ ]+"))

(defun t--zipmap (keys vals)
  "Form a hashmap with the KEYS mapped to the corresponding VALS.

Borrowed from Clojure, thanks guys."
  (let ((table (make-hash-table :test #'equal)))
    (cl-mapc (lambda (k v) (puthash k v table)) keys vals)
    table))

(defun t-into-csv (headers)
  "Transducer: Given a list of HEADERS, rerender each stream item as CSV.
It's assumed that each item in the transduction is a hash table
whose keys are strings that match the values found in HEADERS."
  (if (null headers)
      (error "t-into-csv: Empty headers list")
    (lambda (reducer)
      (let ((unsent t))
        (lambda (result &rest inputs)
          (if inputs (let ((input (car inputs)))  ;; FIXME Only handles first input.
                       (if unsent
                           (let ((res (funcall reducer result (t--recsv headers))))
                             (if (t-reduced-p res)
                                 res
                               (progn (setq unsent nil)
                                      (funcall reducer res (t--table-vals->csv headers input)))))
                         (funcall reducer result (t--table-vals->csv headers input))))
            (funcall reducer result)))))))

;; (t-transduce (t-comp #'t-from-csv (t-into-csv '("Name" "Age")))
;;              #'t-cons '("Name,Age,Hair" "Colin,35,Blond" "Tamayo,26,Black"))
;; (t-transduce (t-comp #'t-from-csv (t-into-csv '()))
;;              #'t-cons '("Name,Age,Hair" "Colin,35,Blond" "Tamayo,26,Black"))

(defun t--table-vals->csv (headers table)
  "Convert a hash TABLE to a csv string.
This requires a sequence of HEADERS to match keys by."
  (t--recsv (t-transduce (t-filter-map (lambda (k) (gethash k table)))
                         #'t-cons headers)))

(defun t--recsv (items)
  "Reconvert some ITEMS into a comma-separated string."
  (mapconcat (lambda (o) (if (stringp o) o (prin1-to-string o))) items ","))

(defun t-once (item)
  "Transducer: Inject some ITEM into the front of the transduction."
  (lambda (reducer)
    (let ((item item))
      (lambda (result &rest inputs)
        (if inputs (if item
                       (let ((res (funcall reducer result item)))
                         (if (t-reduced-p res)
                             res
                           (progn (setq item nil)
                                  (apply reducer res inputs))))
                     (apply reducer result inputs))
          (funcall reducer result))))))

;; (t-transduce (t-comp (t-filter (lambda (n) (> n 10)))
;;                      (t-once 'hi)
;;                      (t-take 3))
;;              #'t-cons (t-ints 1))

;; (t-transduce (t-comp (t-once "Name,Age")
;;                      #'t-csv
;;                      (t-map (lambda (hm) (gethash "Name" hm))))
;;              #'t-cons ["Alice,35" "Bob,26"])

;; --- Reducers --- ;;

(defun t-cons (&rest vargs)
  "Reducer: Collect all results as a list.

Regardings VARGS: as a \"reducer\", this function expects zero to
two arguments."
  (pcase vargs
    (`(,acc ,input) (cons input acc))
    (`(,acc) (reverse acc))
    (`() '())))

;; (t-transduce (t-map #'1+) #'t-cons '(1 2 3))

(defun t-string (&rest vargs)
  "Reducer: Collect all results as a string.

Regardings VARGS: as a \"reducer\", this function expects zero to
two arguments."
  (pcase vargs
    (`(,acc ,input) (cons input acc))
    (`(,acc) (cl-concatenate 'string (reverse acc)))
    (`() '())))

(defun t-vector (&rest vargs)
  "Reducer: Collect all results as a vector.

Regardings VARGS: as a \"reducer\", this function expects zero to
two arguments."
  (pcase vargs
    (`(,acc ,input) (cons input acc))
    (`(,acc) (cl-concatenate 'vector (reverse acc)))
    (`() '())))

(defun t-hash-table (&rest vargs)
  "Reducer: Collect a stream of key-value cons pairs into a hash table.

Regardings VARGS: as a \"reducer\", this function expects zero to
two arguments."
  (pcase vargs
    (`(,acc (,key . ,value)) (progn (puthash key value acc)
                                    acc))
    (`(,acc) acc)
    (`() (make-hash-table :test #'equal))))

(defun t-count (&rest vargs)
  "Reducer: Count the number of elements that made it through the transduction.

Regardings VARGS: as a \"reducer\", this function expects zero to
two arguments."
  (pcase vargs
    (`(,acc ,_) (1+ acc))
    (`(,acc) acc)
    (`() 0)))

(defun t-average (&rest vargs)
  "Reducer: Calculate the average value of all numeric elements in a transduction.

Regardings VARGS: as a \"reducer\", this function expects zero to
two arguments."
  (pcase vargs
    (`((,count . ,total) ,input) (cons (1+ count) (+ total input)))
    (`((,count . ,total)) (if (= 0 count)
                              (error "t-average: Empty transduction")
                            (/ total (float count))))
    (_ (cons 0 0))))

;; (t-transduce #'t-pass #'t-average '(1 2 3 4 5 6))
;; (t-transduce (t-filter #'cl-evenp) #'t-average '(1 3 5))

(defun t-anyp (pred)
  "Reducer: Yield non-nil if any element in the transduction satisfies PRED.

Short-circuits the transduction as soon as the condition is met."
  (lambda (&rest vargs)
    (pcase vargs
      (`(,_ ,input) (if (funcall pred input)
                        ;; NOTE We manually return `t' here because there is no
                        ;; guarantee that `input' iteslf was not `nil' and still
                        ;; passed the `if' when given to `pred'!
                        (make-transducers-reduced :val t)
                      nil))
      (`(,acc) acc)
      (_ nil))))

;; (t-transduce #'t-pass (t-anyp #'cl-evenp) '(1 3 5 7 9 2))

(defun t-allp (pred)
  "Reducer: Yield non-nil if all elements of the transduction satisfy PRED.

Short-circuits with nil if any element fails the test."
  (lambda (&rest vargs)
    (pcase vargs
      (`(,acc ,input) (if (and acc (funcall pred input))
                          t
                        (make-transducers-reduced :val nil)))
      (`(,acc) acc)
      (_ t))))

;; (t-transduce #'t-pass (t-allp #'cl-oddp) '(1 3 5 7 9))

(defun t-first (&rest vargs)
  "Reducer: Yield the first value of the transduction.

Regardings VARGS: as a \"reducer\", this function expects zero to
two arguments."
  (pcase vargs
    (`(,_ ,input) (make-transducers-reduced :val input))
    (`(,acc) (if (eq 't--none acc)
                 (error "t-first: Empty transduction")
               acc))
    (_ 't--none)))

;; (t-transduce (t-filter #'cl-oddp) #'t-first '(2 4 6 7 10))
;; (t-transduce (t-filter #'cl-oddp) #'t-first '(2 4 6 10))

(defun t-last (&rest vargs)
  "Reducer: Yield the last value of the transduction.

Regardings VARGS: as a \"reducer\", this function expects zero to
two arguments."
  (pcase vargs
    (`(,_ ,input) input)
    (`(,acc) (if (eq 't--none acc)
                 (error "t-last: Empty transduction")
               acc))
    (_ 't--none)))

;; (t-transduce #'t-pass (t-last 'none) '(2 4 6 7 10))

(cl-defun t-fold (f &optional (seed nil seed-p))
  "Reducer: The fundamental reducer.

`t-fold' creates an ad-hoc reducer based on a given 2-argument
function F. An optional SEED value can be given as the initial
accumulator value, which also becomes the return value in case
there were no input left in the transduction.

Functions like `+' and `*' are automatically valid reducers, because they yield
sane values even when given 0 or 1 arguments. Other functions like `max' cannot
be used as-is as reducers since they can't be called without arguments. For
functions like this, `t-fold' is appropriate."
  (if seed-p
      (lambda (&rest vargs)
        (pcase vargs
          (`(,acc ,input) (funcall f acc input))
          (`(, acc) acc)
          (_ seed)))
    (lambda (&rest vargs)
      (pcase vargs
        (`(,acc ,input) (if (eq acc 't--none)
                            input
                          (funcall f acc input)))
        (`(,acc) (if (eq acc 't--none)
                     (error "t-fold: Empty transduction")
                   acc))
        (_ 't--none)))))

;; (t-transduce #'t-pass (t-fold #'max) '())
;; (t-transduce #'t-pass (t-fold #'max 0) '(1 2 3 4 1000 5 6))
;; (t-transduce #'t-pass (t-fold #'max) '(1 2 3 4 1000 5 6))

(defun t-find (pred)
  "Reducer: Find the first element in the transduction that satisfies a given PRED.

Yields nil if no such element were found."
  (lambda (&rest vargs)
    (pcase vargs
      (`(,_ ,input) (if (funcall pred input)
                        (make-transducers-reduced :val input)
                      nil))
      (`(,acc) acc)
      (_ nil))))

(defun t-for-each (&rest _vargs)
  "Reducer: Run through every item in a transduction for their side effects.

Throws away all results and yields nil."
  nil)

;; (t-transduce (t-map (lambda (n) (message "%d" n))) #'t-for-each [1 2 3 4])

;; --- Generators --- ;;

(defun t-repeat (item)
  "Source: Endlessly yield a given ITEM."
  (make-transducers-generator :func (lambda (&rest _) item)))

;; (t-transduce (t-take 4) #'t-cons (t-repeat 9))

(cl-defun t-ints (start &key (step 1))
  "Source: Yield all integers.

The generation begins with START and advances by an optional STEP
value which can be positive or negative. If you only want a
specific range within the transduction, then use `t-take-while'
within your transducer chain."
  (let* ((curr start)
         (func (lambda ()
                 (let ((old curr))
                   (setf curr (+ curr step))
                   old))))
    (make-transducers-generator :func func)))

;; (t-transduce (t-take 10) #'t-cons (t-ints 0 :step 2))

(defun t-random (limit)
  "Source: Yield an endless stream of random numbers.

The numbers generated will be between 0 and LIMIT - 1."
  (make-transducers-generator :func (lambda () (cl-random limit))))

;; (t-transduce (t-take 25) #'t-cons (t-random 10))

(defun t-shuffle (arr)
  "Source: Endlessly yield random elements from a given array ARR.

Recall that both vectors and strings are considered Arrays."
  (if (seq-empty-p arr)
      (make-transducers-generator :func (lambda () t-done))
    (let* ((len (length arr))
           (func (lambda () (aref arr (cl-random len)))))
      (make-transducers-generator :func func))))

;; (t-transduce (t-take 5) #'t-cons (t-shuffle ["Colin" "Tamayo" "Natsume"]))
;; (t-transduce (t-take 5) #'t-cons (t-shuffle []))

(cl-defgeneric t-cycle (seq)
  "Source: Yield the values of a given SEQ endlessly.")

(cl-defmethod t-cycle ((seq list))
  "Source: Yield the values of a given list SEQ endlessly."
  (if (null seq)
      (make-transducers-generator :func (lambda () t-done))
    (let* ((curr seq)
           (func (lambda ()
                   (cond ((null curr)
                          (setf curr (cdr seq))
                          (car seq))
                         (t (let ((next (car curr)))
                              (setf curr (cdr curr))
                              next))))))
      (make-transducers-generator :func func))))

(cl-defmethod t-cycle ((seq array))
  "Source: Yield the values of a given array SEQ endlessly.

This works for any type of array, like vectors and strings."
  (if (zerop (length seq))
      (make-transducers-generator :func (lambda () t-done))
    (let* ((ix 0)
           (len (length seq))
           (func (lambda ()
                   (cond ((>= ix len)
                          (setf ix 1)
                          (aref seq 0))
                         (t (let ((next (aref seq ix)))
                              (setf ix (1+ ix))
                              next))))))
      (make-transducers-generator :func func))))

;; (t-transduce (t-take 10) #'t-cons (t-cycle '(1 2 3)))

;; --- Other Sources --- ;;

(defun t-buffer-read (buffer)
  "Source: Given a BUFFER or its name, read its contents line by line."
  (make-transducers-buffer :name buffer))

;; (t-transduce #'t-pass #'t-count (t-buffer-read (current-buffer)))

(defun t-file-read (path)
  "Source: Given a PATH, read its contents line by line."
  (make-transducers-filepath :path path))

;; (t-transduce (t-comp (t-filter (lambda (line) (string-prefix-p "[" line)))
;;                      (t-map #'nreverse))
;;              #'t-cons (t-file-read "/home/colin/.gitconfig"))

(defun t-plist (plist)
  "Source: Yield key-value pairs from a PLIST."
  (make-transducers-plist :list plist))

;; (t-plist '(:a 1 :b 2 :c 3))

(provide 'transducers)
;;; transducers.el ends here

;; Local Variables:
;; read-symbol-shorthands: (("t-" . "transducers-"))
;; End:
