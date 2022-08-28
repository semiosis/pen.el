(require 's)

;; -- shell

(defun hsqf (cmdname)
  "Run a command from history"
  (interactive (list (read-string-hist "hsqf command:")))
  (let* ((selected-command (fz (pen-mnm (pen-sn (concat "hsqc -ao " cmdname))) nil nil "hsqf past cmd: "))
         (selected-command (pen-sn "hsqf-clean" selected-command))
         (wd (pen-uq (s-replace-regexp "^cd \"\\([^\"]+\\)\".*$" "\\1" selected-command)))
         (pen-cmd (s-replace-regexp (concat "^[^;]*; \\([^ ]+\\).*") "\\1" selected-command)))

    (cond ((string-equal cmd "hsqf")
           (progn
             (setq cmd (s-replace-regexp (concat "^[^;]*; [^ ]+ \\([^ ]+\\).*") "\\1" selected-command))
             (hsqf cmd)))

          (t (sps selected-command)))))

(defun hsqf-gc ()
  (interactive)
  (let ((url (fz (pen-snc "xurls | uniqnosort" (pen-mnm (pen-snc (pen-cmd "hsqc" "gc"))))
                 nil nil "gc: ")))
    (gc url)))

(define-key global-map (kbd "M-m") nil)
(pen-mu
 (pen-ms "/M-m/{p;s/M-m/M-l/}"
         (define-key global-map (kbd "M-m H Z") (dff (find-file "$HOME/.zsh_history")))
         (define-key global-map (kbd "M-m H B") (dff (find-file "$HOME/.bash_history")))
         ;; (define-key global-map (kbd "M-m H G") (dff (hsqf "gh")))
         (define-key global-map (kbd "M-m H c") 'hsqf-gc)
         (define-key global-map (kbd "M-m H b") (dff (hsqf "cr")))
         (define-key global-map (kbd "M-m H H") (dff (hsqf "hsqf")))
         (define-key global-map (kbd "M-m H r") (dff (hsqf "readsubs")))
         (define-key global-map (kbd "M-m H A") (dff (hsqf "new-article")))
         ;; (define-key global-map (kbd "M-m H N") (dff (hsqf "new-project")))
         (define-key global-map (kbd "M-m H N") 'new-project)
         (define-key global-map (kbd "M-m H K") (dff (hsqf "killall")))
         (define-key global-map (kbd "M-m H X") (dff (hsqf "xrandr")))
         (define-key global-map (kbd "M-m H F") (dff (hsqf "feh")))
         (define-key global-map (kbd "M-m H P") (dff (hsqf "play-song")))
         (define-key global-map (kbd "M-m H D") (dff (hsqf "docker")))
         (define-key global-map (kbd "M-m H g") (dff (hsqf "git")))
         (define-key global-map (kbd "M-m H O") (dff (hsqf "o")))
         (define-key global-map (kbd "M-m H o") (dff (hsqf "o")))
         (define-key global-map (kbd "M-m H y") (dff (hsqf "yt")))
         (define-key global-map (kbd "M-m H C") (dff (hsqf "hcqf")))
         (define-key global-map (kbd "M-m H h") #'hsqf)))


;; -- emacs

(defun hs (name &rest body)
  "Function. Record the arguments into hs before running."
  ;; (eval `(sh/hs ,name ,(mapconcat 'str body " ")))
  (pen-sn (concat "hist-save " (pen-q name) " " (mapconcat 'pen-q (mapcar 'str body) " "))))

(defalias 'pen-str2lines 's-lines)

(defun pen-hg (name)
  (pen-str2lines (pen-cl-sn (concat "hist-get " (pen-q name)) :chomp t)))

(defun pen-hist-edit (name)
  (find-file (pen-cl-sn (concat "hist-getfile " (pen-q name)) :chomp t)))
(defalias 'pen-he 'pen-hist-edit)

(defmacro sh/hs (name &rest body)
  `(shell-command (concat "hs " "emacs-" (str ,name) " " (pen-q (str ',@body)))))

(provide 'pen-hist)
