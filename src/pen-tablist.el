(require 'tabulated-list)
(require 'navigel)
(require 'tablist)
(require 'tablist)
(require 'pcsv)

(defun cmd-tabulated-list (&optional csv_fp csv_type)
  "csv_type is kinda like the mode name"
  (interactive)
  (let* ((csv (cat (or csv_fp "/dev/null"))))
    (with-current-buffer (new-buffer-from-string "")
      (insert csv))))

;; This works, but it doesn't show in the minor mode list, interestingly
(add-hook 'tabulated-list-mode-hook 'tablist-minor-mode)

(defun tablist-load-csv (path)
  (interactive (list (read-string "path:")))
  (if (not path)
      (setq path "/usr/share/gdal/2.2/vertcs.csv"))

  (ignore-errors (tablist-import-csv path))

  (eval `(setq tabulated-list-revert-hook (λ () (tablist-import-csv ,path)))))

(defun cmd-out-to-tablist-quick (cmd &optional has-header)
  (interactive (list (read-string-hist "tablist cmd: ")))
  (tablist-import-string (pen-sn (concat cmd " | coerce-to-csv")) has-header))


;; Have an interactive selection of the available modes
(defun create-tablist (cmd-or-csv-path &optional modename has-header col-sizes-string wd)
  "Try to create a tablist from a cmd or a csv path"
  (interactive (list (read-string-hist "create-tablist: CMD or CSV path: ")))

  (setq has-header
        (if (sor has-header)
            t
          nil))

  (let* ((path (if (and
                    (f-file-p cmd-or-csv-path)
                    (not (f-executable-p cmd-or-csv-path)))
                   cmd-or-csv-path))
         (pen-cmd (if (not path)
                  cmd-or-csv-path))
         (col-sizes
          (if (sor col-sizes-string)
              (try (mapcar 'string-to-number (uncmd col-sizes-string))))))

    (let ((b (cond ((sor path) (tablist-buffer-from-csv-string (cat path) has-header col-sizes))
                   ((sor cmd) (tablist-buffer-from-csv-string (pen-sn cmd) has-header col-sizes)))))
      (if b
          ;; If mode exists for this command then use it
          (with-current-buffer
              b
            (if (sor wd) (cd wd))
            (let ((modefun (intern (concat (slugify (or modename cmd-or-csv-path)) "-tablist-mode"))))
              (if (fboundp modefun)
                  (funcall modefun)))
            b)
        (error "tablist not created")
        nil))))

(defset pen-tablist-min-column-width 10)

;; (tablist-buffer-from-csv-string (pen-sn "arp -a | spaces2tabs | tsv2csv"))
(defun tablist-buffer-from-csv-string (csvstring &optional has-header col-sizes)
  "This creates a new tabulated list buffer from a CSV string"
  (let* ((b (nbfs csvstring "tablist"))
         (parsed (pcsv-parse-buffer b))
         (header (if has-header
                     (first parsed)
                   (mapcar (λ (s) "") (first parsed))))
         (data (if has-header
                   (-drop 1 parsed)
                 parsed)))

    (switch-to-buffer b)
    (with-current-buffer b

      ;; (-zip '(a b c) '(1 2 3) '(x y z))
      (setq-local tabulated-list-format
                  (si "tabulated-list-format format"
                      (list2vec
                       (let* ((sizes
                               (or col-sizes
                                   (mapcar (λ (e) ;; (si "tabulated-list-format column-size" (max 10 (min 30 (length e))))
                                             (max pen-tablist-min-column-width (min 30 (length e))))
                                           header)))
                              (trues (mapcar (λ (e) t)
                                             header)))
                         (-zip header sizes trues))
                       )))
      (setq-local tabulated-list-sort-key (list (first header)))

      ;; It would be nice to find the approximate length of each column, but who cares for the moment

      (setq-local tabulated-list-entries (-map (λ (lst) (list (first lst) (list2vec lst))) data))

      (tabulated-list-mode)

      (tabulated-list-init-header)

      ;; This is faster but leaves artifacts in some situations
      ;; (tabulated-list-print nil t)

      (tabulated-list-print)
      (tablist-enlarge-column)
      (tablist-shrink-column)
      (revert-buffer)
      (tablist-forward-column 1)
      (tabulated-list-revert))
    b))

(defun tablist-import-path (path &optional has-header)
  ""
  (tablist-import-string (cat path) has-header))
(defalias 'tablist-import-csv 'tablist-import-path)

(defun tablist-import-string (s &optional has-header)
  ""
  (tablist-buffer-from-csv-string (pen-sn "coerce-to-csv" s) has-header))

;; The default char should be tab
;; csv-mode should be started
;; An actual file path should be created -- but based on the mode when I do =yp=
(defun tablist-export-csv (&optional separator always-quote-p
                                     invisible-p out-buffer display-p)
  "Export a tabulated list to a CSV format.

Use SEPARATOR (or ;) and quote if necessary (or always if
ALWAYS-QUOTE-P is non-nil).  Only consider non-filtered entries,
unless invisible-p is non-nil.  Create a buffer for the output or
insert it after point in OUT-BUFFER.  Finally if DISPLAY-P is
non-nil, display this buffer.

Return the output buffer."

  (interactive (list nil t nil nil t))
  (unless (derived-mode-p 'tabulated-list-mode)
    (error "Not in Tabulated List Mode"))
  (unless (stringp separator)
    (setq separator (string (or separator ;; (string-to-char "\t")
                                (string-to-char ",")))))
  (let* ((outb (or out-buffer
                   (get-buffer-create
                    (format "%s.csv" (buffer-name)))))
         (escape-re (format "[%s\"\n]" separator))
         (header (tablist-column-names)))
    (unless (buffer-live-p outb)
      (error "Expected a live buffer: %s" outb))
    (cl-labels
        ((printit (entry)
                  (insert
                   (mapconcat
                    (λ (e)
                      (unless (stringp e)
                        (setq e (car e)))
                      (if (or always-quote-p
                              (string-match escape-re e))
                          (concat "\""
                                  (replace-regexp-in-string "\"" "\"\"" e t t)
                                  "\"")
                        e))
                    entry separator))
                  (insert ?\n)))
      (with-current-buffer outb
        (let ((inhibit-read-only t))
          (erase-buffer)
          (printit header)
          (csv-mode)))
      (save-excursion
        (goto-char (point-min))
        (unless invisible-p
          (tablist-skip-invisible-entries))
        (while (not (eobp))
          (let* ((entry (tabulated-list-get-entry)))
            (with-current-buffer outb
              (let ((inhibit-read-only t))
                (printit entry)))
            (if invisible-p
                (forward-line)
              (tablist-forward-entry)))))
      (if display-p
          (display-buffer outb))
      outb)))

(defun tablist-to-csv ()
  (if (derived-mode-p 'tabulated-list-mode)
      (let ((b (tablist-export-csv)))
        (buffer2string b))))

(defun tablist-init (&optional disable)
  (let ((cleaned-misc (try (cl-remove 'tablist-current-filter
                                      mode-line-misc-info :key 'car)
                           mode-line-misc-info)))
    (cond
     ((not disable)
      (set (make-local-variable 'mode-line-misc-info)
           (append
            (list
             (list 'tablist-current-filter
                   '(:eval (format " [%s]"
                                   (if tablist-filter-suspended
                                       "suspended"
                                     "filtered")))))))
      (add-hook 'post-command-hook
                'tablist-selection-changed-handler nil t)
      (add-hook 'tablist-selection-changed-functions
                'tablist-context-window-update nil t))
     (t
      (setq mode-line-misc-info cleaned-misc)
      (remove-hook 'post-command-hook
                   'tablist-selection-changed-handler t)
      (remove-hook 'tablist-selection-changed-functions
                   'tablist-context-window-update t)))))


(defun tabulated-list-current-column ()
  (let* ((columns (tablist-column-offsets))
         (current (1- (length columns))))
    ;; find current column
    (while (and (>= current 0)
                (> (nth current columns)
                   (current-column)))
      (cl-decf current))
    current))

(defun vector2list (v)
  (append v nil))

(defun tabulated-list-current-cell-contents ()
  (interactive)
  (xc (nth (tabulated-list-current-column) (vector2list (tabulated-list-get-entry)))))


(defun tablist-open-in-fpvd ()
  (interactive)
  (pen-nw "fpvd -csv" nil (tablist-to-csv)))


(defun tablist-shrink-column-around-advice (proc &rest args)
  (if (eq 0 (current-column))
      (forward-char))
  ;; do it twice -- that's 6 chars
  (let* ((res (apply proc args))
         ;; (res (apply proc args))
         )
    res))
(advice-add 'tablist-shrink-column :around #'tablist-shrink-column-around-advice)

(defun tablist-enlarge-column-around-advice (proc &rest args)
  (if (eq 0 (current-column))
      (forward-char))
  ;; do it twice -- that's 6 chars
  (let* ((res (apply proc args))
         ;; (res (apply proc args))
         )
    res))
(advice-add 'tablist-enlarge-column :around #'tablist-enlarge-column-around-advice)

;; TODO Fix this so that tabbing to the correct column works
(comment
 (defun tablist-column-offsets ()
   "Return a list of column positions.

This is a list of offsets from the beginning of the line."
   (let ((cc tabulated-list-padding)
         columns)
     (dotimes (i (length tabulated-list-format))
       (let* ((c (aref tabulated-list-format i))
              (len (nth 1 c))
              (pad (or (plist-get (nthcdr 3 c) :pad-right)
                       1)))
         (push cc columns)
         (when (numberp len)
           (cl-incf cc len))
         (when pad
           (cl-incf cc pad))))
     (nreverse columns))))

(define-derived-mode tabulated-list-mode special-mode "Tabulated"
  "Generic major mode for browsing a list of items.
This mode is usually not used directly; instead, other major
modes are derived from it, using `define-derived-mode'.

In this major mode, the buffer is divided into multiple columns,
which are labeled using the header line.  Each non-empty line
belongs to one \"entry\", and the entries can be sorted according
to their column values.

An inheriting mode should usually do the following in their body:

 - Set `tabulated-list-format', specifying the column format.
 - Set `tabulated-list-revert-hook', if the buffer contents need
   to be specially recomputed prior to `revert-buffer'.
 - Maybe set a `tabulated-list-entries' function (see below).
 - Maybe set `tabulated-list-printer' (see below).
 - Maybe set `tabulated-list-padding'.
 - Call `tabulated-list-init-header' to initialize `header-line-format'
   according to `tabulated-list-format'.

An inheriting mode is usually accompanied by a \"list-FOO\"
command (e.g. `list-packages', `list-processes').  This command
creates or switches to a buffer and enables the major mode in
that buffer.  If `tabulated-list-entries' is not a function, the
command should initialize it to a list of entries for displaying.
Finally, it should call `tabulated-list-print'.

`tabulated-list-print' calls the printer function specified by
`tabulated-list-printer', once for each entry.  The default
printer is `tabulated-list-print-entry', but a mode that keeps
data in an ewoc may instead specify a printer function (e.g., one
that calls `ewoc-enter-last'), with `tabulated-list-print-entry'
as the ewoc pretty-printer."
  (setq-local truncate-lines t)
  (setq-local tabulated-list-padding 0)
  (setq-local buffer-undo-list t)
  (setq-local revert-buffer-function #'tabulated-list-revert)
  (setq-local glyphless-char-display
              (tabulated-list-make-glyphless-char-display-table))
  ;; Avoid messing up the entries' display just because the first
  ;; column of the first entry happens to begin with a R2L letter.
  (setq bidi-paragraph-direction 'left-to-right)
  ;; This is for if/when they turn on display-line-numbers
  (add-hook 'display-line-numbers-mode-hook #'tabulated-list-revert nil t)
  ;; This is for if/when they customize the line-number face or when
  ;; the line-number width needs to change due to scrolling.
  (setq-local tabulated-list--current-lnum-width 0)
  (add-hook 'pre-redisplay-functions
            #'tabulated-list-watch-line-number-width nil t)
  (add-hook 'window-scroll-functions
            #'tabulated-list-window-scroll-function nil t))

(defset pen-tablist-min-padding 0)

(defun tablist-put-mark (&optional pos)
  "Put a mark before the entry at POS.

POS defaults to point. Use `tablist-marker-char',
`tablist-marker-face', `tablist-marked-face' and
`tablist-major-columns' to determine how to mark and what to put
a face on."
  (when (or (null tabulated-list-padding)
            (< tabulated-list-padding pen-tablist-min-padding))
    (setq tabulated-list-padding pen-tablist-min-padding)
    (tabulated-list-revert))
  (save-excursion
    (and pos (goto-char pos))
    (unless (tabulated-list-get-id)
      (error "No entry at this position"))
    (let ((inhibit-read-only t))
      (tabulated-list-put-tag
       (string tablist-marker-char))
      (put-text-property
       (point-at-bol)
       (1+ (point-at-bol))
       'face tablist-marker-face)
      (let ((columns (tablist-column-offsets)))
        (dolist (c (tablist-major-columns))
          (when (and (>= c 0)
                     (< c (length columns)))
            (let ((beg (+ (point-at-bol)
                          (nth c columns)))
                  (end (if (= c (1- (length columns)))
                           (point-at-eol)
                         (+ (point-at-bol)
                            (nth (1+ c) columns)))))
              (cond
               ((and tablist-marked-face
                     (not (eq tablist-marker-char ?\s)))
                (tablist--save-face-property beg end)
                (put-text-property
                 beg end 'face tablist-marked-face))
               (t (tablist--restore-face-property beg end))))))))))

(defun tabulated-list-put-tag (tag &optional advance)
  "Put TAG in the padding area of the current line.
TAG should be a string, with length <= `tabulated-list-padding'.
If ADVANCE is non-nil, move forward by one line afterwards."
  (unless (stringp tag)
    (error "Invalid argument to `tabulated-list-put-tag'"))
  (never
   (unless (> tabulated-list-padding 0)
     (progn
       ;; Annoyingly, this gets run when the tablist mode is set up
       (never
        (setq-local tabulated-list-padding 1)
        (setq-local pen-tablist-min-padding 1)
        ;; Also I havent got this going yet
        (let ((cl (current-line)))
          (tabulated-list-revert t)
          (goto-line cl)))
       (error "Unable to tag the current line"))))
  (never
   (save-excursion
     (beginning-of-line)
     (when (tabulated-list-get-entry)
       (let ((beg (point))
	           (inhibit-read-only t))
	       (forward-char tabulated-list-padding)
	       (insert-and-inherit
	        (let ((width (string-width tag)))
	          (if (<= width tabulated-list-padding)
	              (concat tag
		                    (make-string (- tabulated-list-padding width) ?\s))
	            (truncate-string-to-width tag tabulated-list-padding))))
	       (delete-region beg (+ beg tabulated-list-padding))))))
  (if advance
      (forward-line)))

;; tabulated list mode must not be using this
;; method of making invisible characters
(defun current-visible-column-bak ()
  (let ((cc (current-column))
        (cp (point))
        (vcs 0))
    (message (str cp))
    (save-excursion
      (beginning-of-line)
      (while (and
              (< (point) cp)
              (not (eobp))
              (not (eolp)))
        (if (not (get-text-property (point) 'invisible))
            (progn
              (setq vcs (+ 1 vcs))
              (message (str vcs))
              (message (str (point)))
              (message (concat "_" (thing-at-point 'char)))))
        (forward-char))
      vcs)))

(defun current-visible-column ()
  (tryelse (string-to-number (pen-snc "tmux display-message -p '#{cursor_x}'"))
           (error "Can't get column from tmux")))

(defun tablist-current-column ()
  "Return the column number at point.

Returns nil, if point is before the first column."
  (let ((column
         (1- (cl-position
              (current-visible-column)
              (append (tablist-column-offsets)
                      (list most-positive-fixnum))
              :test (λ (column offset) (> offset column))))))
    (when (>= column 0)
      column)))

;; This is correct
(defun tablist-column-offsets ()
  "Return a list of column positions.

This is a list of offsets from the beginning of the line."
  (let ((cc tabulated-list-padding)
        columns)
    (dotimes (i (length tabulated-list-format))
      (let* ((c (aref tabulated-list-format i))
             (len (nth 1 c))
             (pad (or (plist-get (nthcdr 3 c) :pad-right)
                      1)))
        (push cc columns)
        (when (numberp len)
          (cl-incf cc len))
        (when pad
          (cl-incf cc pad))))
    (nreverse columns)))

;; This needs fixing
(defun tablist-move-to-column (n)
  "Move to the N'th list column."
  (interactive "p")
  (when (tabulated-list-get-id)
    (let ((columns (tablist-column-offsets)))
      (when (or (< n 0)
                (>= n (length columns)))
        (error "No such column: %s" n))
      (beginning-of-line)
      (message (str (nth n columns)))
      (forward-char (nth n columns))

      (when (and (plist-get (nthcdr 3 (elt tabulated-list-format n))
                            :right-align)
                 (not (= n (1- (length columns)))))
        (forward-char (1- (car (cdr (elt tabulated-list-format n)))))))))

(defun tablist-skip-invisible-entries (&optional backward prop)
  "Skip invisible entries BACKWARD or forward.

Do nothing, if the entry at point is visible.  Otherwise move to
the beginning of the next visible entry in the direction
determined by BACKWARD.

Return t, if point is now in a visible area."

  (if (not prop)
      (setq prop 'invisible))

  (cond
   ((and backward
         (not (bobp))
         (get-text-property (point) prop))
    (when (get-text-property (1- (point)) prop)
      (goto-char (previous-single-property-change
                  (point)
                  prop nil (point-min))))
    (forward-line -1))
   ((and (not backward)
         (not (eobp))
         (get-text-property (point) prop))
    (goto-char (next-single-property-change
                (point)
                prop nil (point-max)))))
  (not (or (invisible-p (point))
           (string-equal "…" (get-text-property (point) 'display)))))

(defun tablist-next-column (&optional backward prop)
  "Skip invisible entries BACKWARD or forward.

Do nothing, if the entry at point is visible.  Otherwise move to
the beginning of the next visible entry in the direction
determined by BACKWARD.

Return t, if point is now in a visible area."

  (if (not prop)
      (setq prop 'invisible))

  ;; I can't use the current visible column number
  ;; I should use this function as a references
  ;; to 'find' the correct column numbers
  (while (and (not (eobp))
              (not (eolp)))
    (cond ((string-equal "…" (get-text-property (point) 'display))
           (progn
             (tablist-skip-invisible-entries nil 'display)
             (forward-char 2)))))

  (cond
   ((and backward
         (not (bobp))
         (get-text-property (point) prop))
    (when (get-text-property (1- (point)) prop)
      (goto-char (previous-single-property-change
                  (point)
                  prop nil (point-min))))
    (forward-line -1))
   ((and (not backward)
         (not (eobp))
         (get-text-property (point) prop))
    (goto-char (next-single-property-change
                (point)
                prop nil (point-max)))))
  (not (or (invisible-p (point))
           (string-equal "…" (get-text-property (point) 'display)))))

(defset list-of-tlm
  '(buffer-menu
    bluetooth-list-devices))

(defun run-tlm (tlmcmd &optional pen-pak)
  (interactive (list (fz list-of-tlm
                         nil nil "run-tlm: ")))
  (call-interactively (intern tlmcmd)))


(defset pen-tablist-modes-cmds-or-paths
  '(
    ;; "arp -a | spaces2tabs | tsv2csv"
    "arp"
    "prompts"
    "subnetscan"
    "ports"
    "aws-policies"
    "aws-users"
    "mygit")
  "A list of commands or csv paths to create tablist minor modes for")

(defset pen-tablist-mode-tuples
  '(("list-venv-dirs-csv" . ("venv" t "30 40 20"))
    ("pen-n-list-open-ports" . ("ports" t))
    ("mygit-tablist" . ("mygit" t))
    ("list-current-subnet-computers-details" . ("subnetscan" t))
    ("arp-details" . ("arp" t "20 20 20 20 20 20"))
    ("list-aws-iam-policies-csv" . ("aws-policies" t "30 80"))
    ("unbuffer pen-ci prompts-details -csv" . ("prompts" t "30 30 20 10 15 15 15 10"))
    ("upd list-aws-iam-users-csv" . ("aws-users" t "20 60 20"))))

(defset pen-tablist-modes
  (cl-loop for cmd in pen-tablist-modes-cmds-or-paths collect (eval `(defcmdmode ,cmd "tablist"))))

(defun pen-start-tablist ()
  (interactive)
  (let* ((pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 16))
         (tlname (fz (mapcar 'car pen-tablist-mode-tuples) nil nil "start tablist: "))
         (args
          (if (sor tlname)
              (assoc tlname pen-tablist-mode-tuples))))
    (apply 'create-tablist args)))

(defun arp-tablist-get-ip ()
  (pen-snc "rosie grep -o subs net.ipv4" (cadr (vector2list (tabulated-list-get-entry )))))

(defun arp-tablist-ping ()
  (interactive)
  (pen-sps (concat "ping " (pen-q (arp-tablist-get-ip)) " || pen-pak")))

(defun arp-tablist-nmap-os-detect (&optional ip)
  (interactive)
  (setq ip (or ip (arp-tablist-get-ip)))
  (pen-sps (concat "msudo nmap -O " (pen-q ip) " 2>&1 | vs")))

(defun arp-tablist-nmap-ports (&optional ip)
  (interactive)
  (setq ip (or ip (arp-tablist-get-ip)))
  (pen-sps (concat "nmap -sT " (pen-q ip) " 2>&1 | vs")))

(defun arp-tablist-ssh ()
  (interactive)
  (pen-sps (concat "zrepl ssh " (pen-q (arp-tablist-get-ip)))))


(defun mygit-tablist-get-url ()
  (pen-snc "xurls" (str (vector2list (tabulated-list-get-entry )))))

(defun mygit-tablist-gc ()
  (interactive)
  ;; (pen-sps (concat "zrepl gc " (pen-q (mygit-tablist-get-url))))
  (gc (mygit-tablist-get-url)))



(defun prompts-tablist-get-fp ()
  (pen-umn (concat "$PROMPTS/" (str (car (vector2list (tabulated-list-get-entry)))))))

(defun prompts-tablist-o ()
  (interactive)
  (e (prompts-tablist-get-fp)))


(defun aws-remove-user-policy (id)
  (interactive (list (tabulated-list-get-id)))

  )

(defun aws-create-user (name)
  (interactive (list (read-string-hist "New user name: ")))
  (pen-snc (concat "aws iam create-user --user-name " name))
  (if (derived-mode-p 'tabulated-list-mode)
      (revert-buffer)))

(defun aws-delete-user (name)
  (interactive (list (or (sor (str (tabulated-list-get-id)))
                         (read-string-hist "Delete user name: "))))
  (if (yes-or-no-p (concat "Delete " name "?"))
      (progn
        (pen-snc (concat "aws iam delete-user --user-name " name))
        (if (derived-mode-p 'tabulated-list-mode)
            (revert-buffer)))))

(defun aws-add-policy-to-user (name)
  (interactive (list (or (sor (str (tabulated-list-get-id)))
                         (read-string-hist "Add policy to user: "))))
  (let ((policy (fz (pen-snc "list-aws-iam-policies-csv | sed 1d | cut -d , -f 2 | uq -l"))))
    (pen-snc (concat "unbuffer pen-ci aws iam attach-user-policy --user-name " name " --policy-arn \"" policy "\""))
    (if (derived-mode-p 'tabulated-list-mode)
        (revert-buffer))))

(defun aws-remove-policy-from-user (name)
  (interactive (list (or (sor (str (tabulated-list-get-id)))
                         (read-string-hist "Remove policy from user: "))))
  (let ((policy (fz (pen-snc "list-aws-iam-policies-csv | sed 1d | cut -d , -f 2 | uq -l"))))
    (pen-snc (concat "unbuffer pen-ci aws iam detach-user-policy --user-name " name " --policy-arn \"" policy "\""))
    (if (derived-mode-p 'tabulated-list-mode)
        (revert-buffer))))


(defun server-suggest-subnet-scan (hn)
  (interactive (list tablist-selected-id))
  (if tablist-selected-id
      (server-suggest tablist-selected-id)))

(defun kill-port (port)
  (interactive (read-string "kill-port: "))
  (pen-snc (pen-cmd "kill-port" (str port))))

(defun ports-tablist-kill-port (&optional port)

  )

(define-key tablist-minor-mode-map (kbd "C-s") 'tablist-push-regexp-filter)
(define-key tabulated-list-mode-map (kbd "w") 'tabulated-list-current-cell-contents)
(define-key tabulated-list-mode-map (kbd "C-c C-o") 'org-open-at-point)
(define-key global-map (kbd "H-F") 'run-tlm)
(define-key pen-map (kbd "H-\\") 'pen-start-tablist)
(define-key arp-tablist-mode-map (kbd "p") 'arp-tablist-ping)
(define-key arp-tablist-mode-map (kbd "s") 'arp-tablist-ssh)
(define-key arp-tablist-mode-map (kbd "N") 'arp-tablist-nmap-ports)
(define-key arp-tablist-mode-map (kbd "O") 'arp-tablist-nmap-os-detect)
(define-key mygit-tablist-mode-map (kbd "RET") 'mygit-tablist-gc)
(define-key prompts-tablist-mode-map (kbd "RET") 'prompts-tablist-o)
(define-key aws-users-tablist-mode-map (kbd "d") 'aws-delete-user)
(define-key aws-users-tablist-mode-map (kbd "c") 'aws-create-user)
(define-key aws-users-tablist-mode-map (kbd "a") 'aws-add-policy-to-user)
(define-key aws-users-tablist-mode-map (kbd "r") 'aws-remove-policy-from-user)
(define-key subnetscan-tablist-mode-map (kbd "'") 'server-suggest-subnet-scan)
(define-key ports-tablist-mode-map (kbd "k") 'arp-tablist-nmap-ports)

(advice-add 'tabulated-list-print-entry :around #'ignore-errors-around-advice)

(provide 'pen-tablist)
