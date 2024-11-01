;;; company-web-jade.el --- company for jade-mode

;; Copyright (C) 2015 Olexandr Sydorchuck

;; Author: Olexandr Sydorchuck <olexandr.syd@gmail.com>
;; Keywords: jade, company, auto-complete, javascript

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

;; Configuration:
;;

;;; Code:

(require 'company-web)

(defconst company-web-jade-get-tag-re
  (concat "^[\t ]*\\(" company-web-selector "+\\)[.#(]")
  "Regexp of jade attribute or tag")

(defconst company-web-jade-get-attribute-re
  (concat "[^[:alnum:]-]\\(" company-web-selector "+\\) *=")
  "Regexp of jade attribute or tag")

(defun company-web-jade-current-tag ()
  "Return current jade tag user is typing on."
  (save-excursion
    (re-search-backward company-web-jade-get-tag-re nil t)
    (match-string 1)))

(defun company-web-jade-current-attribute ()
  "Return current jade tag's attribute user is typing on."
  (save-excursion
    (re-search-backward company-web-jade-get-attribute-re nil t)
    (match-string 1)))

(defconst company-web-jade-id-regexp
  (concat
   ;; tag or nil(div)
   "^ *\\(" company-web-selector "+\\|\\)"
   ;; classes ?
   "[.[:alnum:]-]*"
   ;; id?
   "#\\(" company-web-selector "*\\|\\)")

  "A regular expression matching Jade #idofdiv:

  #bar -> <div id=\"bar\">
or
  span#bar -> <span id=\"bar\">
.")

(defconst company-web-jade-class-regexp
  (concat
   ;; tag or nil(div)
   "^ *\\(" company-web-selector "+\\|\\)"
   "[#.[:alnum:]-]*"
   ;; last class
   "[.]\\(" company-web-selector "*\\)")

  "A regular expression matching Jade div's class:

  .foo -> <div class=\"foo\">
or
  span.foo
or
  #foo.baz -> <div id=\"foo\" class=\"baz\">
or
  span#foo.baz.bar
.")

(defconst company-web-jade-tag-regexp
  (concat "^[\t ]*\\(" company-web-selector "*\\)")
  "A regular expression matching Jade tags.")

(defconst company-web-jade-attribute-regexp
  (concat "\\(?:,\\|(\\)[ ]*\\(.*\\)")
  "A regular expression matching Jade attribute.")

(defconst company-web-jade-value-regexp
  (concat "\\w *= *[\"']\\(?:[^\"']+[ ]\\|\\)"
          ;; catch value
          "\\([^\"']*\\)")
  "A regular expression matching Jade attribute.")

;;;###autoload
(defun company-web-jade (command &optional arg &rest ignored)
  "`company-mode' completion back-end for `jade-mode'."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-web-jade))
    (ignore-case t)
    (duplicates nil)
    (prefix (let ((bound (company-web-backward-min-tag-bound)))
              (and (or (derived-mode-p 'jade-mode)
                       (derived-mode-p 'pug-mode))
                   (or (company-grab company-web-jade-value-regexp 1 bound)
                       (company-grab company-web-jade-tag-regexp 1 bound)
                       (company-grab company-web-jade-id-regexp 2 bound)
                       (company-grab company-web-jade-class-regexp 2 bound)
                       (company-grab company-web-jade-attribute-regexp 1 bound)))))

    (candidates
     (let ((bound (company-web-backward-min-tag-bound)))
       (cond
        ;; value
        ((company-grab company-web-jade-value-regexp 1 bound)
         (all-completions arg (company-web-candidates-attrib-values (company-web-jade-current-tag)
                                                                    (company-web-jade-current-attribute)
                                                                    bound)))
        ;; class ".foo" or id "#bar"
        ((and (not (company-web-is-point-in-string-face))
              (company-grab company-web-jade-id-regexp 1 bound))
         (let ((tag (company-grab company-web-jade-id-regexp 1 bound)))
           (if (string= "" tag)
               (setq tag "div"))
           (all-completions arg (company-web-candidates-attrib-values tag "id" bound))))

        ((company-web-grab-not-in-string company-web-jade-class-regexp 1 bound)
         (let ((tag (company-grab company-web-jade-class-regexp 1 bound)))
           (if (string= "" tag)
               (setq tag "div"))
           (all-completions arg (company-web-candidates-attrib-values tag "class" bound))))

        ;; tag
        ((company-web-grab-not-in-string company-web-jade-tag-regexp 1 bound)
         (all-completions arg (company-web-candidates-tags)))
        ;; attr
        ((company-web-grab-not-in-string company-web-jade-attribute-regexp 1 bound)
         (all-completions arg (company-web-candidates-attribute (company-web-jade-current-tag)))))))

    (annotation (company-web-annotation arg))

    (doc-buffer
     (let ((bound (company-web-backward-min-tag-bound)))
       (cond
        ((or (company-web-grab-not-in-string company-web-jade-id-regexp 1 bound)
             (company-web-grab-not-in-string company-web-jade-class-regexp 2 bound)
             (company-grab company-web-jade-value-regexp 1 bound))
         (company-web-candidate-prop-doc arg))
        ;; tag
        ((company-grab company-web-jade-tag-regexp 1 bound)
         (company-web-tag-doc arg))
        ;; attr
        ((company-grab company-web-jade-attribute-regexp 1 bound)
         (company-web-attribute-doc (company-web-jade-current-tag) arg)))))))

(provide 'company-web-jade)
;;; company-web-jade.el ends here
