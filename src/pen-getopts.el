(require 'pen-dict-key-value)

(defun getopts-to-cl-args (optstring)
  (interactive (list (read-string "opts string:")))
  (let* ((ntuple (s-split "=" optstring))
         (key (s-replace "^--" "" (first ntuple)))
         (val (second ntuple)))
    (ifietv
     key)))
;; e:q-cip
;; (cmd-cip "-5" 5 "hello" "=h")

;; https://www.reddit.com/r/emacs/comments/gf6mxo/sets_maps_associative_arrays_dictionaries_or/

;; TODO Try interpret the way
;; that functions interpret key/value pairs
;; key symbols [[el:(type :hdfslk)]]
;; into the key.

(provide 'pen-getopts)
