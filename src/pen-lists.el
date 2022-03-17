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

(defun uncdr (l)
  "Return car with cdr appended"
  (append (car l) (list (cdr l))))

(defun unsnd (l &optional depth)
  "Return car with cdr appended"

  (if (or (not depth)
          (< depth 1))
      (setq depth 1))

  (cond
   ((< 1 depth) (append (unsnd (car l) (- depth 1)) (list (cadr l))))
   (t (append (car l) (list (cadr l))))))

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
        (mapcar (lambda (l) (unsnd l (- len 2)))
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

(defun -filter-not-empty-string (l)
  (-filter 'string-not-empty-nor-nil-p l))
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
(defun -uniq-u (l &optional testfun)
  "Return a copy of LIST with all non-unique elements removed."

  (if (not testfun)
      (setq testfun 'equal))

  ;; Here, contents-hash is some kind of symbol which is set

  (setq testfun (define-hash-table-test 'contents-hash testfun 'sxhash-equal))

  (let ((table (make-hash-table :test 'contents-hash)))
    (cl-loop for string in l do
             (puthash string (1+ (gethash string table 0))
                      table))
    (cl-loop for key being the hash-keys of table
             unless (> (gethash key table) 1)
             collect key)))

(defun -uniq-d (l)
  "Return a copy of LIST with all unique elements removed."
  (-difference l (-uniq-u l)))


(provide 'pen-lists)