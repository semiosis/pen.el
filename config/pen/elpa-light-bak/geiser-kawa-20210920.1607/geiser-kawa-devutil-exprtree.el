;;; geiser-kawa-devutil-complete.el --- get Kawa's Expression tree using kawa-devutil -*- lexical-binding:t -*-

;; Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>

;; SPDX-License-Identifier: BSD-3-Clause

;;; Commentary:
;; The Kawa language framework compilation works producing converting
;; code into an Expression tree and then compiling the latter into
;; Java bytecode.
;; Here are some functions for getting and viewing the Expression tree
;; that Kawa produces for some given code.

(require 'geiser-kawa-util)

;;; Code:

(defvar geiser-kawa-devutil-exprtree-buffer "*kawa exprtree*"
  "Buffer where Expression tree is showed.")

(defun geiser-kawa-devutil-exprtree--view (expr-tree)
  "View EXPR-TREE in a buffer in View-mode."
  (with-current-buffer (get-buffer-create
                        geiser-kawa-devutil-exprtree-buffer)
    (View-quit)
    (delete-region (point-min) (point-max))
    (insert expr-tree)
    (goto-char (point-min)))

  (view-buffer-other-window
   geiser-kawa-devutil-exprtree-buffer))

(defun geiser-kawa-devutil-exprtree--for (code-str)
  "Get the Expression tree for CODE-STR."
  (geiser-kawa-util--eval-get-result
   `(geiser:kawa-devutil-expr-tree-formatted ,code-str)))

(defun geiser-kawa-devutil-exprtree--view-for (code-str)
  "Get and view Expression tree for CODE-STR."
  (geiser-kawa-devutil-exprtree--view
   (geiser-kawa-devutil-exprtree--for
    code-str)))

(defun geiser-kawa-devutil-exprtree-region (reg-beg reg-end)
  "View Exprtree for region.
Argument REG-BEG is beginning of region.
Argument REG-END is end of region."
  (interactive "r")
  (let ((code-str (buffer-substring-no-properties
                   reg-beg reg-end)))
    (geiser-kawa-devutil-exprtree--view-for code-str)))

(defun geiser-kawa-devutil-exprtree-last-sexp ()
  "View Exprtree for sexp before (point)."
  (interactive)
  (let ((code-str
         (save-excursion
           (let ((sexp-beg (progn (backward-sexp) (point)))
                 (sexp-end (progn (forward-sexp) (point))))
             (buffer-substring-no-properties sexp-beg sexp-end)))))
    (geiser-kawa-devutil-exprtree--view-for code-str)))

(provide 'geiser-kawa-devutil-exprtree)

;;; geiser-kawa-devutil-exprtree.el ends here
