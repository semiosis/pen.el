;; What you are looking at are memories.
;; In this case pertaining to one individual...
;; This file contains the most particular memory...
;; I'd like you to see it, if you would.

;; http://github.com/semiosis/pensieve

;; https://www.youtube.com/watch?v=dumUElmlVJA

(defun pensieve-mount-dir (dirname)
  (interactive (list (read-string-hist "Directory name")))

  (let ((dn (f-join "/root/pensieves" dirname)))
    (pen-snc (pen-cmd "mkdir" "-p" dn))
    (pen-sps (pen-cmd "pensieve" dn))
    (dired dn)))

(provide 'pen-pensieve)