;; This is for everything outside of core pen stuff
;; i.e. applications built on pen.el

(defvar pen-tutor-common-questions
  '("What is <1:q> used for?"
    "What are some good learning materials"))

(defun pen-tutor-mode-assist (query)
  (interactive (let* ((bl (buffer-language t t)))
                 (list
                  (read-string-hist
                   (concat "asktutor (" bl "): ")
                   (my/thing-at-point)))))
  (pen-pf-asktutor bl bl query))


(defset pen-doc-queries
  '(
    "What is '${query}' and what how is it used?"
    "What are some examples of using '${query}'?"
    "What are some alternatives to using '${query}'?"))

;; v:pen-ask-documentation 
(defun pen-ask-documentation (thing query)
  (interactive
   (let* ((thing (my/thing-at-point))
          (qs (mapcar (lambda (s) (s-format s 'aget `(("query" . ,thing)))) pen-doc-queries))
          (query
           (fz qs
               nil nil
               "pen-ask-documentation: ")))
     (list
      thing
      query))))

;; "OS which have a bash-like shell of some kind installed"
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

(defun comint-quick (cmd &optional dir)
  (interactive (list (read-string-hist "comint-quick: ")))
  (let* ((slug (slugify cmd))
         (buf (make-comint slug (nsfa cmd dir))))
    (with-current-buffer buf
      (switch-to-buffer buf)
      (turn-on-comint-history (concat "/home/shane/notes/programs/comint/history/" slug)))))

(defun nlsh-os (os)
  (interactive (list (fz list-of-sh-operating-systems
                         nil nil "nlsh-os: ")))
  (comint-quick (cmd "nlsh-os" os)))

(provide 'pen-contrib)