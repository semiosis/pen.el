(setq lexical-binding t)

;; https://emacs.stackexchange.com/questions/74547/completing-read-search-also-in-annotations
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Programmed-Completion.html


;; This is interesting! - the collection is a filter, actually
;; It appears as though the problem is that when
;; str is not empty, flag is 'metadata - always.
;; flag is 't only if str is empty.
(defun dogs-filter (seq)
  (lambda (str pred flag)
    (pcase flag
      ('metadata
       (list 'metadata
             (cons 'annotation-function
                   (lambda (c)
                     (format "\n\t%s" (alist-get c seq nil nil #'string=))))))
      ('t
       (if (string-blank-p str)
           (all-completions str seq)
         (all-completions
          str
          (lambda (s _ _)
            (seq-map
             #'car
             (seq-filter
              (lambda (x)
                (unless (string-blank-p str)
                  (or
                   (s-contains-p str (car x) :ignore-case)
                   (s-contains-p str (cdr x) :ignore-case))))
              seq)))))))))

(let* ((coll '(("Affenpinscher" .  "Loyal and amusing")
               ("Akita" . "Ancient Japanese")
               ("Bulldog" . "Kind but courageous")
               ("Caucasian Shepherd" . "Serious guarding breed")
               ("Miniature Schnauzer" . "Long-lived and low-shedding"))))

  ;; completing-read takes different arguments.
  ;; It doesn't take a 'filter' lambda.
  ;; So I need to see what this person was doing.
  ;; (tv (dogs-filter coll))
  (completing-read
   "Select a breed: "
   (dogs-filter coll)))

(comment
 (fz
  '(("Affenpinscher" . "Loyal and amusing")
    ("Akita" . "Ancient Japanese")
    ("Bulldog" . "Kind but courageous")
    ("Caucasian Shepherd" . "Serious guarding breed")
    ("Miniature Schnauzer" . "Long-lived and low-shedding"))
  nil nil
  "Select a breed: "))

(comment
 (fz
  '(("Affenpinscher" "Loyal and amusing")
    ("Akita" "Ancient Japanese")
    ("Bulldog" "Kind but courageous")
    ("Caucasian Shepherd" "Serious guarding breed")
    ("Miniature Schnauzer" "Long-lived and low-shedding"))
  nil nil
  "Select a breed: "))

(provide 'pen-completing-read)
