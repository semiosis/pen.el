(defun cterm (command)
  (interactive (list (read-string-hist "Shell command: ")))
  (pen-sps (pen-cmd "cterm" "-E" command)))

;; Make a pet command or 'tep' to run eterm inside the current emacs
;; or make an option -elisp
(defun pet (command &optional stdin dir)
  (interactive (list (read-string-hist "Shell command: ")))
  ;; (pen-sps (pen-cmd "pet" "-E" command))
  (eval-string (pen-snc (pen-cmd "pet" "-E" command) stdin dir)))

(defun sps-pet (command &optional stdin dir)
  (interactive (list (read-string-hist "Shell command: ")))
  (esps (lm (pet command stdin dir))))

(defun testpet ()
  (interactive)
  (progn
    (pen-term
     (pen-nsfa
      "\"pen-cterm-ssh\" \"-ssh-to-host\" \"n\" \"-cwd\" \"$HOME/notes\" \"-cmd\" \"cat \\\"/tmp/tf_temp_0d1987b0e3.txt\\\" | tmwr -nopr \\\"glow\\\"\" \"-user\" \"shane\"")
     nil
     "pen-cterm-ssh"
     "cterm-tmwr-nopr-glow"
     nil)))

(defun tm-pet (command &optional stdin dir nw_args)
  (interactive (list (read-string-hist "Shell command: ")))
  (pen-sps (pen-cmd "pet" "-E" command)
           nw_args stdin dir))
(defalias 'tm-sps-pet 'tm-pet)

(defun cterm-start ()
  (interactive)

  (pen-sps "cterm"))

(defun pet-start ()
  (interactive)

  (pen-sps "pet"))

(provide 'pen-cterm)
