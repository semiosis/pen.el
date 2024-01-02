(require 'pen-easymenu)

(require 'avy-menu)
;; for an example of how to use avy-menu
(require 'flyspell-correct-avy-menu)
(require 'ace-popup-menu)
(require 'el-patch)

(require 'menu-bar)
;; (popup-menu-normalize-position (point))

;; Example:
;; (define-key flyspell-mode-map (kbd "C-c $") 'flyspell-correct-word-before-point)
;; (defun popup-menu-normalize-position-around-advice (proc position)
;;   (let* ((res (apply proc (list position)))
;;          (pos (car res))
;;          (x (car pos))
;;          (y (cadr pos))
;;          (win (cadr res)))
;;     ;; res
;;     (list (list (+ 1 x) (+ 1 y)) win)))
;; (advice-add 'popup-menu-normalize-position :around #'popup-menu-normalize-position-around-advice)
;; (advice-remove 'popup-menu-normalize-position #'popup-menu-normalize-position-around-advice)
;; The above code fixes flyspell
;; But changing this breaks my lsp mouse click

;; [[cg:avy-menu]]
;; [[cg:ace-popup-menu]]

(setq ace-popup-menu-show-pane-header t)

;; Simply do not invoke x-popup-menu manually.
;; Instead, invoke popup-menu manually.

;; x-popup-menu is designed to return the menu item itself.
;; but it doesn't automatically expand on submenus.
;; Therefore, I need to use popup-menu instead.
;; It would be nice to have a functional x-popup-menu which does submenus.

;; TODO Figure out if I can use popup-menu to return a value instead
;; of run an interactive command.

(co
 (ace-popup-menu-mode t)
 (ace-popup-menu-mode -1)

 (co
  (easy-menu-define testmenu nil "Test Menu" '(("Hello") ("abc") ("def"))))

 (progn
   (defset testmenu nil "Test Menu")
   (easy-menu-do-define 'testmenu nil "Test Menu"
                        '(("Hello")
                          ("abc")
                          ("def"))))

 (windowp
  (get-buffer-window "*Messages*"))

 (co
  ;; if messages were in another currently open frame, make the menu appear on that frame
  (x-popup-menu `((0 0) ,(get-buffer-window "*Messages*")) testmenu))

 (x-popup-menu (get-pos-for-x-popup-menu)
               testmenu)

 (x-popup-menu `((0 0) ,(get-buffer-window))
               (eval
                (easy-menu-define testmenu nil "Test Menu"
                  '(("Hello") ("abc") ("def")))))

 (x-popup-menu `((0 0) ,(get-buffer-window))
               (eval
                (easy-menu-define testmenu nil "Test Menu"
                  ;; The first element of a tuple must be a string, which is the title
                  '("Hello"
                    ("abc")
                    ("def")
                    ("ghi" ("Hello"
                            ("abc")
                            ("def")
                            ("ghi" (yo "jkl"))))))))

 (popup-menu (eval
              (easy-menu-define testmenu nil "Test Menu"
                ;; The first element of a tuple must be a string, which is the title
                '("Hello"
                  ("abc")
                  ("def")
                  ("ghi" ("Hello"
                          ;; This works - I should use vectors for executing functions
                          ["2-abc" alarm-clock--ding]
                          ("2-def")
                          ("2-ghi" (yo "jkl")))))))
             `((0 0) ,(get-buffer-window)))

 ;; This is the way to make menus that return values
 ;; I have to automate this.
 (etv
  (pps
   (popup-menu (eval
                (easy-menu-define testmenu nil "Test Menu"
                  ;; The first element of a tuple must be a string, which is the title
                  '("Hello"
                    ("abc")
                    ("def")
                    ("ghi"
                     ("Hello"
                      ;; This works - I should use vectors for executing functions
                      ["2-abc" (lambda () (interactive) "2-abc")]
                      ["2-def" (lambda () (interactive) "2-def")]
                      ("2-ghi" (yo "jkl")))))))
               (get-pos-for-x-popup-menu))))

 (etv (x-popup-menu (get-pos-for-x-popup-menu)
                    (eval
                     (easy-menu-define my-menu nil "My own menu"
                       '("My Stuff"
                         ["One entry" my-function t]
                         ("Sub Menu"
                          ["My subentry" my-obscure-function t]))))))

 (etv (popup-menu (eval
                   (easy-menu-define my-menu nil "My own menu"
                     '("My Stuff"
                       ["One entry" alarm-clock--ding t]
                       ("Sub Menu"
                        ["My subentry" alarm-clock--ding t]))))
                  (get-pos-for-x-popup-menu)))

 ;; The emacs menu bar uses the x-popup-menu function, and it works - submenus work good
 (comment
  ;; Arguments to x-popup-menu

  ;; Not working
  ;; They simply do not work when invoked through elisp. A mouse event is required for it to function properly.
  (x-popup-menu `((3 16)
                  ,(get-buffer-window))
                '(keymap "My Stuff"
                         (One\ entry menu-item "One entry" my-function)
                         (Sub\ Menu menu-item "Sub Menu"
                                    (keymap "Sub Menu"
                                            (My\ subentry menu-item "My subentry" my-obscure-function)))))


  ;; working (when invoked with mouse, menu bar)
  ;; But not working when invoked with elisp
  ;; But it also works with mx:menu-bar-open
  (x-popup-menu `(config
                  (,(get-buffer-window)
                   (menu-bar)
                   (24 . 0)
                   0))
                '(keymap
                  (cancel-menu menu-item "Cancel" identity-command :help "Cancel out of this menu")
                  (mi-bible-e-outlines menu-item "Bible outlines" bible-e-outlines :help "Open file containing Bible outlines")
                  (mi-bible-e-chapter-titles menu-item "Bible chapter titles" bible-e-chapter-titles :help "Open file containing Bible chapter titles")
                  (mi-bible-open menu-item "Bible open" bible-open :help "Open the Bible")
                  "Bible"))

  ;; Using popup-menu instead of x-popup-menu
  ;; makes this work.
  ;; But I need to switch around the arguments.
  ;; Add advice for this.
  (popup-menu '(keymap
                (cancel-menu menu-item "Cancel" identity-command :help "Cancel out of this menu")
                (mi-bible-e-outlines menu-item "Bible outlines" bible-e-outlines :help "Open file containing Bible outlines")
                (mi-bible-e-chapter-titles menu-item "Bible chapter titles" bible-e-chapter-titles :help "Open file containing Bible chapter titles")
                (mi-bible-open menu-item "Bible open" bible-open :help "Open the Bible")
                "Bible")
              `(config
                (,(get-buffer-window)
                 (menu-bar)
                 (24 . 0)
                 0))))

 (comment
  (defun x-popup-menu-around-advice (proc &rest args)
    (tv args)
    (let ((res (apply proc args)))
      res))
  (advice-add 'x-popup-menu :around #'x-popup-menu-around-advice)
  (advice-remove 'x-popup-menu #'x-popup-menu-around-advice))

 (comment
  (defun x-popup-menu-around-advice (proc &rest args)
    ;; (tv args)
    (let ((res (apply proc args)))
      res))
  (advice-add 'x-popup-menu :around #'x-popup-menu-around-advice)
  (advice-remove 'x-popup-menu #'x-popup-menu-around-advice))

 (x-popup-menu `((0 0) ,(get-buffer-window))
               (eval
                (easy-menu-define openflow2 nil "Openflow2"
                  '("Openflow2"
                    ["download openflow mp image to target" openflow-download-mp-image-to-target t]
                    ["Telnet to target" (telnet target)]
                    "-----"
                    ("Cleanups"
                     ["LP emake_wrapper clean" (openflow-emake-wrapper my-openflow-lp-build-path "clean")]))))))

;; Generating the menu:
;; j:flyspell-correct-avy-menu
;; menu format:
(defvar avy-menu-example-menu
  '("appleg [nil]"
    ;; menu visible title
    ("flyspell correction menu"
     ;; a list of items
     ("apple" "apple")
     ("apples" "apples")
     ("apple g" "apple g")
     ("apple-g" "apple-g")
     ""
     ("Save word" save)
     ("Accept (session)" session)
     ("Accept (buffer)" buffer))))

(co
 (tv (avy-menu "*ace-popup-menu*" avy-menu-example-menu t))
 (ace-popup-menu-mode t)
 (co (tv (x-popup-menu `((0 0) ,(get-buffer-window)) avy-menu-example-menu)))
 ;; (x-popup-menu `((0 0) ,(get-buffer-window)) avy-menu-example-menu)
 (x-popup-menu `(,(tm-cursor-pos-pane 1 1) ,(get-buffer-window)) avy-menu-example-menu)
 (ace-popup-menu-mode -1)
 (co (tv (x-popup-menu `((0 0) ,(get-buffer-window)) avy-menu-example-menu)))
 (x-popup-menu `((0 0) ,(get-buffer-window)) avy-menu-example-menu)
 ;; (x-popup-menu `((0 0) ,(get-buffer-window)) testmenu)
 (x-popup-menu `((0 0) ,(get-buffer-window))
               '(keymap
                 ;; doesn't show the menu title
                 ("Hello")
                 ;; A list of items but these are submenus
                 (abc menu-item "abc" (keymap "abc"))
                 (def menu-item "def" (keymap "def")))))

;; keymap menu (these do not use avy-menu)
;; TODO Convert this format into the regular menu type format
(co
 (keymap
  ("Hello")
  (abc menu-item "abc"
       (keymap "abc"))
  (def menu-item "def"
       (keymap "def"))))

(defun ace-popup-menu (orig-fun position menu)
  "Pop up a menu in a temporary window and return user's selection.

If POSITION is nil or MENU is a keymap or list of keymaps, the
original `x-popup-menu' function is called via ORIG-FUN instead
of `avy-menu'.  To understand the format of the MENU argument,
see documentation for `x-popup-menu'."
  (if (and position
           (not (keymapp menu))
           (not (keymapp (car-safe menu))))
      (avy-menu "*ace-popup-menu*"
                menu
                ace-popup-menu-show-pane-header)
    (funcall orig-fun position menu)))

;; Make a new macro
(co
 (etv
  (pps
   (popup-menu (eval
                (easy-menu-define testmenu nil "Test Menu"
                  ;; The first element of a tuple must be a string, which is the title
                  '("Hello"
                    ("abc")
                    ("def")
                    ("ghi"
                     ("Hello"
                      ;; This works - I should use vectors for executing functions
                      ["2-abc" (lambda () (interactive) "2-abc")]
                      ["2-def" (lambda () (interactive) "2-def")]
                      ("2-ghi" (yo "jkl")))))))
               (get-pos-for-x-popup-menu)))))

;; j:easy-menu-define

(co
 '("Hello"
   ("abc")
   ("def")
   ("ghi"
    ("Hello"
     ("2-abc" "2-abc")
     ("2-def" "2-def")))))

(defun easy-menu2pen-menu (tp)
  (cond ((and (listp tp)
              (> (length tp) 2))
         (cons
          (car tp)
          (loop for stp in (cdr tp) collect
                (easy-menu2pen-menu stp))))
        ((and (listp tp)
              (= 2 (length tp))
              (listp (cadr tp)))
         (list
          (car tp)
          (easy-menu2pen-menu (cadr tp))))
        ((and (listp tp)
              (= 2 (length tp))
              (not (listp (cadr tp))))
         ;; (list2vec tp)
         (let ((l
                (eval `(lambda () (interactive)
                         ,(cadr tp)))))
           (list2vec `(
                       ,(car tp)
                       ,l))))
        (t tp)))

(comment
 (let ((tp '("2-abc" "2-abc")))
   (easy-menu2pen-menu tp))

 (let ((tp '("Hello"
             ("abc")
             ("def")
             ("ghi"
              ("Hello"
               ("2-abc" "2-abc")
               ("2-def" "2-def"))))))
   (easy-menu2pen-menu tp))

 (let ((tp '("Hello"
             ("2-abc" "2-abc")
             ("2-def" "2-def"))))
   (easy-menu2pen-menu tp)))

;; I want a menu system which returns a value instead of executing a command.
;; And I want this to be able to work with ace-popup-menu.
;; but before figuring out how to get ace-popup-menu working (convert keymap menu definitions into regular ones),
;; I should get this working first.
(defmacro pen-menu-define (symbol doc menu)
  ""
  ;; Recursively go through menu, and if there is a leaf node with a non-list second element
  ;; Then turn that whole thing into a vector, and add (lambda () (interactive) ,value)

  `(progn (easy-menu-define ,symbol nil ,doc ,(easy-menu2pen-menu menu))))

(defalias 'pmd 'pen-menu-define)

(co
 (etv
  (pps
   (popup-menu (eval
                (pmd testmenu "Test Menu"
                                 ;; The first element of a tuple must be a string, which is the title
                                 '("Hello"
                                   ("abc")
                                   ("def")
                                   ("ghi"
                                    ("Hello"
                                     ("2-abc" "2-abc")
                                     ("2-def" "2-def"))))))
               (get-pos-for-x-popup-menu)))))

(co
 (etv
  (pps
   (popup-menu (eval
                (pmd testmenu "Test Menu"
                     '("Hello"
                       ("abc")
                       ("def")
                       ("ghi"
                        ("Hello"
                         ("2-abc" "2-abc")
                         ("2-abc"
                          ("interesting" "value"))
                         ("2-def" "2-def"))))))
               (get-pos-for-x-popup-menu)))))

(co
 (etv
  (pps
   (popup-menu (eval
                (easy-menu-define testmenu nil "Test Menu"
                                 ;; The first element of a tuple must be a string, which is the title
                  (easy-menu2pen-menu
                   '("Hello"
                     ("abc")
                     ("def")
                     ("ghi"
                      ("Hello"
                       ("2-abc" "2-abc")
                       ("2-def" "2-def")))))))
               (get-pos-for-x-popup-menu)))))

;; I should probably improve at manipulating sexps anyway
(defun add-as-second-element (s sexps)
  (append (list (car sexps) s )
          (cdr sexps)))

;; (add-as-second-element "second" '(a b c d e))

(defun pen-menu-bar-open ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'start-menu-bar-at-cursor)
    (call-interactively 'menu-bar-open)))

(define-key global-map (kbd "H-`") 'pen-menu-bar-open)

;; This demonstrates that I don't get the status bar documentation for cursor menus
(defun start-menu-bar-at-cursor ()
  (interactive)

  (popup-menu
   ;; TODO Add "Main menu" string as the second element
   (add-as-second-element
    "~ MENU ~"
    (menu-bar-keymap))
   (get-pos-for-x-popup-menu)))

(defun show-menu-bar-keymap ()
  (interactive)
  (etv (pps (menu-bar-keymap))))

(provide 'pen-ace-popup-menu)
