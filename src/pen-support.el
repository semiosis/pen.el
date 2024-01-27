;; To work around an issue with
;; Debugger entered--Lisp error: (void-function make-closure)
;; in f-join.
;; It's happening for all f functions on pen-debian.
;; Try recompiling emacs
;; (defun f-join (&rest strings)
;;   (s-join "/" strings))

(defmacro never (&rest body)
  "Do not run this code"
  `(if nil
       (progn
         ,@body)))

(defun pen-var-value-maybe (sym)
  "This function gets the value of the symbol"
  (cond
   ((symbolp sym) (if (variable-p sym)
                      (eval sym)))
   ((numberp sym) sym)
   ((stringp sym) sym)
   (t sym)))

(defun buffer2string (buffer)
  "This function gets the contents of the buffer"
  (if (not buffer)
      ""
    (with-current-buffer buffer
      (save-restriction
        (widen)
        (buffer-substring-no-properties (point-min) (point-max))))))

(defun pen-tf (template &optional input ext)
  "Create a temporary file."
  (setq ext (or ext "txt"))
  (let ((fp (pen-snc (concat "mktemp -p /tmp " (pen-q (concat "XXXX" (slugify template) "." ext))))))
    (if (and (sor fp)
             (sor input))
        (shut-up (write-to-file input fp)))
    fp))

(defun pen-is-glossary-file (&optional fp)
  "This function returns true if the file is a glossary file."
  ;; This path works also with info
  (setq fp (or fp
               (get-path nil t)
               ""))

  (or
   (re-match-p "glossary\\.txt$" fp)
   (re-match-p "words\\.txt$" fp)
   (re-match-p "glossaries/.*\\.txt$" fp)))

(defun pen-yas-expand-string (ys)
  "This function expands the string according to yasnippet syntax"
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

(defalias 'typeof 'type-of)
(defalias 'type 'type-of)

(defun pen-eval-string (string)
  "Evaluate elisp code stored in a string."
  (eval (car (read-from-string (format "(progn %s)" string)))))
(defalias 'eval-string 'pen-eval-string)

(defun prin1-to-string-safe (s)
  (if s
      (prin1-to-string s)
    "\"\""))

(defun e/escape-string (&rest strings)
  (let ((print-escape-newlines t))
    (s-join " " (mapcar 'prin1-to-string-safe strings))))
(defalias 'pen-q 'e/escape-string)
;; (defalias 'pen-q 'e/escape-string)

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

(defun variable-p (s)
  (and (not (eq s nil))
       (boundp s)))

(defun calling-function ()
  "Gets the name of the function you are inside. Does not work for byte-compiled."
  (let ((n 6) ;; nestings in this function + 1 to get out of it
        func
        bt)
    (while (and (setq bt (backtrace-frame n))
                (not func))
      (setq n (1+ n)
            func (and bt
                      (nth 0 bt)
                      (nth 1 bt))))
    func))

;; For docker
(if (not (variable-p 'user-home-directory))
    (defvar user-home-directory nil))
(setq user-home-directory (or user-home-directory "/root"))

(defset pen-user-emacs-directory
  (let* ((default-emacs-dir (string-replace "$HOME" user-home-directory user-emacs-directory))
         (host-emacs-dir (f-join (string-replace "$HOME" user-home-directory user-emacs-directory)
                                 "host"))
         (emacs-dir (cond ((f-directory-p host-emacs-dir) host-emacs-dir)
                          t  default-emacs-dir)))
    (s-replace "//" "/" emacs-dir)))

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

(defmacro defset (symbol value &optional documentation)
  "Instead of doing a defvar and a setq, do this. [[http://ergoemacs.org/emacs/elisp_defvar_problem.html][ergoemacs.org/emacs/elisp_defvar_problem.html]]"

  `(progn (defvar ,symbol ,documentation)
          (setq ,symbol ,value)))

(defset pen-directories nil)

