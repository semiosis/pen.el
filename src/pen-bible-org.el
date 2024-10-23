;; j:pen-org-link-types

(org-add-link-type "bible" 'follow-bible-link)
(defun follow-bible-link (query)
  "Run `bible' with QUERY as argument."
  (bible-mode-lookup query))

;; TODO Run a loop over the various modules
;; (org-add-link-type "nasb" 'follow-bible-link-nasb)
;; (defun follow-bible-link-nasb (query)
;;   "Run `bible' with QUERY as argument."
;;   (bible-mode-lookup query "nasb"))

(org-add-link-type "strongs" 'follow-strongs-link)
(defun follow-strongs-link (query)
  "Run `strongs' with QUERY as argument."
  (bible-term-show-word query)
  ;; (strongs-mode-lookup query)
  )

(org-link-set-parameters
 "bible"
 :export (lambda (path desc backend)
           (let ((title (or desc
                            (s-replace-regexp "^[^:]*:" "" path)))
                 (url (snc "canonicalise-bible-ref | biblegatewayify-bible-ref -urlonly" path))
                 ;; (urlsegment (urlencode path))
                 )
             (cond
              ((eq 'html backend)
               (format "<a href=\"%s\">%s</a>" url title))
              ((eq 'latex backend)
               (format "\\href{%s}{%s}" url title))))))

(org-link-set-parameters
 "strongs"
 :export (lambda (path desc backend)
           (let ((title (or desc
                            (s-replace-regexp "^[^:]*:" "" path)))
                 (url (snc "blueletterbibleify-strongs-code | xurls" path))
                 ;; (urlsegment (urlencode path))
                 )
             (cond
              ((eq 'html backend)
               (format "<a href=\"%s\">%s</a>" url title))
              ((eq 'latex backend)
               (format "\\href{%s}{%s}" url title))))))

(provide 'pen-bible-org)
