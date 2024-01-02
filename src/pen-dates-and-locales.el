(defun get-current-timezone ()
  ;; I think NZDT is an incorrect timezone specification
  ;; It should be NZ or Pacific/Auckland
  ;; This should be NZDT
  ;; But it's currently NZ
  ;; Therefore, I need to fix this
  (sor (getenv "TZ")
       "Pacific/Auckland"))

(defun get-current-locale ()
  ;; This should be en_NZ, but en_US is OK
  ;; (snc "locale")
  (sor (getenv "LANG")
       "en_NZ"))



;; e:/usr/share/i18n/locales/en_NZ
;; e:/usr/share/zoneinfo
;; I need to get the date format from the timezone
;; So I need to get the locale from the timezone
;; j:get-locale-date-format
(defun get-locale-default-date-format (&optional locale)
  (setq locale (or locale (get-current-locale)))
  (if (not (re-match-p "_" locale))
      (setq locale (concat "en_" locale)))
  (let* ((locales-dir "/usr/share/i18n/locales")
         (locales-fn (e/head-n (e/grep (e/ls locales-dir) locale) 1)))
    (if (test-n locales-fn)
        (let* ((locales-fn-fc (cat (f-join locales-dir locales-fn)))
               (d_t_fmt
                (--> (e/grep locales-fn-fc "d_t_fmt")
                     (s-replace-regexp "^[^\"]+\"" "" it)
                     (s-replace-regexp "\"$" "" it))))
          d_t_fmt))))

(memoize 'get-locale-default-date-format)

;; Sat 30 Dec 2023 10:37:15 AM NZDT
;; 
;; (sh/date "%D %-I:%M %p")
;; 12/30/23 10:37 AM
;;
;; locale != timezone
;;  en_NZ != NZDT
;; TODO Fix this.
;; TODO get locale from timezone
;; Well, actually, both are separate things and should be treated so.
;; TODO Fix this.
;; (sh/date nil "Pacific/Auckland")
;; (sh/date nil nil "tomorrow")
(defun sh/date (&optional format tz date)
  (setq tz (or tz "NZ"))
  ;; I need to supply the correct locale
  (setq format (or format (get-locale-default-date-format tz)))
  ;; (setq format (or format "%a %b %e %H:%M:%S %Z %Y"))
  (pen-cl-sn (cmd "date"
                  (if date "-d")
                  (if date date)
                  (if format (concat "+" format)))
             :chomp t
             :env-var-tups (list (list "TZ" tz))))

;; (sh-construct-envs '(("UPDATE" "y")))

;; "%D %-I:%M %p"
;; 
;; (e/date "%D %-I:%M %p")
;; 12/30/23 10:37 AM
;; (e/date nil nil "+1d")
(defun e/date (&optional format tz date no-now)
  (setq tz (or tz "NZ"))
  ;; TODO Get the default format from here
  ;; /usr/share/i18n/locales/en_NZ
  (setq format (or format (get-locale-default-date-format tz)))
  (setq format (or format "%a %b %e %H:%M:%S %Z %Y"))
  (setq format (or format "%D %-I:%M %p"))
  (let* ((ts nil)
         ;; Default time is either the timestamp at point or today.
         ;; When entering a range, only the range start is considered.
         (default-time (and ts (org-time-string-to-time ts)))
         (default-input (and ts (org-get-compact-tod ts)))
         (repeater (and ts
                        (string-match "\\([.+-]+[0-9]+[hdwmy] ?\\)+" ts)
                        (match-string 0 ts))))
    ;; date-to-time
    ;; org-read-date
    (setq date (cond (no-now
                      (date-to-time (org-read-date nil nil date)))
                     (date
                      (org-read-date
                       t 'totime
                       date nil nil nil
                       no-now)))))
  (format-time-string format date tz
                      ;; This will show NZDT, but NZDT isn't
                      ;; what the linux `date` command expects.
                      ;; So is the emacs function wrong?
                      ;; Perhaps it should show Pacific/Auckland,
                      ;; or NZ instead of NZDT.
                      ;; (current-time-zone)
                      ))

(defun insert-org-date (&optional with-time)
  (interactive)
  (setq with-time
        (or with-time
            (>= (prefix-numeric-value current-prefix-arg) 4)))
  (insert
   (if with-time
       (concat "<" (e/date "%F %a %T") ">")
     (concat "<" (e/date "%F %a") ">"))))

;; DONE Make sh/date = e/date, and let it be the default
;; format for the date command (i.e. TZ=Pacific/Auckland /bin/date  =>  Sat 30 Dec 2023 02:15:17 PM NZDT).

(comment
 (etv
  (list2str
   (list
    (e/date nil "NZ")
    (sh/date nil "NZ")))))

(defalias 'date 'e/date)

(defun date-short ()
  (interactive)
  ;; (sh/date)
  (sh/date "%d.%m.%y"))

(provide 'pen-dates-and-locales)