(defmacro defdir (symbol value &optional documentation)
  "This does a defset, but adds the symbol to a list of directories"

  `(progn
     (add-to-list 'pen-directories ',symbol)
     (defvar ,symbol ,documentation)
     (setq ,symbol ,value)))

(defun dired-open-pen-defdir ()
  (interactive)

  (let ((dir (tv (fz (-zip-lists pen-directories
                                 (mapcar 'eval pen-directories))
                     nil nil "dired-open-pen-defdir:"))))
    (if dir
        (dired (cdr dir)))))

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
  (let ((c (shut-up
             (shut-up-c (pwd)))))
    (if c
        (f-expand (substring c 10))
      default-directory)))

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
                ;; (pen-sps (concat
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

  ;; It fails from eww
  (ignore-errors
    (if (not tramp-dir)
        (setq tramp-dir (get-dir t)))

    (if tramp-dir
        (let ((tmd (tramp-mountdir tramp-dir t))
              (trd (tramp-remotedir tramp-dir)))
          (f-join tmd (s-replace-regexp "^/" "" trd))))))

(defun get-dir (&optional dont-clean-tramp)
  "Gets the directory of the current buffer's file. But this could be different from emacs' working directory.
Takes into account the current file name."
  (shut-up-c
   (let* ((filedir (if buffer-file-name
                       (file-name-directory buffer-file-name)
                     (cwd)))
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
  (if (sor s)
      (split-string s "\n")))

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

(defun find-package (thing)
  (pen-mu
   (let ((pat (concat "(provide '" (str thing) ")"))
         (dir "$HOME/.emacs.d/host/pen.el/src"))
     (open-pat pat ".el" dir))))

(defun pen-find-thing (thing)
  (interactive)
  (if (stringp thing)
      (setq thing (intern thing)))
  (try (find-function thing)
       (find-variable thing)
       (find-face-definition thing)
       (find-package thing)
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

(defun escape (chars input)
  "Escapes chars inside a string"
  (let ((re (eval `(rx (group (any ,@(butlast (cdr (split-string chars "")))))))))
    (replace-regexp-in-string re "\\\\\\1" input)))

(defun pen-bs (chars input)
  (escape chars input))

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
                          (pen-bs "`" (pen-q rhs)))
                      ""))))))))

(defun pen-worker-name ()
  (let ((d (daemonp)))
    (if d
        (if (stringp d)
            (f-filename (daemonp))
          ;; Sometimes it's a bool
          "DEFAULT")
      "")))

(defun sh (&optional cmd stdin b_output tm_session shell b_switch_to tm_wincmd dir b_wait)
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
        (setq pen-tf (make-temp-file "elispbash")))

    (if (not cmd)
        (setq cmd "zsh"))

    (if b_output
        (if stdin
            (setq final_cmd (concat "pen-tm -f -s -sout " session-dir-cmd " > " tf_output))
          (setq final_cmd (concat "unbuffer pen-tm -f -fout " session-dir-cmd " > " tf_output)))
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
        (shell-command-on-region (point-min) (point-max) final_cmd))
      )

    (if b_output
        (progn
          (setq output (slurp-file tf_output))
          output))))

(cl-defun cl-sh (&optional cmd &key stdin &key b_output &key tm_session &key shell &key b_switch_to &key tm_wincmd &key dir &key b_wait)
  (interactive)

  (if (not tm_wincmd)
      (setq tm_wincmd "sps"))

  (sh cmd stdin b_output tm_session shell b_switch_to tm_wincmd dir b_wait))

