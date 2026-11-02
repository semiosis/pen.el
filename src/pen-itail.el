(require 'itail)

(setq itail-fancy-mode-line t)

(setq itail-highlight-list
      '(("Error" . gamegrid-color-tty-face-red)
        ("GET\\|POST\\|DELETE\\|PUT" . gamegrid-color-tty-face-green)
        ("dispmsg" . gamegrid-color-tty-face-blue)
        ("[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}" . font-lock-string-face)))

(defun itail (file &optional lines)
  "Tail file FILE in itail mode.  Supports remote tailing through tramp "
  (interactive (list (let* ((file (or (and (eq major-mode 'dired-mode)
                                           (dired-get-filename nil :no-error-if-not-filep))
                                      (when (require 'ffap nil :noerror)
                                        (ffap-file-at-point))))
                            (dir (unless (zerop (length file))
                                   (and (file-directory-p file)
                                        (file-name-as-directory file))))
                            (file (unless (zerop (length file))
                                    (file-relative-name file))))
                       (read-file-name (if (and (null dir) file)
                                           (format "Tail file (%s): " file)
                                         "Tail file: ")
                                       dir
                                       (and (null dir) file)))
                     current-prefix-arg))
  (let* ((file (expand-file-name file))
         (buffer-name-template (concat "itail: " file))
         (buffer-name (concat "*" buffer-name-template "*"))
         ;; This was broken for (file-relative-name "/tmp/shell-messages.log").
         ;; (file (file-relative-name file))
         (default-directory (or (and (file-name-absolute-p file)
                                     (or (file-remote-p file)
                                         (and (file-remote-p default-directory)
                                              "~/")))
                                default-directory))
         (file (or (file-remote-p file 'localname) file))
         (lines (or lines (if (functionp itail-lines) (funcall itail-lines) itail-lines))))
    (apply #'make-comint buffer-name-template "tail" nil "-F" file (when (numberp lines)
                                                                     (list "-n" (format "%+d" lines))))
    (funcall itail-open-fn buffer-name)

    (ansi-color-for-comint-mode-on)
    (add-hook 'comint-preoutput-filter-functions 'itail-output-filter)
    (goto-char (point-max))
    (setq buffer-read-only t)
    (setq itail-file file)
    (setq itail-filters ())
    (itail-mode-line)
    (itail-mode)

    ;; These should really be enabled only when witching to the itail buffer,
    ;; rather than when initiating the itail.
    ;; j:bash-messages
    ;; (itail-highlight)
    ;; (if (not org-link-minor-mode)
    ;;     (org-link-minor-mode))
    
    (switch-to-buffer buffer-name))
  ;; (switch-to-buffer "*itail: /tmp/shell-messages.log*")
  )

(provide 'pen-itail)
