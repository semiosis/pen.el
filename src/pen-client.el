;; Pen thin client for emacs
;; This communicates with a Pen.el docker container for basic prompt functions

(require 'pp)
(require 'json)

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun pp-oneline (l)
  (chomp (replace-regexp-in-string "\n +" " " (pp l))))

(defun pen-q (&rest strings)
  (let ((print-escape-newlines t))
    (s-join " " (mapcar 'prin1-to-string strings))))

(defun pen-sn-basic (cmd &optional stdin dir)
  (interactive)

  (let ((output))
    (if (not cmd)
        (setq cmd "false"))

    (if (not dir)
        (setq dir (get-dir)))

    (let ((default-directory dir))
      (if (or (>= (prefix-numeric-value current-global-prefix-arg) 16)
              (or
               (and (variable-p 'sh-update)
                    (eval 'sh-update))
               (>= (prefix-numeric-value current-prefix-arg) 16)))
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

(defun pen-snc (cmd &optional stdin)
  "sn chomp"
  (chomp (pen-sn cmd stdin)))

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

  (let* ((sig-sexps (eval-string
                     (concat
                      "'"
                      (pen-snc (cmd "pene" "(pen-list-signatures-for-client)"))))))

    (cl-loop
     for s in sig-sexps do
     (let* ((fn-name
             (replace-regexp-in-string "(pf-\\([^ )]*\\).*" "pen-fn-\\1" (pp-oneline s)))
            (remote-fn-name
             (replace-regexp-in-string "(\\([^ )]*\\).*" "\\1" (pp-oneline s)))
            (fn-sym
             (intern fn-name))
            (args
             (replace-regexp-in-string "^[^ ]* &optional *\\(.*\\))$" "\\1" (pp-oneline s)))
            (arg-list
             (s-split " " args))
            (arg-list-syms
             (mapcar 'intern arg-list))
            (ilist
             (cons
              'list
              (cl-loop
               for a in arg-list collect
               (eval-string (concat "'(read-string " (pen-q (concat a ": ")) ")")))))
            ;; (sn-cmd (concat "0</dev/null " (eval `(cmd "penf" ,remote-fn-name ,@arg-list-syms))))
            (sn-cmd `(cmd "pena" ,remote-fn-name ,@arg-list-syms)))

       (eval
        `(defun ,fn-sym ,(eval-string
                          (if (string-equal args "")
                              "'()"
                            (format "'(&optional %s)" args)))
           ,(cons 'interactive (list ilist))
           (let ((result
                  (vector2list (json-read-from-string (chomp (eval `(pen-sn-basic ,,sn-cmd)))))))
             (if (interactive-p)
                 (pen-etv result)
               result))))))))

(provide 'pen-client)