;; Disable the finished message from appearing in all shell commands
(defun shell-command-sentinel (process signal)
  (when (memq (process-status process) '(exit signal))))

(defvar inside-host-b nil)

(defun inside-host-p ()
  inside-host-b)

(defun ascify (title)
  (let ((slug-trim-chars '(;; Combining Diacritical Marks https://www.unicode.org/charts/PDF/U0300.pdf
                                 768 ; U+0300 COMBINING GRAVE ACCENT
                                 769 ; U+0301 COMBINING ACUTE ACCENT
                                 770 ; U+0302 COMBINING CIRCUMFLEX ACCENT
                                 771 ; U+0303 COMBINING TILDE
                                 772 ; U+0304 COMBINING MACRON
                                 774 ; U+0306 COMBINING BREVE
                                 775 ; U+0307 COMBINING DOT ABOVE
                                 776 ; U+0308 COMBINING DIAERESIS
                                 777 ; U+0309 COMBINING HOOK ABOVE
                                 778 ; U+030A COMBINING RING ABOVE
                                 779 ; U+030B COMBINING DOUBLE ACUTE ACCENT
                                 780 ; U+030C COMBINING CARON
                                 795 ; U+031B COMBINING HORN
                                 803 ; U+0323 COMBINING DOT BELOW
                                 804 ; U+0324 COMBINING DIAERESIS BELOW
                                 805 ; U+0325 COMBINING RING BELOW
                                 807 ; U+0327 COMBINING CEDILLA
                                 813 ; U+032D COMBINING CIRCUMFLEX ACCENT BELOW
                                 814 ; U+032E COMBINING BREVE BELOW
                                 816 ; U+0330 COMBINING TILDE BELOW
                                 817 ; U+0331 COMBINING MACRON BELOW
                                 )))
          (cl-flet* ((nonspacing-mark-p (char) (memq char slug-trim-chars))
                     (strip-nonspacing-marks (s) (string-glyph-compose
                                                  (apply #'string
                                                         (seq-remove #'nonspacing-mark-p
                                                                     (string-glyph-decompose s)))))
                     (cl-replace (title pair) (replace-regexp-in-string (car pair) (cdr pair) title)))
            (let* ((pairs `(("[^[:alnum:][:digit:]]" . " ") ;; convert anything not alphanumeric
                            ("__*" . "_") ;; remove sequential underscores
                            ("--*" . "-") ;; remove sequential dashes
                            ("^_" . "") ;; remove starting underscore
                            ("_$" . ""))) ;; remove ending underscore
                   (slug (-reduce-from #'cl-replace (strip-nonspacing-marks title) pairs)))
              slug))))

(if (inside-host-p)
    (defalias 'eslugify 'slugify)
  (progn
    (require 'ucs-normalize)
    (defun eslugify (title &optional joinlines length)
      "Return the slug of NODE."
      (if (not joinlines)
          (pen-list2str (mapcar
                         (eval
                          `(lambda
                             (s)
                             (eslugify s t ,length)))
                         (pen-str2list title)))
        (let ((slug-trim-chars '(;; Combining Diacritical Marks https://www.unicode.org/charts/PDF/U0300.pdf
                                 768  ; U+0300 COMBINING GRAVE ACCENT
                                 769  ; U+0301 COMBINING ACUTE ACCENT
                                 770  ; U+0302 COMBINING CIRCUMFLEX ACCENT
                                 771  ; U+0303 COMBINING TILDE
                                 772  ; U+0304 COMBINING MACRON
                                 774  ; U+0306 COMBINING BREVE
                                 775  ; U+0307 COMBINING DOT ABOVE
                                 776  ; U+0308 COMBINING DIAERESIS
                                 777  ; U+0309 COMBINING HOOK ABOVE
                                 778  ; U+030A COMBINING RING ABOVE
                                 779  ; U+030B COMBINING DOUBLE ACUTE ACCENT
                                 780  ; U+030C COMBINING CARON
                                 795  ; U+031B COMBINING HORN
                                 803  ; U+0323 COMBINING DOT BELOW
                                 804  ; U+0324 COMBINING DIAERESIS BELOW
                                 805  ; U+0325 COMBINING RING BELOW
                                 807  ; U+0327 COMBINING CEDILLA
                                 813  ; U+032D COMBINING CIRCUMFLEX ACCENT BELOW
                                 814  ; U+032E COMBINING BREVE BELOW
                                 816  ; U+0330 COMBINING TILDE BELOW
                                 817  ; U+0331 COMBINING MACRON BELOW
                                 )))
          (cl-flet* ((nonspacing-mark-p (char) (memq char slug-trim-chars))
                     (strip-nonspacing-marks (s) (string-glyph-compose
                                                  (apply #'string
                                                         (seq-remove #'nonspacing-mark-p
                                                                     (string-glyph-decompose s)))))
                     (cl-replace (title pair) (replace-regexp-in-string (car pair) (cdr pair) title)))
            (let* ((pairs `(("[^[:alnum:][:digit:]]" . "-") ;; convert anything not alphanumeric
                            ("__*" . "_") ;; remove sequential underscores
                            ("--*" . "-") ;; remove sequential dashes
                            ("^_" . "")   ;; remove starting underscore
                            ("_$" . ""))) ;; remove ending underscore
                   (slug (-reduce-from #'cl-replace (strip-nonspacing-marks title) pairs))
                   (slug (downcase slug))
                   (slug (if length
                             (substring slug 0 (- length 1))
                           slug)))
              slug)))))

    (defalias 'slugify 'eslugify)))

(defun sh/hash-trim (s &optional max-mant-len)
  "Total length = max-mant-len + 6"
  (snc (cmd "hash-trim" max-mant-len) s))

(defun sha256 (o)
  (secure-hash 'sha256 o))

(defun e/hash-trim (s &optional max-mant-len)
  "Total length = max-mant-len + 6"
  (setq max-mant-len (or max-mant-len 20))
  (let* ((hash (s-left 10 (sha256 s)))
         (name (concat (s-left (- max-mant-len 5) s) "-" hash))
         (strl (length s)))
    (if (> strl max-mant-len)
        name
      hash)))

(defalias 'hash-trim 'e/hash-trim)

;; This is set from $SHELL when emacs starts.
;; But I can change it like this.
(setq explicit-shell-file-name (executable-find "bash"))
(setq-default explicit-shell-file-name (executable-find "bash"))
(defvaralias 'default-shell 'explicit-shell-file-name)

;; Nevertheless, I'm still getting a zsh error here, and I don't know why:
;; (shell-command-to-string (concat " ;printf -- \"%s\\n\" " "yo -5 =yo yo"))
;; (shell-command-to-string (concat "env | tv; printf -- \"%s\\n\" " "yo -5 =yo yo"))

;; (setenv "ESHELL" "/bin/bash")
;; (setenv "ESHELL" "/usr/bin/zsh")
;; (setenv "SHELL" "/bin/bash")
;; (setenv "SHELL" "/usr/bin/zsh")

;; (snc "find ~+ -name 'snippets' -type d" nil pen-user-emacs-directory)

;; I think this always assumes output
(defun pen-sn (shell-cmd &optional stdin dir exit_code_var detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code shell env-var-tups)
  "Runs command in shell and return the result.
This appears to strip ansi codes.
\(sh) does not.
This also exports PEN_PROMPTS_DIR, so lm-complete knows where to find the .prompt files"
  (interactive)

  ;; This uses emacs' (getenv "SHELL")
  ;; So I must set it like so:

  (if shell
      (setenv "SHELL" shell)
    (setenv "SHELL" default-shell))

  (let ((output)
        (tf_output)
        (tf_input)
        (slug (e/hash-trim (eslugify (concat "elisp_bash_" shell-cmd " detach:" (str detach))))))
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
               (and (variable-p 'pen-sh-update)
                    (eval 'pen-sh-update))
               (>= (prefix-numeric-value current-prefix-arg) 16)))
          (setq shell-cmd (concat "export UPDATE=y; " shell-cmd)))

      (setq shell-cmd (concat ". $HOME/.shellrc; " shell-cmd))

      (setq tf_output (make-temp-file (concat slug "_output_") nil ".txt"))
      (setq tf_exit_code (make-temp-file (concat slug "_exit_code_") nil ".txt"))

      (let ((exps
             (sh-construct-exports
              (append
               (-filter 'identity
                        (list (list "DISPLAY" ":0")
                              (list "PATH" (getenv "PATH"))
                              (list "TMUX" "")
                              (list "TMUX_PANE" "")
                              (list "PEN_WORKER" (sor (daemonp) "default"))
                              (list "PEN_PROMPTS_DIR" (concat pen-prompts-directory "/prompts"))
                              (if (or (pen-var-value-maybe 'pen-sh-update)
                                      (pen-var-value-maybe 'pen-sh-update))
                                  (list "UPDATE" "y"))
                              (if (or (pen-var-value-maybe 'pen-force-engine))
                                  (list "PEN_ENGINE" (pen-var-value-maybe 'pen-force-engine)))
                              (if (or (pen-var-value-maybe 'force-temperature))
                                  (list "PEN_TEMPERATURE" (pen-var-value-maybe 'force-temperature)))))
               env-var-tups))))

        (if (and detach
                 stdin)
            (progn
              (setq tf_input (make-temp-file (concat slug "_input_") nil ".txt"))
              (shut-up-c (write-to-file stdin tf_input))
              (setq shell-cmd (concat "exec < <(cat " (pen-q tf_input) "); " shell-cmd))))

        (if (not (string-match "[&;]$" shell-cmd))
            (setq shell-cmd (concat shell-cmd ";")))

        (if (and detach
                 stdin)
            (setq final_cmd (concat final_cmd " rm -f " (pen-q tf_input) ";")))

        ;; I need a log level here. This will be too verbose
        (setq final_cmd (concat exps "; ( cd " (pen-q dir) "; " shell-cmd " echo -n $? > " tf_exit_code " ) > " tf_output)))

      (if detach
          (if stdin
              (setq final_cmd (concat "trap '' HUP; bash -c " (pen-q final_cmd) " &"))
            (setq final_cmd (concat "trap '' HUP; unbuffer bash -c " (pen-q final_cmd) " &"))))

      ;; shut-up is needed to remove  (Shell command succeeded with no output)
      (shut-up
        (shut-up-c
         (if (or
              (not stdin)
              detach)
             (progn
               (comment
                (if pen-debug
                    (message "%s" (shell-command-to-string final_cmd))))
               (shell-command final_cmd output_buffer "*pen-sn-stderr*"))
           (with-temp-buffer
             (insert stdin)
             (shell-command-on-region (point-min) (point-max) final_cmd output_buffer nil "*pen-sn-stderr*")))))

      (if detach
          t
        (progn
          (setq output (slurp-file tf_output))
          (if chomp
              (setq output (chomp output)))
          (progn
            (defset b_exit_code (slurp-file tf_exit_code)))

          (if b_output-return-code
              (setq output (str b_exit_code)))
          ;; deleting the temp files needs to happen inside the actual CMD
          (progn (ignore-errors (f-delete tf_input))
                 (ignore-errors (f-delete tf_output))
                 (ignore-errors (f-delete tf_exit_code)))
          output)))))

(cl-defun pen-cl-sn (shell-cmd &key stdin &key dir &key detach &key b_no_unminimise &key output_buffer &key b_unbuffer &key chomp &key b_output-return-code &key shell &key env-var-tups)
  (interactive)
  (pen-sn shell-cmd stdin dir nil detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code shell env-var-tups))

(defun pen-snc (shell-cmd &optional stdin dir)
  "sn chomp"
  (chomp (pen-sn shell-cmd stdin dir)))

(defmacro sh-notty-if (cm then else &rest sh-notty-args)
  "Like an if statement with a first argument which specifies the command to run as the test"
  `(let ((result (pen-sn ,cm ,@sh-notty-args)))
     (if (string-equal b_exit_code "0")
         ,then
       ,else)))

(defmacro sh-notty-true (cm &rest sh-notty-args)
  "Returns t if the shell command exists with 0"
  `(let ((result (pen-sn ,cm ,@sh-notty-args)))
     (string-equal b_exit_code "0")))
(defalias 'sn-true 'sh-notty-true)

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

(defun inside-tmux-p ()
  (or
   (test-n
    (getenv "TMUX"))
   (pen-snq "inside-tmux-p")))

(defun inside-docker-p ()
  (pen-snq "inside-docker-p"))

;; (if (inside-tmux-p) (message "inside tmux"))
;; (if (inside-docker-p) (message "inside docker"))

(if (inside-docker-p)
    (progn
      (defun s/cat (&optional path input)
        "cat out a file"
        (setq path (pen-umn path))
        (pen-sn (concat "cat " (pen-q path) " 2>/dev/null") input))
      (defalias 'cat 's/cat)))

;; slugify is used in sn, so it must contain an explicit directory, to be safe,
;; so that when called by (get-dir), this does not do an infinite loop.
(defun sh/slugify (input &optional joinlines length)
  "Slugify input"
  (let ((slug
         (if joinlines
             (pen-sn "tr '\n' - | slugify" input "/")
           (pen-sn "slugify" input "/"))))
    (if length
        (chomp (pen-sn (pen-cmd "head" "-c" length) nil "/"))
      slug)))


(defun fz-completion-second-of-tuple-annotation-function (s)
  ;; (tv minibuffer-completion-table)
  ;; I need more information than s. s is the first element.
  ;; Sadly, after investigating, it's too hard.
  ;; The best way to get what I want is to add #numbers, then remove them

  ;; (defset filter-cmd-2-tuples
  ;;   ;; They have to be different
  ;;   '(("scrape-bible-references # 1" 'bible-mode-lookup)
  ;;     ("scrape-bible-references # 2" "ebible %q")))
  ;; (fz filter-cmd-2-tuples nil nil "filter-cmd: ")

  (let ((item (assoc s minibuffer-completion-table)))
    (when item
      ;; (concat " # " (second item))
      (cond
       ((and (listp item) (ignore-errors (second item)) (concat " # " (str (second item)))))
       ((consp item) (concat " # " (str (cdr item))))
       ((stringp item) "")
       (t "")))))

(cl-defun cl-fz (listd &key prompt &key full-frame &key initial-input &key must-match &key select-only-match &key hist-var &key add-props &key no-hist &key empty-hist-exit)
  (if (not
       (and (or (not listd)
                (and (stringp listd)
                     (not (sor listd))))
            empty-hist-exit))

      (progn
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

        (if (eq (type-of listd) 'symbol)
            (cond
              ((variable-p 'clojure-mode-funcs) (setq listd (eval listd)))
              ((fboundp 'clojure-mode-funcs) (setq listd (funcall listd)))))

        (if (stringp listd)
            (setq listd (split-string (chomp listd) "\n")))

        (if (and select-only-match (eq (length listd) 1))
            (car listd)
          (let ((sel))
            (setq prompt (or prompt ":"))
            (let ((helm-full-frame full-frame)
                  (completion-extra-properties nil))

              (if add-props
                  (setq completion-extra-properties
                        (append
                         completion-extra-properties
                         add-props)))

              ;; my-ivy-result-tuple is set to the full tuple in ivy-call
              (if (and (listp (car listd)))
                  (setq completion-extra-properties
                        (append
                         ;; my-ivy-result-tuple is set to the full tuple in ivy-call
                         '(:annotation-function fz-completion-second-of-tuple-annotation-function)
                         completion-extra-properties)))

              (setq sel (completing-read prompt listd nil must-match initial-input hist-var)))

            ;; This refreshes the term usually, but not always. It realigns up some REPLs, such as lein.
            ;; Not worth it just for hhgttg
            (if (and
                 pen-term-cl-refresh-after-fz
                 (major-mode-p 'term-mode)
                 ;; char is raw mode
                 (term-in-char-mode))
                (run-with-timer 0.2 nil (lambda () (term-send-raw-string "\C-l"))))
            sel)))
    (progn (message "History empty")
           nil)))

(defun fz (list &optional input b_full-frame prompt must-match select-only-match add-props hist-var no-hist empty-hist-exit)
  (cl-fz
   list
   :initial-input input
   :full-frame b_full-frame
   :prompt prompt
   :must-match must-match
   :select-only-match select-only-match
   :add-props add-props
   :hist-var hist-var
   :no-hist no-hist
   :empty-hist-exit empty-hist-exit))

(defun pen-selected ()
  (or
   (use-region-p)
   (evil-visual-state-p)))
(defalias 'pen-selected-p 'pen-selected)
(defalias 'selected-p 'pen-selected)

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

(defun pen-regex-match-string-1 (pat s)
  "Get first match from substring"
  (save-match-data
    (and (string-match pat s)
         (or (match-string-no-properties 1 s)
             (match-string-no-properties 0 s)))))
(defalias 'regex-match-string 'pen-regex-match-string-1)
(defalias 's-substring 'pen-regex-match-string-1)

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
  (setq prompt
        (cond
         ((re-match-p ":$" prompt) (concat prompt " "))
         ((re-match-p ": $" prompt) prompt)
         (t (concat prompt ": "))))
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

(defun pen-delete-selected-text ()
       (interactive)
       (delete-region (region-beginning) (region-end))
       (deactivate-mark))

;; TODO collect from tmux instead
;; Should I start a tmux in the background and
;; connect to the buffer? Or always have tmux?
(defun pen-screen-words ()
  (pen-words 40 (pen-selection-or-surrounding-context 10))
  ;; TODO Add tmux support - wouldn't work for GUI well though
  ;; But in that case I would take screen shots with imagemagick
  ;; (buffer-string)
  )

(defun pen-screen-text ()
  (pen-selection-or-surrounding-context 10)
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

(defun pen-screen-words-or-selection ()
  (pen-words 40 (pen-screen-or-selection)))

(defun pen-screen-or-selection-ask ()
  (pen-ask (pen-screen-words-or-selection)))

(defun pen-screen-verbatim-or-selection (&optional clean)
  (let* ((sel (pen-selection))
         (ret
          (if (sor sel)
              sel
            (pen-screen-verbatim-text))))
    (if clean
        (pen-snc "clean-term-capture" ret)
      ret)))

(defun pen-screen-verbatim-or-selection-ask ()
  (pen-ask (pen-screen-verbatim-or-selection)))

(defun pen-selected-text-ignore-no-selection (&optional keep-properties)
  "Just give me the selected text as a string. If it's empty, then nothing was selected. region-active-p does not work for evil selection."
  (interactive)
  (pen-selected-text t keep-properties))

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
        (pen-sn "tee >(xsel -b -i) | tee >(xsel -p -i) | tee >(xsel -s -i)" s))
    (if (and (pen-selected-p)
             (not noautosave))
        (progn
          (setq s (pen-selected-text))
          (call-interactively 'kill-ring-save))))
  (if s
      (progn
        ;; (pen-sn "xsel --primary --input" s)
        ;; (pen-sn "xsel --secondary --input" s)
        (pen-sn "xsel --clipboard --input" s)
        (if (not silent) (message "%s" (concat "Copied: " s)))
        s)
    (progn
      ;; Frustratingly, shell-command-to-string uses the current directory.
      ;; (shell-command-to-string "xsel --clipboard --output")
      ;; (pen-sn "xsel --primary --output")
      ;; (pen-sn "xsel --secondary --output")
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

(if (inside-docker-p)
    (defalias 'detect-language 'pen-detect-language))

(defalias 'current-lang 'pen-detect-language)
(defalias 'buffer-language 'pen-detect-language)

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

  (cond ((derived-mode-p 'json-mode) "json")
        ((derived-mode-p 'haskell-mode) "hs")
        ((eq major-mode 'python-mode) "py")
        ((eq major-mode 'problog-mode) "problog")
        ((derived-mode-p 'csv-mode) "csv")
        ((eq major-mode 'fundamental-mode) "txt")
        ((eq major-mode 'graphviz-dot-mode) "dot")
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
  (if (not (minor-mode-p org-src-mode))
      (cond
       ((derived-mode-p 'sh-mode)
        (message "Disabled lsp for sh"))
       ((derived-mode-p 'lisp-mode)
        (message "Disabled lsp for common-lisp"))
       ((derived-mode-p 'prompt-description-mode)
        (message "Disabled lsp for prompts"))
       ((derived-mode-p 'completer-description-mode)
        (message "Disabled lsp for completers"))
       (t
        (call-interactively 'lsp)))))

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
        (let ((doreverse (< rend rstart)))
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
     ;; (message (concat "writing to /tmp/eval-output-" ,worker-name ".txt"))

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

(defun pen-define-general-knowledge-immediate ()
  (interactive)
  (pen-define-general-knowledge (pen-thing-at-point)))

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

(defun tmpdir ()
  (cond ((f-dir-p (f-join penconfdir "tmp")) (f-join penconfdir "tmp"))
        (t "/tmp")))

(defun pen-mnm (input)
  "Minimise string."
  ;; (pen-sn "mnm" input)
  (if input
      (seds (pen-umn input)
            ("/root/notes" "$HOME/notes")
            ((f-join pen-prompts-directory "prompts") "$PROMPTS")
            ((getenv "EMACSD") "$EMACSD")
            (user-emacs-directory "$EMACSD_BUILTIN")
            ((getenv "EMACSD_BUILTIN") "$EMACSD_BUILTIN")
            (pen-prompts-directory "$PEN_PROMPTS_DIR")
            (pen-engines-directory "$PEN_ENGINES_DIR")
            ((getenv "PENELD") "$PENELD")
            (penconfdir "$PEN")
            ((tmpdir) "$TMPDIR")
                                        ; ((f-join user-emacs-directory "pen.el") "$PENEL_DIR")
            ((f-join user-emacs-directory "pen.el") "$PENEL")
            (user-home-directory "$HOME"))))

;; Test
;; (umn "$EMACSD_BUILTIN/elpa-light/")
;; (umn "$EMACSD/elpa-light/")
(defun pen-umn (input)
  "Unminimise string."
  (if input
      (seds input
            ("~" user-home-directory)
            ("$NOTES" "/root/notes")
            ("$PROMPTS" (f-join pen-prompts-directory "prompts"))
            ;; EMACSD is /host
            ;; ("$EMACSD" (pen-umn user-emacs-directory))
            ;; ("$EMACSD" pen-user-emacs-directory)
            ("$EMACSD_BUILTIN" (getenv "EMACSD_BUILTIN"))
            ("$EMACSD" (getenv "EMACSD"))
            ("$PEN_PROMPTS_DIR" pen-prompts-directory)
            ("$PEN_ENGINES_DIR" pen-engines-directory)
            ;; This is dodgy because there are other vars that are prefixed with $PEN_
            ("$PENEL_DIR" (f-join user-emacs-directory "pen.el"))
            ("$PENCONF" penconfdir)
            ("$PENELD" (getenv "PENELD"))
            ("$TMPDIR" (tmpdir))
            ("$PEN" penconfdir)
            ("$PENEL" (f-join user-emacs-directory "pen.el"))
            ("$SCRIPTS" (f-join user-emacs-directory "pen.el/scripts"))
            ("$MYGIT" "/volumes/home/shane/var/smulliga/source/git")
            ("$HOME" user-home-directory)
            ;; ("^//" "/")
            ;; It must start with something. I still need the replace
            ;; I can't do this because it runs on urls, which have http://
            ;; ("\\(.\\)//" "\\1/")
            )))

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

(defalias 'guess-major-mode 'pen-guess-major-mode-set)

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

(if (inside-docker-p)
    (defalias 'sed 'pen-sed))

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

(defmacro pen-macro-filter (s-filter-fun &rest body)
  "This transforms the code with a sed expression"
  (let* ((codestring (pp-map-line body))
         (ucodestring (call-function s-filter-fun codestring))
         (newcode (pen-eval-string (concat "'(progn " ucodestring ")"))))
    newcode))
(defalias 'pen-mf 'pen-macro-filter)

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

(defun advice-auto-yes (proc &rest args)
  (let ((res
         (eval `(auto-yes (apply ,proc ,args)))))
    res))

(defun advice-auto-no (proc &rest args)
  (let ((res
         (eval `(auto-no (apply ,proc ,args)))))
    res))
(advice-add 'save-buffers-kill-terminal :around #'advice-auto-no)
(advice-remove 'save-buffers-kill-terminal #'advice-auto-no)

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

(defun pen-git-buffer-name-to-file-name ()
  (pen-sn "tr -s \"[/\\\\*]\" _" (pen-sed "s/^\\(.*\\)\\(\\.~\\)\\(.*\\)$/\\3\\1/" (buffer-name)))
  ;; (if (string-match "\.~" (buffer-name))
  ;;     (pen-sn "tr -s \"[/\\\\*]\" _" (sed "s/^\\(.*\\)\\(\\.~\\)\\(.*\\)$/\\3\\1/" (buffer-name)))
  ;;   (buffer-name))
  )

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
               (point-max))))

    (let ((line-and-col (concat-string "+" (line-number-at-pos) ":" (current-column))))
      (if (display-graphic-p)
          (progn
            ;; Just a bit lazy
            (xterm "v" (buffer-string))
            ;; (pen-sn "xt tmux" nil nil nil t)
            ;; This could be improved
            ;; (pen-sps "sh -c 'sleep 1'" nil nil nil t)
            ;; (sleep-for 0.5)
            )
        (if (and buffer-file-name
                 (not (string-match "\\[*Org Src" (buffer-name))))
            (progn
              (save-buffer)
              (let ((c
                     (concat-string "pen-tm -d -te " window_type " -fa " editor " " line-and-col " " (pen-q buffer-file-name))))
                (shell-command c)))
          (let ((c
                 (cond
                  ((or
                    (not (buffer-file-path))
                    (string-match "\.~" (buffer-name)))
                   (concat-string "pen-tsp -wincmd " window_type " -fa " editor " " line-and-col))
                  ((string-match "\\[*Org Src" (buffer-name))
                   (concat-string "pen-tsp -wincmd " window_type " -fa " editor " " line-and-col))
                  (t
                   (concat-string "pen-tsp -wincmd " window_type " -fa " editor " " line-and-col)))))
            (shell-command-on-region min max c)))))))

(defalias 'open-in 'pen-tmux-edit)

(defun pen-tm-edit-v-in-nw ()
  "Opens pen-v in new window for buffer contents"
  (interactive)
  (if (ivy-running-p)
      (call-interactively 'ivy-tvipe-filtered-candidates)
    (if (>= (prefix-numeric-value current-prefix-arg) 4)
        (pen-tm-edit-hx-in-nw)
      ;; (pen-tm-edit-bvi-in-nw)
      (pen-tmux-edit "pen-v" "nw")
      ;; (pen-tmux-edit "nve" "nw")
      ;; (pen-tmux-edit "nvem" "tpop")
      )))
(define-key pen-map (kbd "C-c o") #'pen-tm-edit-v-in-nw)

(defun pen-tm-edit-bvi-in-nw ()
  "Opens bvi in new window for buffer contents"
  (interactive)
  (pen-tmux-edit "bvi" "nw"))

(defun pen-tm-edit-hx-in-nw ()
  "Opens hx in new window for buffer contents"
  (interactive)
  (pen-tmux-edit "hx" "nw"))

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

  (cond ((major-mode-p 'org-brain-visualize-mode)
         (call-interactively 'org-brain-visualize-top))
        (t (dired (pen-get-top-level)))))

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

(defun pen-revert (arg)
  (interactive "P")
  (cond ((major-mode-p 'notmuch-search-mode) (notmuch-refresh-this-buffer))
        ((major-mode-p 'notmuch-show-mode) (notmuch-refresh-this-buffer))
        ((major-mode-p 'notmuch-hello-mode) (notmuch-refresh-this-buffer))
        ((major-mode-p 'bible-mode) (bible-mode--display))
        (t
         (progn
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
                                  )))            ; revert without loading from disk
               )

             (goto-line l)
             (move-to-column c)
             ;; For some reason, this hook is added whenever I revert. Therefore remove it. What is adding it?
             (remove-hook 'after-save-hook (lambda nil (byte-force-recompile default-directory)) t))
           (ignore-errors
             (clear-undo-tree))
           (company-cancel)))))

(defun pen-etv-urls-in-region (&optional s ignore-textprops)
  (interactive)
  (new-buffer-from-string
   (urls-in-region-or-buffer s (not ignore-textprops))
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
  (cond ((major-mode-p 'org-agenda-mode)
         (call-interactively 'org-save-all-org-buffers))
        ((major-mode-p 'org-brain-visualize-mode)
         (call-interactively 'sh/git-add-all-below))
        ((major-mode-p 'ebdb-mode)
         (call-interactively 'ebdb-save-ebdb))
        ((major-mode-p 'bible-mode)
         ;; Simulate the hooks for pen-ov-highlight
         (run-hooks 'before-save-hook)
         (run-hooks 'after-save-hook))
        (t
         (progn (save-buffer)
                (shut-up (if-shebang-exec-otherwise-remove))
                (message "%s" "File saved")))))

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

(defun date-ts ()
  (string-to-number (format-time-string "%s")))

(defun glob-exists-p (file-glob)
  (pen-snq (pen-cmd "pen-glob" file-glob)))

(defun e/or (a b)
  ;; or is a builtin, and doesnt work with -reduce
  (or a b))

(defun glob-dir-p (dir-glob)
  (-reduce 'e/or (mapcar 'file-directory-p (glob dir-glob))))

;; example:
;; (locate-dominating-file-glob default-directory "*.cabal")
(defun locate-dominating-file-glob (start-file dir-glob)
  (setq start-file (abbreviate-file-name (expand-file-name start-file)))
  (let ((root nil)
        the-try)
    (while (not (or root
                    (null start-file)
                    (string-match locate-dominating-stop-dir-regexp start-file)))
      (setq the-try (if (stringp dir-glob)
                        (and (glob-dir-p start-file)
                             (glob-exists-p (expand-file-name dir-glob start-file)))
                      (funcall dir-glob start-file)))
      (cond (the-try (setq root start-file))
            ((equal start-file (setq start-file (file-name-directory
                                                 (directory-file-name start-file))))
             (setq start-file nil))))
    (if root (file-name-as-directory root))))

(define-key global-map (kbd "C-a") 'beginning-of-line-or-indentation)

(provide 'pen-support)
