(require 'ivy)
(require 'pen-compatibility)

;; to fix a bug if the var is not available
(if (not (fboundp 'ivy-highlight-grep-commands))
    (defset ivy-highlight-grep-commands nil))
(if (not (fboundp 'ivy-make-magic-action))
    (defun ivy-make-magic-action (a b) nil))

(require 'counsel)

; vim +/"ivy-height" "$EMACSD/config/pen-ivy.el"

;; Spacemacs' find file was annoying because of C-h.
;; Remove the keymap from M-m f f

;; DONE Actually, make my own keymap. M-D does not work to delete line backwards. I have to use M-DEL instead. Super annoying. Or I could add a new map.
;; FIXED
(define-key counsel-mode-map (kbd "M-D") (kbd "M-DEL"))

(defun counsel-find-file (&optional initial-input)
  "Forward to `find-file'.
When INITIAL-INPUT is non-nil, use it in the minibuffer during completion."
  (interactive)
  (ivy-read "Find file: " 'read-file-name-internal
            :matcher #'counsel--find-file-matcher
            :initial-input initial-input
            :action #'counsel-find-file-action
            :preselect (counsel--preselect-file)
            :require-match 'confirm-after-completion
            :history 'file-name-history
            :keymap nil
            :caller 'counsel-find-file))

(setq counsel-ag-base-command "pen-counsel-ag-cmd %s")


;; DONE This and counsel-ag could be used to create a genertic fuzzy finder
(defun counsel-ag-function (string)
  "Grep in the current directory for STRING."
  (let* ((command-args (counsel--split-command-args string))
         (search-term (cdr command-args)))
    (or
     (let ((ivy-text search-term))
       (ivy-more-chars))
     (let* ((default-directory (ivy-state-directory ivy-last))
            ;; (regex (counsel--grep-regex search-term))
            (switches (concat (car command-args)
                              ;; (counsel--ag-extra-switches regex)

                              ;; Don't add extra arguments or generic programs other than ag will have problems

                              ;; (if (ivy--case-fold-p string)
                              ;;     " -i "
                              ;;   " -s ")
                              )))
       (counsel--async-command (counsel--format-ag-command
                                switches
                                (funcall (if (listp counsel-ag-command) #'identity
                                           #'shell-quote-argument)
                                         ;; regex
                                         string
                                         )))
       nil))))


(cl-defun counsel-ag (&optional initial-input initial-directory extra-ag-args ag-prompt
                                &key caller &key histvar)
  "Grep for a string in a root directory using ag.

By default, the root directory is the first directory containing a .git subdirectory.

INITIAL-INPUT can be given as the initial minibuffer input.
INITIAL-DIRECTORY, if non-nil, is used as the root directory for search.
EXTRA-AG-ARGS, if non-nil, is appended to `counsel-ag-base-command'.
AG-PROMPT, if non-nil, is passed as `ivy-read' prompt argument.
CALLER is passed to `ivy-read'.

With a `\\[universal-argument]' prefix argument, prompt for INITIAL-DIRECTORY.
With a `\\[universal-argument] \\[universal-argument]' prefix argument, \
prompt additionally for EXTRA-AG-ARGS."
  (interactive)

  (if (not histvar)
      (setq histvar 'counsel-git-grep-history))

  (setq counsel-ag-command counsel-ag-base-command)
  (setq counsel--regex-look-around counsel--grep-tool-look-around)
  (counsel-require-program counsel-ag-command)
  (let ((prog-name (car (if (listp counsel-ag-command) counsel-ag-command
                          (split-string counsel-ag-command))))
        (arg (prefix-numeric-value current-prefix-arg)))
    (when (>= arg 4)
      (setq initial-directory
            (or initial-directory
                (pen-pwd)
                ;; (counsel-read-directory-name (concat
                ;;                               prog-name
                ;;                               " in directory: "))
                )))
    (when (>= arg 16)
      (setq extra-ag-args
            (or extra-ag-args
                (read-from-minibuffer (format "%s args: " prog-name)))))
    (setq counsel-ag-command (counsel--format-ag-command (or extra-ag-args "") "%s"))
    (let ((default-directory (or initial-directory
                                 (counsel--git-root)
                                 default-directory)))
      (ivy-read (or ag-prompt
                    (concat prog-name ": "))
                #'counsel-ag-function
                :initial-input initial-input
                :dynamic-collection t
                :keymap counsel-ag-map
                :history histvar
                :action #'counsel-git-grep-action
                :require-match t
                :caller (or caller 'counsel-ag)))))



;; (defun helm-google-suggest-action (candidate)
;;   "Default action to jump to a Google suggested candidate."
;;   (let ((arg (format helm-google-suggest-search-url
;;                      (url-hexify-string candidate))))
;;     (helm-aif helm-google-suggest-default-browser-function
;;         (funcall it arg)
;;       (helm-browse-url arg))))

(defun counsel-search-action (x)
  "Search for X."
  ;; This is what gives helm-google its prompt
  (helm-google 'google x)
  ;; (browse-url
  ;;  (concat
  ;;   (nth 2 (assoc counsel-search-engine counsel-search-engines-alist))
  ;;   (url-hexify-string x)))
  )


(defun counsel-search ()
  "Ivy interface for dynamically querying a search engine."
  (interactive)
  (require 'request)
  (require 'json)
  (ivy-read "search: " #'counsel-search-function
            ;; helm-google-suggest-actions
            :action #'counsel-search-action
            :dynamic-collection t
            :caller 'counsel-search))

(defun fz-gl (query)
  (interactive (list (read-string-hist "fz-gl: ")))

  (let ((result (fz (pen-snc (concat (pen-cmd "gl") " " query))
                    nil nil "fz-gl result: ")))
    (eww result)))

(defun counsel-gl ()
  "Ivy interface for dynamically querying a search engine."
  (interactive)
  (require 'request)
  (require 'json)
  (ivy-read "search: " #'counsel-search-function
            ;; helm-google-suggest-actions
            :action #'fz-gl
            :dynamic-collection t
            :caller 'counsel-search))

(defun counsel-fzf-here ()
  (interactive)
  (counsel-fzf nil default-directory))

(define-key pen-map (kbd "M-q M-q") 'counsel-fzf-here)

(provide 'pen-counsel)
