(defun force-alist (anonf)
  (mapcar 'force-keyvalue anonf))

(defun pen-format-json (stdin)
  "Formats the json."
  (pen-sn "python -m json.tool" stdin))

(defun true (&rest args)
  t)
(defalias 'always-true 'true)

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
        (mapatoms (λ (x)
                    (when (boundp x)
                      (let ((file (ignore-errors
                                    (find-lisp-object-file-name x 'defvar))))
                        (when file
                          (push (cons x file) result))))))
        result)))

(defun pen-global-variables-json ()
  (pen-list-global-variables))

(defun emacs-properties ()
  `(("worker/server name" . ,(pen-worker-name))
    ("after-init-hook" . ,(str after-init-hook))))

(defun pen-emacs-properties-json ()
  "Gets some properties of the current emacs buffer in json format."
  (pen-json-encode-alist (emacs-properties)))

(defun pen-tvipe-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (pen-cl-tvipe (pen-json-encode-alist
          `(("emacs-properties" ,(emacs-properties))
            ("pen-buffer-properties" ,(pen-buffer-properties)))) :tm_wincmd "sph" :b-nowait t :b-quiet t))

(defun pen-etv-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-json-encode-alist
                           `(("emacs-properties" ,(emacs-properties))
                             ("pen-buffer-properties" ,(pen-buffer-properties))))
                          nil 'json-mode))

(defun pen-tvipe-emacs-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (pen-cl-tvipe (pen-emacs-properties-json) :tm_wincmd "sph" :b-nowait t :b-quiet t))

(defun pen-etv-emacs-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-emacs-properties-json)
                          nil 'json-mode))

(defun pen-jiq-buffer-variables-json ()
  "Gets the local variables of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (cl-sh "jiq" :stdin (pen-buffer-variables-json) :tm_wincmd "sph" :b_wait t))

(defun pen-tvipe-buffer-variables-json ()
  "Gets the local variables of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (pen-cl-tvipe (pen-buffer-variables-json) :tm_wincmd "sph" :b-nowait t :b-quiet t))

(defun pen-etv-buffer-variables-json ()
  "Gets the local variables of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-buffer-variables-json)
                          nil 'json-mode))

(defun pen-etv-global-variables-json ()
  "Gets the local variables of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string (pen-global-variables-json)
                          nil 'json-mode))

(defun force-keyvalue (e)
  ;; Make a new list
  (ignore-errors
    (try
     (list
      (car e)
      (if (or (stringp (cdr e))
              (symbolp (cdr e))
              (numberp (cdr e)))
          (cdr e)
        nil))
     (list (car e) nil))))

;; (advice-add 'json-encode-key :around #'ignore-errors-around-advice)
;; (advice-remove 'json-encode-key #'ignore-errors-around-advice)

(defun buffer-variables-json ()
  "Gets some properties of the current emacs buffer in json format."
  (pen-json-encode-alist (force-alist (buffer-local-variables))))

(defun pen-tvipe-buffer-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (pen-cl-tvipe (pen-buffer-variables-json) :tm_wincmd "sph" :b-nowait t :b-quiet t))

(defun pen-etv-buffer-properties-json ()
  "Gets some properties of the current emacs buffer in json format and puts it into tmux."
  (interactive)
  (new-buffer-from-string
   (pen-buffer-variables-json)
   nil 'json-mode))

(define-key pen-map (kbd "M-l M-p M-v") 'pen-etv-buffer-properties-json)

(provide 'pen-properties)
