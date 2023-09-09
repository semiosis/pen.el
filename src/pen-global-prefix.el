;; Much code borrowed from emacs28/share/emacs/28.0.50/lisp/simple.el.gz

;; The global prefix is like the universal prefix,
;; but uses H-u instead of C-u.

;;;; Prefix commands

(defmacro defset (symbol value &optional documentation)
  "Instead of doing a defvar and a setq, do this. [[http://ergoemacs.org/emacs/elisp_defvar_problem.html][ergoemacs.org/emacs/elisp_defvar_problem.html]]"

  `(progn (defvar ,symbol ,documentation)
          (setq ,symbol ,value)))

(defset global-prefix-command--needs-update nil)
(defset global-prefix-command--last-echo nil)

;; This is OK I think. I need to make it so both prefixes can be used at the same time
(defun internal-echo-keystrokes-prefix ()
  ;; BEWARE: Called directly from C code.
  ;; If the return value is non-nil, it means we are in the middle of
  ;; a command with prefix, such as a command invoked with prefix-arg.
  (sor
   (s-join
    " "
    (-filter
     'identity
     (list
      (if (not prefix-command--needs-update)
          prefix-command--last-echo
        (setq prefix-command--last-echo
              (let ((strs nil))
                (run-hook-wrapped 'prefix-command-echo-keystrokes-functions
                                  (λ (fun) (push (funcall fun) strs)))
                (setq strs (delq nil strs))
                (when strs (mapconcat #'identity strs " ")))))
      (if (not global-prefix-command--needs-update)
          global-prefix-command--last-echo
        (setq global-prefix-command--last-echo
              (let ((strs nil))
                (run-hook-wrapped 'global-prefix-command-echo-keystrokes-functions
                                  (λ (fun) (push (funcall fun) strs)))
                (setq strs (delq nil strs))
                (when strs (mapconcat #'identity strs " "))))))))))

(defset global-prefix-command-echo-keystrokes-functions nil
  "Abnormal hook that constructs the description of the current prefix state.
Each function is called with no argument, should return a string or nil.")

(defun global-prefix-command-update ()
  "Update state of prefix commands.
Call it whenever you change the \"prefix command state\"."
  (setq global-prefix-command--needs-update t))

(defset global-prefix-command-preserve-state-hook nil
  "Normal hook run when a command needs to preserve the prefix.")

(defun global-prefix-command-preserve-state ()
  "Pass the current prefix command state to the next command.
Should be called by all prefix commands.
Runs `global-prefix-command-preserve-state-hook'."
  (prefix-command-preserve-state)
  (run-hooks 'global-prefix-command-preserve-state-hook)
  ;; If the current command is a prefix command, we don't want the next (real)
  ;; command to have `last-command' set to, say, `global-argument'.
  (setq this-command last-command)
  (setq real-this-command real-last-command)
  (global-prefix-command-update))

;;;;; The main prefix command.

;; FIXME: Declaration of `global-prefix-arg' should be moved here!?

(defset global-prefix-arg nil)
(defset current-global-prefix-arg nil)

(add-hook 'global-prefix-command-echo-keystrokes-functions
          #'global-argument--description)
(defun global-argument--description ()
  (when global-prefix-arg
    (concat "H-u"
            (pcase global-prefix-arg
              ('(-) " -")
              (`(,(and (pred integerp) n))
               (let ((str ""))
                 (while (and (> n 4) (= (mod n 4) 0))
                   (setq str (concat str " H-u"))
                   (setq n (/ n 4)))
                 (if (= n 4) str (format " %s" global-prefix-arg))))
              (_ (format " %s" global-prefix-arg))))))

