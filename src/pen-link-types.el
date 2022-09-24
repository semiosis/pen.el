(require 'grep)
(require 'pen-search)

(setq org-confirm-elisp-link-function nil)

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

(defun org-link--edit-var (varname)
  (edit-var-elisp (intern varname)))

(org-add-link-type "ev" 'org-link--edit-var)
(org-add-link-type "dg" 'degloved-run)

(defun call-interactively-fun-name (s)
  (call-interactively (intern s)))

(org-add-link-type "ci" 'call-interactively-fun-name)
(org-add-link-type "ic" 'call-interactively-fun-name)
(org-add-link-type "mx" 'call-interactively-fun-name)

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

(org-add-link-type "eww" 'follow-eww-link)
(defun follow-eww-link (pattern)
  "Run eww `pattern'."
  (pen-sps (concat "eww " (pen-q pattern))))

(org-add-link-type "ob" 'mullikine/follow-brain-link)
(org-add-link-type "br" 'mullikine/follow-brain-link)
(org-add-link-type "brain" 'mullikine/follow-brain-link)

(defun mullikine/follow-brain-link (pattern)
  "Run brain `pattern'."
  (org-brain-entry-from-text pattern))

(org-add-link-type "chrome" 'mullikine/follow-chrome-link)
(defun mullikine/follow-chrome-link (pattern)
  "Run chrome `pattern'."
  (pen-sn (concat "chrome " (pen-q pattern))))

(org-add-link-type "R" 'mullikine/follow-ranger-link)
(org-add-link-type "ranger" 'mullikine/follow-ranger-link)
(defun mullikine/follow-ranger-link (pattern)
  "Run r `pattern'."
  (pen-sps (concat "ranger " (pen-q pattern))))

(org-add-link-type "ff" 'mullikine/follow-ff-link)
(defun mullikine/follow-ff-link (pattern)
  "Run ff `pattern'."
  (pen-sps (concat "ff " (pen-q pattern))))

(org-add-link-type "replace" 'mullikine/follow-replace-link)
(defun mullikine/follow-replace-link (pattern)
  "Run replace `pattern'."
  (let ((result (chomp (eval-string pattern))))
    (pen-select-regex-at-point "\\[\\[.*\\]\\]")
    (pen-delete-selected-text)
    (insert result)))

(org-add-link-type "v" 'mullikine/follow-v-link)
(defun mullikine/follow-v-link (pattern)
  "Run v `pattern'."
  (pen-sps (concat "v " (pen-q pattern))))

(org-add-link-type "vs" 'mullikine/follow-vs-link)
(defun mullikine/follow-vs-link (pattern)
  "Run v `pattern'."
  (pen-sps (concat "vs " (pen-q pattern))))

(org-add-link-type "sp" 'mullikine/follow-sp-link)
(defun mullikine/follow-sp-link (pattern)
  "Run sp `pattern'."
  (pen-sps (concat "sp " (pen-q pattern))))

(org-add-link-type "h" 'mullikine/follow-symbol-help)
(defun mullikine/follow-symbol-help (name)
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

(org-add-link-type "map" 'org-link-show-map)

(org-add-link-type "tcq" 'tcq)

(org-add-link-type "y" 'pen-goto-glossary-definition-noterm)
(org-add-link-type "Y" 'pen-go-to-glossary-file-for-buffer)

(provide 'pen-link-types)
