#!/usr/bin/env -S sbcl-ql --script
;; #!sbcl --script

(ql:quickload "external-program" :silent t)

;; This gets me 'defmacro'
(ql:quickload "serapeum")

;; quicklisp after being set up in ros sbcl is admittedly slow,
;; but I'm sure I will have these scripts running much faster
;; later on.

;; (write-string "Hello, World!")

;; (ql:quickload "unix-opts")
;; 
;; (opts:define-opts
;;     (:name :help
;;        :description "print this help text"
;;        :short #\h
;;        :long "help")
;;     (:name :nb
;;        :description "here we want a number argument"
;;        :short #\n
;;        :long "nb"
;;        :arg-parser #'parse-integer) ;; <- takes an argument
;;     (:name :info
;;        :description "info"
;;        :short #\i
;;        :long "info"))

;; j:bible-mode-book-chapters
(defparameter *bible-mode-book-chapters*
  '(("Genesis" . 50)
    ("Exodus" . 40)
    ("Leviticus" . 27)
    ("Numbers" . 36)
    ("Deuteronomy" . 34)
    ("Joshua" . 24)
    ("Judges" . 21)
    ("Ruth" . 4)
    ("I Samuel" . 31)
    ("II Samuel" . 24)
    ("I Kings" . 22)
    ("II Kings" . 25)
    ("I Chronicles" . 29)
    ("II Chronicles" . 36)
    ("Ezra" . 10)
    ("Nehemiah" . 13)
    ("Esther" . 10)
    ("Job" . 42)
    ("Psalms" . 150)
    ("Proverbs" . 31)
    ("Ecclesiastes" . 12)
    ("Song of Solomon" . 8)
    ("Isaiah" . 66)
    ("Jeremiah" . 52)
    ("Lamentations" . 5)
    ("Ezekiel" . 48)
    ("Daniel" . 12)
    ("Hosea" . 14)
    ("Joel" . 3)
    ("Amos" . 9)
    ("Obadiah" . 1)
    ("Jonah" . 4)
    ("Micah" . 7)
    ("Nahum" . 3)
    ("Habakkuk" . 3)
    ("Zephaniah" . 3)
    ("Haggai" . 2)
    ("Zechariah" . 14)
    ("Malachi" . 4)
    ("Matthew" . 28)
    ("Mark" . 16)
    ("Luke" . 24)
    ("John" . 21)
    ("Acts" . 28)
    ("Romans" . 16)
    ("I Corinthians" . 16)
    ("II Corinthians" . 13)
    ("Galatians" . 6)
    ("Ephesians" . 6)
    ("Philippians" . 4)
    ("Colossians" . 4)
    ("I Thessalonians" . 5)
    ("II Thessalonians" . 3)
    ("I Timothy" . 6)
    ("II Timothy" . 4)
    ("Titus" . 3)
    ("Philemon" . 1)
    ("Hebrews" . 13)
    ("James" . 5)
    ("I Peter" . 5)
    ("II Peter" . 3)
    ("I John" . 5)
    ("II John" . 1)
    ("III John" . 1)
    ("Jude" . 1)
    ("Revelation of John" . 22)))

;; (write-string (format t "~&~S~&" *posix-argv*))

;; (external-program:run "nw" '("vim"))



#+(or)
(external-program:run "nw" '("vim"))

#+(or)
(external-program:run "tv" '("") :input "hi")


(setf (fdefinition 'doc) #'documentation)


(defun str (o)
  "Convert object to string"  
  #+(or)
  (format nil "~&~S~&" o)
  (write-to-string o))

(defun tv (stdin &optional (tm_wincmd "sps"))
  "tv"
  (with-output-to-string (out) 
    (external-program:run "tv" '()

                          ;; :input *standard-input*
                          :input (make-string-input-stream stdin)

                          ;; :output *standard-output*
                          :output out)))

(let* ((args
         (cdr
          *posix-argv*))
       (bookname
         (if args
             #+(or)
             (string-trim
              '(#\space
                #\newline)
              ;; (format nil "~&~S~&" args)
              (write-to-string args))
             (car args)
             "Genesis")))

  ;; (write-string bookname)
  ;; (tv bookname)
  ;; (tv (car (cdr *posix-argv*)))

  (if bookname
      (progn
        *bible-mode-book-chapters*

        ;; (assoc "Genesis" *bible-mode-book-chapters* :test #'string=)

        (let ((res
                (assoc bookname *bible-mode-book-chapters* :test #'string=)))
          ;; (write-string
          ;;  (format nil "~&~S~&"
          ;;          (cdr res)))
          (write-string
           (write-to-string
            (cdr res)))))))

;; bookname=$1""
;; test -n "$bookname" || exit 1
