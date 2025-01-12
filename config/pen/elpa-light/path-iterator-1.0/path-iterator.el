;;; path-iterator.el --- An iterator for traversing a directory path.  -*-lexical-binding:t-*-

;; Copyright (C) 2015 - 2017, 2019 Free Software Foundation, Inc.
;;
;; Author: Stephen Leake <stephen_leake@stephe-leake.org>
;; Maintainer: Stephen Leake <stephen_leake@stephe-leake.org>
;; Version: 1.0
;; package-requires: ((emacs "25.0"))
;;

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A path-iterator object is created by `make-path-iterator', which
;; takes keyword arguments:
;;
;; user-path-non-recursive: list of directories to return, in order given
;;
;; user-path-recursive: list of root directory trees to return; trees
;; are explored in depth-first order, after all directories in
;; `user-path-non-recursive' are returned.
;;
;; ignore-function: a function that takes one argument (an absolute
;; directory name), and returns nil if directory should be returned,
;; non-nil if not.
;;
;; Other functions:
;;
;; path-iter-next: return the next directory, or nil if done.
;;
;; path-iter-restart: restart iterator; next call to `path-iter-next'
;; will return the first directory.
;;
;; path-iter-reset: clear internal caches; recompute the path. In
;; normal operation, the directories returned from both the
;; non-recursive and recursive path are cached in an array in the
;; first iteration, and subsequent iterations just return items in
;; that array. This avoids calling `directory-files' and the
;; ignore-function on iterations after the first. `path-iter-reset'
;; should be called if directories are added/deleted in the recursive
;; path, or if the ignore-function is changed,
;;
;; path-iter-contains-root: non-nil if the iterator directory lists
;; contain the given directory. For both the non-recursive and
;; recursive lists, the given directory must be in the list; nested
;; directories return nil.
;;
;; path-iter-expand-filename: expand a given filename against all the
;; directories returned by the iterator, return the first one that
;; exists, or nil if the filename exists in none of the directories.

;;; Code:

(cl-defstruct
    (path-iterator
     (:conc-name path-iter-)
     (:copier nil)
     (:constructor nil)
     (:constructor make-path-iterator
		   (&key
		    user-path-non-recursive
		    user-path-recursive
		    ignore-function
		    &aux
		    (path-non-recursive-init (path-iter--to-truename user-path-non-recursive))
		    (path-non-recursive path-non-recursive-init)
		    (path-recursive-init (path-iter--to-truename user-path-recursive))
		    (path-recursive path-recursive-init)
		    (visited nil)
		    (current nil)
		    (state nil))
		   ))

  path-non-recursive-init ;; absolute directory file truenames, no recursion
  path-recursive-init ;; absolute directory file truenames, recurse into subdirectories

  path-non-recursive ;; temp storage while iterating
  path-recursive     ;; "

  ignore-function
  ;; Function called with absolute directory name; return non-nil
  ;; if it should be ignored.

  visited
  ;; During first iteration - list of directories already visited.
  ;; During subsequent iterations - vector of directories to visit
  ;;
  ;; We have to populate the visited list during the first iteration
  ;; in order to avoid visiting a directory twice, so we might as well
  ;; use it for subsequent iterations.

  current ;; index into `visited' during subsequent iterations

  state ;; one of nil, 'started, 'complete. Allows detecting interrupted computation.
  )

(defun path-iter--to-truename (path)
  "Convert each existing element of PATH to an absolute directory file truename,
return the resulting list.  Elements of PATH are either absolute or
relative to `default-directory'.

If an element of PATH is nil, `default-directory' is used."
  ;; The nil handling is as defined by the `load-path' doc string.
  (unless (listp path)
    ;; Users often specify a single root directory, and forget it's
    ;; supposed to be a list.
    (setq path (list path)))
  (let (result)
    (cl-mapc
     (lambda (name)
       (let ((absname (if name
			  (expand-file-name name)
			default-directory)))
	 (when (file-directory-p absname)
	   (push (file-name-as-directory (file-truename absname)) result))
	 ))
     path)
    (nreverse result)))

(cl-defmethod path-iter-next ((iter path-iterator))
  "Return the next directory to visit, or nil if there are no more.

The iterator will first visit all elements of the recursive path,
visiting all subdirectories of the recursive path for which
`ignore-function' returns nil, in depth-first order (parent
directories are visited before their subdirectories; sibling
directories are visited after subdirectories); then visit all
directories in the non-recursive path, but will not visit any
directory more than once. The order of subdirectories within a
directory is given by `directory-files'.

`ignore-function' is passed one argument; the directory file
name. Symlinks in the directory part are resolved, but the
nondirectory part is the link name if it is a symlink.

