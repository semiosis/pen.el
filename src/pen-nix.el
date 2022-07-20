(require 'memoize)
(require 'em-unix)

(require 'nix-env-install)
(require 'nix-modeline)
(require 'nixpkgs-fmt)

(defmacro hsr (name &rest body)
  "Macro. Record the elisp into hs before running."
  `(progn (sh/hs ,name ,@body)
          ,@body))

(defun hs (name &rest body)
  "Function. Record the arguments into hs before running."
  (pen-sn (concat "hist-save " (pen-q name) " " (mapconcat 'pen-q (mapcar 'str body) " "))))

(defun hg (name)
  (s-lines (pen-cl-sn (concat "hist-get " (pen-q name)) :chomp t)))

(defun hist-edit (name)
  (find-file (pen-cl-sn (concat "hist-getfile " (pen-q name)) :chomp t)))
(defalias 'he 'hist-edit)

(defmacro sh/hs (name &rest body)
  `(shell-command (concat "hs " "emacs-" (str ,name) " " (pen-q (str ',@body)))))

(defmacro m/apply (macro mylist)
  `(pen-tvipe ',mylist))

(defmacro quote-args (&rest body)
  "Join all the arguments in a sexp into a single string.
Be mindful of quoting arguments correctly."
  `(mapconcat (lambda (input)
                (shellquote (str input))) ',body " "))

(defun shellquote (input)
  "If string contains spaces or backslashes, put quotes around it, but only if it is not surrounded by ''."
  (if (or (string-match "\\\\" input)
          (string-match " " input)
          (string-match "*" input)
          (string-match "?" input)
          (string-match "\"" input))
      (pen-q input)
    input))

(defmacro sh/tt (&rest body)
  `(let ((mylist ',body))
     (string-equal (pen-sn (concat (quote-args "tt" ,@body) " && echo -n $?")) "0")))
(defalias 'tt 'sh/tt)

(defun current-function ()
  "Gets the name OR definition of the function you are in. Does not work for compiled functions. Works for macros too. Place at the top."
  (let ((n 6)
        func
        bt)
    (while (and (setq bt (backtrace-frame n))
                (not func))
      (setq n (1+ n)
            func (and bt
                      (nth 0 bt)
                      (nth 1 bt))))
    func))

(defmacro sh/test (&rest body)
  `(let ((mylist ',body))
     (string-equal (pen-sn (concat (quote-args "test" ,@body) " && echo $?")) "0")))
(defalias 'test 'sh/test)

(defmacro pen-str (&rest body)
  `(let ((mylist ',body))
     (pen-sn (concat (quote-args ,@body))) "0"))

(defmacro echo (&rest body)
  `(pen-b echo ,@body))

(defalias 'edit-which 'pen-edit-fp-on-path)
(defalias 'ewhich 'pen-edit-fp-on-path)
(defalias 'ew 'pen-edit-fp-on-path)

(defmacro pen-bp (&rest body)
  "Pipe string into bash command. Return stdout."
  `(pen-sn (concat (quote-args ,@(butlast body))) ,@(last body)))

(defmacro bp-tty (&rest body)
  "Pipe string into bash command. Return stdout."
  `(sh (concat (quote-args ,@(butlast body))) (str ,@(last body)) t))

(defmacro bx-right (&rest body)
  "Evaluate the last argument and use as the last argument to shell script. Use the last lisp argument as the final argument to the preceding bash command."
  `(pen-sn (concat (quote-args ,@(butlast body)) " " (pen-q (str ,@(last body))))))
(defalias 'bxr 'bx-right)
(defalias 'bl 'bx-right)

(defmacro bpq (&rest body)
  "Pipe string into bash command. Return exit code."
  `(eq (bpe ,@body) 0))

(defun wrl_q ()
  "Quote each line -force."
  (interactive)
  (filter-selection 'qftln))

(defun wrl_uq ()
  "Unquote each line."
  (interactive)
  (pen-region-pipe "uq -ftln"))

(defun wrl_qne ()
  "Escape each line as if quoting, but do not make surrounding quotes."
  (interactive)
  (pen-region-pipe "qne -ftln"))

(defun cssbeautify ()
  (interactive)
  (pen-region-pipe "cssbeautify"))

(defun erase-bad-whitespace ()
  (interactive)
  (pen-region-pipe "erase-trailing-whitespace"))

(defun less (input)
  (sh "tless -r" input nil nil "sh" t "spv"))
(defalias 'tless 'less)

(defun vime (input)
  (pen-snc "vime" input))

(defun xxd-spv (input)
  (sh "xxd -g1 | tless" input nil nil "sh" t "spv"))
(defalias 'xxd-less 'xxd-spv)

(defun aes (input)
  ;; This is dodgy. -nopad and -nosmake it dodgy. Never use in production
  (pen-sn "openssl aes-128-cbc -K 61 -e -iv 61 -nopad -nosalt" input))

(defun xxd (input)
  (pen-sn "xxd -g1" input))

(defun sh/bs (input &optional chars)
  (if (not chars)
      (setq chars "\\"))
  (pen-sn (concat "pen-bs " (pen-q chars)) input))

(defun hls (input pattern)
  (sh (concat "pen-hls -r " pattern) input t))

(defun udl (input)
  (pen-sn "udl | chomp" input))

(defun sh/cat (input)
  "This is useful as a sponge sometimes. I honestly don't know why fzf doesn't like being passed to filter-selection."
  (sh "cat" input t))

(defun wc (input &optional type)
  (erase-surrounding-whitespace
   (single-space-whitespace
    (e/chomp
     (pen-sn (concat "wc" (if type (concat " -" (str type)))) input)))))

(defun aes-xxd (input)
  (sh "openssl aes-128-cbc -K 61 -e -iv 61 -nopad -nosalt | tless" input nil nil "sh" t "spv"))

(defun vim (path)
  (sh (concat "vim " (pen-q (concat path))) nil nil nil "sh" t "sph"))

(defvaralias '_pwd 'default-directory)

(defun e/pwd ()
  "Returns the current directory."
  default-directory)

(defun sh/pwd ()
  "Returns the current directory."
  default-directory)

(defun u/pwd ()
  "Returns the current directory."
  default-directory)

(defalias 'current-dir-name 'e/pwd)
(defalias 'current-dirname 'e/pwd)
(defalias 'current-directory 'e/pwd)

(defshellinteractive gist-search)

(defshellcommand seq)
(defshellcommand pwgen)
(defshellcommand pwgen 5)
(defshellfilter uniqnosort)
(defshellfilter urlencode)
(defshellfilter head)
(defshellfilter head -n 5)
(defshellfilter xurls)
(defshellfilter cat)
(defshellfilter c uc)

(defmacro e/seq (from &rest body)
  "Same semantics as unix seq. Returns a list of integers."
  (cond ((eq (length body) 0) from)
        ((eq (length body) 1) `(number-sequence ,from ,@body))
        ((eq (length body) 2) `(number-sequence ,from ,(cadr body) ,(first body)))
        (t (error (concat "bad parameters: " (str (cons from body)))))))

(defmacro sh/seq-to-list (&rest body)
  `(mapcar 'string-to-int (pen-str2list (chomp (pen-b seq ,@body)))))

(defalias 'seq 'e/seq)

(defmacro s/cd (dir &rest body)
  "cd for current buffer then return after body is executed."
  (setq dir (pen-umn dir))
  (pen-sn (concat "mkdir -p " (pen-q dir)))
  `(progn (cd ,dir) ,@body (cd ,_pwd)))

(cl-defun sh/cut (stdin &key d &key f)
  (if (not d)
      (setq d " "))

  (if (not f)
      (setq f "1"))
  (pen-sn (concat "cut -d " (pen-q d) " -f " (pen-q f) " 2>/dev/null") stdin))
(defalias 'cut 'sh/cut)

(defun sh/u-rm-dirsuffix (nl-paths)
  "Ensures directories and only directories (excluding symbolic links) show a slash at the end."
  (pen-sn "u rmdirsuffix " nl-paths))
(defalias 'rmds 'sh/u-rm-dirsuffix)

(defun sh/u-dirsuffix (nl-paths)
  "Ensures directories and only directories (excluding symbolic links) show a slash at the end."
  (pen-sn "u dirsuffix " nl-paths))

(defun sh/u-dirname (nl-paths)
  "For directory paths, returns unchanged. For paths, returns the path of the directory they are in."
  (chomp (pen-sn "u dirname " nl-paths)))
(defalias 'cast-dirname 'sh/u-dirname)
(defalias 'u/dn 'sh/u-dirname)
(defalias 'c/dn 'sh/u-dirname)

(cl-defun sh/rsync (src &optional dest)
  (if (not dest)
      (setq dest "")
    (pen-sn (concat "rsync -rtlphx " (pen-q (sh/u-dirsuffix src)) (pen-q (sh/u-rmdirsuffix dest))))))
(defalias 'sh/rs 'sh/rsync)

(defun sh/get-shebang (path)
  (pen-sn (concat "get-shebang " (pen-q path) " | chomp 2>/dev/null")))
(defalias 'get-shebang 'sh/get-shebang)

(defun sh/repeat-string (times string)
  (pen-sn (concat "s rs " (pen-q (str times))) string))
(defalias 'sh/rps 'sh/repeat-string)

(defun sh/grep (pattern input &optional options)
  (pen-sn (concat "grep " options " " (pen-q pattern) " 2>/dev/null") input))

(defun sh/glob-grep (pattern input)
  (pen-sn (concat "glob-grep " (pen-q pattern) " 2>/dev/null") input))

(defun curl (url)
  (pen-sn (concat "curl " (pen-q url) " 2>/dev/null")))

(defun rb (command)
  (pen-sn (concat "rb " (pen-q command) " 2>/dev/null")))

(defmacro globm (&rest pattern)
  `(pen-b glob -b ,@pattern 2>/dev/null))

(defun ca (pattern &optional dir)
  (pen-sn (concat "ca " (pen-q pattern) " 2>/dev/null") nil (pen-umn dir)))

(defmacro bds (stdin &rest body)
  "Save to named file on disk. (ds value key)"
  `(pen-bp pen-ds ,@body ,stdin))
(defalias 'ds 'bds)

(defmacro jq (stdin &rest body)
  "Save to named file on disk."
  `(pen-bp jq ,@body ,stdin))

(defun bgs (name)
  "Get value back from named file."
  (bl gs name))
(defalias 'gs 'bgs)

(defun s/awk1 (s)
  (pen-sn "awk 1" s))
(defun s/cat-awk1 (path &optional dir)
  (setq path (pen-umn path))
  (pen-sn (concat "cat " (pen-q path) " | awk 1" " 2>/dev/null") nil dir))
(defun e/cat (path)
  "Return the contents of FILENAME."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

;; (defun s/cat (path &optional dir)
;;   "cat out a file"
;;   (setq path (pen-umn path))
;;   (pen-sn (concat "cat " (pen-q path) " 2>/dev/null") nil dir))

(defun s/sort (path &optional dir)
  "sort out a file"
  (setq path (pen-umn path))
  (pen-sn (consort "sort " (pen-q path) " 2>/dev/null") nil dir))
(defalias 'sh/cat 's/cat)
(defalias 'sh/cat-file 's/cat)
(defalias 'sh/cat-awk1 's/cat-awk1)
(defalias 'sh/awk1 's/awk1)
(defalias 'cat-file 's/cat)
(defalias 'cat-awk1 's/cat-awk1)
(defalias 'awk1 's/awk1)
(defalias 'cat 's/cat)

(defun /bn (path &optional dir)
  (pen-sn (concat "basename " (pen-q path) " 2>/dev/null | chomp") nil dir))
(defalias 's/bn '/bn)

(require 'eshell)
(defalias 'basename 'eshell/basename)

(defun /dn (path &optional dir)
  (pen-sn (concat "dirname " (pen-q path) " 2>/dev/null | chomp") nil dir))

(defun udn (paths &optional dir)
  (pen-sn (concat "u dn | chomp") paths dir))

(defun e/dn (paths &optional dir)
  (mapcar (lambda (path) (file-name-directory path)) (split-string paths "\n")))
(defalias 'dn 'e/dn)

(defun /rp (path &optional dir)
  (pen-sn (concat "realpath " (pen-q path) " 2>/dev/null | chomp") nil dir))
(defalias 's/rp '/rp)

(defun /ext (path)
  (pen-sn (concat "ext " (pen-q path) " 2>/dev/null | chomp")))

(defun /mant (path)
  (pen-sn (concat "mant " (pen-q path) " 2>/dev/null | chomp")))

(defun /mkdir-p (path)
  (pen-sn (concat "mkdir -p " (pen-q path))))
(defalias 's/mkdir-p '/mkdir-p)
(defalias 'mkdir-p '/mkdir-p)

(defun sh/git-hash (stdin)
  (pen-sn "git hash-object -w --stdin | chomp" stdin))
(defalias 'git-hash 'sh/git-hash)

(defun sh/format-json (stdin)
  "Formats the json."
  (pen-sn "python -m json.tool" stdin))

(defun string-head (s)
  (car (split-string pen-str "\n")))

(defun clipboard-to-string ()
  "docstring"
  (interactive)
  (b-tty clipboard-to-string))
(defalias 'clip2str 'clipboard-to-string)

(defun clipboard-to-file ()
  "docstring"
  (interactive)
  (b-tty clipboard-to-file))
(defalias 'clip2file 'clipboard-to-file)

(defun open-in-vscode ()
  "Opens vscode in current window for buffer contents"
  (interactive)
  (pen-tmux-edit "vsc" "nw"))

(defun pen-term-nsfa (cmd &optional input modename closeframe buffer-name dir)
  "Like term but can run a shell command.
`nsfa` stands for `New Script From Arguments`"
  (interactive (list (read-string "cmd:")))
  (if input
      (let ((tf (make-temp-file "pen-term-nsfa" nil nil input)))
        (pen-term (message (pen-nsfa (message (concat "( " cmd " ) < " (pen-q tf))) dir)) closeframe modename buffer-name))
    (pen-term (pen-nsfa cmd dir) closeframe modename buffer-name)))

(defun tmuxify-cmd (cmd)
  (concat "t new " (pen-q (concat "TTY= " cmd))))

(defun term-nsfa-tm (cmd &optional input)
  "Like term but can run a shell command."
  (if input
      (let ((tf (make-temp-file "term-nsfa" nil nil input)))
        (term (message (nsfa (message (concat "( " cmd " ) < " (pen-q tf)))))))
    (term (nsfa (tmuxify-cmd cmd)))))

(defun open-in-vim ()
  "Opens v in current window for buffer contents"
  (interactive)
  (if (pen-display-p)
      (open-in-vim-in-term)
    (pen-tmux-edit "v" "cw")))

(defun open-in-vs-for-copying ()
  "Opens v in current window for buffer contents"
  (interactive)
  (if (pen-display-p)
      (open-in-vim-in-term)
    (pen-tmux-edit "vs" "cw")))

(defun open-in-vim-in-term ()
  "Opens v in current window for buffer contents"
  (interactive)
  (let ((line-and-col (pen-concat "+" (line-number-at-pos) ":" (current-column))))
    (if (and buffer-file-name (not (string-match "\\[*Org Src" (buffer-name))))
        (pen-term-nsfa (concat "vs -c \"set ls=0\" " line-and-col " " (pen-q (buffer-file-path))))
      (pen-term-nsfa (concat "vs -c \"set ls=0\" " line-and-col) (buffer-string)))))
(defalias 'e/open-in-vim 'open-in-vim-in-term)

(defun new-project-dir (name)
  (interactive (list (read-string-hist "Project name: ")))
  (pen-cl-sn (concat "new-project " (pen-q name)) :chomp t))

(defun new-project (name ext)
  "Create a new project in my git directory"
  (interactive (let* ((project-name (read-string-hist "Project name: "))
                      (ext (if (not (f-directory-p (concat "/home/shane/source/git/mullikine/" (slugify project-name))))
                               (read-string-hist "Project ext: "))))
                 (list project-name ext)))
  ;; (find-file (chomp (eval `(pen-b new-project ,(slugify name)))))
  (find-file (pen-cl-sn (concat "new-project "
                            (pen-q name)
                            " "
                            (pen-q ext)) :chomp t)))

(defun pen-show-extensions-below ()
  (interactive)
  (pen-term-nsfa "show-extensions-below | xsv table | vs"))

(defun recent-project ()
  (interactive)
  (pen-term-nsfa "hsqf new-project"))

(defun recent-playground ()
  (interactive)
  ;; (pen-term-nsfa "hsqf pg")
  (pen-nw "hsqf pg"))

(defun recent-git ()
  (interactive)
  ;; (pen-nw "hsqf git")
  (eshell-run-command (fz (pen-mnm (pen-sn "hsqc git")))))

(defun recent-hsq ()
  (interactive)
  ;; (pen-nw "hsqf git")
  (eshell-run-command (fz (pen-mnm (pen-sn "hsqc hsqc")))))

(defun fun (path)
  (interactive (list (read-string "path:")))
  "docstring"

  (if (string-empty-p path) (setq path "defaultval"))

  (let ((result (chomp (pen-sn (concat "pen-ci yt-list-playlist-urls " (pen-q path))))))
    (if (called-interactively-p 'any)
        ;; (message result)
        (new-buffer-from-string result)
      result)))

(defun eww-list-history ()
  (interactive)
  (let ((l (pen-bp uniqnosort (pen-sed "s/^.*cache://"
                                   (pen-cl-sn "uq -l | tac" :stdin (pen-list2str (hg "eww-display-html"))
                                      ;; (pen-sed "s/^.*cache://" (pen-list2str (hg "eww-display-html")))
                                              :chomp t)))))
    (if (interactive-p)
        (etv l)
      l)))

(defun eww-fz-history ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (he "eww-display-html")
    (let ((url (fz
                (eww-list-history)
                nil
                nil
                "eww history: ")))
      (if url
          (pen-lg url)))))

(provide 'pen-nix)
