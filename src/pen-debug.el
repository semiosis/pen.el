;; Since debug.el is so early on in pen.el, define this here
(defmacro comment (&rest body) nil)

(defmacro tryelse (thing &optional otherwise)
  "Try to run a thing. Run something else if it fails."
  `(condition-case
       nil ,thing
     (error ,otherwise)))

(comment
 (defun try-cascade (list-of-alternatives)
   "Try to run a thing. Run something else if it fails."
   ;; (pen-list2str list-of-alternatives)

   (let* ((failed t)
          (result
           (catch 'bbb
             (dolist (p list-of-alternatives)
               ;; (message "%s" (pen-list2str p))
               (let ((result nil))
                 (tryelse
                  (progn
                    (setq result (eval p))
                    (setq failed nil)
                    (throw 'bbb result))
                  result))))))
     (if failed
         (error "Nothing in try succeeded")
       result))))

(defun try-cascade (list-of-alternatives &optional error-message)
  "Try to run a thing. Run something else if it fails."
  ;; (pen-list2str list-of-alternatives)

  (let* ((failed t)
         (result
          (catch 'bbb
            (dolist (p list-of-alternatives)
              ;; (message "%s" (pen-list2str p))
              (let ((result nil))
                (tryelse
                 (progn
                   (setq result (eval p))
                   (setq failed nil)
                   (throw 'bbb result))
                 result))))))
    (if failed
        (error (or error-message
                   "Nothing in try succeeded"))
      result)))

(defmacro rename-error (message &rest list-of-alternatives)
  "Try to run a thing. Run something else if it fails."
  `(try-cascade '(,@list-of-alternatives) ,message))

(defmacro try (&rest list-of-alternatives)
  "Try to run a thing. Run something else if it fails."
  `(try-cascade '(,@list-of-alternatives)))

(comment
 (rename-error "SUP"
               (try (error "yo")
                    (error "yoyo")))
 
 (rename-error "SUP"
               (try t
                    (error "yoyo"))))

(defmacro pen-try (&rest list-of-alternatives)
  "Try to run a thing. Run something else if it fails."
  (if pen-debug
      (car list-of-alternatives)
    `(try-cascade '(,@list-of-alternatives))))

(defvar pen_loaded_packages nil)

;; I think I should just leave this on
(defvar require-depth 0)
(defun require-around-advice (proc &rest args)
  (let* ((package_name (format "%s" (car args)))
         (path (locate-library package_name))
         (visible-depth (mod require-depth 20))
         (spaces (make-string visible-depth ? )))
    (if (not (member package_name pen_loaded_packages))
        (progn
          (message (concat spaces (format "%s" require-depth) "p:%S  " path) args))))
  (setq require-depth (+ require-depth 1)) t

  (let ((res (apply proc args)))
    ;; (message "require returned %S" res)
    (setq require-depth (- require-depth 1))
    (let* ((package_name (format "%s" (car args)))
           (visible-depth (mod require-depth 20))
           (spaces (make-string visible-depth ? )))
      (if (not (member package_name pen_loaded_packages))
          (progn
            (message (concat spaces (format "%s" require-depth) "p:%S END") args)
            (push package_name pen_loaded_packages))))
    res))
(advice-add 'require :around #'require-around-advice)
;; (advice-remove 'require #'require-around-advice)

(require 'lispy)

(defun pen-goto-package (p)
  (interactive (list (fz pen_loaded_packages nil nil "Package:")))

  (if (symbolp p)
      (setq p (str p)))

  (if (member p pen_loaded_packages)
      (let ((mn "*emacs-lisp-scratch*"))
        (with-current-buffer
            (switch-to-buffer mn)
          (emacs-lisp-mode)
          (let ((r (lispy-goto-symbol p)))
            (kill-buffer mn)
            r)))

    (error (concat "Can't find " p " in loaded packages"))))

(defun all-loaded-packages ()
  (append (mapcar #'car package-alist)
          ;; (mapcar #'car package-archive-contents)
          (mapcar #'car package--builtins)))

;; TODO: I can get the precise location the way j:describe-package-1 does it
;; j:describe-package-1

(defun pen-goto-package-all (p)
  (interactive (list (fz
                      (-uniq
                       (append
                        (mapcar
                         'str2sym
                         pen_loaded_packages)
                        (all-loaded-packages))) nil nil "Package:")))

  (if (symbolp p)
      (setq p (str p)))

  (let ((mn "*emacs-lisp-scratch*"))
    (rename-error
     (concat "Can't find " p " in loaded packages")
     

     ;; (try
     ;;  (with-current-buffer
     ;;      (switch-to-buffer mn)
     ;;    (emacs-lisp-mode)
     ;;    (let ((r (lispy-goto-symbol ,(str2sym p))))
     ;;      (kill-buffer mn)
     ;;      r)))

     (try
      (with-current-buffer
          (switch-to-buffer mn)
        (emacs-lisp-mode)
        (let ((r (lispy-goto-symbol (str2sym p))))
          (kill-buffer mn)
          r))
      (progn
        (kill-buffer mn)
        (error (concat "Can't find " p " in loaded packages. Killing buffer")))))))

(comment
 (defun pen-goto-package-all (p)
   (interactive (list (fz
                       (-uniq
                        (append
                         (mapcar
                          'str2sym
                          pen_loaded_packages)
                         (all-loaded-packages))) nil nil "Package:")))

   (if (symbolp p)
       (setq p (str p)))

   (let ((mn "*emacs-lisp-scratch*"))
     (with-current-buffer
         (switch-to-buffer mn)
       (emacs-lisp-mode)
       (let ((r (lispy-goto-symbol p)))
         (kill-buffer mn)
         r)))

   (error (concat "Can't find " p " in loaded packages"))))

(provide 'pen-debug)
