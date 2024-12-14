(require 'pen-getopts)

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

(provide 'pen-exl)
