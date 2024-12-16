(require 'pen-exl)

(comment
 (repeat 7
         :e "Top"
         :down))

;; Example
;; e:watch-chess-960
(comment

 ;; Something like this
 ;; Just write out some equivalent invocations
 ;; and then make the macros to make it possible.

 ;; gensh should generate an sh command invocation for each
 ;; of its elements, and descend into the lists to transform them.
 ;; it's just a big macro expansion.

 ;; Haha, it's almost actually done.

 (gensh
  
  (in-tty
   ;; If a list is in the last cell of a list, then concat the commands together
   (x :sh "cli-chess"
      :e "Online"
      :down
      :e "Create"
      :right
      :down
      :down
      :e "Top"
      :down
      :down
      :down
      :down
      :down
      :down
      :down
      :f1
      :i))

  (in-tty x
          :sh "cli-chess"
          :e "Online"
          :down
          :e "Create"
          :right
          (rpt2
           ;; I could simply use 2, or repeat 2
           :down)
          :e "Top"
          (repeat 7 :down)
          :f1
          :i)))

(comment
 ;; I want to macroexpand without trying to run functions
 ;; or eval anything.

 ;; TODO Figure out how to expand the interior of this list
 '(in-tty x
          :sh "cli-chess"
          :e "Online"
          :down
          :e "Create"
          :right
          (rpt2
           ;; I could simply use 2, or repeat 2
           :down)
          :e "Top"
          (repeat 7 :down)
          :f1
          :i)

 (macroexpand-all
  (list in-tty x
        :sh "cli-chess"
        :e "Online"
        :down
        :e "Create"
        :right
        (rpt2
         ;; I could simply use 2, or repeat 2
         :down)
        :e "Top"
        (repeat 7 :down)
        :f1
        :i)))

(provide 'pen-exl-test)
