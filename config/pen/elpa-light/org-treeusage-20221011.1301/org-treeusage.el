;;; org-treeusage.el --- Examine the usage of org headings in a tree-like manner -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Mehmet Tekman <mtekman89@gmail.com>

;; Author: Mehmet Tekman
;; URL: https://github.com/mtekman/org-treeusage.el
;; Keywords: outlines
;; Package-Requires: ((emacs "26.1") (dash "2.17.0") (org "9.1.6"))
;; Version: 0.4

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; A minor mode to show the line or character density of org-mode files.
;; The main motivation was to help in the archiving and arrangement of
;; very large org files that might have some redundant data still in it.

;;; Code:
(require 'org-treeusage-overlay)

(defgroup org-treeusage nil
  "Customisation group for org-treeusage."
  :group 'org)

(defun org-treeusage--printstats ()
  "Print stats for each heading, indenting at every level.
Useful mostly for debugging."
  (let ((ntype (intern (format ":n%s" org-treeusage-cycle--difftype)))
        (ptype (intern (format ":p%s" org-treeusage-cycle--difftype)))
        (neubff (get-buffer-create "org-treeusage-summary.txt")))
    (maphash
     (lambda (head info)
       (let ((indent (make-string (* 4 (car head)) ? ))
             (header (or (cdr head) "{root}"))
             (ndiffs (or (plist-get info ntype) 0))
             (percnt (or (plist-get info ptype) 100)))
         (with-current-buffer neubff
           (insert
            (format "\n;;%s %3.0f -- %s {%d}"
                    indent percnt header ndiffs)))))
     (org-treeusage-parse--processvisible))))


(defvar org-treeusage--modebind
  (let ((map (make-sparse-keymap)))
    ;; Don't inherit from parent (read-only-mode)
    (define-key map (kbd ",") 'org-treeusage-cycle-modebackward)
    (define-key map (kbd ".") 'org-treeusage-cycle-modeforward)
    (define-key map (kbd "l") 'org-treeusage-cycle-cycletype)
    (define-key map (kbd "<return>") 'org-treeusage-mode)
    (define-key map (kbd "q") 'org-treeusage-mode)
    map)
  "Keymap for minor mode.")

(define-minor-mode org-treeusage-mode
  "The minor mode for org-treeusage."
  nil
  " tu"
  org-treeusage--modebind
  (if (string-suffix-p ".org" (buffer-file-name))
      (if org-treeusage-mode
          (progn (setq buffer-read-only t)
                 (add-hook 'org-cycle-hook #'org-treeusage-overlay--setall)
                 (org-treeusage-overlay--setall -1) ;; regenerate (-1)
                 (org-treeusage-overlay--setheader t))
        (setq buffer-read-only nil)
        (remove-hook 'org-cycle-hook #'org-treeusage-overlay--setall)
        (org-treeusage-overlay--clear)
        (org-treeusage-overlay--setheader nil))
    (message "Not an org file.")))

(add-hook 'org-treeusage-cycle--publichook #'org-treeusage-overlay--setall)

(provide 'org-treeusage)
;;; org-treeusage.el ends here
