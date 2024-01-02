(require 'alert)

(use-package org-super-agenda :ensure t)
(use-package org-alert :ensure t)

;; (setq org-agenda-show-future-repeats nil)
(setq org-agenda-show-future-repeats t)
;; Show a single future repeat
;; (setq org-agenda-show-future-repeats 'next)

;; For org-super-agenda
(setq org-agenda-skip-scheduled-if-done t)
;; If something is both SCHEDULED and DONE, then don't display it.
;; This allows me to finish recurring scheduled tasks.

;; (setq org-agenda-prefix-format
;;  '((agenda . " %i %-12:c%?-12t% s")
;;   (todo . "%(org-entry-get nil \"CLOSED\") ")
;;   (tags . "%(org-entry-get nil \"CLOSED\") ")
;;   (search . " %i %-12:c")))

(defun org-agenda-next-line ()
  "Move cursor to the next line, and show if follow mode is active."
  (interactive)
  (call-interactively 'next-line)
  (org-agenda-do-context-action))

(defun org-agenda-previous-line ()
  "Move cursor to the previous line, and show if follow-mode is active."
  (interactive)
  (call-interactively 'previous-line)
  (org-agenda-do-context-action))

(defun org-agenda-scroll-down ()
  "Move cursor to the next line, and show if follow mode is active."
  (interactive)
  (call-interactively 'pen-scroll-down)
  (org-agenda-do-context-action))

(defun org-agenda-scroll-up ()
  "Move cursor to the previous line, and show if follow-mode is active."
  (interactive)
  (call-interactively 'pen-scroll-up)
  (org-agenda-do-context-action))

(define-key org-agenda-mode-map (kbd "C-n") 'org-agenda-scroll-down)
(define-key org-agenda-mode-map (kbd "C-p") 'org-agenda-scroll-up)

(define-key org-agenda-mode-map (kbd "<down>") 'org-agenda-next-line)
(define-key org-agenda-mode-map (kbd "<up>") 'org-agenda-previous-line)

(comment
 ;; basic
 (setq org-agenda-custom-commands
       '(("n" "Agenda and all TODOs"
          ((agenda "")
           (alltodo ""))))))

;; https://youtu.be/8BOiRmjw5aU?t=754
(setq org-agenda-custom-commands
      '(
        ;; ("wi" "Weekly review"
        ;;  tags "+CLOSED>\"<-7d>\"/DONE"
        ;;  ((org-agenda-files '("$HOME/Notebooks/org/work.org"))))

        ("v" "A better agenda view"
         ((agenda "" ((org-agenda-start-on-weekday nil)
                      (org-agenda-start-day "-1d")
                      ;; (org-agenda-start-day nil)
                      ;; (org-agenda-span 3)
                      (org-agenda-span 15)
                      ;; (org-deadline-warning-days 0)
                      ;; (org-agenda-block-separator nil)
                      (org-agenda-block-separator t)
                      (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                      (org-agenda-overriding-header "Remember to complete tasks at the opportune moment!\n\nNext 14 days:")))

          ;; (agenda "")

          ;; Global list of TODO items of type: ALL
          ;; (alltodo "")

          ;; The following taken from:
          ;; https://protesilaos.com/emacs/dotemacs
          ;; (tags-todo "*"
          ;;            (
          ;;             ;; (org-agenda-skip-function '(org-agenda-skip-if nil '(timestamp)))

          ;;             ;; (org-agenda-skip-function
          ;;             ;;  '(org-agenda-skip-if
          ;;             ;;    'deadline 'scheduled 'timestamp))

          ;;             (org-agenda-skip-function
          ;;              `(org-agenda-skip-entry-if
          ;;                'notregexp ,(format "\\[#%s\\]" (char-to-string org-priority-highest))))

          ;;             (org-agenda-block-separator nil)

          ;;             (org-agenda-overriding-header "Important tasks without a date\n")))

          ;; (agenda "" ((org-agenda-span 1)
          ;;             (org-deadline-warning-days 0)
          ;;             (org-agenda-block-separator nil)
          ;;             (org-scheduled-past-days 0)
          ;;             ;; We don't need the `org-agenda-date-today'
          ;;             ;; highlight because that only has a practical
          ;;             ;; utility in multi-day views.
          ;;             (org-agenda-day-face-function (lambda (date) 'org-agenda-date))
          ;;             (org-agenda-format-date "%A %-e %B %Y")
          ;;             (org-agenda-overriding-header "\nToday's agenda\n")))

          (agenda "" ((org-agenda-time-grid nil)
                      (org-agenda-start-on-weekday nil)
                      ;; We don't want to replicate the previous section's
                      ;; three days, so we start counting from the day after.
                      (org-agenda-start-day "+4d")
                      (org-agenda-span 14)
                      (org-agenda-show-all-dates nil)
                      (org-deadline-warning-days 0)
                      (org-agenda-block-separator nil)
                      (org-agenda-entry-types '(:deadline))
                      (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                      (org-agenda-overriding-header "\nUpcoming deadlines (+14d)\n")))

          ;; These bugged out when some items had priority

          ;; (tags "PRIORITY=\"A\""
          ;;       ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo ''done))
          ;;        (org-agenda-overriding-header "High-priority unfinished tasks:")))

          ;; (tags "PRIORITY=\"B\""
          ;;       ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
          ;;        (org-agenda-overriding-header "Medium-priority unfinished tasks:")))

          ;; (tags "PRIORITY=\"C\""
          ;;       ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
          ;;        (org-agenda-overriding-header "Low-priority unfinished tasks:")))
          ))))

(with-eval-after-load 'org-agenda
  (add-to-list 'org-agenda-custom-commands
               '("w" "Weekly review"
                 agenda ""
                 ((org-agenda-start-day "-14d")
                  (org-agenda-span 14)
                  (org-agenda-start-on-weekday 1)
                  ;; (org-agenda-start-with-log-mode '(closed))
                  ;; (org-agenda-skip-function
                  ;;  '(org-agenda-skip-entry-if 'notregexp "^\\*\\* DONE "))
                  ))))

(comment
 ;; https://protesilaos.com/emacs/dotemacs

 ;; This is the expanded view of my code (which is further below):
 (setq org-agenda-custom-commands
       `(("A" "Daily agenda and top priority tasks"
          ((tags-todo "*"
                      ((org-agenda-skip-function '(org-agenda-skip-if nil '(timestamp)))
                       (org-agenda-skip-function
                        `(org-agenda-skip-entry-if
                          'notregexp ,(format "\\[#%s\\]" (char-to-string org-priority-highest))))
                       (org-agenda-block-separator nil)
                       (org-agenda-overriding-header "Important tasks without a date\n")))
           (agenda "" ((org-agenda-span 1)
                       (org-deadline-warning-days 0)
                       (org-agenda-block-separator nil)
                       (org-scheduled-past-days 0)
                       ;; We don't need the `org-agenda-date-today'
                       ;; highlight because that only has a practical
                       ;; utility in multi-day views.
                       (org-agenda-day-face-function (lambda (date) 'org-agenda-date))
                       (org-agenda-format-date "%A %-e %B %Y")
                       (org-agenda-overriding-header "\nToday's agenda\n")))
           (agenda "" ((org-agenda-start-on-weekday nil)
                       (org-agenda-start-day "+1d")
                       (org-agenda-span 3)
                       (org-deadline-warning-days 0)
                       (org-agenda-block-separator nil)
                       (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                       (org-agenda-overriding-header "\nNext three days\n")))
           (agenda "" ((org-agenda-time-grid nil)
                       (org-agenda-start-on-weekday nil)
                       ;; We don't want to replicate the previous section's
                       ;; three days, so we start counting from the day after.
                       (org-agenda-start-day "+4d")
                       (org-agenda-span 14)
                       (org-agenda-show-all-dates nil)
                       (org-deadline-warning-days 0)
                       (org-agenda-block-separator nil)
                       (org-agenda-entry-types '(:deadline))
                       (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                       (org-agenda-overriding-header "\nUpcoming deadlines (+14d)\n")))))
         ("P" "Plain text daily agenda and top priorities"
          ((tags-todo "*"
                      ((org-agenda-skip-function '(org-agenda-skip-if nil '(timestamp)))
                       (org-agenda-skip-function
                        `(org-agenda-skip-entry-if
                          'notregexp ,(format "\\[#%s\\]" (char-to-string org-priority-highest))))
                       (org-agenda-block-separator nil)
                       (org-agenda-overriding-header "Important tasks without a date\n")))
           (agenda "" ((org-agenda-span 1)
                       (org-deadline-warning-days 0)
                       (org-agenda-block-separator nil)
                       (org-scheduled-past-days 0)
                       ;; We don't need the `org-agenda-date-today'
                       ;; highlight because that only has a practical
                       ;; utility in multi-day views.
                       (org-agenda-day-face-function (lambda (date) 'org-agenda-date))
                       (org-agenda-format-date "%A %-e %B %Y")
                       (org-agenda-overriding-header "\nToday's agenda\n")))
           (agenda "" ((org-agenda-start-on-weekday nil)
                       (org-agenda-start-day "+1d")
                       (org-agenda-span 3)
                       (org-deadline-warning-days 0)
                       (org-agenda-block-separator nil)
                       (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                       (org-agenda-overriding-header "\nNext three days\n")))
           (agenda "" ((org-agenda-time-grid nil)
                       (org-agenda-start-on-weekday nil)
                       ;; We don't want to replicate the previous section's
                       ;; three days, so we start counting from the day after.
                       (org-agenda-start-day "+4d")
                       (org-agenda-span 14)
                       (org-agenda-show-all-dates nil)
                       (org-deadline-warning-days 0)
                       (org-agenda-block-separator nil)
                       (org-agenda-entry-types '(:deadline))
                       (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                       (org-agenda-overriding-header "\nUpcoming deadlines (+14d)\n"))))
          ((org-agenda-with-colors nil)
           (org-agenda-prefix-format "%t %s")
           (org-agenda-current-time-string ,(car (last org-agenda-time-grid)))
           (org-agenda-fontify-priorities nil)
           (org-agenda-remove-tags t))
          ("agenda.txt"))))



 ;; And this is what I actually use.  The `defvar' is stored in my
 ;; prot-org.el file.  In the video I explain why I use this style.

 (defvar prot-org-custom-daily-agenda
   ;; NOTE 2021-12-08: Specifying a match like the following does not
   ;; work.
   ;;
   ;; tags-todo "+PRIORITY=\"A\""
   ;;
   ;; So we match everything and then skip entries with
   ;; `org-agenda-skip-function'.
   `((tags-todo "*"
                ((org-agenda-skip-function '(org-agenda-skip-if nil '(timestamp)))
                 (org-agenda-skip-function
                  `(org-agenda-skip-entry-if
                    'notregexp ,(format "\\[#%s\\]" (char-to-string org-priority-highest))))
                 (org-agenda-block-separator nil)
                 (org-agenda-overriding-header "Important tasks without a date\n")))
     (agenda "" ((org-agenda-span 1)
                 (org-deadline-warning-days 0)
                 (org-agenda-block-separator nil)
                 (org-scheduled-past-days 0)
                 ;; We don't need the `org-agenda-date-today'
                 ;; highlight because that only has a practical
                 ;; utility in multi-day views.
                 (org-agenda-day-face-function (lambda (date) 'org-agenda-date))
                 (org-agenda-format-date "%A %-e %B %Y")
                 (org-agenda-overriding-header "\nToday's agenda\n")))
     (agenda "" ((org-agenda-start-on-weekday nil)
                 (org-agenda-start-day "+1d")
                 (org-agenda-span 3)
                 (org-deadline-warning-days 0)
                 (org-agenda-block-separator nil)
                 (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "\nNext three days\n")))
     (agenda "" ((org-agenda-time-grid nil)
                 (org-agenda-start-on-weekday nil)
                 ;; We don't want to replicate the previous section's
                 ;; three days, so we start counting from the day after.
                 (org-agenda-start-day "+4d")
                 (org-agenda-span 14)
                 (org-agenda-show-all-dates nil)
                 (org-deadline-warning-days 0)
                 (org-agenda-block-separator nil)
                 (org-agenda-entry-types '(:deadline))
                 (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "\nUpcoming deadlines (+14d)\n"))))
   "Custom agenda for use in `org-agenda-custom-commands'.")

 (setq org-agenda-custom-commands
       `(("A" "Daily agenda and top priority tasks"
          ,prot-org-custom-daily-agenda)
         ("P" "Plain text daily agenda and top priorities"
          ,prot-org-custom-daily-agenda
          ((org-agenda-with-colors nil)
           (org-agenda-prefix-format "%t %s")
           (org-agenda-current-time-string ,(car (last org-agenda-time-grid)))
           (org-agenda-fontify-priorities nil)
           (org-agenda-remove-tags t))
          ("agenda.txt")))))


;; work with org-agenda dispatcher [c] "Today Clocked Tasks" to view today's clocked tasks.
(defun org-agenda-log-mode-colorize-block ()
  "Set different line spacing based on clock time duration."
  (save-excursion
    (let* ((colors (cl-case (alist-get 'background-mode (frame-parameters))
                     ('light
                      (list "#F6B1C3" "#FFFF9D" "#BEEB9F" "#ADD5F7"))
                     ('dark
                      (list "#aa557f" "DarkGreen" "DarkSlateGray" "DarkSlateBlue"))))
           pos
           duration)
      (nconc colors colors)
      (goto-char (point-min))
      (while (setq pos (next-single-property-change (point) 'duration))
        (goto-char pos)
        (when (and (not (equal pos (point-at-eol)))
                   (setq duration (org-get-at-bol 'duration)))
          ;; larger duration bar height
          (let ((get-current-line-string-height (if (< duration 15) 1.0 (+ 0.5 (/ duration 30))))
                (ov (make-overlay (point-at-bol) (1+ (point-at-eol)))))
            (overlay-put ov 'face `(:background ,(car colors) :foreground "black"))
            (setq colors (cdr colors))
            (overlay-put ov 'line-height line-height)
            (overlay-put ov 'line-spacing (1- line-height))))))))

(add-hook 'org-agenda-finalize-hook #'org-agenda-log-mode-colorize-block)

(defun agenda ()
  (interactive)
  (find-file (umn "$PEN/documents/agenda/agenda.org")))

(defun view-agenda ()
  (interactive)
  (org-agenda nil "v")
  (setq default-directory (umn "$PEN/documents/agenda")))


(defun org-agenda-list (&optional arg start-day span with-hour)
  "Produce a daily/weekly view from all files in variable `org-agenda-files'.
The view will be for the current day or week, but from the overview buffer
you will be able to go to other days/weeks.

With a numeric prefix argument in an interactive call, the agenda will
span ARG days.  Lisp programs should instead specify SPAN to change
the number of days.  SPAN defaults to `org-agenda-span'.

START-DAY defaults to TODAY, or to the most recent match for the weekday
given in `org-agenda-start-on-weekday'.

When WITH-HOUR is non-nil, only include scheduled and deadline
items if they have an hour specification like [h]h:mm."
  (interactive "P")
  (when org-agenda-overriding-arguments
    (setq arg (car org-agenda-overriding-arguments)
          start-day (nth 1 org-agenda-overriding-arguments)
          span (nth 2 org-agenda-overriding-arguments)))
  (when (and (integerp arg) (> arg 0))
    (setq span arg arg nil))
  (when (numberp span)
    (unless (< 0 span)
      (user-error "Agenda creation impossible for this span(=%d days)" span)))
  (catch 'exit
    (setq org-agenda-buffer-name
          (org-agenda--get-buffer-name
           (and org-agenda-sticky
                (cond ((and org-keys (stringp org-match))
                       (format "*Org Agenda(%s:%s)*" org-keys org-match))
                      (org-keys
                       (format "*Org Agenda(%s)*" org-keys))
                      (t "*Org Agenda(a)*")))))
    (org-agenda-prepare "Day/Week")
    (setq start-day (or start-day org-agenda-start-day))
    (when (stringp start-day)
      ;; Convert to an absolute day number
      (setq start-day (time-to-days (org-read-date nil t start-day))))
    (org-compile-prefix-format 'agenda)
    (org-set-sorting-strategy 'agenda)
    (let* ((span (org-agenda-ndays-to-span (or span org-agenda-span)))
           (today (org-today))
           (sd (or start-day today))
           (ndays (org-agenda-span-to-ndays span sd))
           (org-agenda-start-on-weekday
            (and (or (eq ndays 7) (eq ndays 14))
                 org-agenda-start-on-weekday))
           (thefiles (org-agenda-files nil 'ifmode))
           (files thefiles)
           (start (if (or (null org-agenda-start-on-weekday)
                          (< ndays 7))
                      sd
                    (let* ((nt (calendar-day-of-week
                                (calendar-gregorian-from-absolute sd)))
                           (n1 org-agenda-start-on-weekday)
                           (d (- nt n1)))
                      (- sd (+ (if (< d 0) 7 0) d)))))
           (day-numbers (list start))
           (day-cnt 0)
           ;; FIXME: This may cause confusion when users are trying to
           ;; debug agenda.  The debugger will not trigger without
           ;; redisplay.
           (inhibit-redisplay (not debug-on-error))
           (org-agenda-show-log-scoped org-agenda-show-log)
           s rtn rtnall file date d start-pos end-pos todayp ;; e
           clocktable-start clocktable-end)                  ;; filter
      (setq org-agenda-redo-command
            (list 'org-agenda-list (list 'quote arg) start-day (list 'quote span) with-hour))
      (dotimes (_ (1- ndays))
        (push (1+ (car day-numbers)) day-numbers))
      (setq day-numbers (nreverse day-numbers))
      (setq clocktable-start (car day-numbers)
            clocktable-end (1+ (or (org-last day-numbers) 0)))
      (setq-local org-starting-day (car day-numbers))
      (setq-local org-arg-loc arg)
      (setq-local org-agenda-current-span (org-agenda-ndays-to-span span))
      (unless org-agenda-compact-blocks
        (let* ((d1 (car day-numbers))
               (d2 (org-last day-numbers))
               (w1 (org-days-to-iso-week d1))
               (w2 (org-days-to-iso-week d2)))
          (setq s (point))
          (org-agenda--insert-overriding-header
            (concat (org-agenda-span-name span)
                    "-agenda"
                    (cond ((<= 350 (- d2 d1)) "")
                          ((= w1 w2) (format " (W%02d)" w1))
                          (t (format " (W%02d-W%02d)" w1 w2)))
                    ":\n")))
        ;; Add properties if we actually inserted a header.
        (when (> (point) s)
          (add-text-properties s (1- (point))
                               (list 'face 'org-agenda-structure
                                     'org-date-line t))
          (org-agenda-mark-header-line s)))
      (while (setq d (pop day-numbers))
        (setq date (calendar-gregorian-from-absolute d)
              s (point))
        (if (or (setq todayp (= d today))
                (and (not start-pos) (= d sd)))
            (setq start-pos (point))
          (when (and start-pos (not end-pos))
            (setq end-pos (point))))
        (setq files thefiles
              rtnall nil)
        (while (setq file (pop files))
          (catch 'nextfile
            (org-check-agenda-file file)
            (let ((org-agenda-entry-types org-agenda-entry-types))
              ;; Starred types override non-starred equivalents
              (when (member :deadline* org-agenda-entry-types)
                (setq org-agenda-entry-types
                      (delq :deadline org-agenda-entry-types)))
              (when (member :scheduled* org-agenda-entry-types)
                (setq org-agenda-entry-types
                      (delq :scheduled org-agenda-entry-types)))
              ;; Honor with-hour
              (when with-hour
                (when (member :deadline org-agenda-entry-types)
                  (setq org-agenda-entry-types
                        (delq :deadline org-agenda-entry-types))
                  (push :deadline* org-agenda-entry-types))
                (when (member :scheduled org-agenda-entry-types)
                  (setq org-agenda-entry-types
                        (delq :scheduled org-agenda-entry-types))
                  (push :scheduled* org-agenda-entry-types)))
              (unless org-agenda-include-deadlines
                (setq org-agenda-entry-types
                      (delq :deadline* (delq :deadline org-agenda-entry-types))))
              (cond
               ((memq org-agenda-show-log-scoped '(only clockcheck))
                (setq rtn (org-agenda-get-day-entries
                           file date :closed)))
               (org-agenda-show-log-scoped
                (setq rtn (apply #'org-agenda-get-day-entries
                                 file date
                                 (append '(:closed) org-agenda-entry-types))))
               (t
                (setq rtn (apply #'org-agenda-get-day-entries
                                 file date
                                 org-agenda-entry-types)))))
            (setq rtnall (append rtnall rtn)))) ;; all entries
        (when org-agenda-include-diary
          (let ((org-agenda-search-headline-for-time t))
            (require 'diary-lib)
            (setq rtn (org-get-entries-from-diary date))
            (setq rtnall (append rtnall rtn))))
        (when (or rtnall org-agenda-show-all-dates)
          (setq day-cnt (1+ day-cnt))
          (if (equal (calendar-current-date) date)
              (insert "TODAY:\n"))
          (insert
           (if (stringp org-agenda-format-date)
               (format-time-string org-agenda-format-date
                                   (org-time-from-absolute date))
             (funcall org-agenda-format-date date))

           "\n")
          (put-text-property s (1- (point)) 'face
                             (org-agenda-get-day-face date))
          (put-text-property s (1- (point)) 'org-date-line t)
          (put-text-property s (1- (point)) 'org-agenda-date-header t)
          (put-text-property s (1- (point)) 'org-day-cnt day-cnt)
          (when todayp
            (put-text-property s (1- (point)) 'org-today t))
          (setq rtnall
                (org-agenda-add-time-grid-maybe rtnall ndays todayp))
          (when rtnall (insert ;; all entries
                        (org-agenda-finalize-entries rtnall 'agenda)
                        "\n"))
          (put-text-property s (1- (point)) 'day d)
          (put-text-property s (1- (point)) 'org-day-cnt day-cnt)))
      (when (and org-agenda-clockreport-mode clocktable-start)
        (let ((org-agenda-files (org-agenda-files nil 'ifmode))
              ;; the above line is to ensure the restricted range!
              (p (copy-sequence org-agenda-clockreport-parameter-plist))
              tbl)
          (setq p (org-plist-delete p :block))
          (setq p (plist-put p :tstart clocktable-start))
          (setq p (plist-put p :tend clocktable-end))
          (setq p (plist-put p :scope 'agenda))
          (setq tbl (apply #'org-clock-get-clocktable p))
          (when org-agenda-clock-report-header
            (insert (propertize org-agenda-clock-report-header 'face 'org-agenda-structure))
            (unless (string-suffix-p "\n" org-agenda-clock-report-header)
              (insert "\n")))
          (insert tbl)))
      (goto-char (point-min))
      (or org-agenda-multi (org-agenda-fit-window-to-buffer))
      (unless (or (not (get-buffer-window org-agenda-buffer-name))
                  (and (pos-visible-in-window-p (point-min))
                       (pos-visible-in-window-p (point-max))))
        (goto-char (1- (point-max)))
        (recenter -1)
        (when (not (pos-visible-in-window-p (or start-pos 1)))
          (goto-char (or start-pos 1))
          (recenter 1)))
      (goto-char (or start-pos 1))
      (add-text-properties (point-min) (point-max)
                           `(org-agenda-type agenda
                                             org-last-args (,arg ,start-day ,span)
                                             org-redo-cmd ,org-agenda-redo-command
                                             org-series-cmd ,org-cmd))
      (when (eq org-agenda-show-log-scoped 'clockcheck)
        (org-agenda-show-clocking-issues))
      (org-agenda-finalize)
      (setq buffer-read-only t)
      (message ""))))

(defun org-super-agenda-run ()
  (interactive)
  (let ((org-super-agenda-groups
         '(;; Each group has an implicit boolean OR operator between its selectors.
           (:name "Today"         ; Optionally specify section name
                  :time-grid t    ; Items that appear on the time grid
                  :todo "TODAY")  ; Items that have this TODO keyword
           (:name "Important"
                  ;; Single arguments given alone
                  :tag "bills"
                  :priority "A")
           ;; Set order of multiple groups at once
           (:order-multi (2 (:name "Shopping in town"
                                   ;; Boolean AND group matches items that match all subgroups
                                   :and (:tag "shopping" :tag "@town"))
                            (:name "Food-related"
                                   ;; Multiple args given in list with implicit OR
                                   :tag ("food" "dinner"))
                            (:name "Personal"
                                   :habit t
                                   :tag "personal")
                            (:name "Space-related (non-moon-or-planet-related)"
                                   ;; Regexps match case-insensitively on the entire entry
                                   :and (:regexp ("space" "NASA")
                                                 ;; Boolean NOT also has implicit OR between selectors
                                                 :not (:regexp "moon" :tag "planet")))))
           ;; Groups supply their own section names when none are given
           (:todo "WAITING" :order 8)   ; Set order of this section
           (:todo ("SOMEDAY" "TO-READ" "CHECK" "TO-WATCH" "WATCHING")
                  ;; Show this group at the end of the agenda (since it has the
                  ;; highest number).  If you specified this group last, items
                  ;; with these todo keywords that e.g. have priority A would be
                  ;; displayed in that group instead, because items are grouped
                  ;; out in the order the groups are listed.
                  :order 9)
           (:priority<= "B"
                        ;; Show this section after "Today" and "Important", because
                        ;; their order is unspecified, defaulting to 0. Sections
                        ;; are displayed lowest-number-first.
                        :order 1)
           ;; After the last group, the agenda will display items that didn't
           ;; match any of these groups, with the default order position of 99
           )))
    (org-agenda nil "a")))

(setq org-alert-interval 300
      org-alert-notify-cutoff 10
      org-alert-notify-after-event-cutoff 10)

(define-key global-map (kbd "C-c A") 'agenda)
(define-key global-map (kbd "C-c v") 'org-agenda)
(define-key global-map (kbd "C-c a") 'view-agenda)
(define-key global-map (kbd "C-c s") 'org-super-agenda-run)


(defun agenda-fix-questionmarks ()
  (interactive)
  (view-agenda)
  (let ((cb (current-buffer)))
    (loop for fp in (org-agenda-files) do
          (progn (find-file fp)
                 (org-element-cache-reset)))
    (switch-to-buffer cb))
  (org-agenda-redo-all))

(defun org-agenda-list-tags ()
  (str2lines (snc "list-agenda-tags")))

(defun org-list-agenda-notmuch-searches ()
  (-uniq (str2lines (snc "list-agenda-notmuch-searches"))))

(defun notmuch-search-agenda ()
  (interactive)

  "Any notmuch search contained inside the agenda is listed here"

  (let ((query (fz (org-list-agenda-notmuch-searches)
                   nil nil "Agenda-related emails")))

    (notmuch-search query)))

;; Fix trailing whitespace on agenda items
;; Search for:
;; org-outline-regexp-bol
;; Make modification to several functions
;; Or just do the following:
(defun org-agenda-redo-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (region-erase-trailing-whitespace (point-min) (point-max))
    res))
(advice-add 'org-agenda-redo :around #'org-agenda-redo-around-advice)
;; (advice-remove 'org-agenda-redo #'org-agenda-redo-around-advice)

(advice-add 'org-agenda-finalize :around #'org-agenda-redo-around-advice)

;; org-agenda-refresh is my own command
(define-key org-agenda-mode-map (kbd "g") 'org-agenda-refresh)
(define-key org-agenda-mode-map (kbd "r") 'helm-org-ql-agenda-files)

(provide 'pen-org-agenda)
