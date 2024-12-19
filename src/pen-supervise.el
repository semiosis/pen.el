;; - I need supervision for bash scripts invocations first. See: e:supervisor-details
;; - Then I should make supervision for emacs functions. See: e:/root/.emacs.d/host/pen.el/src/pen-supervise.el
;; So I'll need at least two supervisory systems.

;; TODO Turn these into function advice

;; After calling the function, wait for the user to continue operations
(defun supervise-after-call-function (fsymbol message &rest args)
  "The human can interactively supervise the goto-line function.
This way, I can stepwise be sure that I have, for example, gone to the correct line when the goto-line function is called."
  (eval `(apply ,fsymbol ,@args)))

;; TODO Use supervise-after-call-function
;; Example:
;; The external program e:update-emacs-table
;; should RPC to emacs to update a table in
;; an org-file. It has some idea of where the table is.
;; So it runs the function j:goto-line.
;; However, before continuing, the human user needs
;; to confirm this step was successful.
;; In fact, the entire process should be supervised carefully.

;; So, the user goes to the supervisor table,
;; and sees a bunch of pending function calls that need supervising as they come in.
;; If satisfied with the default arguments, then the function is called.
;; The user then has an opportunity to make adjustments before proceeding to the next function call.
;; The external script should actually also be polling/waiting for the supervisor in emacs
;; in order to proceed with the next function call from the external script,
;; which should RPC back to emacs to do the next edit.

;; The supervision user-interface I think should be a part of emacs.
;; I need something like a tabulated list mode like mx:list-processes.

;; e:update-emacs-table

;; Before calling the function, wait for the user to confirm the arguments
(defun supervised-goto-line (line-number instructive-message-to-user)
  "This should be called by a program so that the
human can interactively supervise the goto-line function.
This way, I can stepwise be sure that I have gone to the correct line.")

(defun supervise-before-call-function (fsymbol message &rest args)
  "The human can interactively supervise the goto-line function.
This way, I can stepwise be sure that I have, for example, gone to the correct line when the goto-line function is called."
  (eval `(apply ,fsymbol ,@args)))

(provide 'pen-supervise)
