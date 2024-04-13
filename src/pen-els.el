;; Shared functions for pen.els and pen

;; e:$EMACSD/pen.el/scripts/bible-mode-scripts/pen.els

;; ln -sf pen-els cmd-2d-to-1d
(defun cmd-2d-to-1d (ref &rest args)

  (pen-list2str (append (list ref) args)))

;; Yes, that works now cmd-2d-to-1d yo

;; This is an example:
;; ln -sf pen-els bible-canonicalise-ref
(defun bible-canonicalise-ref (ref &optional nilfailure)
  (let* ((booktitle (s-replace-regexp "[. ][0-9].*" "" ref))
         (chapverse (pen-sn-basic "sed -n 's/.*[. ]\\([0-9].*\\)/\\1/p'" ref))
         (booktitle (bible-canonicalise-book-title booktitle nilfailure)))
    (if (test-n chapverse)
        (concat booktitle " " chapverse)
      booktitle)))

(defun bible-canonicalise-book-title (ref &optional nilfailure)
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
               (car tp)
             (if nilfailure
                 nil
               ref))))

(provide 'pen-els)
