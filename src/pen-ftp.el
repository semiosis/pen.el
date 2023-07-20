;; https://www.gnu.org/software/tramp/#index-method-ftp
;; https://www.emacswiki.org/emacs/AngeFtp

;; This is for setting up dired and ftp
;; Say, to browse https://wiki.crosswire.org/Official_and_Affiliated_Module_Repositories#Lockman_Foundation

(require 'ange-ftp)

(setq ange-ftp-ftp-program-name "ftp")
(setq ange-ftp-ftp-program-args '("-i" "-n" "-g" "-v"))

(provide 'pen-ftp)
