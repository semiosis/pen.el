;;; ess-view-data.el --- View Data                   -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020  Shuguang Sun <shuguang79@qq.com>

;; Author: Shuguang Sun <shuguang79@qq.com>
;; Created: 2019/04/06
;; Version: 1.3
;; URL: https://github.com/ShuguangSun/ess-view-data
;; Package-Requires: ((emacs "26.1") (ess "18.10.1") (csv-mode "1.12"))
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Customization:
;; ess-view-data-backend-list: dplyr (default), dplyr+DT, data.table+magrittr
;; ess-view-data-print-backend-list: print (default), kable
;; ess-view-data-save-backend-list: write.csv (default), readr::write_csv,
;;                                  data.table::fwrite kable
;; ess-view-data-complete-backend-list: jsonlite
;; ess-view-data-read-string: ess-completing-read (default), completing-read,
;;                            ido-completing-read, ivy-completing-read

;; Utils:
;; NOTE: it will make a copy of the data and then does the following action
;; ess-view-data-print: the main function to view data

;; Example: In a ess-r buffer or a Rscript buffer, `M-x ess-view-data-print`
;; and input `mtcars`.

;; ess-view-data-set-backend: change backend
;; ess-view-data-toggle-maxprint: toggle limitation of lines per page to print

;; ess-view-data-verbs

;; Example: In the ESS-V buffer, `M-x ess-view-data-verbs` and select the verb
;; to do with.

;; ess-view-data-filter

;; Example: In the ESS-V buffer, `M-x ess-view-data-filter`, `cyl <RET> mpg` to
;; select columns and <C-j> to finish input.  An indirect buffer pops up and
;; 'data-masking' Expressions can be edited.

;; ess-view-data-select / ess-view-data-unselect

;; Example: In the ESS-V buffer, `M-x ess-view-data-select`, `cyl <RET> mpg` to
;; select columns and <C-j> to finish input.

;; ess-view-data-sort
;; ess-view-data-group / ess-view-data-ungroup
;; ess-view-data-mutate
;; ess-view-data-slice
;; ess-view-data-wide2long / ess-view-data-long2wide
;; ess-view-data-update
;; ess-view-data-reset

;; Example: In the ESS-V buffer, `M-x ess-view-data-reset`, an indirect buffer
;; pops up and the action history can be edited.

;; ess-view-data-unique
;; ess-view-data-count

;; Example: In the ESS-V buffer, `M-x ess-view-data-count`, `cyl <RET> mpg` to
;; select columns and <C-j> to finish input.  In the updated buffer with count
;; information, `M-x ess-view-data-print` to go back.

;; ess-view-data-summarise
;; ess-view-data-overview
;; ess-view-data-goto-page / -next-page / -preious-page / -first-page /
;;                           -last-page / -page-number
;; ess-view-data-save

;;; Code:

