(library (geiser)
  (export geiser:eval
          geiser:completions
          geiser:module-completions
          geiser:autodoc
          geiser:no-values
          geiser:load-file
          geiser:newline
          geiser:macroexpand)
  (import (chezscheme))

  (define (last-index-of str-list char idx last-idx)
    (if (null? str-list)
        last-idx
        (last-index-of (cdr str-list) char (+ 1 idx) (if (char=? char (car str-list)) idx last-idx))))

  (define (obj-file-name name)
    (let ((idx (last-index-of (string->list name) #\. 0 -1)))
      (if (= idx -1)
          (string-append name ".so")
          (string-append (substring name 0 idx) ".so"))))

  (define (geiser:load-file filename)
    (let ((output-filename (obj-file-name filename)))
      (maybe-compile-file filename output-filename)
      (load output-filename)))

  (define string-prefix?
    (lambda (x y)
      (let ([n (string-length x)])
        (and (fx<= n (string-length y))
             (let prefix? ([i 0])
               (or (fx= i n)
                   (and (char=? (string-ref x i) (string-ref y i))
                        (prefix? (fx+ i 1)))))))))

  (define (geiser:completions prefix . rest)
    rest
    (sort string-ci<?
          (filter (lambda (el)
                    (string-prefix? prefix el))
                  (map write-to-string (environment-symbols (interaction-environment))))))

  (define (write-to-string x)
    (with-output-to-string
      (lambda ()
        (write x))))

  (define (geiser:eval module form . rest)
    rest
    (let ((output-string (open-output-string)))
      (write
       (call/cc
        (lambda (k)
          (with-exception-handler
              (lambda (e)
                (debug-condition e)     ; save the condition for the debugger
                (k `((result "")
                     (output . ,(format "~a~%~a"
                                        (get-output-string output-string)
                                        (with-output-to-string
                                          (lambda ()
                                            (display-condition e)))))
                     (error (key . geiser-debugger)))))
            (lambda ()
              (call-with-values
                  ;; evaluate form, allow for multiple return values,
                  ;; and capture output in output-string.
                  (lambda ()
                    (parameterize ((current-output-port output-string))
                      (if module
                          (eval form (environment module))
                          (eval form))))
                (lambda result
                  `((result ,(with-output-to-string
                               (lambda ()
                                 (pretty-print
                                  (if (null? (cdr result)) (car result) result)))))
                    (output . ,(get-output-string output-string))))))))))
      (newline)
      (close-output-port output-string)))

  (define (geiser:module-completions prefix . rest)
    (define (substring? s1 s2)
      (let ([n1 (string-length s1)] [n2 (string-length s2)])
        (let loop2 ([i2 0])
          (let loop1 ([i1 0] [j i2])
            (if (fx= i1 n1)
                i2
                (and (not (fx= j n2))
                     (if (char=? (string-ref s1 i1) (string-ref s2 j))
                         (loop1 (fx+ i1 1) (fx+ j 1))
                         (loop2 (fx+ i2 1)))))))))
    (filter (lambda (el)
              (substring? prefix el))
            (map write-to-string (library-list))))

  (define (procedure-parameter-list p)
    ;; same as (inspect object), then hitting c
    (let ((s (((inspect/object p) 'code) 'source)))
      (if s
          (let ((form (s 'value)))
            (if (and (list? form)
                     (>= (length form) 2))
                (case (car form)
                  [(lambda) (list (cadr form))]
                  [(case-lambda) (map car (cdr form))]
                  [(record-predicate record-accessor)
                   (list (list (record-type-name (cadr (cadr form)))))]
                  [(record-mutator)
                   (let ([rtd (cadr (cadr form))]
                         [field-idx (caddr form)])
                     (list (list (record-type-name rtd)
                                 (vector-ref (record-type-field-names rtd) field-idx))))]
                  [(record-constructor)
                   (let* ([rcd (cadr (cadr form))]
                          [rtd (((inspect/object rcd) 'ref 'rtd) 'value)])
                     (list (vector->list (record-type-field-names rtd))))]
                  [else #f])
                #f))
          #f)))

  (define (operator-arglist operator)
    (define (make-autodoc-arglist arglist)
      (let loop ([arglist arglist]
                 [optionals? #f]
                 [required '()]
                 [optional '()])
        (cond ((null? arglist)
               `(("required" ,@(reverse required))
                 ("optional" ,@(reverse optional))
                 ("key")
                 ;; ("module" ,module)
                 ))
              ((symbol? arglist)
               (loop '()
                     #t
                     required
                     (cons "..." (cons arglist optional))))
              (else
               (loop
                (cdr arglist)
                optionals?
                (if optionals? required (cons (car arglist) required))
                (if optionals? (cons (car arglist) optional) optional))))))
    (let ([binding (eval operator)])
      (if binding
          (let ([arglists (procedure-parameter-list binding)])
            `(,operator ("args" ,@(map make-autodoc-arglist arglists))))
          '())))


  (define (geiser:autodoc ids . rest)
    (cond ((null? ids) '())
          ((not (list? ids))
           (geiser:autodoc (list ids)))
          ((not (symbol? (car ids)))
           (geiser:autodoc (cdr ids)))
          (else
           (map (lambda (id)
                  (operator-arglist id))
                ids))))

  (define (geiser:no-values)
    #f)

  (define (geiser:newline)
    #f)

  (define (geiser:macroexpand form . rest)
    (with-output-to-string
      (lambda ()
        (pretty-print
         (syntax->datum (expand form)))))))
