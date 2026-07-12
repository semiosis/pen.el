;; Ruby has a sort_by! function which can sort a list of vectors of elements of various types
;; e.g.:
;; ["https://stackoverflow", ".", "com/q/", 0.0]
;; ["https://stackoverflow", ".", "com/q/", 4078906.0]

;; So if I want to implement a natural sort method for elisp, then I'd need to implement this functionality.

;; However, here is a decent solution without using vectors:
;; https://stackoverflow.com/q/1942045
;; j:dictionary-lessp

(defun pen-natural-sort-mls (multiline-string)
  (pen-snc "human-natural-sort.rb" multiline-string))

(defun s-to-naturalised (s)
  (scrape "([^0-9.]+|[0-9.]+)" s)

  )

;; TODO Rewrite e:human-natural-sort.rb in elisp

;; A comparator would be cool but then human-natural-sort.rb would need to be rewritten in elisp
(comment
 (defun pen-natural-sort-comparator (a b)
   (< (car a) (car b)))

 (sort it 'pen-natural-sort-comparator)
 
 (defun pen-natural-sort (sequence)
   (sort sequence 'pen-natural-sort-comparator)))


;; https://stackoverflow.com/q/1942045
(defun dictionary-lessp (str1 str2)
  "return t if STR1 is < STR2 when doing a dictionary compare
(splitting the string at numbers and doing numeric compare with them)"
  (let ((str1-components (dict-split str1))
        (str2-components (dict-split str2)))
    (dict-lessp str1-components str2-components)))

(defun dict-lessp (slist1 slist2)
  "compare the two lists of strings & numbers"
  (cond ((null slist1)
         (not (null slist2)))
        ((null slist2)
         nil)
        ((and (numberp (car slist1))
              (stringp (car slist2)))
         t)
        ((and (numberp (car slist2))
              (stringp (car slist1)))
         nil)
        ((and (numberp (car slist1))
              (numberp (car slist2)))
         (or (< (car slist1) (car slist2))
             (and (= (car slist1) (car slist2))
                  (dict-lessp (cdr slist1) (cdr slist2)))))
        (t
         (or (string-lessp (car slist1) (car slist2))
             (and (string-equal (car slist1) (car slist2))
                  (dict-lessp (cdr slist1) (cdr slist2)))))))

(defun dict-split (str)
  "split a string into a list of number and non-number components"
  (save-match-data 
    (let ((res nil))
      (while (and str (not (string-equal "" str)))
        (let ((p (string-match "[0-9]*\\.?[0-9]+" str)))
          (cond ((null p)
                 (setq res (cons str res))
                 (setq str nil))
                ((= p 0)
                 (setq res (cons (string-to-number (match-string 0 str)) res))
                 (setq str (substring str (match-end 0))))
                (t
                 (setq res (cons (substring str 0 (match-beginning 0)) res))
                 (setq str (substring str (match-beginning 0)))))))
      (reverse res))))

;; Testing:
(comment
 (and (dictionary-lessp "a" "b")
      (null (dictionary-lessp "b" "a"))
      (null (dictionary-lessp "a" "a"))
      (dictionary-lessp "1" "2")
      (null (dictionary-lessp "2" "1"))
      (null (dictionary-lessp "1" "1"))
      (dictionary-lessp "1" "a")
      (null (dictionary-lessp "a" "1"))
      (dictionary-lessp "" "a")
      (null (dictionary-lessp "a" ""))

      (dictionary-lessp "ab12" "ab34")
      (dictionary-lessp "ab12" "ab123")
      (dictionary-lessp "ab12" "ab12d")
      (dictionary-lessp "ab132" "ab132z")


      (dictionary-lessp "132zzzzz" "ab132z")
      (null (dictionary-lessp "1.32" "1ab"))))

(comment
 (sort '("b" "a" "1" "f19" "f" "f2" "f1can") 'dictionary-lessp))

(provide 'pen-sort)
