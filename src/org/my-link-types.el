(require 'grep)
(require 'my-search)


;; The list of link types
;; (org-link-types)
;; j org-link-parameters


;; Disable confirmation
(setq org-confirm-elisp-link-function nil)

;; TODO Add support for evaluating a variable
(defun org-link--open-elisp (path)
  "Open a \"elisp\" type link.
PATH is the sexp to evaluate, as a string."
  (if (boundp (str2sym path))
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


;; j:org-link--open-elisp
(org-add-link-type "el" 'org-link--open-elisp)

(defun org-link--edit-var (varname)
  (edit-var-elisp (str2sym varname)))


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
(org-add-link-type "grep-app" 'mullikine/follow-grep-app-link)
(defun mullikine/follow-grep-app-link (regexp)
  "Run `grep-app' with REGEXP as argument."
  (grep-app regexp))


;; https://index.ros.org/packages/
(org-add-link-type "ros" 'mullikine/follow-rosindex-link)
(defun mullikine/follow-rosindex-link (query)
  "Search `https://index.ros.org/packages/' with QUERY as argument."
  (engine/search-rosindex query))


;; Glimpse search engine
(org-add-link-type "gli" 'mullikine/follow-gli-link)
(defun mullikine/follow-gli-link (regexp)
  "Run `gli' with REGEXP as argument."
  (glimpse-thing-at-point regexp))


;; Edit - dired
(org-add-link-type "e" 'ewhich)

;; d == ranger. dired can just be e
(org-add-link-type "d" 'e)

;;  rifle,  not ranger
(org-add-link-type "r" 'rifle)
(org-add-link-type "ri" 'rifle)


;; egr (google)
(org-add-link-type "egr" 'mullikine/follow-egr-link)
(defun mullikine/follow-egr-link (query)
  "Run `egr' with QUERY as argument."
  (sps (concat "egr " query)))


(org-add-link-type "pa" 'mullikine/follow-pa-link)
(defun mullikine/follow-pa-link (cmd)
  "Run `pa' with CMD as argument."
  (sps (concat cmd " | pa -vs")))


;; pa
(org-add-link-type "pa" 'mullikine/follow-pa-link)
(defun mullikine/follow-pa-link (cmd)
  "Run `pa' with CMD as argument."
  (sps (concat cmd " | pa -vs")))


;; cmd
(org-add-link-type "cmd" 'mullikine/follow-cmd-link)
(defun mullikine/follow-cmd-link (cmd)
  "Run `CMD'."
  (sps cmd))


(org-add-link-type "sps" 'mullikine/follow-sps-link)
(defun mullikine/follow-sps-link (cmd)
  "Run sps `CMD'."
  (sps cmd))


(org-add-link-type "yt" 'mullikine/follow-yt-link)
(defun mullikine/follow-yt-link (cmd)
  "Run sps `CMD'."
  (nw (concat "yt-search " cmd " | xa o")))


(org-add-link-type "z" 'zathura)
(defun zathura (path)
  (sn (cmd "z" path) nil nil nil t))


(org-add-link-type "l" 'mullikine/follow-l-link)
(defun mullikine/follow-l-link (pattern)
  "Run l `pattern'."
  (sps (concat "l " (q pattern))))

(org-add-link-type "j" 'mullikine/follow-j-link)
(defun mullikine/follow-j-link (pattern)
  "Run j `symbol'."
  (j (str2sym pattern)))

;; TODO Add current working directory to this
(org-add-link-type "ead" 'mullikine/follow-ead-link)
(defun mullikine/follow-ead-link (pattern)
  "Run ead `pattern'."
  (sps (concat "ead " (q pattern))))


;; This overrides the builtin eww link type
(org-add-link-type "eww" 'mullikine/follow-eww-link)
(defun mullikine/follow-eww-link (pattern)
  "Run eww `pattern'."
  (sps (concat "eww " (q pattern))))

;; This overrides the builtin eww link type
(org-add-link-type "ob" 'mullikine/follow-brain-link)
(org-add-link-type "br" 'mullikine/follow-brain-link)
(org-add-link-type "brain" 'mullikine/follow-brain-link)
(defun mullikine/follow-brain-link (pattern)
  "Run brain `pattern'."
  (org-brain-entry-from-text pattern))


(org-add-link-type "chrome" 'mullikine/follow-chrome-link)
(defun mullikine/follow-chrome-link (pattern)
  "Run chrome `pattern'."
  (sn (concat "chrome " (q pattern))))


(org-add-link-type "R" 'mullikine/follow-ranger-link)
(org-add-link-type "ranger" 'mullikine/follow-ranger-link)
(defun mullikine/follow-ranger-link (pattern)
  "Run r `pattern'."
  (sps (concat "ranger " (q pattern))))


(org-add-link-type "ff" 'mullikine/follow-ff-link)
(defun mullikine/follow-ff-link (pattern)
  "Run ff `pattern'."
  (sps (concat "ff " (q pattern))))


(org-add-link-type "v" 'mullikine/follow-v-link)
(defun mullikine/follow-v-link (pattern)
  "Run v `pattern'."
  (sps (concat "v " (q pattern))))

(org-add-link-type "vs" 'mullikine/follow-vs-link)
(defun mullikine/follow-vs-link (pattern)
  "Run v `pattern'."
  (sps (concat "vs " (q pattern))))

(org-add-link-type "sp" 'mullikine/follow-sp-link)
(defun mullikine/follow-sp-link (pattern)
  "Run sp `pattern'."
  (sps (concat "sp " (q pattern))))


;; [[tag:work+phonenumber-boss][Optional Description]]
(org-add-link-type "tag" 'endless/follow-tag-link)
(defun endless/follow-tag-link (tag)
  "Display a list of TODO headlines with tag TAG.
With prefix argument, also display headlines without a TODO keyword."
  (org-tags-view (null current-prefix-arg) tag))



(defun ead-emacs-config (pattern)
  (interactive (list (read-string-hist "ead-emacs-config: ")))
  (wgrep (concat "\\b" pattern "\\b") (mu "$EMACSD/config"))
  ;; (mu (sps (concat "cd $EMACSD/config; ead " (q pattern))))
  )
(org-add-link-type "lrk" 'ead-emacs-config)



(defset org-link-auto-functions '(show-map
                                  describe-package))

(defun org-link-generate-link-types ()
  (interactive)
  (dolist (f org-link-auto-functions)
    (let* ((name (sym2str f))
           (funname (concat "org-link-" name))
           (funsym (str2sym funname)))
      (eval
       `(progn
          (defun ,funsym (name)
            (interactive (list (read-string-hist (concat ,name ": "))))

            ;; I have to check what type the function takes
            (,f (str2sym name)))
          (org-add-link-type ,name ',funsym))))))
(org-link-generate-link-types)

(org-add-link-type "map" 'org-link-show-map)



(org-add-link-type "tcq" 'tcq)


(org-add-link-type "y" 'goto-glossary-definition-noterm)


(provide 'my-link-types)