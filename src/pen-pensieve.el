;; What you are looking at are memories.
;; In this case pertaining to one individual...
;; This file contains the most particular memory...
;; I'd like you to see it, if you would.

;; http://github.com/semiosis/pensieve

;; https://www.youtube.com/watch?v=dumUElmlVJA

(defun pensieve-mount-dir (dirname)
  (interactive (list (read-string-hist "Directory name")))

  (pen-sps (pen-cmd "pensieve" dirname))
  (dired dirname))

(provide 'pen-pensieve)