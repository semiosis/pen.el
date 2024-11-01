;;; company-web-slim.el --- company for slim-mode

;; Copyright (C) 2015 Olexandr Sydorchuck

;; Author: Olexandr Sydorchuck <olexandr.syd@gmail.com>
;; Keywords: slim, company, auto-complete, javascript

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

(defconst company-web-slim-get-tag-re
  (concat "^[\t ]*\\(" company-web-selector "+\\)")
  "Regexp of slim attribute or tag")

(defconst company-web-slim-get-attribute-re
  (concat "[^[:alnum:]-]\\(" company-web-selector "+\\) *=")
  "Regexp of slim attribute or tag")

(defun company-web-slim-current-tag ()
  "Return current slim tag user is typing on."
  (save-excursion
    (re-search-backward company-web-slim-get-tag-re nil t)
    (match-string 1)))

(defun company-web-slim-current-attribute ()
  "Return current slim tag's attribute user is typing on."
  (save-excursion
    (re-search-backward company-web-slim-get-attribute-re nil t)
    (match-string 1)))

(defconst company-web-slim-id-regexp
  (concat
   ;; tag or nil(div)
   "^ *\\(" company-web-selector "+\\|\\)"
   ;; classes ?
   "[.[:alnum:]-]*"
   ;; id?
   "#\\(" company-web-selector "*\\|\\)")

  "A regular expression matching Slim #id:

  #bar -> <div id=\"bar\">
or
  span#bar -> <span id=\"bar\">
.")

(defconst company-web-slim-class-regexp
  (concat
   ;; tag or nil(div)
   "^ *\\(" company-web-selector "+\\|\\)"
   "[#.[:alnum:]-]*"
   ;; last class
   "[.]\\(" company-web-selector "*\\)")

  "A regular expression matching Slim div's class:

  .foo -> <div class=\"foo\">
or
  span.foo
or
  #foo.baz -> <div id=\"foo\" class=\"baz\">
or
  span#foo.baz.bar
.")

(defconst company-web-slim-tag-regexp
  (concat "^[\t ]*\\(" company-web-selector "*\\)")
  "A regular expression matching Slim tags.")

(defconst company-web-slim-attribute-regexp
  (concat "\\(?:"                       ; attribute may start after tag and: "[", "(", "{"
          "[[({]"                       ;
          "\\|"                         ; or
          " +\\)"                       ; after whitespace
          "\\(" company-web-selector "*\\)")
  "A regular expression matching Slim attribute.")

(defconst company-web-slim-value-regexp
  (concat "\\w *= *[\"]\\(?:[^\"]+[ ]\\|\\)"
          ;; catch value
          "\\([^\"]*\\)")
  "A regular expression matching Slim attribute.")

;;;###autoload
(defun company-web-slim (command &optional arg &rest ignored)
  "`company-mode' completion back-end for `slim-mode'."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-web-slim))
    (ignore-case t)
    (duplicates nil)
    (prefix (let ((bound (company-web-backward-min-tag-bound)))
              (and (derived-mode-p 'slim-mode)
                   (or (company-grab company-web-slim-value-regexp 1 bound)
                       (company-grab company-web-slim-tag-regexp 1 bound)
                       (company-grab company-web-slim-id-regexp 2 bound)
                       (company-grab company-web-slim-class-regexp 2 bound)
                       (company-grab company-web-slim-attribute-regexp 1 bound)))))

    (candidates
     (let ((bound (company-web-backward-min-tag-bound)))
       (cond
        ;; value
        ((company-grab company-web-slim-value-regexp 1 bound)
         (all-completions arg (company-web-candidates-attrib-values (company-web-slim-current-tag)
                                                                    (company-web-slim-current-attribute)
                                                                    bound)))
        ;; class ".foo" or id "#bar"
        ((company-web-grab-not-in-string company-web-slim-id-regexp 1 bound)
         (let ((tag (company-grab company-web-slim-id-regexp 1 bound)))
           (if (string= "" tag)
               (setq tag "div"))
           (all-completions arg (company-web-candidates-attrib-values tag "id" bound))))
        ((company-web-grab-not-in-string company-web-slim-class-regexp 1 bound)
         (let ((tag (company-grab company-web-slim-class-regexp 1 bound)))
           (if (string= "" tag)
               (setq tag "div"))
           (all-completions arg (company-web-candidates-attrib-values tag "class" bound))))
        ;; tag
        ((company-web-grab-not-in-string company-web-slim-tag-regexp 1 bound)
         (all-completions arg (company-web-candidates-tags)))
        ;; attr
        ((company-web-grab-not-in-string company-web-slim-attribute-regexp 1 bound)
         (all-completions arg (company-web-candidates-attribute (company-web-slim-current-tag)))))))

    (annotation (company-web-annotation arg))

    (doc-buffer
     (let ((bound (company-web-backward-min-tag-bound)))
       (cond
        ((or (company-web-grab-not-in-string company-web-slim-id-regexp 1 bound)
             (company-web-grab-not-in-string company-web-slim-class-regexp 2 bound)
             (company-grab company-web-slim-value-regexp 1 bound))
         (company-web-candidate-prop-doc arg))
        ;; tag
        ((company-grab company-web-slim-tag-regexp 1 bound)
         (company-web-tag-doc arg))
        ;; attr
        ((company-grab company-web-slim-attribute-regexp 1 bound)
         (company-web-attribute-doc (company-web-slim-current-tag) arg)))))))

(provide 'company-web-slim)
;;; company-web-slim.el ends here
