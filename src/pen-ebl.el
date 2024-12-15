;; EBL stands for Emacs-Lisp Bash
;; It should be able to generate bash (and maybe POSIX shell)

;; Similar to this:
;; - e:$EMACSD/pen.el/src/pen-epl.el
;; - e:$EMACSD/pen.el/src/pen-epl-test.epl

;; Hmm, so like the embedded j:cl-loop macro or the j:rx macro,
;; within, elisp, have an say an ebl macro (for generating a bash command),
;; and within that, another macro generator but this time, exl,
;; and exl should generate an e:pen-x invocation.
;; Perhaps ebl should do it all, actually.

(defmacro ebl (&rest bashmacros))

(provide 'pen-ebl)
