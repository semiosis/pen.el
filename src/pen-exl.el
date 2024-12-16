(require 'pen-getopts)
(require 'pen-dict-key-value)

;; EXL stands for Emacs-Lisp Expect
;; I wonder if I should do build this on TCL generation. Maybe not worth it.

;; It should be able to generate expect scripts
;; by passing arguments to e:pen-x

;; For example, this one:
;; e:watch-fischer-random-chess

;; Similar to this:
;; - e:$EMACSD/pen.el/src/pen-epl.el
;; - e:$EMACSD/pen.el/src/pen-epl-test.epl
;; - e:$EMACSD/pen.el/src/pen-ebl.el

;; TODO Base this on a cli argument generator

;; Also, I should probably combine this with j:pen-ebl.
;; Just gradually build up something which generates bash!

;; Hmm, so like the embedded j:cl-loop macro or the j:rx macro,
;; within, elisp, have an say an ebl macro (for generating a bash command),
;; and within that, another macro generator but this time, exl,
;; and exl should generate an e:pen-x invocation.
;; Perhaps ebl should do it all, actually.

(defvar exl-macro-aliases '())

;; TODO Do an initial car replacement of sexps within
;; to fully qualify the interior macros, as I have done with j:problog-expand
;; or perhaps I can just use a map here.
;; I don't have any yet.
(defmacro exl (&rest xmacros)
  (let ((xm (mapcar
             (lambda (e) `(quote ,e))
             xmacros)))
    `(list
      ;; ,@xm
      ,@xmacros)))
(defalias 'gensh 'exl)

;; I guess that as I'm making these sexp-generator macros,
;; I should make them generic enough to be able to use them outside
;; of bash/x/ebl

(defmacro rpt2 (&rest body)
  ""
  (-flatten (-repeat 2 body)))

(defmacro repeat (n &rest body)
  ""
  (-flatten (-repeat n body)))

(provide 'pen-exl)
