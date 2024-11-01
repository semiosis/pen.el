;;; helm-ext-ff.el --- Extension to helm-find-files  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; Keywords: extensions

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'ffap)
(require 'helm-files)
(require 'helm-mode)

(defvar helm-ext-ff-skipping-dots-recenter nil
  "If t, recenter after skipping the dots.")

(defvar helm-ext-ff-valid-expansion-only t
  "It t, only consider valid path expansions.")

(defvar helm-ext-ff-sort-expansions nil
  "If t, sort the expansions.")

(defvar helm-ext-ff-expansion-ignore-case t
  "If t, ignore case when expanding the paths.")

(defvar helm-ext-ff--invalid-dir nil)

(defun helm-ext-ff--generate-case-ignore-pattern (pattern)
  (let (head (ci-pattern ""))
    (dotimes (i (length pattern) ci-pattern)
      (setq head (aref pattern i))
      (cond
       ((and (<= head ?z) (>= head ?a))
        (setq ci-pattern (format "%s[%c%c]" ci-pattern (upcase head) head)))
       ((and (<= head ?Z) (>= head ?A))
        (setq ci-pattern (format "%s[%c%c]" ci-pattern head (downcase head))))
       (:else
        (setq ci-pattern (format "%s%c" ci-pattern head)))))))

(defun helm-ext-ff--try-expand-fname (candidate)
  (let ((dirparts (split-string candidate "/"))
        valid-dir
        fnames)
    (catch 'break
      (while dirparts
        (if (file-directory-p (concat valid-dir (car dirparts) "/"))
            (setq valid-dir (concat valid-dir (pop dirparts) "/"))
          (throw 'break t))))
    (setq fnames (cons candidate (helm-ext-ff--try-expand-fname-1 valid-dir dirparts)))
    (if helm-ext-ff-sort-expansions
        (sort fnames
              (lambda (f1 f2) (or (file-exists-p f1)
                                  (file-directory-p f1)
                                  (not (file-directory-p f2)))))
      fnames)))

(defun helm-ext-ff--try-expand-fname-1 (parent children)
  (if children
      (if (equal children '(""))
          (and (file-directory-p parent) `(,(concat parent "/")))
        (when (file-directory-p parent)
          (apply 'nconc
                 (mapcar
                  (lambda (f)
                    (or (helm-ext-ff--try-expand-fname-1 f (cdr children))
                        (unless helm-ext-ff-valid-expansion-only
                          (and (file-directory-p f)
                               `(,(concat f "/" (mapconcat 'identity
                                                           (cdr children)
                                                           "/")))))))
                  (directory-files parent t
                                   (concat "^"
                                           (if helm-ext-ff-expansion-ignore-case
                                               (helm-ext-ff--generate-case-ignore-pattern
                                                (car children))
                                             (car children))))))))
    `(,(concat parent (and (file-directory-p parent) "/")))))

(defun helm-ext-ff--try-expand-fname-first (orig-func &rest args)
  (let* ((candidate (car args))
         (collection (helm-ext-ff--try-expand-fname candidate)))
    (if (and (> (length collection) 1)
             (not (file-exists-p candidate)))
        (with-helm-alive-p
          (when (helm-file-completion-source-p)
            (helm-set-pattern
             (helm-comp-read "Expand Path to: " collection :allow-nest t))))
      (apply orig-func args))))

(defun helm-ext-find-files-get-candidates (&optional require-match)
  "Create candidate list for `helm-source-find-files'."
  (let* ((path          (helm-ff-set-pattern helm-pattern))
         (dir-p         (file-accessible-directory-p path))
         basedir
         invalid-basedir
         non-essential
         (tramp-verbose helm-tramp-verbose)) ; No tramp message when 0.
    ;; Tramp check if path is valid without waiting a valid
    ;; connection and may send a file-error.
    (setq helm--ignore-errors (file-remote-p path))
    (set-text-properties 0 (length path) nil path)
    ;; Issue #118 allow creation of newdir+newfile.
    (unless (or
             ;; A tramp file name not completed.
             (string= path "Invalid tramp file name")
             ;; An empty pattern
             (string= path "")
             (and (string-match-p ":\\'" path)
                  (helm-ff--tramp-postfixed-p path))
             ;; Check if base directory of PATH is valid.
             (helm-aif (file-name-directory path)
                 ;; If PATH is a valid directory IT=PATH,
                 ;; else IT=basedir of PATH.
                 (file-directory-p it)))
      ;; BASEDIR is invalid, that's mean user is starting
      ;; to write a non--existing path in minibuffer
      ;; probably to create a 'new_dir' or a 'new_dir+new_file'.
      (setq invalid-basedir t))
    ;; Don't set now `helm-pattern' if `path' == "Invalid tramp file name"
    ;; like that the actual value (e.g /ssh:) is passed to
    ;; `helm-ff--tramp-hostnames'.
    (unless (or (string= path "Invalid tramp file name")
                ;; Ext: remove invalid-basedir
                )      ; Leave  helm-pattern unchanged.
      (setq helm-ff-auto-update-flag  ; [1]
            ;; Unless auto update is disabled at startup or
            ;; interactively, start auto updating only at third char.
            (unless (or (null helm-ff-auto-update-initial-value)
                        (null helm-ff--auto-update-state)
                        ;; But don't enable auto update when
                        ;; deleting backward.
                        helm-ff--deleting-char-backward
                        (and dir-p (not (string-match-p "/\\'" path))))
              (or (>= (length (helm-basename path)) 3) dir-p)))
      ;; At this point the tramp connection is triggered.
      (setq helm-pattern (helm-ff--transform-pattern-for-completion path))
      ;; This have to be set after [1] to allow deleting char backward.
      (setq basedir (expand-file-name
                     (if (and dir-p helm-ff-auto-update-flag)
                         ;; Add the final "/" to path
                         ;; when `helm-ff-auto-update-flag' is enabled.
                         (file-name-as-directory path)
                       (if (string= path "")
                           "/" (file-name-directory path)))))
      (setq helm-ff-default-directory
            (if (string= helm-pattern "")
                (expand-file-name "/")  ; Expand to "/" or "c:/"
              ;; If path is an url *default-directory have to be nil.
              (unless (or (string-match helm-ff-url-regexp path)
                          (and ffap-url-regexp
                               (string-match ffap-url-regexp path)))
                basedir))))
    (when (and (string-match ":\\'" path)
               (file-remote-p basedir nil t))
      (setq helm-pattern basedir))
    (cond ((string= path "Invalid tramp file name")
           (or (helm-ff--tramp-hostnames) ; Hostnames completion.
               (prog2
                   ;; `helm-pattern' have not been modified yet.
                   ;; Set it here to the value of `path' that should be now
                   ;; "Invalid tramp file name" and set the candidates list
                   ;; to ("Invalid tramp file name") to make `helm-pattern'
                   ;; match single candidate "Invalid tramp file name".
                   (setq helm-pattern path)
                   ;; "Invalid tramp file name" is now printed
                   ;; in `helm-buffer'.
                   (list path))))
          ((or (and (file-regular-p path)
                    (eq last-repeatable-command 'helm-execute-persistent-action))
               ;; `ffap-url-regexp' don't match until url is complete.
               (string-match helm-ff-url-regexp path)
               (and ffap-url-regexp (string-match ffap-url-regexp path)))
           (list (helm-ff-filter-candidate-one-by-one path nil t)))
          ;; Ext: list all possible expansions
          ((or invalid-basedir
               (and (not (file-exists-p path)) (string-match "/$" path)))
           (mapcar (lambda (p) (helm-ext-ff-filter-candidate-one-by-one p nil t)) (helm-ext-ff--try-expand-fname path)))
          ((string= path "") (helm-ff-directory-files "/"))
          ;; Check here if directory is accessible (not working on Windows).
          ((and (file-directory-p path) (not (file-readable-p path)))
           (list (format "file-error: Opening directory permission denied `%s'" path)))
          ;; A fast expansion of PATH is made only if `helm-ff-auto-update-flag'
          ;; is enabled.
          ((and dir-p helm-ff-auto-update-flag)
           (helm-ff-directory-files path))
          (t
           (append (unless (or require-match
                               ;; When `helm-ff-auto-update-flag' has been
                               ;; disabled, whe don't want PATH to be added on top
                               ;; if it is a directory.
                               (file-exists-p path)
                               dir-p)
                     (list (helm-ext-ff-filter-candidate-one-by-one path nil t)))
                   (helm-ff-directory-files basedir))))))

