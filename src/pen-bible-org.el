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
               (tv (format "\\href{%s}{%s}" url title)))))))

(provide 'pen-bible-org)
