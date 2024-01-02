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

(defun prin1-to-string-safe (s)
  (if s
      (prin1-to-string s)
    "\"\""))

(defun pen-q (&rest strings)
  (let ((print-escape-newlines t))
    (mapconcat 'identity (mapcar 'prin1-to-string-safe strings) " ")))

(defalias 'e/escape-string 'pen-q)
(defalias 'e/q 'pen-q)

(defun pen-client-ecmd (&rest args)
  (chomp (mapconcat 'identity (mapcar 'e/q
                                      (mapcar 'substring-no-properties
                                              (mapcar (λ (e) (if e e "")) args))) " ")))

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

  (shut-up
    (let ((output))
      (if (not cmd)
          (setq cmd "false"))

      (if (not dir)
          (setq dir default-directory))

      (let ((default-directory dir))
        (if (or
             (and (variable-p 'pen-sh-update)
                  (eval 'pen-sh-update))
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
        (ignore-errors
          (progn (f-delete tf)
                 (f-delete tf_exit_code)))
        output))))

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
      ;; This may not be available
      (ignore-errors (pen-add-ink-change-hook)))
    buffer))
(defalias 'nbfs 'new-buffer-from-string)

(defun nbfs-sps (s)
  (esps (lm (nbfs s))))

(defun new-buffer-from-string-detect-lang (s &optional mode)
  (let* ((b (new-buffer-from-string s)))
    (with-current-buffer b
      (switch-to-buffer b)
      (if mode
          (funcall mode)
        (guess-major-mode)))))

(defun new-buffer-from-o (o &optional mode)
  "Returns the object. This is a way to see the contents of a variable while not interrupting the flow of code.
 Example:
 (message (pen-etv \"shane\"))"
  (new-buffer-from-string
   (if (stringp o)
       o
     (pp-to-string o))
   nil mode))

(defalias 'pen-etv 'new-buffer-from-o)

(defmacro ifi-message (&rest body)
  `(let ((result
          ,@body))
     (if (interactive-p)
         (message "%s" (str result))
       result)))

(defmacro ifietv (&rest body)
  ""
  `(let ((result ,@body))
     (if (interactive-p)
         (pen-etv result)
       result)))
(defalias 'ifi-etv 'ifietv)

(defmacro ifi-v (&rest body)
  `(let ((result
          ,@body))
     (if (interactive-p)
         (tpop "v" (str result)
               :output_b nil)
       result)))

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

(defun pen-list2str-oneliners (&rest l)
  "join the string representation of elements of a given list into a single string with newline delimiters"
  (if (cl-equalp 1 (length l))
      (setq l (car l)))
  (pen-list2str (mapcar 'pen-onelineify l)))

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
             (λ (s) (pen-eval-string (concat "'" s)))
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
                                proxy
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
                   (client-do-pen-update
                     (or
                      ;; H-u -- this doesn't work with some interactive functions, such as (interactive (list (read-string "kjlfdskf")))
                      ;; Can't use current-global-prefix-arg because a vanilla client doesn't necessarily have this
                      ;; (>= (prefix-numeric-value current-global-prefix-arg) 4)
                      ;; C-u 0
                      (= (prefix-numeric-value current-prefix-arg) 0)
                      (pen-var-value-maybe 'do-pen-update)))
                   ;; I have to supply prompt-hist-id here as an option
                   (sn-cmd
                    (if client-do-pen-update
                        `(pen-client-ecmd ,pen-script-name "-u" "--prompt-hist-id" prompt-hist-id ,,remote-fn-name ,@',arg-list-syms)
                      `(pen-client-ecmd ,pen-script-name "--prompt-hist-id" prompt-hist-id ,,remote-fn-name ,@',arg-list-syms))))
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
                           :proxy proxy
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

(defun pen-sh (&optional cmd stdin b_output tm_session shell b_switch_to tm_wincmd dir b_wait)
  "Runs command in a new tmux window and optionally returns the output of the command as a string.
b_output is (t/nil) tm_session is the session of the new tmux window"
  (interactive)

  (if (not dir)
      (setq dir (get-dir)))

  (let ((default-directory dir))

    (if (not shell)
        (setq shell "bash"))

    (if (not tm_wincmd)
        (setq tm_wincmd "nw"))

    (if tm_session
        (setq tm_session (concat " -t " tm_session)))

    (setq session-dir-cmd (concat tm_wincmd " -sh " shell tm_session (if b_switch_to "" " -d") " -c " (pen-q dir) " " (pen-q cmd)))

    (if b_output
        (setq tf (make-temp-file "elispbash")))

    (if (not cmd)
        (setq cmd "zsh"))

    (if b_output
        ;; unbuffer breaks stdout
        (if stdin
            (setq final_cmd (concat "pen-tm -f -s -sout " session-dir-cmd " > " tf))
          (setq final_cmd (concat "unbuffer pen-tm -f -fout " session-dir-cmd " > " tf)))
      (if stdin
          (if b_wait
              (setq final_cmd (concat "pen-tm -f -S -tout -w " session-dir-cmd))
            (setq final_cmd (concat "pen-tm -f -S -tout " session-dir-cmd)))
        (if b_wait
            (setq final_cmd (concat "unbuffer pen-tm -f -tout -te -w " session-dir-cmd))
          (setq final_cmd (concat "unbuffer pen-tm -f -d -tout -te " session-dir-cmd)))))

    (if (not stdin)
        (shell-command final_cmd)
      (with-temp-buffer
        (insert stdin)

        (shell-command-on-region (point-min) (point-max) final_cmd)))

    (if b_output
        (progn
          (setq output (slurp-file tf))
          output))))

(defun pen-sh/tvipe (&optional stdin editor tm_wincmd ft b_nowait b_quiet dir)
  "Converts the parameter to its string representation and pipes it into tmux.
If a region is selected then it replaces that region.
If a region is selected and stdin is provided then stdin is the stdin.
If a region is selected and stdin is nil then the selected region is the stdin.
TODO make it so if I don't have anything selected, it takes me to the same position that I am currently in.

This function doesn't really like it when you put 'sp' as the editor."
  (interactive)
  (if (not editor)
      (setq editor "v"))

  (if (not tm_wincmd)
      (setq tm_wincmd "sps"))

  (setq editor (concat "EDITOR=" (pen-q editor) " vipe"))

  (if b_quiet (setq editor (concat editor " &>/dev/null")))

  (if (not stdin)
      (if (region-active-p)
          (setq stdin (pen-selected-text))))

  (if stdin (setq stdin (str stdin)))

  (if (not (pen-empty-string-p stdin))
      (if (region-active-p)
          (progn
            ;; (select-tmux-current)
            (let ((stdout (pen-sn (concat "ptw tm vipe -wintype " tm_wincmd " " (e/q editor))
                                  (format "%s" stdin)
                                  dir
                                  nil
                                  b_nowait)))
              (if (not b_nowait)
                  (progn
                    (delete-region (region-beginning) (region-end))
                    (insert stdout)))))
        (pen-bash editor (str stdin) (or (not b_quiet) (not b_nowait)) nil t tm_wincmd dir (not b_nowait)))
    (message "%s" "tvipe: stdin is empty")))

(cl-defun pen-cl-tv (&optional stdin &key editor &key tm_wincmd &key dir &key pp
                               &key use_etv
                               &key use_tm_tv)
  "Setting b-wait to -1 disables waiting.
"
  (interactive)
  (setq pp (or pp 'pp-to-string))

  (if (and (or (display-graphic-p)
               use_etv)
           (not use_tm_tv))
      (etv stdin)
    ;; (xtv stdin)
    (if stdin
        (let ((tv_input
               (cond ((and (stringp stdin)
                           (eq pp 'pp-to-string))
                      stdin)
                     (t (apply pp (list stdin))))))
          (pen-sh/tvipe tv_input editor tm_wincmd nil t t dir))
      (message "tv: no input")))
  stdin)
(defalias 'pen-tv 'pen-cl-tv)

(defmacro qtv (&rest args)
  "Quiet tv"
  ;; body
  `(pen-nil (pen-tv ,@args)))

(defmacro tvd (&rest args)
  "tvipe detached"
  ;; body
  ;; (eval `(pen-nil (pen-tvipe ,@args :editor "colvs" :tm_wincmd "sps" :b-quiet t :b-nowait t)))
  `(pen-nil (pen-tvipe ,@args :editor "colv" :tm_wincmd "sps" :b-quiet t :b-nowait t)))

(defmacro qtvd (&rest args)
  "Quiet tvd"
  ;; body
  `(pen-nil (tvd ,@args)))

(defun xtv (stdin)
  (pen-sn "xt v" stdin nil nil t))

(cl-defun pen-cl-tvipe (&optional stdin &key editor &key tm_wincmd &key b-quiet &key b-nowait &key dir)
  "Setting b-wait to -1 disables waiting."
  (interactive)
  (pen-sh/tvipe stdin editor tm_wincmd nil b-nowait b-quiet dir))
(defalias 'pen-tvipe 'pen-cl-tvipe)

(defun pen-bash (&optional cmd stdin b_output tm_session b_switch_to tm_wincmd dir b_wait)
  (interactive)
  (pen-sh cmd stdin b_output tm_session "bash" b_switch_to tm_wincmd dir b_wait))

(provide 'pen-client)
