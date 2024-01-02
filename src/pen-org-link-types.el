(require 'ace-link)
(require 'grep)
(require 'pen-search)

(setq org-confirm-elisp-link-function nil)

;; This generates links for functions
(defset org-link-auto-functions '(show-map
                                  describe-package))

(defun org-link-generate-link-types ()
  (interactive)
  (dolist (f org-link-auto-functions)
    (let* ((name (symbol-name f))
           (funname (concat "org-link-" name))
           (funsym (intern funname)))
      (eval
       `(progn
          (defun ,funsym (name)
            (interactive (list (read-string-hist (concat ,name ": "))))
            (,f (intern name)))
          (org-add-link-type ,name ',funsym))))))
(org-link-generate-link-types)

;; For example:
;; e:$EMACSD/pen.el/src/pen-journal.el



;; org-open-at-point-functions

(defun ace-link--org-collect ()
  (let ((end (window-end))
        res)
    (save-excursion
      (goto-char (window-start))
      (while (re-search-forward org-link-any-re end t)
        ;; Check that the link is visible. Look at the last character
        ;; position in the link ("...X]]") to cover links with and
        ;; without a description.
        (when (not (outline-invisible-p (- (match-end 0) 3)))
          (push
           (cons
            ;; this makes it more reliable
            (save-excursion
              ;; The goto-byte match-beginngin thing broke it for [[brain:agenda/agenda::Church]]
              ;; (goto-byte
              ;;  (match-beginning 0))
              (backward-char)
              (link-at-point))
            ;; (buffer-substring-no-properties
            ;;  (match-beginning 0)
            ;;  (match-end 0))
            (match-beginning 0))
           res)))
      (nreverse res))))

(defun org-link--open-elisp (path)
  "Open a \"elisp\" type link.
PATH is the sexp to evaluate, as a string."
  (if (boundp (intern path))
      (org-link--edit-var path)
    (if (or (and (org-string-nw-p org-link-elisp-skip-confirm-regexp)
	             (string-match-p org-link-elisp-skip-confirm-regexp path))
	        (not org-link-elisp-confirm-function)
	        (funcall org-link-elisp-confirm-function
		             (format "Execute %S as Elisp? "
			                 (org-add-props path nil 'face 'org-warning))))
        (message "%s => %s" path
	             (if (eq ?\( (string-to-char path))
		             (eval (read path))
		           (call-interactively (read path))))
      (user-error "Abort"))))

(org-add-link-type "el" 'org-link--open-elisp)

(org-add-link-type "o" 'open)
(org-add-link-type "open" 'open)


(defun org-link--edit-var (varname)
  (shut-up
    (cond ((symbolp varname)
           (edit-var-elisp varname))
          ((stringp varname)
           (edit-var-elisp (intern varname)))))
  nil)

;; rely on the fall-through
;; (org-add-link-type "ev" 'org-link--edit-var)

(org-add-link-type "dg" 'degloved-run)

(defun call-interactively-fun-name (s)
  (let* ((allargs (pen-cip-string s))
         (funname (car allargs))
         (args (cdr allargs))
         (funsym (intern funname))
         (min-arity (car (func-arity funsym)))
         (max-arity (cdr (func-arity funsym))))

    ;; This works for functions with different numbers of arguments
    (eval
     (-minsize-list `(funcall-interactively
                      ',(intern funname)
                      ,@args)
                    (+ 2 min-arity) nil))))

(org-add-link-type "ci" 'call-interactively-fun-name)
(org-add-link-type "ic" 'call-interactively-fun-name)
(org-add-link-type "mx" 'call-interactively-fun-name)

(defun call-interactively-fun-name-with-prefix (s)
  (setq current-prefix-arg '(4)) ; C-u
  (call-interactively (intern s)))
(org-add-link-type "cumx" 'call-interactively-fun-name-with-prefix)

;; grep
(org-add-link-type "grep" 'endless/follow-grep-link)
(defun endless/follow-grep-link (regexp)
  "Run `rgrep' with REGEXP as argument."
  (grep-compute-defaults)
  (rgrep regexp "*" (expand-file-name "./")))

;; http://grep.app
(org-add-link-type "grep-app" 'follow-grep-app-link)
(defun follow-grep-app-link (regexp)
  "Run `grep-app' with REGEXP as argument."
  (grep-app regexp))

;; https://index.ros.org/packages/
(org-add-link-type "ros" 'follow-rosindex-link)
(defun follow-rosindex-link (query)
  "Search `https://index.ros.org/packages/' with QUERY as argument."
  (engine/search-rosindex query))

;; Glimpse search engine
(org-add-link-type "gli" 'follow-gli-link)
(defun follow-gli-link (regexp)
  "Run `gli' with REGEXP as argument."
  (glimpse-thing-at-point regexp))

;; Edit - dired
(org-add-link-type "e" 'pen-ewhich)

;; d == ranger. dired can just be e
(org-add-link-type "d" 'e)

;;  rifle,  not ranger
(org-add-link-type "r" 'rifle)
(org-add-link-type "ri" 'rifle)

(org-add-link-type "egr" 'follow-egr-link)
(defun follow-egr-link (query)
  "Run `egr' with QUERY as argument."
  (pen-sps (concat "egr " query)))

(org-add-link-type "pa" 'follow-pa-link)
(defun follow-pa-link (cmd)
  "Run `pa' with CMD as argument."
  (pen-sps (concat cmd " | pa -vs")))

(org-add-link-type "pa" 'follow-pa-link)
(defun follow-pa-link (cmd)
  "Run `pa' with CMD as argument."
  (pen-sps (concat cmd " | pa -vs")))

(org-add-link-type "cmd" 'follow-cmd-link)
(defun follow-cmd-link (cmd)
  "Run `CMD'."
  (pen-sps cmd))

(org-add-link-type "sps" 'follow-sps-link)
(defun follow-sps-link (cmd)
  "Run pen-sps `CMD'."
  (pen-sps cmd))

(org-add-link-type "nw" 'follow-nw-link)
(defun follow-nw-link (cmd)
  "Run nw `CMD'."
  (nw cmd))

(org-add-link-type "sh" 'follow-sh-link)
(defun follow-sh-link (cmd)
  "sh:feh:$DUMP$HOME/notes/ws/screenshots/file_1668131537_screen_xNXjJJ_rand-20272_pid-733616.png "
  (pen-sn (pen-cl-sn "sed 's/^\\([a-z]\\+\\):/\\1 /'" :stdin cmd :chomp t) nil nil nil t))

(org-add-link-type "pen-sps" 'follow-pen-sps-link)
(org-add-link-type "psps" 'follow-pen-sps-link)
(org-add-link-type "psp" 'follow-pen-sps-link)
(defun follow-pen-sps-link (cmd)
  "Run sps `CMD' in pen."
  (pen-sps (concat "pen sh " cmd)))

(org-add-link-type "yt" 'follow-yt-link)
(defun follow-yt-link (cmd)
  "Run pen-sps `CMD'."
  (pen-nw (concat "yt-search " cmd " | pen-xa o")))

(org-add-link-type "z" 'zathura)
(defun zathura (path)
  (pen-sn (pen-cmd "z" path) nil nil nil t))

(org-add-link-type "l" 'follow-l-link)
(defun follow-l-link (pattern)
  "Run l `pattern'."
  (pen-sps (concat "l " (pen-q pattern))))

(org-add-link-type "j" 'follow-j-link)
(org-add-link-type "pj" 'follow-j-link)
(defun follow-j-link (pattern)
  "Run j `symbol'."
  (j (intern pattern)))

(org-add-link-type "J" 'follow-J-link)
(defun follow-J-link (pattern)
  "Run b `symbol'. to go to a Clojure symbol in Pen"
  (pen-sps (pen-cmd "psh" "J" pattern)))

(org-add-link-type "ead" 'follow-ead-link)
(defun follow-ead-link (pattern)
  "Run ead `pattern'."
  (pen-sps (concat "pen-ead " (pen-q pattern))))

(org-add-link-type "mail" 'follow-mail-link)
(defun follow-mail-link (pattern)
  "Run notmuch-mua-mail `pattern'."
  (let ((response (eval
                   `(qa -c ,(concat "Compose new email to " pattern)
                        -s ,(concat "Search for " pattern)))))
    (cond ((string-equal response (concat "Compose new email to " pattern))
           (notmuch-mua-mail pattern))
          ((string-equal response (concat "Search for " pattern))
           (notmuch-search pattern)))))

(org-add-link-type "eww" 'follow-eww-link)
(defun follow-eww-link (pattern)
  "Run eww `pattern'."
  ;; (pen-sps (concat "eww " (pen-q pattern)))
  (eww-open-url-maybe-file pattern))

(org-add-link-type "ob" 'pen-follow-brain-link)
(org-add-link-type "br" 'pen-follow-brain-link)
(org-add-link-type "brain" 'pen-follow-brain-link)

(defun pen-follow-brain-link (pattern)
  "Run brain `pattern'."
  (org-brain-entry-from-text pattern))

(org-add-link-type "chrome" 'pen-follow-chrome-link)
(defun pen-follow-chrome-link (pattern)
  "Run chrome `pattern'."
  ;; (pen-sn (concat "chrome " (pen-q pattern)))
  (chrome pattern))

(org-add-link-type "R" 'pen-follow-ranger-link)
(org-add-link-type "ranger" 'pen-follow-ranger-link)
(defun pen-follow-ranger-link (pattern)
  "Run r `pattern'."
  (pen-sps (concat "ranger " (pen-q pattern))))

(org-add-link-type "ff" 'pen-follow-ff-link)
(defun pen-follow-ff-link (pattern)
  "Run ff `pattern'."
  (pen-sps (concat "ff " (pen-q pattern))))

(org-add-link-type "replace" 'pen-follow-replace-link)
(defun pen-follow-replace-link (pattern)
  "Run replace `pattern'."
  (let ((result (chomp (eval-string pattern))))
    (pen-select-regex-at-point "\\[\\[.*\\]\\]")
    (pen-delete-selected-text)
    (insert result)))

(org-add-link-type "ftp" 'follow-ftp-link)
(defun follow-ftp-link (query)
  "Run `ftp' with QUERY as argument."

  ;; The easiest way is to open up with tramp,
  ;; and then switch to the inferior ftp server.

  (if (not (re-match-p "@" query))
      (setq query (concat "Anonymous@" query)))

  (if (not (re-match-p ":" query))
      (setq query (concat query ":/")))

  (let ((bufname (concat "*ftp " (car (s-split ":" query)) "*")))
    (find-file (concat "/ftp:" query))
    (let ((cbuf (current-buffer)))
      (split-window-no-error)
      (switch-to-buffer bufname)))

  ;; "buffer-name": "*ftp Anonymous@ftp.crosswire.org*"
  ;; (ange-ftp-smart-login)
  )

(org-add-link-type "bible" 'follow-bible-link)
(defun follow-bible-link (query)
  "Run `bible' with QUERY as argument."
  (bible-mode-lookup query))

(org-add-link-type "v" 'pen-follow-v-link)
(defun pen-follow-v-link (pattern)
  "Run v `pattern'."
  (pen-sps (concat "v " (pen-q pattern))))

(org-add-link-type "vs" 'pen-follow-vs-link)
(defun pen-follow-vs-link (pattern)
  "Run v `pattern'."
  (pen-sps (concat "vs " (pen-q pattern))))

(org-add-link-type "sp" 'pen-follow-sp-link)
(defun pen-follow-sp-link (pattern)
  "Run sp `pattern'."
  (pen-sps (concat "sp " (pen-q pattern))))

(org-add-link-type "h" 'pen-follow-symbol-help)
(defun pen-follow-symbol-help (name)
  (helpful-symbol (intern name)))

(org-add-link-type "tag" 'endless/follow-tag-link)
(defun endless/follow-tag-link (tag)
  "Display a list of TODO headlines with tag TAG.
With prefix argument, also display headlines without a TODO keyword."
  (org-tags-view (null current-prefix-arg) tag))

(defun ead-emacs-config (pattern)
  (interactive (list (read-string-hist "ead-emacs-config: ")))
  (wgrep (concat "\\b" pattern "\\b") (mu "$EMACSD/config")))
(org-add-link-type "lrk" 'ead-emacs-config)



(org-add-link-type "map" 'org-link-show-map)
(org-add-link-type "tcq" 'tcq)
(org-add-link-type "y" 'pen-goto-glossary-definition-noterm)
(org-add-link-type "Y" 'pen-go-to-glossary-file-for-buffer)


;; I extended org-info--link-file-node to handle both formats

;; [[info:(org) Deadlines and Scheduling]]
;; [[info:org#Deadlines and Scheduling]]
;; [[info:org]]
;; [[info:(org)]]

(defun org-info--link-file-node (path)
  "Extract file name and node from info link PATH.

Return cons consisting of file name and node name or \"Top\" if node
part is not specified.  Components may be separated by \":\" or by \"#\".
File may be a virtual one, see `Info-virtual-files'."
  (if (not path)
      '("dir" . "Top")
    (cond ((re-match-p "#" path)
           (progn
             (string-match "\\`\\([^#:]*\\)\\(?:[#:]:?\\(.*\\)\\)?\\'" path)
             (let* ((node (match-string 2 path))
                    ;; Do not reorder, `org-trim' modifies match.
                    (file (org-trim (match-string 1 path))))
               (cons
                (if (org-string-nw-p file) file "dir")
                (if (org-string-nw-p node) (org-trim node) "Top")))))
          ((re-match-p "(" path)
           (progn
             (string-match "\\`(\\([^):]*\\)) *\\(\\(.*\\)\\)?\\'" path)
             (let* ((node (match-string 2 path))
                    ;; Do not reorder, `org-trim' modifies match.
                    (file (org-trim (match-string 1 path))))
               (cons
                (if (org-string-nw-p file) file "dir")
                (if (org-string-nw-p node) (org-trim node) "Top")))))
          (t
           (progn
             (string-match "\\`\\([^#:]*\\)\\(?:[#:]:?\\(.*\\)\\)?\\'" path)
             (let* ((node (match-string 2 path))
                    ;; Do not reorder, `org-trim' modifies match.
                    (file (org-trim (match-string 1 path))))
               (cons
                (if (org-string-nw-p file) file "dir")
                (if (org-string-nw-p node) (org-trim node) "Top"))))))))

(defun org-link-open-from-string (s &optional arg)
  "Open a link in the string S, as if it was in Org mode.
Optional argument is passed to `org-open-file' when S is
a \"file\" link."
  (interactive "sLink: \nP")
  (pcase (with-temp-buffer
	       (let ((org-inhibit-startup nil))
	         (insert s)
             ;; Switching to org-mode kinda breaks it
	         ;; (org-mode)
	         (goto-char (point-min))
             ;; (call-interactively 'tm-edit-v-in-nw)
	         (org-element-link-parser)))
    (`nil (user-error "No valid link in %S" s))
    (link (org-link-open link arg))))

(provide 'pen-org-link-types)
