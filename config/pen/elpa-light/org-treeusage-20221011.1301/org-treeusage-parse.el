;;; org-treeusage-parse.el --- Main parsing library for org -*- lexical-binding: t; -*-

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
(require 'org-element)

(defvar-local org-treeusage-parse--prntalist nil
  "List of (level . heading) parent nodes.
Popped from and pushed to, as the org file is parsed.")

(defvar-local org-treeusage-parse--hashmap nil)

(defun org-treeusage-parse--gettitlebounds (info)
  "Get header title and the bounding positions from org element INFO."
  (let ((head (or (plist-get info :raw-value) (plist-get info :title)))
        (bend (plist-get info :contents-begin))
        (bbeg (line-beginning-position)))
    (when head
      (save-excursion
        (goto-char bbeg) ;; important
        (let* ((end (or (search-forward-regexp
                         (shell-quote-argument head) bend t)
                        ;; search using regexp, failing that use normal
                        (search-forward head bend)))
               (beg (progn (search-backward-regexp "^\\*+ " bbeg)
                           (match-end 0))))
          (cons head (cons beg end)))))))

(defun org-treeusage-parse--makeroot (hashmap)
  "Generate the initial root parent node by getting the full bounds of the whole org file and inserting them into the HASHMAP."
  (let* ((pend (progn (goto-char (point-max))
                      (org-backward-sentence)
                      (point)))
         (pbeg (progn (goto-char 0)
                      (org-next-visible-heading 1)
                      (point))))
    (let ((dchar (- pend pbeg))
          (dline (count-lines pbeg pend))
          (dword (count-words pbeg pend))
          (dkey (cons 0 nil))) ;; make key: level title
      (move-beginning-of-line 0)
      (puthash dkey
               (list :nlines dline :nchars dchar :nwords dword)
               hashmap)
      dkey)))


(defun org-treeusage-parse--updateparents (lvl-now previousk)
  "Get the parent of the current node at LVL-NOW, and update the parent if the current node deviates from the previous node PREVIOUSK."
  (let ((prev-lvl (car previousk))
        (prev-hdr (cdr previousk))
        (curr-parent (car org-treeusage-parse--prntalist)))
    (cond ((not prev-lvl)
           curr-parent)
          ((> lvl-now prev-lvl)
           ;; Gone N level's deep, push the last
           ;; heading as the new parent at level
           (car (push (cons prev-lvl prev-hdr)  ;; make key: level title
                      org-treeusage-parse--prntalist)))
          ;;
          ((< lvl-now prev-lvl)
           ;; Returned to a level up. Pop all levels up to.
           (while (>= (caar org-treeusage-parse--prntalist) lvl-now)
             (pop org-treeusage-parse--prntalist))
           (car org-treeusage-parse--prntalist))
          (t curr-parent))))

(defun org-treeusage-parse--gethashmap (&optional reusemap)
  "Retrieve or generate hashmap.  If REUSEMAP is:
* nil :: Lformat changed, use existing hashmap
*  -1 :: Mode initialise, delete hashmap
* any :: Head expa/contr, update the hashmap from point."
  (let ((noexist (not org-treeusage-parse--hashmap)))
    (cond ((eq reusemap nil) org-treeusage-parse--hashmap)
          ((or (eq reusemap -1) noexist)
           (progn (message "Regenerating.")
                  (org-treeusage-parse--processvisible t)))
          (t (progn (message "Updating from point.")
                    (org-treeusage-parse--processvisible nil (point)))))))

(defun org-treeusage-parse--processvisible (&optional clearmap startpos)
  "Parse the visible org headings in the current buffer, and calculate\
percentages.  Set `org-treeusage-parse--hashmap'.  If CLEARMAP, clear the\
hashtable and do not re-use it.  If STARTPOS, assume that we are processing\
only the current heading and any children, stop once the parent changes."
  (save-excursion
    (setq-local org-treeusage-parse--prntalist nil) ;; clear parent list
    (let ((gettitle #'org-treeusage-parse--gettitlebounds)
          (up-parent #'org-treeusage-parse--updateparents)
          (hasher (if clearmap (make-hash-table :test 'equal)
                    org-treeusage-parse--hashmap))
          (calcperc (lambda (c p) (/ (float (* 100 c)) p)))
          (prnt-curr nil) (prev-key nil))
      (push (if startpos                              ;; Set current position
                (--> (cadr (org-element-at-point))    ;; as parent if exists
                     (cons (plist-get it :level)
                           (car (funcall gettitle it))))
              (org-treeusage-parse--makeroot hasher)) ;; Or jump to BOF
            org-treeusage-parse--prntalist)
      (while (let ((prevpnt (point)))
               (progn (org-next-visible-heading 1)  ;; org-next-vis always
                      (not (eq prevpnt (point)))))  ;; returns nil
        (let* ((info (cadr (org-element-at-point)))
               (level (plist-get info :level))
               (bound (funcall gettitle info))
               (head (car bound)) (hrng (cdr bound))
               (elkey (cons level head))
               (elhash (gethash elkey hasher)))
          (if elhash
              ;; If data set from a previous run, then this must be
              ;; an update operation, so tell the overlay setter to skip
              (plist-put (gethash elkey hasher) :overlay-already t)
            (when head
              ;; Set parent, regardless of whether if it already exists.
              (setq prnt-curr (funcall up-parent level prev-key))
              (if (and startpos (not prnt-curr)) ;; no parent? break.
                  (goto-char (point-at-eol))
                (let* ((parent (gethash prnt-curr hasher))
                       (posbeg (plist-get info :begin))
                       (posend (plist-get info :end))
                       (dchar (- posend posbeg))
                       (dline (count-lines posbeg posend))
                       (dword (count-words posbeg posend)))
                  (let ((pchar (funcall calcperc dchar
                                        (plist-get parent :nchars)))
                        (pline (funcall calcperc dline
                                        (plist-get parent :nlines)))
                        (pword (funcall calcperc dword
                                        (plist-get parent :nwords))))
                    (puthash elkey ;; Make values: plist
                             (list :nlines dline :nchars dchar :nwords dword
                                   :plines pline :pchars pchar :pwords pword
                                   :bounds hrng)
                             hasher))))))
          (setq prev-key elkey)))
      (setq-local org-treeusage-parse--hashmap hasher))))

(provide 'org-treeusage-parse)
;;; org-treeusage-parse.el ends here
