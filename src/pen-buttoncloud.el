(require 'pen-glossary)
(require 'pen-custom-conf)

;; TODO Move into pen-status-buttoncloud.el

;; toggle-no-external-handler

;; Turned off so it's red. It turns things on
(defsetface off-button-face
  '((t :foreground "#222222"
       :background "#444444"
       :weight bold
       :underline t))
  "Face for off buttons.")

(defsetface on-button-face
  '((t :foreground "#444444"
       :background "#00aa00"
       :weight bold
       :underline t))
  "Face for on buttons.")

(defsetface unk-button-face
  '((t :foreground "#aa00aa"
       :background "#222222"
       :weight bold
       :underline t))
  "Face for unknown state buttons.")


(defsetface glossary-button-face
  '((t :foreground "#3fa75f"
       :background "#2e2e2e"
       :weight bold
       :underline t))
  "Face for glossary buttons.")


;; Objectives
;; - Toggle things from pen-rc
;; - Toggle variables
;; - Toggle modes
;; - Toggle scripts


;; TODO Make 2 button types -- an 'enable' and a 'disable'
(define-button-type 'glossary-button 'follow-link t 'help-echo "Click to go to definition" 'face 'glossary-button-face)
(define-button-type 'on-button 'follow-link t 'help-echo "Click to turn off" 'face 'on-button-face)
(define-button-type 'off-button 'follow-link t 'help-echo "Click to turn on" 'face 'off-button-face)
(define-button-type 'unk-button 'follow-link t 'help-echo "Click to toggle" 'face 'unk-button-face)

(defun create-buttoncloud (button-name-action-tuples-list &optional prompt implicitquit)
  (with-output-to-temp-buffer "*button cloud*"
    (with-current-buffer "*button cloud*"
      (if prompt
          (insert (concat prompt "\n")))
      (let ((consecutive))
        (cl-loop
         for
         bt
         in
         button-name-action-tuples-list
         do
         (progn
           (if consecutive (insert " "))
           (if implicitquit
               (insert-button (car bt)
                              ;; 'type
                              ;; 'glossary-button
                              'action (eval `(lambda (b)
                                               ;; Quit before or after?
                                               (quit-window) (funcall ,(cdr bt) b))))
             (insert-button (car bt)
                            'type
                            'on-button
                            'action
                            (eval (macroexpand (cdr bt)))))
           (setq consecutive t))))
      (if prompt (call-interactively 'forward-button))))
  (with-current-buffer "*button cloud*"
    (if prompt (call-interactively 'forward-button))))

(defmacro if-bc-yn (ify &optional ifn prompt)
  `(create-buttoncloud '(("Yes" . (lambda (b) (interactive) (quit-window) ,ify))
                         ("No" . (lambda (b) (interactive) (quit-window) ,ifn)))
                       ,prompt))

(defun test-cb-yn ()
  (interactive)

  (if-bc-yn
   (message "Yes, my good sir") (message "No, my good sir")
   "Talk?"))

;; TODO Ensure that when I create a button it's value is represented by how it looks
;; Therefore, I must create associations between the variable, the button and the function

;; Determiner is some elisp which when evaluated, will return the state
;; It could be a variable or function invocation
;; (defmacro deftogglebuttonl (determiner enablecode disablecode)
;;   `(list
;;     (lambda (b)
;;       (let ((bt (button-get b 'type)))
;;         (if (eq bt 'on-button)
;;             (progn
;;               (button-put b 'type 'off-button)
;;               ,disablecode)
;;           (progn
;;             (button-put b 'type 'on-button)
;;             ,enablecode))))))

;; A button is defined by
;; - a type
;; - the require parameters for that type
;; - The required parameters could be provided in the form of properties on each button?
;;   - When defining a button in create-buttoncloud, the last parameter should be a list of properties to add to the button
;; I want to reuse functions

;; TODO Create the constructors first and make the create-buttoncloud function fit to those constructors

;; What types of buttons do I want?
;; - status
;;   - An external process updates the button in real time?
;;     - Yes, use a callback. It will be far more efficient.
;;     - Perhaps a timer to check on the status would be better? -- That might be a hog
;;   - cooldown with a timer?
;;   - maybe I want buttons which are associated with an asynchronous process that sends back 
;; - toggle

;; (defun test-buttoncloud-new ()
;;   (interactive)
;;   ;; If the first value is a variable then assume it is a toggle button for a variable
;;   ;; If the first value is a function then assume it is a toggle button for a function that toggles, such as a mode function
;;   ;; If the first value is a string then it's assumed

;;   ;; (create-buttoncloud `((toggle-no-external-handler)))
;;   )

;; (defmacro deftogglebuttonvar (varsym)
;;   (let ((varname (sym2str (eval varsym))))
;;     (deftogglebuttonl
;;       (setq))))

;; (defmacro make-toggle-button-value (&rest body)
;;   `(progn (,@body) nil))

;; TODO Create lambdas for the timers. The state is provided in the form of literals within the lambda


;; (deftogglebuttonl
;;   (message "enabled")
;;   (message "disabled"))


;; Initiate a timer with a function and a state.
;; I want some kind of function object that I can call but that has its own state.
;; I want to be able to create them like lambdas.


;; TODO Create a timer which updates a button asynchronously

(provide 'pen-buttoncloud)
