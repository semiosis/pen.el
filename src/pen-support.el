;; To work around an issue with
;; Debugger entered--Lisp error: (void-function make-closure)
;; in f-join.
;; It's happening for all f functions on pen-debian.
;; Try recompiling emacs
;; (defun f-join (&rest strings)
;;   (s-join "/" strings))

(defun pen-tf (template &optional input ext)
  "Create a temporary file."
  (setq ext (or ext "txt"))
  (let ((fp (pen-snc (concat "mktemp -p /tmp " (pen-q (concat "XXXX" (slugify template) "." ext))))))
    (if (and (sor fp)
             (sor input))
        (shut-up (write-to-file input fp)))
    fp))

(defun pen-is-glossary-file (&optional fp)
  ;; This path works also with info
  (setq fp (or fp
               (get-path nil t)
               ""))

  (or
   (re-match-p "glossary\\.txt$" fp)
   (re-match-p "words\\.txt$" fp)
   (re-match-p "glossaries/.*\\.txt$" fp)))

(defun pen-yas-expand-string (ys)
  (interactive)
  (save-window-excursion
    (save-excursion
      (let ((m major-mode)
            (b (new-buffer-from-string
                ys
                nil
                'fundamental-mode)))
        (str
         (with-current-buffer b
           (let ((s))
             (funcall m)
             (yas-minor-mode 1)
             (yas-expand-snippet
              (buffer-string)
              (point-min)
              (point-max)
              '((yas-indent-line 'fixed)))
             (setq s (buffer-string))
             (kill-buffer b)
             s)))))))

(defun pen-get-glossary-topic (&optional fp)
  (if (pen-is-glossary-file)
      (cond
       ((or
         (re-match-p "glossary\\.txt$" fp)
         (re-match-p "words\\.txt$" fp))
        (f-mant (pen-f-basename (f-dirname (buffer-file-name)))))
       (t
        (f-mant (pen-f-basename (buffer-file-name)))))))

(defun url-found-p (url)
  "Return non-nil if URL is found, i.e. HTTP 200."
  (with-current-buffer (url-retrieve-synchronously url nil t 5)
    (prog1 (eq url-http-response-status 200)
      (kill-buffer))))

(defun ecurl (url)
  (with-current-buffer (url-retrieve-synchronously url t t 5)
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point) (point-min))
    (kill-line)
    (let ((result (buffer2string (current-buffer))))
      (kill-buffer)
      result)))

(defun pen-messages-buffer ()
  "Return the \"*Messages*\" buffer.
If it does not exist, create it and switch it to `messages-buffer-mode'."
  (or (get-buffer "*Messages*")
      (with-current-buffer (get-buffer-create "*Messages*")
        (messages-buffer-mode)
        (current-buffer))))

;; Ensure the messages buffer exists
(defun message-around-advice (proc &rest args)
  (pen-messages-buffer)
  (let ((res (apply proc args)))
    res))
(advice-add 'message :around #'message-around-advice)

(defun pen-message-no-echo (format-string &rest args)
  (let ((inhibit-read-only t))
    (with-current-buffer (pen-messages-buffer)
      (goto-char (point-max))
      (when (not (bolp))
        (insert "\n"))
      (insert (apply 'format format-string args))
      (when (not (bolp))
        (insert "\n"))))
  ;; (let ((minibuffer-message-timeout 0))
  ;;   (message format-string args))
  )

(defun pen-log (&rest ss)
  (let ((ret (s-join ", " (mapcar 'str ss))))
    (pen-message-no-echo "%s\\n" ret))

  ;; This is for backwards compatibility
  (car ss)
  ;; ret
  )

(defun pen-log-verbose (&rest ss)
  ;; TODO Add some verbosity level in custom
  ;; (let ((ret (s-join ", " (mapcar 'str ss))))
  ;;   (pen-message-no-echo "%s\\n" ret))

  ;; This is for backwards compatibility
  (car ss)
  ;; ret
  )

(defun pen-aget (key alist)
  (cdr (assoc key alist)))

(defun pen-alist-set (alist-symbol key value)
  "Set KEY to VALUE in alist ALIST-SYMBOL."
  (set alist-symbol
       (cons (list key value) 
             (assq-delete-all key (eval alist-symbol)))))

(defun pen-alist-setcdr (alist-symbol key value)
  "Set KEY to VALUE in alist ALIST-SYMBOL."
  (set alist-symbol
       (cons (cons key value)
             (assq-delete-all key (eval alist-symbol)))))

(defun pen-write-to-file (stdin file_path)
  (ignore-errors (with-temp-buffer
                   (insert stdin)
                   (delete-file file_path)
                   (write-file file_path))))

(defun pen-cartesian-product (&rest ls)
  (let* ((len (length ls))
         (result (cond
                  ((not ls) nil)
                  ((equal 1 len) ls)
                  (t
                   (-reduce 'cartesian-product-2 ls)))))
    (if (< 2 len)
        (mapcar (lambda (l) (unsnd l (- len 2)))
                result)
      result)))

(defun pp-oneline (l)
  (chomp (replace-regexp-in-string "\n +" " " (pp l))))
(defalias 'pp-ol 'pp-oneline)

(defalias 'type 'type-of)

(defun pen-eval-string (string)
  "Evaluate elisp code stored in a string."
  (eval (car (read-from-string (format "(progn %s)" string)))))
(defalias 'eval-string 'pen-eval-string)

(defun pcre-replace-string (pat rep s &rest body)
  "Replace pat with rep in s and return the result.
The string replace part is still a regular emacs replacement pattern, not PCRE"
  (eval `(replace-regexp-in-string (pcre-to-elisp pat ,@body) rep s)))

(defun prin1-to-string-safe (s)
  (if s
      (prin1-to-string s)
    "\"\""))

