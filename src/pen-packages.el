(package-initialize)

(eval-after-load "polymode"
  (lambda nil
    (define-hostmode org-brain-poly-hostmode :mode 'org-brain-visualize-mode)
    (define-innermode org-brain-poly-innermode :mode 'org-mode :head-matcher "^[─-]\\{3\\} Entry [─-]+
" :tail-matcher "\\'" :head-mode 'host :tail-mode 'host)
    (define-polymode org-brain-polymode :hostmode 'org-brain-poly-hostmode :innermodes
      '(org-brain-poly-innermode)
      (setq-local polymode-move-these-vars-from-old-buffer
                  (delq 'buffer-read-only polymode-move-these-vars-from-old-buffer)))
    (defun org-brain-polymode-save nil "Save entry text to the entry's file."
           (interactive)
           (when
               (buffer-modified-p)
             (let
                 ((text
                   (save-excursion
                     (goto-char org-brain--vis-entry-text-marker)
                     (end-of-line)
                     (buffer-substring
                      (point)
                      (point-max)))))
               (find-file
                (org-brain-entry-path org-brain--vis-entry))
               (seq-let
                   (entry-min entry-max)
                   (org-brain-text-positions org-brain--vis-entry)
                 (goto-char entry-min)
                 (delete-region entry-min entry-max)
                 (insert text)
                 (unless
                     (looking-at-p "
")
                   (insert "

"))
                 (save-buffer)
                 (switch-to-buffer
                  (other-buffer
                   (current-buffer)
                   1))
                 (set-buffer-modified-p nil)))))
    (define-key org-brain-polymode-map "" 'org-brain-polymode-save)))

(defun pen-slurp-file (f)
  (with-temp-buffer
    (insert-file-contents f)
    (buffer-substring-no-properties
     (point-min)
     (point-max))))

(defun pen-load-list-file (f)
  "split-string splits the file into a list of strings. mapcar intern turns the list of strings into a list of symbols"
  (mapcar 'intern
          (split-string
           (pen-slurp-file f) "\n" t)))

;; Auto install package are installed if they are missing

(defvar package-list nil)

(defun pen-auto-load-packages ()
  (interactive)

  (let ((pl "~/.pen/emacs-packages.txt"))
    (if (f-exists-p pl)
        (progn
          (package-refresh-contents)
          (setq package-list
                (-uniq
                 (append
                  package-list
                  '(markdown-mode)
                  (pen-load-list-file
                   pl))))

          ;; This one requires emacs25
          ;; lsp-javascript-typescript

          ;; fetch the list of packages available
          (unless package-archive-contents
            (package-refresh-contents))

          ;; install the missing packages
          (dolist (package package-list)
            (unless (package-installed-p package)
              (yes (ignore-errors (package-install package)))))))))

;; TODO Definitely do not do this unless the main distro

;; Now that the packages have been installed, don't do it again
;; until I add more logic to control it.
;; (comment
;;  (if (string-equal (pen-daemon-name)
;;                    "DEFAULT")
;;      (pen-auto-load-packages)))

(define-key global-map (kbd "C-c h I") 'package-install)

(provide 'pen-packages)