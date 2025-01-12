;; -*- lexical-binding: t -*-

(require 'cl-lib)
(require 'subr-x)

(require 'wordnut-u)

(cl-defstruct wordnut--h "A history structure"
	      (max 19)
	      (list '())
	      (pos -1))

(defconst wordnut--h-word-delim-re "[_-]")

(defun wordnut--h-clean (hs)
  (setf (wordnut--h-list hs) '()
	(wordnut--h-pos hs) -1))

(defun wordnut--h-item-new (name &optional point category sense)
  "Return an alist."
  (if (or (null name) (string-blank-p name))
      (error "NAME must not be empty or nil"))

  (list `(name . ,name)
	`(point . ,point)
	`(category . ,category)
	`(sense . ,sense)) )

(defun wordnut--h-equal-words? (left right)
  (setq left (replace-regexp-in-string wordnut--h-word-delim-re " " left))
  (setq right (replace-regexp-in-string wordnut--h-word-delim-re " " right))
  (equal (downcase left) (downcase right)))

(cl-defun wordnut--h-index-of (hs str)
  (let ((index 0))
    (cl-loop for elm in (wordnut--h-list hs) do
	     (if (wordnut--h-equal-words? str (cdr (assoc 'name elm)))
		 (cl-return-from wordnut--h-index-of index))
	     (setq index (1+ index)))

    -1))

(defun wordnut--h-find (hs str)
  (let (index)
    (setq index (wordnut--h-index-of hs str))
    (if (not (eq -1 index)) (nth index (wordnut--h-list hs))
      nil)))

(cl-defun wordnut--h-name-by-pos (hs pos)
  (let (item)
    (if (< pos 0) (cl-return-from wordnut--h-name-by-pos nil))
    (if (setq item (nth pos (wordnut--h-list hs)))
	(cdr (assoc 'name item))
      nil)))

(cl-defun wordnut--h-names (hs)
  "Return a list of names from (wordnut--h-list)."
  (let ((list '()) )
    (cl-loop for elm in (wordnut--h-list hs) do
	     (push (cdr (assoc 'name elm)) list))
    (reverse list)))

(defun wordnut--h-delete-all (list str)
  "Return a new list w/o items where items names == str."
  (wordnut-u-filter
   (lambda (idx)
     (if (not (wordnut--h-equal-words? (cdr (assoc 'name idx)) str))
	 idx))
   list))

(defun wordnut--h-slice (list start &optional end)
  "omglol common lisp; return a new list."
  (if start
      (if (> (abs start) (length list)) (setq start 0)))
  (if end
      (if (> (abs end) (length list)) (setq end (length list))))
  (remove nil (cl-subseq list start end)))

(defun wordnut--h-add (hs item)
  "Inject an ITEM to (wordnut--h-list hs) into a proper position.
Set (wordnut--h-pos hs) to the ITEM physical index in (wordnut--h-list hs)."
  (unless item (error "ITEM is nil"))
  (let (left right name name_orig)
    (setq name_orig (cdr (assoc 'name item))) ;; elisp is very pretty
    (setq name (concat name_orig "_tmp"))
    (setf (cdr (assoc 'name item)) name)

    (setq left (wordnut--h-slice (wordnut--h-list hs) 0 (wordnut--h-pos hs)))
    (setq right (wordnut--h-slice (wordnut--h-list hs) (wordnut--h-pos hs)))

    (setq left (reverse
		(wordnut--h-slice
		 (reverse (wordnut--h-delete-all left name_orig))
		 0 (wordnut--h-max hs))))

    (setq right (wordnut--h-slice
		 (wordnut--h-delete-all right name_orig)
		 0 (wordnut--h-max hs)))

    (setf (cdr (assoc 'name item)) name_orig)
    (setf (wordnut--h-list hs) (append left (list item) right))
    (setf (wordnut--h-pos hs) (wordnut--h-index-of hs name_orig))
    ))

(defun wordnut--h-back-size (hs)
  (- (- (length (wordnut--h-list hs)) (wordnut--h-pos hs)) 1))

(defun wordnut--h-forw-size (hs)
  (wordnut--h-pos hs))

(cl-defun wordnut--h-back (hs func)
  (if (= 0 (wordnut--h-back-size hs)) (cl-return-from wordnut--h-back nil))

  (funcall func hs) ;; update current item
  (setf (wordnut--h-pos hs) (1+ (wordnut--h-pos hs)))
  (nth (wordnut--h-pos hs) (wordnut--h-list hs)))

(cl-defun wordnut--h-forw (hs func)
  (if (= 0 (wordnut--h-forw-size hs)) (cl-return-from wordnut--h-forw nil))

  (funcall func hs) ;; update current item
  (setf (wordnut--h-pos hs) (1- (wordnut--h-pos hs)))
  (nth (wordnut--h-pos hs) (wordnut--h-list hs)))



(provide 'wordnut-history)