(defun e/escape-string (&rest strings)
  (let ((print-escape-newlines t))
    (s-join " " (mapcar 'prin1-to-string-safe strings))))
(defalias 'pen-q 'e/escape-string)
;; (defalias 'q 'e/escape-string)

(defun pen-qne (string)
  "Like q but without the end quotes"
  (pcre-replace-string "\"(.*)\"" "\\1" (pen-q string)))

(defun pen-append-uniq-to-file (stdin file_path)
  (pen-sn
   (concat "cat " (pen-q file_path) " | uniqnosort | sponge " (pen-q file_path)) stdin))

;; append-to-file is a builtin. I shouldn't do this
(defun pen-append-to-file (stdin file_path)
  (pen-sn
   (concat "cat >> " (pen-q file_path)) stdin))

(defun s/awk1 (s)
  (pen-sn "awk 1" s))
(defun s/cat-awk1 (path &optional dir)
  (setq path (pen-umn path))
  (pen-sn (concat "cat " (pen-q path) " | awk 1" " 2>/dev/null") nil dir))
(defun e/cat (path)
  "Return the contents of FILENAME."
  (if (sor path)
      (with-temp-buffer
        (insert-file-contents path)
        (buffer-string))))
(defun s/cat (path &optional dir)
  "cat out a file"
  (setq path (pen-umn path))
  (pen-sn (concat "cat " (pen-q path) " 2>/dev/null") nil dir))
(defalias 'cat 's/cat)

(defmacro comment (&rest body) nil)

(defun variable-p (s)
  (and (not (eq s nil))
       (boundp s)))

;; For docker
(if (not (variable-p 'user-home-directory))
    (defvar user-home-directory nil))
(setq user-home-directory (or user-home-directory "/root"))

(defmacro upd (&rest body)
  (let ((l (eval
            `(let (;; (current-global-prefix-arg '(4))
                   ;; (current-prefix-arg '(4))
                   ;; for cacheit
                   (pen-sh-update t)
                   ;; for memoize
                   (do-pen-update t))
               ,@body))))
    `',l))

(comment
 (pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line")))
 (upd (pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line")))))

;; This was running prompt functions on load

;; (defun test-upd2 ()
;;   (interactive)
;;   (pen-etv (pps (upd (pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line")))))))

;; (defun test-upd ()
;;   (interactive)
;;   (pen-etv (pps (eval `(upd (pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line"))))))))

(defmacro noupd (&rest body)
  `(let ((pen-sh-update nil)) ,@body))

(defmacro tryelse (thing &optional otherwise)
  "Try to run a thing. Run something else if it fails."
  `(condition-case
       nil ,thing
     (error ,otherwise)))

(defmacro try (&rest list-of-alternatives)
  "Try to run a thing. Run something else if it fails."
  `(try-cascade '(,@list-of-alternatives)))

(defmacro pen-try (&rest list-of-alternatives)
  "Try to run a thing. Run something else if it fails."
  (if pen-debug
      (car list-of-alternatives)
    `(try-cascade '(,@list-of-alternatives))))

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
      result)))

(defmacro defset (symbol value &optional documentation)
  "Instead of doing a defvar and a setq, do this. [[http://ergoemacs.org/emacs/elisp_defvar_problem.html][ergoemacs.org/emacs/elisp_defvar_problem.html]]"

  `(progn (defvar ,symbol ,documentation)
          (setq ,symbol ,value)))

(defun string-empty-or-nil-p (s)
  (or (not s)
      (string-empty-p s)))

(defun string-not-empty-nor-nil-p (s)
  (not (string-empty-or-nil-p s)))

(defun -filter-not-empty-string (l)
  (-filter 'string-not-empty-nor-nil-p l))

(defun string-first-nonnil-nonempty-string (&rest ss)
  "Get the first non-nil string."
  (let ((result))
    (catch 'bbb
      (dolist (p ss)
        (if (string-not-empty-nor-nil-p p)
            (progn
              (setq result p)
              (throw 'bbb result)))))
    result))
(defalias 'sor 'string-first-nonnil-nonempty-string)

(defun nor (val)
  "Number or"
  (cond
   ((and (stringp val)
         ;; TODO Check for full string, rather that regex on a line
         (re-match-p "^[0-9.]*$" val))
    (pen-str2num val))
   ((numberp val)
    val
    (pen-str2num val))))

(defmacro generic-or (p &rest items)
  "Return the first element of ITEMS that does not fail p.
ITEMS will be evaluated in normal `or' order."
  `(generic-or-1 ,p (list ,@items)))

(defalias 'call-function 'funcall)

(defun generic-or-1 (p items)
  (let (item)
    (while items
      (setq item (pop items))
      (if (call-function p item)
          (setq item nil)
        (setq items nil)))
    item))

;; The macro implementation also has the problem of evaluating all strings first
(defmacro str-or (&rest strings)
  "Return the first element of STRINGS that is a non-blank string.
STRINGS will be evaluated in normal `or' order."
  `(generic-or-1 'string-empty-or-nil-p (list ,@strings)))
(defalias 'msor 'str-or)

(defun cwd ()
  "Gets the current working directory"
  (interactive)
  (f-expand (substring (shut-up-c (pwd)) 10)))

(defun tramp-mount-sshfs (&optional tramp-dir)
  (interactive)
  ;; /ssh:andrewdo@localhost#2222:/home/andrewdo/

  (if (not tramp-dir)
      (setq tramp-dir (get-dir t)))

  (let ((mountdir (tramp-mountdir nil t)))
    (if mountdir
        (pcase-let ((`("/ssh" ,full-target ,remote-dir) (s-split ":" tramp-dir)))
          (if (re-match-p "#" full-target)
              (let* ((target (s-replace-regexp "#.*" "" full-target))
                     (port (s-replace-regexp ".*#" "" full-target))
                     (host (s-replace-regexp ".*@" "" target))
                     (user (s-replace-regexp "@.*" "" target)))
                ;; (sps (concat
                ;;       ;; (pen-cmd "ssh-mount" "-sshcmd" "ssh -oBatchMode=no -t" "-sl" "-p" port host user remote-dir)
                ;;       ;; TMUX= new doesn't work either
                ;;       (pen-cmd "ssh-mount" "-sl" "-p" port host user remote-dir)
                ;;       "; zcd " (pen-cmd mountdir)))
                ;; Even with pen-term-nsfa it's not mounting
                ;; Also the first password always fails. What is going on?
                ;; Sad! Just copy the command then.
                ;; Ahhh! It's the working directory that is the problem.
                ;; (xc (pen-cmd "ssh-mount" "-sl" "-p" port host user remote-dir))
                (let ((default-directory "/"))
                  (pen-sps
                   (concat
                    (pen-cmd "ssh-mount" "-sl" "-p" port host user "/")
                    "; pen-sps zcd " (pen-cmd mountdir))))
                ;; (pen-term-nsfa
                ;;  (concat
                ;;   ;; (pen-cmd "ssh-mount" "-sshcmd" "ssh -oBatchMode=no -t" "-sl" "-p" port host user remote-dir)
                ;;   ;; TMUX= new doesn't work either
                ;;   "TMUX= "
                ;;   (pen-cmd "tmux" "new" "ssh-mount" "-sl" "-p" port host user remote-dir)
                ;;   "; sps zcd " (pen-cmd mountdir))
                ;;  nil nil nil nil "/")
                ))))))

(defun tramp-mountdir (&optional tramp-dir root)
  ;; /ssh:andrewdo@localhost#2222:/home/andrewdo/

  (if (not tramp-dir)
      (setq tramp-dir (get-dir t)))

  ;; default directory is set so that slugify does not call (get-dir t)
  (let ((default-directory "/"))
    (pcase-let ((`("/ssh" ,full-target ,remote-dir) (s-split ":" tramp-dir)))
      (if (sor remote-dir)
          (if (re-match-p "#" full-target)
              (let* ((target (s-replace-regexp "#.*" "" full-target))
                     (port (s-replace-regexp ".*#" "" full-target))
                     (host (s-replace-regexp ".*@" "" target))
                     (user (s-replace-regexp "@.*" "" target))
                     (slug (slugify remote-dir)))
                (if root
                    (concat "/media/ssh-" host "_" user)
                  (concat "/media/ssh-" host "_" user "-" slug))))))))

(defun tramp-remotedir (&optional tramp-dir)
  ;; /ssh:andrewdo@localhost#2222:/home/andrewdo/

  (if (not tramp-dir)
      (setq tramp-dir (get-dir t)))

  ;; default directory is set so that slugify does not call (get-dir t)
  (let ((default-directory "/"))
    (pcase-let ((`("/ssh" ,full-target ,remote-dir) (s-split ":" tramp-dir)))
      (if (sor remote-dir)
          remote-dir))))

(defun tramp-localdir (&optional tramp-dir)
  ;; /ssh:andrewdo@localhost#2222:/home/andrewdo/

  (if (not tramp-dir)
      (setq tramp-dir (get-dir t)))

  (if tramp-dir
      (let ((tmd (tramp-mountdir tramp-dir t))
            (trd (tramp-remotedir tramp-dir)))
        (f-join tmd (s-replace-regexp "^/" "" trd)))))

(defun get-dir (&optional dont-clean-tramp)
  "Gets the directory of the current buffer's file. But this could be different from emacs' working directory.
Takes into account the current file name."
  (shut-up-c
   (let* ((filedir (if buffer-file-name
                       (file-name-directory buffer-file-name)
                     (file-name-directory (cwd))))
          (dir
           (if (s-blank? filedir)
               (cwd)
             filedir)))

     ;; If the dir is a tramp path, just use root
     ;; (setq dir "/")
     ;; get-dir must provide the tramp path if requested
     ;; not the mount path
     (if (and
          dir
          (string-match "/[^:]+:" dir))
         (if dont-clean-tramp
             dir
           ;; (setq dir "/")
           ;; this is crashing
           (let* ((md dir)
                  (tmd (tramp-mountdir dir t))
                  (tmr (tramp-remotedir dir)))
             (if (and
                  tmd
                  (f-directory-p tmd))
                 ;; (setq dir tmd)
               (progn
                 (let ((default-directory "/"))
                   (if (not (pen-snq (pen-cmd "mountpoint" tmd) nil "/"))
                       (progn
                         ;; It may already be unmounted, but it may have
                         ;; "Transport endpoint is not connected",
                         ;; so umount to be sure.
                         (pen-sn (pen-cmd "sudo" "umount" "-l" tmd))
                         ;; get-dir gets called repeatedly so I can't do this automatically
                         ;; (tramp-mount-sshfs dir)
                         ;; Also, I don't get the message because the screen may be split
                         (message "%s" (concat tmd " is not mounted"))
                         ;; (pen-ns (concat tmd " is not mounted"))
                         (identity-command))))
                 (setq dir (f-join tmd (s-replace-regexp "^/" "" tmr))))
               (setq dir "/")))))
     dir)))

(defmacro shut-up-c (&rest body)
  "This works for c functions where shut-up does not."
  `(progn (let* ((inhibit-message t))
            ,@body)))

(defun pen-q (&rest strings)
  (let ((print-escape-newlines t))
    (s-join " " (mapcar 'prin1-to-string strings))))

(defun pen-str2list (s)
  "Convert a newline delimited string to list."
  (split-string s "\n"))

(defun pen-list2str (&rest l)
  "join the string representation of elements of a given list into a single string with newline delimiters"
  (if (cl-equalp 1 (length l))
      (setq l (car l)))
  (mapconcat 'identity (mapcar 'str l) "\n"))

(defun scrape (re s &optional delim)
  "Return a list of matches of re within s.
delim is used to guarantee the function returns multiple matches per line
(pen-etv (scrape \"\\b\\w+\\b\" (buffer-string) \" +\"))"
  (pen-list2str (scrape-list re s delim)))

(defun scrape-list (re s &optional delim)
  "Return a list of matches of re within s.
delim is used to guarantee the function returns multiple matches per line
(pen-etv (scrape \"\\b\\w+\\b\" (buffer-string) \" +\"))"
  (if delim
      (setq s (pen-list2str (s-split delim s))))
  (-flatten
   (cl-loop
    for
    line
    in
    (s-split "\n" (str s))
    collect
    (if (string-match-p re line)
        (s-replace-regexp (concat "^.*\\(" re "\\).*") "\\1" line)))))

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun rx/chomp (str)
  "Chomp leading and tailing whitespace from STR."
  (replace-regexp-in-string
   (rx (or (: bos (* (any " \t\n")))
           (: (* (any " \t\n")) eos)))
   ""
   str))

(defun slurp-file (filePath)
  "Return filePath's file content."
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))

(defun pen-find-thing (thing)
  (interactive)
  (if (stringp thing)
      (setq thing (intern thing)))
  (try (find-function thing)
       (find-variable thing)
       (find-face-definition thing)
       t))
(defalias 'pen-j 'pen-find-thing)
(defalias 'pen-ft 'pen-find-thing)

(defmacro pen-lm (&rest body)
  "Interactive lambda with no arguments."
  `(lambda () (interactive) ,@body))

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

(defun sh-construct-exports (varval-tuples)
  (concat
   "export "
   (sh-construct-envs varval-tuples)))

(defun sh-construct-envs (varval-tuples)
  (s-join
   " "
   (-filter
    'identity
    (cl-loop for tp in varval-tuples
             collect
             (let ((lhs (car tp))
                   (rhs (cadr tp)))
               (if tp
                   (concat
                    lhs
                    "="
                    (if rhs
                        (if (booleanp rhs)
                            "y"
                          (pen-q rhs))
                      ""))))))))

(defun pen-daemon-name ()
  (let ((d (daemonp)))
    (if d
        (if (stringp d)
            (f-filename (daemonp))
          ;; Sometimes it's a bool
          "DEFAULT")
      "")))

;; Disable the finished message from appearing in all shell commands
(defun shell-command-sentinel (process signal)
  (when (memq (process-status process) '(exit signal))))

(defun pen-sn (shell-cmd &optional stdin dir exit_code_var detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code)
  "Runs command in shell and return the result.
This appears to strip ansi codes.
\(sh) does not.
This also exports PEN_PROMPTS_DIR, so lm-complete knows where to find the .prompt files"
  (interactive)

  (let ((output)
        (tf)
        (input_tf))
    (if (not shell-cmd)
        (setq shell-cmd "false"))

    ;; sn must never contain a tramp path
    (if (not dir)
        (let ((cand-dir (get-dir)))
          (if (f-directory-p cand-dir)
              (setq dir cand-dir)
            (setq dir "/"))))

    ;; If the dir is a tramp path, just use root
    (if (string-match "/[^:]+:" dir)
        (setq dir "/"))

    (let ((default-directory dir))
      (if b_unbuffer
          (setq shell-cmd (concat "unbuffer -p " shell-cmd)))

      (if (or (or
               (pen-var-value-maybe 'pen-sh-update)
               (>= (prefix-numeric-value current-global-prefix-arg) 16))
              (or
               (and (variable-p 'sh-update)
                    (eval 'sh-update))
               (>= (prefix-numeric-value current-prefix-arg) 16)))
          (setq shell-cmd (concat "export UPDATE=y; " shell-cmd)))

      (setq shell-cmd (concat ". $HOME/.shellrc; " shell-cmd))

      (setq tf (make-temp-file "elisp_bash"))
      (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

      (let ((exps
             (sh-construct-exports
              (-filter 'identity
                       (list (list "DISPLAY" ":0")
                             (list "PATH" (getenv "PATH"))
                             (list "PEN_DAEMON" (sor (daemonp) "default"))
                             (list "PEN_PROMPTS_DIR" (concat pen-prompts-directory "/prompts"))
                             (if (or (pen-var-value-maybe 'pen-sh-update)
                                     (pen-var-value-maybe 'sh-update))
                                 (list "UPDATE" "y"))
                             (if (or (pen-var-value-maybe 'pen-force-engine))
                                 (list "PEN_ENGINE" (pen-var-value-maybe 'pen-force-engine)))
                             (if (or (pen-var-value-maybe 'force-temperature))
                                 (list "PEN_TEMPERATURE" (pen-var-value-maybe 'force-temperature))))))))

        (if (and detach
                 stdin)
            (progn
              (setq input_tf (make-temp-file "elisp_bash_input"))
              (write-to-file stdin input_tf)
              (setq shell-cmd (concat "exec < <(cat " (pen-q input_tf) "); " shell-cmd))))

        (if (not (string-match "[&;]$" shell-cmd))
            (setq shell-cmd (concat shell-cmd ";")))

        (if (and detach
                 stdin)
            (setq final_cmd (concat final_cmd " rm -f " (pen-q input_tf) ";")))

        ;; I need a log level here. This will be too verbose
        (setq final_cmd (pen-log-verbose
                         (concat exps "; ( cd " (pen-q dir) "; " shell-cmd " echo -n $? > " tf_exit_code " ) > " tf))))

      (if detach
          (if stdin
              (setq final_cmd (concat "trap '' HUP; bash -c " (pen-q final_cmd) " &"))
            (setq final_cmd (concat "trap '' HUP; unbuffer bash -c " (pen-q final_cmd) " &"))))

      (shut-up-c
       (if (or
            (not stdin)
            detach)
           (shell-command final_cmd output_buffer "*pen-sn-stderr*")
         (with-temp-buffer
           (insert stdin)
           (shell-command-on-region (point-min) (point-max) final_cmd output_buffer nil "*pen-sn-stderr*"))))

      (if detach
          t
        (progn
          (setq output (slurp-file tf))
          (if chomp
              (setq output (chomp output)))
          (progn
            (defset b_exit_code (slurp-file tf_exit_code)))

          (if b_output-return-code
              (setq output (str b_exit_code)))
          (ignore-errors
            (progn (f-delete tf)
                   (f-delete tf_exit_code)))
          output)))))

(cl-defun pen-cl-sn (shell-cmd &key stdin &key dir &key detach &key b_no_unminimise &key output_buffer &key b_unbuffer &key chomp &key b_output-return-code)
  (interactive)
  (pen-sn shell-cmd stdin dir nil detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code))

(defun pen-snc (shell-cmd &optional stdin dir)
  "sn chomp"
  (chomp (pen-sn shell-cmd stdin dir)))

(defun pen-eval-string (string)
  "Evaluate elisp code stored in a string."
  (eval (car (read-from-string (format "(progn %s)" string)))))

;; (wrlp "hi\nshane" (tv))
;; (pen-etv (wrlp "hi\nshane" (chomp)))
;; (type (wrlp "hi\n\nshane" (pen-etv)))
;; (type (wrlp "hi\n\nshane" (pen-etv) t))
;; (wrlp "hi\n\nshane" (identity))
(defmacro mwrlp (s form &optional nojoin)
  ;; The (eval s) undoes the macroishness of the s arg
  (let* ((sval (eval s))
         (ret
          (cl-loop for l in (s-split "\n" sval) collect
                (if (sor l)
                    ;; This is needed to access form.
                    ;; Unfortunately this occludes dynamic scope.
                    (eval
                     `(-> ,l
                        ,form))
                  l))))
    (if nojoin
        `',ret
      (s-join "\n" ret))))
(defalias 'wrlp 'mwrlp)

(defun fwrlp (s form &optional nojoin)
  "Function version of wrlp"
  (let* ((ret
          (cl-loop for l in (s-split "\n" s) collect
                (if (sor l)
                    (eval
                     `(-> ,l
                        ,form))
                  l))))
    (if nojoin
        ret
      (s-join "\n" ret))))

(defun pen-sne (shell-cmd &optional stdin &rest args)
  "Returns the exit code."
  (defset b_exit_code nil)

  (progn
    (apply 'pen-sn (append (list shell-cmd stdin) args))
    (string-to-number b_exit_code)))

;; (pen-snq "grep hi" "hi")
;; (pen-snq "grep hi" "yo")
(defun pen-snq (shell-cmd &optional stdin &rest args)
  (let ((code (apply 'pen-sne (append (list shell-cmd stdin) args))))
    (equal code 0)))

;; slugify is used in sn, so it must contain an explicit directory, to be safe,
;; so that when called by (get-dir), this does not do an infinite loop.
(defun slugify (input &optional joinlines length)
  "Slugify input"
  (interactive)
  (let ((slug
         (if joinlines
             (pen-sn "tr '\n' - | slugify" input "/")
           (pen-sn "slugify" input "/"))))
    (if length
        (chomp (pen-sn (pen-cmd "head" "-c" length) nil "/"))
      slug)))

(defun fz-completion-second-of-tuple-annotation-function (s)
  (let ((item (assoc s minibuffer-completion-table)))
    (when item
      ;; (concat " # " (second item))
      (cond
       ((listp item) (concat " # " (second item)))
       ((stringp item) "")
       (t "")))))

(cl-defun cl-fz (list &key prompt &key full-frame &key initial-input &key must-match &key select-only-match &key hist-var &key add-props &key no-hist)
          (setq select-only-match
                (or select-only-match
                    (pen-var-value-maybe 'pen-select-only-match)))

          (if no-hist
              (setq hist-var nil)
              (if (and (not hist-var)
                       (sor prompt))
                  (setq hist-var (intern (concat "histvar-fz-" (slugify prompt))))))

          (setq prompt (sor prompt ":"))

          (if (not (string-match " $" prompt))
              (setq prompt (concat prompt " ")))

          (if (eq (type-of list) 'symbol)
              (cond
                ((variable-p 'clojure-mode-funcs) (setq list (eval list)))
                ((fboundp 'clojure-mode-funcs) (setq list (funcall list)))))

          (if (stringp list)
              (setq list (split-string list "\n")))

          (if (and select-only-match (eq (length list) 1))
              (car list)
              (let ((sel))
                (setq prompt (or prompt ":"))
                (let ((helm-full-frame full-frame)
                      (completion-extra-properties nil))

                  (if add-props
                      (setq completion-extra-properties
                            (append
                             completion-extra-properties
                             add-props)))

                  (if (and (listp (car list)))
                      (setq completion-extra-properties
                            (append
                             '(:annotation-function fz-completion-second-of-tuple-annotation-function)
                             completion-extra-properties)))

                  (setq sel (completing-read prompt list nil must-match initial-input hist-var)))

                ;; This refreshes the term usually, but not always. It realigns up some REPLs, such as lein.
                ;; Not worth it just for hhgttg
                (if (and
                     pen-term-cl-refresh-after-fz
                     (major-mode-p 'term-mode)
                     ;; char is raw mode
                     (term-in-char-mode))
                    (run-with-timer 0.2 nil (lambda () (term-send-raw-string "\C-l"))))
                sel)))

(defun fz (list &optional input b_full-frame prompt must-match select-only-match add-props hist-var no-hist)
  (cl-fz
   list
   :initial-input input
   :full-frame b_full-frame
   :prompt prompt
   :must-match must-match
   :select-only-match select-only-match
   :add-props add-props
   :hist-var hist-var
   :no-hist no-hist))

(defun pen-selected ()
  (or
   (use-region-p)
   (evil-visual-state-p)))
(defalias 'pen-selected-p 'pen-selected)

(defun glob (pattern &optional dir)
  (split-string (pen-cl-sn (concat "pen-glob " (pen-q pattern) " 2>/dev/null") :stdin nil :dir dir :chomp t) "\n"))

(defun flatten-once (list-of-lists)
  (apply #'append list-of-lists))

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

(defun regex-match-string-1 (pat s)
  "Get first match from substring"
  (save-match-data
    (and (string-match pat s)
         (match-string-no-properties 0 s))))
(defalias 'regex-match-string 'regex-match-string-1)

(defun s-trailing-whitespace (s)
  (regex-match-string "[ \t\n]*\\'" s))

(defun s-remove-trailing-newline (s)
  (replace-regexp-in-string "\n\\'" "" s))

(defun s-remove-leading-whitespace (s)
  (replace-regexp-in-string "\\`[ \t\n]*" "" s))

(defun s-remove-trailing-whitespace (s)
  (replace-regexp-in-string "[ \t\n]*\\'" "" s))

(defun s-chompall (s)
  (s-remove-leading-whitespace
   (s-remove-trailing-whitespace s)))

(defun s-remove-starting-specified-whitespace (s ws)
  (replace-regexp-in-string (concat "\\`" ws) "" s))

(defun s-preserve-trailing-whitespace (s-new s-old)
  "Return s-new but with the same amount of trailing whitespace as s-old."
  (let* ((trailing_ws_pat "[ \t\n]*\\'")
         (original_whitespace (regex-match-string trailing_ws_pat s-old))
         (new_result (concat (replace-regexp-in-string trailing_ws_pat "" s-new) original_whitespace)))
    new_result))

(defun preserve-trailing-whitespace (fun s)
  "Run a string filter command, but preserve the amount of trailing whitespace. (ptw 'awk1 \"hi\")"
  (s-preserve-trailing-whitespace (apply fun (list s)) s))
(defalias 'ptw 'preserve-trailing-whitespace)

(defun filter-selected-region-through-function (fun)
  (let* ((start (if (pen-selected) (region-beginning) (point-min)))
         (end (if (pen-selected) (region-end) (point-max)))
         (doreverse (and (pen-selected) (< (point) (mark))))
         (removed (delete-and-extract-region start end))
         (replacement (str (ptw fun (str removed))))
         (replacement-len (length (str replacement))))
    (if buffer-read-only (new-buffer-from-string replacement)
      (progn
        (insert replacement)
        (let ((end-point (point))
              (start-point (- (point) replacement-len)))
          (push-mark start-point)
          (goto-char end-point)
          (setq deactivate-mark nil)
          (activate-mark)
          (if doreverse
              (cua-exchange-point-and-mark nil)))))))
(defalias 'filter-selection 'filter-selected-region-through-function)

(defmacro ntimes (n &rest body)
  (cons 'progn (flatten-once
                (cl-loop for i from 1 to n collect body))))

;; (let ((func-name "yo")) (pen-read-string "hi"))
;; TODO Use this is more places
(defun pen-read-string (prompt &optional initial-input history default-value inherit-input-method)
  (let ((fnn (pen-var-value-maybe 'func-name)))
    (if (sor fnn)
        (setq prompt (concat fnn " ~ " prompt)))
    (if (pen-var-value-maybe 'do-pen-batch)
        ""
      (read-string prompt initial-input history default-value inherit-input-method))))

(defun pen-selected-text (&optional ignore-no-selection keep-properties)
  "Just give me the selected text as a string. If it's empty, then nothing was selected.
region-active-p does not work for evil selection."
  (interactive)
  (let ((sel
         (cond
          ((or (region-active-p)
               (eq evil-state 'visual))
           (buffer-substring (region-beginning) (region-end)))
          (iedit-mode
           (iedit-current-occurrence-string))
          (ignore-no-selection nil)
          (t (pen-read-string "pen-selected-text: ")))))
    (if keep-properties
        sel
      (str sel))))

;; TODO collect from tmux instead
;; Should I start a tmux in the background and
;; connect to the buffer? Or always have tmux?
(defun pen-screen-text ()
  (pen-words 40 (pen-selection-or-surrounding-context 10))
  ;; TODO Add tmux support - wouldn't work for GUI well though
  ;; But in that case I would take screen shots with imagemagick
  ;; (buffer-string)
  )

(defun test-read-string ()
  (interactive)
  ;; (eval `(let ((func-name "yo")) (pen-read-string "hi")))
  ;; (let ((func-name "yo")) (pen-read-string "hi"))
  (let ((func-name "yo"))
    ;; (eval-string
    ;;  "(pen-read-string \"hi\")")
    (eval-string
     "(pen-selected-text)")))

(defun pen-screen-or-selection ()
  (let ((sel (pen-selection)))
    (if (sor sel)
        sel
      (pen-screen-text))))

(defun pen-screen-or-selection-ask ()
  (pen-ask (pen-screen-or-selection)))

(defun pen-selected-text-ignore-no-selection (&optional keep-properties)
  "Just give me the selected text as a string. If it's empty, then nothing was selected. region-active-p does not work for evil selection."
  (interactive)
  (pen-selected-text t t))

(defalias 'pen-selection 'pen-selected-text-ignore-no-selection)

(defun pen-token-length-warn (s)
  "Warn on token length, and ask to continue, in case it's high."
  s)

(defun pen-buffer-string (&optional select)
  ""
  ;; Trim to most relevant according to engine's max prompt length
  (if select
        (progn
          (set-mark (point-min))
          (goto-char (point-max))
          (activate-mark)))
  (buffer-string))

(defun pen-buffer-string-or-selection (&optional select)
  (let ((s (if mark-active
               (pen-selection)
             (pen-buffer-string select))))
    (pen-token-length-warn s)))

(defun pen-buffer-visible-or-selection (&optional select)
  (let ((s (if mark-active
               (pen-selection)
             (buffer-string-visible))))
    (pen-token-length-warn s)))

(defalias 'pps 'pp-to-string)

(defun xc (&optional s silent noautosave)
  "emacs kill-ring, xclip copy
when s is nil, return current contents of clipboard
when s is a string, set the clipboard to s"
  (interactive)
  (if (and
       s
       (not (stringp s)))
      (setq s (pps s)))
  (if (not (s-blank? s))
      (progn
        (kill-new s)
        (pen-sn "xsel --clipboard -i" s))
    (if (and (pen-selected-p)
             (not noautosave))
        (progn
          (setq s (pen-selected-text))
          (call-interactively 'kill-ring-save))))
  (if s
      (if (not silent) (message "%s" (concat "Copied: " s)))
    (progn
      ;; Frustratingly, shell-command-to-string uses the current directory.
      ;; (shell-command-to-string "xsel --clipboard --output")
      (pen-sn "xsel --clipboard --output"))))

(defun pen-ivy-completing-read (prompt collection
                                       &optional predicate require-match initial-input
                                       history def inherit-input-method)
  "This is like ivy-completing-read but it does not escape +"
  (let ((handler
         (and (< ivy-completing-read-ignore-handlers-depth (minibuffer-depth))
              (assq this-command ivy-completing-read-handlers-alist))))
    (if handler
        (let ((completion-in-region-function #'completion--in-region)
              (ivy-completing-read-ignore-handlers-depth (1+ (minibuffer-depth))))
          (funcall (cdr handler)
                   prompt collection
                   predicate require-match
                   initial-input history
                   def inherit-input-method))
      ;; See the doc of `completing-read'.
      (when (consp history)
        (when (numberp (cdr history))
          (setq initial-input (nth (1- (cdr history))
                                   (symbol-value (car history)))))
        (setq history (car history)))
      (when (consp def)
        (setq def (car def)))
      (let ((str (ivy-read
                  prompt collection
                  :predicate predicate
                  :require-match (when (and collection require-match)
                                   require-match)
                  :initial-input (cond ((consp initial-input)
                                        (car initial-input))
                                       (t
                                        initial-input))
                  :preselect def
                  :def def
                  :history history
                  :keymap nil
                  :dynamic-collection ivy-completing-read-dynamic-collection
                  :extra-props '(:caller ivy-completing-read)
                  :caller (if (and collection (symbolp collection))
                              collection
                            this-command))))
        (if (string= str "")
            (or def "")
          str)))))

(defmacro initvar (symbol &optional value)
  "defvar while ignoring errors"
  (let ((sym (eval symbol)))
    `(progn (ignore-errors (defvar ,sym nil))
            ;; (ignore-errors (defvar ,symbol nil))
            (if ,value (setq ,symbol ,value)))))

;; To get around an annoying error message
(defvar histvar nil)

(defun pen-uq (input)
  "Unquotes"
  (interactive)
  (pen-cl-sn "uq" :stdin input :chomp t))

(defun pen-qne (string)
    "Like q but without the end quotes"
    (pcre-replace-string "\"(.*)\"" "\\1" (pen-q string)))

(defun completing-read-hist (prompt &optional initial-input histvar default-value override-func-name)
  "read-string but with history and newline evaluation."
  (setq initial-input (or initial-input
                          ""))

  (if (pen-var-value-maybe 'do-pen-batch)
      ""
    (progn
      (let ((fnn (or
                  override-func-name
                  (pen-var-value-maybe 'func-name))))
        (if (sor fnn)
            (setq prompt (concat fnn " ~ " prompt))))

      (if (not histvar)
          (setq histvar (intern (concat "completing-read-hist-" (slugify prompt)))))

      (setq prompt (sor prompt ":"))

      (if (not (string-match " $" prompt))
          (setq prompt (concat prompt " ")))

      (if (not (variable-p histvar))
          (eval `(defvar ,histvar nil)))
      (if (and (not initial-input)
               (listp histvar))
          (setq initial-input (first histvar)))

      ;; (pen-etv (completing-read-hist "test: " (snc "cat $PROMPTS/generate-transformative-code.prompt | yq -r '.examples[0]'")))
      ;; (pen-etv (pen-qne (snc "cat /home/shane/var/smulliga/source/git/semiosis/prompts/prompts/generate-transformative-code.prompt | yq -r '.examples[0]'")))
      ;; (eval-string (concat "\"" (pen-qne "lskjdfldks\ndshi\\nslkfjof") "\""))
      ;; (setq initial-input (bs "\"" initial-input))
      ;; (setq initial-input (bs "\n" initial-input))

      ;; (pen-etv (completing-read-hist "test2: " "test\nt\\nest"))
      (setq initial-input (pen-qne initial-input))

      (eval `(progn
               (let ((inhibit-quit t))
                 (or (with-local-quit
                       (let* ((completion-styles
                               '(basic))
                              (s (str (pen-ivy-completing-read ,prompt ,histvar nil nil initial-input ',histvar nil)))
                              ;; (s (string-replace "\\n" "\n" s))

                              ;; Using the perl script isn't ideal
                              (s (pen-uq s)))

                         (setq ,histvar (seq-uniq ,histvar 'string-equal))
                         s))
                     "")))))))
(defalias 'read-string-hist 'completing-read-hist)

(defun vector2list (pen-v)
  (append pen-v nil))

(defun region-or-buffer-string ()
  (interactive)
  (if (or (region-active-p) (eq evil-state 'visual))
      (str (buffer-substring (region-beginning) (region-end)))
    (str (buffer-substring (point-min) (point-max)))))

(defun current-major-mode-string ()
  "Get the current major mode as a string."
  (str major-mode))

(defun pen-string-to-buffer (string)
  "temporary buffer from string"
  (with-temp-buffer
    (insert string)))

;; This should also check the file extension
(defun pen-detect-language (&optional detect buffer-not-selection world programming)
  "Returns the language of the buffer or selection."
  (interactive)

  (let* ((text (if buffer-not-selection
                   (buffer-string)
                 (region-or-buffer-string)))
         (buf (nbfs text))
         (mode-lang (and (not detect)
                         (mode-to-lang (current-major-mode-string))))
         (mode-lang
          (cond
           ((string-equal "fundamental" mode-lang) nil)
           ((string-equal "lisp-interaction" mode-lang) nil)
           (t mode-lang)))
         (programming-lang (and (not world)
                                (sor (language-detection-string text))))
         (world-lang (and (not programming-lang)
                          (sor (with-current-buffer buf
                                 (insert text)
                                 (guess-language-buffer)))))
         (lang (sor mode-lang programming-lang world-lang)))

    (if (string-equal "rustic" lang) (setq lang "rust"))
    (if (string-equal "clojurec" lang) (setq lang "clojure"))

    (kill-buffer buf)
    (str lang)))

(defun mode-to-lang (&optional modesym)
  (if (not modesym)
      (setq modesym major-mode))

  (if (symbolp modesym)
      (setq modesym (symbol-name modesym)))

  (s-replace-regexp "-mode$" "" modesym))

(defun lang-to-mode (&optional langstr)
  (if (not langstr)
      (setq langstr (pen-detect-language)))

  (setq langstr (slugify langstr))

  (cond
   ((string-equal "elisp" langstr)
    (setq langstr "emacs-lisp"))
   ((string-equal "bash" langstr)
    (setq langstr "sh")))

  (intern (concat langstr "-mode")))

(defun get-ext-for-lang (langstr)
  (get-ext-for-mode (lang-to-mode langstr)))

(defun get-ext-for-mode (&optional m)
  (interactive)
  (if (not m) (setq m major-mode))

  (cond ((eq major-mode 'json-mode) "json")
        ((eq major-mode 'python-mode) "py")
        ((eq major-mode 'fundamental-mode) "txt")
        (t (try (let ((result (chomp (s-replace-regexp "^\." "" (scrape "\\.[a-z0-9A-Z]+" (car (rassq m auto-mode-alist)))))))
                  (setq result (cond ((string-equal result "pythonrc") "py")
                                     (t result)))

                  (if (called-interactively-p)
                      (message result)
                    result))
                "txt"))))
(defalias 'get-path-ext-from-mode-alist 'get-ext-for-mode)

(defalias 'second 'cadr)

;; I would like to disable the yaml lsp server for .prompt files.
;; At least, until a schema for it is made in schemastore.
;; http://www.schemastore.org/json/
(defun maybe-lsp ()
  "Maybe run lsp."
  (interactive)
  (cond
   ((derived-mode-p 'prompt-description-mode)
    (message "Disabled lsp for prompts"))
   ((derived-mode-p 'completer-description-mode)
    (message "Disabled lsp for completers"))
   (t
    (call-interactively 'lsp))))

(defun pen-awk1 (s)
  (pen-sn "awk 1" s))

(defun pen-onelineify (s)
  (pen-snc "pen-str onelineify" s))

(defun pen-unonelineify (s)
  (pen-sn "pen-str unonelineify" s))

(defun pen-onelineify-safe (s)
  (pen-snc "pen-str onelineify-safe" s))

(defun pen-unonelineify-safe (s)
  (pen-sn "pen-str unonelineify-safe" s))

(defun replace-region (s)
  ""
  (let ((rstart (if (region-active-p) (region-beginning) (point-min)))
        (rend (if (region-active-p) (region-end) (point-max)))
        (was_selected (pen-selected-p))
        (deactivate-mark nil))

    (if buffer-read-only
        (progn
          (message "buffer is readonly. placing in temp buffer")
          (nbfs s))
      (progn
        (let ((doreverse (< (point) (mark))))
          (delete-region
           rstart
           rend)
          (insert s)

          (if doreverse
              (call-interactively 'cua-exchange-point-and-mark)))

        (if (not was_selected)
            (deactivate-mark))))))

(defun write-to-file (stdin file_path)
  ;; The ignore-errors is needed for babel for some reason
  (ignore-errors (with-temp-buffer
                   (insert stdin)
                   (delete-file file_path)
                   (write-file file_path nil))))

;; Sadly this doesn't work very well in pen-eval-for-host.
(defun sh-write-to-file (stdin file_path)
  ;; This may hang less often
  (pen-sn (pen-cmd "tee" file_path) stdin))

(defmacro pen-eval-for-host (host-fp
                             ;; sentinel
                             &rest body)
  `(let ((result
          (progn ,@body)))
     ;; (message (concat "writing to /tmp/eval-output-" ,daemon-name ".txt"))

     (shut-up
       (if result
           ;; use sh-write-to-file instead of write-to-file to prevent hanging
           (write-to-file (str result) ,host-fp)
         (write-to-file "" ,host-fp))
       ;; (f-touch sentinel)
       )
     ;; (message "written")
     nil
     ;; Not sure if I want this to be output
     ;; result
     ))

(defun pen-var-value-maybe (sym)
  (cond
   ((symbolp sym) (if (variable-p sym)
                      (eval sym)))
   ((numberp sym) sym)
   ((stringp sym) sym)
   (t sym)))

(defun -uniq-u (l &optional testfun)
  "Return a copy of LIST with all non-unique elements removed."

  (if (not testfun)
      (setq testfun 'equal))

  ;; Here, contents-hash is some kind of symbol which is set

  (setq testfun (define-hash-table-test 'contents-hash testfun 'sxhash-equal))

  (let ((table (make-hash-table :test 'contents-hash)))
    (cl-loop for string in l do
             (puthash string (1+ (gethash string table 0))
                      table))
    (cl-loop for key being the hash-keys of table
             unless (> (gethash key table) 1)
             collect key)))

(defun lm-define (term &optional prepend-lm-warning topic)
  (interactive)
  (let* (;; (final-topic
         ;;  (if (sor topic)
         ;;      (concat " in the context of " topic)
         ;;    ""))
         (def
          ;; (pf-define-word-for-glossary/1 (concat term final-topic))
          (pf-define-word-for-glossary/2 term topic)))

    (if (sor def)
        (progn
          (if prepend-lm-warning
              (setq def (concat "NLG: " (ink-propertise def))))
          (if (interactive-p)
              (pen-etv def)
            def)))))

;; Example
(defun gpt-test-haskell ()
  (let ((lang
         (pen-detect-language (pen-selected-text))))
    (message (concat "Language:" lang))
    (istr-match-p "Haskell" (message lang))))

(defun pen-word-clickable ()
  (or (not (pen-selected-p))
      (= 1 (length (s-split " " (pen-selection))))))

(defun identity-command (&optional body)
  (interactive)
  (identity body))

;; j:pen-add-to-glossary-file-for-buffer
(defun pen-define (term)
  (interactive (list (pen-thing-at-point-ask "word" t)))
  (message (lm-define term t (pen-topic t t :no-select-result t))))

(defun pen-define-general-knowledge (term)
  (interactive (list (pen-thing-at-point-ask "word" t)))
  (pen-add-to-glossary term nil nil "general knowledge")
  ;; (message (lm-define term t "general knowledge"))
  )

(defun pen-define-detectlang (term)
  (interactive (list (pen-thing-at-point-ask "word" t)))
  (pen-add-to-glossary term nil nil (pen-detect-language)))

(defun pen-define-word-for-topic (term topic)
  (interactive (list (pen-thing-at-point-ask "word" t)
                     (read-string-hist "pen define word (topic): ")))
  (pen-add-to-glossary term nil nil topic))

(defun pen-extract-keywords ()
  (interactive)

  (pen-etv (pps (pen-single-generation (pf-keyword-extraction/1 (pen-selected-text) :no-select-result t))))
  ;; (nbfs
  ;;  (pps
  ;;   (str2lines
  ;;    (pen-snc
  ;;     (concat
  ;;      "printf -- '%s\n' "
  ;;      ;; It doesn't always generate keywords, so it's not very reliable
  ;;      (pen-single-generation (pf-keyword-extraction/1 (pen-selected-text) :no-select-result t))
  ;;      ;; (pf-keyword-extraction/1 (pen-selected-text) :no-select-result t)
  ;;      )))))
  ;; nil 'emacs-lisp-mode
  )

(defun s-replace-regexp-thread (regex rep string)
  (s-replace-regexp regex rep string t))

(defmacro do-substitutions (str &rest tups)
  ""
  (let* ((newtups (mapcar (lambda (tup) (cons 's-replace-regexp-thread tup)) tups)))
    `(progn (->>
                ,str
              ,@newtups))))
(defalias 'seds 'do-substitutions)

(defun pen-mnm (input)
  "Minimise string."
  ;; (pen-sn "mnm" input)
  (if input
      (seds (pen-umn input)
            ((f-join pen-prompts-directory "prompts") "$PROMPTS")
            (user-emacs-directory "$EMACSD")
            (penconfdir "$PEN")
            ((f-join user-emacs-directory "pen.el") "$PENEL")
            (user-home-directory "$HOME"))))

(defun pen-umn (input)
  "Unminimise string."
  (if input
      (seds input
            ("~" user-home-directory)
            ("$PROMPTS" (f-join pen-prompts-directory "prompts"))
            ("$EMACSD" user-emacs-directory)
            ("$PEN" penconfdir)
            ("$PENEL" (f-join user-emacs-directory "pen.el"))
            ("$HOME" user-home-directory)
            ("//" "/"))))

(defun pen-topic-ask (&optional prompt)
  (setq prompt (sor prompt "pen-topic-ask"))
  (read-string-hist
   (concat prompt ": ")
   (pen-batch (pen-topic t))))

(defun pen-show-last-prompt ()
  (interactive)
  (pen-etv (f-read (f-join penconfdir "last-final-prompt.txt"))))

(defun pen-set-major-mode (name)
  (setq name (str name))

  (funcall (cond ((string= name "shell-mode") 'sh-mode)
                 ((string= name "emacslisp-mode") 'common-lisp-mode)
                 (t (intern name)))))

(defun pen-guess-major-mode-set (&optional lang)
  "Guesses which major mode this file should have and set it."
  (interactive)
  (if (not lang)
      (setq lang
            (pen-detect-language-ask)))
  ;; (setq lang (language-detection-string (buffer-string))
  (pen-set-major-mode (lang-to-mode lang)))

(defmacro df (name &rest body)
  "Named interactive lambda with no arguments"
  `(defun ,name ()
     (interactive)
     ,@body))

(defun pen-sed (command stdin)
  "wrapper around sed"
  (interactive)
  (setq stdin (str stdin))

  (setq command (concat "sed '" (str command) "'"))
  (pen-sn command stdin))

;; (alist2pairs '(("hi" . "yo") ("my day" . "is good")))
;; (alist2pairs '((hi . "yo") (my-day . "is good")))
(defun alist2pairs (al)
  (mapcar (lambda (e)
            (list (intern (slugify (str (car e))))
                  (cdr e)))
          al))

(defun pen-safe-alist2pairs (al)
  (mapcar (lambda (e)
            (list (intern (slugify (str (car e))))
                  (if (listp (cdr e))
                      ""
                    (cdr e))))
          al))

(defmacro pen-let-keyvals (keyvals &rest body)
  `(let ,(pen-safe-alist2pairs (eval keyvals))
     ,@body))

;; (pen-let-keyvals '(("hi" . "yo") ("my day" . "is good")) my-day)
(defun pen-test-let-keyvals ()
  (interactive)
  (pen-let-keyvals '(("hi" . "yo") ("my day" . "is good")) hi))

(defun pen-test-alist-set ()
  (let ((vals-sofar))
    (pen-alist-set 'vals-sofar 'yoyo "hi")))

(defun pen-test-let-keyvals ()
  (interactive)
  ;; (eval
  ;;  `(pen-let-keyvals '(("postags" . "hi")) (eval-string "postags")))
  (eval
   `(pen-let-keyvals '((postags . "hi")) (eval-string "postags")))
  ;; (pen-let-keyvals '(("postags" . "hi")) postags)
  )

(defun pen-subprompts-to-alist (ht)
  (ht->alist (-reduce 'ht-merge (vector2list ht))))

(defun pen-test-kickstarter ()
  (eval
   `(pen-let-keyvals
     '(("kickstarter" . "Python 3.8.5 (default, Jan 27 2021, 15:41:15)\nType 'copyright', 'credits' or 'license' for more information\nIPython 7.21.0 -- An enhanced Interactive Python. Type '?' for help.\n\nIn [1]: <expression>\nOut\n"))
     (if "kickstarter"
         (eval-string "kickstarter")
       (read-string-hist "history: " "In [1]:")))))

(defun pen-test-kickstarter-2 ()
  (let
      ((kickstarter "Python 3.8.5 (default, Jan 27 2021, 15:41:15)
Type 'copyright', 'credits' or 'license' for more information
IPython 7.21.0 -- An enhanced Interactive Python. Type '?' for help.

In [1]: <expression>
Out
"))
    (if "kickstarter"
        (eval-string "kickstarter")
      (read-string-hist "history: " "In [1]:"))))

(comment
 (defun pen-test-kickstarter-3 ()
   `(eval
     `(pen-let-keyvals
       ',',(pen-subprompts-to-alist subprompts)
       (if ,,default
           (eval-string ,,(str default))
         (read-string-hist ,,(concat varname ": ") ,,example))))))

(defun pen-activate-mark ()
  (setq deactivate-mark nil)
  (activate-mark))

(defun pen-insert (s)
  (interactive)
  (cond
   ((derived-mode-p 'term-mode)
    (term-send-raw-string s))
   ((derived-mode-p 'vterm-mode)
    (vterm-insert s))
   ;; This must come *after* the checks to term-mode
   (buffer-read-only
    (pen-etv s)
    (call-interactively 'mark-whole-buffer)
    (message "buffer read only, placing in temporary buffer"))
   ((derived-mode-p 'comint-mode)
    (let ((p (point)))
      (insert s)))
   (t
    (let ((p (point)))
      (insert s)
      (set-mark p)
      (pen-activate-mark)))))

(defun pp-oneline (l)
  (chomp (replace-regexp-in-string "\n +" " " (pp l))))
(defalias 'pp-ol 'pp-oneline)

(defun pp-map-line (l)
  (string-join (mapcar 'pp-oneline l) "\n"))

(defun pen-sed (command stdin)
  "wrapper around sed"
  (interactive)
  (setq stdin (str stdin))

  (setq command (concat "sed '" (str command) "'"))
  (pen-sn command stdin))

(defmacro pen-macro-sed (expr &rest body)
  "This transforms the code with a sed expression"
  (let* ((codestring (pp-map-line body))
         (ucodestring (pen-sed expr codestring))
         (newcode (pen-eval-string (concat "'(progn " ucodestring ")"))))
    newcode))
(defalias 'pen-ms 'pen-macro-sed)

;; Only bind if there isn't a binding currently?
(comment
 (defun pen-define-key ()
   (let ((cb (key-binding (kbd (format "%s" (key-description (read-key-sequence-vector "Key: ")))))))

     (if (not cb)
         (define-key pen-map (kbd "seq"))))))

(defmacro pen-define-key (map kbd-expr func-sym)
  (macroexpand
   `(pen-ms "/H-[A-Z]\\+/{p;s/H-\\([A-Z]\\+\\)/<H-\\L\\1>/;}"
            (define-key ,map ,kbd-expr ,func-sym))))

(defalias 'λ 'lambda)

(defun pen-round-to-dec (n &optional decimal-count)
  (setq decimal-count (or decimal-count 1))
  (let ((mult (expt 10 decimal-count)))
    (number-to-string
     (/
      (fround
       (*
        mult
        n))
      mult))))

(defun ignore-truthy (&rest _arguments)
  "Do nothing and return nil.
This function accepts any number of ARGUMENTS, but ignores them."
  (interactive)
  t)

(defmacro auto-yes (&rest body)
  ""
  `(cl-letf (((symbol-function 'yes-or-no-p) #'ignore-truthy)
             ((symbol-function 'y-or-n-p) #'ignore-truthy))
     (progn ,@body)))
(defmacro auto-no (&rest body)
  ""
  `(cl-letf (((symbol-function 'yes-or-no-p) #'ignore)
             ((symbol-function 'y-or-n-p) #'ignore))
     (progn ,@body)))

(defun pen-go-to-last-results-dir ()
  (interactive)
  (let ((user (pen-snc "whoami")))
    (if (not (string-equal "root" user))
        (pen-sn (format "sudo chown -R %s:%s ~/.pen" user user)))

    (let ((dir
           (s-replace-regexp "^/root/" (format "/home/%s/" user) (pen-tmp-preview "lm-complete-stdout"))))
      (dired dir))))

(defun pen-lm-define (term &optional prepend-lm-warning topic)
  (interactive)
  (let* (;; (final-topic
         ;;  (if topic
         ;;      (concat " in the context of " topic)
         ;;    ""))
         (def
          ;; (pf-define-word-for-glossary/1 (concat term final-topic))
          (pf-define-word-for-glossary/2 term topic)))

    (if (sor def)
        (progn
          (if prepend-lm-warning
              (setq def (concat "NLG: " def)))
          (if (interactive-p)
              (pen-etv def)
            def)))))

(defun beginning-of-line-or-indentation ()
  "move to beginning of line, or indentation"
  (interactive)
  (cond
   ((major-mode-p 'dun-mode)
    (progn
      (beginning-of-line)
      (if (looking-at-p "^>")
          (forward-char))))
   ((or (major-mode-p
         'haskell-interactive-mode)
        (major-mode-p 'eshell-mode))
    (let ((my-mode nil))
      (execute-kbd-macro (kbd "C-a"))))
   (t
    (progn
      (if (bolp)
          (back-to-indentation)
        (beginning-of-line))))))

(defun pen-copy-line (&optional arg)
  "arg is C-u, if provided"
  (interactive "P")
  (if (region-active-p)
      (progn
        (execute-kbd-macro (kbd "M-w"))
        (deselect))
    (progn
      (if (equal current-prefix-arg nil)
          (progn
            (end-of-line)
            (call-interactively 'cua-set-mark)
            (beginning-of-line-or-indentation)
            (beginning-of-line-or-indentation)
            (call-interactively 'cua-exchange-point-and-mark))
        (progn
          (beginning-of-line)
          (cua-set-mark)
          (end-of-line))))))
(define-key global-map (kbd "M-Y") 'pen-copy-line)

(defun pen-git-buffer-name-to-file-name ()
  (if (string-match "\.~" (buffer-name))
      (pen-sn "tr -s \/ _" (sed "s/^\\(.*\\)\\(\\.~\\)\\(.*\\)$/\\3\\1/" (buffer-name)))
    (buffer-name)))

(defun pen-save-buffer-to-file ()
  (write-to-file
   (buffer-string)
   (pen-tf
    (pen-git-buffer-name-to-file-name))))

(defun concat-string (&rest body)
  "Converts to string and concatenates."
  (mapconcat 'str body ""))

(defun pen-tmux-edit (&optional editor window_type)
  "Simple function that allows us to open the underlying file of a buffer in an external program."
  (interactive (list "pen-v" "spv"))
  (if (not editor)
      (setq editor "pen-v"))

  (if (not window_type)
      (setq window_type "spv"))

  ;; buffer-string-visible

  (let ((min (if (major-mode-p 'term-mode)
                 (first (buffer-string-visible-points))
               (point-min)))
        (max (if (major-mode-p 'term-mode)
                 (second (buffer-string-visible-points))
               (point-min))))

    (let ((line-and-col (concat-string "+" (line-number-at-pos) ":" (current-column))))
      (if (and buffer-file-name
               (not (string-match "\\[*Org Src" (buffer-name))))
          (progn
            (save-buffer)
            (shell-command (concat-string "pen-tm -d -te " window_type " -fa " editor " " line-and-col " " (pen-q buffer-file-name))))
        (cond ((string-match "\.~" (buffer-name))
               (let ((new_fp (pen-save-buffer-to-file)))
                 (shell-command-on-region min max (concat-string "pen-tsp -wincmd " window_type " -fa " editor " " line-and-col))))
              ((string-match "\\[*Org Src" (buffer-name))
               (shell-command-on-region min max (concat-string "pen-tsp -wincmd " window_type " -fa " editor " " line-and-col)))
              (t
               (shell-command-on-region min max (concat-string "pen-tsp -wincmd " window_type " -fa " editor " " line-and-col))))))))
(defalias 'open-in 'pen-tmux-edit)

(defun pen-tm-edit-v-in-nw ()
  "Opens pen-v in new window for buffer contents"
  (interactive)
  (pen-tmux-edit "pen-v" "nw"))
(define-key pen-map (kbd "C-c o") #'pen-tm-edit-v-in-nw)

(defun pen-tm-edit-pet-v-in-nw ()
  "Opens pen-v in new window for buffer contents"
  (interactive)
  (pen-tmux-edit "pet pen-v" "nw"))
(define-key pen-map (kbd "C-c O") #'pen-tm-edit-pet-v-in-nw)

(defun parent-modes ()
  (interactive)
  (let ((ms (parent-mode-list major-mode)))
    (xc (car (last ms)) nil)
    (message (pp-to-string ms))))

(defun pen-kill-other-clients (&optional including-this-client)
  "Kills the emacsclient frames for clients"
  (interactive)
  (let ((this-frame (selected-frame)))
    (dolist (p
             (-filter 'identity
                      (mapcar
                       (lambda (f)
                         (frame-parameter f 'client))
                       (-filter
                        (lambda (f) (or including-this-client
                                        (not (equal this-frame f))))
                        (frame-list)))))
      (delete-process p))))

(defun dired-here ()
  (interactive)
  (dired "."))

(defun pen-columnate-window (&optional max-cols)
  (interactive)
  (delete-other-windows)
  (setq max-cols (or max-cols 100))
  (setq max-cols (- max-cols 1))
  (let ((w (+ (/ (frame-width) 80) 0)))
    (if (> w max-cols)
        (setq w max-cols))
    (dotimes (i w)
      (split-window-right))
    (balance-windows)
    (follow-mode)))

(defalias 'pen-get-top-level 'projectile-project-root)

(defun pen-cd-vc-cd-top-level ()
  (interactive)
  (dired (pen-get-top-level)))

(defun dired-here-columnate ()
  (interactive)
  (with-current-buffer
      (dired ".")
    (pen-columnate-window 2)))

(defun pen-ns (s_message &optional from_clipboard)
  (let ((com "ns")
        (mess (or s_message
                  "nil")))
    (if from_clipboard
        (setq com (concat com " -clip")))
    (chomp (pen-sn com (chomp (str mess))))
    s_message))

(defmacro pen-with (package &rest body)
  "This attempts to run code dependent on a package and otherwise doesn't run the code."
  `(when (require ,package nil 'noerror)
     ,@body))

(defun escape (chars input)
  "Escapes chars inside a string"
  (let ((re (eval `(rx (group (any ,@(butlast (cdr (split-string chars "")))))))))
    (replace-regexp-in-string re "\\\\\\1" input)))

(defun pen-bs (chars input)
  (escape input chars))

(defun pen-revert (arg)
  (interactive "P")
  (remove-overlays (point-min) (point-max))
  (pen-run-buttonize-hooks)
  (let ((l (line-number-at-pos))
        (c (current-column)))

    (if arg
        (progn (force-revert-buffer)
               (message "%s" "Reverted from disk"))
      (progn (try (progn (if (string-match-p "\\*Org .*" (buffer-name))
                             (message "Not going to revert.")
                           (undo-tree-restore-state-from-register ?^))
                         )
                  (progn (force-revert-buffer)
                         )))       ; revert without loading from disk
      )

    (goto-line l)
    (move-to-column c)
    ;; For some reason, this hook is added whenever I revert. Therefore remove it. What is adding it?
    (remove-hook 'after-save-hook (lambda nil (byte-force-recompile default-directory)) t))
  (ignore-errors
    (clear-undo-tree))
  (company-cancel))

(defun pen-etv-urls-in-region (&optional s)
  (interactive)
  (new-buffer-from-string (urls-in-region-or-buffer s)
                          nil 'org-mode))

(defun pen-yank-dir ()
  (interactive)
  ;; (xc-m default-directory)
  (cond
   ((derived-mode-p 'proced-mode) (call-interactively 'proced-get-pwd))
   (t
    (xc (chomp (pen-ns default-directory)))
    ;; (xc (chomp (get-dir)))
    )))

(defun pen-yank-file ()
  (interactive)
  (xc (pen-ns (chomp (f-basename (get-path))))))

(defalias 'pen-yank-bn 'pen-yank-file)

(defun pen-yank-path ()
  (interactive)
  (if mark-active
      (with-current-buffer (new-buffer-from-string (pen-selected-text))
        (guess-major-mode)
        (xc (pen-ns (get-path nil nil t)))
        (kill-buffer))
    (xc (pen-ns (get-path)))))

(defun pen-yank-git-path ()
  (interactive)
  (let ((path
         (chomp (pen-ns (pen-bp pen-xa git-file-to-url -noask (get-path))))))

    (if mark-active
        (setq path (concat path "#L" (str (org-current-line)))))
    (kill-new path)))

(defun pen-yank-git-path-sha ()
  (interactive)
  (let ((path
         (chomp (pen-ns (pen-bp pen-xa git-file-to-url -s -noask (get-path))))))

    (if mark-active
        (setq path (concat path "#L" (str (org-current-line)))))
    (kill-new path)))

(defun pen-evil-enabled ()
  "True if in evil mode. Spacemacs agnostic."
  ;; Keep in mind that evil-mode is enabled when emacs is in holy mode. I have to also check if we are spacemacs

  (minor-mode-enabled evil-mode))

;; These need more work for pen.el
(defun pen-evil-star-maybe ()
  "Perform an evil star if text is selected."
  (interactive)

  (if mark-active
      (progn
        (pcre-mode -1)
        (evil-search-word-forward)
        ;; (execute-kbd-macro (kbd "p"))
        ;; (deselect)
        )
    (let ((pen nil))
      (execute-kbd-macro (kbd "*")))))

(defun pen-evil-star ()
  "Perform an evil star if text is selected."
  (interactive)

  (progn
    (pcre-mode -1)
    (evil-search-word-forward)
    ;; (deselect)
    ;; (execute-kbd-macro (kbd "p"))
    ))

(defun if-shebang-exec-otherwise-remove ()
  "Adds x perm to current file acl if file has a shebang."
  (interactive)
  (ignore-errors
    (try (if (string-equal (buffer-substring (point-min) (2+ (point-min))) "#!")
             (progn
               (if (not (blq pen-ux isx (s/rp (buffer-name))))
                   (progn
                     (pen-ns "file is a shebang but not executable. making file executable.")
                     (bl chmod a+x (buffer-file-name)))))
           (progn
             (if (blq pen-ux isx (s/rp (buffer-name)))
                 (progn
                   (pen-ns "file is not shebang and is executable. removing executable.")
                   (bl chmod a-x (buffer-file-name)))))))))

(defun pen-save ()
  (interactive)
  (save-buffer)
  (shut-up (if-shebang-exec-otherwise-remove))
  (message "%s" "File saved"))

(defmacro pen-defun (name arglist suggest-predicates &optional docstring &rest body)
  "Same as defun, except provide context predicates.
If any of the suggest predicates evaluated to t, then suggest the function"
  (declare (doc-string 3) (indent 2))
  (or name (error "Cannot define '%s' as a function" name))
  (if (null
       (and (listp arglist)
            (null (delq t (mapcar #'symbolp arglist)))))
      (error "Malformed arglist: %s" arglist))
  (if (null suggest-predicates)
      (error "Malformed suggest-predicates: %s" suggest-predicates))
  (setq pen-context-tuples (-uniq (append `((,suggest-predicates
                                         ,name))
                                          pen-context-tuples)))
  (let ((decls (cond
                ((eq (car-safe docstring) 'declare)
                 (prog1 (cdr docstring) (setq docstring nil)))
                ((and (stringp docstring)
                      (eq (car-safe (car body)) 'declare))
                 (prog1 (cdr (car body)) (setq body (cdr body)))))))
    (if docstring (setq body (cons docstring body))
      (if (null body) (setq body '(nil))))
    (let ((declarations
           (mapcar
            #'(lambda (x)
                (let ((f (cdr (assq (car x) defun-declarations-alist))))
                  (cond
                   (f (apply (car f) name arglist (cdr x)))
                   ;; Yuck!!
                   ((and (featurep 'cl)
                         (memq (car x)  ;C.f. cl-do-proclaim.
                               '(special inline notinline optimize warn)))
                    (push (list 'declare x)
                          (if (stringp docstring)
                              (if (eq (car-safe (cadr body)) 'interactive)
                                  (cddr body)
                                (cdr body))
                            (if (eq (car-safe (car body)) 'interactive)
                                (cdr body)
                              body)))
                    nil)
                   (t (message "Warning: Unknown defun property `%S' in %S"
                               (car x) name)))))
            decls))
          (def (list 'defalias
                     (list 'quote name)
                     (list 'function
                           (cons 'lambda
                                 (cons arglist body))))))
      (if declarations
          (cons 'prog1 (cons def declarations))
        def))))

(provide 'pen-support)