;;;; geiser-gauche.scm -- procedures for Emacs-Gauche interaction

;;; Copyright (C) 2020 András Simonyi
;;; SPDX-License-Identifier: BSD-3-Clause

(define-module geiser
  (use srfi-13)
  (use gauche.interactive)
  (export
   geiser:macroexpand
   geiser:eval
   geiser:newline
   geiser:autodoc
   geiser:load-file
   geiser:compile-file
   geiser:no-values
   geiser:completions
   geiser:module-completions
   geiser:add-to-load-path
   geiser:symbol-documentation
   geiser:symbol-location
   geiser:module-location
   geiser:module-exports))

(select-module geiser)


;;;; Utility functions

;;; Return the list of elements before the dot in a "dotted list" of the form
;;; (x_1 x_2 ... x_n . y).
(define (dotted-list-head dl)
  (if (pair? (cdr dl))
      (cons (car dl) (dotted-list-head (cdr dl)))
      (list (car dl))))

;;; Return the first leaf of a tree.
(define (get-first-leaf tree)
  (if (pair? tree)
      (get-first-leaf (car tree))
      tree))

;;; Add a colon at the beginning to a symbol.
(define (coloned-sym sym)
  (if (string-prefix? ":" (symbol->string sym))
      sym
      (symbol-append ': sym)))

;;; Return the id of a module as symbol.
(define (module-id module)
  (let ((module-repr (write-to-string module)))
    (string->symbol
     (substring module-repr 9 (- (string-length module-repr) 1)))))


;;;; Simple command implementations

(define (geiser:macroexpand form . rest)
  (with-output-to-string
    (cut pprint (macroexpand form))))

(define (geiser:eval module-name form . rest)
  rest
  (guard (err
	  (else
	   (write
	    `((error (key . ,(report-error err #f)))))))
    (let* ((output (open-output-string))
	   (module (or (and (symbol? module-name )
			    (find-module module-name))
		       (find-module 'user)))
	   (result (with-output-to-port output
		     (^ () (eval form module)))))
      (write `((result ,(write-to-string result))
	       (output . ,(get-output-string output)))))))

(define (geiser:load-file filename . rest)
  (geiser:eval 'user `(load ,filename)))

(define (geiser:compile-file filename . rest)
  (geiser:load-file  filename))

(define (geiser:newline . rest)
  (newline))

(define (geiser:no-values . rest)
  (values))

;;; NOTE: We add the load-path at the end. Is this correct?
(define-macro (geiser:add-to-load-path dir)
  `(add-load-path ,dir :after))


;;;; Completions

;;; Return completions for PREFIX for module with MOD-NAME.
;;; MOD-NAME is a symbol. 
(define (geiser:completions prefix mod-name . rest)
  (let* ((module (or (and (symbol? mod-name )
			  (find-module mod-name))
		     (find-module 'user)))
	 (symbols (module-visible-symbols module))
	 (strings (map symbol->string symbols)))
    (filter! (cut string-prefix? prefix <>) strings)))

;;; Return the list of symbols defined by MODULE.
(define (module-symbols module)
  (hash-table-keys (module-table module)))

;;; Return the list of symbols visible from MODULE.
(define (module-visible-symbols module)
  (let* ((imports (module-imports module))
	 (inherits (module-precedence-list module))
	 (imported-syms (concatenate!
			 (map module-exports imports)))
	 (inherited-syms (concatenate!
			  (map module-symbols inherits)))
	 (own-syms (module-symbols module)))
    (delete-duplicates! (concatenate!
			 (list imported-syms inherited-syms own-syms)))))

(define (geiser:module-completions prefix . rest)
  (filter
   (cut string-prefix? prefix <>)
   (map (^x (symbol->string (module-name x)))
	(all-modules))))

;;;; Symbol information

;;; Return the signature of SYMBOL in MODULE if there is one, SYMBOL if the
;;; symbol is bound without one, #f otherwise.
(define (signature-in-module symbol module)
  (if (hash-table-get (module-table module) symbol #f)
      (let1 obj (global-variable-ref module symbol)
	    (if (is-a? obj <procedure>)
		(~ obj 'info)
		symbol))
      #f))

;;; Return a list of symbol-infos, i.e., (SIGNATURE-OR-SYMBOL MODULE) pairs for
;;; all bindings of SYMBOL. SIGNATURE-OR-SYMBOL is the signature of SYMBOL in
;;; MODULE if it can be found, and SYMBOL otherwise.
(define (symbol-infos symbol)
  (let ((signatures-w-modules
	 (map (^x (cons (signature-in-module symbol x)
			(module-id x)))
	      (all-modules))))
    (remove (^x (not (car x)))
	    signatures-w-modules)))

;;; Format a symbol-info list for presenting with symbol documentation
(define (format-symbol-infos symbol-infos)
  (map (^x `(,(cdr x) ,(if (pair? (car x))
			   (car x)
			   `(,(car x) "..."))))
       symbol-infos))

(define (geiser:symbol-documentation symbol . rest)
  `(("signature" ,(format-symbol-infos (symbol-infos symbol)))))

(define (geiser:symbol-location symbol pref-module)
  (let* ((module (or pref-module 'user))
	 (obj (global-variable-ref module symbol #f)))
    (or (and-let* (obj
		   ((or (is-a? obj <procedure>)
			(is-a? obj <generic>)))
		   (sl (source-location obj))
		   (file (car sl))
		   ((string-contains file "/"))
		   ((not (string-contains file "./")))
		   (line (cadr sl)))
	  `(("file" . ,file) ("line" . ,line) ("column")))
	'(("file") ("line") ("column")))))


;;;; Autodoc

(define (geiser:autodoc symbols pref-module . rest)
  (map (cut formatted-autodoc <> pref-module)
       symbols))

(define (formatted-autodoc symbol pref-module)
  (format-autodoc-symbol-info
   (autodoc-symbol-info symbol pref-module)))

;;; Return a (SIGNATURE-OR-SYMBOL MODULE) pair or SYMBOL itself to be used in the
;;; autodoc for SYMBOL. SIGNATURE-OR-SYMBOL is a signature of SYMBOL in MODULE if
;;; it can be found, and SYMBOL otherwise. Only SYMBOL and not a pair is returned
;;; if no suitable bindings were found. Prefer the binding which is visible from
;;; module PREF-MODULE, which should be a symbol.
(define (autodoc-symbol-info symbol pref-module)
  (let1 sis (symbol-infos symbol)
	(if (not (null? sis))
	    (or (find (^x (eq? (global-variable-ref pref-module symbol #f)
			       (global-variable-ref (cdr x) symbol #f)))
		      sis)
		(find (^x ($ not $ symbol? $ car x)) sis)
		(car sis))
	    symbol)))


;;; Format an autodoc symbol-info in autodoc format.
(define (format-autodoc-symbol-info asi)

  (define (format-normal-arg-info arg-info)
    (let ((required '("required"))
	  (optional '("optional"))
	  (key '("key"))
	  (section :required)
	  (arg-no 0))
      (dolist (x arg-info)
	      (if (memq x '(:optional :key :rest))
		  (set! section x)
		  (begin
		    (inc! arg-no)
		    (case section
		      ((:optional) (push! optional x))
		      ((:key) (push! key
				     (cons (coloned-sym (get-first-leaf x))
					   arg-no)))
		      ((:rest) (push! required "..."))
		      (else (push! required x))))))
      (map (cut reverse <>)
	   (list required optional key))))

  (define (process-dotted-arg-info arg-info)
    `(,(if (symbol? arg-info)
	   '("required" "...")
	   `("required" ,@(dotted-list-head arg-info) "..."))
      ("optional")
      ("key")))

  (if (symbol? asi)
      (list asi)
      (let ((sig (car asi)) (module (cdr asi)))
	(if (symbol? sig)
	    `(,sig ("args" (("required" "...")))
		   ("module" ,module))
	    `(,(car sig)
	      ("args"
	       ,((if (list? sig)
		     format-normal-arg-info
		     process-dotted-arg-info)
		 (cdr sig)))
	      ("module" ,module))))))


;;;; Module information

(define (geiser:module-exports mod-name . rest)
  (let* ((module (find-module mod-name))
	 (symbols (module-exports module))
	 (syms-objs
	  (sort
	   (map (^x (cons x (global-variable-ref module x)))
		symbols)
	   string>? (^x (symbol->string (car x)))))
	 (procs ()) (macros ()) (vars ()))
    (dolist (sym-obj syms-objs)
	    (let ((obj (cdr sym-obj))
		  (sym (car sym-obj)))
	      (cond
	       ((or (is-a? obj <generic>)
		    (is-a? obj <procedure>))
		(push! procs
		       (list sym (cons "signature"
				       (remove (^x (and (pair? x)
							(string? (car x))
							(string= "module" (car x))))
					(formatted-autodoc sym mod-name))))))
	       ((or (is-a? obj <macro>)
		    (is-a? obj <syntax>))
		(push! macros (list sym)))
	       (else (push! vars (list sym))))))
    `(list ("modules") ("procs" . ,procs) ("syntax" . ,macros) ("vars" . ,vars))))

(define (geiser:module-location m . rest)
  (and (find-module m)
       (let1 paths (map cdr (library-fold m acons '()))
	     (if (pair? paths)
		 `(("file" . ,(car paths)) ("line") ("column"))
		 '(("file") ("line") ("column"))))))
