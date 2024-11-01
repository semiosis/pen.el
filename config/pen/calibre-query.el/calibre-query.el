;;; calibre-query.el --- query the Calibre metadata database from emacs

;; Copyright (C) 2011- whacked

;; Author: whacked <whacked@users.noreply.github.com>
;; Version: 0.0.1
;; Package-Requires: (esqlite s seq hydra)
;; Keywords: calibre, ebook, database
;; URL: https://github.com/whacked/calibre-query.el

;;; Commentary:

;; Provides convenience functions to query the calibre database for
;; information about books, including attributes like author, path on
;; disk, formats, and provides interactive shortcuts for inserting and
;; interacting with the information from the minibuffer via hydra.

;;; Code:

(require 'cl)
(require 'esqlite)
(require 'hydra)
(require 'json)
(require 'org)
(require 's)
(require 'seq)
(require 'sql)
(when (featurep 'ivy)
  (require 'ivy))

;; NOTE: esqlite-sqlite-program must be findable in exec-path
(setq calibre--calibre-library-name "Calibre Library")

(defun calibre--get-first-existing-path (candidate-path-list)
  (first
   (seq-remove
    (lambda (maybe-path)
      (or (null maybe-path)
          (not (file-exists-p
                maybe-path))))
    candidate-path-list)))

(defun calibre--get-library-path-from-global-py (calibre-global-py-path)
  (with-temp-buffer
    (insert-file-contents calibre-global-py-filepath)
    (delete-non-matching-lines "library_path")
    (goto-char (point-min))
    (while (search-forward-regexp
            "library_path *= *\\u?['\"]\\(.+\\)['\"]" nil t)
      (replace-match "\\1"))
    (goto-char (point-min))
    (while (search-forward "\\\\" nil t)
      (replace-match "\\" nil t))
    (file-name-as-directory (s-chomp (buffer-string)))))

(defun calibre--get-library-path-from-global-py-json (calibre-global-py-json-path)
  (cdr
   (assoc
    'library_path
    (json-read-file calibre-global-py-json-path))))

(defun calibre--find-library-filepath ()
  (or
   ;; if global.py.json exists, parse it for "library_path"
   (let ((global-py-json (calibre--get-first-existing-path
                          (list
                           (expand-file-name "~/.config/calibre/global.py.json")
                           (expand-file-name "~/calibre/global.py.json")))))
     (when (file-exists-p global-py-json)
       (calibre--get-library-path-from-global-py-json global-py-json)))

   ;; if global.py exists, parse it for "library_path"
   (let ((global-py (calibre--get-first-existing-path
                     (list (expand-file-name "~/.config/calibre/global.py")
                           (expand-file-name "~/calibre/global.py")))))
     (when (file-exists-p global-py)
       (calibre--get-library-path-from-global-py global-py)))

   ;; look for default candidates
   (calibre--get-first-existing-path
    (list
     (when (getenv "UserProfile")
       (concat (file-name-as-directory (getenv "UserProfile"))
               calibre--calibre-library-name))
     (expand-file-name (concat "~/"
                               calibre--calibre-library-name))))))


(defvar calibre--latest-selected-item nil)

(defvar calibre-root-dir (calibre--find-library-filepath))

(defvar calibre-db
  (or
   (getenv "CALIBRE_OVERRIDE_DATABASE_PATH")
   (concat (file-name-as-directory
            calibre-root-dir) "metadata.db")))

(defvar calibre-default-opener
  (cond ((eq system-type 'gnu/linux)
         ;; HACK!
         ;; "xdg-open"
         ;; ... but xdg-open doesn't seem work as expected! (process finishes but program doesn't launch)
         ;; appears to be related to http://lists.gnu.org/archive/html/emacs-devel/2009-07/msg00279.html
         ;; you're better off replacing it with your exact program...
         ;; here we run xdg-mime to figure it out for *pdf* only. So this is not general!
         (s-chomp
          (shell-command-to-string
           (concat
            "grep Exec "
            (first
             ;; attempt for more linux compat, ref
             ;; http://askubuntu.com/questions/159369/script-to-find-executable-based-on-extension-of-a-file
             ;; here we try to find the location of the mimetype opener that xdg-mime refers to.
             ;; it works for okular (Exec=okular %U %i -caption "%c"). NO IDEA if it works for others!
             (delq nil (let ((mime-appname (s-chomp
                                            (replace-regexp-in-string
                                             "kde4-" "kde4/"
                                             (shell-command-to-string "xdg-mime query default application/pdf")))))

                         (mapcar
                          #'(lambda (dir) (let ((outdir (concat dir "/" mime-appname))) (if (file-exists-p outdir) outdir)))
                          '("~/.local/share/applications" "/usr/local/share/applications" "/usr/share/applications")))))
            "|head -1|awk '{print $1}'|cut -d '=' -f 2"))))
        ((eq system-type 'windows-nt)
         ;; based on
         ;; http://stackoverflow.com/questions/501290/windows-equivalent-of-the-mac-os-x-open-command
         ;; but no idea if it actually works
         "start")
        ((eq system-type 'darwin)
         "open")
        (t (message "unknown system!?"))))

;; TODO: consolidate default-opener with dispatcher
(defun calibre-open-with-default-opener (filepath)
  (if (eq system-type 'windows-nt)
      (start-process "shell-process" "*Messages*"
                     "cmd.exe" "/c" filepath)
    (start-process "shell-process" "*Messages*"
                   calibre-default-opener filepath)))

;; CREATE TABLE pdftext ( filepath CHAR(255) PRIMARY KEY, content TEXT );
;; (defvar calibre-text-cache-db (expand-file-name "~/Documents/pdftextcache.db"))
;; (defun calibre-get-cached-pdf-text (pdf-filepath)
;;   (let ((found-text (shell-command-to-string
;;                      (format "%s -separator '\t' '%s' 'SELECT content FROM pdftext WHERE filepath = '%s'" sql-sqlite-program calibre-text-cache-db pdf-filepath))))
;;     (if (< 0 (length found-text))
;;         found-text
;;       (let ((text-extract (shell-command-to-string
;;                            (format "pdftotext '%s' -" pdf-filepath))))
;;         (message "supposed to insert this!")
;;         ))))


;; (shell-command-to-string
;;  (format "%s -separator '\t' '%s' '%s'" sql-sqlite-program calibre-db ".schema books"))

(defun calibre-query (sql-query)
  (interactive (list (read-string-hist "calibre-query: ")))
  (esqlite-read calibre-db sql-query))

(defun calibre-record-to-alist (record)
  "converts esqlite query output like
  ((\"1\" \"a\" \"b\")
   (\"2\" \"c\" \"d\"))
  to alist based on column position"
  `((:id                     ,(nth 0 record))
    (:author-sort            ,(nth 1 record))
    (:book-dir               ,(nth 2 record))
    (:book-name              ,(nth 3 record))
    (:book-format  ,(downcase (nth 4 record)))
    (:book-pubdate           ,(nth 5 record))
    (:book-title             ,(nth 6 record))
    (:file-path    ,(concat (file-name-as-directory calibre-root-dir)
                            (file-name-as-directory (nth 2 record))
                            (nth 3 record) "." (downcase (nth 4 record))))))

(defun calibre-build-default-query (whereclause &optional limit)
  (concat "SELECT "
          "b.id, b.author_sort, b.path, d.name, d.format, b.pubdate, b.title"
          " FROM data AS d "
          "LEFT OUTER JOIN books AS b ON d.book = b.id "
          whereclause
          (when limit
            (format "LIMIT %s" limit))))

(defun calibre-query-by-field (wherefield argstring)
  (concat "WHERE lower(" wherefield ") LIKE '%%"
          (format "%s" (downcase argstring))
          "%%'"))

(defun calibre-read-query-filter-command ()
  (interactive)
  (let* ((default-string (if mark-active (s-trim (buffer-substring (mark) (point)))))
         ;; prompt &optional initial keymap read history default
         (search-string (read-string (format "Search Calibre for%s: "
                                             (if default-string
                                                 (concat " [" default-string "]")
                                               "")) nil nil default-string))
         (spl-arg (split-string search-string ":")))
    (if (and (< 1 (length spl-arg))
             (= 1 (length (first spl-arg))))
        (let* ((command (downcase (first spl-arg)))
               (argstring (second spl-arg))
               (wherefield
                (cond ((string= "a" (substring command 0 1))
                       "b.author_sort")
                      ((string= "t" (substring command 0 1))
                       "b.title")
                      )))
          (calibre-query-by-field wherefield argstring))
      (format "WHERE lower(b.author_sort) LIKE '%%%s%%' OR lower(b.title) LIKE '%%%s%%'"
              (downcase search-string) (downcase search-string)))))

(defun calibre-list ()
  (interactive)
  (message "%s"
           (mapconcat
            (lambda (rec)
              (format "%s" (car rec)))
            (calibre-query
             (concat "SELECT b.path FROM books AS b "
                     (calibre-read-query-filter-command)))
            "\n")))

(defun calibre-get-cached-pdf-text (pdf-filepath)
  (let ((found-text (shell-command-to-string
                     (format "%s -separator '\t' '%s' 'SELECT content FROM pdftext WHERE filepath = '%s'" sql-sqlite-program calibre-text-cache-db pdf-filepath))))
    (if (< 0 (length found-text))
        found-text
      (let ((text-extract (shell-command-to-string
                           (format "pdftotext '%s' -" pdf-filepath))))
        (message "supposed to insert this!")
        ))))

(defun calibre-open-citekey ()
  (interactive)
  (if (word-at-point)
      (let ((where-string
             (replace-regexp-in-string
              ;; capture all up to optional "etal" into group \1
              ;; capture 4 digits of date          into group \2
              ;; capture first word in title       into group \3
              "\\b\\([^ :;,.]+?\\)\\(?:etal\\)?\\([[:digit:]]\\\{4\\\}\\)\\(.*?\\)\\b"
              "WHERE lower(b.author_sort) LIKE '%\\1%' AND lower(b.title) LIKE '\\3%' AND b.pubdate >= '\\2-01-01' AND b.pubdate <= '\\2-12-31' LIMIT 1" (word-at-point))))
        (mark-word)
        (calibre-find (calibre-build-default-query where-string)))
    (message "nothing at point!")))

(defun getattr (my-alist key)
  (cadr (assoc key my-alist)))

(defun calibre-make-citekey (calibre-res-alist)
  "return some kind of a unique citation key for BibTeX use"
  (let* ((stopword-list '("the" "on" "a"))
         (spl (split-string (s-trim (getattr calibre-res-alist :author-sort)) "&"))
         (first-author-lastname (first (split-string (first spl) ",")))
         (first-useful-word-in-title
          ;; ref fitlering in http://www.emacswiki.org/emacs/ElispCookbook#toc39
          (first (delq nil
                  (mapcar
                   (lambda (token) (if (member token stopword-list) nil token))
                   (split-string (downcase (getattr calibre-res-alist :book-title)) " "))))))
    (concat
     (downcase (replace-regexp-in-string  "\\W" "" first-author-lastname))
     (if (< 1 (length spl)) "etal" "")
     (substring (getattr calibre-res-alist :book-pubdate) 0 4)
     (downcase (replace-regexp-in-string  "\\W.*" "" first-useful-word-in-title)))))

(defun mark-aware-copy-insert (content)
  "copy to clipboard if mark active, else insert"
  (if mark-active
      (progn (kill-new content)
             (deactivate-mark))
    (insert content)))

(defhydra calibre-handle-book-information (:hint nil :exit t)
  "
Choose value:

_i_ values in the book's `Ids` field (ISBN, DOI...)
_d_ publication date
_a_ author list

_q_ quit
"
  ("i" (lambda ()
         (interactive)
         (mark-aware-copy-insert
          (mapconcat
           (lambda (rec)
             (format "%s %s" (car rec) (cadr rec)))
           (calibre-query
            (concat "SELECT "
                    "idf.type, idf.val "
                    "FROM identifiers AS idf "
                    (format "WHERE book = %s" (getattr calibre--latest-selected-item :id))))
           "\n"))))
  ("d" (lambda ()
         (interactive)
         (mark-aware-copy-insert
          (substring (getattr calibre--latest-selected-item :book-pubdate) 0 10))))
  ("a" (lambda ()
         (interactive)
         (mark-aware-copy-insert
          (getattr calibre--latest-selected-item :author-sort))))
  ("q" nil))

(defhydra calibre-handle-entry (:hint nil :color blue)
  "conditional depending on mark"
  ("o"
   (lambda ()
     (interactive)
     (find-file-other-window (getattr calibre--latest-selected-item :file-path))))
  ("O"
   (lambda ()
     (interactive)
     (find-file-other-frame (getattr calibre--latest-selected-item :file-path))))
  ("v"
   (lambda ()
     (interactive)
     (calibre-open-with-default-opener (getattr calibre--latest-selected-item :file-path))))
  ("x"
   (lambda ()
     (interactive)
     (start-process "xournal-process" "*Messages*" "xournal"
                    (let ((xoj-file-path (concat calibre-root-dir "/"
                                                 (getattr calibre--latest-selected-item :book-dir)
                                                 "/"
                                                 (getattr res :book-name)
                                                 ".xoj")))
                      (if (file-exists-p xoj-file-path)
                          xoj-file-path
                        (getattr res :file-path))))))

  ("s"
   (lambda ()
     (interactive)
     (mark-aware-copy-insert
      (concat "title:\"" (getattr calibre--latest-selected-item :book-title) "\""))))
  ("c"
   (lambda ()
     (interactive)
     (mark-aware-copy-insert (calibre-make-citekey calibre--latest-selected-item))))
  ("i" (calibre-handle-book-information/body))

  ("p"
   (lambda ()
     (interactive)
     (mark-aware-copy-insert (getattr calibre--latest-selected-item :file-path))))
  ("t"
   (lambda ()
     (interactive)
     (mark-aware-copy-insert (getattr calibre--latest-selected-item :book-title))))
  ("g"
   (lambda ()
     (interactive)
     (insert (format "[[%s][%s]]"
                     (getattr calibre--latest-selected-item :file-path)
                     (concat (getattr calibre--latest-selected-item :author-sort)
                             ", "
                             (getattr calibre--latest-selected-item :book-title))))))
  ("j"
   (lambda ()
     (interactive)
     (mark-aware-copy-insert (json-encode calibre--latest-selected-item))))
  ("X"
   (lambda ()
     (interactive)

     (let* ((citekey (calibre-make-citekey calibre--latest-selected-item)))
       (let* ((pdftotext-out-buffer
               (get-buffer-create
                (format "pdftotext-extract-%s" (getattr calibre--latest-selected-item :id)))))
         (set-buffer pdftotext-out-buffer)
         (insert (shell-command-to-string (concat "pdftotext '"
                                                  (getattr calibre--latest-selected-item :file-path)
                                                  "' -")))
         (switch-to-buffer-other-window pdftotext-out-buffer)
         (beginning-of-buffer)))))
  ("q" nil :color red))

;; sets up dynamic hydra hinting based on whether the mark is active
(setq calibre-handle-entry/hint

      ;; note the leading newline is CRUCIAL for hydra--format to work!
      (let ((hint-template "\n(%s) [%s] found; choose action:

^Insert^                           ^Open with^

_s_: calibre search string         _o_: current frame
_c_: cite key                      _O_: other frame
_p_: file path                     _v_: default viewer
_g_: org link                      _x_: xournal
_j_: entry json                    _X_: pdftotext output
_t_: title
_i_: book information (contd menu)

_q_: quit"))
        `(eval
          (hydra--format nil nil
                         (format
                          (if mark-active
                              (prog1 (replace-regexp-in-string
                                      "\\^Insert\\^           "
                                      "^Copy to clipboard^"
                                      ,hint-template))
                            ,hint-template)
                          (getattr calibre--latest-selected-item :book-format)
                          (getattr calibre--latest-selected-item :book-name))
                         calibre-handle-entry/heads))))

(defun calibre-file-interaction-menu (calibre-item)
  (if (file-exists-p (getattr calibre-item :file-path))
      (progn
        (setq calibre--latest-selected-item calibre-item)
        (calibre-handle-entry/body))
    (message "didn't find that file")))

(defun calibre--make-book-alist
    (id book-title author-sort book-format)
  `((:id ,id)
    (:book-title ,book-title)
    (:author-sort ,author-sort)
    (:book-format ,book-format)))

(defun calibre--make-item-selectable-string
    (book-alist)
  (format
   "(%s) [%s] %s -- %s"
   (getattr book-alist :id)
   (getattr book-alist :book-format)
   (getattr book-alist :author-sort)
   (getattr book-alist :book-title)))

(if (featurep 'ivy)

    (defun calibre-format-selector-menu (calibre-item-list)
      (ivy-read "Pick a book"
                (let (display-alist)
                  (dolist (item calibre-item-list display-alist)
                    (setq
                     display-alist
                     (cons
                      (list (calibre--make-item-selectable-string item)
                            item)
                      display-alist))))
                :action (lambda (item)
                          (calibre-file-interaction-menu (cadr item)))))

  (defun calibre-format-selector-menu (calibre-item-list)
    (let ((chosen-item
           (completing-read "Pick book: "
                            (mapcar 'calibre--make-item-selectable-string
                                    calibre-item-list)
                            nil t)))
      (calibre-file-interaction-menu
       (find-if (lambda (item)
                  (equal chosen-item
                         (calibre--make-item-selectable-string item)))
                calibre-item-list)))))



(defun calibre-find (&optional custom-query)
  (interactive)
  (let* ((sql-query (if custom-query
                        custom-query
                      (calibre-build-default-query (calibre-read-query-filter-command))))
         (results (calibre-query sql-query)))
    (if (= 0 (length results))
        (progn
          (message "nothing found.")
          (deactivate-mark))
      (let ((res-list (mapcar 'calibre-record-to-alist results)))
        (if (= 1 (length res-list))
            (calibre-file-interaction-menu (car res-list))
          (calibre-format-selector-menu res-list))))))

(global-set-key "\C-cK" 'calibre-open-citekey)

;; ORG MODE INTERACTION
(org-add-link-type "calibre" 'org-calibre-open 'org-calibre-link-export)

(defun org-calibre-open (org-link-text)
  ;; TODO: implement link parsers; assume default is title, e.g.
  ;; [[calibre:Quick Start Guide]]
  ;; will need to handle author shibori
  (calibre-find
   (calibre-build-default-query
    (calibre-query-by-field "b.title" org-link-text))))

(defun org-calibre-link-export (link description format)
  "FIXME: stub function"
  (concat "link in calibre: " link " (" description ")"))

(provide 'calibre-query)
