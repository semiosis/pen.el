(require 'wgrep)

;; To save all buffer changes automatically when wgrep-finish-edit.
(setq wgrep-auto-save-buffer t)

(define-key wgrep-mode-map (kbd "C-m") #'compile-goto-error)
(define-key wgrep-mode-map (kbd "RET") #'compile-goto-error)

;; This needed an umn to allow wgrep / ead to minimise paths
(defun wgrep-gather-editor ()
  (let (res)
    (dolist (edit-field (wgrep-edit-field-overlays))
      (goto-char (overlay-start edit-field))
      (forward-line 0)
      (cond
       ;; ignore removed line or removed overlay
       ((eq (overlay-start edit-field) (overlay-end edit-field)))
       ((get-text-property (point) 'wgrep-line-filename)
        (let* ((name (get-text-property (point) 'wgrep-line-filename))
               (linum (get-text-property (point) 'wgrep-line-number))
               (start (next-single-property-change
                       (point) 'wgrep-line-filename nil (point-at-eol)))
               (file (expand-file-name (pen-umn name) default-directory))
               (file-error nil)
               (old (overlay-get edit-field 'wgrep-old-text))
               (new (overlay-get edit-field 'wgrep-edit-text))
               result)
          ;; wgrep-result overlay show the commiting of this editing
          (catch 'done
            (dolist (o (overlays-in (overlay-start edit-field) (overlay-end edit-field)))
              (when (overlay-get o 'wgrep-result)
                ;; get existing overlay
                (setq result o)
                (throw 'done t)))
            ;; create overlay to show result of committing
            (setq result (wgrep-make-overlay start (overlay-end edit-field)))
            (overlay-put result 'wgrep-result t))
          (setq res
                (cons
                 (list file (list linum old new result edit-field))
                 res))))))
    (nreverse res)))

;; Can't change for existence if pen-i am mnm the grep list because it will spawn too many mnm
(defun wgrep-parse-command-results ()
  (let ((cache (make-hash-table)))
    (while (not (eobp))
      (cond
       ((looking-at wgrep-line-file-regexp)
        (let* ((fn (match-string-no-properties 1))
               (line (string-to-number (match-string 3)))
               (start (match-beginning 0))
               (end (match-end 0))
               (fstart (match-beginning 1))
               (fend (match-end 1))
               (lstart (match-beginning 3))
               (lend (match-end 3))
               (fprop (wgrep-construct-filename-property fn))
               (flen (length fn)))
          (when (or (gethash fn cache nil)
                    (and
                     (puthash fn t cache)))
            (put-text-property start end 'wgrep-line-filename fn)
            (put-text-property start end 'wgrep-line-number line)
            (put-text-property start (+ start flen) fprop fn)
            (save-excursion
              (wgrep-prepare-context-while fn line -1 fprop flen))
            (wgrep-prepare-context-while fn line 1 fprop flen)
            (forward-line -1))))
       (t
        ;; Add property but this may be removed by `wgrep-prepare-context-while'
        (put-text-property
         (point-at-bol) (point-at-eol)
         'wgrep-ignore t)))
      (forward-line 1))))

(define-key wgrep-mode-map (kbd "C-c C-j") #'ivy-wgrep-change-to-wgrep-mode)

(provide 'pen-wgrep)
