(define-key global-map (kbd "C-M-d") nil)

;; swap M-` and M-~
;; So I can execute commands using M-` and bring up the menu bar ith M-~
(define-key key-translation-map (kbd "<ESC> `") (kbd "<ESC> ~"))
(define-key key-translation-map (kbd "<ESC> ~") (kbd "<ESC> `"))

;; Make it so C-M-x works like C-x
;; To make easier:
;; C-x left
;; C-x right
(define-key key-translation-map (kbd "C-M-x") (kbd "C-x"))

(define-key key-translation-map (kbd "C-M-p") (kbd "<prior>"))
(define-key key-translation-map (kbd "C-M-n") (kbd "<next>"))
(define-key key-translation-map (kbd "C-8") (kbd "DEL"))

(define-key key-translation-map (kbd "<f49>") (kbd "<M-f1>"))
(define-key key-translation-map (kbd "<f50>") (kbd "<M-f2>"))
(define-key key-translation-map (kbd "<f51>") (kbd "<M-f3>"))
(define-key key-translation-map (kbd "<f52>") (kbd "<M-f4>"))

;; Make GUI emacs more like TUI emacs
(define-key key-translation-map (kbd "C-M-SPC") (kbd "C-M-@"))
;; The Insert key produces <insertchar>. This is translating it to a chord
;; (define-key key-translation-map (kbd "<insertchar>") nil)
;; M-TAB and M-C-i produce <insertchar> without any modifications.
;; Therefore, change it to C-M-i so that the GUI functions similarly.
(define-key key-translation-map (kbd "<insertchar>") (kbd "C-M-i"))
(define-key key-translation-map (kbd "C-M-i") nil)
;; What should super-TAB do?
(define-key key-translation-map (kbd "s-TAB") nil)

;; Do this so that the bindings work everywhere, including helm etc.
(define-key key-translation-map (kbd "C-M-k") (kbd "<up>"))
(define-key key-translation-map (kbd "C-M-j") (kbd "<down>"))
(define-key key-translation-map (kbd "C-M-h") (kbd "<left>"))
(define-key key-translation-map (kbd "C-M-l") (kbd "<right>"))

;; [[sps:v +/"(define-key global-map \[execute\]	'execute-extended-command)" "/usr/local/share/emacs/29.4.50/lisp/bindings.el.gz"]]
;; [[sps:v +/"\"find\"," "$MYGIT/emacs/src/keyboard.c"]]

;; I think I should normally select from terminfo function keys,
;; rather than other keys such as media keys,
;; unless I'm just going to use the translation-map, such as with <again>.
;; [[sps:v +/"fkey_table" "$MYGIT/emacs/src/term.c"]]
;; Or perhaps I can recompile term.c
;; [[sps:v +/"{\"@6\", \"create\"},  /\* man:terminfo \*/" "$MYGIT/emacs/src/term.c"]]

;; I should actually assign <menu> a terminfo binding because it's a proper
;; terminfo fkey.

(define-key key-translation-map (kbd "C-M-q") (kbd "<menu>"))
(define-key key-translation-map (kbd "C-M-a") (kbd "<again>"))
;; <LFD> is C-j, so don't use C-M-f

;; [[sps:zrepl tic /root/.emacs.d/host/pen.el/config/xterm-256color.ti]]
;; [[sps:zrepl v /root/.emacs.d/host/pen.el/config/xterm-256color.ti]]

;; [[sps:zrepl tic /root/.emacs.d/host/pen.el/config/screen-256color.ti]]
;; [[sps:zrepl v /root/.emacs.d/host/pen.el/config/screen-256color.ti]]

;; [[sps:zrepl tic /root/.emacs.d/host/pen.el/config/xterm-24bit.ti]]
;; [[sps:zrepl v /root/.emacs.d/host/pen.el/config/xterm-24bit.ti]]

;; https://www.ibm.com/docs/en/zos/3.1.0?topic=syntax-defined-capabilities
;; [[sps:nem man terminfo | grep key_]]

;; Test:
;; [[sps:TERM=screen-256color tput khlp|cat -v|v]]
;; [[sps:TERM=screen-256color tput kcrt|cat -v|v]]

;; S-TAB (shift-TAB) is <backtab>.

;; I might have to actually connect kcrt to <new> in the emacs .c source.

