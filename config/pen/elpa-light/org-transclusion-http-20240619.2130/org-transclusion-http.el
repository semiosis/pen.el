;;; org-transclusion-http.el --- Transclude over HTTP -*- lexical-binding: t; -*-

;; Copyright (C) 2024  USHIN, Inc.

;; Author: Joseph Turner <first name at ushin.org>
;; Maintainer: Joseph Turner <~ushin/ushin@lists.sr.ht>
;; Created: 2024
;; Package-Version: 20240619.2130
;; Package-Revision: 65caad0d9b19
;; Package-Requires: ((emacs "28.1") (org-transclusion "1.4.0") (plz "0.7.2"))
;; Homepage: https://git.sr.ht/~ushin/org-transclusion-http

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public
;; License along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This file extends the `org-transclusion' package to allow for transcluding
;; content over HTTP.  Features include:
;;
;; - Transclude plain text
;;   + Transclude only Org headings matching search options
;; - Transclude HTML converted to Org using Pandoc, a lá `org-web-tools'
;;   + Transclude only HTML headings matching link anchor
;; - TODO: Support :lines

;;; Code:

;;;; Requirements

(require 'org)
(require 'org-element)
(require 'org-transclusion)
(require 'org-transclusion-html)
(require 'cl-lib)
(require 'pcase)
(require 'url)
(require 'plz)

;;;; Functions

;;;###autoload
(defun org-transclusion-http-add (link _plist)
  "Return handler function when HTTP transclusion is appropriate.
Otherwise, return nil.  Intended to be added to
`org-transclusion-add-functions', which see for descriptions of
arguments LINK and PLIST."
  (pcase (org-element-property :type link)
    ((or "http" "https")
     (message "Asynchronously transcluding over HTTP at point %d, line %d..."
              (point) (org-current-line))
     #'org-transclusion-http--add-file)))

(add-hook 'org-transclusion-add-functions #'org-transclusion-http-add)

(defun org-transclusion-http--add-file (link plist copy)
  "Load HTTP file at LINK.
Then call `org-transclusion-add-payload' with PAYLOAD, LINK,
PLIST, COPY."
  (pcase-let* ((target-mkr (point-marker))
               (url (org-element-property :raw-link link))
               ((cl-struct url filename target) (url-generic-parse-url url))
               (tc-type))
    ;; TODO: When plz adds ":as 'response-with-buffer", use that.
    (plz 'get url :noquery t :as 'response :then
      (lambda (response)
        (pcase-let (((cl-struct plz-response body (headers (map content-type))) response)
                    (target-buf (marker-buffer target-mkr)))
          (when target-buf
            (with-temp-buffer
              (insert body)
              (goto-char (point-min))
              (pcase content-type
                ((or (rx bos "text/html")
                     (and (or (rx bos "application/octet-stream")
                              'nil)
                          (guard (org-transclusion-html--html-p (current-buffer)))))
                 ;; Server declares the content is HTML, or server did
                 ;; not specify a type but it appears to be HTML.
                 (unless (executable-find "pandoc")
                   (error "org-transclusion-http: Unable to transclude content at <%s>:  Can't find \"pandoc\" executable"
                          url))
                 (let ((dom (libxml-parse-html-region (point-min) (point-max))))
                   (when (dom-by-id dom (format "\\`%s\\'" target))
                     ;; Page contains id element matching link target.
                     (erase-buffer)
                     (dom-print (org-transclusion-html--target-content dom target)))
                   (org-transclusion--insert-org-from-html-with-pandoc)
                   ;; Use "org"-prefixed `tc-type' since HTML is converted to Org mode.
                   (setf tc-type "org-html-http")))
                ((or (rx bos "application/vnd.lotus-organizer")
                     (and (or (rx bos "application/octet-stream")
                              'nil)
                          ;; FIXME: filename may contain a query string, so it may not end
                          ;; with "org" or "org.gpg".  For example,
                          ;; https://example.com/foobar.org?query=answer has the filename
                          ;; /foobar.org?query=answer and therefore doesn't match.
                          (guard (org-transclusion-org-file-p filename))))
                 ;; Appears to be an Org-mode file.
                 (when target
                   (org-mode)
                   (let ((org-link-search-must-match-exact-headline t))
                     (when (with-demoted-errors "org-transclusion-http: Transcluding whole file due to %S"
                             (org-link-search (format "#%s" target)))
                       (org-narrow-to-subtree))))
                 (setf tc-type "org-http"))
                (_
                 ;; All other file types.
                 (setf tc-type "others-http")))
              (let* ((payload-without-type
                      (org-transclusion-content-org-buffer-or-element nil plist))
                     (payload (append `(:tc-type ,tc-type) payload-without-type)))
                (with-current-buffer target-buf
                  (org-with-wide-buffer
                   (goto-char (marker-position target-mkr))
                   (org-transclusion-add-payload payload link plist copy))))))))
      :else (lambda (err)
              (let ((buf (get-buffer-create (format "*org-transclusion-http-error <%s>" url))))
                (with-current-buffer buf
                  (erase-buffer)
                  (princ err (current-buffer)))
                (message "org-transclusion-http: Unable to transclude content at <%s>.  Please open %S for details."
                         url buf))))))

;;;; Footer

(provide 'org-transclusion-http)

;;; org-transclusion-http.el ends here
