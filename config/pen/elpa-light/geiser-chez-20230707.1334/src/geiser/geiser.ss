;;; geiser.ss -- emacs/scheme interface

;; Copyright (c) 2022 Jose A Ortega Ruiz

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the Modified BSD License. You should
;; have received a copy of the license along with this program. If
;; not, see <http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5>.

;; Start date: Tue Apr 26 22:27:26 2016 +0200

(library (geiser)
  (export geiser:eval
          geiser:ge:eval
          geiser:completions
          geiser:module-completions
          geiser:autodoc
          geiser:no-values
          geiser:load-file
          geiser:newline
          geiser:macroexpand
          geiser:symbol-location
          geiser:module-location
          geiser:add-to-load-path
          geiser:symbol-documentation
          quote)

  (import (chezscheme))
  (import (geiser-data))

  (define-syntax as-string
    (syntax-rules () ((_ b ...) (with-output-to-string (lambda () b ...)))))

  (define (write-to-string x) (as-string (write x)))

  (define (pretty-string x)
    (parameterize ((print-extended-identifiers #t)
                   (print-vector-length #t))
      (as-string (pretty-print x))))

  (define (code-location obj)
    (let* ((i (inspect/object obj))
           (c (and i (not (eq? 'simple (i 'type))) (i 'code))))
      (if c
          (let ((name `("name" . ,(or (c 'name) (write-to-string obj)))))
            (call-with-values (lambda () (c 'source-path))
              (case-lambda
                ((path line col)
                 `(,name ("file" . ,path) ("line" . ,line) ("column" . ,col)))
                ((path char)
                 `((,name) ("file" . ,path) ("char" . ,char)))
                (() #f))))
          #f)))

  (define (condition-location c)
    (let ((finder (make-object-finder procedure? c (collect-maximum-generation))))
      (let loop ((obj (finder)) (res '()))
        (if obj
            (let ((loc (code-location (car obj))))
              (loop (finder) (if loc (cons loc res) res)))
            res))))

  (define (call-with-result thunk)
    (let ((output (open-output-string)))
      (write
       (call/cc
        (lambda (k)
          (with-exception-handler
              (lambda (e)
                (debug-condition e) ; save the condition for the debugger
                (let ((loc (or (condition-location e) '()))
                      (desc (as-string (display-condition e))))
                  (k `((result "")
                       (output . ,(get-output-string output))
                       (error (key . condition)
                              (msg . ,(cons desc loc)))))))
            (lambda ()
              (call-with-values
                  (lambda ()
                    (parameterize ((current-output-port output)) (thunk)))
                (lambda result
                  `((result ,(write-to-string
                              (if (null? (cdr result)) (car result) result)))
                    (output . ,(get-output-string output))))))))))
      (newline)
      (close-output-port output)))

  (define (last-index-of str-list char idx last-idx)
    (if (null? str-list)
        last-idx
        (last-index-of (cdr str-list) char (+ 1 idx)
                       (if (char=? char (car str-list)) idx last-idx))))

  (define (with-extension name ext)
    (let ((idx (last-index-of (string->list name) #\. 0 -1)))
      (if (= idx -1)
          (string-append name ext)
          (string-append (substring name 0 idx) ext))))

  (define (obj-file-name name) (with-extension name ".so"))

  (define (file-directory filename)
    (let ((idx (last-index-of (string->list filename) #\/ 0 -1)))
      (if (= idx -1) filename (substring filename 0 idx))))

  (define (library-source-filename id)
    (let ((obj (library-object-filename id)))
      (let loop ((exts (if obj (map car (library-extensions)) '())))
        (cond ((null? exts) #f)
              ((file-exists? (with-extension obj (car exts)))
               (with-extension obj (car exts)))
              (else (loop (cdr exts)))))))

  (define string-prefix?
    (lambda (x y)
      (let ([n (string-length x)])
        (and (fx<= n (string-length y))
             (let prefix? ([i 0])
               (or (fx= i n)
                   (and (char=? (string-ref x i) (string-ref y i))
                        (prefix? (fx+ i 1)))))))))

  (define current-library (make-parameter #f))

  (define (transitive-env . lib)
    (let ((lib (if (null? lib) (current-library) (car lib))))
      (and lib (apply environment lib (library-requirements lib)))))

  (define (current-libraries)
    (and (current-library)
         (cons (current-library) (library-requirements (current-library)))))

  (define (known-symbols)
    (if (current-library)
        (apply append (map library-exports (current-libraries)))
        (environment-symbols (interaction-environment))))

  (define symbol-lib
    (case-lambda
      ((s) (cond ((current-libraries) => (lambda (ls) (symbol-lib s ls)))
                 ((memq s (known-symbols)) (symbol-lib s (library-list)))
                 (else #f)))
      ((s l) (cond ((null? l) #f)
                   ((memq s (library-exports (car l))) (car l))
                   (else (symbol-lib s (cdr l)))))))

  (define (add-reverse-deps! deps lib)
    (for-each (lambda (dep)
                (let ((rdeps (hashtable-ref deps dep '())))
                  (when (not (member lib rdeps))
                    (hashtable-set! deps dep (cons lib rdeps)))))
              (library-requirements lib)))

  (define (add-reverse-deps*! deps libs)
    (when (not (null? libs))
      (add-reverse-deps*! deps (cdr libs))
      (add-reverse-deps! deps (car libs))))

  (define reverse-lib-deps
    (let ((deps (make-hashtable equal-hash equal?)))
      (add-reverse-deps*! deps (library-list))
      deps))

  (define (reverse-deps lib) (hashtable-ref reverse-lib-deps lib '()))

  (define not-found (gensym))

  (define (try-eval sym)
    (call/cc
     (lambda (k)
       (with-exception-handler (lambda (e) (k not-found))
         (let ((env (transitive-env)))
           (lambda () (if env (eval sym env) (eval sym))))))))

  (define (compile-and-load lib)
    (let ((scm (if (string? lib) lib (library-source-filename lib))))
      (when scm
        (let ((obj (obj-file-name scm)))
          (parameterize ([current-directory (file-directory scm)]
                         [compile-file-message #f])
            (compile-file scm obj)
            (load obj)))
        (for-each compile-and-load (reverse-deps lib)))))

  (define (geiser:load-file filename lib)
    (let ((output-filename (obj-file-name filename)))
      (call-with-result
       (lambda ()
         (compile-and-load filename)
         (when lib
           (for-each compile-and-load (reverse-deps lib))
           (add-reverse-deps! reverse-lib-deps lib))))))

  (define (geiser:add-to-load-path path)
    (let ((p (cons path path)))
      (library-directories (cons p (remove p (library-directories))))))

  (define (geiser:eval lib form)
    (call-with-result
     (lambda ()
       (let ((env (transitive-env lib)))
         (if env (eval form env) (eval form))))))

  (define (geiser:ge:eval lib form)
    (parameterize ([current-library lib])
      (call-with-result (lambda () (eval form (environment '(geiser)))))))

  (define (geiser:completions prefix)
    (sort string-ci<?
          (filter (lambda (el) (string-prefix? prefix el))
                  (map symbol->string (known-symbols)))))

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

  (define (arity->parameter-list p)
    (define (nparams n)
      (map (lambda (n) (string->symbol (format "x~a" n))) (iota n)))
    (define (add-opt pl)
      (cons (append (if (null? pl) '() (car pl)) '(...)) pl))
    (let* ((m (procedure-arity-mask p))
           (pm (if (< m 0) (+ 1 (lognot m)) m))
           (n (if (> pm 0) (/ (log pm) (log 2)) 0)))
      (let loop ((k 1) (pl '()))
        (cond ((> k n) (reverse (if (< m 0) (add-opt pl) pl)))
              ((logbit? k pm) (loop (+ k 1) (cons (nparams k) pl)))
              (else (loop (+ k 1) pl))))))

  (define (source->parameter-list p)
    ;; same as (inspect object), then hitting c
    (let* ((s (((inspect/object p) 'code) 'source))
           (form (and s (s 'value))))
      (and (list? form)
           (>= (length form) 2)
           (case (car form)
             [(lambda) (list (cadr form))]
             [(case-lambda) (map car (cdr form))]
             [(record-predicate record-accessor)
              (list (list (record-type-name (cadr (cadr form)))))]
             [(record-mutator)
              (let ([rtd (cadr (cadr form))]
                    [field-idx (caddr form)])
                (list (list (record-type-name rtd)
                            (vector-ref (record-type-field-names rtd)
                                        field-idx))))]
             [(record-constructor)
              (let* ([rcd (cadr (cadr form))]
                     [rtd (((inspect/object rcd) 'ref 'rtd) 'value)])
                (list (vector->list (record-type-field-names rtd))))]
             [else #f]))))

  (define (value->string x)
    (define max-len 80)
    (define sub-str "...")
    (define sub-len (- max-len (string-length sub-str)))
    (let* ((s (pretty-string x))
           (l (string-length s)))
      (if (<= l max-len) s (string-append (substring s 0 sub-len) sub-str))))

  (define (id-autodoc id)
    (define (procedure-parameter-list id p)
      (and (procedure? p)
           (or (source->parameter-list p)
               (symbol-signatures id)
               (arity->parameter-list p))))
    (define (autodoc-arglist* args req)
      (cond ((null? args) (list (list* "required" (reverse req))))
            ((pair? args) (autodoc-arglist* (cdr args) (cons (car args) req)))
            (else `(("required" . ,(reverse req))
                    ("optional" ,args)))))
    (define (autodoc-arglist arglist) (autodoc-arglist* arglist '()))
    (define (signature as lib)
      `(,id ("args" ,@(map autodoc-arglist as))
            ,@(if (and (not (null? lib)) (not (equal? '(chezscheme) lib)))
                  (list (cons "module" (write-to-string lib)))
                  '())))
    (let* ((lib (symbol-lib id))
           (binding (and lib (try-eval id))))
      (cond ((and binding (not (eq? binding not-found)))
             (let ([as (procedure-parameter-list id binding)])
               (if as
                   (signature as lib)
                   `(,id ("value" . ,(value->string binding))))))
            ((and lib (symbol-signatures id)) => (lambda (a) (signature a '())))
            (else (list id)))))

  (define (geiser:autodoc ids)
    (cond ((null? ids) '())
          ((not (list? ids)) (geiser:autodoc (list ids)))
          ((not (symbol? (car ids))) (geiser:autodoc (cdr ids)))
          (else (map id-autodoc ids))))

  (define (geiser:symbol-location id)
    (let ([b (try-eval id)])
      (or (and (not (eq? not-found b)) (code-location b)) '())))

  (define (geiser:module-location id)
    (let ((f (library-source-filename id)))
      (if f `(("file" . ,f)) '())))

  (define (docstr lib id)
    (format "A ~a defined in library ~a"
            ((or (inspect/object (try-eval id)) (lambda (x) "value")) 'type)
            lib))

  (define (geiser:symbol-documentation id)
    (let ((lib (symbol-lib id)))
      (and lib
           `(("docstring" . ,(docstr lib id))
             ("signature" . ,(id-autodoc id))
             ("labels" . ,(symbol-labels id))))))

  (define geiser:no-values void)
  (define geiser:newline newline)

  (define (geiser:macroexpand form . rest)
    (with-output-to-string
      (lambda () (pretty-print (syntax->datum (expand form)))))))
