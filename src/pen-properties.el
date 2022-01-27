(defun force-alist (lambda)
  (mapcar 'force-keyvalue l))

(defun pen-format-json (stdin)
  "Formats the json."
  (pen-sn "python -m json.tool" stdin))

(defun true ()
  t)

(defun true-p (e)
  (if e t))

(defun get-car-val (e)
  (let ((s (car e)))
    (if (and (variable-p s)
             (true-p (eval s)))
        (str s))))

(defun get-enabled-minor-modes ()
  "Only list minor modes that are enabled"
  (remove '() (mapcar #'get-car-val minor-mode-alist)))

(defun get-current-mode-hook ()
  (let ((cmm (intern (concat (current-major-mode-string) "-hook"))))
    (if (variable-p cmm)
        cmm
      nil)))

(defun pen-buffer-properties ()
  `(("current-major-mode-string" . ,(try (current-major-mode-string)))
    ("current-minor-modes-string" . ,(try (get-enabled-minor-modes)))
    ("completion-at-point-functions" . ,(try completion-at-point-functions))
    ("company-backends" . ,(try company-backends))
    ("current-mode-hook" . ,(try (eval (get-current-mode-hook))))
    ("buffer-name" . ,(try (buffer-name)))))

(defun pen-json-encode-alist (alist)
  (pen-format-json (json-encode-alist alist)))

(defun pen-buffer-variables-json ()
  "Gets some properties of the current emacs buffer in json format."

  (pen-json-encode-alist (force-alist (buffer-local-variables))))

(defun pen-list-buffer-variables ()
  (mapcar 'car (buffer-local-variables)))

(defun pen-list-global-variables ()
  "Warning: it takes a long time to finish."

  ;; This doesnt return json
  ;; https://stackoverflow.com/questions/8031246/listing-all-top-level-global-variables-in-emacs

  (if (yes-or-no-p "This takes a long time. Continue?")
      (let ((result '()))
        (mapatoms (lambda (x)
                    (when (boundp x)
                      (let ((file (ignore-errors
                                    (find-lisp-object-file-name x 'defvar))))
                        (when file
                          (push (cons x file) result))))))
        result)))

(defun pen-global-variables-json ()
  (pen-list-global-variables))

(defun pen-emacs-properties-json ()
  "Gets some properties of the current emacs buffer in json format."
  (pen-json-encode-alist (emacs-properties)))

(defun pen-tvipe-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (cl-tvipe (pen-json-encode-alist
          `(("emacs-properties" ,(emacs-properties))
            ("pen-buffer-properties " ,(pen-buffer-properties)))) :tm_wincmd "sph" :b-nowait t :b-quiet t))

(defun pen-etv-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-json-encode-alist
                           `(("emacs-properties" ,(emacs-properties))
                             ("pen-buffer-properties " ,(pen-buffer-properties))))))

(defun pen-tvipe-pen-emacs-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (cl-tvipe (pen-emacs-properties-json) :tm_wincmd "sph" :b-nowait t :b-quiet t))

(defun pen-etv-pen-emacs-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-emacs-properties-json)))

(defun pen-jiq-pen-buffer-variables-json ()
  "Gets the local variables of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (cl-sh "jiq" :stdin (pen-buffer-variables-json) :tm_wincmd "sph" :b_wait t))

(defun pen-tvipe-pen-buffer-variables-json ()
  "Gets the local variables of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (cl-tvipe (pen-buffer-variables-json) :tm_wincmd "sph" :b-nowait t :b-quiet t))

(defun pen-etv-pen-buffer-variables-json ()
  "Gets the local variables of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-buffer-variables-json)))

(defun pen-etv-pen-global-variables-json ()
  "Gets the local variables of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-global-variables-json)))

(defun pen-tvipe-pen-buffer-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (cl-tvipe (pen-buffer-properties-json) :tm_wincmd "sph" :b-nowait t :b-quiet t))

(defun pen-etv-pen-buffer-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-buffer-properties-json)))

(define-key pen-map (kbd "M-l M-p M-v") 'pen-etv-pen-buffer-properties-json)

(provide 'pen-properties)