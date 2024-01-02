;; Yeah, I guess it's about time I made a few tools for working with json files.
;; This should be quite useful for debugging elisp, actually.

(defun jstate-get (key &optional dbname)
  (interactive (list (read-string-hist "jstate key: ")))
  (ifi-etv
   (snc (cmd-f "jstate-get" "-db" dbname key))))

(defun jstate-jq (query &optional dbname)
  (interactive (list (read-string-hist "jstate query: ")))
  (ifi-etv
   (snc (cmd-f "jstate-jq" "-db" dbname query))))

(defun jstate-del (key &optional dbname)
  (interactive (list (read-string-hist "jstate key: ")))
  (ifi-etv
   (snc (cmd-f "jstate-del" "-db" dbname key))))

(defun jstate-set (key val &optional dbname)
  (interactive (list (read-string-hist "jstate key: ")
                     (read-string-hist "jstate val: ")))
  (ifi-etv
   (snc (cmd-f "jstate-set" "-db" dbname key val))))

(defun jstate-clear (&optional dbname)
  (interactive)
  (snc (cmd-f "jstate-clear" "-db" dbname)))

(defun jstate-watch (&optional dbname)
  (interactive)
  (sps (cmd-f  "jstate-watch" "-db" dbname)
       "-nv -d -l 30%"))

(defun jstate-jiq (&optional dbname)
  (interactive)
  (nw (cmd-f "jstate-jiq" "-db" dbname)))

(provide 'pen-jstate)
