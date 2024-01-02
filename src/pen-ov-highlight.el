(add-to-list 'load-path "/root/repos/ov-highlight")
(require 'ov-highlight)

(defvar hl-dir (umn "$PEN/document-highlights"))
(if (f-dir-p pen-confdir)
    (mkdir-p hl-dir))

(defun ov-highlight-dired-open-dir ()
  (interactive)
  (dired hl-dir))

(defun ov-highlight-save ()
  "Save highlight information.
Data is saved in comment in the document."
  (let* ((data (ov-highlight-get-highlights))
         ;; (data-serialised (base64-encode-string (format "%S" data) t))
         (data-serialised
          ;; (format "%S" data)
          (pp-to-string data))
         (fileslug (concat
                    (f-join hl-dir (slugify (get-path nil t)))
                    ".sexp")))

    (if data
        (write-to-file data-serialised fileslug))

    (unless data
      ;; cleanup if we have no highlights
      (remove-hook 'before-save-hook 'ov-highlight-save t)
      (delete-file-local-variable 'ov-highlight-data))))

(defun ov-highlight-load ()
  "Load and apply highlighted text."
  (interactive)

  (message "Loading highlights...")
  (let ((fileslug (concat
                   (f-join hl-dir (slugify (get-path nil t)))
                   ".sexp")))

    (if (f-exists-p fileslug)
        (setq-local ov-highlight-data (e/cat fileslug))
      (setq-local ov-highlight-data nil))

    (mapc
     (lambda (entry)
       (let ((beg (nth 0 entry))
             (end (nth 1 entry))
             (properties (nth 2 entry)))
         (flyspell-delete-region-overlays beg end)
         (let ((ov (make-overlay beg end)))
           (apply 'ov-put ov properties)
           (set-buffer-modified-p t)
           (let ((p (point)))
             (when (mark)
               (deactivate-mark))
             (goto-char p))
           ov)))
     (when ov-highlight-data
       (read
        ;; disable base64
        ;; (base64-decode-string (or ov-highlight-data ""))
        (or ov-highlight-data ""))))

    (add-hook 'before-save-hook 'ov-highlight-save nil t)
    ;; loading marks the buffer as modified, because the overlay functions mark
    ;; it, but it isn't. We mark it unmodified here.
    (set-buffer-modified-p nil))
  (message "Loading highlights... DONE!"))

;; (define-key global-map (kbd "H-a") 'annotate-annotate)
;; (define-key global-map (kbd "H-a") 'ov-highlight/body)
(define-key global-map (kbd "s-a") 'ov-highlight/body)

;; TODO Make it so the comments save to disk
;; j:ov-highlight-make

(provide 'pen-ov-highlight)
