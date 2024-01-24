(require 'ctable)

;; Demo
(comment
 (let* ((column-model                   ; column model
         (list (make-ctbl:cmodel
                :title "A" :sorter 'ctbl:sort-number-lessp
                :min-width 5 :align 'right)
               (make-ctbl:cmodel
                :title "Title" :align 'center
                :sorter (lambda (a b) (ctbl:sort-number-lessp (length a) (length b))))
               (make-ctbl:cmodel
                :title "Comment" :align 'left)))
        (data
         '((1  "Bon Tanaka" "8 Year Curry." 'a)
           (2  "Bon Tanaka" "Nan-ban Curry." 'b)
           (3  "Bon Tanaka" "Half Curry." 'c)
           (4  "Bon Tanaka" "Katsu Curry." 'd)
           (5  "Bon Tanaka" "Gyu-don." 'e)
           (6  "CoCo Ichi"  "Beaf Curry." 'f)
           (7  "CoCo Ichi"  "Poke Curry." 'g)
           (8  "CoCo Ichi"  "Yasai Curry." 'h)
           (9  "Berkley"    "Hamburger Curry." 'i)
           (10 "Berkley"    "Lunch set." 'j)
           (11 "Berkley"    "Coffee." k)))
        (model                          ; data model
         (make-ctbl:model
          :column-model column-model :data data))
        (component                      ; ctable component
         (ctbl:create-table-component-buffer
          :model model)))
   (pop-to-buffer (ctbl:cp-get-buffer component))))

(provide 'pen-ctable)
