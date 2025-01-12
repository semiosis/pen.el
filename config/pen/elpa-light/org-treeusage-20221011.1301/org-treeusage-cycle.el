;;; org-treeusage-cycle.el --- Cycle or toggle line formats -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Mehmet Tekman <mtekman89@gmail.com>

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

;; See org-treeusage.el

;;; Code:
(require 'cl-lib)

(defcustom org-treeusage-cycle-formats
  '((barname . "%1$-5s |%7$s")
    (bardiffname . "%1$s%3$-5d|%7$s")
    (barpercdiffname . "%1$-5s |%2$5.1f%%|%3$-5d|%7$s")
    (percname . "%2$5.1f%%|%7$s")
    (diffname . "%3$d|%7$s")
    (barpercdiffallname . "%1$-5s |%2$5.1f%%|l%4$-3d w%5$-4d c%6$-5d|%7$s")
    (bardiffperc . "%1$-5s |%3$d|%2$5.1f%%")
    (bardiff . "%1$s%3$d")
    (bar . "%1$-5s")
    (perc . "%2$5.1f%%")
    (diff . "%3$d"))
  "Specify different formats to represent the line or character density.\
Some are given here as examples.  The first is the default used on\
 startup.  Bands are given by `org-treeusage-percentlevels' variable, and\
 the current difftype is given as `org-treeusage-cycle--difftype'.  The\
 format takes 6 positional arguments:
     1. A string representing the percentage band for the current diff type.
     2. A float showing the current percentage for current diff type.
     3. An integer showing the absolute diff type amount.
 4,5,6. An integer showing the current values for lines, words, chars.
     7. A string with the title of the headline."
  :type 'alist
  :group 'org-treeusage)

(defvar-local org-treeusage-cycle--currentmode 'barpercdiffname
  "Current line format.  Default is bar.")

(defvar-local org-treeusage-cycle--difftype 'lines
  "Current diff type.  Strictly either `lines', `chars', or `words'.")

(defvar org-treeusage-cycle--publichook nil
  "Hook to run at the end of an interactive function.")

(defun org-treeusage-cycle--runpublichook (&optional arg)
  "Run the public finish hook, and pass ARG."
  (run-hook-with-args 'org-treeusage-cycle--publichook arg))

(defun org-treeusage-cycle--usermodes (forw)
  "Cycle line formats forward if FORW, otherwise backwards."
  (let* ((oh-cm org-treeusage-cycle--currentmode)
         (oh-fm (mapcar #'car org-treeusage-cycle-formats))
         (direc (if forw 1 -1))
         (curr-index (cl-position oh-cm oh-fm))
         (next-index (mod (+ curr-index direc) (length oh-fm)))
         (next-umode (nth next-index oh-fm)))
    (setq-local org-treeusage-cycle--currentmode next-umode)
    ;; nil argument does not regenerate hashmap
    (org-treeusage-cycle--runpublichook)
    (message "Mode: %s" next-umode)))

;;;###autoload
(defun org-treeusage-cycle-modeforward ()
  "Cycle line formats forwards."
  (interactive)
  (org-treeusage-cycle--usermodes t))

;;;###autoload
(defun org-treeusage-cycle-modebackward ()
  "Cycle line formats backwards."
  (interactive)
  (org-treeusage-cycle--usermodes nil))

;;;###autoload
(defun org-treeusage-cycle-cycletype ()
  "Cycle the diff type between `lines', `chars', or `words'."
  (interactive)
  (let* ((types '(lines chars words))
         (cmode org-treeusage-cycle--difftype)
         (cindx (cl-position cmode types))
         (nindx (mod (1+ cindx) (length types)))
         (nmode (nth nindx types)))
    (setq-local org-treeusage-cycle--difftype nmode)
    ;; nil argument does not regenerate hashmap
    (org-treeusage-cycle--runpublichook)
    (message "Type: %s" nmode)))


(provide 'org-treeusage-cycle)
;;; org-treeusage-cycle.el ends here
