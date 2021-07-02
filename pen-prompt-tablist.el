(require 'tabulated-list)
(require 'tablist)

(defvar pen-prompts-tablist-data-command "oci prompts-details -csv")

(defvar pen-prompts-tablist-meta ("prompts" t "30 30 20 10 15 15 15 10"))

(defmacro defcmdmode (cmd &optional cmdtype)
  (setq cmd (str cmd))
  (setq cmdtype (or cmdtype "term"))
  (let* ((cmdslug (slugify (str cmd)))
         (modestr (concat cmdslug "-" cmdtype "-mode"))
         (modesym (intern modestr))
         (mapsym (intern (concat modestr "-map"))))
    `(progn
       (defvar ,mapsym (make-sparse-keymap)
         ,(concat "Keymap for `" modestr "'."))
       (defvar-local ,modesym nil)

       (define-minor-mode ,modesym
         ,(concat "A minor mode for the '" cmd "' " cmdtype " command.")
         :global nil
         :init-value nil
         :lighter ,(s-upcase cmdslug)
         :keymap ,mapsym)
       (provide ',modesym))))

(defcmdmode "prompts" "tablist")

(defun pen-prompts-tablist-start ()
  (interactive)
  (let* ((sh-update (>= (prefix-numeric-value current-global-prefix-arg) 16))
         (args pen-prompts-tablist-meta))
    (apply 'create-tablist args)))

(provide 'pen-tablist)