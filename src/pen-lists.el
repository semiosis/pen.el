(require 'seq)
;; Another list library
(require 'dash)

;;https://www.emacswiki.org/emacs/ListModification#toc7

;; (cartesian-product '(a b c) '(1 2 3))

;; I want to make any number of lists here
;; I just need to reduce a list with the reductor being the cartesian-product
;; (-reduce 'cartesian-product '((1 2 3) (a b c) (x y z)))
;; I want to make any number of lists here
;; I just need to reduce a list with the reductor being the cartesian-product
;; (-reduce 'cartesian-product '((1 2 3) (a b c) (x y z)))
(defun cartesian-product-2 (l1 l2)
  (loop for x in l1
        nconc
        (loop for y in l2
              collect (list x y))))

(defun uncdr (lst)
  "Return car with cdr appended"
  (append (car lst) (list (cdr lst))))

(defun unsnd (lst &optional depth)
  "Return car with cdr appended"

  (if (or (not depth)
          (< depth 1))
      (setq depth 1))

  (cond
   ((< 1 depth) (append (unsnd (car lst) (- depth 1)) (list (cadr lst))))
   (t (append (car lst) (list (cadr lst))))))

;; (uncdr '((1 2) . c))

;; (uncdr '((((";" 'ansi-zsh) "w") pen-map) a))
;; (unsnd '((((";" 'ansi-zsh) "w") pen-map) a))

;; uncdr to depth

(defun cartesian-product (&rest ls)
  (let* ((len (length ls))
         (result (cond
                  ((not ls) nil)
                  ((equal 1 len) ls)
                  ;; ((equal 2 (length ls)) (apply 'cartesian-product-2 ls))
                  (t
                   ;; I don't want to flatten all the way, actually
                   ;; (mapcar 'flatten-once (-reduce 'cartesian-product-2 ls))
                   ;; (-reduce 'cartesian-product-2 ls)
                   (-reduce 'cartesian-product-2 ls)
                   ;; (flatten-once (apply 'cartesian-product-2 ls))
                   ;; (mapcar '-flatten (-reduce 'cartesian-product-2 ls))
                   ;; (-reduce 'cartesian-product-2 ls)
                   ))))
    (if (< 2 len)
        (mapcar (lambda (lst) (unsnd lst (- len 2)))
                result)
      result)))

;; Tests
(defalias '-cartesian-product 'cartesian-product)
(defalias '-cx 'cartesian-product)

(defun cartesian-product-recursive (&rest ls)
  (if (equal 1 (length ls))
      ls
    (mapcar '-flatten (-reduce 'cartesian-product-2 ls))))

(defalias '-cxr 'cartesian-product-recursive)

(cartesian-product '(a b c) '(1 2 3) '("h" "i" "j") '(x y z))

(defmacro ntimes (n &rest body)
  (cons 'progn (flatten-once 
                (cl-loop for pen-i from 1 to n collect body))))

(defun delete-nth (index seq)
  "Delete the INDEX th element of SEQ.
Return result sequence, SEQ __is__ modified."
  (if (equal index 0)
      (progn
        (setcar seq (car (cdr seq)))
        (setcdr seq (cdr (cdr seq))))
    (setcdr (nthcdr (1- index) seq) (nthcdr (1+ index) seq))))
(defun set-nth (index seq newval)
  "Set the INDEX th element of SEQ to NEWVAL.
SEQ __is__ modified."
  (setcar (nthcdr index seq) newval))

(defun endcons (a v)
  (if (null v) (cons a nil) (cons (car v) (endcons a (cdr v)))))
;; (endcons 'a '(b c d))

(defun -filter-not-empty-string (lst)
  (-filter 'string-not-empty-nor-nil-p lst))
(defalias '-filter-string-not-empty '-filter-not-empty-string)

;; (-uniq '(("haskell" "DependentTypes" "36bc2cfa-2ffe-4a80-bfb1-26243e220ce4")
;;          ("haskell" "LinearTypes" "78488cbc-5821-43c4-adbf-fdb918ece005")
;;          ("haskell" "ImpredicativeTypes" "01f5902b-0b1c-4ed1-9719-8068f609ee48")
;;          ("haskell" "DependentTypes" "36bc2cfa-2ffe-4a80-bfb1-26243e220ce4")
;;          ("haskell" "LinearTypes" "78488cbc-5821-43c4-adbf-fdb918ece005")
;;          ("haskell" "ImpredicativeTypes" "01f5902b-0b1c-4ed1-9719-8068f609ee48")))

;; (-uniq-u '(("haskell" "DependentTypes" "36bc2cfa-2ffe-4a80-bfb1-26243e220ce4")
;;            ("haskell" "LinearTypes" "78488cbc-5821-43c4-adbf-fdb918ece005")
;;            'a
;;            ("haskell" "ImpredicativeTypes" "01f5902b-0b1c-4ed1-9719-8068f609ee48")
;;            ("haskell" "DependentTypes" "36bc2cfa-2ffe-4a80-bfb1-26243e220ce4")
;;            ("haskell" "LinearTypes" "78488cbc-5821-43c4-adbf-fdb918ece005")
;;            ("haskell" "ImpredicativeTypes" "01f5902b-0b1c-4ed1-9719-8068f609ee48")))

;; https://www.reddit.com/r/emacs/comments/jzcefc/question_keep_only_unique_elements_uniq_u/
(defun -uniq-u (lst &optional testfun)
  "Return a copy of LIST with all non-unique elements removed."

  (if (not testfun)
      (setq testfun 'equal))

  ;; Here, contents-hash is some kind of symbol which is set

  (setq testfun (define-hash-table-test 'contents-hash testfun 'sxhash-equal))

  (let ((table (make-hash-table :test 'contents-hash)))
    (cl-loop for string in lst do
             (puthash string (1+ (gethash string table 0))
                      table))
    (cl-loop for key being the hash-keys of table
             unless (> (gethash key table) 1)
             collect key)))

(defun -uniq-d (lst)
  "Return a copy of LIST with all unique elements removed."
  (-difference lst (-uniq-u lst)))

;; Make
(defun -resize-list (lst size-len &optional init)
  (let* ((len (length lst))
         (diff (- len min)))
    (cond ((< diff 0)
           ;; Add more
           (-minsize-list lst size-len init))
          ((> diff 0)
           ;; remove some
           (-maxsize-list lst size-len))
          (t lst))))

(defun -minsize-list (lst min &optional init)
  (let* ((len (length lst))
         (diff (- len min)))
    (if (< diff 0)
        ;; Add more
        (append lst (make-list (- diff) init))
      ;; otherwise return the same list
      lst)))

(defun -maxsize-list (lst max)
  (-take max lst))

(defalias '-nth 'nth)
(defalias '-pick-nth 'nth)

;; -pick
;; -nth

(defalias '-random-element 'seq-random-elt)

(defun -select-mod-element (lst mod)
  (let* ((n (length lst))
         (i (modulo mod n)))
    (-nth i lst)))

(defun number-a-list-last-element (l)
  (loop for i from 1 to (length l)
        collect
        (append (nth (- i 1) l) `(,i))))

(comment
 (number-a-list-last-element
  chem-atomic-data))

(provide 'pen-lists)
