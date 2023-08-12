(require 'pen-custom)

;; M-m is better than M-l

;; This is not the same as change dir / cd. If you're in ranger, then open with ranger, etc.
(defun pen-open-dir (dir)
  (setq dir (pen-umn dir))
  (cond
   ;; Both dired-mode and ranger-mode can be true at the same time. Therefore, ranger must precede
   ((derived-mode-p 'ranger-mode) (ranger dir))
   ((derived-mode-p 'dired-mode) (dired dir))
   (t (dired dir))))

(defun sh-file-p (fp)
  (pen-snq (cmd "test" "-f" fp)))

(defun cat-filter-exists (fp)
  ;; (-filter 'f-exists-p (pen-str2lines (cat fp)))
  (-filter 'sh-file-p (pen-str2lines (cat fp))))

(df fz-find-ws-music (e (concat "$HOME/notes/ws/music/" (fz (b find "$HOME/notes/ws/music" -type f -mindepth 1 -maxdepth 1 | sed "s=.*/==") nil nil "fz-find-ws-music: "))))
(df fz-find-ws (e (concat "$HOME/notes/ws/" (fz (b find "$HOME/notes/ws" -type d -mindepth 1 -maxdepth 1 | sed "s=.*/==") nil nil "fz-find-ws: "))))
(df fz-find-dir (e (fz (cat-filter-exists "$HOME/notes/directories.org") nil nil "fz-find-dir: ")))
(df fz-find-src (e (fz (cat-filter-exists "$HOME/notes/files.txt") nil nil "fz-find-src: ")))
(df fz-find-config (e (fz (b tm-list-config | pen-mnm | pen-str uniq) nil nil "fz-find-config: ")))

(defun swiper-swiper-dir (&optional dir)
  (interactive (list (read-string-hist "swiper dir:")))
  (with-current-buffer
      (dired dir)
    (call-interactively 'swiper)
    (ekm "RET")
    (call-interactively 'swiper)
    ;; (call-interactively 'pen-counsel-ag)
    ))

(defun swiper-swiper-glossaries ()
  (interactive)
  (swiper-swiper-dir pen-glossaries-directory))

(defun ag-glossaries ()
  (interactive)
  (ag-dir pen-glossaries-directory))

(defun swiper-glossaries ()
  (interactive)
  (swiper-dir pen-glossaries-directory))

(defun ag-ws ()
  (interactive)
  (dired "/root/.pen/documents/notes/ws"))

;; (pen-mu (s-replace-regexp "^$DUMP\\(.*\\)$" "\\1" "/home/shane/dump/home/shane/notes"))

(defun dired-toggle-dumpd-dir ()
  (interactive)
  (pen-mu (let* ((cwd (pen-umn (pen-pwd)))
             (newdir (if (string-match-p "^$DUMP" cwd)
                         (s-replace-regexp "^$DUMP\\(.*\\)$" "\\1" "/home/shane/dump/home/shane/notes")
                       (concat "$DUMP" cwd))))
        (/mkdir-p newdir)
        (pen-open-dir newdir))))

(define-key dired-mode-map (kbd "M-c") 'dired-toggle-dumpd-dir)
(define-key ranger-mode-map (kbd "M-c") 'dired-toggle-dumpd-dir)

;; (ms "/M-m/{p;s/M-m/M-l/}"
;;     (define-key pen-map (kbd "M-m d w") 'fz-find-ws))

(defun dired-fz-git-repo ()
  (interactive)
  (let ((sel (fz (chomp (pen-sn "list-git-repos"))))
        (dir (concat "/root/repos/" sel)))
    (if (and (str-or sel) (f-directory-p dir)))))


(provide 'pen-directory-navigation)
