(defun find-thing (thing)
  (interactive)
  (if (stringp thing)
      (setq thing (intern thing)))

  (try
   (pen-goto-package thing)
   (find-function thing)
   (find-variable thing)
   (find-face-definition thing)

   (pen-ns (concat (str thing) " is neither function nor variable"))))
(defalias 'j 'find-thing)
(defalias 'ft 'find-thing)

(defmacro progn-read-only-disable (&rest body)
  `(progn
     (if buffer-read-only
         (progn
           (read-only-mode -1)
           (let ((res
                  ,@body))
             res)
           (read-only-mode 1))
       (progn
         ,@body))))

(defun gl-find-deb (query)
  (interactive (list (read-string-hist "binary name: ")))
  (wget (fz (pen-cl-sn (pen-concat "find-deb " query) :chomp t))))

(defun zcd (dir)
  (interactive (list (read-directory-name "zcd: ")))
  (pen-sps (pen-cmd "zcd" dir)))

(defun byte-pos ()
  (position-bytes (point)))

(defun date-ts ()
  (string-to-number (format-time-string "%s")))

(defun edit-var-elisp (variable &optional buffer frame)
  (interactive
   (let ((v (variable-at-point))
         (enable-recursive-minibuffers t)
         (orig-buffer (current-buffer))
         val)
     (setq val (completing-read
                (if (symbolp v)
                    (format
                     "Describe variable (default %s): " v)
                  "Describe variable: ")
                #'help--symbol-completion-table
                (lambda (vv)
                  ;; In case the variable only exists in the buffer
                  ;; the command we switch back to that buffer before
                  ;; we examine the variable.
                  (with-current-buffer orig-buffer
                    (or (get vv 'variable-documentation)
                        (and (boundp vv) (not (keywordp vv))))))
                t nil nil
                (if (symbolp v) (symbol-name v))))
     (list (if (equal val "")
               v (intern val)))))
  (with-current-buffer
      (new-buffer-from-string (concat "(setq " (symbol-name variable) "\n'" (pp (eval variable)) ")"))
    (emacs-lisp-mode)))
(defalias 'evar 'edit-var-elisp)

;; doesn't work perrfectly. But it's useful.
;; http:/grapevine.net.au$HOMEstriggs/elisp/emacs-homebrew.el
;; Useful custom functions
(defun reselect-last-region ()
  (interactive)
  (let ((start (mark t))
        (end (point)))
    (goto-char start)
    (call-interactively' set-mark-command)
    (goto-char end)))
(defalias 'reselect 'reselect-last-region)
(defalias 'activate-region 'reselect-last-region)

(defun current-file-path ()
  buffer-file-name)

(defun current-file-name ()
  (if buffer-file-name (basename buffer-file-name)))

(defun file-delete (path &optional force)
  "Delete PATH, which can be file or directory."
  (if (or (file-regular-p path) (not (not (file-symlink-p path))))
      (delete-file path)
    (delete-directory path force)))

(defun open-next-file ()
  (interactive)
  ;; This works but killing the buffer is a little dangerous
  ;; (ekm "M-m f d <up> RET M-l M-m <M-f4>")
  (if (current-file-name)
      (let ((next-file (chomp (pen-sn (concat "next-file " (pen-q (basename (current-file-name)))) nil (current-dir-name)))))
        (if next-file (find-file next-file) (message "%s" "Cannot move further")))
    (message "%s" "No current file name")))

(defun open-prev-file ()
  (interactive)
  ;; This works but killing the buffer is a little dangerous
  ;; (ekm "M-m f d <down> RET M-l M-m <M-f4>")
  (if (current-file-name)
      (let ((prev-file (chomp (pen-sn (concat "prev-file " (pen-q (basename (current-file-name)))) nil (current-dir-name)))))
        (if prev-file (find-file prev-file) (message "%s" "Cannot move further")))
    (message "%s" "No current file name")))

(defun cat-to-file (stdin file_path)
  ;; The ignore-errors is needed for babel for some reason
  (ignore-errors (with-temp-buffer
                   (insert stdin)
                   (delete-file file_path)
                   (write-file file_path))))
(defalias 'write-string-to-file 'cat-to-file)
(defalias 'write-to-file 'cat-to-file)

(defun append-uniq-to-file (stdin file_path)
  (sn
   (concat "cat " (q file_path) " | uniqnosort | sponge " (q file_path)) stdin))

;; append-to-file is a builtin. I shouldn't do this
(defun my-append-to-file (stdin file_path)
  (sn
   (concat "cat >> " (q file_path)) stdin))
(defalias 'append-string-to-file 'my-append-to-file)

(defun new-buffer-from-string-or-selected (&optional s)
  (interactive)
  (if (and (pen-selected-p)
           (not s))
      (new-buffer-from-string (pen-selected-text))
    (new-buffer-from-string s)))

;; si and uncmd are used for tabulated list
(defun si (category input &rest args)
  ;; input may also be nil

  (ignore-errors (pen-snc (concat "si +" category " " (pen-list2cmd args)) (pps input)))
  input)

(defun uncmd (s)
  (pen-str2lines (pen-snc (concat "pl " s))))

(defun list2vec (l)
  (apply 'vector l))

(defun pen-apropos-function (pattern)
  (-filter 'functionp
           (apropos-internal pattern)))

(defun pen-join-line ()
  (interactive)
  (save-excursion
    (next-line)
    (join-line)))

(defun copy-current-line-position-to-clipboard ()
  "Copy current line in file to clipboard as '</path/to/file>:<line-number>'"
  (interactive)
  (let ((path-with-line-number
         (concat buffer-file-name ":" (number-to-string (line-number-at-pos)))))
    ;;(x-select-text path-with-line-number)
    (xc path-with-line-number)
    (message "%s" (concat path-with-line-number " copied to clipboard"))))

(defun pen-what-face ()
  "Shows the face for what's under the cursor."
  (interactive)
  (ekm "C-u C-x ="))
(defalias 'what-face 'pen-what-face)

(defun last-line-of-buffer-p ()
  "Return non-nil if the cursor is at the last line of the
buffer."
  (save-excursion (end-of-line) (/= (forward-line) 0)))

(defun pen-start-process (command)
  (interactive (list (read-string-hist "command: ")))
  (with-current-buffer
      (switch-to-buffer command)
    (start-process
     command
     (current-buffer)
     command)))

(defun pen-join (list-of-things &optional delim)
  "Joins a list of strings."
  (if (not delim) (setq delim "\n"))
  (mapconcat 'identity (mapcar 'str list-of-things) delim))

(defun show-environment ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (tpop "vs" (list2str process-environment))
    (if (inside-tmux-p)
        (nbfs (list2str process-environment))
      (tpop "vs" (list2str process-environment)))))

(defun noop (&rest args)
  "Do nothing."
  nil)

(defalias 'detect-language-set-mode 'guess-major-mode)

(defun getline (&optional number)
  (chomp
   (str
    (if number
        (save-excursion
          (goto-line number)
          (thing-at-point 'line))
      (thing-at-point 'line)))))

(defalias 'get-line 'getline)

(defun test-f (filename)
  (file-exists-p (umn filename)))

(defun test-s (filename)
  (not (denote--file-empty-p (umn filename))))

(defun pen-switch-to-buffer-for-pen-e (ret)
  (if (bufferp ret)
      (switch-to-buffer ret)))

(defun crc32 (s)
  (pen-snc "hash-crc32" s))

(defun elisp-serialise (o)
  ;; I guess this works a lot like pps
  (format "%S" o))

(provide 'pen-utils)
