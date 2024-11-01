;;; company-lua.el --- Company backend for Lua       -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Peter Vasil

;; Author: Peter Vasil <mail@petervasil.net>
;; Keywords:
;; Package-Requires: ((company "0.8.12") (s "1.10.0") (f "0.17.0") (lua-mode "20151025"))

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

(require 'company)
(require 'lua-mode)
(require 'f)
(require 's)


(defgroup company-lua nil
  "Completion backend for Lua."
  :group 'company)

(defcustom company-lua-executable
  (executable-find "lua")
  "Location of Lua executable."
  :type 'file
  :group 'company-lua)

(defcustom company-lua-interpreter 'lua52
  "Lua interpreter."
  :group 'company-lua
  :type '(choice (const :tag "Lua 5.1" lua51)
                 (const :tag "Lua 5.2" lua52)
                 (const :tag "Lua 5.2" lua53)
                 (const :tag "LÖVE" love))
  :safe #'symbolp)

(defconst company-lua-complete-script
  (f-join (f-dirname (f-this-file)) "lua/complete.lua")
  "Script file for completion.")

(defun company-lua--parse-output ()
  "Parse output of `company-lua-complete-script'."
  (goto-char (point-min))
  (let ((pattern "word:\\(.*\\),kind:\\(.*\\),args:\\(.*\\),returns:\\(.*\\),doc:\\(.*\\)$")
        (case-fold-search nil)
        result)
    (while (re-search-forward pattern nil t)
      (let ((item (match-string-no-properties 1))
            (kind (match-string-no-properties 2))
            (args (match-string-no-properties 3))
            (returns (match-string-no-properties 4))
            (doc (match-string-no-properties 5)))
        (when doc
          (setq doc (s-replace "\\n" "\n" doc)))
        (push (propertize item 'kind kind 'args args 'returns returns 'doc doc) result)))
    result))

(defun company-lua--start-process (callback &rest args)
  (let ((buf (get-buffer-create "*company-lua-output*"))
        (process-adaptive-read-buffering nil))
    (if (get-buffer-process buf)
        (funcall callback nil)
      (with-current-buffer buf
        (erase-buffer)
        (setq buffer-undo-list t))
      (let ((process (apply #'start-process "lua" buf
                            company-lua-executable args)))
        (set-process-sentinel
         process
         (lambda (proc status)
           (funcall
            callback
            (let ((res (process-exit-status proc)))
              (with-current-buffer buf
                (company-lua--parse-output))))))))))

(defun company-lua--get-interpreter()
  (if (memq company-lua-interpreter '(lua51 lua52 lua53 love))
      (symbol-name company-lua-interpreter)
    "lua52"))

(defun company-lua--build-args ()
  (list company-lua-complete-script
        (company-lua--get-interpreter)
        (lua-funcname-at-point)))

(defun company-lua--get-candidates (callback)
  (apply 'company-lua--start-process
         callback (company-lua--build-args)))

(defun company-lua--candidates ()
  "Candidates handler for the company backend."
  (cons :async (lambda (cb)
                 (company-lua--get-candidates cb))))

(defun company-lua--annotation (candidate)
  (let ((kind (get-text-property 0 'kind candidate))
        (returns (get-text-property 0 'returns candidate))
        (args (get-text-property 0 'args candidate)))
    (concat
     (when (s-present? args) args)
     (when (s-present? returns) (s-prepend " -> " returns))
     (when (s-present? kind) (format " [%s]" kind)))))

(defun company-lua--meta (candidate)
  (let ((kind (get-text-property 0 'kind candidate))
        (returns (get-text-property 0 'returns candidate))
        (args (get-text-property 0 'args candidate)))
    (concat
     (when (s-present? returns) (s-append " " returns))
     candidate
     (when (s-present? args) args))))

(defun company-lua--prefix ()
  (and (derived-mode-p 'lua-mode)
       (not (company-in-string-or-comment))
       (or (company-grab-symbol-cons "\\." 1) 'stop)))

(defun company-lua--doc-buffer (candidate)
  (let ((doc (get-text-property 0 'doc candidate)))
    (when (s-present? doc)
      (company-doc-buffer doc))))

;;;###autoload
(defun company-lua (command &optional arg &rest ignored)
  "`company-mode' completion back-end for Lua."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-lua))
    (init (unless company-lua-executable
            (error "Company found no Lua executable")))
    (prefix (company-lua--prefix))
    (candidates (company-lua--candidates))
    (annotation (company-lua--annotation arg))
    (meta (company-lua--meta arg))
    (doc-buffer (company-lua--doc-buffer arg))
    (duplicates t)))

(provide 'company-lua)
;;; company-lua.el ends here