The directories returned by `path-iter-next' are absolute
directory file truenames; they contain forward slashes, end in a
slash, have casing that matches the existing directory file name,
and resolve simlinks (see `file-truename')."
  (cond
   ((and (listp (path-iter-visited iter))
	 (not (null (path-iter-path-recursive iter))))
    ;; First iteration, doing recursive path

    (let ((result (pop (path-iter-path-recursive iter)))
	  subdirs)

      (while (member result (path-iter-visited iter))
	(setq result (pop (path-iter-path-recursive iter))))

      (when result
	(push result (path-iter-visited iter))

	;; Push directories in `result' onto the path, to be visited
	;; next. `directory-files' sorts the list.
	(cl-mapc
	 (lambda (absname)
	   (unless (or (string-equal "." (file-name-nondirectory absname))
		       (string-equal ".." (file-name-nondirectory absname))
		       (not (file-directory-p absname))
		       ;; If `absname' is a symlink, we assume
		       ;; `ignore-function' wants the link name.
		       (and (path-iter-ignore-function iter)
			    (funcall (path-iter-ignore-function iter) absname)))
	     (push (file-name-as-directory (file-truename absname)) subdirs))
	   )
	 (directory-files result t))

	(setf (path-iter-path-recursive iter)
	      (append
	       (nreverse subdirs)
	       (path-iter-path-recursive iter)))
	)
      (unless result
	(setf (path-iter-state iter) 'complete))

      result))

   ((and (listp (path-iter-visited iter))
	 (not (null (path-iter-path-non-recursive iter))))
    ;; First iteration, doing non-recursive path
    (let ((result (pop (path-iter-path-non-recursive iter))))

      (while (member result (path-iter-visited iter))
	(setq result (pop (path-iter-path-non-recursive iter))))

      (when result
	(push result (path-iter-visited iter)))

      (unless result
	(setf (path-iter-state iter) 'complete))

      result))

   ((listp (path-iter-visited iter))
    ;; Both paths empty; first iteration done.

    (setf (path-iter-state iter) 'complete)

    nil)

   (t
    ;; Subsequent iterations; path-iter-visited changed to a vector
    (setf (path-iter-current iter) (1+ (path-iter-current iter)))

    (if (< (path-iter-current iter) (length (path-iter-visited iter)))
	(aref (path-iter-visited iter) (path-iter-current iter))
      (setf (path-iter-state iter) 'complete)
      nil))
   ))

(cl-defmethod path-iter-restart ((iter path-iterator))
  "Restart ITER.
Next call to `path-iter-next' will return first directory visited.
Uses cached path computed during first iteration; see `path-iter-reset'."
  (if (eq 'started (path-iter-state iter))
      ;; compute was interrupted (probably by `while-no-input' in icomplete)
      (path-iter-reset iter)

    (cond
     ((null (path-iter-visited iter))
      ;; Not run first time yet
      (setf (path-iter-state iter) 'started))

     ((listp (path-iter-visited iter))
      ;; Run once; convert to vector
      (setf (path-iter-visited iter) (vconcat nil (nreverse (path-iter-visited iter))))
      (setf (path-iter-current iter) -1))

     (t
      ;; Run more than once
      (setf (path-iter-current iter) -1))
     )))

(cl-defmethod path-iter-reset ((iter path-iterator))
  "Reset ITER; recomputes path.
Next call to `path-iter-next' will return first directory visited."
  (setf (path-iter-path-non-recursive iter) (path-iter-path-non-recursive-init iter))
  (setf (path-iter-path-recursive iter) (path-iter-path-recursive-init iter))
  (setf (path-iter-visited iter) nil)
  (setf (path-iter-current iter) nil)
  (setf (path-iter-state iter) 'started)
  )

(cl-defmethod path-iter-expand-filename ((iter path-iterator) filename)
  "Expand FILENAME with ITER.
Return a list of absolute filenames or nil if none found."
  (path-iter-restart iter)

  (let (result dir)
    (while (setq dir (path-iter-next iter))
      (cl-mapc
       (lambda (filename)
	 (push (concat (file-name-as-directory dir) filename) result))
       (file-name-all-completions filename dir)))
    result))

(cl-defmethod path-iter-files ((iter path-iterator) pred)
  "Return all filenames in ITER satisfying predicate PRED.
If non-nil, PRED is a function taking a single absolute file
name; the file is included if PRED returns non-nil"
  (let (dir result)
    (path-iter-restart iter)

    (while (setq dir (path-iter-next iter))
      (mapc
       (lambda (absfile)
	 (when (and (not (string-equal "." (substring absfile -1)))
		    (not (string-equal ".." (substring absfile -2)))
		    (not (file-directory-p absfile))
                    (or (null pred)
                        (funcall pred absfile)))
	   (push absfile result)))
       (directory-files dir t))
      )
    result))

(provide 'path-iterator)
;;; path-iterator.el ends here.