(add-hook 'global-prefix-command-preserve-state-hook
          #'global-argument--preserve)
(defun global-argument--preserve ()
  (setq global-prefix-arg current-global-prefix-arg))

(defset global-argument-map
  (let ((map (make-sparse-keymap))
        (global-argument-minus
         ;; For backward compatibility, minus with no modifiers is an ordinary
         ;; command if digits have already been entered.
         `(menu-item "" global-negative-argument
                     :filter ,(λ (cmd)
                                (if (integerp global-prefix-arg) nil cmd)))))
    (define-key map [switch-frame]
      (λ (e) (interactive "e")
        (handle-switch-frame e) (global-argument--mode)))
    (define-key map [?\H-u] 'global-argument-more)
    (define-key map [?-] global-argument-minus)
    (define-key map [?0] 'global-digit-argument)
    (define-key map [?1] 'global-digit-argument)
    (define-key map [?2] 'global-digit-argument)
    (define-key map [?3] 'global-digit-argument)
    (define-key map [?4] 'global-digit-argument)
    (define-key map [?5] 'global-digit-argument)
    (define-key map [?6] 'global-digit-argument)
    (define-key map [?7] 'global-digit-argument)
    (define-key map [?8] 'global-digit-argument)
    (define-key map [?9] 'global-digit-argument)
    (define-key map [kp-0] 'global-digit-argument)
    (define-key map [kp-1] 'global-digit-argument)
    (define-key map [kp-2] 'global-digit-argument)
    (define-key map [kp-3] 'global-digit-argument)
    (define-key map [kp-4] 'global-digit-argument)
    (define-key map [kp-5] 'global-digit-argument)
    (define-key map [kp-6] 'global-digit-argument)
    (define-key map [kp-7] 'global-digit-argument)
    (define-key map [kp-8] 'global-digit-argument)
    (define-key map [kp-9] 'global-digit-argument)
    (define-key map [kp-subtract] global-argument-minus)
    map)
  "Keymap used while processing \\[global-argument].")

(defun global-argument--mode ()
  (global-prefix-command-update)
  (set-transient-map global-argument-map nil))

(defun global-argument ()
  "Begin a numeric argument for the following command.
Digits or minus sign following \\[global-argument] make up the numeric argument.
\\[global-argument] following the digits or minus sign ends the argument.
\\[global-argument] without digits or minus sign provides 4 as argument.
Repeating \\[global-argument] without digits or minus sign
 multiplies the argument by 4 each time.
For some commands, just \\[global-argument] by itself serves as a flag
that is different in effect from any particular numeric argument.
These commands include \\[set-mark-command] and \\[start-kbd-macro]."
  (interactive)
  ;; (setq last-command-event nil)
  (global-prefix-command-preserve-state)
  (setq global-prefix-arg (list 4))
  (global-argument--mode))

(defun global-argument-more (arg)
  ;; A subsequent H-u means to multiply the factor by 4 if we've typed
  ;; nothing but H-u's; otherwise it means to terminate the prefix arg.
  (interactive "P")
  (let ((arg current-global-prefix-arg))
    (global-prefix-command-preserve-state)
    ;; (ns (str arg))
    (setq global-prefix-arg
          ;; (cond
          ;;  ((consp arg) (list (* 4 (car arg))))
          ;;  ((and (not (consp arg)) (eq arg '-)) (list -4))
          ;;  ((numberp arg) (* 4 arg))
          ;;  ((not arg) 4)
          ;;  (t arg))

          (if (consp arg)
              (list (* 4 (car arg)))
            (if (eq arg '-)
                (list -4)
              arg))))
  (when (consp global-prefix-arg) (global-argument--mode)))

(defun global-negative-argument (arg)
  "Begin a negative numeric argument for the next command.
\\[global-argument] following digits or minus sign ends the argument."
  (interactive "P")
  (let ((arg current-global-prefix-arg))
    (global-prefix-command-preserve-state)
    (setq global-prefix-arg (cond ((integerp arg) (- arg))
                                  ((eq arg '-) nil)
                                  (t '-))))
  (global-argument--mode))

(defun global-digit-argument (arg)
  "Part of the numeric argument for the next command.
\\[global-argument] following digits or minus sign ends the argument."
  (interactive "P")
  (let ((arg current-global-prefix-arg))
    (global-prefix-command-preserve-state)
    (let* ((char (if (integerp last-command-event)
                     last-command-event
                   (get last-command-event 'ascii-character)))
           (digit (- (logand char ?\177) ?0)))
      (setq global-prefix-arg (cond ((integerp arg)
                                     (+ (* arg 10)
                                        (if (< arg 0) (- digit) digit)))
                                    ((eq arg '-)
                                     ;; Treat -0 as just -, so that -01 will work.
                                     (if (zerop digit) '- (- digit)))
                                    (t
                                     digit)))))
  (global-argument--mode))

(define-key global-map (kbd "H-u") 'global-argument)

;; interactive breaks current-global-prefix-arg
;; No, read-string does it
;; Also, cl-defun doesn't make a difference at all.
(cl-defun test-cl-defun (str)
  ;; (interactive (list (pen-read-string "hi")))
  (interactive (list (read-string "test-cl-defun: ")))
  ;; (interactive (list "fkdjlsfk"))
  (message (concat "prefix: " (sor (str current-prefix-arg) "-")
                   ", "
                   "global prefix: " (sor (str global-prefix-arg) "-")
                   ", "
                   "global prefix: " (sor (str current-global-prefix-arg) "-"))))

;; (define-key pen-map (kbd "H-#") 'test-cl-defun)

(defun test-global-prefix ()
  (interactive)
  ;; (prefix-numeric-value '(4))
  (message (concat "prefix: " (sor (str current-prefix-arg) "-")
                   ", "
                   "global prefix: " (sor (str current-global-prefix-arg) "-"))))

;; (define-key global-map (kbd "H-$") 'test-global-prefix)

(defun command-execute (cmd &optional record-flag keys special)
  ;; BEWARE: Called directly from the C code.
  "Execute CMD as an editor command.
CMD must be a symbol that satisfies the `commandp' predicate.

Optional second arg RECORD-FLAG non-nil means unconditionally put
this command in the variable `command-history'.  Otherwise, that
is done only if an arg is read using the minibuffer.

The argument KEYS specifies the value to use instead of the
return value of the `this-command-keys' function when reading the
arguments; if it is nil, `this-command-keys' is used.

The argument SPECIAL, if non-nil, means that this command is
executing a special event, so ignore the prefix argument and
don't clear it."
  (setq debug-on-next-call nil)
  (let ((prefixarg
         (unless special
           ;; FIXME: This should probably be done around
           ;; pre-command-hook rather than here!
           (prog1 prefix-arg
             (setq current-prefix-arg prefix-arg)
             (setq prefix-arg nil)
             (when current-prefix-arg
               (prefix-command-update)))))
        (globalprefixarg
         (unless special
           ;; FIXME: This should probably be done around
           ;; pre-command-hook rather than here!
           (prog1 global-prefix-arg
             (setq current-global-prefix-arg global-prefix-arg)
             (setq global-prefix-arg nil)
             (when current-global-prefix-arg
               (global-prefix-command-update))))))
    (if (and (symbolp cmd)
             (get cmd 'disabled)
             disabled-command-function)
        ;; FIXME: Weird calling convention!
        (run-hooks 'disabled-command-function)
      (let ((final cmd))
        (while
            (progn
              (setq final (indirect-function final))
              (if (autoloadp final)
                  (setq final (autoload-do-load final cmd)))))
        (cond
         ((arrayp final)
          ;; If requested, place the macro in the command history.  For
          ;; other sorts of commands, call-interactively takes care of this.
          (when record-flag
            (add-to-history
             'command-history `(execute-kbd-macro ,final ,prefixarg) nil t))
          (execute-kbd-macro final prefixarg))
         (t
          ;; Pass `cmd' rather than `final', for the backtrace's sake.
          (prog1 (call-interactively cmd record-flag keys)
            (when (and (symbolp cmd)
                       (get cmd 'byte-obsolete-info)
                       (not (get cmd 'command-execute-obsolete-warned)))
              (put cmd 'command-execute-obsolete-warned t)
              (message "%s" (macroexp--obsolete-warning
                             cmd (get cmd 'byte-obsolete-info) "command"))))))))))

(provide 'pen-global-prefix)
