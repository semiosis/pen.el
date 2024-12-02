#lang racket
((lambda (fun)
   (fun
    (let-syntax ([syn (lambda (stx)     ; fix 1: add [...]
                        #'23)])   ; fix 2: add syntax
      (syn (fun 1) 20))))
 (lambda (x) (+ x 1)))
