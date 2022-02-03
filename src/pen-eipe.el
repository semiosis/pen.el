;; This is for creating a read-only area at the top of human input buffers
;; - used to place the prompt
;; - used to tell the user what they are doing

;; purple is a good font for a prompt
;; human(red) / ai(blue)
(defface pen-read-only
  '((t :foreground "#8b26d2"
       :background "#2e2e2e"
       :weight normal
       :slant italic
       :underline t))
  "Read only face."
  :group 'pen-faces)

(defun pen-eipe-set-prompt-ro (end)
  ;; Frustratingly, I can't seem to make the start of the buffer readonly
  ;; Maybe I can configure self-insert-command in the future.
  (ignore-errors
    (put-text-property (point-min) end 'face 'pen-read-only)

    ;; Don't actually use read-only because it causes too many problems
    ;; (put-text-property (point-min) end 'read-only t)

    ;; Unfortunately, I need a way to:
    ;; - *Not* use the preceding faces/text state etc. when typing text
    ;; - Disable typing at the start of the document

    (put-text-property (point-min) end 'pen-eipe-prompt t)
    (eval
     `(try (goto-char (+ 1 ,end))
           (goto-char ,end)
           nil))))

(defun pen-find-file-read-only-context ()
  ;; Also ensure this is an eipe in the first place
  ;; Either that or remove the file when done with it
  (let ((fp (concat "~/.pen/eipe/" (pen-daemon-name) "_prompt")))
    (if (f-exists-p fp)
        (let* ((prompt (slurp-file fp))
               ;; (charlen (string-bytes prompt))
               (charlen (length prompt)))
          (pen-eipe-set-prompt-ro (+ 1 charlen))
          (f-delete fp t)))))

(defmacro setface (name spec doc)
  `(custom-set-faces (list ',name
                           ,spec)))

(defmacro defsetface (name spec doc)
  `(progn
     (defface ,name ,spec ,doc)
     (setface ,name ,spec ,doc)))

(defsetface pen-human-prompt
  '((t :foreground "#f664b5"
       ;; :background "#c01565"
       :background "#111111"
       :weight bold
       :underline nil))
  "Face representing a prompt to a human user.")

(defsetface pen-none-face
  '((t
     ;; :foreground "#64b5f6"
     ;; :background "#1565c0"
     :foreground "#f664b5"
     :background "#111111"
     ;; :background "#c01565"
     :weight bold
     :underline nil))
  "Face representing a prompt to a human user.")

(defun pen-display-doc-overlay (info)
  (setq-local window-min-height 1)
  (lsp-ui-doc--display "pen" info))

(require 'lsp-ui-doc)
(defun pen-eipe-set-info-overlay (info)
  (pen-display-doc-overlay info))

;; This isn't ideal for human prompting because not all of the docs are displayed.
;; I might have to stick with an inline text prompt, sadly.
(defun pen-find-file-overlay-info ()
  (let ((fp (concat "~/.pen/eipe/" (pen-daemon-name) "_overlay")))
    (if (f-exists-p fp)
        (let* ((info (slurp-file fp)))
          ;; (end-of-buffer)
          ;; Annoyingly, this is needed to guarantee that we have
          ;; enough lines for the docs to appear
          ;; but it should be ok if the eipe is chomped
          ;; (insert "\n\n\n\n")

          ;; Still, I shouldn't do the above as the trailing newlines are usually accepted by the consuming function

          (beginning-of-buffer)
          (pen-eipe-set-info-overlay info)
          (f-delete fp t)))))

(defun pen-eipe-set-info-buffer (info)
  (let ((b (get-buffer-create "*pen-help*")))
    (with-current-buffer b
      (mark-whole-buffer)
      (delete-region (mark) (point))
      (insert (propertize info 'face 'pen-human-prompt)))
    (display-buffer
     (get-buffer-create "*pen-help*")
     '((display-buffer-below-selected display-buffer-at-bottom)
       (inhibit-same-window . t)
       (window-height . fit-window-to-buffer)))))

(defun pen-find-file-buffer-info ()
  (let ((fp (concat "~/.pen/eipe/" (pen-daemon-name) "_help")))
    (if (f-exists-p fp)
        (let* ((info (slurp-file fp)))
          (pen-eipe-set-info-buffer info)
          (f-delete fp t)))))

(defun pen-eipe-set-info-preoverlay (info)
  (overlay-put
   (make-overlay (point-min) (point-min))
   'after-string
   (concat (propertize info 'face 'pen-human-prompt)
           (propertize "\n" 'face 'pen-none-face))))

(defun pen-find-file-preoverlay-info ()
  (let ((fp (concat "~/.pen/eipe/" (pen-daemon-name) "_preoverlay")))
    (if (f-exists-p fp)
        (let* ((info (slurp-file fp)))
          (pen-eipe-set-info-preoverlay info)
          (f-delete fp t)))))

(defsetface off-button-face
  '((t :foreground "#222222"
       :background "#444444"
       :weight bold
       :underline t))
  "Face for off buttons.")

(defsetface on-button-face
  '((t :foreground "#444444"
       :background "#00aa00"
       :weight bold
       :underline t))
  "Face for on buttons.")

(define-button-type 'on-button 'follow-link t 'help-echo "Click to turn off" 'face 'on-button-face)
(define-button-type 'off-button 'follow-link t 'help-echo "Click to turn on" 'face 'off-button-face)

;; echo hi | pen-eipe -data '{"buttons": [{"label": "Abort", "command": "World Wide Web"}]}'
(defun pen-eipe-set-eipe-data (info)
  ;; This should generate an overlay buttons for accept and abort.
  ;; Load the json.
  ;; Then get a list of buttons, etc.
  ;; Generate them.

  (let* ((data (json-read-from-string info))
         (buttons (pen-vector2list (cdr (assoc 'buttons data)))))

    (if buttons
        (progn
          (loop for b in buttons do
                (let* ((label (cdr (assoc 'label b)))
                       (command (cdr (assoc 'command b)))
                       (type (or (cdr (assoc 'type b))
                                 'on-button)))

                  (overlay-put
                   (make-overlay (point) (point))
                   'after-string
                   (propertize
                    " "
                    'face 'pen-none-face))

                  ;; Don't use buttons
                  ;; Instead use a clickable overlay similar to this
                  ;; j:lsp-ui-sideline--code-actions
                  (insert-button label
                                 'type
                                 (intern type)
                                 'action
                                 (eval `(lambda (b) (funcall ',(intern command)))))))

          (overlay-put
           (make-overlay (point) (point))
           'after-string
           (propertize "\n" 'face 'pen-none-face))))))

(defun pen-find-file-eipe-data ()
  (let ((fp (concat "~/.pen/eipe/" (pen-daemon-name) "_eipe_data")))
    (if (f-exists-p fp)
        (let* ((info (slurp-file fp)))
          (pen-eipe-set-eipe-data info)
          (f-delete fp t)))))

(defset pen-eipe-hook '())

;; This needs to happen after the file is loaded
(add-hook 'pen-eipe-hook 'pen-find-file-read-only-context)
(add-hook 'pen-eipe-hook 'pen-find-file-buffer-info)
(add-hook 'pen-eipe-hook 'pen-find-file-overlay-info)
(add-hook 'pen-eipe-hook 'pen-find-file-preoverlay-info)
(add-hook 'pen-eipe-hook 'pen-find-file-eipe-data)

(defun run-eipe-hooks ()
  (interactive)
  (run-hooks 'pen-eipe-hook))

(add-hook 'find-file-hooks 'run-eipe-hooks t)

(provide 'pen-eipe)