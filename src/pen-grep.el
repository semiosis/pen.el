(require 's)
(require 'wgrep)

(defun vc-get-top-level ()
  (s-replace-regexp "/$" "" (projectile-project-root)))

(defun sps-ead-thing-at-point ()
  (interactive)
  ;; TODO complete pen-ead
  (pen-sph (concat "pen-ead " (pen-q (pen-eatify (str (pen-thing-at-point)))))))

(defun pen-grep-eead-on-results (paths query)
  (interactive (list
                (grep-get-paths)
                (read-string "pen-ead:")))
  (pen-eead-thing-at-point query paths))

(defun pen-wgrep-thing-at-point (s &optional dir)
  (interactive (list (pen-thing-at-point)))
  (if (major-mode-p 'grep-mode)
      (call-interactively 'pen-grep-eead-on-results)
    (if dir
        (wgrep (pen-eatify (str s)) dir)
      (if (>= (prefix-numeric-value current-prefix-arg) 4)
          ;; use top dir if prefix is specified
          (let ((current-prefix-arg nil))
            (wgrep (pen-eatify (str s)) (vc-get-top-level)))
        ;; use current directory by default
        (wgrep (pen-eatify (str s)) (my/pwd))))))

(defun pen-eatify (pat)
  (if (re-match-p "^[a-zA-Z_]" pat)
      (setq pat (concat "\\b" pat)))
  (if (re-match-p "[a-zA-Z_]$" pat)
      (setq pat (concat pat "\\b")))
  pat)

;; This is so nice and fast! I should definitely stay within emacs!
(defun pen-eead-thing-at-point (&optional thing paths-string dir)
  (interactive (list (str (pen-thing-at-point))
                     nil
                     (get-top-level)))
  (let* ((cmd (concat "pen-ead " (pen-q (pen-eatify thing))))
         (cmdnoeat (if paths-string
                       (concat "pen-umn | uniqnosort | pen-ead " (pen-q thing))
                     (concat "pen-ead " (pen-q thing))))
         (slug (slugify cmdnoeat))
         (bufname (concat "*grep:" slug "*"))
         (results (string-or (pen-sn cmd paths-string)
                             (pen-sn cmdnoeat))))

    (with-current-buffer (new-buffer-from-string results
                                                 bufname)
      (cd dir)
      (grep-mode)
      (ivy-wgrep-change-to-wgrep-mode)
      (define-key compilation-button-map (kbd "C-m") 'compile-goto-error)
      (define-key compilation-button-map (kbd "RET") 'compile-goto-error)
      (visual-line-mode -1))))

(defun pen-grep-for-thing-select ()
  (interactive)
  (let ((action
         (pen-qa
          -h "here"
          -r "repo")))
    (cond
     ((string-equal "here" action)
      (call-interactively 'pen-wgrep-thing-at-point))
     ((string-equal "repo" action)
      (pen-wgrep-thing-at-point (pen-thing-at-point) (vc-get-top-level)))
     (t
      (call-interactively 'pen-wgrep-thing-at-point)))))

(define-key global-map (kbd "M-3") #'pen-grep-for-thing-select)

(provide 'pen-grep)