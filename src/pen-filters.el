;; e:/root/.emacs.d/host/pen.el/scripts/filters

(defmacro pen-flash-region (&rest body)
  `(let ((fg "#00aa00")
         (bg "#006600")
         (fg_blue "#5555ff")
         (bg_blue "#2222bb")
         (fg_purple "#ff55ff")
         (bg_purple "#bb22bb")
         (fg_limegreen "#55ff55")
         (bg_limegreen "#22bb22")
         (fg_yellow "#ffff55")
         (bg_yellow "#bbbb22")
         (fg_orange "#ffA500")
         (bg_orange "#996200"))

     (set-face-foreground 'region fg_limegreen)
     (set-face-background 'region bg_limegreen)

     (sit-for 0.05)

     (let ((r ,@body))
       (set-face-foreground 'region fg)
       (set-face-background 'region bg)
       r)))

(defun pen-replace-region (s)
  (replace-region s))

(defun pen-region-filter (func)
  "Apply the function to the selected region. The function must accept a string and return a string."
  (let ((rstart (if (region-active-p) (region-beginning) (point-min)))
        (rend (if (region-active-p) (region-end) (point-max))))

    (let ((res
           (pen-flash-region
            (ptw func (buffer-substring rstart rend)))))
      (pen-replace-region res))))

(defun pen-region-pipe (cmd)
  "pipe region through shell command"
  (interactive (list (read-string "shell filter:")))

  (let ((gparg (prefix-numeric-value current-prefix-arg))
        (current-prefix-arg nil))
    (if (>= gparg 4) (setq cmd (concat "upd " cmd))))
  
  (if (not (sor cmd))
      (setq cmd "pen-tm filter"))
  (pen-region-filter (lambda (input) (pen-sn (concat cmd) input))))

(defun select-filter (&optional prompt type)
  (interactive (list "pen-fwfzf:"
                     (intern (fz '(filters extractors transformers grepfilters)
                                 nil nil "Filter type"))))
  (setq prompt (or prompt "pen-fwfzf:"))

  (let* ((dir (f-join pen-penel-directory "config/filters"))
         (filters
          (pcase type
            ('extractors
             ;; e:/root/.emacs.d/host/pen.el/config/filters/extractors.sh
             (cat (f-join dir "extractors.sh")))
            ('transformers
             ;; e:/root/.emacs.d/host/pen.el/config/filters/transformers.sh
             (cat (f-join dir "transformers.sh")))
            ('grepfilters
             ;; e:/root/.emacs.d/host/pen.el/config/filters/grepfilters.sh
             (cat (f-join dir "grepfilters.sh")))
            ('summarizers
             ;; e:/root/.emacs.d/host/pen.el/config/filters/summarizers.sh
             (cat (f-join dir "summarizers.sh")))
            (_
             ;; e:/root/.emacs.d/host/pen.el/config/filters/filters.sh
             (cat (f-join dir "filters.sh"))))))

    (chomp (esed " #.*" ""
                 (fz filters nil nil prompt)))))

;; Filter should include the extract and transform commands
(defun pen-fwfzf (&optional type manually)
  "This will pipe the selection into fzf filters, replacing the original region. If no region is selected, then the entire buffer is passed read only.

e:$EMACSD/pen.el/config/filters/filters.sh
"
  (interactive)

  (cond ((>= (prefix-numeric-value current-prefix-arg) 16)
         (call-interactively 'grepfilter))

        ;; Instead of this, send the prefix to pen-region-pipe so that I can UPDATE=y when I use C-u
        
        ;; ((>= (prefix-numeric-value current-prefix-arg) 4)
        ;;  (if (region-active-p)
        ;;      (pen-region-pipe "pen-tm filter")
        ;;    (pen-nil (pen-sn (concat "pen-tm -f -S -tout nw -noerror " (pen-q "f filter-with-fzf")) (buffer-string) nil nil t))))
                                        ; in one clause
        (t
         (let ((filter (select-filter
                        (if manually
                            "pen-fwfzf (with manual touch-up):"
                          "pen-fwfzf:")
                        type)))
           
           (pen-region-pipe
            (if manually
                (concat "manually " filter)
              filter))))))

(defun pen-extract ()
  (interactive)

  ;; (message "Extract")
  (pen-fwfzf 'extractors))

(defun pen-transform ()
  (interactive)

  ;; (message "Transform")
  (pen-fwfzf 'transformers))

(defun pen-grepfilter ()
  (interactive)
  ;; H-u is the global prefix
  (let ((gparg (prefix-numeric-value current-global-prefix-arg))
        (current-global-prefix-arg nil))

    (cond ((>= gparg 16) nil)
          ((>= gparg 4) (pen-fwfzf 'grepfilters t))
          (t (pen-fwfzf 'grepfilters nil))))

  ;; (message "Grepfilter")
  )

(defun pen-summarizer ()
  (interactive)

  (pen-fwfzf 'summarizers))

(define-key pen-map (kbd "M-q M-f") 'pen-fwfzf)
(define-key pen-map (kbd "M-q M-e") 'pen-extract)
(define-key pen-map (kbd "M-q M-t") 'pen-transform)
(define-key pen-map (kbd "M-q M-g") 'pen-grepfilter)
(define-key pen-map (kbd "M-q M-s") 'pen-summarizer)
(define-key pen-map (kbd "M-q M-h") 'grepfilter)

(defun pen-nwp (&optional cmd input nw_args)
  "Runs command in a new window with input"
  (interactive)
  (if (not cmd)
      (setq cmd "zsh"))
  (pen-sn (concat "pen-tm -tout -S nw " nw_args " " (pen-q cmd) " &") input (get-dir)))

(defun rt-from-region ()
  "Start an pen-rtcmd with the current region as input"
  (interactive)
  (if mark-active
      (pen-nwp "pen-rtcmd awk '{$2 = gensub(\"$\", \" |\", \"g\", $2); print $0}'" (pen-selected-text))))

(defun fzf-on-buffer ()
  (interactive)
  (shell-command-on-region
   (point-min) (point-max)
   (concat "pen-tm -S -tout nw 'fzf --sync | pen-tm -S -soak -tout nw v'")))

;; cat "$PENELD/config/filters/filters.sh"
(require 'f)
(defun pen-filter-shellscript (script)
  "This will pipe the selection into fzf filters,\nreplacing the original region. If no region is\nselected, then the entire buffer is passed\nread only."
  (interactive (list (fz (cat (f-join pen-penel-directory "config" "filters" "filters.sh")) nil nil "pen-filter-shellscript: ")))
  (if (region-active-p)
      (pen-region-pipe
       (chomp
        (replace-regexp-in-string
         " #.*" ""
         script)))))

(defun pen-fi-join (arg)
  "Indent by prefix arg"
  (interactive "P")
  (progn (if (not arg) (setq arg ""))
         (pen-region-pipe (concat "pen-str join " (str arg)))))

(defun pen-fi-indent (arg)
  "Indent by prefix arg"
  (interactive "P")
  ;; (pen-ns (str arg))
  (progn (if (not arg) (setq arg 4))
         (pen-region-pipe (concat "pen-indent " (str arg)))))

(defun pen-fi-unindent (arg)
  "Indent by prefix arg"
  (interactive "P")
  ;; (pen-ns (str arg))

  (progn
    (if (not arg) (setq arg 4))
    (pen-region-pipe (concat "pen-indent -" (str arg)))))

(defun pen-fi-org-indent (arg)
  "Indent by prefix arg"
  (interactive "P")
  ;; (pen-ns (str arg))
  (cond
   ((and (equal major-mode 'org-mode)
         (string-match-p "\\`\\*"
                         (if mark-active
                             (pen-selected-text)
                           (thing-at-point 'line))))
    (pen-region-pipe "pen-orgindent"))
   ((and (equal major-mode 'org-mode)
         (string-match-p "\\` *[-+]"
                         (if mark-active
                             (pen-selected-text)
                           (thing-at-point 'line))))
    (pen-region-pipe (pen-cmd "pen-indent" "2")))
   (t (progn (if (not arg) (setq arg 4))
             (pen-region-pipe (concat "pen-indent " (str arg)))))))

(defun pen-fi-org-unindent (arg)
  "Indent by prefix arg"
  (interactive "P")
  ;; (pen-ns (str arg))

  (cond
   ((and (equal major-mode 'org-mode)
         (not arg)
         (string-match-p "\\`\\*"
                         (if mark-active
                             (pen-selected-text)
                           (thing-at-point 'line))))
    (pen-region-pipe "pen-orgindent -1"))
   ((and (equal major-mode 'org-mode)
         (not arg))
    (if (string-match-p "\\` *[-+]"
                        (if mark-active
                            (pen-selected-text)
                          (thing-at-point 'line)))
        (pen-region-pipe "pen-indent -2")
      (call-interactively #'org-run-babel-template-hydra)))
   (t (progn
        (if (not arg) (setq arg 4))
        (pen-region-pipe (concat "pen-indent -" (str arg)))))))

;; TODO Add quote

(define-key org-mode-map (kbd "M-l M-f M-<") 'org-run-babel-template-hydra)
(define-key org-mode-map (kbd "M-l M-r M-<") 'org-run-babel-template-hydra)

(defun pen-org-quote-selection ()
  (interactive)

  (hot-expand "<q" "QUOTE"))

(define-key org-mode-map (kbd "M-l M-f M-e") 'pen-org-quote-selection)

(provide 'pen-filters)
