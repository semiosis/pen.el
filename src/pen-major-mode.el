(require 'pen-context)

(defun fz-syms (prompt collection)
  "This will show documentation because they are symbols"

  (if (stringp collection)
      (setq collection (s-lines collection)))

  (setq collection (mapcar 'intern collection))

  ;; I could use fz here too
  (completing-read prompt
                   collection nil t nil nil))

(defun get-major-mode-functions (&optional map)
  (if (not map)
      (setq map (current-major-mode-map)))

  (let ((ms (show-map-as-string map)))
    (if (sor ms)
        (let* ((funstr
                (pen-snc "sed -e '/^ /d' -e '/Prefix Command/d' -e '/^$/d' -e '/^--/d' -e '/^key/d' -e '/Key.*Binding/d' | rev | pen-str field 1 | rev" ms)))
          (if (sor funstr)
              (-filter 'commandp (mapcar 'intern (str2lines funstr))))))))

(defun select-major-mode-function (&optional map)
  (if (not map)
      (setq map (current-major-mode-map)))

  (let ((ms (show-map-as-string map)))
    (if (sor ms)
        (let* ((funstr
                (fz-syms
                 "select-major-mode-function: "
                 (pen-snc "sed -e '/^ /d' -e '/Prefix Command/d' -e '/^$/d' -e '/^--/d' -e '/^key/d' -e '/Key.*Binding/d' | rev | pen-str field 1 | rev" ms))))
          (if (sor funstr)
              (let ((fun (intern funstr)))
                (if (commandp fun)
                    fun)))))))

(defun run-major-mode-function (&optional map)
  (interactive)
  (let ((fun (select-major-mode-function map)))
    (if (commandp fun)
        (call-interactively fun))))

(defcustom custom-defined-keys nil
  "Custom defined keys"
  :type 'list
  :group 'pen-major-mode
  :initialize #'custom-initialize-default)

(defun custom-define-key (keymap key def)
  (interactive (list nil nil nil))

  (if (not keymap)
      (setq keymap (showmap--read-symbol "map: " (variable-name-re-p "-map$"))))

  (if (not key)
      (setq key
            (save-window-excursion
              (save-selected-window
                (free-keys "C-c"))
              (let ((kp (read-key-sequence-vector "Key: ")))
                (kill-buffer "*Free keys*")
                kp))))

  (if (not def)
      (setq def (select-major-mode-function keymap)))

  (let ((keystr (format "%s" (key-description key))))
    (if (not def)
        (setq def (eval `(lambda () (interactive)
                           (message ,(concat keystr " not defined"))
                           (edit-var-elisp 'custom-defined-keys)))))

    (let* ((wassym (symbolp def))
           (defquoted (if wassym
                          (eval `'',def)
                        def))
           (dk `(define-key ,(current-major-mode-map) (kbd ,keystr) ,defquoted)))
      (add-to-list 'custom-defined-keys dk)
      (eval dk)
      (custom-set-variables `(custom-defined-keys (quote ,custom-defined-keys)))
      (custom-save-all)
      (if (not wassym)
          (edit-var-elisp 'custom-defined-keys)))))

(defun custom-keys-edit ()
  (interactive)
  (edit-var-elisp 'custom-defined-keys))

(defun custom-keys-goto (do-define-all-keys)
  (interactive "P")

  (if do-define-all-keys
      (dolist (e custom-defined-keys)
        (eval e))
    (j 'custom-keys-goto)))

(defun custom-keys-define-all (&optional goto-custom)
  (interactive "P")

  (if custom-defined-keys
      (dolist (e custom-defined-keys)
        (eval e))))

(add-hook-last 'window-setup-hook 'custom-keys-define-all)

(defun custom-keys-undefine-all (&optional permanent)
  (interactive "P")

  (dolist (e (mapcar
              (lambda (ee)
                (append (-drop-last 1 ee) (list nil)))
              custom-defined-keys))
    (eval e))

  (if permanent
      (progn
        (setq custom-defined-keys nil)
        (custom-set-variables '(custom-defined-keys nil))
        (custom-save-all))))

(defun custom-keys-undefine-all-permanent ()
  (interactive)
  (custom-keys-undefine-all t))

(provide 'pen-major-mode)
