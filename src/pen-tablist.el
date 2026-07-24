(require 'tabulated-list)
(require 'navigel)
(require 'tablist)
(require 'tablist)
(require 'pcsv)

;; This was not working for docker container tablist
(advice-add 'tablist-revert :around #'ignore-errors-around-advice)

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

  (eval `(setq tabulated-list-revert-hook (lambda () (tablist-import-csv ,path)))))

(defun cmd-out-to-tablist-quick (cmd &optional has-header)
  (interactive (list (read-string-hist "tablist cmd: ")))
  (tablist-import-string (pen-sn (concat cmd " | coerce-to-csv")) has-header t))


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

(defun tablist-put-mark-state (state)
  "Set the mark of the entry at point according to STATE.

STATE is a return value of `tablist-get-mark-state'."
  (cl-destructuring-bind (tablist-marker-char
                          tablist-marker-face
                          tablist-marked-face)
      state
    (tablist-put-mark)))

;; nadvice - proc is the original function, passed in. do not modify
(defun tablist-put-mark-state-around-advice (proc state)
  (if state
      ;; (let ((res (apply proc (list state))))
      ;;   res)
    (tablist-put-mark)
    (tablist-unmark)))
(advice-add 'tablist-put-mark-state :around #'tablist-put-mark-state-around-advice)
;; (advice-remove 'tablist-put-mark-state #'tablist-put-mark-state-around-advice)

(defmacro tablist-save-marks (&rest body)
  "Eval body, while preserving all marks."
  (let ((marks (make-symbol "marks")))
    `(let (,marks)
       (save-excursion
         (goto-char (point-min))
         (let ((re "^\\([^ ]\\)"))
           (while (re-search-forward re nil t)
             (push (cons (tabulated-list-get-id)
                         (tablist-get-mark-state))
                   ,marks))))
       (unwind-protect
           (progn ,@body)
         (save-excursion
           (dolist (m ,marks)
             (let ((id (pop m)))
               (goto-char (point-min))
               (while (and id (not (eobp)))
                 (when (equal id (tabulated-list-get-id))
                   (tablist-put-mark-state m)
                   (setq id nil))
                 (forward-line)))))))))

(defun tablist-enlarge-column (&optional column width)
  "Enlarge column COLUMN by WIDTH.

This function is lazy and therefore pretty slow."
  (interactive
   (list nil (* (prefix-numeric-value current-prefix-arg)
                3)))
  (unless column (setq column (tablist-current-column)))
  (unless column
    (error "No column given and no entry at point"))
  (unless width (setq width 1))
  (when (or (not (numberp column))
            (< column 0)
            (>= column (length tabulated-list-format)))
    (error "No such column: %d" column))
  (when (= column (1- (length tabulated-list-format)))
    (error "Can't resize last column"))

  (let* ((cur-width (cadr (elt tabulated-list-format column))))
    (setcar (cdr (elt tabulated-list-format column))
            (max 3 (+ cur-width width)))

    (tablist-with-remembering-entry
      (tablist-save-marks
       (tabulated-list-init-header)
       (tabulated-list-print)))))

;; (tablist-buffer-from-csv-string (pen-sn "arp -a | spaces2tabs | tsv2csv"))
(defun tablist-buffer-from-csv-string (csvstring &optional has-header col-sizes)
  "This creates a new tabulated list buffer from a CSV string"
  (setq has-header
        (cond ((numberp has-header) (> has-header 0))
              ;; nil
              ((not has-header) (yn "Has header?"))
              (t has-header)))

  (let* ((b (nbfs csvstring "tablist"))
         (parsed (pcsv-parse-buffer b))
         (header (if has-header
                     (first parsed)
                   ;; (mapcar (lambda (e) (concat "[" (number-to-string e) "]")) (seq 1 (length (first parsed))))
                   ;; (mapcar (lambda (e) (concat "_" (number-to-string e) "_")) (seq 1 (length (first parsed))))
                   (mapcar (lambda (e) (concat "." (number-to-string e) ".")) (seq 1 (length (first parsed))))
                   ;; (mapcar (lambda (s) "") (first parsed))
                   ))
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
                                   (mapcar (lambda (e) ;; (si "tabulated-list-format column-size" (max 10 (min 30 (length e))))
                                             (max pen-tablist-min-column-width (min 30 (length e))))
                                           header)))
                              (trues (mapcar (lambda (e) t)
                                             header)))
                         (-zip header sizes trues)))))
      (setq-local tabulated-list-sort-key (list (first header)))

      ;; It would be nice to find the approximate length of each column, but who cares for the moment

      (setq-local tabulated-list-entries (-map (lambda (lst) (list (first lst) (list2vec lst))) data))

      (tabulated-list-mode)

      (tabulated-list-init-header)

      ;; This is faster but leaves artifacts in some situations
      ;; (tabulated-list-print nil t)

      (tabulated-list-print)
      (comment
       (tablist-enlarge-column)
       (tablist-shrink-column)
       (revert-buffer)
       (comment
        (tablist-forward-column 1))
       (tabulated-list-revert)))
    b))

(defun tablist-import-path (path &optional has-header)
  ""
  (tablist-import-string (cat path) has-header))
(defalias 'tablist-import-csv 'tablist-import-path)

(defun tablist-import-string (s &optional has-header no-coerce-to-csv-b)
  ""
  (tablist-buffer-from-csv-string (if no-coerce-to-csv-b
                                      s
                                    (pen-sn "coerce-to-csv" s)) has-header))

;; The default char should be tab
;; csv-mode should be started
;; An actual file path should be created -- but based on the mode when I do =yp=
(defun tablist-export-csv (&optional separator always-quote-p
                                     invisible-p out-buffer display-p
                                     only-marked-p)
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
                    (lambda (e)
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


(defun tabulated-list-current-column (&optional n)
  (setq n (or n (current-column)))
  
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

(defun tabulated-list-current-cell-contents (&optional nocopy)
  (interactive)
  (let ((contents (nth (tabulated-list-current-column) (vector2list (tabulated-list-get-entry))))
        (gparg (prefix-numeric-value current-prefix-arg))
        (current-prefix-arg nil))
    (if (or (>= gparg 4)
            nocopy) 
        contents
      (xc (str contents)))))

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

(comment
 (defun tablist-enlarge-column-around-advice (proc &rest args)
   (if (eq 0 (current-column))
       (forward-char))
   ;; do it twice -- that's 6 chars
   (let* ((res (apply proc args))
          ;; (res (apply proc args))
          )
     res))
 ;; (advice-add 'tablist-enlarge-column :around #'tablist-enlarge-column-around-advice)
 (advice-remove 'tablist-enlarge-column #'tablist-enlarge-column-around-advice))

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

(defun tablist-goto-first-column ()
  (interactive)
  (let ((offsets (tablist-column-offsets)))
    (if offsets
        (move-to-column
         (car (tablist-column-offsets))))))

;; DONE Make it so j:tablist-mark-forward marks all of the selected
;; Fixed
(defun tablist-mark-forward (&optional arg interactive)
  "Mark ARG entries forward.

ARG is interpreted as a prefix-arg.  If interactive is non-nil,
maybe use the active region instead of ARG.

See `tablist-put-mark' for how entries are marked."
  (interactive (list current-prefix-arg t))
  (cond
   ;; Mark files in the active region.
   ((and interactive (use-region-p))
    ;; (pen-normalise-point-and-mark)
    ;; (goto-char (region-beginning))
    (eval
     `(save-excursion
        (goto-char ,(region-beginning))
        (beginning-of-line)
        (tablist-repeat-over-lines
         (1+ (count-lines
              (point)
              (save-excursion
                (goto-char ,(region-end))
                (beginning-of-line)
                (point))))
         'tablist-put-mark))))
   ;; Mark the current (or next ARG) files.
   (t
    (comment (tablist-repeat-over-lines
              (prefix-numeric-value arg)
              'identity-command))

    ;; I had to do this instead of save-excursion-reliably
    (save-excursion-line
     (tablist-repeat-over-lines
      (prefix-numeric-value arg)
      'tablist-put-mark))
    (pen-comint-bol)))
  (forward-char))

(defun tablist-mark-forward-and-next (&optional arg interactive)
  (interactive (list current-prefix-arg t))

  (tablist-mark-forward arg interactive)
  (tablist-next-line))

;; I think I want to keep this on permanently to make tings easier
(setq tabulated-list-padding 1)
(setq pen-tablist-min-padding 1)
(setq-default tabulated-list-padding 1)
(setq-default pen-tablist-min-padding 1)

;; Ensure that this doesn't go to the top of the screen
;; TODO I think I need to build this up again from scratch.
(defun tablist-put-mark (&optional pos)
  "Put a mark before the entry at POS.

POS defaults to point. Use `tablist-marker-char',
`tablist-marker-face', `tablist-marked-face' and
`tablist-major-columns' to determine how to mark and what to put
a face on."
  
  (when (or (eq 0 tabulated-list-padding)
            (null tabulated-list-padding)
            (< tabulated-list-padding pen-tablist-min-padding))
    (setq tabulated-list-padding pen-tablist-min-padding)
    (tabulated-list-revert)
    (tabulated-list-init-header))

  (save-excursion
   (and pos (goto-char pos))

   ;; This needs to be removed to work in mx:list-timers

   ;; (unless (tabulated-list-get-id)
   ;;   (error "No entry at this position"))

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
  (unless (> tabulated-list-padding 0)
    (progn
      ;; Annoyingly, this gets run when the tablist mode is set up
      (never)
      (setq-local tabulated-list-padding 1)
      (setq-local pen-tablist-min-padding 1)
      ;; (tabulated-list-revert t)
      ;; Also I havent got this going yet
      (let ((cl (current-line)))
        (tabulated-list-revert t)
        (goto-line cl))
      ;; (error "Unable to tag the current line")
      ))
  (never)
  (save-excursion
    (tablist-goto-first-column)
    (pen-comint-bol)
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
        (delete-region beg (+ beg tabulated-list-padding)))))
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
      (tablist-goto-first-column)
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

(advice-add 'tablist-skip-invisible-entries :around #'ignore-errors-around-advice)

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

(advice-add 'tabulated-list-print-entry :around #'ignore-errors-around-advice)

;; Get rid of the truncate string ellipsis, since I'm not a huge fan of using unicode
;; or multi-byte everywhere;
;; Hmm. I will keep it for now because I solved some issues.
(require 'mule-util)
(defun truncate-string-ellipsis ()
  "Return the string used to indicate truncation.
Use the value of the variable `truncate-string-ellipsis' when it's non-nil.
Otherwise, return the Unicode character U+2026 \"HORIZONTAL ELLIPSIS\"
when it's displayable on the selected frame, or `...'.  This function
needs to be called on every use of `truncate-string-to-width' to
decide whether the selected frame can display that Unicode character."
  (cond
   (truncate-string-ellipsis)
   ((char-displayable-p ?…) "…")
   ("...")))

;; Forward-char is also broken
(defun tablist-forward-column (n)
  ;; DONE: Make new simpler version
  (interactive "p")
  ;; (unless (tabulated-list-get-id)
  ;;   (error "No entry on this line"))

  (dotimes (_n n) 
    (let* ((ncols (length (tablist-column-offsets)))
           (lcol (- ncols 1))
           (ccol (tabulated-list-current-column))
           (ncol (+ ccol 1)))

      ;; (tabulated-list-current-column) is unreliable. after running forward-char, it may report the next column
      ;; but before it's visually at that column.
      ;; Even though (point) has increased. But I think (point) increases, but (current-column) does not increase.
      ;; Therefore, in forward-char-safe, I need to increase the point until current-column increases.

      (cond ((= ccol lcol) (tablist-goto-first-column))
            ((< ccol lcol) (while (< (tabulated-list-current-column)
                                     ncol)
                             ;; (message "%d %d" (point) (tabulated-list-current-column))
                             (forward-char-safe)
                             ;; (message "%d %d" (point) (tabulated-list-current-))
                             ))))))

;; The tablist-current-column is broken
(defalias 'tablist-current-column 'tabulated-list-current-column)

(defun pen-tablist-go-to-start-of-column ()
  (interactive)
  (let ((current-prefix-arg nil))
    
    (let ((ccol (tabulated-list-current-column)))
      (while (and
              ;; (< 0 (current-column))
              (= ccol (tabulated-list-current-column))
              ;; (< pcol
              ;;    (tabulated-list-current-column))
              )
        ;; (message "ccol: %d" ccol)
        (backward-char))
      (forward-char))))

;; Both forward-char and backward char suffer from the issue

(defun backward-char-safe (&optional n)
  (interactive "p")
  (let ((cpt (point))
        (ccol (current-column)))
    ;; I need to run backward-char until the point changes
    
    ;; Not even this works in tabulated-list-mode
    ;; Backwards char doesn't work at the start of a column
    ;; (goto-char (- (point) 1))
    (while (and
            (< 0 cpt)
            (= cpt (point))
            (= ccol (current-column)))
      ;; (message "cpt: %d ccol: %d" cpt ccol)
      (backward-char)
      ;; This move-to-column current-column is not required here
      ;; (move-to-column (current-column))
      )))

(defun forward-char-safe (&optional n)
  (interactive "p")
  (let ((cpt (point))
        (ccol (current-column)))
    ;; I need to run forward-char until the point changes

    ;; Sigh... after forward-char runs, it seemsm to revert the point

    (while (and
            (< cpt (point-max))
            (= cpt (point))
            (= ccol (current-column)))
      (forward-char)
      ;; This move-to-column current-column fixed the issue
      (move-to-column (current-column)))))

;; Hmm. It seems as though the updated tablist-mode fixed some things

(defun tablist-backward-column (n)
  ;; DONE: Make new simpler version
  (interactive "p")
  ;; (unless (tabulated-list-get-id)
  ;;   (error "No entry on this line"))

  ;; Remember that backward-char is almost fundamentally broken
  ;; inside tabulated-list, and so is goto-char.
  ;; It has problems when the cursor is at the first char of a column.
  ;; But I have backward-char-safe now

  ;; Therefore, I will only go forwards

  (setq n (or n 1))
  (let* ((ccol (tabulated-list-current-column))
         (ncol (- ccol n))
         (ncols (length (tablist-column-offsets))))

    (if (eq ncol -1)
        (setq ncol (- ncols 1)))

    (tablist-move-to-column ncol))

  ;; (dotimes (_n n)
  ;;   (let* ((ncols (length (tablist-column-offsets)))
  ;;          (lcol (- ncols 1))
  ;;          (ccol (tabulated-list-current-column))
  ;;          (pcol (- ccol 1)))

  ;;     ;; (message "pcol: %d" pcol)
  ;;     ;; (message "pcol: %d" ccol)

  ;;     (cond ((= ccol 0)
  ;;            (tablist-forward-column lcol)
  ;;            ;; (end-of-line)
  ;;            )
  ;;           ((> ccol 0)
  ;;            (progn
  ;;              ;; Strangely, backward-char is not working
  ;;              ;; most of the time
  ;;              (while (< pcol
  ;;                        (tabulated-list-current-column))
  ;;                ;; (message "ccol: %d" (tabulated-list-current-column))
  ;;                (message "%d" (current-column))
  ;;                ;; (ekm "C-b")
  ;;                (call-interactively 'backward-char-safe))
  ;;              ;; (message "a: %d" (current-column))
  ;;              ;; (ekm "C-f")
  ;;              (call-interactively 'forward-char)
  ;;              ;; (message "b: %d" (current-column))
  ;;              )))))

  ;; (message "c: %d" (current-column))
  ;; (call-interactively 'pen-tablist-go-to-start-of-column)
  )

(defun tablist-next-line (&optional n)
  ;; Make simpler version
  (interactive "p")
  (setq n (or n 1))
  (lsp-ui-doc-hide)
  (when (and (< n 0)
             (save-excursion
               (end-of-line 0)
               (tablist-skip-invisible-entries t)
               (bobp)))
    (signal 'beginning-of-buffer nil))
  (when (and (> n 0)
             (save-excursion
               (tablist-forward-entry)
               (eobp)))
    (signal 'end-of-buffer nil))


  (let ((col (tablist-current-column)))
    (if (eq col -1)
        (progn
          (tablist-goto-first-column)
          (setq col (tablist-current-column))))

    (tablist-forward-entry (or n 1))
    (if col
        (tablist-move-to-column col)
      (tablist-move-to-major-column)))

  (not (eobp)))

(defun tablist-previous-line (&optional n)
  (interactive "p")
  (lsp-ui-doc-hide)
  (tablist-next-line (- (or n 1))))

(define-key tablist-minor-mode-map (kbd "C-s") 'tablist-push-regexp-filter)
(define-key tabulated-list-mode-map (kbd "w") 'pen-yank-path)
(define-key tabulated-list-mode-map (kbd "y p") 'pen-yank-path)
(define-key tabulated-list-mode-map (kbd "y f") 'pen-yank-path)
(define-key tabulated-list-mode-map (kbd "y m") 'pen-tablist-copy-marked)
(define-key tabulated-list-mode-map (kbd "y s") 'pen-tablist-copy-selected)
(define-key tabulated-list-mode-map (kbd "y y") 'pen-tablist-copy-line-or-marked-andor-selected)
;; (define-key tablist-minor-mode-map (kbd "y") nil)
(define-key tabulated-list-mode-map (kbd "c") 'tabulated-list-current-cell-contents)
(define-key tabulated-list-mode-map (kbd "y c") 'tabulated-list-current-cell-contents)
(define-key tabulated-list-mode-map (kbd "y h") 'tabulated-list-current-cell-contents)
(define-key tabulated-list-mode-map (kbd "C-c C-o") 'org-open-at-point)
(define-key global-map (kbd "H-F") 'run-tlm)
(define-key pen-map (kbd "H-\\") 'pen-start-tablist)
(define-key pen-map (kbd "H-|") 'run-tabcmd)
(define-key arp-tablist-mode-map (kbd "p") 'arp-tablist-ping)
(define-key arp-tablist-mode-map (kbd "s") 'arp-tablist-ssh)
(define-key arp-tablist-mode-map (kbd "N") 'arp-tablist-nmap-ports)
(define-key arp-tablist-mode-map (kbd "O") 'arp-tablist-nmap-os-detect)
(define-key mygit-tablist-mode-map (kbd "RET") 'mygit-tablist-gc)
(define-key aws-users-tablist-mode-map (kbd "d") 'aws-delete-user)
(define-key aws-users-tablist-mode-map (kbd "c") 'aws-create-user)
(define-key aws-users-tablist-mode-map (kbd "a") 'aws-add-policy-to-user)
(define-key aws-users-tablist-mode-map (kbd "r") 'aws-remove-policy-from-user)
(define-key subnetscan-tablist-mode-map (kbd "'") 'server-suggest-subnet-scan)
(define-key ports-tablist-mode-map (kbd "k") 'arp-tablist-nmap-ports)

;; Make some vimlike bindings for tabulated list mode
;; This makes refreshing docker container list too annoying.
;; Keep g as revert. Also, remove G since I removed "g g"
;; (define-key tabulated-list-mode-map (kbd "g g") 'beginning-of-buffer)
;; (define-key tabulated-list-mode-map (kbd "g g") nil)
;; (define-key tabulated-list-mode-map (kbd "G") 'end-of-buffer)
;; (define-key tabulated-list-mode-map (kbd "G") nil)
(define-key tabulated-list-mode-map (kbd "g") 'tabulated-list-revert)

(define-key tabulated-list-mode-map (kbd "0") 'tablist-goto-first-column)
(define-key tabulated-list-mode-map (kbd "$") 'end-of-line)
;; (define-key tabulated-list-mode-map (kbd "w") nil)
(define-key tabulated-list-mode-map (kbd "b") 'tablist-backward-column)
(define-key tabulated-list-mode-map (kbd "f") 'tablist-forward-column)

(define-key tabulated-list-mode-map (kbd "p") 'previous-line)
(define-key tabulated-list-mode-map (kbd "n") 'next-line)
(define-key tabulated-list-mode-map (kbd "k") 'previous-line)
(define-key tabulated-list-mode-map (kbd "j") 'next-line)

(define-key tabulated-list-mode-map (kbd "M-<left>") 'tablist-backward-column)
(define-key tabulated-list-mode-map (kbd "M-<right>") 'tablist-forward-column)
(define-key tabulated-list-mode-map (kbd "M-<up>") 'previous-line)
(define-key tabulated-list-mode-map (kbd "M-<down>") 'next-line)

(define-key tablist-minor-mode-map (kbd "K") 'tablist-do-kill-lines)
;; (define-key tablist-minor-mode-map (kbd "G") 'end-of-buffer)
;; (define-key tablist-minor-mode-map (kbd "G") nil)
(define-key tablist-minor-mode-map (kbd "R") 'tablist-revert)
;; (define-key tablist-minor-mode-map (kbd "y") 'pen-tablist-copy-marked)

;; DONE: Make new simpler version
(defun tablist-move-to-column (n)
  "Move to the N'th list column."
  (interactive "p")
  ;; (when (tabulated-list-get-id)
  ;;   (let ((columns (tablist-column-offsets)))
  ;;     (when (or (< n 0)
  ;;               (>= n (length columns)))
  ;;       (error "No such column: %s" n))
  ;;     (beginning-of-line)
  ;;     ;; (message "tablist-forward-column %d" n)
  ;;     (tablist-forward-column n)))
  (let ((columns (tablist-column-offsets)))
      (when (or (< n 0)
                (>= n (length columns)))
        (error "No such column: %s" n))
      (tablist-goto-first-column)
      ;; (message "tablist-forward-column %d" n)
      (tablist-forward-column n)))

;; Add faces for whitespace
(defun tabulated-list-print-col (n col-desc x)
  "Insert a specified Tabulated List entry at point.
N is the column number, COL-DESC is a column descriptor (see
`tabulated-list-entries'), and X is the column number at point.
Return the column number after insertion."
  (let* ((format    (aref tabulated-list-format n))
	     (name      (nth 0 format))
	     (width     (nth 1 format))
	     (props     (nthcdr 3 format))
	     (pad-right (or (plist-get props :pad-right) 1))
         (right-align (plist-get props :right-align))
         (label (cond ((stringp col-desc) col-desc)
                      ((eq (car col-desc) 'image) " ")
                      (t (car col-desc))))
         (label-width (string-width label))
	     (help-echo (concat (car format) ": " label))
	     (opoint (point))
	     (not-last-col (< (1+ n) (length tabulated-list-format)))
	     (available-space (and not-last-col
                               (if right-align
                                   width
                                 (tabulated-list--available-space width n)))))
    ;; Truncate labels if necessary (except last column).
    ;; Don't truncate to `width' if the next column is align-right
    ;; and has some space left, truncate to `available-space' instead.
    (when (and not-last-col
	           (> label-width available-space))
      (setq label (truncate-string-to-width
		           label available-space nil nil t t)
	        label-width available-space))
    (setq label (bidi-string-mark-left-to-right label))
    (when (and right-align (> width label-width))
      (let ((shift (- width label-width)))
        (insert (propertize (make-string shift ?\s)
                            'display `(space :align-to ,(+ x shift))
                            'face 'font-lock-warning-face))
        (setq width (- width shift))
        (setq x (+ x shift))))
    (cond ((stringp col-desc)
           (insert (if (get-text-property 0 'help-echo label)
                       label
                     (propertize label 'help-echo help-echo))))
          ((eq (car col-desc) 'image)
           (insert (propertize " "
                               'display col-desc
                               'face 'ahs-plugin-bod-face
                               'help-echo help-echo)))
          ((apply 'insert-text-button label (cdr col-desc))))
    (let ((next-x (+ x pad-right width)))
      ;; No need to append any spaces if this is the last column.
      (when not-last-col
        (when (> pad-right 0) (insert (make-string pad-right ?\s)))
        (insert (propertize
                 (make-string (- width (min width label-width)) ?\s)
                 'display `(space :align-to ,next-x)
                 ;; 'face 'ac-candidate-face
                 )))
      (put-text-property opoint (point) 'tabulated-list-column-name name)
      next-x)))

;; For some reason marks are not being cleared
;; I need to fix up tabulated-list unmarking
;; j:tablist-unmark-all-marks
;; Fixed. Kinda

(defun tablist-get-mark-state ()
  "Return the mark state of the entry at point."
  (save-excursion
    (move-to-column 3)
    (eq 'dired-marked (get-text-property (point) 'face))
    ;; (when (looking-at "^\\([^ ]\\)")
    ;;   (let ((mark (buffer-substring
    ;;                (match-beginning 1)
    ;;                (match-end 1))))
    ;;     (tablist-move-to-major-column)
    ;;     (list (aref mark 0)
    ;;           (get-text-property 0 'face mark)
    ;;           (get-text-property (point) 'face))))
    ))

(defun dired-current-line-marked-p ()
  (tablist-get-mark-state))

(defun pen-tabulated-list-get-entry ()
  (mapcar
   'str
   (vec2list (tabulated-list-get-entry))))

(defun pen-tablist-get-marked (&optional invisible-p)
  ;; Collect a sexp of all the entries
  ;; Use j:tablist-export-csv

  ;; Actually, it's simpler to use this
  ;; (tabulated-list-get-entry)
  (save-excursion-and-region-reliably

   (goto-char (point-min))
   (unless invisible-p
     (tablist-skip-invisible-entries))

   (-filter 'identity
            (cl-loop while (not (eobp)) collect
                     (let ((row
                            (if (dired-current-line-marked-p)
                                ;; http://xahlee.info/emacs/emacs/elisp_list_vs_vector.html
                                (pen-tabulated-list-get-entry))))
                       (if invisible-p
                           (forward-line)
                         (tablist-forward-entry))
                       row)))))

(defun tablist-unmark ()
  (let ((tablist-marker-char ?\s)
        tablist-marker-face
        tablist-marked-face)
    (tablist-put-mark)))
(defalias 'tablist-del-mark 'tablist-unmark)

;; Simplify this. I don't know what tablist mark characters are.
;; But it's too complicated, I think. I just want to mark lines and operate on them.
;; Marks are a tablist thing and not a tabulated list thing
(defun tablist-unmark-all-marks (&optional marks interactive)
  "Remove all marks in MARKS.

MARKS should be a string of mark characters to match and defaults
to all marks.  Interactively, remove all marks, unless a prefix
arg was given, in which case ask about which ones to remove.
Give a message, if interactive is non-nil.

Returns the number of unmarked marks."
  (interactive
   (list (if current-prefix-arg
             (read-string "Remove marks: ")) t))

  (let ((removed 0))
    (save-excursion
      (goto-char (point-min))
      (let ((another-line (not (eobp))))

        (while another-line
          (tablist-unmark)
          (setq another-line (tablist-next-line 1))
          (cl-incf removed))))
    (when interactive
      (message "Removed %d marks" removed))

    ;; Remove the mark column
    (when
        (and (< 0 tabulated-list-padding)
             (< 0 pen-tablist-min-padding))
      
      (setq tabulated-list-padding 0)
      (setq pen-tablist-min-padding 0)
      (tabulated-list-revert))
    
    removed))

(defun tablist-nth-column (n &optional entry)
  (unless entry (setq entry (tabulated-list-get-entry)))
  (when (and entry
             (>= n 0)
             (< n (length entry)))
    (let ((str (elt entry n)))
      (if (stringp str)
          str
        (car str)))))
(defalias 'pen-tablist-nth-column 'tablist-nth-column)

;; The one in the original package seems incorrect
(defun pen-tablist-nth-entry (&optional n)
  (if (and n (< n 1))
      (error "n must be > 0"))
  (setq n (or (- n 1) 1))
  (if n
      (save-excursion
        (beginning-of-buffer)
        (dotimes (- n 1)
          (tablist-next-line))
        (tabulated-list-get-entry))
    (tabulated-list-get-entry)))

(defun pen-tablist-get-selected ()
  (if (not (pen-selected-p))
      ;; (error "No region selected")
      nil
    (-let* (((start end) (pen-get-region-line-numbers))
            (collection nil))
      (save-excursion-and-region-reliably
       (goto-line start)
       (while (< (current-line) end)
         (add-to-list 'collection (pen-tabulated-list-get-entry))
         (next-line)))
      collection)))

(defun pen-tablist-copy-selected ()
  (interactive)
  (let ((selected (pen-tablist-get-selected)))
    (if selected
        (xc (pps selected))
      (error "Nothing selected for copying"))))

(defun pen-tablist-copy-first-cell-current-line ()
  (interactive)
  (let ((firstcell (car (pen-tabulated-list-get-entry))))
    (if firstcell
        (xc firstcell)
      (error "Nothing in firstcell for copying"))))

(defun pen-tablist-copy-marked ()
  (interactive)
  (let ((marked (pen-tablist-get-marked)))
    (if marked
        (xc (pps marked))
      (error "Nothing marked for copying"))))

(defun pen-tablist-etv-marked ()
  (interactive)
  (let ((marked (pen-tablist-get-marked)))
    (if marked
        (etv (pps marked) 'emacs-lisp-mode)
      (error "Nothing marked for etv"))))

(defun pen-tablist-copy-line-or-marked-andor-selected ()
  (interactive)
  (let ((marked (pen-tablist-get-marked))
        (selected (pen-tablist-get-selected)))
    (if marked
        (pen-tablist-copy-marked)
      (error "FIXIT Copy the current line"))))

(defalias 'tablist-edit-cell 'tablist-edit-column)

(defun tsv-to-org-table ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")

    (org-table-select)
    (delete-region (mark) (point))

    (let ((beg (point))
          (pm (point-max)))
      (insert-file-contents file)
      (org-table-convert-region beg (+ (point) (- (point-max) pm)) separator))

    (org-table-import newfile nil)
    (org-table-insert-hline)))

(defun tablist-to-org-table ()
  (interactive)
  (nbfs (pen-snc "csv2org-table" (tablist-to-csv))
        nil 'org-mode))

(defun tabulated-list-init-header ()
  "Set up header line for the Tabulated List buffer."
  ;; FIXME: Should share code with tabulated-list-print-col!

  ;; I need to check for tabulated-list-mode because
  ;; (add-hook 'window-state-change-hook #'tabulated-list-init-header)
  (if (major-mode-p 'tabulated-list-mode)
      (let* ((x (max tabulated-list-padding 0))
             (button-props `(help-echo "Click to sort by column"
                                       mouse-face header-line-highlight
                                       keymap ,tabulated-list-sort-button-map))
             (len (length tabulated-list-format))
             ;; Pre-compute width for available-space compution.
             (hcols (mapcar #'car tabulated-list-format))
             (tabulated-list--near-rows (list hcols hcols))
             (cols nil))
        (push (propertize " " 'display
                          `(space :align-to (+ header-line-indent-width ,x)))
              cols)
        (let ((cumulative-len 0))
          (dotimes (n len)
            (let* ((col (aref tabulated-list-format n))
                   (not-last-col (< n (1- len)))
                   (label (nth 0 col))
                   (lablen (length label))
                   (pname label)
                   (width (nth 1 col))
                   (props (nthcdr 3 col))
                   (pad-right (or (plist-get props :pad-right) 1))
                   (right-align (plist-get props :right-align))
                   (next-x (+ x pad-right width))
                   (available-space
                    (and not-last-col
                         (if right-align
                             width
                           (tabulated-list--available-space width n)))))
              (when (and (>= lablen 3)
                         not-last-col
                         (> lablen available-space))
                (setq label (truncate-string-to-width label available-space
                                                      nil nil t)))
              (let* ((cc (cond
                          ;; An unsortable column
                          ((not (nth 2 col))
                           (propertize label 'tabulated-list-column-name pname))
                          ;; The selected sort column
                          ((equal (car col) (car tabulated-list-sort-key))
                           (apply 'propertize
                                  (concat label
                                          (cond
                                           ((and (< lablen 3) not-last-col) "")

                                           ;; reverse the mouse-face
                                           ;; mouse-face
                                           ((cdr tabulated-list-sort-key)
                                            (propertize ;; (format "%c" tabulated-list-gui-sort-indicator-desc)
                                             "↑"
                                             'face 'transient-heading))
                                           (t
                                            (propertize ;; (format "%c" tabulated-list-gui-sort-indicator-asc)
                                             "↓"
                                             'face 'transient-heading))))
                                  ;; 'face 'bold
                                  'face 'transient-heading
                                  'tabulated-list-column-name pname
                                  button-props))
                          ;; Unselected sortable column.
                          (t (apply 'propertize label
                                    'tabulated-list-column-name pname
                                    button-props)))))
                ;; (message "%d %d %d %s" cumulative-len (window-hscroll) (or available-space (length cc)) cc)
                (if (>= cumulative-len (window-hscroll))
                    (push
                     cc
                     cols))
                (setq cumulative-len (+ cumulative-len (or available-space (length cc)))))
              (when right-align
                (let ((shift (- width (string-width (car cols)))))
                  (when (> shift 0)
                    (setq cols
                          (cons (car cols)
                                (cons
                                 (propertize
                                  (make-string shift ?\s)
                                  'display
                                  `(space :align-to
                                          (+ header-line-indent-width ,(+ x shift))))
                                 (cdr cols))))
                    (setq x (+ x shift)))))
              (if (>= pad-right 0)
                  (push (propertize
                         " "
                         'display `(space :align-to
                                          (+ header-line-indent-width ,(- next-x (window-hscroll))))
                         'face 'fixed-pitch)
                        cols))
              (setq x next-x))))
        (setq cols (apply 'concat (nreverse cols)))
        (if tabulated-list-use-header-line
            (setq header-line-format (list "" 'header-line-indent cols))
          (setq-local tabulated-list--header-string cols)))))

(add-hook 'changed-hscroll-hook 'tabulated-list-init-header)

(tabulated-list-init-header)

(defun tablist-show-info-popup ()
  (interactive)
  (let ((data (append
               `(,(concat "Cell contents: " (str (e/q (nth (tabulated-list-current-column) (vector2list (tabulated-list-get-entry))))))
                 ,(concat "Attribute: " (e/q (nth (tabulated-list-current-column) (vector2list (tabulated-list-get-entry)))))
                 ,(concat "Entry ID: " (str (tabulated-list-get-id)))
                 "")

               ;; (mapcar (lambda (e) (s-join ": " e))
               ;;         (-zip-lists
               ;;          (mapcar 'car (vector2list tabulated-list-format))
               ;;          (mapcar 'str (vector2list (tabulated-list-get-entry)))))
               ))
        (id (str (tabulated-list-get-id))))
    (comment
     (etv
      ;; tpop-fit-vim-string
      ;; pen-custom-lsp-ui-doc-display
      (pen-list2str data)
      id))

    (with-current-buffer
        (tablist-buffer-from-csv-string
         ;; tpop-fit-vim-string
         ;; pen-custom-lsp-ui-doc-display

         (list2str
          (mapcar (lambda (e) (s-join "," (mapcar 'e/q e)))
                  (append '(("Key" "Value"))
                          (-zip-lists
                           (mapcar 'car (vector2list tabulated-list-format))
                           (mapcar 'str (vector2list (tabulated-list-get-entry)))))))
         t
     
         ;; (pen-list2str data)
         ;; (str (tabulated-list-get-id))
         )

      ;; (pen-custom-lsp-ui-doc-display (pen-list2str data) id)
      ;; (tpop-fit-vim-string (pen-list2str data) id)
      )))

(define-key tabulated-list-mode-map (kbd "i") 'tablist-show-info-popup)

(defun pen-tablist-select-cell ()
  (interactive)
  (if (bolp)
      (forward-char))
  (pen-select-regex-at-point
   (pen-unregexify (tabulated-list-current-cell-contents t))))

(define-key tabulated-list-mode-map (kbd "r") 'pen-tablist-select-cell)

;; Don't use tablist-minor-mode-map because it will override the major
;; mode map of for example sx-question-list-mode
(comment
 (define-key tablist-minor-mode-map (kbd "m") nil)
 (define-key tablist-minor-mode-map (kbd ",") nil)
 (define-key tablist-minor-mode-map (kbd "RET") nil)
 (define-key tablist-minor-mode-map (kbd "m") 'tablist-mark-forward-and-next)
 (define-key tablist-minor-mode-map (kbd ",") 'tablist-mark-forward)
 (define-key tablist-minor-mode-map (kbd "RET") 'pen-tablist-etv-marked))

;; These get in the way of prodigy bindings, though instead of unbinding these, I think I should keep them bound
;; but have functions which defer to other packages
(define-key tablist-minor-mode-map (kbd "m") nil)
(define-key tablist-minor-mode-map (kbd "u") nil)
(define-key tablist-minor-mode-map (kbd "U") nil)

(define-key tabulated-list-mode-map (kbd "m") 'tablist-mark-forward-and-next)
(define-key tabulated-list-mode-map (kbd ",") 'tablist-mark-forward)
(define-key tabulated-list-mode-map (kbd "RET") 'pen-tablist-etv-marked)


(defun tablist-sort (&optional column)
  "Sort the tabulated-list by COLUMN.

COLUMN may be either a name or an index.  The default compare
function is given by the `tabulated-list-format', which see.

This function saves the current sort column and the inverse
sort-direction in the variable `tabulated-list-sort-key', which
also determines the default COLUMN and direction.

The main difference to `tabulated-list-sort' is, that this
function sorts the buffer in-place and it ignores a nil sort
entry in `tabulated-list-format' and sorts on the column
anyway (why not ?)."

  (interactive
   (list
    (if (null current-prefix-arg)
        (tablist-column-name
         (or (tablist-current-column)
             (car (tablist-major-columns))
             0))
      (tablist-read-column-name
       '(4) "Sort by column"
       (tablist-column-name (car (tablist-major-columns)))))))

  (unless column
    (setq column (or (car tabulated-list-sort-key)
                     (tablist-column-name (car (tablist-major-columns)))
                     (tablist-column-name 0))))
  (when (numberp column)
    (let ((column-name (tablist-column-name column)))
      (unless column-name
        (error "No such column: %d" column))
      (setq column column-name)))

  (setq tabulated-list-sort-key
        (cons column
              (if (equal column (car tabulated-list-sort-key))
                  (cdr tabulated-list-sort-key))))

  (let* ((entries (if (functionp tabulated-list-entries)
                      (funcall tabulated-list-entries)
                    tabulated-list-entries))
         (reverse (cdr tabulated-list-sort-key))
         (n (tabulated-list--column-number ;;errors if column is n/a
             (car tabulated-list-sort-key)))
         (compare-fn
          (nth 2 (aref tabulated-list-format n))))

    ;; (tv tabulated-list-sort-key)
    ;; (tv column)
    ;; (tv n)
    (when (or (null compare-fn)
              (eq compare-fn t))
      (setq compare-fn
            (eval
             `(lambda (a b)
                (setq a (aref (cadr a) ,n))
                (setq b (aref (cadr b) ,n))
                ;; (string< (if (stringp a) a (car a))
                ;;          (if (stringp b) b (car b)))
                (dictionary-lessp (if (stringp a) a (car a))
                                  (if (stringp b) b (car b)))))))

    ;; (tv compare-fn)
    (unless compare-fn
      (error "This column cannot be sorted: %s" column))

    (setcdr tabulated-list-sort-key (not reverse))
    
    ;; This is sorting correctly
    ;; (setq entries (tv-pps (sort (copy-sequence entries) compare-fn)))
    
    ;; Presort the entries and hash the result and sort the buffer.
    (setq entries (sort (copy-sequence entries) compare-fn))
    (setq entries (mapcar 'vec2list entries))

    ;; But for some reason it is only sorting by the first column
    (let ((hash (make-hash-table :test 'equal)))

      ;; (: tv-pps entries)
      ;; (: tv-pps (cadr (cadr entries)))
      
      (dotimes (i (length entries))
        ;; (puthash (caar entries) i hash)
        (puthash (vec2list (cadr (cadr entries))) i hash)
        (setq entries (cdr entries)))

      ;; (: tv-pps.hash-table-values hash)
      
      (tablist-with-remembering-entry
        (goto-char (point-min))
        (tablist-skip-invisible-entries)
        (let ((inhibit-read-only t))
          (sort-subr
           nil 'tablist-forward-entry 'end-of-line
           (lambda ()
             ;; Use a hash of the row instead
             ;; (pen-tabulated-list-get-entry)
             ;; (gethash (tabulated-list-get-id) hash 0)
             (gethash (pen-tabulated-list-get-entry) hash 0))
           nil (if reverse '< '>))))
      (tablist-move-to-column n)
      ;; Make the sort arrows display.
      (tabulated-list-init-header))))

(comment
 (length (read (cat "/root/.pen/tmp/f9EfjXiHbr"))))

;; The sorting *does* seem to work in test. Oh, but a hash table is made...
;; Perhaps the hash table is breaking it.
(comment
 (etv
  (pps
   (sort
    '(("pen"
       ["pen" "708" "1" "0" "Jun07" "?" "00:00:21" "  /inspircd-2.0.25/run/bin/inspircd --config=/inspircd-2.0.25/run/conf/inspircd.conf"])
      ("postgres"
       ["postgres" "716" "1" "0" "Jun07" "?" "00:00:07" "  /usr/lib/postgresql/11/bin/postgres -D /var/lib/postgresql/11/main -c config_file=/etc/postgresql/11/main/postgresql.conf"])
      ("postgres"
       ["postgres" "718" "716" "0" "Jun07" "?" "00:00:00" "    postgres: 11/main: checkpointer   "])
      ("postgres"
       ["postgres" "719" "716" "0" "Jun07" "?" "00:00:09" "    postgres: 11/main: background writer   "])
      ("postgres"
       ["postgres" "720" "716" "0" "Jun07" "?" "00:00:08" "    postgres: 11/main: walwriter   "])
      ("postgres"
       ["postgres" "721" "716" "0" "Jun07" "?" "00:00:04" "    postgres: 11/main: autovacuum launcher   "])
      ("postgres"
       ["postgres" "722" "716" "0" "Jun07" "?" "00:00:10" "    postgres: 11/main: stats collector   "])
      ("postgres"
       ["postgres" "723" "716" "0" "Jun07" "?" "00:00:00" "    postgres: 11/main: logical replication launcher   "])
      ("root"
       ["root" "2137263" "0" "0" "14:25" "pts/1" "00:00:00" "bash -c . ~/.emacs.d/pen.el/scripts/setup-term.sh; \"eval\" \"'/root/.emacs.d/pen.el/scripts/newframe.sh'\""])
      ("root"
       ["root" "2137316" "2137263" "0" "14:25" "pts/1" "00:00:00" "  /bin/bash /root/.emacs.d/pen.el/scripts/newframe.sh"])
      ("root"
       ["root" "2137319" "2137316" "0" "14:25" "pts/1" "00:00:00" "    /bin/bash /root/.emacs.d/host/pen.el/scripts/newframe.sh"])
      ("root"
       ["root" "2137329" "2137319" "0" "14:25" "pts/1" "00:00:00" "      /bin/bash /root/.emacs.d/host/pen.el/scripts/in-tm pen-emacsclient -s DEFAULT -a  -t"])
      ("root"
       ["root" "2137382" "2137329" "0" "14:25" "pts/1" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/pen-tm init-or-attach sh -c 'pen-emacsclient' '-s' 'DEFAULT' '-a' '' '-t'"])
      ("root"
       ["root" "2137647" "2137382" "0" "14:25" "pts/1" "00:00:00" "          /bin/bash /root/.emacs.d/host/pen.el/scripts/tmux-scripts/tmux attach -t 1781231116:"])
      ("root"
       ["root" "2137649" "2137647" "0" "14:25" "pts/1" "00:00:00" "            /root/.local/bin/tmux attach -t 1781231116:"])
      ("root"
       ["root" "1" "0" "0" "Jun07" "pts/0" "00:00:03" "/bin/bash /root/run.sh"])
      ("root"
       ["root" "13" "1" "0" "Jun07" "pts/0" "00:00:00" "  /bin/bash /root/.emacs.d/host/pen.el/scripts/run.sh"])
      ("root"
       ["root" "2240567" "13" "0" "17:43" "pts/0" "00:00:00" "    sleep 1000"])
      ("root"
       ["root" "48" "1" "0" "Jun07" "?" "00:00:01" "  /usr/sbin/cron"])
      ("root"
       ["root" "706" "1" "0" "Jun07" "pts/0" "00:00:00" "  ttyd -p 7689 bash -l /root/.emacs.d/pen.el/scripts/newframe.sh"])
      ("root"
       ["root" "857" "1" "0" "Jun07" "?" "00:02:01" "  /root/.local/bin/tmux new -d"])
      ("root"
       ["root" "858" "857" "0" "Jun07" "pts/2" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell"])
      ("root"
       ["root" "859" "858" "0" "Jun07" "pts/2" "00:00:00" "      /bin/bash"])
      ("root"
       ["root" "1289" "857" "0" "Jun07" "pts/4" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell"])
      ("root"
       ["root" "1290" "1289" "0" "Jun07" "pts/4" "00:00:00" "      /bin/bash"])
      ("root"
       ["root" "1895" "857" "0" "Jun07" "pts/5" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c zsh"])
      ("root"
       ["root" "1899" "1895" "0" "Jun07" "pts/5" "00:00:00" "      zsh"])
      ("root"
       ["root" "1989" "857" "0" "Jun07" "pts/6" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell"])
      ("root"
       ["root" "1990" "1989" "0" "Jun07" "pts/6" "00:00:00" "      /bin/bash"])
      ("root"
       ["root" "2719" "857" "0" "Jun07" "pts/8" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_tempuT0h239.sh\" && . /root/.pen/tmp/tf_tempuT0h239.sh;  stty stop undef; stty start undef;  pen-tm attach \"localhost_ws\"; sleep 0.1 ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcRLLNf5s.txt\""])
      ("root"
       ["root" "2720" "2719" "0" "Jun07" "pts/8" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_tempuT0h239.sh\" && . /root/.pen/tmp/tf_tempuT0h239.sh;  stty stop undef; stty start undef;  pen-tm attach \"localhost_ws\"; sleep 0.1 ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcRLLNf5s.txt\""])
      ("root"
       ["root" "2728" "2720" "0" "Jun07" "pts/8" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/pen-tm attach localhost_ws"])
      ("root"
       ["root" "3133" "2728" "0" "Jun07" "pts/8" "00:00:00" "          /bin/bash /tmp/pen-scripts/tmux-scripts/tmux attach -c /root/.pen/documents/notes/ws -t localhost_ws:"])
      ("root"
       ["root" "3135" "3133" "0" "Jun07" "pts/8" "00:00:00" "            /root/.local/bin/tmux attach -c /root/.pen/documents/notes/ws -t localhost_ws:"])
      ("root"
       ["root" "2740" "857" "0" "Jun07" "pts/10" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell"])
      ("root"
       ["root" "2741" "2740" "0" "Jun07" "pts/10" "00:00:00" "      /bin/bash"])
      ("root"
       ["root" "3104" "857" "0" "Jun07" "pts/11" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell"])
      ("root"
       ["root" "3108" "3104" "0" "Jun07" "pts/11" "00:00:00" "      /bin/bash"])
      ("root"
       ["root" "4010" "857" "0" "Jun07" "pts/14" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_tempt1PxaqD.sh\" && . /root/.pen/tmp/tf_tempt1PxaqD.sh; while :; do  stty stop undef; stty start undef;  pen-pak -k s;  agenda ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcQJ6IF9r.txt\"; pen-pak -k f; done"])
      ("root"
       ["root" "4014" "4010" "0" "Jun07" "pts/14" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_tempt1PxaqD.sh\" && . /root/.pen/tmp/tf_tempt1PxaqD.sh; while :; do  stty stop undef; stty start undef;  pen-pak -k s;  agenda ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcQJ6IF9r.txt\"; pen-pak -k f; done"])
      ("root"
       ["root" "4031" "4014" "0" "Jun07" "pts/14" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/pen-pak -k s"])
      ("root"
       ["root" "4984" "857" "0" "Jun07" "pts/13" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_temp3INzlKG.sh\" && . /root/.pen/tmp/tf_temp3INzlKG.sh; while :; do  stty stop undef; stty start undef;  pen-pak -k s;  enotmuch ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rco4ctx92.txt\"; pen-pak -k f; done"])
      ("root"
       ["root" "4985" "4984" "0" "Jun07" "pts/13" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_temp3INzlKG.sh\" && . /root/.pen/tmp/tf_temp3INzlKG.sh; while :; do  stty stop undef; stty start undef;  pen-pak -k s;  enotmuch ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rco4ctx92.txt\"; pen-pak -k f; done"])
      ("root"
       ["root" "4992" "4985" "0" "Jun07" "pts/13" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/pen-pak -k s"])
      ("root"
       ["root" "5402" "857" "0" "Jun07" "pts/7" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_temp4PPizKS.sh\" && . /root/.pen/tmp/tf_temp4PPizKS.sh; while :; do  stty stop undef; stty start undef;  pen-pak -k s;  cfw-agenda ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rc2vCp9K8.txt\"; pen-pak -k f; done"])
      ("root"
       ["root" "5403" "5402" "0" "Jun07" "pts/7" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_temp4PPizKS.sh\" && . /root/.pen/tmp/tf_temp4PPizKS.sh; while :; do  stty stop undef; stty start undef;  pen-pak -k s;  cfw-agenda ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rc2vCp9K8.txt\"; pen-pak -k f; done"])
      ("root"
       ["root" "5412" "5403" "0" "Jun07" "pts/7" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/pen-pak -k s"])
      ("root"
       ["root" "6167" "857" "0" "Jun07" "pts/9" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_tempEbHxz4y.sh\" && . /root/.pen/tmp/tf_tempEbHxz4y.sh; while :; do  stty stop undef; stty start undef;  preview \"clipboard.txt\"; rifle \"clipboard.txt\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcXXxipXs.txt\"; done"])
      ("root"
       ["root" "6168" "6167" "0" "Jun07" "pts/9" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_tempEbHxz4y.sh\" && . /root/.pen/tmp/tf_tempEbHxz4y.sh; while :; do  stty stop undef; stty start undef;  preview \"clipboard.txt\"; rifle \"clipboard.txt\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcXXxipXs.txt\"; done"])
      ("root"
       ["root" "6176" "6168" "0" "Jun07" "pts/9" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/preview clipboard.txt"])
      ("root"
       ["root" "6178" "6176" "0" "Jun07" "pts/9" "00:00:00" "          /bin/bash /root/.emacs.d/host/pen.el/scripts/less -S clipboard.txt"])
      ("root"
       ["root" "6179" "6178" "0" "Jun07" "pts/9" "00:00:00" "            /usr/bin/less -S clipboard.txt"])
      ("root"
       ["root" "6546" "857" "0" "Jun07" "pts/15" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_tempezpiTMX.sh\" && . /root/.pen/tmp/tf_tempezpiTMX.sh; while :; do  stty stop undef; stty start undef;  preview \"files.txt\"; rifle \"files.txt\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcXrfi631.txt\"; done"])
      ("root"
       ["root" "6547" "6546" "0" "Jun07" "pts/15" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_tempezpiTMX.sh\" && . /root/.pen/tmp/tf_tempezpiTMX.sh; while :; do  stty stop undef; stty start undef;  preview \"files.txt\"; rifle \"files.txt\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcXrfi631.txt\"; done"])
      ("root"
       ["root" "6553" "6547" "0" "Jun07" "pts/15" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/preview files.txt"])
      ("root"
       ["root" "6555" "6553" "0" "Jun07" "pts/15" "00:00:00" "          /bin/bash /root/.emacs.d/host/pen.el/scripts/less -S files.txt"])
      ("root"
       ["root" "6557" "6555" "0" "Jun07" "pts/15" "00:00:00" "            /usr/bin/less -S files.txt"])
      ("root"
       ["root" "6927" "857" "0" "Jun07" "pts/17" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_temp20t32w6.sh\" && . /root/.pen/tmp/tf_temp20t32w6.sh; while :; do  stty stop undef; stty start undef;  preview \"glossary.txt\"; rifle \"glossary.txt\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcD1y5xDs.txt\"; done"])
      ("root"
       ["root" "6930" "6927" "0" "Jun07" "pts/17" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_temp20t32w6.sh\" && . /root/.pen/tmp/tf_temp20t32w6.sh; while :; do  stty stop undef; stty start undef;  preview \"glossary.txt\"; rifle \"glossary.txt\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcD1y5xDs.txt\"; done"])
      ("root"
       ["root" "6937" "6930" "0" "Jun07" "pts/17" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/preview glossary.txt"])
      ("root"
       ["root" "6938" "6937" "0" "Jun07" "pts/17" "00:00:00" "          /bin/bash /root/.emacs.d/host/pen.el/scripts/less -S glossary.txt"])
      ("root"
       ["root" "6939" "6938" "0" "Jun07" "pts/17" "00:00:00" "            /usr/bin/less -S glossary.txt"])
      ("root"
       ["root" "7306" "857" "0" "Jun07" "pts/18" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_tempo0zLToz.sh\" && . /root/.pen/tmp/tf_tempo0zLToz.sh; while :; do  stty stop undef; stty start undef;  preview \"links.org\"; rifle \"links.org\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcflHQBwY.txt\"; done"])
      ("root"
       ["root" "7307" "7306" "0" "Jun07" "pts/18" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_tempo0zLToz.sh\" && . /root/.pen/tmp/tf_tempo0zLToz.sh; while :; do  stty stop undef; stty start undef;  preview \"links.org\"; rifle \"links.org\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcflHQBwY.txt\"; done"])
      ("root"
       ["root" "7313" "7307" "0" "Jun07" "pts/18" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/preview links.org"])
      ("root"
       ["root" "7315" "7313" "0" "Jun07" "pts/18" "00:00:00" "          /bin/bash /root/.emacs.d/host/pen.el/scripts/less -S links.org"])
      ("root"
       ["root" "7316" "7315" "0" "Jun07" "pts/18" "00:00:00" "            /usr/bin/less -S links.org"])
      ("root"
       ["root" "7709" "857" "0" "Jun07" "pts/19" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_tempnVyQSEH.sh\" && . /root/.pen/tmp/tf_tempnVyQSEH.sh; while :; do  stty stop undef; stty start undef;  preview \"perspective.org\"; rifle \"perspective.org\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcHmI1wye.txt\"; done"])
      ("root"
       ["root" "7710" "7709" "0" "Jun07" "pts/19" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_tempnVyQSEH.sh\" && . /root/.pen/tmp/tf_tempnVyQSEH.sh; while :; do  stty stop undef; stty start undef;  preview \"perspective.org\"; rifle \"perspective.org\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcHmI1wye.txt\"; done"])
      ("root"
       ["root" "7718" "7710" "0" "Jun07" "pts/19" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/preview perspective.org"])
      ("root"
       ["root" "7719" "7718" "0" "Jun07" "pts/19" "00:00:00" "          /bin/bash /root/.emacs.d/host/pen.el/scripts/less -S perspective.org"])
      ("root"
       ["root" "7720" "7719" "0" "Jun07" "pts/19" "00:00:00" "            /usr/bin/less -S perspective.org"])
      ("root"
       ["root" "8222" "857" "0" "Jun07" "pts/20" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_tempjxCr4QT.sh\" && . /root/.pen/tmp/tf_tempjxCr4QT.sh; while :; do  stty stop undef; stty start undef;  preview \"README.org\"; rifle \"README.org\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcD5G9uhO.txt\"; done"])
      ("root"
       ["root" "8223" "8222" "0" "Jun07" "pts/20" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_tempjxCr4QT.sh\" && . /root/.pen/tmp/tf_tempjxCr4QT.sh; while :; do  stty stop undef; stty start undef;  preview \"README.org\"; rifle \"README.org\" ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rcD5G9uhO.txt\"; done"])
      ("root"
       ["root" "8230" "8223" "0" "Jun07" "pts/20" "00:00:00" "        /bin/bash /root/.emacs.d/host/pen.el/scripts/preview README.org"])
      ("root"
       ["root" "8232" "8230" "0" "Jun07" "pts/20" "00:00:00" "          /bin/bash /root/.emacs.d/host/pen.el/scripts/less -S README.org"])
      ("root"
       ["root" "8233" "8232" "0" "Jun07" "pts/20" "00:00:00" "            /usr/bin/less -S README.org"])
      ("root"
       ["root" "8241" "857" "0" "Jun07" "pts/21" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c \"bash\""])
      ("root"
       ["root" "8242" "8241" "0" "Jun07" "pts/21" "00:00:00" "      bash"])
      ("root"
       ["root" "2137643" "857" "0" "14:25" "pts/12" "00:00:00" "    sh -c 'pen-emacsclient' '-s' 'DEFAULT' '-a' '' '-t'"])
      ("root"
       ["root" "2137646" "2137643" "0" "14:25" "pts/12" "00:00:00" "      /bin/bash /root/.emacs.d/host/pen.el/scripts/pen-emacsclient -s DEFAULT -a  -t"])
      ("root"
       ["root" "2137780" "2137646" "0" "14:25" "pts/12" "00:00:00" "        /usr/local/bin/emacsclient -s DEFAULT -a  -t"])
      ("root"
       ["root" "2140760" "857" "0" "14:36" "pts/16" "00:00:00" "    /bin/bash /root/.emacs.d/pen.el/scripts/tmux-shell -c test -f \"/root/.pen/tmp/tf_temp8iNHXk2.sh\" && . /root/.pen/tmp/tf_temp8iNHXk2.sh;  stty stop undef; stty start undef;  zsh ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rccXmFbVO.txt\""])
      ("root"
       ["root" "2140761" "2140760" "0" "14:36" "pts/16" "00:00:00" "      /bin/bash -c test -f \"/root/.pen/tmp/tf_temp8iNHXk2.sh\" && . /root/.pen/tmp/tf_temp8iNHXk2.sh;  stty stop undef; stty start undef;  zsh ; ret=$?; printf -- \"%s\" $ret > \"/root/.pen/tmp/tf_rccXmFbVO.txt\""])
      ("root"
       ["root" "2140766" "2140761" "0" "14:36" "pts/16" "00:00:00" "        zsh"])
      ("root"
       ["root" "2141207" "2140766" "0" "14:36" "pts/16" "00:00:00" "          /bin/bash /tmp/pen-scripts/container/pe"])
      ("root"
       ["root" "2141252" "2141207" "0" "14:36" "pts/16" "00:00:00" "            /bin/bash /root/.emacs.d/host/pen.el/scripts/pin"])
      ("root"
       ["root" "2141488" "2141252" "0" "14:36" "pts/16" "00:00:00" "              bash -c . ~/.emacs.d/pen.el/scripts/setup-term.sh; \"eval\" \"'newframe.sh'\""])
      ("root"
       ["root" "2141536" "2141488" "0" "14:36" "pts/16" "00:00:00" "                /bin/bash /root/.emacs.d/host/pen.el/scripts/newframe.sh"])
      ("root"
       ["root" "2141546" "2141536" "0" "14:36" "pts/16" "00:00:00" "                  /bin/bash /root/.emacs.d/host/pen.el/scripts/in-tm pen-emacsclient -s DEFAULT -a  -t"])
      ("root"
       ["root" "2141574" "2141546" "0" "14:36" "pts/16" "00:00:00" "                    /bin/bash /root/.emacs.d/host/pen.el/scripts/pen-emacsclient -s DEFAULT -a  -t"])
      ("root"
       ["root" "2141706" "2141574" "0" "14:36" "pts/16" "00:00:00" "                      /usr/local/bin/emacsclient -s DEFAULT -a  -t"])
      ("root"
       ["root" "5007" "1" "0" "Jun07" "?" "00:11:40" "  /usr/local/bin/emacs --daemon=pen-emacsd-1"])
      ("root"
       ["root" "34681" "5007" "0" "Jun07" "?" "00:00:00" "    /bin/bash /tmp/pen-scripts/ispell-scripts/ispell -a -m -B"])
      ("root"
       ["root" "34815" "34681" "0" "Jun07" "?" "00:00:00" "      /usr/bin/ispell -a -m -B"])
      ("root"
       ["root" "36340" "5007" "0" "Jun07" "pts/22" "00:00:00" "    /bin/bash /root/.emacs.d/host/pen.el/scripts/pen-banner.sh"])
      ("root"
       ["root" "36354" "36340" "0" "Jun07" "pts/22" "00:00:00" "      /bin/bash /root/.emacs.d/host/pen.el/scripts/less -rS"])
      ("root"
       ["root" "36363" "36354" "0" "Jun07" "pts/22" "00:00:00" "        /usr/bin/less -rS"])
      ("root"
       ["root" "1186068" "5007" "0" "Jun11" "?" "00:00:00" "    /bin/bash /root/.emacs.d/host/pen.el/scripts/node /root/.emacs.d/.cache/lsp/npm/bash-language-server/bin/bash-language-server start"])
      ("root"
       ["root" "1186562" "1186068" "0" "Jun11" "?" "00:00:07" "      node /root/.emacs.d/.cache/lsp/npm/bash-language-server/bin/bash-language-server start"])
      ("root"
       ["root" "3526372" "1" "6" "09:13" "?" "00:31:35" "  /usr/local/bin/emacs --daemon=DEFAULT"])
      ("root"
       ["root" "3540329" "3526372" "0" "09:16" "?" "00:00:00" "    /bin/bash /tmp/pen-scripts/ispell-scripts/ispell -a -m -B"])
      ("root"
       ["root" "3540403" "3540329" "0" "09:16" "?" "00:00:00" "      /usr/bin/ispell -a -m -B"])
      ("root"
       ["root" "2066660" "3526372" "0" "12:57" "?" "00:00:00" "    /bin/bash /root/.emacs.d/host/pen.el/scripts/node /root/.emacs.d/.cache/lsp/npm/bash-language-server/bin/bash-language-server start"])
      ("root"
       ["root" "2067237" "2066660" "0" "12:57" "?" "00:00:03" "      node /root/.emacs.d/.cache/lsp/npm/bash-language-server/bin/bash-language-server start"])
      ("root"
       ["root" "2240933" "3526372" "0" "17:58" "?" "00:00:00" "    /usr/bin/zsh -c export DISPLAY=\":0\" PATH=\"/tmp/pen-scripts/deprecated:/tmp/pen-scripts/oleo:/tmp/pen-scripts/babashka:/tmp/pen-scripts/babashka/playground:/tmp/pen-scripts/babashka/utils:/tmp/pen-scripts/babashka/basic_cli_tool:/tmp/pen-scripts/time:/tmp/pen-scripts/strace-scripts:/tmp/pen-scripts/stackexchange:/tmp/pen-scripts/math-scripts:/tmp/pen-scripts/emacs-internal-scripts:/tmp/pen-scripts/xsh-scripts:/tmp/pen-scripts/latex-scripts:/tmp/pen-scripts/playground:/tmp/pen-scripts/racket-scripts:/tmp/pen-scripts/visidata-scripts:/tmp/pen-scripts/rosie-scripts:/tmp/pen-scripts/dump-clean_dir:/tmp/pen-scripts/grepapp-scripts:/tmp/pen-scripts/fennel-scripts:/tmp/pen-scripts/apl-scripts:/tmp/pen-scripts/term-scripts:/tmp/pen-scripts/rust-tools:/tmp/pen-scripts/utils:/tmp/pen-scripts/prompting:/tmp/pen-scripts/hymnal-resources:/tmp/pen-scripts/websearch:/tmp/pen-scripts/programming:/tmp/pen-scripts/locate-scripts:/tmp/pen-scripts/tty-scripts:/tmp/pen-scripts/workers:/tmp/pen-scripts/writing:/tmp/pen-scripts/git:/tmp/pen-scripts/vim-scripts:/tmp/pen-scripts/lib:/tmp/pen-scripts/gum-scripts:/tmp/pen-scripts/pagers:/tmp/pen-scripts/bible-resources:/tmp/pen-scripts/geography:/tmp/pen-scripts/christian-resources:/tmp/pen-scripts/elpa-scripts:/tmp/pen-scripts/eshell-scripts:/tmp/pen-scripts/dbus:/tmp/pen-scripts/update:/tmp/pen-scripts/databases:/tmp/pen-scripts/filters:/tmp/pen-scripts/filters/transformers:/tmp/pen-scripts/filters/readability:/tmp/pen-scripts/filters/extractors:/tmp/pen-scripts/filters/grepfilters:/tmp/pen-scripts/filters/bikeshed:/tmp/pen-scripts/filters/summarizers:/tmp/pen-scripts/inotify-scripts:/tmp/pen-scripts/font-scripts:/tmp/pen-scripts/python-scripts:/tmp/pen-scripts/ispell-scripts:/tmp/pen-scripts/supervisor:/tmp/pen-scripts/golang:/tmp/pen-scripts/unix-aliases:/tmp/pen-scripts/jstate:/tmp/pen-scripts/browser-scripts:/tmp/pen-scripts/productivity:/tmp/pen-scripts/tablist-scripts:/tmp/pen-scripts/mon:/tmp/pen-scripts/org-scripts:/tmp/pen-scripts/cat-scripts:/tmp/pen-scripts/net-scripts:/tmp/pen-scripts/bbs-scripts:/tmp/pen-scripts/bible-books:/tmp/pen-scripts/bible-dbs:/tmp/pen-scripts/x11:/tmp/pen-scripts/container:/tmp/pen-scripts/scrape-scripts:/tmp/pen-scripts/emacs-scripts:/tmp/pen-scripts/pics:/tmp/pen-scripts/sqlite-scripts:/tmp/pen-scripts/strings:/tmp/pen-scripts/bikeshed:/tmp/pen-scripts/haskell-scripts:/tmp/pen-scripts/haskell-scripts/cabal-haskellscript-scripts:/tmp/pen-scripts/haskell-scripts/stack-lts-6.25-scripts:/tmp/pen-scripts/haskell-scripts/cabal-3.10.3.0-scripts:/tmp/pen-scripts/sorting:/tmp/pen-scripts/host-scripts:/tmp/pen-scripts/awk-scripts:/tmp/pen-scripts/ed-scripts:/tmp/pen-scripts/metservice:/tmp/pen-scripts/chess:/tmp/pen-scripts/ruby-scripts:/tmp/pen-scripts/unicode-scripts:/tmp/pen-scripts/vim-related:/tmp/pen-scripts/text-scripts:/tmp/pen-scripts/ved-scripts:/tmp/pen-scripts/emacs-remote-control:/tmp/pen-scripts/clojure:/tmp/pen-scripts/clojure/utils:/tmp/pen-scripts/clojure/.cpcache:/tmp/pen-scripts/clojure/tools:/tmp/pen-scripts/graphviz:/tmp/pen-scripts/docker-scripts:/tmp/pen-scripts/nl:/tmp/pen-scripts/markdown:/tmp/pen-scripts/games:/tmp/pen-scripts/c-scripts:/tmp/pen-scripts/bible-mode-scripts:/tmp/pen-scripts/bible-mode-scripts/dbqueries:/tmp/pen-scripts/sh-ext:/tmp/pen-scripts/html:/tmp/pen-scripts/libraries:/tmp/pen-scripts/grepscripts:/tmp/pen-scripts/pascal:/tmp/pen-scripts/prolog-scripts:/tmp/pen-scripts/prolog-scripts/tutorialspoint:/tmp/pen-scripts/apt:/tmp/pen-scripts/sixel:/tmp/pen-scripts/logging-scripts:/tmp/pen-scripts/filter-tools:/tmp/pen-scripts/docs:/tmp/pen-scripts/eww:/tmp/pen-scripts/net:/tmp/pen-scripts/shell:/tmp/pen-scripts/readme-scripts:/tmp/pen-scripts/apps:/tmp/pen-scripts/filesystem:/tmp/pen-scripts/git-scripts:/tmp/pen-scripts/m4-scripts:/tmp/pen-scripts/devotionals:/tmp/pen-scripts/bible-scripts-tests:/tmp/pen-scripts/tmux-scripts:/tmp/pen-scripts/rust-scripts:/tmp/pen-scripts/scratch:/root/.emacs.d/host/host/pen.el/scripts/container:/root/.emacs.d/host/pen.el/scripts/container:/root/.emacs.d/host/host/pen.el/scripts:/root/.emacs.d/host/pen.el/scripts:/root/.emacs.d/host/host/pen.el/scripts-host:/root/.emacs.d/host/pen.el/scripts-host:/root/.emacs.d/host/pen.el/scripts/deprecated:/root/.emacs.d/host/pen.el/scripts/oleo:/root/.emacs.d/host/pen.el/scripts/babashka:/root/.emacs.d/host/pen.el/scripts/babashka/playground:/root/.emacs.d/host/pen.el/scripts/babashka/utils:/root/.emacs.d/host/pen.el/scripts/babashka/basic_cli_tool:/root/.emacs.d/host/pen.el/scripts/time:/root/.emacs.d/host/pen.el/scripts/strace-scripts:/root/.emacs.d/host/pen.el/scripts/stackexchange:/root/.emacs.d/host/pen.el/scripts/math-scripts:/root/.emacs.d/host/pen.el/scripts/emacs-internal-scripts:/root/.emacs.d/host/pen.el/scripts/xsh-scripts:/root/.emacs.d/host/pen.el/scripts/latex-scripts:/root/.emacs.d/host/pen.el/scripts/playground:/root/.emacs.d/host/pen.el/scripts/racket-scripts:/root/.emacs.d/host/pen.el/scripts/visidata-scripts:/root/.emacs.d/host/pen.el/scripts/rosie-scripts:/root/.emacs.d/host/pen.el/scripts/dump-clean_dir:/root/.emacs.d/host/pen.el/scripts/grepapp-scripts:/root/.emacs.d/host/pen.el/scripts/fennel-scripts:/root/.emacs.d/host/pen.el/scripts/apl-scripts:/root/.emacs.d/host/pen.el/scripts/term-scripts:/root/.emacs.d/host/pen.el/scripts/rust-tools:/root/.emacs.d/host/pen.el/scripts/utils:/root/.emacs.d/host/pen.el/scripts/prompting:/root/.emacs.d/host/pen.el/scripts/hymnal-resources:/root/.emacs.d/host/pen.el/scripts/websearch:/root/.emacs.d/host/pen.el/scripts/programming:/root/.emacs.d/host/pen.el/scripts/locate-scripts:/root/.emacs.d/host/pen.el/scripts/tty-scripts:/root/.emacs.d/host/pen.el/scripts/workers:/root/.emacs.d/host/pen.el/scripts/writing:/root/.emacs.d/host/pen.el/scripts/git:/root/.emacs.d/host/pen.el/scripts/vim-scripts:/root/.emacs.d/host/pen.el/scripts/lib:/root/.emacs.d/host/pen.el/scripts/gum-scripts:/root/.emacs.d/host/pen.el/scripts/pagers:/root/.emacs.d/host/pen.el/scripts/bible-resources:/root/.emacs.d/host/pen.el/scripts/geography:/root/.emacs.d/host/pen.el/scripts/christian-resources:/root/.emacs.d/host/pen.el/scripts/elpa-scripts:/root/.emacs.d/host/pen.el/scripts/eshell-scripts:/root/.emacs.d/host/pen.el/scripts/dbus:/root/.emacs.d/host/pen.el/scripts/update:/root/.emacs.d/host/pen.el/scripts/databases:/root/.emacs.d/host/pen.el/scripts/filters:/root/.emacs.d/host/pen.el/scripts/filters/transformers:/root/.emacs.d/host/pen.el/scripts/filters/readability:/root/.emacs.d/host/pen.el/scripts/filters/extractors:/root/.emacs.d/host/pen.el/scripts/filters/grepfilters:/root/.emacs.d/host/pen.el/scripts/filters/bikeshed:/root/.emacs.d/host/pen.el/scripts/filters/summarizers:/root/.emacs.d/host/pen.el/scripts/inotify-scripts:/root/.emacs.d/host/pen.el/scripts/font-scripts:/root/.emacs.d/host/pen.el/scripts/python-scripts:/root/.emacs.d/host/pen.el/scripts/ispell-scripts:/root/.emacs.d/host/pen.el/scripts/supervisor:/root/.emacs.d/host/pen.el/scripts/golang:/root/.emacs.d/host/pen.el/scripts/unix-aliases:/root/.emacs.d/host/pen.el/scripts/jstate:/root/.emacs.d/host/pen.el/scripts/browser-scripts:/root/.emacs.d/host/pen.el/scripts/productivity:/root/.emacs.d/host/pen.el/scripts/tablist-scripts:/root/.emacs.d/host/pen.el/scripts/mon:/root/.emacs.d/host/pen.el/scripts/org-scripts:/root/.emacs.d/host/pen.el/scripts/cat-scripts:/root/.emacs.d/host/pen.el/scripts/net-scripts:/root/.emacs.d/host/pen.el/scripts/bbs-scripts:/root/.emacs.d/host/pen.el/scripts/bible-books:/root/.emacs.d/host/pen.el/scripts/bible-dbs:/root/.emacs.d/host/pen.el/scripts/x11:/root/.emacs.d/host/pen.el/scripts/scrape-scripts:/root/.emacs.d/host/pen.el/scripts/emacs-scripts:/root/.emacs.d/host/pen.el/scripts/pics:/root/.emacs.d/host/pen.el/scripts/sqlite-scripts:/root/.emacs.d/host/pen.el/scripts/strings:/root/.emacs.d/host/pen.el/scripts/bikeshed:/root/.emacs.d/host/pen.el/scripts/haskell-scripts:/root/.emacs.d/host/pen.el/scripts/haskell-scripts/cabal-haskellscript-scripts:/root/.emacs.d/host/pen.el/scripts/haskell-scripts/stack-lts-6.25-scripts:/root/.emacs.d/host/pen.el/scripts/haskell-scripts/cabal-3.10.3.0-scripts:/root/.emacs.d/host/pen.el/scripts/sorting:/root/.emacs.d/host/pen.el/scripts/host-scripts:/root/.emacs.d/host/pen.el/scripts/awk-scripts:/root/.emacs.d/host/pen.el/scripts/ed-scripts:/root/.emacs.d/host/pen.el/scripts/metservice:/root/.emacs.d/host/pen.el/scripts/chess:/root/.emacs.d/host/pen.el/scripts/ruby-scripts:/root/.emacs.d/host/pen.el/scripts/unicode-scripts:/root/.emacs.d/host/pen.el/scripts/vim-related:/root/.emacs.d/host/pen.el/scripts/text-scripts:/root/.emacs.d/host/pen.el/scripts/ved-scripts:/root/.emacs.d/host/pen.el/scripts/emacs-remote-control:/root/.emacs.d/host/pen.el/scripts/clojure:/root/.emacs.d/host/pen.el/scripts/clojure/utils:/root/.emacs.d/host/pen.el/scripts/clojure/.cpcache:/root/.emacs.d/host/pen.el/scripts/clojure/tools:/root/.emacs.d/host/pen.el/scripts/graphviz:/root/.emacs.d/host/pen.el/scripts/docker-scripts:/root/.emacs.d/host/pen.el/scripts/nl:/root/.emacs.d/host/pen.el/scripts/markdown:/root/.emacs.d/host/pen.el/scripts/games:/root/.emacs.d/host/pen.el/scripts/c-scripts:/root/.emacs.d/host/pen.el/scripts/bible-mode-scripts:/root/.emacs.d/host/pen.el/scripts/bible-mode-scripts/dbqueries:/root/.emacs.d/host/pen.el/scripts/sh-ext:/root/.emacs.d/host/pen.el/scripts/html:/root/.emacs.d/host/pen.el/scripts/libraries:/root/.emacs.d/host/pen.el/scripts/grepscripts:/root/.emacs.d/host/pen.el/scripts/pascal:/root/.emacs.d/host/pen.el/scripts/prolog-scripts:/root/.emacs.d/host/pen.el/scripts/prolog-scripts/tutorialspoint:/root/.emacs.d/host/pen.el/scripts/apt:/root/.emacs.d/host/pen.el/scripts/sixel:/root/.emacs.d/host/pen.el/scripts/logging-scripts:/root/.emacs.d/host/pen.el/scripts/filter-tools:/root/.emacs.d/host/pen.el/scripts/docs:/root/.emacs.d/host/pen.el/scripts/eww:/root/.emacs.d/host/pen.el/scripts/net:/root/.emacs.d/host/pen.el/scripts/shell:/root/.emacs.d/host/pen.el/scripts/readme-scripts:/root/.emacs.d/host/pen.el/scripts/apps:/root/.emacs.d/host/pen.el/scripts/filesystem:/root/.emacs.d/host/pen.el/scripts/git-scripts:/root/.emacs.d/host/pen.el/scripts/m4-scripts:/root/.emacs.d/host/pen.el/scripts/devotionals:/root/.emacs.d/host/pen.el/scripts/bible-scripts-tests:/root/.emacs.d/host/pen.el/scripts/tmux-scripts:/root/.emacs.d/host/pen.el/scripts/rust-scripts:/root/.emacs.d/host/pen.el/scripts/scratch:/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/go/bin:/root/.cargo/bin/cargo:/root/repos/go-ethereum/build/bin:/root/.cabal/bin:/root/.ghcup/bin:/usr/local/go/bin:/root/.local/bin:/root/.roswell/bin:/usr/games:/home/shane/source/git/fzf/bin\" TMUX=\"\" TMUX_PANE=\"\" PEN_WORKER=\"DEFAULT\" PEN_PREFIX=\"1\" PEN_GLOBAL_PREFIX=\"1\" PEN_PROMPTS_DIR=\"~/.emacs.d//host/prompts/prompts\" PEN_ENGINE=\"Human\"; ( cd \"/root/.emacs.d/host/pen.el/src/\"; . $HOME/.shellrc; \"ps\" \"-H\" \"-w\" \"-w\" \"-ef\"; echo -n $? > /tmp/elisp-bash-ps-h-2c94d11ce5_exit_code_65Sezg.txt ) > /tmp/elisp-bash-ps-h-2c94d11ce5_output_OclPzI.txt"])
      ("root"
       ["root" "2240974" "2240933" "0" "17:58" "?" "00:00:00" "      /bin/sh /root/.emacs.d/host/pen.el/scripts/ps -H -w -w -ef"])
      ("root"
       ["root" "2240975" "2240974" "0" "17:58" "?" "00:00:00" "        /bin/ps -H -w -w -ef"])
      ("root"
       ["root" "2238166" "1" "0" "17:23" "?" "00:00:00" "  xsel -p -i"])
      ("root"
       ["root" "2238169" "1" "0" "17:23" "?" "00:00:00" "  xsel -s -i"])
      ("root"
       ["root" "2238213" "1" "0" "17:23" "?" "00:00:00" "  xsel --clipboard --input"]))

    (let ((n 6))
      (eval
       `(lambda (a b)
          (setq a (aref (cadr a) ,n))
          (setq b (aref (cadr b) ,n))
          ;; (string< (if (stringp a) a (car a))
          ;;          (if (stringp b) b (car b)))
          (dictionary-lessp (if (stringp a) a (car a))
                            (if (stringp b) b (car b))))))))))
;; 19;18M



(provide 'pen-tablist)
