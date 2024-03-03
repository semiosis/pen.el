(require 'pen-comint)

(defcustom pen-nlsh-histdir ""
  "Directory where history files for nlsh"
  :type 'string
  :group 'pen
  :initialize #'custom-initialize-default)

(comment
 (pen-one (pf-list-of/2 10 "operating systems with a command line")))

;; "OS which have a bash-like shell of some kind installed"
;; (ci (pen-one (pf-list-of/2 10 "operating systems with a command line")))
(defset list-of-sh-operating-systems '(
                                       ;;  There has been a name change
                                       ;; That's why this is giving bad results
                                       ;; "GNU Guix System"
                                       "GuixSD"
                                       "Alpine Linux"
                                       "RHEL Red Hat Enterprise Linux"
                                       "Amazon Linux 2"
                                       "NixOS"
                                       "macOS"
                                       "Ubuntu 20.04"
                                       "Arch Linux"))

(defun turn-on-comint-history (history-file)
  (setq comint-input-ring-file-name history-file)
  (comint-read-input-ring 'silent))

(defun ii-python ()
  (interactive)

  (ii-language "python"))

(defun ii-bash ()
  (interactive)

  (ii-language "bash"))

(defun ii-language (language)
  (interactive (list (fz
                      (append
                       '("Python"
                         "Bash")
                       (eval `(pen-ci (pen-one (pf-list-of/2 10 "programming languages"))))
                       nil nil "ii-language: ")
                      nil nil "Language:")))

  ;; Strangely, it broke ii to start in pen-prompts-directory
  ;; (pen-sps (pen-cmd "ii" language) nil nil pen-prompts-directory)
  (pen-sps (pen-cmd "ii" language)))
(defalias 'ii 'ii-language)

(defun nlsh-os (os)
  (interactive (list (fz
                      (append
                       '(;;  There has been a name change
                         ;; That's why this is giving bad results
                         ;; "GNU Guix System"
                         "GuixSD"
                         "Alpine Linux"
                         "RHEL Red Hat Enterprise Linux"
                         "Amazon Linux 2"
                         "NixOS"
                         "macOS"
                         "Ubuntu 20.04"
                         "Arch Linux")
                       (eval `(pen-ci (pen-one (pf-list-of/2 10 "operating systems with a command line"))))
                       nil nil "nlsh-os: "))))
  (comint-quick (pen-cmd "nlsh" os) pen-prompts-directory))

(defun pen-bol-context ()
  (interactive)
  (term-send-raw-string "\C-a")
  (sleep-for 0.1)
  (pen-preceding-text))

(defun pen-start-ii-from-buffer (lang kickstarter)
  (interactive (list (pen-detect-language-ask)
                     (pen-bol-context)))
  (pen-sps (pen-cmd "ii" lang "" kickstarter)))

(provide 'pen-ii)
