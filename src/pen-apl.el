(require 'gnu-apl-mode)

;; https://tryapl.org/
;; https://www.gnu.org/software/apl/apl-intro.html
;; https://www.gnu.org/software/apl/apl-intro.html#CH_3.3.3

;; +/⍳100000

(defun start-apl-server ()
  (interactive)
  (nw "apl" "-d"))

(defun runapl (s)
  (pen-snc
   (concat
    (cmd "apl" "-s" "-f"
         (tf "tempXXX" (concat
                        (awk1 s)
                        ")OFF") "apl"))
    "| sed '/^$/d'")))

;; It's not exactly fast
;; But start APL first in a tmux split, and it will run much faster
(defun testrunapl ()
  (interactive)
  (ifietv
   (runapl "+/⍳100000")))

(defun testrunapl-2 ()
  (interactive)
  (ifietv
   (runapl "+/[2] (3 3⍴1 2 3 4 5 6 7 8 9)")))

(provide 'pen-apl)