;; (require 'eieio)

(eval-when-compile (require 'cl-lib))
(eval-when-compile (require 'cl-generic))

(require 'ess-inf)
(require 'ess-rdired)
(require 'ess-r-mode)
(require 'ess-r-completion)
(require 'subr-x)
(require 'json)

(defgroup ess-view-data ()
  "ess-view-dat"
  :group 'ess
  :prefix "ess-view-data-")

(defcustom ess-view-data-buffer-name-format "*R Data View: %1$s (%2$s)*"
  "Buffer name for R data, with two parameter: variable name, proc-name."
  :type 'string
  :group 'ess-view-data)

(defcustom ess-view-data-source-buffer-name-format "*R Data View Edit: %s*"
  "Buffer for R data."
  :type 'string
  :group 'ess-view-data)

;; FIXME: r symbol name
(defcustom ess-view-data-objname-regex "^[^a-zA-Z]\\|[^.a-zA-Z0-9]+"
  "Object name needs to be back quoted."
  :type 'string
  :group 'ess-view-data)

(defcustom ess-view-data-options-width 5000
  "Width to print data: options(width= `ess-view-data-options-width')."
  :type 'integer
  :group 'ess-view-data)

(defcustom ess-view-data-rows-per-page 200
  "Rows per page."
  :type 'integer
  :group 'ess-view-data)

(defcustom ess-view-data-show-code t
  "Show code on top of the view data buffer."
  :type 'boolean
  :group 'ess-view-data)

(defcustom ess-view-data-show-no-page-number t
  "Not to show page number on top of the view data buffer."
  :type 'boolean
  :group 'ess-view-data)

(defcustom ess-view-data-write-dribble t
  "Write to dribble for tracking."
  :type 'boolean
  :group 'ess-view-data)

(defcustom ess-view-data-tibble-crayon-enabled-p nil
  "Whether to enable crayon for tibble.

If enabled, `ansi-color-for-comint-mode-on' should be turn on."
  :type 'boolean
  :group 'ess-view-data)


(defvar ess-view-data-backend-list
  (list 'dplyr 'dplyr+DT 'data.table+magrittr)
  "List of backends.")

(defcustom ess-view-data-current-backend 'dplyr
  "The ess-view-data backend in using."
  :type `(choice ,@(mapcar (lambda (x)
			                 `(const :tag ,(symbol-name x) ,x))
			               ess-view-data-backend-list)
                 (symbol :tag "Other"))
  :group 'ess-view-data)


(defvar ess-view-data-print-backend-list
  (list 'print 'kable)
  "List of backends.")


(defcustom ess-view-data-current-update-print-backend 'print
  "The ess-view-data backend in using."
  :type `(choice ,@(mapcar (lambda (x)
			                 `(const :tag ,(symbol-name x) ,x))
			               ess-view-data-print-backend-list)
                 (symbol :tag "Other"))
  :group 'ess-view-data)

(defcustom ess-view-data-current-summarize-print-backend 'kable
  "The ess-view-data backend in using."
  :type `(choice ,@(mapcar (lambda (x)
			                 `(const :tag ,(symbol-name x) ,x))
			               ess-view-data-print-backend-list)
                 (symbol :tag "Other"))
  :group 'ess-view-data)


(defvar ess-view-data-save-backend-list
  (list 'write.csv 'readr::write_csv 'data.table::fwrite 'kable)
  "List of backends for write data to csv.")

(defcustom ess-view-data-current-save-backend 'write.csv
  "The backend to save data."
  :type `(choice ,@(mapcar (lambda (x)
			                 `(const :tag ,(symbol-name x) ,x))
			               ess-view-data-save-backend-list)
                 (symbol :tag "Other"))
  :group 'ess-view-data)

(defvar ess-view-data-complete-backend-list
  (list 'jsonlite)
  "List of backends to read completion list.")

(defcustom ess-view-data-current-complete-backend 'jsonlite
  "The backend to save data."
  :type `(choice ,@(mapcar (lambda (x)
			                 `(const :tag ,(symbol-name x) ,x))
			               ess-view-data-complete-backend-list)
                 (symbol :tag "Other"))
  :group 'ess-view-data)


(defcustom ess-view-data-read-string 'ess-completing-read
  "The function used to completing read."
  :type `(choice (const :tag "ESS" ess-completing-read)
                 (const :tag "basic" completing-read)
                 (const :tag "ido" ido-completing-read)
                 (const :tag "ivy" ivy-completing-read)
                 (function :tag "Other"))
  :group 'ess-view-data)


;; TODO: configure input functions here
(defvar ess-view-data-backend-setting
  '((dplyr . (:desc "desc(%s)" :slice "pos, like 1, 1:5, n(): "))
    (dplyr+DT . (:desc "desc(%s)" :slice "pos, like 1, 1:5, n(): "))
    (data.table+magrittr . (:desc "-%s" :slice "pos, like 1, 1:5, .N: ")))
  "List of backends.")

(defvar ess-view-data-verb-update-list
  (list "select" "unselect" "sort" "group" "ungroup" "slice")
  "List of verbs which can change the data.")

(defvar ess-view-data-verb-update-indirect-list
  (list "filter" "mutate" "transmute"
        "wide2long" "long2wide" "wide2long-pivot_longer" "long2wide-pivot_wider")
  "List of verbs which can change the data.")

(defvar ess-view-data-verb-summarise-list
  (list "count" "unique" "slice" "summarise" "skimr" "skimr-all")
  "List of verbs which do summarise.")

(defvar ess-view-data-verb-summarise-indirect-list
  (list "count" "unique" "slice" "summarise")
  "List of verbs which do summarise.")

(defvar-local ess-view-data-object nil
  "Cache of object name.")

(defvar-local ess-view-data-temp-object nil
  "Temporary varible for ess-view-data.")

(defvar ess-view-data-temp-object-list '()
  "List of temparory varible for ess-view-data.")

(defvar-local ess-view-data-maxprint-p nil
  "Whether to print all data in one page.")

(defvar-local ess-view-data-page-number 0
  "Current page number - 1.")

(defvar-local ess-view-data-total-page 1
  "Total page number.")


(defvar-local ess-view-data-history nil
  "The history of operations.")

(defvar-local ess-view-data-completion-object nil
  "The candidate for completion.")

(defvar-local ess-view-data-completion-candidate nil
  "The candidate for completion.")




(defvar ess-view-data-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "C-c C-p") #'ess-view-data-print-ex)
    (define-key keymap (kbd "C-c C-t") #'ess-view-data-toggle-maxprint)
    (define-key keymap (kbd "C-c C-s") #'ess-view-data-select)
    (define-key keymap (kbd "C-c C-u") #'ess-view-data-unselect)
    (define-key keymap (kbd "C-c C-f") #'ess-view-data-filter)
    (define-key keymap (kbd "C-c C-o") #'ess-view-data-sort)
    ;; (define-key keymap (kbd "C-c C-g") #'ess-view-data-group)
    ;; (define-key keymap (kbd "C-c C-G") #'ess-view-data-ungroup)
    (define-key keymap (kbd "C-c C-i") #'ess-view-data-slice)
    (define-key keymap (kbd "C-c C-l") #'ess-view-data-unique)
    (define-key keymap (kbd "C-c C-v") #'ess-view-data-summarise)
    (define-key keymap (kbd "C-c C-r") #'ess-view-data-reset)
    (define-key keymap (kbd "C-c C-w") #'ess-view-data-save)
    (define-key keymap (kbd "M-g p") #'ess-view-data-goto-previous-page)
    (define-key keymap (kbd "M-g n") #'ess-view-data-goto-next-page)
    (define-key keymap (kbd "M-g f") #'ess-view-data-goto-first-page)
    (define-key keymap (kbd "M-g l") #'ess-view-data-goto-last-page)
    keymap)
  "Keymap for function `ess-view-data-mode'.")

;;; Indirect Buffers Minor Mode
(defvar ess-view-data-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c'" #'ess-view-data-do-commit)
    (define-key map "\C-c\C-k" #'ess-view-data-commit-abort)
    (define-key map "\C-c\C-i" #'ess-view-data-complete-object)
    (define-key map "\C-c\C-l" #'ess-view-data-complete-data)
    (define-key map "\C-c\C-a" #'ess-view-data-insert-all-cols)
    (define-key map "\C-c\C-v" #'ess-view-data-insert-all-values)
    map)
  "Keymap for `ess-view-data-edit-mode', a minor mode.")

(defvar ess-view-data-edit-mode-hook nil
  "Hook for the `ess-view-data-edit-mode' minor mode.")

(define-minor-mode ess-view-data-edit-mode
  "Minor mode for special key bindings in a ess-view-data-edit buffer.

Turning on this mode runs the normal hook `ess-view-data-edit-mode-hook'."
  :lighter " Evd"
  (setq-local
   header-line-format
   (substitute-command-keys
    "Edit, then exit with `\\[ess-view-data-do-commit] '' or abort with `\\[ess-view-data-commit-abort]'")))

;;; Utils

;;; Backend Access API

(cl-defgeneric ess-view-data--do-print (backend str)
  "Benchmark function to do print.

Argument BACKEND Backend to dispatch, i.e.,
the `ess-view-data-current-update-print-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data--do-update (backend str)
  "Do Update.

Argument BACKEND Backend to dispatch, i.e., the `ess-view-data-current-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data--do-summarise (backend str)
  "Do summarising.

Argument BACKEND Backend to dispatch, i.e., the `ess-view-data-current-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data--create-indirect-buffer (backend str)
  "Create indirect-buffer for editting.

Argument BACKEND Backend to dispatch, i.e., the `ess-view-data-current-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data--do-reset (backend str)
  "Reset print buffer.

Argument BACKEND Backend to dispatch, i.e., the `ess-view-data-current-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data-do-save (backend str)
  "Save.

Argument BACKEND Backend to dispatch, i.e., the `ess-view-data-current-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data-do-complete-data (backend str)
  "Completing input.

Argument BACKEND Backend to dispatch, i.e.,
the `ess-view-data-current-complete-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data-get-total-page (backend str)
  "Total number of pages.

Argument BACKEND Backend to dispatch, i.e., the `ess-view-data-current-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data--header-line (backend str)
  "Head-line.

Argument BACKEND Backend to dispatch, i.e., the `ess-view-data-current-backend'.
Argument STR R script to run.")

(cl-defgeneric ess-view-data--initialize-backend (_backend)
  "Initialization."
  nil)

(cl-defgeneric ess-view-data-do-kill-buffer-hook (backend str)
  "Functions to run after `kill-buffer' on '*R Data View' buffer.

Argument BACKEND Backend to dispatch, i.e., the `ess-view-data-current-backend'.
Argument STR R script to run.")

;;; * print-backend: print
(defvar ess-view-data--print-format
  (concat
   (format
    (concat
     "op.tmp <- options(\"width\", \"tibble.width\", \"crayon.enabled\");"
     "options(tibble.width = Inf, width = %d, crayon.enabled = FALSE);")
    ess-view-data-options-width)
   "print(%s, n = nrow(%s));"
   "options(op.tmp)")
  "Format string for print.")

(defvar ess-view-data--print-format-with-crayon
  (concat
   (format
    (concat
     "op.tmp <- options(\"width\", \"tibble.width\", \"crayon.enabled\");"
     "options(tibble.width = Inf, width = %d, crayon.enabled = TRUE);")
    ess-view-data-options-width)
   "print(%s, n = nrow(%s));"
   "options(op.tmp)")
  "Format string for print, with crayon.enabled for tibble.")

(cl-defmethod ess-view-data--do-print ((_backend (eql print)))
  "Do print using print."
  (if ess-view-data-tibble-crayon-enabled-p
      ess-view-data--print-format-with-crayon
    ess-view-data--print-format))

;;; * kable-backend: kable
(defvar ess-view-data--kable-format
  (concat
   (format
    (concat
     "op.tmp <- options(\"width\", \"tibble.width\", \"crayon.enabled\");"
     "options(tibble.width = Inf, width = %d, crayon.enabled = FALSE);")
    ess-view-data-options-width)
   "print(knitr::kable(%s, n = nrow(%s)));"
   "options(op.tmp)")
  "Format string for kable.")

(cl-defmethod ess-view-data--do-print ((_backend (eql kable)))
  "Do print using kable."
  ess-view-data--kable-format)


;;; * backend: dplyr

;;; ** Initialization
(cl-defmethod ess-view-data--initialize-backend ((_backend (eql dplyr)) proc-name proc)
  "Initialization.

Initializing the history of operations, make temp object.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
  (let ((obj-space-p (string-match-p ess-view-data-objname-regex ess-view-data-object))
        (obj-back-quote-p (string-match-p "`" ess-view-data-object))
        (obj-back-quote (replace-regexp-in-string "`" "" ess-view-data-object)))
  (unless ess-view-data-history
    (setq ess-view-data-history
          (format (cond (obj-back-quote-p "as_tibble(%s)")
                        (obj-space-p "as_tibble(`%s`)")
                        (t "as_tibble(%s)"))
                  ess-view-data-object)))
  ;; Initializing the temparory object, for stepwise
  (unless ess-view-data-temp-object
    (setq ess-view-data-temp-object
          (format (cond (obj-back-quote-p "`%s`")
                        (obj-space-p "`%s`")
                        (t "`%s`"))
                  (make-temp-name obj-back-quote)))
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (ess-command (concat "{suppressPackageStartupMessages(require(dplyr)); "
                           ;; ess-command using local 2021-12-04
                           ess-view-data-temp-object " <<- as_tibble("
                           (format (cond (obj-back-quote-p "`%s`")
                                         (obj-space-p "`%s`")
                                         (t "`%s`"))
                                   obj-back-quote)
                           ")}\n")
                   nil nil nil nil proc))))
  (cl-pushnew ess-view-data-temp-object ess-view-data-temp-object-list)
  (delete-dups ess-view-data-temp-object-list))


;; (defvar csv--header-line)
(defvar-local csv--header-line nil)
(declare-function csv-header-line "csv-mode")

(cl-defmethod ess-view-data--header-line ((_backend (eql dplyr)))
  "Make header-line for dplyr."
  (goto-char (point-min))
  ;; (if (looking-at "# A tibble:")
  ;;     (delete-region (point-min) (1+ (line-end-position))))
  (let ((lin 1))
    (while ;; (looking-at-p "^\\(+\\|#\\)")
        (search-forward-regexp "^\\([+]\\|#\\|[[].+?#\\)" nil t)
      (forward-line)
      (setq lin (1+ lin)))
    (unless (fboundp 'csv-header-line) (require 'csv-mode nil t))
    (when (fboundp 'csv-header-line)
      (setq csv--header-line nil)
      (with-no-warnings (csv-header-line lin))))
  (goto-char (point-min)))

(cl-defmethod ess-view-data-get-total-page ((_backend (eql dplyr)) proc-name proc)
  "Get total number of pages of the current object (data.frame/tibble/data.table).

If `ess-view-data-maxprint-p' is nil, it will show 100 rows/lines
per page for dplyr+print/kable.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (setq ess-view-data-total-page
            (string-to-number
             (car (ess-get-words-from-vector
                   (format "as.character(nrow(%s))\n" ess-view-data-temp-object)))))
      (setq ess-view-data-total-page
            (1+ (floor (/ ess-view-data-total-page ess-view-data-rows-per-page))))))



(cl-defmethod ess-view-data-do-kill-buffer-hook ((_backend (eql dplyr)) proc-name proc)
  "Functions to run after `kill-buffer' on '*R Data View' buffer.

The default is to rm the temparory object.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (ess-command (format "rm(%s, envir = globalenv())\n" ess-view-data-temp-object))
      (ess-write-to-dribble-buffer (format "[ESS-v] rm(%s, envir = globalenv())\n" ess-view-data-temp-object))))


;;; ** Utilities
(cl-defmethod ess-view-data--do-update ((_backend (eql dplyr)) fun action)
  "Update the data frame by dplyr stepwisely.

Optional argument FUN What to do with the data, e.g.,
verb like select, filter, and etc..
Optional argument ACTION Parameter (R script) for FUN, e.g., columns for select."
  (let (cmdhist cmd result)
    (setq cmdhist
          (pcase fun
            ('select
             (format " %%>%% dplyr::select(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('filter
             (format " %%>%% dplyr::filter(%s)" action))
            ('mutate
             (format " %%>%% dplyr::mutate(%s)" action))
            ('sort
             (format " %%>%% dplyr::arrange(%s, .by_group = TRUE)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('group
             (format " %%>%% dplyr::group_by(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('ungroup
             (format " %%>%% dplyr::ungroup(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('transmute
             (format " %%>%% dplyr::transmute(%s)" action))
            ('wide2long
             (format " %%>%% tidyr::gather(%s)" action))
            ('long2wide
             (format " %%>%% tidyr::spread(%s)" action))
            ('wide2long-pivot_longer
             (format " %%>%% tidyr::pivot_longer(%s)" action))
            ('long2wide-pivot_wider
             (format " %%>%% tidyr::pivot_wider(%s)" action))
            ('slice
             (format " %%>%% dplyr::slice(%s)" action))
            ('unselect
             (format " %%>%% dplyr::select(%s)"
                     (mapconcat (lambda (x) (concat "-" x))
                                (delete-dups (nreverse action)) ",")))
            (_
             (format " %%>%% %s" action))))

    (setq ess-view-data-page-number 0)
    (setq cmd (concat
               ess-view-data-temp-object " <<- " ess-view-data-temp-object cmdhist "; "
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-update-print-backend)
                       (concat ess-view-data-temp-object
                               (unless ess-view-data-maxprint-p
                                 (format "[(%1$d*%2$d + 1) : min((%1$d + 1)*%2$d, nrow(%s)),]"
                                         ess-view-data-page-number
                                         ess-view-data-rows-per-page
                                         ess-view-data-temp-object)))
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))


(cl-defmethod ess-view-data--do-summarise ((_backend (eql dplyr)) fun action)
  "Do summarising by dplyr stepwisely, without modfiy the data frame.

Optional argument FUN What to do with the data, e.g.,
verb like count, unique, and etc..
Optional argument ACTION Parameter (R script) for FUN, e.g., columns for count."
  (let (cmdhist cmd result)
    (setq cmdhist
          (pcase fun
            ('count
             (format " %%>%% dplyr::count(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('unique
             (format " %%>%% dplyr::distinct(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('slice
             (format " %%>%% dplyr::slice(%s)" action))
            ('skimr
             (format " %%>%% skimr::skim(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('skimr-all
             " %>% skimr::skim()")
            ;; ('summarise
            ;;  (format " %%>%% dplyr::summarise(%s)" action))
            (_
             (format " %%>%% %s" action))))

    (setq cmd (concat
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-summarize-print-backend)
                       (concat ess-view-data-temp-object cmdhist)
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))

(cl-defmethod ess-view-data--do-reset ((_backend (eql dplyr)) action)
  "Update the data frame by dplyr stepwisely.

Optional argument ACTION R script to reset the view process,
which will become the cmd history."
  (let (cmdhist cmd result)
    (setq cmdhist action)
    (setq ess-view-data-page-number 0)
    (setq cmd (concat
               ess-view-data-temp-object " <<- " cmdhist "; "
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-update-print-backend)
                       (concat ess-view-data-temp-object
                               (unless ess-view-data-maxprint-p
                                 (format "[(%1$d*%2$d + 1) : min((%1$d + 1)*%2$d, nrow(%s)),]"
                                         ess-view-data-page-number
                                         ess-view-data-rows-per-page
                                         ess-view-data-temp-object)))
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))

(cl-defmethod ess-view-data-do-goto-page ((_backend (eql dplyr)) page &optional pnumber)
  "Goto PAGE.

Optional argument PNUMBER The page number to go to."
  (let (cmd result)
    (setq ess-view-data-page-number
          (pcase page
            ('first 0)
            ('last ess-view-data-total-page)
            ('previous (max 0 (1- ess-view-data-page-number)))
            ('next (min (1+ ess-view-data-page-number) ess-view-data-total-page))
            ('page (max (min pnumber ess-view-data-total-page) 0))
            (_ ess-view-data-page-number)))

    (setq cmd (concat
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-update-print-backend)
                       (concat ess-view-data-temp-object
                               (unless ess-view-data-maxprint-p
                                 (format "[(%1$d*%2$d + 1) : min((%1$d + 1)*%2$d, nrow(%s)),]"
                                         ess-view-data-page-number
                                         ess-view-data-rows-per-page
                                         ess-view-data-temp-object)))
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons nil cmd))
    result))

(defvar-local ess-view-data--parent-buffer nil)
(defvar-local ess-view-data--reset-buffer-p nil)
(defvar-local ess-view-data--action nil)
(defvar-local ess-local-process-name nil)

(cl-defmethod ess-view-data--create-indirect-buffer
  ((_backend (eql dplyr))
   type fun obj-list temp-object parent-buf proc-name)
  "Create an edit-indirect buffer and return it.

Optional argument TYPE Action type, e.g., update, reset, summarise.
Optional argument FUN Action function to do with data, e.g.,
select, count, and etc..
Optional argument OBJ-LIST Columns/variables to do with.
Optional argument TEMP-OBJECT Temporary data in the view process.
Optional argument PARENT-BUF The associated parent buffer for the view process.
Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'."
  (let ((buf (get-buffer-create (format ess-view-data-source-buffer-name-format temp-object)))
        pts)
    (with-current-buffer buf
      (ess-r-mode)
      (set-buffer-modified-p nil)
      (setq ess-view-data--parent-buffer parent-buf)
      (setq ess-view-data--reset-buffer-p t)
      (setq ess-view-data--action `((:type . ,type) (:function . ,fun)))
      ;; (print (alist-get :function ess-view-data--action))
      ;; (print (alist-get ':type ess-view-data--action))
      (insert "# Insert [all] variable name[s] (C-c C-i[a]), [all] Values (C-c C-l[v])\n")
      (insert "# Line started with `#' will be omited\n")
      (insert "# Don't comment code as all code will be wrapped in one line\n")
      (pcase fun
        ('filter
         (setq ess-view-data-completion-object (car obj-list))
         (insert "# dplyr::filter(...)\n")
         (setq pts (point))
         (insert (mapconcat (lambda (x) (propertize x 'evd-object x))
                            (delete-dups (nreverse obj-list)) ","))
         (goto-char pts))
        ('mutate
         (insert "# dplyr::mutate(...)\n")
         (setq pts (point))
         (insert (mapconcat (lambda (x) (format " = %s" (propertize x 'evd-object x)))
                            (delete-dups (nreverse obj-list)) ","))
         (goto-char pts))
        ('wide2long
         (insert "# tidyr::gather(cols, ...)\n")
         (insert (format "key = %s, value = %s" (car obj-list) (nth 1 obj-list))))
        ('long2wide
         (insert "# tidyr::spread(key to clomn names)\n")
         (insert (format "key = %s, value = %s" (car obj-list) (nth 1 obj-list))))
        ('wide2long-pivot_longer
         (insert "# tidyr::pivot_longer(cols, names and values to)\n")
         (insert (format "c(), names_to = %s, values_to = %s" (car obj-list) (nth 1 obj-list))))
        ('long2wide-pivot_wider
         (insert "# tidyr::pivot_wider(names and values from)\n")
         (insert (format "names_from = %s, values_from = %s" (car obj-list) (nth 1 obj-list))))
        ;; ('summarise
        ;;  (insert "# %> ... \n# Not limited to function summarise\n")
        ;;  (insert (mapconcat (lambda (x) (format "%s" (propertize x 'evd-object x)))
        ;;                     (delete-dups (nreverse obj-list)) ","))
        ('summarise
         (insert "# %> ... \n# Not limited to function summarise\n")
         ;; (insert (format "summarise(mean = mean(%s, na.rm = TRUE), n = n())" obj-list))
         (insert "summarise(")
         (insert (mapconcat (lambda (x) (format "%s" (propertize x 'evd-object x)))
                            (delete-dups (nreverse obj-list)) ","))
         (insert ", n = n())"))
        ('reset
         (insert "# reset\n")
         (insert obj-list))
        (_
         (insert "# %> ... \n")
         (setq pts (point))
         (insert (mapconcat 'identity (delete-dups (nreverse obj-list)) ","))
         (goto-char pts)))
      (setq ess-local-process-name proc-name)
      (setq ess-view-data-temp-object
            (buffer-local-value 'ess-view-data-temp-object parent-buf))
      (ess-view-data-edit-mode))
    (select-window (display-buffer buf))))


;;; * backend: dplyr+DT


(defcustom ess-view-data-DT-rows-per-page 1000
  "Rows per page for DT."
  :type 'integer
  :group 'ess-view-data)

(defcustom ess-view-data-cache-directory
  (expand-file-name (format "ess-view-data-%d" (user-uid))
		    temporary-file-directory)
  "The base directory, where the cache files (e.g., html files from DT)
will be saved."
  :type 'directory
  :group 'ess-view-data)



(defun ess-view-data-make-safe-dir (dir)
  "This is from `doc-view-make-safe-dir'.
Just to try create a temporary directory to cache the DT files.

Argument DIR name of temparory dir."
  (condition-case nil
      ;; Create temp files with strict access rights.  It's easy to
      ;; loosen them later, whereas it's impossible to close the
      ;; time-window of loose permissions otherwise.
      (with-file-modes #o0700 (make-directory dir))
    (file-already-exists
     (when (file-symlink-p dir)
       (error "Danger: %s points to a symbolic link" dir))
     ;; In case it was created earlier with looser rights.
     ;; We could check the mode info returned by file-attributes, but it's
     ;; a pain to parse and it may not tell you what we want under
     ;; non-standard file-systems.  So let's just say what we want and let
     ;; the underlying C code and file-system figure it out.
     ;; This also ends up checking a bunch of useful conditions: it makes
     ;; sure we have write-access to the directory and that we own it, thus
     ;; closing a bunch of security holes.
     (condition-case error
	 (set-file-modes dir #o0700)
       (file-error
	(error
	 (format "Unable to use temporary directory %s: %s"
		 dir (mapconcat #'identity (cdr error) " "))))))))


;;; ** Initialization
(cl-defmethod ess-view-data--initialize-backend ((_backend (eql dplyr+DT)) proc-name proc)
  "Initialization.

Initializing the history of operations, make temp object.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
  (let ((obj-space-p (string-match-p ess-view-data-objname-regex ess-view-data-object))
        (obj-back-quote-p (string-match-p "`" ess-view-data-object))
        (obj-back-quote (replace-regexp-in-string "`" "" ess-view-data-object)))
  (unless ess-view-data-history
    (setq ess-view-data-history
          (format (cond (obj-back-quote-p "as_tibble(%s)")
                        (obj-space-p "as_tibble(`%s`)")
                        (t "as_tibble(%s)"))
                  ess-view-data-object)))
  ;; Initializing the temparory object, for stepwise
  (unless ess-view-data-temp-object
    (setq ess-view-data-temp-object
          (format (cond (obj-back-quote-p "`%s`")
                        (obj-space-p "`%s`")
                        (t "`%s`"))
                  (make-temp-name obj-back-quote)))
    (ess-view-data-make-safe-dir ess-view-data-cache-directory)
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (ess-command (concat "{suppressPackageStartupMessages(require(dplyr));"
                           "suppressPackageStartupMessages(require(DT)); "
                           ess-view-data-temp-object " <<- as_tibble("
                           (format (cond (obj-back-quote-p "`%s`")
                                         (obj-space-p "`%s`")
                                         (t "`%s`"))
                                   obj-back-quote)
                           ")}\n")
                   nil nil nil nil proc))))
  (cl-pushnew ess-view-data-temp-object ess-view-data-temp-object-list)
  (delete-dups ess-view-data-temp-object-list))


(cl-defmethod ess-view-data--header-line ((_backend (eql dplyr+DT)))
  "Make header-line for dplyr+DT."
  (goto-char (point-min))
  (browse-url (format "%s/%s.html" ess-view-data-cache-directory
                      (replace-regexp-in-string "`" "" ess-view-data-temp-object))))


(cl-defmethod ess-view-data-get-total-page ((_backend (eql dplyr+DT)) proc-name proc)
  "Get the total number of pages.

Get total number of pages of the current object (data.frame/tibble/data.table).

If `ess-view-data-maxprint-p' is nil, it will show 1000 rows/lines per page
for DT.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
  (when (and proc-name proc
             (not (process-get proc 'busy)))
    (setq ess-view-data-total-page
          (string-to-number
           (car (ess-get-words-from-vector
                 (format "as.character(nrow(%s))\n" ess-view-data-temp-object)))))
    (setq ess-view-data-total-page
          (1+ (floor (/ ess-view-data-total-page ess-view-data-rows-per-page))))))

(cl-defmethod ess-view-data-do-kill-buffer-hook ((_backend (eql dplyr+DT)) proc-name proc)
  "Functions to run after `kill-buffer' on '*R Data View' buffer.

The default is to rm the temparory object.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (ess-command (format "rm(%s, envir = globalenv())\n" ess-view-data-temp-object))
      (ess-write-to-dribble-buffer (format "[ESS-v] rm(%s, envir = globalenv())\n" ess-view-data-temp-object))))

;;; ** Utilities
(cl-defmethod ess-view-data--do-update ((_backend (eql dplyr+DT)) fun action)
  "Update the data frame by dplyr stepwisely.

Optional argument FUN what to do, e.g. select, filter, etc..
Optional argument ACTION parameters to the FUN."
  (let (cmdhist cmd result)
    (setq cmdhist
          (pcase fun
            ('select
             (format " %%>%% dplyr::select(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('filter
             (format " %%>%% dplyr::filter(%s)" action))
            ('mutate
             (format " %%>%% dplyr::mutate(%s)" action))
            ('sort
             (format " %%>%% dplyr::arrange(%s, .by_group = TRUE)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('group
             (format " %%>%% dplyr::group_by(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('ungroup
             (format " %%>%% dplyr::ungroup(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('transmute
             (format " %%>%% dplyr::transmute(%s)" action))
            ('wide2long
             (format " %%>%% tidyr::gather(%s)" action))
            ('long2wide
             (format " %%>%% tidyr::spread(%s)" action))
            ('wide2long-pivot_longer
             (format " %%>%% tidyr::pivot_longer(%s)" action))
            ('long2wide-pivot_wider
             (format " %%>%% tidyr::pivot_wider(%s)" action))
            ('slice
             (format " %%>%% dplyr::slice(%s)" action))
            ('unselect
             (format " %%>%% dplyr::select(%s)"
                     (mapconcat (lambda (x) (concat "-" x))
                                (delete-dups (nreverse action)) ",")))
            (_
             (format " %%>%% %s" action))))

    (setq ess-view-data-page-number 0)
    (setq cmd (concat
               ess-view-data-temp-object " <<- " ess-view-data-temp-object cmdhist "; "
               "local({"
               (format "DT::saveWidget(datatable(%1$s, filter = 'top' %2$s), file = '%3$s/%4$s.html')\n"
                       ess-view-data-temp-object
                       (if ess-view-data-maxprint-p
                           (format ", options = list(autoWidth = FALSE,pageLength = %d)"
                                   ess-view-data-DT-rows-per-page)
                         (format ", options = list(lengthMenu = c(10,50,100,%d))" ess-view-data-DT-rows-per-page))
                       ess-view-data-cache-directory
                       (replace-regexp-in-string "`" "" ess-view-data-temp-object))
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))


(cl-defmethod ess-view-data--do-summarise ((_backend (eql dplyr+DT)) fun action)
  "Do summarising by dplyr stepwisely, without modfiy the data frame.

Optional argument FUN what to do, e.g., count, unique, etc..
Optional argument ACTION parameters to the FUN."
  (let (cmdhist cmd result)
    (setq cmdhist
          (pcase fun
            ('count
             (format " %%>%% dplyr::count(%s)" (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('unique
             (format " %%>%% dplyr::distinct(%s)" (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('slice
             (format " %%>%% dplyr::slice(%s)" action))
            ('skimr
             (format " %%>%% skimr::skim(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('skimr-all
             " %>% skimr::skim()")
            ;; ('summarise
            ;;  (format " %%>%% dplyr::summarise(%s)" action))
            (_
             (format " %%>%% %s" action))))

    (setq cmd (concat
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-summarize-print-backend)
                       (concat ess-view-data-temp-object cmdhist)
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))

(cl-defmethod ess-view-data--do-reset ((_backend (eql dplyr+DT)) action)
  "Update the data frame by dplyr stepwisely.

Optional argument ACTION R script to reset the view process,
which will become the cmd history."
  (let (cmdhist cmd result)
    (setq cmdhist action)
    (setq ess-view-data-page-number 0)
    (setq cmd (concat
               ess-view-data-temp-object " <<- " cmdhist "; "
               "local({"
               (format "DT::saveWidget(datatable(%1$s, filter = 'top' %2$s), file = '%3$s/%4$s.html')\n"
                       ess-view-data-temp-object
                       (if ess-view-data-maxprint-p
                           (format ", options = list(autoWidth = FALSE,pageLength = %d)"
                                   ess-view-data-DT-rows-per-page)
                         (format ", options = list(lengthMenu = c(10,50,100,%d))"
                                 ess-view-data-DT-rows-per-page))
                       ess-view-data-cache-directory
                       (replace-regexp-in-string "`" "" ess-view-data-temp-object))
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))

(cl-defmethod ess-view-data--create-indirect-buffer
  ((_backend (eql dplyr+DT))
   type fun obj-list temp-object parent-buf proc-name)
  "Create an edit-indirect buffer and return it.

Optional argument TYPE Action type, e.g., update, reset, summarise.
Optional argument FUN Action function to do with data, e.g.,
select, count, and etc..
Optional argument OBJ-LIST Columns/variables to do with.
Optional argument TEMP-OBJECT Temporary data in the view process.
Optional argument PARENT-BUF The associated parent buffer for the view process.
Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'."
  (let ((buf (get-buffer-create (format ess-view-data-source-buffer-name-format temp-object)))
        pts)
    (with-current-buffer buf
      (ess-r-mode)
      (set-buffer-modified-p nil)
      (setq ess-view-data--parent-buffer parent-buf)
      (setq ess-view-data--reset-buffer-p t)
      (setq ess-view-data--action `((:type . ,type) (:function . ,fun)))
      ;; (print (alist-get :function ess-view-data--action))
      ;; (print (alist-get ':type ess-view-data--action))
      (insert "# Insert variable name[s] (C-c i[I]), Insert Values (C-c l[L])\n")
      (insert "# Line started with `#' will be omited\n")
      (insert "# Don't comment code as all code will be wrapped in one line\n")
      (pcase fun
        ('filter
         (setq ess-view-data-completion-object (car obj-list))
         (insert "# dplyr::filter(...)\n")
         (setq pts (point))
         (insert (mapconcat (lambda (x) (propertize x 'evd-object x))
                            (delete-dups (nreverse obj-list)) ","))
         (goto-char pts))
        ('mutate
         (insert "# dplyr::mutate(...)\n")
         (setq pts (point))
         (insert (mapconcat (lambda (x) (format " = %s" (propertize x 'evd-object x)))
                            (delete-dups (nreverse obj-list)) ","))
         (goto-char pts))
        ('wide2long-gather
         (insert "# tidyr::gather(cols, ...)\n")
         (insert (format "key = %s, value = %s" (car obj-list) (nth 1 obj-list))))
        ('long2wide-spread
         (insert "# tidyr::spread(key to clomn names)\n")
         (insert (format "key = %s, value = %s" (car obj-list) (nth 1 obj-list))))
        ('wide2long-pivot_longer
         (insert "# tidyr::pivot_longer(cols, names and values to)\n")
         (insert (format "c(), names_to = %s, values_to = %s" (car obj-list) (nth 1 obj-list))))
        ('long2wide-pivot_wider
         (insert "# tidyr::pivot_wider(names and values from)\n")
         (insert (format "names_from = %s, values_from = %s" (car obj-list) (nth 1 obj-list))))
        ('summarise
         (insert "# %> ... \n# Not limited to function summarise\n")
         ;; (insert (format "summarise(mean = mean(%s, na.rm = TRUE), n = n())" obj-list))
         (insert "summarise(")
         (insert (mapconcat (lambda (x) (format "%s" (propertize x 'evd-object x)))
                            (delete-dups (nreverse obj-list)) ","))
         (insert ", n = n())"))
        ('reset
         (insert "# reset\n")
         (insert obj-list))
        (_
         (insert "# %> ... \n")
         (setq pts (point))
         (insert (mapconcat 'identity (delete-dups (nreverse obj-list)) ","))
         (goto-char pts)))
      (setq ess-local-process-name proc-name)
      (setq ess-view-data-temp-object
            (buffer-local-value 'ess-view-data-temp-object parent-buf))
      (ess-view-data-edit-mode))
    (select-window (display-buffer buf))))


(cl-defmethod ess-view-data-do-goto-page ((_backend (eql dplyr+DT)) page &optional pnumber)
  "Goto PAGE.  Just reset `ess-view-data-page-number' when backend is dplyr+DT.

Optional argument PNUMBER The page number to go to."
  (let (result)
    (setq ess-view-data-page-number
          (pcase page
            ('first 0)
            ('last ess-view-data-total-page)
            ('previous (max 0 (1- ess-view-data-page-number)))
            ('next (min (1+ ess-view-data-page-number) ess-view-data-total-page))
            ('page (max (min pnumber ess-view-data-total-page) 0))
            (_ ess-view-data-page-number)))

    (setq result (cons nil nil))
    result))


;;; * backend: data.table

;;; ** Initialization
(cl-defmethod ess-view-data--initialize-backend ((_backend (eql data.table+magrittr)) proc-name proc)
  "Initializing the history of operations.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
  (let ((obj-space-p (string-match-p ess-view-data-objname-regex ess-view-data-object))
        (obj-back-quote-p (string-match-p "`" ess-view-data-object))
        (obj-back-quote (replace-regexp-in-string "`" "" ess-view-data-object)))
  (unless ess-view-data-history
    (setq ess-view-data-history
          (format (cond (obj-back-quote-p "as.data.table(%s)")
                        (obj-space-p "as.data.table(`%s`)")
                        (t "as.data.table(%s)"))
                  ess-view-data-object)))
  ;; Initializing the temparory object, for stepwise
  (unless ess-view-data-temp-object
    (setq ess-view-data-temp-object
          (format (cond (obj-back-quote-p "`%s`")
                        (obj-space-p "`%s`")
                        (t "`%s`"))
                  (make-temp-name obj-back-quote)))
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (ess-command (concat "{suppressPackageStartupMessages(require(magrittr));"
                           "suppressPackageStartupMessages(require(data.table)); "
                           ess-view-data-temp-object " <- as.data.table("
                           (format (cond (obj-back-quote-p "`%s`")
                                         (obj-space-p "`%s`")
                                         (t "`%s`"))
                                   obj-back-quote)
                           ")}\n")
                   nil nil nil nil proc))))
  (cl-pushnew ess-view-data-temp-object ess-view-data-temp-object-list)
  (delete-dups ess-view-data-temp-object-list))


(cl-defmethod ess-view-data--header-line ((_backend (eql data.table+magrittr)))
  "Make header-line for data.table+magrittr."
  (goto-char (point-min))
  (let ((lin 1))
    (while ;; (looking-at-p "^\\(+\\|#\\)")
        (search-forward-regexp "^\\([+]\\|#\\)" nil t)
      (forward-line)
      (setq lin (1+ lin)))
    (unless (fboundp 'csv-header-line) (require 'csv-mode nil t))
    (when (fboundp 'csv-header-line)
      (setq csv--header-line nil)
      (with-no-warnings (csv-header-line lin))))
  (goto-char (point-min)))

(cl-defmethod ess-view-data-get-total-page ((_backend (eql data.table+magrittr)) proc-name proc)
  "Initializing the history of operations.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (setq ess-view-data-total-page
            (string-to-number
             (car (ess-get-words-from-vector
                   (format "as.character(nrow(%s))\n" ess-view-data-temp-object)))))
      (setq ess-view-data-total-page
            (1+ (floor (/ ess-view-data-total-page ess-view-data-rows-per-page))))))



(cl-defmethod ess-view-data-do-kill-buffer-hook ((_backend (eql data.table+magrittr)) proc-name proc)
  "Initializing the history of operations.

Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'.
Optional argument PROC The assciated ESS process."
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (ess-command (format "rm(%s, envir = globalenv())\n" ess-view-data-temp-object))
      (ess-write-to-dribble-buffer (format "[ESS-v] rm(%s, envir = globalenv())\n" ess-view-data-temp-object))))


;;; ** Utilities
(defvar-local ess-view-data--group nil)

(cl-defmethod ess-view-data--do-update ((_backend (eql data.table+magrittr)) fun action)
  "Update the data frame by data.table stepwisely.

Optional argument FUN What to do with the data, e.g.,
verb like select, filter, and etc..
Optional argument ACTION Parameter (R script) for FUN, e.g., columns for select."
  (let (cmdhist cmd result)
    (setq cmdhist
          (pcase fun
            ('select
             (format " %%>%% .[, .(%s)]"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('filter
             (format " %%>%% .[%s,]" action))
            ('mutate
             (format " %%>%% .[,`:=`(%s)]" action))
            ('sort
             (format " %%>%% setorder(., %s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('group
             ;; (error "No single group step for data.table+magrittr")
             (setq ess-view-data--group
                   (mapconcat 'identity (delete-dups (nreverse action)) ","))
             nil)
            ('ungroup
             (error "No single ungroup step for data.table+magrittr"))
            ('transmute
             (format " %%>%% .[,`:=`(%s)]" action))
            ('wide2long
             (format " %%>%% melt(., %s)" action))
            ('long2wide
             (format " %%>%% dcast(., %s)" action))
            ('slice
             (if ess-view-data--group
                 (format " %%>%% .[, .SD[%s], by = .(%s)]" action
                         ess-view-data--group)
               (error "Group is required for data.table+magrittr")))
            ('unselect
             (format " %%>%% .[,`:=`(%s)]"
                     (mapconcat (lambda (x) (concat x " = NULL"))
                                (delete-dups (nreverse action)) ",")))
            (_
             (format " %%>%% %s" action))))

    (setq ess-view-data-page-number 0)
    (setq cmd (concat
               ess-view-data-temp-object " <<- " ess-view-data-temp-object cmdhist "; "
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-update-print-backend)
                       (concat ess-view-data-temp-object
                               (unless ess-view-data-maxprint-p
                                 (format "[(%1$d*%2$d + 1) : min((%1$d + 1)*%2$d, nrow(%s)),]"
                                         ess-view-data-page-number
                                         ess-view-data-rows-per-page
                                         ess-view-data-temp-object)))
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))


(cl-defmethod ess-view-data--do-summarise ((_backend (eql data.table+magrittr)) fun action)
  "Do summarising by data.table stepwisely, without modfiy the data frame.

Optional argument FUN What to do with the data, e.g.,
verb like count, unique, and etc..
Optional argument ACTION Parameter (R script) for FUN, e.g., columns for count."
  (let (cmdhist cmd result)
    (setq cmdhist
          (pcase fun
            ('count
             (format " %%>%% .[, .N, by = .(%s)] "
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('unique
             (format " %%>%% unique(., by = c(\"%s\"))"
                     (replace-regexp-in-string
                      "^`\\(.*\\)`$" "\\1"
                      (mapconcat 'identity (delete-dups (nreverse action)) "\",\""))))
            ('slice
             (if ess-view-data--group
                 (format " %%>%% .[, .SD[%s], by = .(%s)]" action
                         ess-view-data--group)
               (error "Group is required for data.table+magrittr")))
            ('skimr
             (format " %%>%% skimr::skim(%s)"
                     (mapconcat 'identity (delete-dups (nreverse action)) ",")))
            ('skimr-all
             " %>% skimr::skim()")
            ('summarise
             (format " %%>%% %s" action))
            (_
             (format " %%>%% %s" action))))

    (setq cmd (concat
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-update-print-backend)
                       (concat ess-view-data-temp-object cmdhist)
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))

(cl-defmethod ess-view-data--do-reset ((_backend (eql data.table+magrittr)) action)
  "Update the data frame by data.table stepwisely.

Optional argument ACTION R script to reset the view process,
which will become the cmd history."
  (let (cmdhist cmd result)
    (setq cmdhist action)
    (setq ess-view-data-page-number 0)
    (setq cmd (concat
               ess-view-data-temp-object " <<- " cmdhist "; "
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-update-print-backend)
                       (concat ess-view-data-temp-object
                               (unless ess-view-data-maxprint-p
                                 (format "[(%1$d*%2$d + 1) : min((%1$d + 1)*%2$d, nrow(%s)),]"
                                         ess-view-data-page-number
                                         ess-view-data-rows-per-page
                                         ess-view-data-temp-object)))
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons cmdhist cmd))
    result))

(cl-defmethod ess-view-data-do-goto-page ((_backend (eql data.table+magrittr)) page &optional pnumber)
  "Goto PAGE.

Optional argument PNUMBER The page number to go to."
  (let (cmd result)
    (setq ess-view-data-page-number
          (pcase page
            ('first 0)
            ('last ess-view-data-total-page)
            ('previous (max 0 (1- ess-view-data-page-number)))
            ('next (min (1+ ess-view-data-page-number) ess-view-data-total-page))
            ('page (max (min pnumber ess-view-data-total-page) 0))
            (_ ess-view-data-page-number)))

    (setq cmd (concat
               "local({"
               (format (ess-view-data--do-print ess-view-data-current-update-print-backend)
                       (concat ess-view-data-temp-object
                               (unless ess-view-data-maxprint-p
                                 (format "[(%1$d*%2$d + 1) : min((%1$d + 1)*%2$d, nrow(%s)),]"
                                         ess-view-data-page-number
                                         ess-view-data-rows-per-page
                                         ess-view-data-temp-object)))
                       ess-view-data-temp-object)
               "})\n"))
    (setq result (cons nil cmd))
    result))

(cl-defmethod ess-view-data--create-indirect-buffer
  ((_backend (eql data.table+magrittr))
   type fun obj-list temp-object parent-buf proc-name)
  "Create an edit-indirect buffer and return it.

Optional argument TYPE Action type, e.g., update, reset, summarise.
Optional argument FUN Action function to do with data, e.g.,
select, count, and etc..
Optional argument OBJ-LIST Columns/variables to do with.
Optional argument TEMP-OBJECT Temporary data in the view process.
Optional argument PARENT-BUF The associated parent buffer for the view process.
Optional argument PROC-NAME The name of associated ESS process,
usually `ess-local-process-name'."
  (let ((buf (get-buffer-create (format ess-view-data-source-buffer-name-format temp-object)))
        pts)
    (with-current-buffer buf
      (ess-r-mode)
      (set-buffer-modified-p nil)
      (setq ess-view-data--parent-buffer parent-buf)
      (setq ess-view-data--reset-buffer-p t)
      (setq ess-view-data--action `((:type . ,type) (:function . ,fun)))
      ;; (print (alist-get :function ess-view-data--action))
      ;; (print (alist-get ':type ess-view-data--action))
      (insert "# Insert variable name[s] (C-c i[I]), Insert Values (C-c l[L])\n")
      (insert "# Line started with `#' will be omited\n")
      (insert "# Don't comment code as all code will be wrapped in one line\n")
      (pcase fun
        ('filter
         (setq ess-view-data-completion-object (car obj-list))
         (insert "# DT[...,]\n")
         (setq pts (point))
         (insert (mapconcat (lambda (x) (propertize x 'evd-object x))
                            (delete-dups (nreverse obj-list)) "&"))
         (goto-char pts))
        ('mutate
         (insert "# DT[,`:=`(%s)]\n")
         (setq pts (point))
         (insert (mapconcat (lambda (x) (format " = %s" (propertize x 'evd-object x)))
                            (delete-dups (nreverse obj-list)) ","))
         (goto-char pts))
        ('wide2long
         (insert "# melt(DT, ...)\n")
         (insert (format "id.vars = c(\"%s\"), measure = col to fill, variable.name = , value.name = c(\"%s\")"
                         (car obj-list) (nth 1 obj-list))))
        ('long2wide
         (insert "# dcast(DT, ...)\n")
         (insert (format "id? ~ %s, value.var = c(\"%s\")" (car obj-list)
                         (nth 1 obj-list))))
        ('summarise
         (insert "# DT[...] \n# Not limited to function summarise\n")
         ;; (insert (format "summarise(mean = mean(%s, na.rm = TRUE), n = n())" obj-list))
         (insert ".[, .( ), by = .(")
         (insert (mapconcat (lambda (x) (format "%s" (propertize x 'evd-object x)))
                            (delete-dups (nreverse obj-list)) ","))
         (insert ")]"))
        ('reset
         (insert "# reset\n")
         (insert obj-list))
        (_
         (insert "# ... \n")
         (setq pts (point))
         (insert (mapconcat 'identity (delete-dups (nreverse obj-list)) ","))
         (goto-char pts)))
      (setq ess-local-process-name proc-name)
      (setq ess-view-data-temp-object
            (buffer-local-value 'ess-view-data-temp-object parent-buf))
      (ess-view-data-edit-mode))
    (select-window (display-buffer buf))))



;;; * save data

(cl-defmethod ess-view-data-do-save ((_backend (eql write.csv)) file-name)
  "Ess view data doing select by write.csv stepwise.

Optional argument FILE-NAME file name."
  (let (cmd result)
    (setq cmd (concat
               "write.csv(" ess-view-data-temp-object ", file = \""
               file-name
               "\")\n"))
    (setq result (cons nil cmd))
    result))

(cl-defmethod ess-view-data-do-save ((_backend (eql readr::write_csv)) file-name)
  "Ess view data doing select by readr::write_csv stepwise.

Optional argument FILE-NAME file-name."
  (let (cmd result)
    (setq cmd (concat
               "readr::write_csv(" ess-view-data-temp-object ", file = \""
               file-name
               "\")\n"))
    (setq result (cons nil cmd))
    result))

(cl-defmethod ess-view-data-do-save ((_backend (eql data.table::fwrite)) file-name)
  "Ess view data doing select by data.table::fwrite stepwise.

Optional argument FILE-NAME file-name."
  (let (cmd result)
    (setq cmd (concat
               "data.table::fwrite(" ess-view-data-temp-object ", file = \""
               file-name
               "\")\n"))
    (setq result (cons nil cmd))
    result))


;;; * For completion
(cl-defmethod ess-view-data-do-complete-data ((_backend (eql jsonlite)) &optional dataframe)
  "To get the list for completing in data frame.

Optional argument DATAFRAME dataframe to do complete which will
be dumped vis toJSON."
  (let (cmd result)
    (setq cmd
          (concat
           "jsonlite::toJSON("
           (format "c(list(%1$s = names(%1$s)), lapply(%1$s, function(x) as.character(unique(x))))"
                   (or dataframe ess-view-data-temp-object))
           ")\n"))
    (setq result (json-read-from-string (ess-string-command cmd)))
    result))



(defun ess-view-data--previous-complete-object (prop)
  "Search for the object.

Argument PROP text property to get the object for completion."
  (let (prop-value)
    (while (progn
             (goto-char (previous-single-char-property-change (point) prop))
             (not (or (setq prop-value (get-text-property (point) prop))
                      (eobp)
                      (bobp)))))
    prop-value))



(defun ess-view-data-complete-data (&optional arg)
  "Ess view data do complete.

Optional argument ARG if non-nil, it will read the which variable
to be completed."
  (interactive "P")
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name)))
    ;; Initializing backed
    ;; (ess-view-data--initialize-backend ess-view-data-current-backend proc-name proc)

    (unless ess-view-data-completion-candidate
      (when (and proc-name proc
                 (not (process-get proc 'busy)))
        (setq ess-view-data-completion-candidate
              (ess-view-data-do-complete-data ess-view-data-current-complete-backend)))))

  (let (evd-object)

    (if (or arg (null (save-excursion
                        (save-restriction
                          (setq evd-object (ess-view-data--previous-complete-object 'evd-object))))))
        (progn
          (let* ((possible-completions (ess-r-get-rcompletions))
                 (token-string (or (car possible-completions) ""))
                 (start (- (point) (length token-string)))
                 (end (point)))
            (setq evd-object
                  (funcall ess-view-data-read-string
                           "Variable: "
                           (delq nil (delete-dups (append
                            (if (assq (intern ess-view-data-temp-object)
                                      ess-view-data-completion-candidate)
                                (alist-get (intern ess-view-data-temp-object)
                                           ess-view-data-completion-candidate)
                              (alist-get (intern (replace-regexp-in-string
                                                  "`" "" ess-view-data-temp-object))
                                         ess-view-data-completion-candidate))
                            nil)))
                           nil nil token-string))
            (delete-region start end)
            ;; propertize
            (insert (propertize evd-object 'evd-object evd-object))))

      (if evd-object
          (let* ((possible-completions (ess-r-get-rcompletions))
                 (token-string (or (car possible-completions) ""))
                 (start (- (point) (length token-string)))
                 (end (point))
                 com)
            (setq com
                  (funcall ess-view-data-read-string
                           "Value: "
                           (delq nil (delete-dups (append
                            (if (assq (intern evd-object)
                                      ess-view-data-completion-candidate)
                                (alist-get (intern evd-object)
                                           ess-view-data-completion-candidate)
                              (alist-get (intern (replace-regexp-in-string
                                                  "`" "" evd-object))
                                         ess-view-data-completion-candidate))
                            nil)))
                           nil nil token-string))
            (delete-region start end)
            (insert com))))))


(defun ess-view-data-insert-all-cols ()
  "Insert all column/variable names."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name)))
    ;; Initializing backed
    ;; (ess-view-data--initialize-backend ess-view-data-current-backend proc-name proc)

    (unless ess-view-data-completion-candidate
      (when (and proc-name proc
                 (not (process-get proc 'busy)))
        (setq ess-view-data-completion-candidate
              (ess-view-data-do-complete-data ess-view-data-current-complete-backend)))))

  (if ess-view-data-completion-candidate
      (let* ((obj-list (append
                        (if (assq (intern ess-view-data-temp-object)
                                  ess-view-data-completion-candidate)
                            (alist-get (intern ess-view-data-temp-object)
                                       ess-view-data-completion-candidate)
                          (alist-get (intern (replace-regexp-in-string
                                              "`" "" ess-view-data-temp-object))
                                     ess-view-data-completion-candidate))
                        nil)))
        (insert (mapconcat (lambda (x) (propertize x 'evd-object x))
                           (delete-dups obj-list) ",")))))


(defun ess-view-data-insert-all-values ()
  "Insert all column/variable names."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name)))
    ;; Initializing backed
    ;; (ess-view-data--initialize-backend ess-view-data-current-backend proc-name proc)

    (unless ess-view-data-completion-candidate
      (when (and proc-name proc
                 (not (process-get proc 'busy)))
        (setq ess-view-data-completion-candidate
              (ess-view-data-do-complete-data ess-view-data-current-complete-backend)))))

  (let (evd-object)
    (save-excursion
      (save-restriction
        (setq evd-object (ess-view-data--previous-complete-object 'evd-object))))

    (if evd-object
        (let* ((obj-list (append
                          (if (assq (intern evd-object)
                                    ess-view-data-completion-candidate)
                              (alist-get (intern evd-object)
                                         ess-view-data-completion-candidate)
                            (alist-get (intern (replace-regexp-in-string
                                                "`" "" evd-object))
                                       ess-view-data-completion-candidate))
                          nil)))
          (insert (format "\"%s\""(mapconcat 'identity (delete-dups obj-list) ",")))))))


(defun ess-view-data-complete-object ()
  "Ess view data do complete object name."
  (interactive)
  (ess-view-data-complete-data 1))

(defun ess-view-data-complete-set-object ()
  "Set object for completion."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name)))
    ;; Initializing backed
    ;; (ess-view-data--initialize-backend ess-view-data-current-backend proc-name proc)

    (unless ess-view-data-completion-candidate
      (when (and proc-name proc
                 (not (process-get proc 'busy)))
        (setq ess-view-data-completion-candidate
              (ess-view-data-do-complete-data ess-view-data-current-complete-backend)))))

  (let* ((possible-completions (ess-r-get-rcompletions))
         (token-string (or (car possible-completions) ""))
         object)
    (setq object
          (funcall ess-view-data-read-string
                   "Variable: "
                   (append
                    (if (assq (intern ess-view-data-temp-object)
                              ess-view-data-completion-candidate)
                        (alist-get (intern ess-view-data-temp-object)
                                   ess-view-data-completion-candidate)
                      (alist-get (intern (replace-regexp-in-string
                                          "`" "" ess-view-data-temp-object))
                                 ess-view-data-completion-candidate))
                    nil)
                   nil nil token-string))
    (insert (propertize " " 'evd-object object))))

;;; * Export function

(defun ess-view-data-do-commit ()
  "Commit the modifications done in an edit-indirect buffer.

Can be called only when the current buffer is an edit-indirect buffer."
  (interactive)
  (let* ((parent-buffer ess-view-data--parent-buffer)
         (proc-name (buffer-local-value 'ess-local-process-name parent-buffer))
         (proc (get-process proc-name))
         (fill-column most-positive-fixnum)
         (fun (alist-get :function ess-view-data--action))
         (type (alist-get :type ess-view-data--action))
         command)
    (with-current-buffer (current-buffer)
      (when ess-view-data--reset-buffer-p
        (save-excursion
          (save-match-data
            (goto-char (point-min))
            (flush-lines "^#")
            (fill-region (point-min) (point-max))
            (setq command (buffer-substring-no-properties (point-min) (point-max)))
            ;; make command in one line to avoid the print of ` + ' in the output buffer
            (setq command (replace-regexp-in-string "\n+" " " command))))
        (kill-buffer)))

    (pop-to-buffer parent-buffer)

    (when (and proc-name proc command
               (not (process-get proc 'busy)))
      (setq command
            (pcase type
              ('update
               (ess-view-data--do-update ess-view-data-current-backend fun command))
              ('summarise
               (ess-view-data--do-summarise ess-view-data-current-backend fun command))
              ('reset
               (ess-view-data--do-reset ess-view-data-current-backend command))))
      (ess-command (concat "{" (cdr command) "}") parent-buffer nil nil nil proc)
      (ess-write-to-dribble-buffer (format "[ESS-v] %s.\n" (symbol-name fun)))
      (with-current-buffer parent-buffer
        ;; (ansi-color-apply-on-region (point-min) (point-max))
        (when (memq type '(update reset))
          (if (eql type 'reset)
              (setq ess-view-data-history (car command))
            (setq ess-view-data-history (concat ess-view-data-history (car command))))
          (setq ess-view-data-page-number 0)
          (ess-view-data-get-total-page ess-view-data-current-backend proc-name proc))
        (ess-write-to-dribble-buffer (format "# Trace: %s\n" ess-view-data-history))
        (ess-write-to-dribble-buffer (format "# Last: %s\n" (car command)))
        (goto-char (point-min))
        ;; (toggle-truncate-lines 1)
        ;; (setq-local scroll-preserve-screen-position t)
        (when ess-view-data-show-code
          (insert (format "# Trace: %s\n" ess-view-data-history))
          (insert (format "# Last: %s\n" (car command))))
        (when (memq type '(update reset))
          (unless (or ess-view-data-maxprint-p ess-view-data-show-no-page-number)
                  (insert (format "# Page number: %d / %d\n"
                                  (1+ ess-view-data-page-number) ess-view-data-total-page))))
        ;; (delete-line)
        (goto-char (point-min))
        (ess-view-data-mode 1)
        (goto-char (point-min))
        (ess-view-data--header-line ess-view-data-current-backend)))))


(defun ess-view-data-do-apply (type fun indirect &optional desc trans prompt)
  "Update data frame.

Argument TYPE Action type, e.g., update, reset, summarise.
Argument FUN Action function to do with data, e.g., select, count, etc..
Argument INDIRECT Indirect buffter to edit the parameters or verbs.
Optional argument DESC if non-nil, then descending.
Optional argument TRANS if non-nil, read key and value for tranform.
Optional argument PROMPT prompt for `read-string'."
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         (obj " ")
         obj-list
         objs
         objs2
         command)
    ;; Initializing backed
    (ess-view-data--initialize-backend ess-view-data-current-backend proc-name proc)
    ;; variables
    (if (eql 'reset fun)
        ;; reset
        (ess-view-data--create-indirect-buffer ess-view-data-current-backend
                                               type fun
                                               ess-view-data-history
                                               ess-view-data-temp-object buf proc-name)
      ;; other actions
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (if prompt
          ;; general read-string
          (setq obj-list (read-string prompt))
        ;; read column names
        (setq objs (ess-get-words-from-vector
                    (concat "colnames(" ess-view-data-temp-object ")\n"))) ;; or "ls()"
        ;; In case the colname is not simple
        (setq objs (mapcar (lambda (x)
                             (format (if (string-match-p ess-view-data-objname-regex x)
                                         "`%s`" "%s")
                                     x))
                           objs))
        (if desc
            (setq objs (apply 'append
                              `(,objs
                                ,(mapcar (lambda (x) (format desc x)) objs)))))
        (if trans
            (progn
              (setq obj (funcall ess-view-data-read-string "key"  objs))
              (setq objs2 (funcall ess-view-data-read-string "value"  objs))
              (setq obj-list (list obj objs2)))
          (if (equal ess-view-data-read-string 'completing-read)
              (setq obj-list (nreverse (completing-read-multiple "Select Variables: " objs)))
            (while (not (equal obj ""))
              (setq obj (funcall ess-view-data-read-string
                                 (format "Variable (%s), C-j to finish"
                                         (mapconcat 'identity
                                                    (setq objs2 (nreverse objs2))
                                                    ","))
                                 objs))
              (unless (equal obj "")
                (setq objs (delete obj objs))
                (cl-pushnew obj obj-list)
                (cl-pushnew obj objs2))))))
      (if indirect
          (when obj-list
            (ess-view-data--create-indirect-buffer ess-view-data-current-backend
                                                   type fun obj-list
                                                   ess-view-data-temp-object
                                                   buf proc-name))
        (when obj-list
          (setq command
                (pcase type
                  ('update
                   (ess-view-data--do-update ess-view-data-current-backend fun obj-list))
                  ('summarise
                   (ess-view-data--do-summarise ess-view-data-current-backend fun obj-list)))))
        (when (and proc-name proc command
                   (not (process-get proc 'busy)))
          (ess-command (concat "{" (cdr command) "}") buf nil nil nil proc)
          (ess-write-to-dribble-buffer (format "[ESS-v] %s.\n" (symbol-name fun)))
          (with-current-buffer buf
            ;; (ansi-color-apply-on-region (point-min) (point-max))
            (when (eql type 'update)
              (setq ess-view-data-history (concat ess-view-data-history (car command)))
              (setq ess-view-data-page-number 0)
              (ess-view-data-get-total-page ess-view-data-current-backend proc-name proc))
            (ess-write-to-dribble-buffer (format "# Trace: %s\n" ess-view-data-history))
            (ess-write-to-dribble-buffer (format "# Last: %s\n" (car command)))
            (goto-char (point-min))
            (when ess-view-data-show-code
              (insert (format "# Trace: %s\n" ess-view-data-history))
              (insert (format "# Last: %s\n" (car command))))
            (when (eql type 'update)
              (unless (or ess-view-data-maxprint-p ess-view-data-show-no-page-number)
                      (insert (format "# Page number: %d / %d\n"
                                      (1+ ess-view-data-page-number) ess-view-data-total-page))))
            ;; (delete-line)
            (goto-char (point-min))
            (ess-view-data-mode 1)
            (goto-char (point-min))
            (ess-view-data--header-line ess-view-data-current-backend))))))))




(defun ess-view-data-select ()
  "Select columns/variables."
  (interactive)
  (ess-view-data-do-apply 'update 'select nil nil))

(defun ess-view-data-unselect ()
  "Select columns/variables."
  (interactive)
  (ess-view-data-do-apply 'update 'unselect nil nil))

(defun ess-view-data-sort ()
  "Sort columns/variables."
  (interactive)
  (ess-view-data-do-apply
   'update 'sort nil
   (plist-get (alist-get ess-view-data-current-backend ess-view-data-backend-setting) :desc)))

(defun ess-view-data-group ()
  "Group columns/variables."
  (interactive)
  (ess-view-data-do-apply 'update 'group nil nil))

(defun ess-view-data-ungroup ()
  "Ungroup columns/variables."
  (interactive)
  (ess-view-data-do-apply 'update 'ungroup nil nil))


;; filter
(defun ess-view-data-filter ()
  "Do filter."
  (interactive)
  (ess-view-data-do-apply 'update 'filter t nil))

;; mutate
(defun ess-view-data-mutate ()
  "Do mutate."
  (interactive)
  (ess-view-data-do-apply 'update 'mutate t nil))

(defun ess-view-data-slice ()
  "Slice."
  (interactive)
  (ess-view-data-do-apply
   'update 'slice nil nil nil
   (plist-get (alist-get ess-view-data-current-backend ess-view-data-backend-setting) :slice)))


;; wide2long
(defun ess-view-data-wide2long ()
  "Do wide2long."
  (interactive)
  (ess-view-data-do-apply 'update 'wide2long t nil t))


;; long2wide
(defun ess-view-data-long2wide ()
  "Do long2wide."
  (interactive)
  (ess-view-data-do-apply 'update 'long2wide t nil t))

;; update
(defun ess-view-data-update ()
  "Do update."
  (interactive)
  (ess-view-data-do-apply 'update 'update t nil))

;;; ** reset
(defun ess-view-data-reset ()
  "Do filter."
  (interactive)
  (ess-view-data-do-apply 'reset 'reset t nil))


;;; ** summarise
(defun ess-view-data-unique ()
  "Unique."
  (interactive)
  (ess-view-data-do-apply 'summarise 'unique nil nil))


(defun ess-view-data-count ()
  "Count."
  (interactive)
  (ess-view-data-do-apply 'summarise 'count nil nil))

(defun ess-view-data-skimr ()
  "Count."
  (interactive)
  (ess-view-data-do-apply 'summarise 'skimr nil nil))

(defun ess-view-data-summarise ()
  "Ess view data do summarise."
  (interactive)
  (ess-view-data-do-apply 'summarise 'summarise t nil))

(defun ess-view-data-overview ()
  "Ess view data do summarise."
  (interactive)
  (ess-view-data-do-apply 'summarise 'overview t nil))


(defun ess-view-data-verbs (verb)
  "Select the VERB to do."
  (interactive (list (completing-read
                      "verb: "
				      (append ess-view-data-verb-update-list
                              ess-view-data-verb-update-indirect-list
                              ess-view-data-verb-summarise-list
                              ess-view-data-verb-summarise-indirect-list
                              '("reset"))
				      nil t)))
  (cond
   ((member verb ess-view-data-verb-update-list)
    (ess-view-data-do-apply 'update (intern verb) nil nil))
   ((member verb ess-view-data-verb-update-indirect-list)
    (ess-view-data-do-apply 'update (intern verb) t nil))
   ((member verb ess-view-data-verb-summarise-list)
    (ess-view-data-do-apply 'summarise (intern verb) nil nil))
   ((member verb ess-view-data-verb-summarise-indirect-list)
    (ess-view-data-do-apply 'summarise (intern verb) t nil))
   ((string= verb "reset")
    (ess-view-data-do-apply 'reset 'reset t nil))))



(defun ess-view-data-commit-abort ()
  "Kill the edit-indirect buffer."
  (interactive)
  (kill-buffer))



;; scroll data

;;; ** goto page
(defun ess-view-data-goto-page (page &optional pnumber)
  "Goto PAGE.
Optional argument PNUMBER pange number to go."
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         command)
    ;; Initializing backed
    (ess-view-data--initialize-backend ess-view-data-current-backend proc-name proc)

    (setq command
          (ess-view-data-do-goto-page ess-view-data-current-backend page pnumber))

    (when (and proc-name proc command
               (not (process-get proc 'busy)))
      (ess-command (concat "{" (cdr command) "}") buf nil nil nil proc)
      (with-current-buffer buf
        (goto-char (point-min))
        ;; (ansi-color-apply-on-region (point-min) (point-max))
        ;; (toggle-truncate-lines 1)
        ;; (setq-local scroll-preserve-screen-position t)
        (when ess-view-data-show-code
          (insert (format "# Trace: %s\n" ess-view-data-history)))
        (when ess-view-data-show-no-page-number
          (insert (format "# Page number: %d / %d\n"
                          (1+ ess-view-data-page-number)
                          ess-view-data-total-page)))
        ;; (delete-line)
        (goto-char (point-min))
        (ess-view-data-mode 1)
        (goto-char (point-min))
        (ess-view-data--header-line ess-view-data-current-backend)))))


(defun ess-view-data-goto-next-page ()
  "Ess view data do select."
  (interactive)
  (ess-view-data-goto-page 'next))

(defun ess-view-data-goto-previous-page ()
  "Ess view data do select."
  (interactive)
  (ess-view-data-goto-page 'previous))

(defun ess-view-data-goto-first-page ()
  "Ess view data do select."
  (interactive)
  (ess-view-data-goto-page 'first))

(defun ess-view-data-goto-last-page ()
  "Ess view data do select."
  (interactive)
  (ess-view-data-goto-page 'last))


(defun ess-view-data-goto-page-number (&optional pnumber)
  "Ess view data do select.

Optional argument PNUMBER The page number to go to."
  (interactive "NGoto page:")
  ;; (unless pnumber )
  (ess-view-data-goto-page 'page (1- pnumber)))


;; save
(defun ess-view-data-save ()
  "Ess view data do save."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         file-name
         command)
    ;; Initializing backed
    (ess-view-data--initialize-backend ess-view-data-current-backend proc-name proc)
    ;; slice variables
    (setq file-name (find-file-read-args "Find file: "
                                         (confirm-nonexistent-file-or-buffer)))
    (if file-name
        (setq command
              (ess-view-data-do-save ess-view-data-current-save-backend (car file-name))))
    (when (and proc-name proc command
               (not (process-get proc 'busy)))
      (ess-command (concat "{" (cdr command) "}") nil nil nil nil proc)
      (ess-write-to-dribble-buffer "[ESS-v] Saved.\n")
      (ess-write-to-dribble-buffer (format "# Trace: %s\n" ess-view-data-history))
      (ess-write-to-dribble-buffer (format "# Last: %s\n" (car command)))
      (with-current-buffer buf
        (goto-char (point-min))))))



;; utilities
(defun ess-view-data-quit ()
  "Quit from ess-view-data."
  (interactive)
  (kill-buffer))

(defun ess-view-data-kill-buffer-hook ()
  "Hook for `kill-buffer' to clean environment."
  (let* ((proc-name (buffer-local-value 'ess-local-process-name (current-buffer)))
         (proc (get-process proc-name)))
    (ess-view-data-do-kill-buffer-hook ess-view-data-current-backend proc-name proc)))


(define-minor-mode ess-view-data-mode
  "ess-view-data"
  :global nil
  :group 'ess-view-data
  :keymap ess-view-data-mode-map
  :lighter " ESS-V"
  (if ess-view-data-mode
      (progn
        (require 'ansi-color)
        (ansi-color-apply-on-region (point-min) (point-max))
        (setq buffer-read-only t)
        (setq mode-line-process
              '(" ["
                (:eval (format "%d/%d"
                               ess-view-data-page-number
                               ess-view-data-total-page))
                "]"))
        (force-mode-line-update)
        (add-hook 'kill-buffer-hook #'ess-view-data-kill-buffer-hook nil t))))

(defun ess-view-data-print-ex (&optional obj proc-name maxprint)
  "Do print.

Optional argument OBJ the object (data.frame/tibble etc.) to print and view.
Optional argument PROC-NAME the name of associated ESS process.
Optional argument MAXPRINT if non-nil, 100 rows/lines per page; if t, shwo all."
  (interactive "P")
  (let* ((obj (or obj ess-view-data-object))
         (proc-name (or proc-name (buffer-local-value 'ess-local-process-name (current-buffer))))
         (buf (get-buffer-create (format ess-view-data-buffer-name-format obj proc-name)))
         ;; (proc-name-buf (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         command)
    ;; (if (or (not proc-name-buf) (equal proc-name proc-name-buf))
        ;; A new view or from the same process
        (with-current-buffer buf
          (if maxprint
              (setq ess-view-data-maxprint-p (not ess-view-data-maxprint-p)))
          (unless ess-view-data-object
            (setq ess-view-data-object obj)
            (setq ess-local-process-name proc-name))
          (ess-view-data--initialize-backend ess-view-data-current-backend proc-name proc)
          (ess-view-data-get-total-page ess-view-data-current-backend proc-name proc)
          (setq command
                (ess-view-data--do-reset ess-view-data-current-backend
                                        (format "%s" ess-view-data-temp-object))))

    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (ess-command (concat "{" (cdr command) "}") buf nil nil nil proc)
      ;; (ansi-color-apply-on-region (point-min) (point-max))
      (ess-write-to-dribble-buffer "[ESS-v] Print.\n")
      (ess-write-to-dribble-buffer (format "# Trace: %s\n" ess-view-data-history))
      (with-current-buffer buf
        (setq-local scroll-preserve-screen-position t)
        (toggle-truncate-lines 1)
        (goto-char (point-min))
        (when ess-view-data-show-code
          (insert (format "# Trace: %s\n" ess-view-data-history)))
        (unless (or ess-view-data-maxprint-p ess-view-data-show-no-page-number)
          (insert (format "# Page number: %d / %d\n"
                          (1+ ess-view-data-page-number)
                          ess-view-data-total-page)))
        ;; (delete-line)
        (goto-char (point-min))
        (ess-view-data--header-line ess-view-data-current-backend)
        (ess-view-data-mode 1))
      buf)))



;;;###autoload
(defun ess-view-data-print (&optional maxprint)
  "Ess R dv using pprint.
Optional argument MAXPRINT maxprint."
  (interactive "P")
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((obj (or ess-view-data-object
                 (tabulated-list-get-id)
                 ;; (current-word)
                 (funcall ess-view-data-read-string
                  "Object: "
                  (ess-get-words-from-vector "ls(envir = .GlobalEnv)\n")
                  nil nil (current-word)))))
    (pop-to-buffer (ess-view-data-print-ex obj maxprint))))


(defun ess-view-data-clean-up ()
  "Ess view data do select."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         command)
    (setq command (concat "rm("
                          (mapconcat 'identity ess-view-data-temp-object-list
                                      ",")
                           ", envir = globalenv())\n"))
    (when (and proc-name proc command
               (not (process-get proc 'busy)))
      (ess-command (concat "{" command "}") nil nil nil nil proc))
    (setq ess-view-data-temp-object-list '(ess-view-data-temp-object))))


(defun ess-view-data-toggle-maxprint ()
  "Ess view data do select."
  (interactive)
  (setq ess-view-data-page-number 0)
  (setq ess-view-data-maxprint-p (not ess-view-data-maxprint-p)))

(defun ess-view-data-make-header-line ()
  "Ess view data do select."
  (interactive)
  (ess-view-data--header-line ess-view-data-current-backend))


(defun ess-view-data-set-backend (manipulate update summarise write complete)
  "Set backend.

Argument MANIPULATE `ess-view-data-current-backend' from
`ess-view-data-backend-list'.
Argument UPDATE `ess-view-data-current-update-print-backend' from
`ess-view-data-print-backend-list'.
Argument SUMMARISE `ess-view-data-current-summarize-print-backend' from
`ess-view-data-print-backend-list'.
Argument WRITE `ess-view-data-current-save-backend' from
`ess-view-data-save-backend-list'.
Argument COMPLETE `ess-view-data-current-complete-backend' from
`ess-view-data-complete-backend-list'."
  (interactive (list (completing-read
                      (format "Backend for data manipulate (%s): "
                              ess-view-data-current-backend)
				      (mapcar (lambda (x)
						        (symbol-name x))
					          ess-view-data-backend-list)
				      nil t)
                     (completing-read
                      (format "Backend for data print in Emacs buffer (%s): "
                              ess-view-data-current-update-print-backend)
				      (mapcar (lambda (x)
						        (symbol-name x))
					          ess-view-data-print-backend-list)
				      nil t)
                     (completing-read
                      (format "Backend for summary print in Emacs buffer (%s): "
                              ess-view-data-current-summarize-print-backend)
				      (mapcar (lambda (x)
						        (symbol-name x))
					          ess-view-data-print-backend-list)
				      nil t)
                     (completing-read
                      (format "Backend for save data (%s): "
                              ess-view-data-current-save-backend)
				      (mapcar (lambda (x)
						        (symbol-name x))
					          ess-view-data-save-backend-list)
				      nil t)
                     (completing-read
                      (format "Backend for completion (%s): "
                              ess-view-data-current-complete-backend)
				      (mapcar (lambda (x)
						        (symbol-name x))
					          ess-view-data-complete-backend-list)
				      nil t)))
  (unless (or (null manipulate) (string-blank-p manipulate))
    (setq ess-view-data-current-backend (intern manipulate)))
  (unless (or (null update) (string-blank-p update))
    (setq ess-view-data-current-update-print-backend (intern update)))
  (unless (or (null summarise) (string-blank-p summarise))
    (setq ess-view-data-current-summarize-print-backend (intern summarise)))
  (unless (or (null write) (string-blank-p write))
    (setq ess-view-data-current-save-backend (intern write)))
  (unless (or (null complete) (string-blank-p complete))
    (setq ess-view-data-current-complete-backend (intern complete))))



(provide 'ess-view-data)
;;; ess-view-data.el ends here
