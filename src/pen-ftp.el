(require 'dired)

;; https://www.gnu.org/software/tramp/#index-method-ftp
;; https://www.emacswiki.org/emacs/AngeFtp

;; This is for setting up dired and ftp
;; Say, to browse https://wiki.crosswire.org/Official_and_Affiliated_Module_Repositories#Lockman_Foundation

(require 'ange-ftp)

(setq ange-ftp-ftp-program-name "ftp")
(setq ange-ftp-ftp-program-args '("-i" "-n" "-g" "-v"))

;; ftp:ftp.crosswire.org:/pub/sword/raw

;; ftp:ftp.crosswire.org:/pub/bible.org/sword

;; ftp:ftp.crosswire.org:/pub/sword/atticraw

;; ftp:ftp.crosswire.org:/pub/sword/betaraw

;; ftp:ftp.crosswire.org:/pub/sword/wyclifferaw

;; Make it so I'm asked if I want to download the file when I open a file in dired in ftp
(defun dired-find-file ()
  "In Dired, visit the file or directory named on this line."

(interactive)

  (let ((path (dired-get-file-for-visit)))
    (pcase path
      ;; ((rx "custom-id") (concat "#" path))
      ;; ((pred (lambda (s) (re-match-p "^/ftp:" s))) (tv path))

      ;; See j:pen-pcase
      ((re "^/ftp:") (tv path))
      (_ (dired--find-possibly-alternative-file path)))))

(provide 'pen-ftp)
