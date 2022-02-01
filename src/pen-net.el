(require 'parse-csv)

;; What I really need is a list of services + ports then work on that
;; But I'm using nmap, so nah.

(defun csv-load (data)
  (parse-csv-string-rows data ?, ?\" "\n"))

(defun pen-n-list-open-ports (&optional hn fast)
  (if (not hn)
      (setq hn "localhost"))
  (csv-load (pen-snc (concat
                      (if fast
                          (pen-cmd "pen-n-list-open-ports" "-F" hn)
                        (pen-cmd "pen-n-list-open-ports" hn))
                      "|sed 1d"))))
(defalias 'list-open-ports 'pen-n-list-open-ports)

(defun n-get-free-port (&optional from to)
  (setq from (or from "40000"))
  (setq to (or to "65535"))
  (pen-snc (pen-cmd "pen-n-get-free-port-from-range" from to)))

(provide 'pen-net)