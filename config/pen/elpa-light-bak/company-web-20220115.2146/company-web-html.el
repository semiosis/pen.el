;;; company-web-html.el --- company for html-mode & web-mode

;; Copyright (C) 2015 Olexandr Sydorchuck

;; Author: Olexandr Sydorchuck <olexandr.syd@gmail.com>
;; Keywords: html, company, auto-complete

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

(defcustom company-web-html-emmet-enable t
  "Enable emmet specified completion when `emmet-mode' active."
  :group 'company-web
  :type 'boolean)

(defcustom company-web-html-emmet-preview-enable-advice t
  "Enable advice for `emmet-preview-accept'. This advice check for visibility of company popup
and call `company-complete-selection' if so.

You may want disable it when you remap emmet-mode key map and change RET behavior."
  :group 'company-web
  :type 'boolean)

;; html grabs
(defconst company-web-html-get-tag-re
  (concat "<[[:space:]]*\\(" company-web-selector "+\\)[[:space:]]")
  "Regexp of html tag")

(defconst company-web-html-get-attribute-re
  (concat "<[[:space:]]*\\(" company-web-selector "+\\)[^>]*"
          "[^[:alnum:]>_-]\\(" company-web-selector "+\\)=")
  "Regexp of html attribute")

(defun company-web-html-current-tag ()
  "Return current html tag user is typing on."
  (let ((bound (save-excursion
                 (if (re-search-backward ">" (company-web-backward-min-tag-bound) t)
                     (point)
                   (company-web-backward-min-tag-bound)))))
    (save-excursion
      (if (re-search-backward company-web-html-get-tag-re bound t)
          (cons (match-string-no-properties 1) (point))
        (cons nil (point))))))

(defun company-web-html-current-attribute (bound)
  "Return current html tag's attribute user is typing on."
  (save-excursion
    (re-search-backward company-web-html-get-attribute-re bound t)
    (match-string-no-properties 2)))

(defconst company-web-html-tag-regexp
  (concat "<[[:space:]]*\\("
          company-web-selector
          "*\\)")
  "A regular expression matching HTML tags.")

(defconst company-web-html-attribute-regexp
  (concat "<[[:space:]]*" company-web-selector "[^>]*[[:space:]]+\\(.*\\)")
  "A regular expression matching HTML attribute.")

(defconst company-web-html-value-regexp
  (concat "\\w=[\"']\\(?:[^\"']+[ ;:]\\|\\)"
          ;; catch value
          "\\([^\"']*\\)")
  "A regular expression matching HTML attribute.")

;; emmet grabs
(defconst company-web-html-emmet-tag-separator
  "\\(?:^\\|[\t( +>]+\\)")

(defconst company-web-html-emmet-tag-regexp
  (concat company-web-html-emmet-tag-separator
          "\\(" company-web-selector "*\\)")
  "A regular expression matching emmet's tags.")

(defconst company-web-html-emmet-class-regexp
  (concat  company-web-html-emmet-tag-separator
           ;; tag
           "\\(" company-web-selector "+\\|\\)"
           ;;    maybe "/" after tag
           "/?"
           ;; skip #foo or .bar or .foo.bar.baz
           "[#.[:alnum:]-]*"
           ;; class
           "[.]\\(" company-web-selector "*\\)")
  "A regular expression matching emmet's class name.")

(defconst company-web-html-emmet-id-regexp
  (concat  company-web-html-emmet-tag-separator
           ;; tag
           "\\(" company-web-selector "+\\|\\)"
           ;;    maybe "/" after tag
           "/?"
           ;; skip #foo or .bar or .foo.bar.baz
           "[#.[:alnum:]-]*"
           ;; class
           "[#]\\(" company-web-selector "*\\)")
  "A regular expression matching emmet's class name.")

(defconst company-web-html-emmet-attr-regexp
  (concat  company-web-html-emmet-tag-separator
           ;; tag name
           "\\(" company-web-selector "+\\)"
           ;;    maybe "/" after tag
           "/?"
           ;; skip not tag separator
           "[^\t +>]*?"
           ;;      untill found "["
           "\\["
           ;;      skip any defined attributes like foo="bar"
           "\\(?:" company-web-selector "+=\"[^\"]*\"\\|\\)+"
           ;; current attribute
           "\\(" company-web-selector "*\\)")
  "A regular expression matching emmet's attribute name.")

(defconst company-web-html-emmet-value-regexp
  (concat  company-web-html-emmet-tag-separator
           ;; get tag name
           "\\(" company-web-selector "+\\)"
           ;;    maybe "/" after tag
           "/?"
           ;; skip not tag separator
           "[^\t +>]*?"
           ;;      untill found "["
           "\\["
           ;;      skip any defined attributes like foo="bar"
           "\\(?:" company-web-selector "+=\"[^\"]*\"\\|\\)+"
           ;; get current attribute
           "\\(" company-web-selector "+\\)"
           ;; get current value
           "=\"\\(.*\\)")
  "A regular expression matching emmet's value name.")

(defun company-web-html-emmet-grab ()
  (let* ((limit (company-web-backward-min-tag-bound))
         (bound (save-excursion
                  (if (re-search-backward ">" limit t)
                      (point)
                    limit))))
    (and company-web-html-emmet-enable
         (bound-and-true-p emmet-mode)
         (or
          (company-grab company-web-html-emmet-tag-regexp 1 bound)
          (company-grab company-web-html-emmet-class-regexp 2 bound)
          (company-grab company-web-html-emmet-id-regexp 2 bound)
          (company-grab company-web-html-emmet-attr-regexp 2 bound)
          (company-grab company-web-html-emmet-value-regexp 3 bound)))))

(defun company-web-html-emmet-candidates()
  (when (and company-web-html-emmet-enable
             (bound-and-true-p emmet-mode))
    (let* ((limit (company-web-backward-min-tag-bound))
           (bound (save-excursion
                    (if (re-search-backward ">" limit t)
                        (point)
                      limit))))
      (cond
       ((company-grab company-web-html-emmet-tag-regexp 1 bound)
        (all-completions arg (company-web-candidates-tags)))
       ;; class (default for div tag)
       ((company-grab company-web-html-emmet-class-regexp 2 bound)
        (let ((tag (company-grab company-web-html-emmet-class-regexp 1 bound)))
          (if (string= "" tag)
              (setq tag "div"))
          (all-completions arg (company-web-candidates-attrib-values tag "class" bound))))
       ;; id (default for div tag)
       ((company-grab company-web-html-emmet-id-regexp 2 bound)
        (let ((tag (company-grab company-web-html-emmet-id-regexp 1 bound)))
          (if (string= "" tag)
              (setq tag "div"))
          (all-completions arg (company-web-candidates-attrib-values tag "id" bound))))
       ;; attributes (default for div)
       ((company-grab company-web-html-emmet-attr-regexp 2 bound)
        (let ((tag (company-grab company-web-html-emmet-attr-regexp 1 bound)))
          (if (string= "" tag)
              (setq tag "div"))
          (all-completions arg (company-web-candidates-attribute tag))))
       ;; attribute values
       ((company-grab company-web-html-emmet-value-regexp 3 bound)
        (let ((tag (company-grab company-web-html-emmet-value-regexp 1 bound))
              (attribute (company-grab company-web-html-emmet-value-regexp 2 bound)))
          (all-completions arg (company-web-candidates-attrib-values tag attribute bound))))))))

(defadvice emmet-preview-accept (around emmet-with-company-accept)
  "First call `company-complete-selection' if visible company popup."
  (if (and company-web-html-emmet-enable
           company-web-html-emmet-preview-enable-advice
           company-pseudo-tooltip-overlay)
      (company-complete-selection)
    ad-do-it))

(defadvice emmet-preview-abort (around emmet-with-company-abort)
  "First call `company-abort' if visible company popup."
  (if (and company-web-html-emmet-enable
           company-web-html-emmet-preview-enable-advice
           company-pseudo-tooltip-overlay)
      (company-abort)
    ad-do-it))

(defun company-web-html-emmet-doc (arg)
  (let* ((limit (company-web-backward-min-tag-bound))
         (bound (save-excursion
                  (if (re-search-backward ">" limit t)
                      (point)
                    limit))))
    (when (and company-web-html-emmet-enable
               (bound-and-true-p emmet-mode))
      (cond
       ((company-grab company-web-html-emmet-tag-regexp 1 bound)
        (company-web-tag-doc arg))
       ;; class (default for div tag)
       ((company-grab company-web-html-emmet-class-regexp 2 bound)
        (let ((tag (company-grab company-web-html-emmet-class-regexp 1 bound)))
          (if (string= "" tag)
              (setq tag "div"))
          (company-web-attribute-doc tag arg)))
       ;; id (default for div tag)
       ((company-grab company-web-html-emmet-id-regexp 2 bound)
        (let ((tag (company-grab company-web-html-emmet-id-regexp 1 bound)))
          (if (string= "" tag)
              (setq tag "div"))
          (company-web-attribute-doc tag arg)))
       ;; attributes (default for div)
       ((company-grab company-web-html-emmet-attr-regexp 2 bound)
        (let ((tag (company-grab company-web-html-emmet-attr-regexp 1 bound)))
          (if (string= "" tag)
              (setq tag "div"))
          (company-web-attribute-doc tag arg)))
       ((company-grab company-web-html-emmet-value-regexp 3 bound)
        (let ((tag (company-grab company-web-html-emmet-value-regexp 1 bound))
              (attribute (company-grab company-web-html-emmet-value-regexp 2 bound)))
          (company-web-attribute-doc tag arg)))))))

(defun company-web-html-prefix-tag ()
  (company-web-grab-not-in-string company-web-html-tag-regexp 1 (company-web-backward-min-tag-bound)))

(defun company-web-html-prefix-attribute (bound)
  (company-web-grab-not-in-string company-web-html-attribute-regexp 1 bound))

(defun company-web-html-prefix-value (bound)
  (when (looking-back company-web-html-value-regexp bound)
    (match-string-no-properties 1)))

;;;###autoload
(defun company-web-html (command &optional arg &rest ignored)
  "`company-mode' completion back-end for `html-mode' and `web-mode'."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-web-html))
    (ignore-case t)
    (duplicates nil)

    (prefix (and (or (derived-mode-p 'html-mode)
                     (derived-mode-p 'web-mode))
                 (let* ((tag-info (company-web-html-current-tag))
                        (tag (car tag-info))
                        (tag-bound (cdr tag-info)))
                   (or (and tag (company-web-html-prefix-value tag-bound))
                       (and tag (company-web-html-prefix-attribute tag-bound))
                       (company-web-html-prefix-tag)
                       (company-web-html-emmet-grab)
                       ))))

    (candidates
     (let* ((tag-info (company-web-html-current-tag))
            (tag (car tag-info))
            (tag-bound (cdr tag-info)))
       (cond
        ;; value
        ((and tag (company-web-html-prefix-value tag-bound))
         (all-completions arg (company-web-candidates-attrib-values tag
                                                                    (company-web-html-current-attribute tag-bound) tag-bound)))
        ;; attr
        ((and tag (company-web-html-prefix-attribute tag-bound))
         (all-completions arg (company-web-candidates-attribute tag)))
        ;; tag
        ((company-web-html-prefix-tag)
         (all-completions arg (company-web-candidates-tags)))
        ;; emmet
        ((company-web-html-emmet-grab)
         (company-web-html-emmet-candidates))
        )))

    (annotation (company-web-annotation arg))

    (doc-buffer
     ;; No need grab for attribute value, attribute regexp will match enyway
     (let* ((tag-info (company-web-html-current-tag))
            (tag (car tag-info))
            (tag-bound (cdr tag-info)))
       (cond
        ;; value
        ((and tag (company-web-html-prefix-value tag-bound))
         (company-web-candidate-prop-doc arg))
        ;; attr
        ((and tag (company-web-html-prefix-attribute tag-bound))
         (company-web-attribute-doc tag arg))
        ;; tag
        ((company-web-html-prefix-tag)
         (company-web-tag-doc arg))
        ;; emmet
        ((company-web-html-emmet-grab)
         (company-web-html-emmet-doc arg))
        )))))

(provide 'company-web-html)
;;; company-web-html.el ends here
