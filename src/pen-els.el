;; Shared functions for pen.els and pen

;; e:$EMACSD/pen.el/scripts/bible-mode-scripts/pen.els

;; ln -sf pen-els cmd-2d-to-1d
(defun cmd-2d-to-1d (ref &rest args)

  (pen-list2str (append (list ref) args)))

(defalias 're-match-p 'string-match)

;; Yes, that works now cmd-2d-to-1d yo

(comment
 (bible-canonicalise-ref "Rev")
 (bible-canonicalise-ref-short "Revelation of John")
 (bible-canonicalise-ref "I John" nil t))

;; This is an example:
;; ln -sf pen-els bible-canonicalise-ref
(defun bible-canonicalise-ref (ref &optional nilfailure short?)
  (let* ((booktitle (s-replace-regexp "[. ][0-9].*" "" ref))
         (chapverse (pen-sn-basic "sed -n 's/.*[. ]\\([0-9].*\\)/\\1/p'" ref))
         (booktitle (bible-canonicalise-book-title booktitle nilfailure short?)))
    (if (test-n chapverse)
        (concat booktitle " " chapverse)
      booktitle)))

(defun bible-canonicalise-ref-short (ref &optional nilfailure)
  (bible-canonicalise-ref ref nilfailure t))

(defun bible-canonicalise-book-title (ref &optional nilfailure short?)
  (setq ref (s-replace-regexp "\\(\\. \\?\\|\\.\\)" " " ref))
  (setq ref (esed "\\.$" "" ref))
  (cl-loop for tp in bible-book-map-names
           until ;; (member ref (cdr tp))
           (member-similar ref tp)
           ;; (member ref tp)
           finally return
           (if ;; (member ref (cdr tp))
               (member-similar ref tp)
               ;; (member ref tp)
               (if short?
                   ;; Sometimes the first one is quite big
                   (or (-first (lambda (s) (and
                                            (re-match-p "^[^ ]*$" s)
                                            (< (length s) 5))) tp)
                       (-first (lambda (s) (re-match-p "^[^ ]*$" s)) tp))
                 (car tp))
             (if nilfailure
                 nil
               ref))))

(provide 'pen-els)
