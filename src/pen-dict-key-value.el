;; Functions for representing key-value associations, (i.e. dicts, hash-maps, etc.)
;; alists, plists...

;; https://www.reddit.com/r/emacs/comments/gf6mxo/sets_maps_associative_arrays_dictionaries_or/

;; There are lots of ways to represent key-value
;; associations and to look up the value for a
;; key (and in some cases look up the key for a
;; value).

;; The main ones are what Tom mentioned:
;; association lists (alists) and hash tables.

;; Others include property lists.

;; Symbols have a property list.

;; Strings and buffer text can have a property
;; list (text properties).

;; Buffer overlays have (or are) property lists
;; associated with pairs of buffer positions.

;; And of course you can roll your own form of
;; key-value store/lookup.

(comment
 '((pine . cones)
   (oak . acorns)
   (maple . seeds)))

;; Sometimes it is better to design an alist
;; to store the associated value in the CAR of
;; the CDR of the element.

;; Here is an example of such an alist:

(comment
 '((rose red) (lily white) (buttercup yellow)))

;; A property list (plist for short) is a list of
;; paired elements.
;; Each of the pairs associates a property name
;; (usually a symbol) with a property or value.
;; Here is an example of a property list:
;; http://xahlee.info/emacs/emacs/elisp_property_list.html

(comment
 (defvar testalist '())
 (add-to-list 'testalist '()))

;; alist-get is very similar to rassoc

(defun alist-update (list-var key value &optional key-is-cdr)
  "examples:
 (alist-update 'auto-mode-alist 'javascript-mode 'js2-mode)
 (alist-update 'testalist :b 2)"
  (if key-is-cdr
      (if (rassoc key (eval list-var))
          (setf (cdr (rassoc key (eval list-var))) value)
        (alist-put list-var value key))
    (if (alist-get key (eval list-var))
        (setf (cdr (assoc key (eval list-var))) value)
      (alist-put list-var key value))))

;; https://emacs.stackexchange.com/questions/3397/how-to-replace-an-element-of-an-alist
;; (defalias 'alist-put 'add-to-list)
(defun alist-put (list-var key value)
  ;;  with an alist you can simply add a new element to the front of the list and it will shadow matches further down the list.
  (add-to-list list-var `(,key . ,value)))

(comment
 (alist-update 'testalist :b 5)

 '(pine cones numbers (1 2 3) color "blue")
 (plist-get '(:x 1 :y 2) :y)
 (plist-get '(x 1 y 2) 'y)

 ;; create a var xx with value of property list
 (let ((xx '(a 1 b 2)))
   ;; set value to a existing key
   (setq xx (plist-put xx 'b 3))
   (message "%S" xx)
   (message "%S" (plist-member xx 'b))
   ;; (plist-member xx 'b)
   ))

(provide 'pen-dict-key-value)
