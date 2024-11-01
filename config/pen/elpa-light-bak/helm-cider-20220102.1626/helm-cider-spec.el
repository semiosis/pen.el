;;; helm-cider-spec.el --- Helm interface to CIDER spec browser        -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2022 Tianxiang Xiong

;; Author: Tianxiang Xiong <tianxiang.xiong@gmail.com>

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

;; Helm interface to CIDER spec browser

;;; Code:

(require 'cider-client)
(require 'cl-lib)
(require 'helm-cider-util)
(require 'subr-x)


;;;; Customize

(defgroup helm-cider-spec nil
  "Helm interface to CIDER spec browser."
  :prefix "helm-cider-spec-"
  :group 'helm-cider
  :tag "Helm CIDER Spec")

(defcustom helm-cider-spec-ns-compare-fn
  #'helm-cider-spec--ns-compare-fn
  "Function to compare spec namespaces for sorting.

Comparison function takes two arguments, ns-1 and ns-2.  If ns-1
< ns-2, it appears earlier as a Helm source in `helm-cider-spec'
and candidate in `helm-cider-spec-ns'."
  :group 'helm-cider-spec
  :type 'function)

(defcustom helm-cider-spec-ns-key "C-c n"
  "String representation of key sequence for executing
`helm-cider-spec-ns'.

This is intended to be added to the keymap for
`helm-cider-spec-symbol'."
  :group 'helm-cider-spec
  :type 'key-sequence)

(defcustom helm-cider-spec-follow nil
  "If non-nil, turn on `helm-follow-mode' for CIDER specs."
  :group 'helm-cider-spec
  :type 'boolean)

(defcustom helm-cider-spec-actions
  (helm-make-actions
   "View spec" #'cider-browse-spec--browse)
  "Actions for Helm CIDER specs."
  :group 'helm-cider-spec
  :type '(alist :key-type string :value-type function))

(defcustom helm-cider-spec-ns-actions
  (helm-make-actions
   "Search in namespace" #'helm-cider-spec-symbol)
  "Actions for Helm CIDER spec namespaces."
  :group 'helm-cider-spec
  :type '(alist :key-type string :value-type function))


;;;; Spec

(defun helm-cider-spec--hashtable (spec-names)
  "Build a hash table from list of SPECS-NAMES.

Keys are kw namespaces and values are lists of names."
  (let ((ht (make-hash-table :test #'equal)))
    (dolist (name spec-names)
      (let ((ns (helm-cider--symbol-ns name)))
        (puthash ns (cons name (gethash ns ht)) ht)))
    (cl-loop
       for ns being the hash-keys of ht
       using (hash-value names)
       do (setf (gethash ns ht) (sort names #'string<))
       finally (return ht))))

(defun helm-cider-spec--candidate (spec-name)
  "Create a Helm CIDER spec candidate.

SPEC-NAME is a spec keyword string."
  (cons (propertize (helm-cider--symbol-name spec-name)
                    'face 'clojure-keyword-face)
        spec-name))

(defvar helm-cider-spec--map
  (let ((keymap (copy-keymap helm-map)))
    ;; Select ns
    (define-key keymap (kbd helm-cider-spec-ns-key)
      (lambda ()
        (interactive)
        (helm-exit-and-execute-action (lambda (candidate)
                                        (helm-cider-spec-ns candidate)))))
    keymap)
  "Keymap for use with `helm-cider-spec'.")

(defun helm-cider-spec--persistent-action (candidate)
  "Persistent action for Helm CIDER apropos."
  (if (and (helm-attr 'spec-lookup-p)
           (string= candidate (helm-attr 'current-candidate)))
      (progn
        (kill-buffer cider-browse-spec-buffer)
        (helm-attrset 'spec-lookup-p nil))
    (cider-browse-spec--browse candidate)
    (helm-attrset 'spec-lookup-p t))
  (helm-attrset 'current-candidate candidate))

(defun helm-cider-spec--source (ns spec-names &optional follow)
  "Helm source for specs in namespace NS.

SPEC-NAMES is a list of spec keywords strings."
  (helm-build-sync-source ns
    :action helm-cider-spec-actions
    :candidates (mapcar #'helm-cider-spec--candidate spec-names)
    :follow (when follow 1)
    :keymap helm-cider-spec--map
    :nomark t
    :persistent-action #'helm-cider-spec--persistent-action
    :persistent-help "View spec"
    :volatile t))

(defun helm-cider-spec--ns-compare-fn (ns-1 ns-2)
  "Function to compare spec namespaces NS-1 and NS-2.

Namespaces are compared as symbols, without keywords' leading
colons."
  (let ((ns-1 (replace-regexp-in-string "^:" "" ns-1))
        (ns-2 (replace-regexp-in-string "^:" "" ns-2)))
    (string< ns-1 ns-2)))

(defun helm-cider-spec--sources (&optional spec-names)
  "A list of Helm sources specs.

Each source is the set specs in a namespace.

Optional argument SPEC-NAMES is a list of spec keyword strings.
If not supplied, it is retrieved with
`cider-sync-request:spec-list'."
  (cl-loop
     with ht = (helm-cider-spec--hashtable (or spec-names
                                               (cider-sync-request:spec-list "")))
     for ns being the hash-keys in ht using (hash-value names)
     collect (helm-cider-spec--source ns names helm-cider-spec-follow)
     into sources
     finally (return (cl-sort sources helm-cider-spec-ns-compare-fn
                              :key (lambda (source) (assoc-default 'name source))))))

(defun helm-cider-spec--all-ns ()
  "Return a list of all spec namespace strings.

E.g. '(\":ring.async.handler\", \":ring.core\", ...)."
  (let ((nss (thread-last (cider-sync-request:spec-list "")
               (mapcar #'helm-cider--symbol-ns))))
    (cl-delete-duplicates nss :test #'equal)))

(defun helm-cider-spec--propertize-ns (ns)
  "Propertize a spec namespace NS.

I.e. how `:foo' would be propertized in `:foo/bar' in
`clojure-mode'.

It is also possible for a spec ns to be a regular symbol
instead of keyword, as with `clojure.core'."
  (if (string-prefix-p ":" ns)
      (concat (propertize (substring ns 0 1)
                          'face 'clojure-keyword-face)
              (propertize (substring ns 1)
                          'face 'font-lock-type-face))
    (propertize ns 'face 'font-lock-type-face)))

(defun helm-cider-spec--ns-source (&optional follow)
  "Helm source of namespaces.

Namespaces in EXCLUDED-NS are excluded.  If not supplied,
`helm-cider-apropos-excluded-ns' is used.

If FOLLOW is true, use function `helm-follow-mode' for source."
  (helm-build-sync-source "Clojure Spec Namespaces"
    :action helm-cider-spec-ns-actions
    :candidates (cl-loop
                   for ns in (helm-cider-spec--all-ns)
                   collect (helm-cider-spec--propertize-ns ns) into all
                   finally (return (sort all helm-cider-spec-ns-compare-fn)))
    :follow (when follow 1)
    :nomark t
    :persistent-action #'ignore
    :volatile t))

(defun helm-cider-spec--resolve-name (&optional ns name)
  "Try to get correct values for NS and NAME.

NS is a spec keyword ns, e.g. \":ring.core\". NAME is a spec
keyword name, e.g. \"error\"."
  (let* ((name (or name (unless ns (cider-symbol-at-point))))
         (qualified (when name
                      (or (cider-namespace-qualified-p name)
                          (string-match-p "^::" name))))
         (ns (cond (qualified (if (string-match-p "^::" name)
                                  (cider-current-ns)
                                (helm-cider--symbol-ns name)))
                   (t ns))))
    (list ns (if qualified
                 (helm-cider--symbol-name name)
               name))))


;;;; API

;;;###autoload
(defun helm-cider-spec-symbol (&optional ns name)
  "Choose Clojure specs across namespaces.

Each Helm source is a Clojure namespace (ns), and candidates are
spec keywords in the namespace.

If both NS and NAME are supplied, puts selection line on
first NAME of NS.

If NS is supplied, puts the selection line on the first
candidate of source with name NS.

If NAME is supplied, puts the selection line on the
first candidate matching NAME.

Set `helm-cider-spec-follow' to non-nil to turn on function
`helm-follow-mode' for all sources.  This is useful for quickly
viewing specs."
  (interactive)
  (cider-ensure-connected)
  (cl-multiple-value-bind (ns name) (helm-cider-spec--resolve-name ns name)
    (let ((name (when name
                  (helm-cider--regexp-symbol name))))
      (with-helm-after-update-hook
        (with-helm-buffer
          (let ((helm--force-updating-p t))
            (if name
                (helm-preselect name (helm-cider--source-by-name ns))
              (helm-goto-source (or ns ""))
              (when ns
                (helm-next-line)))
            (recenter 1))))
      (helm :buffer "*Helm Clojure Specs*"
            :candidate-number-limit 9999
            :sources (helm-cider-spec--sources)))))

;;;###autoload
(defun helm-cider-spec-ns (&optional kw-ns-or-qualified-name)
  "Choose spec namespace to call `helm-cider-browse-spec' on.

KW-NS-OR-QUALIFIED-NAME is a spec keyword namespace
 (e.g. \":ring.core\") or a qualified keyword
name (e.g. \":ring.core/error\").  If supplied, it is used as the
default selection."
  (interactive)
  (cider-ensure-connected)
  (helm :buffer "*Helm Clojure Spec Namespaces*"
        :candidate-number-limit 9999
        :preselect (thread-first (or kw-ns-or-qualified-name "")
                     helm-cider--symbol-ns
                     helm-cider--regexp-symbol)
        :sources (helm-cider-spec--ns-source)))

;;;###autoload
(defun helm-cider-spec (&optional arg)
  "Helm interface to CIDER specs.

If ARG is raw prefix argument \\[universal-argument]
\\[universal-argument], choose namespace before symbol."
  (interactive "P")
  (cond ((equal arg '(4)) (helm-cider-spec-ns))
        (t (helm-cider-spec-symbol))))



(provide 'helm-cider-spec)

;;; helm-cider-spec.el ends here
