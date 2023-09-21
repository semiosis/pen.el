(require 'alarm-clock)

(defcustom alarm-hour ""
  "Hour of alarm clock"
  :type 'string
  :group 'alarmclock
  :options (mapcar 'str (seq 1 12))
  :set (lambda (_sym value)
         (set _sym value))
  :get (lambda (_sym)
         (eval (sor _sym nil)))
  :initialize #'custom-initialize-default)

(defcustom alarm-min ""
  "Minutes of alarm clock"
  :type 'string
  :group 'alarmclock
  :options (mapcar 'str (list 0 15 30 45))
  :set (lambda (_sym value)
         (set _sym value))
  :get (lambda (_sym)
         (eval (sor _sym nil)))
  :initialize #'custom-initialize-default)

(defcustom alarm-ampm ""
  "AM/PM of alarm clock"
  :type 'string
  :group 'alarmclock
  :options (mapcar 'str (list "am" "pm"))
  :set (lambda (_sym value)
         (set _sym value))
  :get (lambda (_sym)
         (eval (sor _sym nil)))
  :initialize #'custom-initialize-default)

;; alarmbell
;; #!/bin/bash
;; sps vlc -l "$@"

(defun alarm-clock--ding ()
  (interactive)
  "Play ding.
In osx operating system, 'afplay' will be used to play sound,
and 'mpg123' in linux"
  (let ((title "Alarm Clock")
        (program (cond ((eq system-type 'darwin) "afplay")
                       ;; ((eq system-type 'gnu/linux) "mplayer")
                       ((eq system-type 'gnu/linux) "tm-alarmbell")
                       (t "")))
        (sound (expand-file-name alarm-clock-sound-file)))
    (when (and (executable-find program)
               (file-exists-p sound))
      (start-process title nil program sound))))

(defun time-preceeding-zero (c)
  (if (eq 1 (length c))
      (concat "0" c)
    c))

;; timezone must be correctly set
(setenv "TZ" "UTC+12")

(defun pen-alarm-set (hour min ampm)
  (interactive (list (completing-read "hour: " (mapcar 'str (seq 1 12))
                                      nil nil alarm-hour)
                     (completing-read "min: " (mapcar 'str (list 0 15 30 45))
                                      nil nil alarm-min)
                     (completing-read "am/pm: " (list "am" "pm")
                                      nil nil alarm-ampm)))
  (alarm-clock-set (concat hour ":" (time-preceeding-zero min) ampm) "Wake up!"))

(defun pen-test-alarm-clock ()
  (interactive)
  ;; (alarm-clock-set "08:23am" "Wake up!")
  (alarm-clock-set "02:17am" "Wake up!")
  ;; (alarm-clock-set "11:23pm" "Wake up!")
  )

(defun pen-show-alarm-clock-list ()
  (interactive)
  (call-interactively 'alarm-clock-list-view))

(defalias 'pen-test-alarm-bell 'alarm-clock--ding)

(provide 'pen-alarm)
