(defvar-local pen-ui-doc--inline-ov nil
  "Overlay used to display the documentation in the buffer.")

(defvar-local pen-ui-doc--parent-vars nil
  "Variables from the parents frame that we want to access in the child.
Because some variables are buffer local.")

(defconst pen-ui-doc--buffer-prefix " *pen-ui-doc-")

(defun pen-ui-doc--make-buffer-name ()
  "Construct the buffer name, it should be unique for each frame."
  (concat pen-ui-doc--buffer-prefix
          (or (frame-parameter nil 'window-id)
              (frame-parameter nil 'name))
          "*"))

(defmacro pen-ui-doc--with-buffer (&rest body)
  "Execute BODY in the pen-ui-doc buffer."
  (declare (indent 0) (debug t))
  `(let ((parent-vars (list :buffer (current-buffer)
                            :window (get-buffer-window)))
         (buffer-list-update-hook nil))
     (with-current-buffer (get-buffer-create (pen-ui-doc--make-buffer-name))
       (setq pen-ui-doc--parent-vars parent-vars)
       (prog1 (let ((buffer-read-only nil)
                    (inhibit-modification-hooks t)
                    (inhibit-point-motion-hooks t)
                    (inhibit-redisplay t))
                ,@body)
         (setq buffer-read-only t)
         (let ((text-scale-mode-step 1.1))
           (text-scale-set lsp-ui-doc-text-scale-level))))))

(defun pen-ui-doc--inline-height ()
  (pen-ui-doc--with-buffer
   (length (split-string (buffer-string) "\n"))))

(defun lsp-ui-doc--make-request nil
  "Request the documentation to the LS."
  (and (not track-mouse) lsp-ui-doc-show-with-mouse (setq-local track-mouse t))
  (when (and lsp-ui-doc-show-with-cursor
             (not (memq this-command lsp-ui-doc--ignore-commands))
             (not (bound-and-true-p lsp-ui-peek-mode))
             (lsp--capability "hoverProvider"))
    (-if-let (bounds (or (and (symbol-at-point) (bounds-of-thing-at-point 'symbol))
                         (and (looking-at "[[:graph:]]") (cons (point) (1+ (point))))))
        (unless (equal lsp-ui-doc--bounds bounds)
          (lsp-ui-doc--hide-frame)
          (lsp-ui-util-safe-kill-timer lsp-ui-doc--timer)
          (setq lsp-ui-doc--timer
                (run-with-idle-timer
                 lsp-ui-doc-delay nil
                 (let ((buf (current-buffer)))
                   (lambda nil
                     (when (equal buf (current-buffer))
                       (lsp-request-async
                        "textDocument/hover"
                        (lsp--text-document-position-params)
                        (lambda (hover)
                          (when (equal buf (current-buffer))
                            (lsp-ui-doc--callback hover bounds (current-buffer))))
                        :mode 'tick
                        :cancel-token :lsp-ui-doc-hover)))))))
      (lsp-ui-doc--hide-frame))))

(defun pen-ui-doc--hide-frame (&optional _win)
  "Hide the frame."
  (setq lsp-ui-doc--bounds nil
        lsp-ui-doc--from-mouse nil)
  (lsp-ui-util-safe-delete-overlay pen-ui-doc--inline-ov))

(defun pen-ui-doc--inline ()
  "Display the doc in the buffer."
  (-let* ((height (pen-ui-doc--inline-height))
          ((start . end) (lsp-ui-doc--inline-pos height))
          (buffer-string (buffer-substring start end))
          (ov (if (overlayp pen-ui-doc--inline-ov) pen-ui-doc--inline-ov
                (setq pen-ui-doc--inline-ov (make-overlay start end)))))
    (move-overlay ov start end)
    (overlay-put ov 'face 'default)
    (overlay-put ov 'display (lsp-ui-doc--inline-merge buffer-string))
    (overlay-put ov 'lsp-ui-doc-inline t)
    (overlay-put ov 'window (selected-window))))

(defun pen-ui-doc--visible-p ()
  "Return whether the LSP UI doc is visible"
  (or (overlayp pen-ui-doc--inline-ov)
      (and (lsp-ui-doc--get-frame)
           (frame-visible-p (lsp-ui-doc--get-frame)))))

(defun pen-ui-doc--glance-hide-frame ()
  "Hook to hide hover information popup for `lsp-ui-doc-glance'."
  (when (or (overlayp pen-ui-doc--inline-ov)
            (lsp-ui-doc--frame-visible-p))
    (pen-ui-doc--hide-frame)
    (remove-hook 'post-command-hook 'pen-ui-doc--glance-hide-frame)
    ;; make sure child frame is unfocused
    (setq lsp-ui-doc--unfocus-frame-timer
          (run-at-time 1 nil #'lsp-ui-doc-unfocus-frame))))

(provide 'pen-overlay-doc)
