;;; consult-notmuch.el --- Notmuch search using consult  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: mail
;; License: GPL-3.0-or-later
;; Version: 0.8.1
;; Package-Requires: ((emacs "26.1") (consult "0.9") (notmuch "0.31"))
;; Homepage: https://codeberg.org/jao/consult-notmuch


;; Copyright (C) 2021, 2022  Jose A Ortega Ruiz

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

;; This package provides two commands using consult to query notmuch
;; emails and present results either as single emails
;; (`consult-notmuch') or full trees (`consult-notmuch-tree').
;;
;; The package also defines a narrowing source for `consult-buffer',
;; which can be activated with
;;
;;   (add-to-list 'consult-buffer-sources 'consult-notmuch-buffer-source)

;; This elisp file is automatically generated from its literate
;; counterpart at
;; https://codeberg.org/jao/consult-notmuch/src/branch/main/readme.org

;;; Code:

(require 'consult)
(require 'notmuch)

(defgroup consult-notmuch nil
  "Options for `consult-notmuch'."
  :group 'consult)

(defcustom consult-notmuch-show-single-message t
  "Show only the matching message or the whole thread in listings."
  :type 'boolean)

(defcustom consult-notmuch-result-format
  '(("date" . "%12s  ")
    ("count" . "%-7s ")
    ("authors" . "%-20s")
    ("subject" . "  %-54s")
    ("tags" . " (%s)"))
  "Format for matching candidates in minibuffer.
Supported fields are: date, authors, subject, count and tags."
  :type '(alist :key-type string :value-type string))


(defun consult-notmuch--command (input)
  "Construct a search command for emails containing INPUT."
  (if consult-notmuch-show-single-message
      `(,notmuch-command "show" "--body=false" ,input)
    `(,notmuch-command "search" ,input)))

(defun consult-notmuch--search (&optional initial)
  "Perform an asynchronous notmuch search via `consult--read'.
If given, use INITIAL as the starting point of the query."
  (setq consult-notmuch--partial-parse nil)
  (consult--read (consult--async-command
                     #'consult-notmuch--command
                   (consult--async-filter #'identity)
                   (consult--async-map #'consult-notmuch--transformer))
                 :prompt "Notmuch search: "
                 :require-match t
                 :initial (consult--async-split-initial initial)
                 :history '(:input consult-notmuch-history)
                 :state #'consult-notmuch--preview
                 :lookup #'consult--lookup-member
                 :category 'notmuch-result
                 :sort nil))

(defvar consult-notmuch-history nil
  "History for `consult-notmuch'.")

(defun consult-notmuch--transformer (str)
  "Transform STR to notmuch display style."
  (if consult-notmuch-show-single-message
      (consult-notmuch--show-transformer str)
    (consult-notmuch--search-transformer str)))

(defun consult-notmuch--format-field (spec msg)
  "Return a string for SPEC given the MSG metadata."
  (let ((field (car spec)))
    (cond ((equal field "count")
           (when-let (cnt (plist-get msg :count))
             (format (cdr spec) cnt)))
          ((equal field "tags")
           (when (plist-get msg :tags)
             (notmuch-tree-format-field "tags" (cdr spec) msg)))
          (t (notmuch-tree-format-field field (cdr spec) msg)))))

(defun consult-notmuch--format-candidate (msg)
  "Format the result (MSG) of parsing a notmuch show information unit."
  (when-let (id (plist-get msg :id))
    (let ((result-string))
      (dolist (spec consult-notmuch-result-format)
        (when-let (field (consult-notmuch--format-field spec msg))
          (setq result-string (concat result-string field))))
      (propertize result-string 'id id 'tags (plist-get msg :tags)))))

(defun consult-notmuch--candidate-id (candidate)
  "Recover the thread id for the given CANDIDATE string."
  (when candidate (get-text-property 0 'id candidate)))

(defun consult-notmuch--candidate-tags (candidate)
  "Recover the message tags for the given CANDIDATE string."
  (when candidate (get-text-property 0 'tags candidate)))

(defvar consult-notmuch--partial-parse nil
  "Internal variable for parsing status.")
(defvar consult-notmuch--partial-headers nil
  "Internal variable for parsing status.")
(defvar consult-notmuch--info nil
  "Internal variable for parsing status.")

(defun consult-notmuch--set (k v)
  "Set the value V for property K in the message we're currently parsing."
  (setq consult-notmuch--partial-parse
        (plist-put consult-notmuch--partial-parse k v)))

(defun consult-notmuch--show-transformer (str)
  "Parse output STR of notmuch show, extracting its components."
  (if (string-prefix-p "message}" str)
      (prog1
          (consult-notmuch--format-candidate
           (consult-notmuch--set :headers consult-notmuch--partial-headers))
        (setq consult-notmuch--partial-parse nil
              consult-notmuch--partial-headers nil
              consult-notmuch--info nil))
    (cond ((string-match "message{ \\(id:[^ ]+\\) .+" str)
           (consult-notmuch--set :id (match-string 1 str))
           (consult-notmuch--set :match t))
          ((string-prefix-p "header{" str)
           (setq consult-notmuch--info t))
          ((and str consult-notmuch--info)
           (when (string-match "\\(.+\\) (\\([^)]+\\)) (\\([^)]*\\))$" str)
             (consult-notmuch--set :Subject (match-string 1 str))
             (consult-notmuch--set :date_relative (match-string 2 str))
             (consult-notmuch--set :tags (split-string (match-string 3 str))))
           (setq consult-notmuch--info nil))
          ((string-match "\\(Subject\\|From\\|To\\|Cc\\|Date\\): \\(.+\\)?" str)
           (let ((k (intern (format ":%s" (match-string 1 str))))
                 (v (or (match-string 2 str) "")))
             (setq consult-notmuch--partial-headers
                   (plist-put consult-notmuch--partial-headers k v)))))
    nil))

(defun consult-notmuch--search-transformer (str)
  "Transform STR from notmuch search to notmuch display style."
  (when (string-match "thread:" str)
    (let* ((id (car (split-string str "\\ +")))
           (date (substring str 24 37))
           (mid (substring str 24))
           (c0 (string-match "[[]" mid))
           (c1 (string-match "[]]" mid))
           (count (substring mid c0 (1+ c1)))
           (auths (string-trim (nth 1 (split-string mid "[];]"))))
           (subject (string-trim (nth 1 (split-string mid "[;]"))))
           (headers (list :Subject subject :From auths))
           (t0 (string-match "([^)]*)\\s-*$" mid))
           (tags (split-string (substring mid (1+  t0) -1)))
           (msg (list :id id
                      :match t
                      :headers headers
                      :count count
                      :date_relative date
                      :tags tags)))
      (consult-notmuch--format-candidate msg))))


(defvar consult-notmuch--buffer-name "*consult-notmuch*"
  "Name of preview and result buffers.")

(defun consult-notmuch--show-id (id buffer)
  "Show message or thread id in the requested buffer"
  (let ((notmuch-show-only-matching-messages
         consult-notmuch-show-single-message))
    (notmuch-show id nil nil nil buffer)))

(defun consult-notmuch--preview (action candidate)
  "Preview CANDIDATE when ACTION is 'preview."
  (cond ((eq action 'preview)
         (when-let ((id (consult-notmuch--candidate-id candidate)))
           (when (get-buffer consult-notmuch--buffer-name)
             (kill-buffer consult-notmuch--buffer-name))
           (consult-notmuch--show-id id consult-notmuch--buffer-name)))
        ((eq action 'exit)
         (when (get-buffer consult-notmuch--buffer-name)
           (kill-buffer consult-notmuch--buffer-name)))))


(defun consult-notmuch--show (candidate)
  "Open resulting CANDIDATE in ‘notmuch-show’ view."
  (when-let ((id (consult-notmuch--candidate-id candidate)))
    (let* ((subject (car (last (split-string candidate "\t"))))
           (title (concat consult-notmuch--buffer-name " " subject)))
      (consult-notmuch--show-id id title))))


(defun consult-notmuch--tree (candidate)
  "Open resulting CANDIDATE in ‘notmuch-tree’."
  (when-let ((thread-id (consult-notmuch--candidate-id candidate)))
    (notmuch-tree thread-id nil nil)))


;; Embark Integration:
(with-eval-after-load 'embark
  (defvar consult-notmuch-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "+") 'consult-notmuch-tag)
      (define-key map (kbd "-") 'consult-notmuch-tag)
      map)
    "Keymap for actions on Notmuch entries.")
  
  (set-keymap-parent consult-notmuch-map embark-general-map)
  (add-to-list 'embark-keymap-alist '(notmuch-result . consult-notmuch-map))
  
  (defun consult-notmuch--address-to-multi-select (address)
    "Select more email addresses, in addition to the current selection"
    (consult-notmuch-address t address))
  
  (defvar consult-notmuch-address-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "c") #'consult-notmuch-address-compose)
      (define-key map (kbd "m") #'consult-notmuch--address-to-multi-select)
      map))
  
  (set-keymap-parent consult-notmuch-address-map embark-general-map)
  (add-to-list 'embark-keymap-alist
               '(notmuch-address . consult-notmuch-address-map))
  
  (defun consult-notmuch-tag (msg)
    (when-let* ((id (consult-notmuch--candidate-id msg))
                (tags (consult-notmuch--candidate-tags msg))
                (tag-changes (notmuch-read-tag-changes tags "Tags: " "+")))
      (notmuch-tag (concat "(" id ")") tag-changes)))
  
  (defvar consult-notmuch-export-function #'notmuch-search
    "Function used to ask notmuch to display a list of found ids.
  Typical options are notmuch-search and notmuch-tree.")
  
  (defun consult-notmuch-export (msgs)
    "Create a notmuch search buffer listing messages."
    (funcall consult-notmuch-export-function
     (concat "(" (mapconcat #'consult-notmuch--candidate-id msgs " ") ")")))
  (add-to-list 'embark-exporters-alist
               '(notmuch-result . consult-notmuch-export)))

;;;###autoload
(defun consult-notmuch (&optional initial)
  "Search for your email in notmuch, showing single messages.
If given, use INITIAL as the starting point of the query."
  (interactive)
  (consult-notmuch--show (consult-notmuch--search initial)))

;;;###autoload
(defun consult-notmuch-tree (&optional initial)
  "Search for your email in notmuch, showing full candidate tree.
If given, use INITIAL as the starting point of the query."
  (interactive)
  (consult-notmuch--tree (consult-notmuch--search initial)))

(defun consult-notmuch--address-command (input)
  "Spec for an async command querying a notmuch address with INPUT."
  `(,notmuch-command "address" "--format=text" ,input))

(defun consult-notmuch-address-compose (address)
  "Compose an email to a given ADDRESS."
  (let ((other-headers (and notmuch-always-prompt-for-sender
                            `((From . ,(notmuch-mua-prompt-for-sender))))))
    (notmuch-mua-mail address
                      nil
                      other-headers
                      nil
                      (notmuch-mua-get-switch-function))))

(defun consult-notmuch--address-prompt ()
  (consult--read (consult--async-command #'consult-notmuch--address-command)
                 :prompt "Notmuch addresses: "
                 :sort nil
                 :category 'notmuch-address))

;;;###autoload
(defun consult-notmuch-address (&optional multi-select-p initial-addr)
  "Search the notmuch db for an email address and compose mail to it.
With a prefix argument, prompt multiple times until there
is an empty input."
  (interactive "P")
  (if multi-select-p
      (cl-loop for addr = (consult-notmuch--address-prompt)
               until (eql (length addr) 0)
               collect addr into addrs
               finally (consult-notmuch-address-compose
                        (mapconcat #'identity
                                   (if initial-addr
                                       (cons initial-addr addrs)
                                     addrs)
                                   ", ")))
    (consult-notmuch-address-compose (consult-notmuch--address-prompt))))


(defun consult-notmuch--interesting-buffers ()
  "Return a list of names of buffers with interesting notmuch data."
  (consult--buffer-query
   :as (lambda (buf)
         (when (notmuch-interesting-buffer buf)
           (buffer-name buf)))))

;;;###autoload
(defvar consult-notmuch-buffer-source
  '(:name "Notmuch Buffer"
    :narrow (?n . "Notmuch")
    :hidden t
    :category buffer
    :face consult-buffer
    :history buffer-name-history
    :state consult--buffer-state
    :items consult-notmuch--interesting-buffers)
  "Notmuch buffer candidate source for `consult-buffer'.")

(provide 'consult-notmuch)
;;; consult-notmuch.el ends here
