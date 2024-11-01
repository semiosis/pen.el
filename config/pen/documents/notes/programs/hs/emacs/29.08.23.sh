cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)

  (nbfs \"hi\")
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)

  (nbfs \"hi\")
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)

  (nbfs \"hi\")
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)

  (nbfs \"hi\")
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)

  (nbfs \"hi\")
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (nbfs \"hi\")
  (read-only-mode 1)
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (nbfs \"hi\")
  (read-only-mode 1)
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'quit-window)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)

  (load \"/tmp/lambda-emacs-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'quit-window)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (load \"/tmp/lambda-emacs-load.el\")
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs \"hi\")
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun e/cat (path)
    \"Return the contents of FILENAME.\"
    (with-temp-buffer
      (insert-file-contents path)
      (buffer-string)))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs (e/cat \"/root/.emacs.d/host/pen.el/scripts/lambda-emacs\"))
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun e/cat (path)
    \"Return the contents of FILENAME.\"
    (with-temp-buffer
      (insert-file-contents path)
      (buffer-string)))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs (e/cat \"/root/.emacs.d/host/pen.el/scripts/lambda-emacs\"))
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun e/cat (path)
    \"Return the contents of FILENAME.\"
    (with-temp-buffer
      (insert-file-contents path)
      (buffer-string)))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs (e/cat \"/root/.emacs.d/host/pen.el/scripts/lambda-emacs\"))
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun e/cat (path)
    \"Return the contents of FILENAME.\"
    (with-temp-buffer
      (insert-file-contents path)
      (buffer-string)))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs (e/cat \"/root/.emacs.d/host/pen.el/scripts/lambda-emacs\"))
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
  (setq mode-line-format nil)
  (setq-default mode-line-format nil)
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)

  (define-key key-translation-map (kbd \"C-M-k\") (kbd \"<up>\"))
  (define-key key-translation-map (kbd \"C-M-j\") (kbd \"<down>\"))
  (define-key key-translation-map (kbd \"C-M-h\") (kbd \"<left>\"))
  (define-key key-translation-map (kbd \"C-M-l\") (kbd \"<right>\"))

  (defun e/cat (path)
    \"Return the contents of FILENAME.\"
    (with-temp-buffer
      (insert-file-contents path)
      (buffer-string)))

  (defun str (thing)
    \"Converts object or string to an unformatted string.\"

    (if thing
        (if (stringp thing)
            (substring-no-properties thing)
          (progn
            (setq thing (format \"%s\" thing))
            (set-text-properties 0 (length thing) nil thing)
            thing))
      \"\"))

  (defvar new-buffer-hooks '())

  (defun my-new-buffer-frame (&optional contents bufname mode nodisplay)
    \"Create a new frame with a new empty buffer.\"
    (interactive)
    (if (not bufname)
        (setq bufname \"*untitled*\"))
    (let ((buffer (generate-new-buffer bufname)))
      (set-buffer-major-mode buffer)
      ;; (display-buffer buffer '(display-buffer-pop-up-frame . nil))
      (if (not nodisplay)
          (display-buffer buffer '(display-buffer-same-window . nil)))
      (with-current-buffer buffer
        (if contents (insert (str contents)))
        (beginning-of-buffer)
        (run-hooks 'new-buffer-hooks))
      buffer))
  (defalias 'new-buffer-from-string 'my-new-buffer-frame)
  (defalias 'nbfs 'my-new-buffer-frame)

  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (with-current-buffer (nbfs (e/cat \"/root/.emacs.d/host/pen.el/scripts/lambda-emacs\"))
    (local-set-key \"q\" 'save-buffers-kill-terminal)
    (read-only-mode 1))
  (message \"\"))" "#" "<==" "nvim"
