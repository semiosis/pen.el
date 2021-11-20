;; Pen thin client for emacs
;; This communicates with a Pen.el docker container for basic prompt functions

(require 'pp)
(require 'json)
(require 'cl-lib)

;; This file can be loaded by a vanilla emacs

(defun pen-eval-string (string)
  "Evaluate elisp code stored in a string."
  (eval (car (read-from-string (format "(progn %s)" string)))))

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun pp-oneline (l)
  (chomp (replace-regexp-in-string "\n +" " " (pp l))))

(defun pen-q (&rest strings)
  (let ((print-escape-newlines t))
    (mapconcat 'identity (mapcar 'prin1-to-string strings) " ")))

(defun e/escape-string (&rest strings)
  (let ((print-escape-newlines t))
    (mapconcat 'identity (mapcar 'prin1-to-string strings) " ")))
(defalias 'e/q 'e/escape-string)

(defun ecmd (&rest args)
  (chomp (mapconcat 'identity (mapcar 'e/q args) " ")))

(defun variable-p (s)
  (and (not (eq s nil))
       (boundp s)))

(defmacro shut-up-c (&rest body)
  "This works for c functions where shut-up does not."
  `(progn (let* ((inhibit-message t))
            ,@body)))

(defun slurp-file (filePath)
  "Return filePath's file content."
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))

(defun pen-sn-basic (cmd &optional stdin dir)
  (interactive)

  (let ((output))
    (if (not cmd)
        (setq cmd "false"))

    (if (not dir)
        (setq dir default-directory))

    (let ((default-directory dir))
      (if (or
           (and (variable-p 'sh-update)
                (eval 'sh-update))
           (>= (prefix-numeric-value current-prefix-arg) 16))
          (setq cmd (concat "export UPDATE=y; " cmd)))

      (setq tf (make-temp-file "elisp_bash"))
      (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

      (setq final_cmd (concat "( cd " (pen-q dir) "; " cmd " ) > " tf))

      (shut-up-c
       (with-temp-buffer
         (insert (or stdin ""))
         (shell-command-on-region (point-min) (point-max) final_cmd)))
      (setq output (slurp-file tf))
      output)))

(defun vector2list (v)
  (append v nil))

(defun new-buffer-from-string (&optional contents bufname mode nodisplay)
  "Create a new untitled buffer from a string."
  (interactive)
  (if (not bufname)
      (setq bufname "*untitled*"))
  (let ((buffer (generate-new-buffer bufname)))
    (set-buffer-major-mode buffer)
    (if (not nodisplay)
        (display-buffer buffer '(display-buffer-same-window . nil)))
    (with-current-buffer buffer
      (if contents
          (if (stringp contents)
              (insert contents)
            (insert (str contents))))
      (beginning-of-buffer)
      (if mode (funcall mode)))
    buffer))
(defalias 'nbfs 'new-buffer-from-string)
(defun new-buffer-from-o (o)
  (new-buffer-from-string
   (if (stringp o)
       o
     (pp-to-string o))))
(defun pen-etv (o)
  "Returns the object. This is a way to see the contents of a variable while not interrupting the flow of code.
 Example:
 (message (pen-etv \"shane\"))"
  (new-buffer-from-o o)
  o)

(defun pen-client-generate-functions ()
  (interactive)

  (let* ((sig-sexps (pen-eval-string
                     (concat
                      "'"
                      (chomp (pen-sn-basic (ecmd "pene" "(pen-list-signatures-for-client)")))))))

    (dolist (s sig-sexps)
        (let* ((fn-name
                (replace-regexp-in-string "(pf-\\([^ )]*\\).*" "pen-fn-\\1" (pp-oneline s)))
               (remote-fn-name
                (replace-regexp-in-string "(\\([^ )]*\\).*" "\\1" (pp-oneline s)))
               (fn-sym
                (intern fn-name))
               (args
                (replace-regexp-in-string "^[^ ]* &optional *\\(.*\\))$" "\\1" (pp-oneline s)))
               (arg-list
                (split-string args))
               (arg-list-syms
                (mapcar 'intern arg-list))
               (ilist
                (cons
                 'list
                 (cl-loop
                  for a in arg-list collect
                  (pen-eval-string (concat "'(read-string " (pen-q (concat a ": ")) ")")))))
               (sn-cmd `(ecmd "pena" ,remote-fn-name ,@arg-list-syms)))

          (eval
           `(defun ,fn-sym ,(pen-eval-string
                             (if (string-equal args "")
                                 "'()"
                               (format "'(&optional %s)" args)))
              ,(cons 'interactive (list ilist))
              (let ((result
                     (vector2list (json-read-from-string (chomp (eval `(pen-sn-basic ,,sn-cmd)))))))
                (if (interactive-p)
                    (pen-etv result)
                  result))))))))

(pen-client-generate-functions)

(provide 'pen-client)