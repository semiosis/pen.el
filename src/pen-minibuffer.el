(require 'miniedit)

;; This is taken now
;; (define-key minibuffer-local-map (kbd "C-M-f") #'miniedit)
(define-key minibuffer-local-map (kbd "C-c '") #'miniedit)


(define-key minibuffer-local-map (kbd "M-g") #'keyboard-quit)

;; Do I want ex mode to be accessible from the minibuffer?
;; No. I can't do subsitutions, so it's just a nuisance
(define-key minibuffer-local-map (kbd "M-;") (pen-lm (pen-beep)))

;; This doesn't save and I don't need it because I'm using the evil-minibuffer for saving
;; (define-key minibuffer-local-map (kbd "M-;") '(λ () (interactive) (ignore-errors (exit-minibuffer) (pen-save-buffer))))


;; This changes the mode. I don't want this.
;; (add-hook 'miniedit-mode-hook (pen-lm (emacs-lisp-mode)))

(add-hook 'miniedit-mode-hook (pen-lm (pen-lisp-mode 1)))


;; Added C-c ' keybinding
(defun miniedit ()
  "The main miniedit function."
  (interactive)
  (let ((miniedit-string miniedit-string)
          (minibufname (buffer-name))
          )
    (save-excursion
      ;; so that it can be redefined below..
      (makunbound 'miniedit-mode-map)
      (easy-mmode-define-minor-mode
       miniedit-mode
       "The mode to inherit minibuffer keybindings"
       nil
       " MINI"
       ;; 3 means C-c
       ;; 16 means C-p
       (list 'keymap (cons 16 (current-local-map))))
      (define-key miniedit-mode-map (kbd "C-c C-c") 'exit-recursive-edit)
      (define-key miniedit-mode-map (kbd "C-c '") 'exit-recursive-edit)
      (let ((contents
               (miniedit-recursive-edit
                ""
                (progn
                    (setq miniedit-string
                          (minibuffer-contents-no-properties))
                    (when (and
                             (stringp miniedit-string)
                             miniedit-before-edit-kill-p)
                      (kill-new miniedit-string))
                    (when
                        miniedit-before-edit-function
                      (miniedit-withit
                       (funcall miniedit-before-edit-function
                                  miniedit-string)
                       (when it (setq miniedit-string it))))
                    (run-hooks 'miniedit-before-editing-hook)
                    miniedit-string))))
          (delete-other-windows)
          (other-window 1)
          (miniedit-set-minibuffer-contents contents minibufname)))))


;; (defun minibuccer-bg ()
;;   (set (make-local-variable 'face-remapping-alist)
;;        '((default :background "#222222"))))

;; (defun minibuffer-bg ()
;;   (set (make-local-variable 'face-remapping-alist)
;;        '((default :foreground "#992222" :background "#110000"))))

(defun minibuffer-bg ()
  (set (make-local-variable 'face-remapping-alist)
       '((default :foreground "#ff1133" :background "#111111"))))
(add-hook 'minibuffer-setup-hook 'minibuffer-bg)




(defun miniedit-recursive-edit (msg &optional content)
  "Enter recursive edit to permit a user to edit long contents..
Useful when the original contents are in a minibuffer.  Transfer those
contents to a new buffer and edit them there.

MSG is a message, which is displayed in a Edit buffer.
Mostly copied from `checkdoc-recursive-edit'.
CONTENT is the content to be edited..
Then, returns a string...

Optimized for being called when the current buffer is a minibuffer.."
  (let ((this-buffer (buffer-name))
	(new-content content)
	save-content
	(errorp nil)
	)
    (save-excursion
      (other-window 1)
      (switch-to-buffer "*Miniedit*")
      (set-buffer "*Miniedit*")
      (setq save-content (buffer-substring (point-min) (point-max)))
      (delete-region (point-min) (point-max))
      ;; I must not enable text mode because my glossary / annotate hooks break it. I think it was annotate
      ;; (text-mode)
      (emacs-lisp-mode)
      (miniedit-mode t)
      (let ((fill-column (- fill-column
			                      (eval miniedit-fill-column-deduction))))
	      (if (stringp content) (insert content)
	        (setq errorp t))
	      (unless errorp
	        ;; (miniedit-show-help
	        ;;  "Read THIS MESSAGE --->\n  " msg
	        ;;  "\n\nEdit field, and press C-c C-c or C-M-c to continue.")


	        ;; (message "When you're done editing press C-M-c to continue.")

	        (unwind-protect
	            (recursive-edit)
	          (if (get-buffer-window "*Miniedit*")
		            (progn
		              (progn
		                (setq new-content (buffer-substring
				                               (point-min) (point-max)))
                    ;;(delete-window (get-buffer-window "*Miniedit*"))
		                (kill-buffer "*Miniedit*")
		                )))
	          (when
		            (get-buffer "*Miniedit Help*")
	            (kill-buffer "*Miniedit Help*")))))
      (unless (stringp new-content)
	      (setq errorp t))


      ;;user-customization of new content begins..
      (setq miniedit-string
	          new-content)
      (when (and
	           (stringp miniedit-string)
	           miniedit-before-commit-kill-p)
	      (kill-new miniedit-string))
      (when
	        miniedit-before-commit-function
	      (miniedit-withit
	       (funcall miniedit-before-commit-function
		              miniedit-string)
	       (when it (setq miniedit-string it))))
      (run-hooks 'miniedit-before-committing-hook)
      ;;user-customization of new content ends..


      (if (not errorp)
	        new-content
        save-content))))


;; This actually broke counsel-ag
;; Also, it looked awful and was useless.
;; emacs 27
;; (fido-mode 1)
;; (fido-mode -1)


(provide 'pen-minibuffer)