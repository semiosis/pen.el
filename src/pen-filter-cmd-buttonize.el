;; Given an external filter script, which finds substrings of a file,
;; buttonize those strings within in the buffer. Clicking on one of
;; these buttons should do something

(defsetface filter-cmd-button-face
  '((t :foreground "#66cc00"
       ;; It's better for the glossary buttons to have no background, so normal syntax things, such as LSP highlighting can still be visible
       ;; underline is enough
       ;; :background "#2e2e2e"
       :background nil
       :weight bold
       :underline t))
  "Face for filter-cmd buttons.")

(define-button-type 'filter-cmd-button 'follow-link t 'help-echo "Click to run command" 'face 'filter-cmd-button-face)

(defset filter-cmd-buttonize-2-tuples
  ;; TODO Replace %q with a quoted argument
  '(
    ;; ("scrape \"\\bami-[a-z0-9]+\\b\"" "sps zrepl -cm pavit aws ec2 describe-images --image-ids %q")
    ;; ("sed -n 's/.*instance_type\\s*=\\s*\"\\([^\"]*\\)\".*/\\1/p'" "sps zrepl -cm pavit aws ec2 describe-instance-types --instance-types")
    ;; ("sed -n 's/.*instance_type\\s*=\\s*\"\\([^\"]*\\)\".*/\\1/p'" "sps aws-list-instance-types")
    ;; ("sed -n 's/\\bregion\\s*=\\s*\"\\([^\"]*\\)\".*/\\1/p'" "sps aws-list-regions")
    ;; ("sed -n 's/.*\\bowners\\s*=\\s*\\[\"\\([^\"]*\\)\"\\].*/\\1/p'" "sps aws-list-image-names-from-owner")
    ;; ("json2hcl -reverse | jq -r '.data[].aws_ami[][][].owners[]'" "sps aws-list-image-names-from-owner")
    ;; ("sed -n 's/^resource \\s*\"\\([^\\\"]*\\)\" \"[^\\\"]*\" *{$/\\1/p'" "go-to-terraform-resource %q")
    ;; ("scrape-terraform-resource" "go-to-terraform-resource %q")
    ;; ("scrape-bible-references" "bible-open %q")
    ))


(add-hook 'terraform-mode-hook 'make-buttons-for-all-filter-cmds)


(defun remove-filter-cmd-buttons-over-region (beg end)
  (interactive "r")
  (remove-overlays beg end 'face 'filter-cmd-button-face))

(defun remove-all-filter-cmd-buttons (beg end)
  (interactive "r")
  (remove-filter-cmd-buttons-over-region (point-min) (point-max)))
(defalias 'clear-filter-cmd-buttons 'remove-all-filter-cmd-buttons)

(defun get-filter-cmd-button-data-at (p)
  (interactive (list (point)))
  (-filter
   (lambda (tp)
     (apply 'gnus-and tp))
   (cl-loop
    for
    o
    in
    (overlays-at p)
    collect
    (list
     (button-get o 'term)
     (button-get o 'runfunc)
     (button-get o 'filtercmd)))))

(defun filter-cmd-button-pressed (button)
  "When I press a filtercmd button, it should run the button's function"
  (let* (
         ;; (term (button-get-text button))
         (term (button-get button 'term))
         (runfunc (button-get button 'runfunc))
         (start (button-start button))
         (filtercmd (button-get button 'filtercmd))
         (buttons-data-here (get-filter-cmd-button-data-at start)))

    (if (< 1 (length buttons-data-here))
        (let* ((button-line (pen-umn (fz (pen-mnm (pp-map-line buttons-data-here)))))
               (button-tuple (if button-line
                                 (pen-eval-string (concat "'" button-line))))
               (selected-button (if button-tuple
                                    (car (-filter (lambda (li) (and (equal (first button-tuple) (button-get li 'term))
                                                               (equal (cadr button-tuple) (button-get li 'runfunc))
                                                               (equal (third button-tuple) (button-get li 'filtercmd))))
                                                  (overlays-at start))))))
          (if selected-button
              (progn
                (setq button selected-button)
                ;; (setq term (button-get-text button))
                (setq term (button-get button 'term))
                (setq runfunc (button-get button 'runfunc))
                (setq start (button-start button))
                ;; filtercmd isnt used here
                (setq filtercmd (button-get button 'filtercmd))
                (setq buttons-data-here (get-filter-cmd-button-data-at start)))
            (backward-char))))
    (cond
     ((equal current-prefix-arg (list 4)) (setq current-prefix-arg nil))
     ((not current-prefix-arg) (setq current-prefix-arg (list 4))))

    (funcall runfunc term)))

(defun create-buttons-for-filtrate (term beg end filtercmd runfunc buttontype)
  ""
  (if (not buttontype)
      (setq buttontype 'filter-cmd-button))

  (goto-char beg)
  (let ((pat
         (concat
          "\\(\\b\\|[. ']\\|^\\)"
          (regexp-quote term)
          "s?\\(\\b\\|[. ']\\|$\\)")))
    (while (re-search-forward pat end t)
      (progn
        ;; (message "%s" (concat "searching forward " (str (point))))
        (let ((contents (match-string 0))
              (beg (match-beginning 0))
              (end (match-end 0)))
          (make-button
           (if (string-match "^[ '.].*" contents)
               (+ beg 1)
             beg)
           (if (string-match ".*[' .]$" contents)
               (- end 1)
             end)
           'term term
           'runfunc runfunc
           'filtercmd filtercmd
           'action 'filter-cmd-button-pressed
           'type buttontype))))))

(defun make-buttons-for-filter-cmd (beg end filtercmd runcmd &optional clear-first)
  "Makes buttons for terms found by filter-cmd in this buffer."
  (interactive (list (point-min)
                     (point-max)
                     (read-string-hist "filter-cmd: ")
                     (read-string-hist "runcmd %s: ")))

  (if clear-first (remove-all-filter-cmd-buttons))

  (let* ((terms (-filter 'sor (-uniq (pen-str2list (pen-snc filtercmd (region2string beg end))))))
         (runfunc (eval `(lambda (term) (sn
                                         (if (string-match "%q" ,runcmd)
                                             (s-replace-regexp "%q" (pen-q term) ,runcmd)
                                           (concat ,runcmd " " (pen-q term))))))))
    (if (not (or (derived-mode-p 'org-modmfse)
                 (derived-mode-p 'outline-mode)
                 (string-equal (buffer-name) "*glossary cloud*")))
        (save-excursion
          (cl-loop for term in terms do
                   (progn
                     (message "creating for %s" term)
                     (create-buttons-for-filtrate
                      term
                      beg end
                      ;; This is just to make it easy to introspect
                      filtercmd
                      runfunc
                      'filter-cmd-button)))))))

(defun make-buttons-for-all-filter-cmds (&optional clear-first)
  (interactive)
  (cl-loop for tp in filter-cmd-buttonize-2-tuples do
           (make-buttons-for-filter-cmd
            (point-min) (point-max)
            (car tp)
            (cadr tp)
            clear-first)))

(provide 'pen-filter-cmd-buttonize)