(defun helm-ext-ff--transform-pattern-for-completion (pattern)
  "Maybe return PATTERN with it's basename modified as a regexp.
This happen only when `helm-ff-fuzzy-matching' is enabled.
This provide a similar behavior as `ido-enable-flex-matching'.
See also `helm--mapconcat-pattern'.
If PATTERN is an url returns it unmodified.
When PATTERN contain a space fallback to multi-match.
If basename contain one or more space fallback to multi-match.
If PATTERN is a valid directory name,return PATTERN unchanged."
  ;; handle bad filenames containing a backslash.
  (setq pattern (helm-ff-handle-backslash pattern))
  (let ((bn      (helm-basename pattern))
        (bd      (or (helm-basedir pattern) ""))
        ;; Trigger tramp connection with file-directory-p.
        (dir-p   (or (file-directory-p pattern)
                     ;; Ext: as long as it ends with `/'
                     (string-match "/$" pattern)))
        (tramp-p (cl-loop for (m . f) in tramp-methods
                          thereis (string-match m pattern))))
    ;; Ext: set invalid
    (setq helm-ext-ff--invalid-dir (not (file-exists-p bd)))
    ;; Always regexp-quote base directory name to handle
    ;; crap dirnames such e.g bookmark+
    ;; Ext: fuzzy match -- in order to bypass `helm-mm-match'
    (replace-regexp-in-string
     "/"
     ".*/"
     (cond
      ((or (and dir-p tramp-p (string-match ":\\'" pattern))
           (string= pattern "")
           (and dir-p (<= (length bn) 2))
           ;; Fix Issue #541 when BD have a subdir similar
           ;; to BN, don't switch to match plugin
           ;; which will match both.
           (and dir-p (string-match (regexp-quote bn) bd)))
       ;; Use full PATTERN on e.g "/ssh:host:".
       (regexp-quote pattern))
      ;; Prefixing BN with a space call multi-match completion.
      ;; This allow showing all files/dirs matching BN (Issue #518).
      ;; FIXME: some multi-match methods may not work here.
      (dir-p (concat (regexp-quote bd) " " (regexp-quote bn)))
      ((or (not (helm-ff-fuzzy-matching-p))
           (string-match "\\s-" bn))    ; Fall back to multi-match.
       (concat (regexp-quote bd) bn))
      ((or (string-match "[*][.]?.*" bn) ; Allow entering wilcard.
           (string-match "/$" pattern)   ; Allow mkdir.
           (string-match helm-ff-url-regexp pattern)
           (and (string= helm-ff-default-directory "/") tramp-p))
       ;; Don't treat wildcards ("*") as regexp char.
       ;; (e.g ./foo/*.el => ./foo/[*].el)
       (concat (regexp-quote bd)
               (replace-regexp-in-string "[*]" "[*]" bn)))
      (t (concat (regexp-quote bd)
                 (if (>= (length bn) 2) ; wait 2nd char before concating.
                     (helm--mapconcat-pattern bn)
                   (concat ".*" (regexp-quote bn)))))))))

(defun helm-ext-find-files-1 (orig-func &rest args)
  (unwind-protect
      (apply orig-func args)
    ;; Ext: reset to nil
    (setq helm-ext-ff--invalid-dir nil)))

(defun helm-ext-ff-filter-candidate-one-by-one (file &optional reverse skip-boring-check)
  "`filter-one-by-one' Transformer function for `helm-source-find-files'."
  ;; Handle boring files
  (unless (and helm-ff-skip-boring-files
               (cl-loop for r in helm-boring-file-regexp-list
                        ;; Prevent user doing silly thing like
                        ;; adding the dotted files to boring regexps (#924).
                        thereis (and (not (string-match "\\.$" file))
                                     (string-match r file))))
    ;; Handle tramp files.
    (if (and (string-match helm-tramp-file-name-regexp helm-pattern)
             helm-ff-tramp-not-fancy)
        (if helm-ff-transformer-show-only-basename
            (if (helm-dir-is-dot file)
                file
              (cons (or (helm-ff--get-host-from-tramp-invalid-fname file)
                        (helm-basename file))
                    file))
          file)
      ;; Now highlight.
      (let* ((disp (if (and helm-ff-transformer-show-only-basename
                            ;; Ext: Don't show basename if not valid
                            (not helm-ext-ff--invalid-dir)
                            (not (helm-dir-is-dot file))
                            (not (and ffap-url-regexp
                                      (string-match ffap-url-regexp file)))
                            (not (string-match helm-ff-url-regexp file)))
                       (or (helm-ff--get-host-from-tramp-invalid-fname file)
                           (helm-basename file)) file))
             (attr (file-attributes file))
             (type (car attr)))

        (cond ((string-match "file-error" file) file)
              ( ;; A not already saved file.
               (and (stringp type)
                    (not (helm-ff-valid-symlink-p file))
                    (not (string-match "^\.#" (helm-basename file))))
               (cons (helm-ff-prefix-filename
                      (propertize disp 'face 'helm-ff-invalid-symlink) t)
                     file))
              ;; A dotted directory symlinked.
              ((and (helm-ff-dot-file-p file) (stringp type))
               (cons (helm-ff-prefix-filename
                      (propertize disp 'face 'helm-ff-dotted-symlink-directory) t)
                     file))
              ;; A dotted directory.
              ((helm-ff-dot-file-p file)
               (cons (helm-ff-prefix-filename
                      (propertize disp 'face 'helm-ff-dotted-directory) t)
                     file))
              ;; A symlink.
              ((stringp type)
               (cons (helm-ff-prefix-filename
                      (propertize disp 'face 'helm-ff-symlink) t)
                     file))
              ;; A directory.
              ((eq t type)
               (cons (helm-ff-prefix-filename
                      (propertize disp 'face 'helm-ff-directory) t)
                     file))
              ;; An executable file.
              ((and attr (string-match "x" (nth 8 attr)))
               (cons (helm-ff-prefix-filename
                      (propertize disp 'face 'helm-ff-executable) t)
                     file))
              ;; A file.
              ((and attr (null type))
               (cons (helm-ff-prefix-filename
                      (propertize disp 'face 'helm-ff-file) t)
                     file))
              ;; A non--existing file.
              (t
               (cons (helm-ff-prefix-filename
                      (propertize disp 'face 'helm-ff-file) nil 'new-file)
                     file)))))))

(defun helm-ext-ff-skip-dots (orig-func &rest args)
  (prog1 (apply orig-func args)
    (unless (helm-empty-buffer-p helm-buffer)
	  (let ((src (helm-get-current-source))
			(flag nil)
			(scroll-margin 0))
		(while (and (not (helm-end-of-source-p))
					(helm-dir-is-dot (helm-get-selection nil t src)))
		  (helm-next-line)
		  (setq flag t))
		(when (and (helm-end-of-source-p)
				   (helm-dir-is-dot (helm-get-selection nil t src)))
		  (helm-previous-line))
		(and helm-ext-ff-skipping-dots-recenter
			 flag
			 (with-helm-window
			   (recenter-top-bottom 0)))))))

(defvar helm-ext-ff--horizontal-split-action
  '("Find file in horizontal split" .
    helm-ext-ff-action-horizontal-split))