;; DONE:
;; - key_create (need to extend term.c)
;;   - DONE Recompile emacs adding <create>. It now exists.
;;   - Translate <new> (a multimedia key) into <create>, so that keyboards with a New key will use <create>
;;   - DISCARD Bind this to emacs' <new> key and bind that in emacs to C-M-_ which is C-M-/ on the real keyboard
;;   - kcrt=\E[101~
;;     - Hmmm.

;; TODO:
;; There are some interesting terminfo caps I might use such as:
;; - key_move
;;   - Bind this to emacs' <convert> key C-M-d (tmux currently has this bound)
;; - key_reference
;;   - Bind this to emacs' <convert> key C-M-v (tmux currently has this bound)
;; - key_options
;;   - Bind this to emacs' <menu> key C-M-q
;; - key_open
;;   - Bind this to emacs' <open> key with a binding - what should it be ? C-M-i
;; - key_mark
;;   - Bind this to emacs' <C-SPC> key C-@
;; - key_message
;;   - Bind this to emacs' <attn> key 
;; - key_redo (exists in term.c)
;;   - Bind this to emacs' <again> key C-M-a
;; - key_select
;;   - Bind this to emacs' <jump> key C-M-r (tmux currently has this bound)
;; - key_command
;;   - Bind this to emacs' <execute> key C-M-e
;; DONE:
;; - key_print
;;   - It needs a reasonable escape sequence
;;   - key_kprt=\E[7~, is reasonable to me
;;   - OK, I have it working. Now what do I use it for?
;;   - DISCARD Maybe key_kprt=\E[0prt~ would have been better, so I can just add more and more under \E[0. Sadly emacs didn't like this alphanumeric code.
;;     - Rather, do something like \E[101~ and upwards for custom keys.

;; invent some keys?
;; - key_cancel (or key_replace,key_beg,key_restart,key_resume?)
;;   - Bind this to emacs' <mode-change> key C-M-c

;; key_find is actually a real terminfo key according to man:find.
;; So add kfnd (key_find) to the terminfo database.

;; [[sps:infocmp -L1 | v +/help]]
;; (define-key key-translation-map (kbd "C-M-f") (kbd "<LFD>"))
;; I'd like to add key_find to the infocmp database,
;; and use C-M-f as the escape sequence.
;; However, I don't think infocmp uses control characters in the ansi codes.
;; Well, actually, control characters are sometimes used.
;; bell=^G, enter_alt_charset_mode=^N, key_help=\E^],

;; Emacs actually supports terminfo <find>, so could be bound from tmux.
;; As in, could bind in tmux C-M-f to send-keys -H "tput find"
;; rather than or in addition to using the key-translation-map here.
;; Then one day, I could program a mechanical keyboard to have a Find key.
;; [[sps:v +/"{\"@0\", \"find\"},	/\* terminfo \*/" "$MYGIT/emacs/src/term.c"]]
(define-key key-translation-map (kbd "C-M-f") (kbd "<find>"))

;; key_find would look like this:
;; key_find=\E^F,
;; Inside .ti it would look like this:
;; kfnd=\E^F,
;; e:/root/.emacs.d/host/pen.el/config/screen-256color.ti

;; This is where I set up the termcaps
;; e:setup.sh
;; [[sps:zrepl -cd "$PENELD/config" tic screen-256color.ti]]
;; That worked. Now I don't need define-key key-translation-map for C-M-f <find>

;; Also, it might be possible to use an escape code for custom keys
;; like key_backspace's code
;; i.e. key_backspace=\177,

;; I don't know how but C-M-b is already <select>
;; (define-key key-translation-map (kbd "C-M-b") (kbd "<select>"))
(define-key key-translation-map (kbd "C-M-e") (kbd "<execute>"))

(define-key global-map (kbd "<C-M-up>") (df up5 (ekm (s-repeat 5 "<up> "))))
(define-key global-map (kbd "<C-M-down>") (df down5 (ekm (s-repeat 5 "<down>"))))
(define-key global-map (kbd "<C-M-left>") (df left5 (ekm (s-repeat 5 "<left>"))))
(define-key global-map (kbd "<C-M-right>") (df right5 (ekm (s-repeat 5 "<right>"))))

;; [[sps:cat-all-terminfo | grep key_ | sort | uniq | pavs]]
;; This is the actual key_help ansi code
(define-key key-translation-map (kbd "C-M-]") (kbd "<help>"))

;; So that it works outside of tmux
(define-key key-translation-map (kbd "C-M-_") (kbd "<create>"))
;; So that it works in the GUI
(define-key key-translation-map (kbd "C-M-/") (kbd "<create>"))
;; So that it works with keyboards that have a New key (for multimedia)
(define-key key-translation-map (kbd "<new>") (kbd "<create>"))

;; It's still possible to define custom terminfo entries

;; This isn't used anywhere yet
(define-minor-mode pen-disable-keys-mode
  "Disables all keys."
  :lighter " dk"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-g") (lambda ()
                                          (interactive)
                                          (pen-disable-keys-mode -1)))
            (define-key map [t] 'ignore)
            map))

;; Add Hyper and Super
(defun add-event-modifier (string e)
  (let ((symbol (if (symbolp e) e (car e))))
    (setq symbol (intern (concat string
                                 (symbol-name symbol))))
    (if (symbolp e)
        symbol
      (cons symbol (cdr e)))))

(defun superify (prompt)
  (let ((e (read-event)))
    (vector (if (numberp e)
                (logior (lsh 1 23) e)
              (if (memq 'super (event-modifiers e))
                  e
                (add-event-modifier "s-" e))))))

(defun hyperify (prompt)
  (let ((e (read-event)))
    (vector (if (numberp e)
                (logior (lsh 1 24) e)
              (if (memq 'hyper (event-modifiers e))
                  e
                (add-event-modifier "H-" e))))))

(define-key global-map (kbd "C-M-6") nil)             ;For GUI
(define-key function-key-map (kbd "C-M-6") 'superify) ;For GUI
(define-key function-key-map (kbd "C-M-^") 'superify)
(define-key function-key-map (kbd "C-^") 'superify)
(define-key global-map (kbd "C-M-\\") nil) ;Ensure that this bindings isnt taken
(define-key function-key-map (kbd "C-M-\\") 'hyperify)

(provide 'pen-translation-map)
