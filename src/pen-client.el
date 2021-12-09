;; Pen thin client for emacs
;; This communicates with a Pen.el docker container for basic prompt functions

(require 'pp)
(require 'json)
(require 'cl-lib)
(require 'ilambda)

;; This file can be loaded by a vanilla emacs

(defun pen-container-running-p ()
  (string-equal "0" (chomp (pen-sn-basic (concat (pen-client-ecmd "pen" "-running-p") "; echo $?")))))

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

(defalias 'e/escape-string 'pen-q)
(defalias 'e/q 'pen-q)

(defun pen-client-ecmd (&rest args)
  (chomp (mapconcat 'identity (mapcar 'e/q
                                      (mapcar 'substring-no-properties
                                              (mapcar (lambda (e) (if e e "")) args))) " ")))

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
      (if mode (funcall mode))
      (pen-add-ink-change-hook))
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

(defun str (thing)
  "Converts object or string to an unformatted string."

  (if thing
      (if (stringp thing)
          (substring-no-properties thing)
        (progn
          (setq thing (format "%s" thing))
          (set-text-properties 0 (length thing) nil thing)
          thing))
    ""))

(defun pen-list2str (&rest l)
  "join the string representation of elements of a given list into a single string with newline delimiters"
  (if (cl-equalp 1 (length l))
      (setq l (car l)))
  (mapconcat 'identity (mapcar 'str l) "\n"))

(defun pen-var-value-maybe (sym)
  (cond
   ((symbolp sym) (if (variable-p sym)
                      (eval sym)))
   ((numberp sym) sym)
   ((stringp sym) sym)
   (t sym)))

(defun pen-list-signatures-for-client ()
  (cl-loop for nm in pen-prompt-functions collect
           (downcase (replace-regexp-in-string " &key.*" ")" (helpful--signature nm)))))

;; (pen-fn-translate/3 (buffer-substring (region-beginning) (region-end)) "English" "French")
(defun pen-client-generate-functions ()
  (interactive)

  (let* ((sig-sexps
          (if (pen-container-running-p)
              (pen-eval-string
               (concat
                "'"
                (chomp
                 (pen-sn-basic
                  (pen-client-ecmd
                   "pene"
                   "(pen-list-signatures-for-client)")))))
            (mapcar
             (lambda (s) (pen-eval-string (concat "'" s)))
             (pen-list-signatures-for-client)))))

    (dolist (s sig-sexps)
      (let* ((fn-name
              (replace-regexp-in-string "(pf-\\([^ )]*\\).*" "pen-fn-\\1" (pp-oneline s)))
             (remote-fn-name
              (replace-regexp-in-string "(\\([^ )]*\\).*" "\\1" (pp-oneline s)))
             (fn-sym
              (intern fn-name))
             (remote-fn-sym
              (intern remote-fn-name))
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
                (pen-eval-string (concat "'(read-string " (pen-q (concat a ": ")) ")"))))))

        (eval
         `(cl-defun ,fn-sym ,(append
                              (pen-eval-string
                               (if (string-equal args "")
                                   "'()"
                                 (format "'(&optional %s)" args)))
                              '(&key
                                no-select-result
                                include-prompt
                                no-gen
                                select-only-match
                                variadic-var
                                pretext
                                prompt-hist-id
                                inject-gen-start
                                override-prompt
                                force-interactive
                                ;; inert for client
                                client
                                server))
            ,(cons 'interactive (list ilist))

            (let* ((is-interactive
                    (or (interactive-p)
                        force-interactive))
                   (pen-script-name
                    (if (eq 1 (pen-var-value-maybe 'force-n-completions))
                        ;; TODO Force this somehow to do one completion
                        ;; Can't use penf, because it's different.
                        "penj"
                      "pena"))
                   ;; I have to supply prompt-hist-id here as an option
                   (sn-cmd `(pen-client-ecmd ,pen-script-name "-u" "--prompt-hist-id" prompt-hist-id ,,remote-fn-name ,@',arg-list-syms)))
              (if (or server
                      (not (pen-container-running-p)))
                  (apply ',remote-fn-sym
                         (append
                          (mapcar 'eval ',arg-list-syms)
                          (list
                           :no-select-result no-select-result
                           :include-prompt include-prompt
                           :no-gen no-gen
                           :select-only-match select-only-match
                           :variadic-var variadic-var
                           :pretext pretext
                           :prompt-hist-id prompt-hist-id
                           :inject-gen-start inject-gen-start
                           :override-prompt override-prompt
                           :force-interactive is-interactive
                           ;; inert for client
                           ;; client
                           ;; server
                           )))
                (let* ((results (vector2list (json-read-from-string (chomp (eval `(pen-sn-basic ,sn-cmd)))))))
                  (if is-interactive
                      (pen-etv
                       (completing-read ,(concat remote-fn-name ": ") results))
                    results))))))))))

(defun pen-test-client-fn ()
  (interactive)
  (pf-very-witty-pick-up-lines-for-a-topic/1 "slovenia" :client t :force-interactive t))

(defun pen-test-client-pickup-lines ()
  (interactive)
  (pen-fn-very-witty-pick-up-lines-for-a-topic/1 "slovenia" :force-interactive t))

(defun test-ilambda-thin-client ()
  (interactive)

  (eval
   `(progn
      ;; (load-library "pen-client")
      ;; (load-library "ilambda")

      (setq iλ-thin t)

      (idefun thing-to-hex-color (thing))
      (let ((color
             (upd (thing-to-hex-color "watermelon"))))
        (if ,(interactive-p)
            (pen-etv color)
          color)))))

(defun test-ilambda-full-client ()
  (interactive)

  (eval
   `(progn
      ;; (load-library "pen-client")
      ;; (load-library "ilambda")

      (setq iλ-thin nil)

      (idefun thing-to-hex-color (thing))

      (let ((color
             (upd (thing-to-hex-color "watermelon"))))
        (if ,(interactive-p)
            (pen-etv color)
          color)))))

(provide 'pen-client)