(defvar helm-ext-ff--vertical-split-action
  '("Find file in vertical split" .
    helm-ext-ff-action-vertical-split))

(defvar helm-ext-ff--buffer-horizontal-split-action
  '("View buffer in horizontal split" .
    helm-ext-ff-action-horizontal-split))

(defvar helm-ext-ff--buffer-vertical-split-action
  '("View buffer in vertical split" .
    helm-ext-ff-action-vertical-split))

(defvar helm-ext-ff-horizontal-split-key "C-c s h")
(defvar helm-ext-ff-vertical-split-key "C-c s v")
(defvar helm-ext-ff-split-actions-keymaps (list helm-find-files-map helm-buffer-map))

(defun helm-ext-ff-default-find-function (candidate)
  (if (get-buffer candidate)
      (switch-to-buffer candidate)
    (find-file candidate)))

(defun helm-ext-ff-get-split-function (type find-func balance-p)
  (let ((body (list 'lambda '(buf)
                    `(select-window (,(if (eq type 'horizontal)
                                          'split-window-below
                                        'split-window-right)))
                    `(,find-func buf))))
    (if balance-p
        (append body '((balance-windows)))
      body)))

;;;###autoload
(defmacro helm-ext-ff-define-split (name type find-func &optional balance-p)
  (declare (indent 2))
  (let ((action-func (intern (format "helm-ext-ff-%s-action-%s-split" name type)))
        (execution-func (intern (format "helm-ext-ff-%s-execute-%s-split" name type)))
        (split-func (helm-ext-ff-get-split-function type find-func balance-p)))
    `(progn
       (defun ,action-func (_candidate)
         (dolist (buf (helm-marked-candidates))
           (funcall ,split-func buf)))
       (defun ,execution-func ()
         (interactive)
         (with-helm-alive-p
           (helm-exit-and-execute-action ',action-func))))))

(helm-ext-ff-define-split
    buffer
    horizontal
  helm-ext-ff-default-find-function
  t)

(helm-ext-ff-define-split
    buffer
    vertical
  helm-ext-ff-default-find-function
  t)

(provide 'helm-ext-ff)
;;; helm-ext-ff.el ends here
