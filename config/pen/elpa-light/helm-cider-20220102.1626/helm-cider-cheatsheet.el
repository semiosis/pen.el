;;; helm-cider-cheatsheet.el --- Helm interface to CIDER cheatsheet -*- lexical-binding: t; -*-

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

;; Helm interface to CIDER cheatsheet.

;; Mostly taken from Kris Jenkins' `clojure-cheatsheet'
;; See: https://github.com/clojure-emacs/clojure-cheatsheet

;;; Code:

(require 'cider)
(require 'cider-cheatsheet)
(require 'cl-lib)
(require 'helm)
(require 'helm-multi-match)
(require 'helm-cider-util)


;;;; Helpers

(defvar helm-cider-cheatsheet--jacked-in-source-p nil
  "Non-nil `helm-cider-cheatsheet--source' was evaluated while
CIDER was jacked in.

When loading this package at init, CIDER is not jacked in.  Some
font-locking etc. are then not available.

When calling `helm-cider-cheatsheet', if this var is nil and
CIDER is connected, the source is re-evaluated to obtain the
additional information.")

(defun helm-cider-cheatsheet--treewalk (before after node)
  "Walk a tree.
Invoke BEFORE before the walk, and AFTER after it, on each NODE."
  (thread-last node
    (funcall before)
    (funcall (lambda (new-node)
               (if (listp new-node)
                   (mapcar (lambda (child)
                             (helm-cider-cheatsheet--treewalk before after child))
                           new-node)
                 new-node)))
    (funcall after)))

(defun helm-cider-cheatsheet--symbol-qualifier (namespace symbol)
  "Given a (Clojure) NAMESPACE and a SYMBOL, fully-qualify that symbol."
  (intern (format "%s/%s" namespace symbol)))

(defun helm-cider-cheatsheet--string-qualifier (head subnode)
  (cond
    ((keywordp (car subnode)) (list head subnode))
    ((symbolp (car subnode)) (cons head subnode))
    ((stringp (car subnode)) (cons (format "%s : %s" head (car subnode))
                                   (cdr subnode)))
    (t (mapcar (apply-partially 'helm-cider-cheatsheet--string-qualifier head) subnode))))

(defun helm-cider-cheatsheet--propagate-headings (node)
  (helm-cider-cheatsheet--treewalk
   #'identity
   (lambda (item)
     (if (listp item)
         (cl-destructuring-bind (head &rest tail) item
           (cond ((equal :special head) tail)
                 ((keywordp head) item)
                 ((symbolp head) (mapcar (apply-partially #'helm-cider-cheatsheet--symbol-qualifier head) tail))
                 ((stringp head) (mapcar (apply-partially #'helm-cider-cheatsheet--string-qualifier head) tail))
                 (t item)))
       item))
   node))

(defun helm-cider-cheatsheet--flatten (node)
  "Flatten NODE, which is a tree structure, into a list of its leaves."
  (cond
    ((not (listp node)) node)
    ((keywordp (car node)) node)
    ((listp (car node)) (apply 'append (mapcar 'helm-cider-cheatsheet--flatten node)))
    (t (list (mapcar 'helm-cider-cheatsheet--flatten node)))))

(defun helm-cider-cheatsheet--group-by-head (data)
  "Group the DATA, which should be a list of lists, by the head of each list."
  (let ((result '()))
    (dolist (item data result)
      (let* ((head (car item))
             (tail (cdr item))
             (current (cdr (assoc head result))))
        (if current
            (setf (cdr (assoc head result))
                  (append current tail))
          (setq result (append result (list item))))))))

(defvar helm-cider-cheatsheet--ns-mappings
  '(("clojure.core" . "")
    ("clojure.core.async" . "async")
    ("clojure.data" . "data")
    ("clojure.data.zip.xml" . "zip.xml")
    ("clojure.edn" . "edn")
    ("clojure.java.browse" . "browse")
    ("clojure.java.io" . "io")
    ("clojure.java.javadoc" . "javadoc")
    ("clojure.java.shell" . "shell")
    ("clojure.pprint" . "pprint")
    ("clojure.repl" . "repl")
    ("clojure.set" . "set")
    ("clojure.spec.alpha" . "s")
    ("clojure.string" . "str")
    ("clojure.test" . "test")
    ("clojure.walk" . "walk")
    ("clojure.xml" . "xml")
    ("clojure.zip" . "zip")))

(defun helm-cider-cheatsheet--shorten-ns (ns)
  (or (assoc-default ns helm-cider-cheatsheet--ns-mappings) ns))

(defun helm-cider-cheatsheet--item-to-helm-source (item &optional apropos-ht)
  "Turn ITEM, which will be (\"HEADING\" candidates...), into a helm-source.

APROPOS-HT is a hash-table of (NAME APROPOS-DICT) entries."
  (cl-destructuring-bind (heading &rest entries) item
    (helm-build-sync-source heading
      :action helm-cider--doc-actions
      :candidates (cl-loop
                     for s in (mapcar #'symbol-name entries)
                     for ns = (helm-cider--symbol-ns s)
                     for name = (helm-cider--symbol-name s)
                     for face = (when apropos-ht
                                  (thread-first (gethash s apropos-ht)
                                    (nrepl-dict-get "type")
                                    helm-cider--symbol-face))
                     for propertized-s = (let ((short-ns (helm-cider-cheatsheet--shorten-ns ns))
                                               (propertized-name (if face (cider-propertize name face) name)))
                                           (if (string-empty-p short-ns)
                                               propertized-name
                                             (concat (cider-propertize short-ns 'ns) "/" propertized-name)))
                     collect (cons propertized-s s) into candidates
                     finally return (cl-sort candidates #'string< :key #'car))
      :match (lambda (candidate)
               (helm-mm-3-match (format "%s %s" candidate heading)))
      :persistent-action #'helm-cider--doc-lookup-persistent-action
      :persistent-help "Look up documentation")))

(defun helm-cider-cheatsheet--make-source (&optional hierarchy)
  (let ((ht (when (cider-connected-p)
              (let ((ht (make-hash-table :test 'equal)))
                (dolist (dict (cider-sync-request:apropos ""))
                  (puthash (nrepl-dict-get dict "name") dict ht))
                ht))))
    (thread-last (or hierarchy cider-cheatsheet-hierarchy)
      helm-cider-cheatsheet--propagate-headings
      helm-cider-cheatsheet--flatten
      helm-cider-cheatsheet--group-by-head
      (mapcar (lambda (x) (helm-cider-cheatsheet--item-to-helm-source x ht))))))

(defvar helm-cider-cheatsheet--source
  (helm-cider-cheatsheet--make-source)
  "Helm source for `helm-cider-cheatsheet.'")


;;;; API

;;;###autoload
(defun helm-cider-cheatsheet ()
  "Use Helm to show a Clojure cheatsheet."
  (interactive)
  (helm :buffer "*Helm CIDER Cheatsheet*"
        :sources (if (and (not helm-cider-cheatsheet--jacked-in-source-p)
                          (cider-connected-p))
                     (progn
                       (message "Preparing cheatsheet (this is only needed once after `cider-jack-in')...")
                       (setq helm-cider-cheatsheet--jacked-in-source-p t
                             helm-cider-cheatsheet--source (helm-cider-cheatsheet--make-source)))
                   helm-cider-cheatsheet--source)))


(provide 'helm-cider-cheatsheet)

;;; helm-cider-cheatsheet.el ends here
