;;; alarm-clock.el --- Alarm Clock                   -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Steve Lemuel

;; Author: Steve Lemuel <wlemuel@hotmail.com>
;; Keywords: calendar, tools, convenience
;; Version: 2019.02.12
;; Package-Version: 20190212.1
;; Package-Requires: ((emacs "24.4") (f "0.17.0"))
;; URL: https://github.com/wlemuel/alarm-clock

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This program is an alarm management tool for Emacs.
;; To set an alarm clock, call `M-x alarm-clock-set', then enter time as
;; the following tips.
;; To view alarm clock list, call `M-x alarm-clock-list-view', then use
;; 'a' key to set a new alarm clock,
;; 'C-k' to kill an alarm clock in the current line.

;;; Code:

(require 'parse-time)
(require 'f)

(defgroup alarm-clock nil
  "An alarm clock management."
  :group 'applications
  :prefix "alarm-clock-")

(defcustom alarm-clock-sound-file
  (f-join (f-dirname (f-this-file)) "alarm.mp3")
  "File to play the alarm sound."
  :type 'file
  :group 'alarm-clock)

(defcustom alarm-clock-play-sound t
  "Whether to play sound when notifying, only avaiable for osx and linux."
  :type 'boolean
  :group 'alarm-clock)

(defcustom alarm-clock-system-notify t
  "Whether to notify via system based notification feature."
  :type 'boolean
  :group 'alarm-clock)

(defcustom alarm-clock-snooze-enable nil
  "Whether enable snooze feature."
  :type 'boolean
  :group 'alarm-clock)

(defcustom alarm-clock-snooze-default-duration 300
  "Default duration (5 minutes = 300 seconds) for snooze feature."
  :type 'number
  :group 'alarm-clock)

(defcustom alarm-clock-cache-file
  (expand-file-name ".alarm-clock.cache" user-emacs-directory)
  "The name of alarm-clock's cache file."
  :type 'string
  :group 'alarm-clock)

(defvar alarm-clock--alist nil
  "List of information about alarm clock.")

(defvar alarm-clock--macos-sender nil
  "Notification sender for MacOS.")

(define-derived-mode alarm-clock-mode special-mode "Alarm Clock"
  "Mode for listing alarm-clocks.

\\{alarm-clock-mode-map}"
  (buffer-disable-undo)
  (setq truncate-lines t)

  (define-key alarm-clock-mode-map [(control k)] 'alarm-clock-kill)
  (define-key alarm-clock-mode-map "a" 'alarm-clock-set))

;;;###autoload
(defun alarm-clock-set (time message)
  "Set an alarm clock at time TIME.
MESSAGE will be shown when notifying in the status bar."
  (interactive "sAlarm at (e.g: 2 minutes, 60 seconds, 3 days): \nsMessage: ")
  (let* ((time (if (stringp time) (string-trim time) time))
         (message (string-trim message))
         (timer (run-at-time
                 time
                 nil
                 (lambda (message) (alarm-clock--notify "Alarm Clock" message))
                 message)))
    (push (list :time (timer--time timer)
                :message message
                :timer timer)
          alarm-clock--alist))
  (alarm-clock--list-prepare))

;;;###autoload
(defun alarm-clock-list-view ()
  "Display the alarm clocks."
  (interactive)
  (unless alarm-clock--alist
    (user-error "No alarm clocks are set"))
  (alarm-clock--list-prepare)
  (pop-to-buffer "*alarm clock*"))

(defun alarm-clock--list-prepare ()
  "Prefare the list buffer."
  (alarm-clock--cleanup)
  (when alarm-clock--alist
    (set-buffer (get-buffer-create "*alarm clock*"))
    (alarm-clock-mode)
    (let* ((format (format "%%-%ds %%s" 25))
           (inhibit-read-only t)
           start time)
      (erase-buffer)
      (setq header-line-format (format format "Time" "Message"))
      (dolist (alarm alarm-clock--alist)
        (setq start (point)
              time (format-time-string "%F %X" (plist-get alarm :time)))
        (insert (format format time (plist-get alarm :message)) "\n")
        (put-text-property start (1+ start) 'alarm-clock alarm))
      (goto-char (point-min)))))

(defun alarm-clock-kill ()
  "Kill the current alarm clock."
  (interactive)
  (let* ((start (line-beginning-position))
         (alarm (get-text-property start 'alarm-clock))
         (inhibit-read-only t))
    (unless alarm
      (user-error "No alarm clock on the current line"))
    (forward-line 1)
    (delete-region start (point))
    (cancel-timer (plist-get alarm :timer))
    (setq alarm-clock--alist (delq alarm alarm-clock--alist))))

(defun alarm-clock--cleanup ()
  "Remove expired records."
  (dolist (alarm alarm-clock--alist)
    (when (time-less-p (plist-get alarm :time) (current-time))
      (setq alarm-clock--alist (delq alarm alarm-clock--alist)))))

(defun alarm-clock--ding ()
  "Play ding.
In osx operating system, 'afplay' will be used to play sound,
and 'mpg123' in linux"
  (let ((title "Alarm Clock")
        (program (cond ((eq system-type 'darwin) "afplay")
                       ((eq system-type 'gnu/linux) "mpg123")
                       (t "")))
        (sound (expand-file-name alarm-clock-sound-file)))
    (when (and (executable-find program)
               (file-exists-p sound))
      (start-process title nil program sound))))

(defun alarm-clock--system-notify (title message)
  "Notify with formatted TITLE and MESSAGE by the system notification feature."
  (let ((program (cond ((eq system-type 'darwin) "terminal-notifier")
                       ((eq system-type 'gnu/linux) "notify-send")
                       (t "")))
        (args (cond ((eq system-type 'darwin) `("-title" ,title
                                                ,@(alarm-clock--get-macos-sender)
                                                "-message" ,message
                                                "-ignoreDnD"))
                    ((eq system-type 'gnu/linux) (list "-u" "critical" title message)))))
    (when (executable-find program)
      (apply 'start-process (append (list title nil program) args)))))

(defun alarm-clock--notify (title message)
  "Notify in status bar with formatted TITLE and MESSAGE."
  (when alarm-clock-play-sound
    (alarm-clock--ding))
  (when alarm-clock-system-notify
    (alarm-clock--system-notify title message))
  (message (format "[%s] - %s" title message)))

;;;###autoload
(defun alarm-clock-restore ()
  "Restore alarm clocks on startup."
  (interactive)
  (alarm-clock--kill-all)
  (let* ((file alarm-clock-cache-file)
        (alarm-clocks (unless (zerop (or (nth 7 (file-attributes file)) 0))
                        (with-temp-buffer
                          (insert-file-contents file)
                          (read (current-buffer))))))
    (when alarm-clocks
      (dolist (alarm alarm-clocks)
        (alarm-clock-set (parse-iso8601-time-string (plist-get alarm :time))
                         (plist-get alarm :message))))))

;;;###autoload
(defun alarm-clock-save ()
  "Save alarm clocks to local file."
  (interactive)
  (let ((alarm-clocks))
    (dolist (alarm alarm-clock--alist)
      (unless (time-less-p (plist-get alarm :time) (current-time))
        (push (list :time (format-time-string "%FT%T%z" (plist-get alarm :time))
                    :message (plist-get alarm :message))
              alarm-clocks)))
    (with-temp-file alarm-clock-cache-file
      (insert ";; Auto-generated file; don't edit\n")
      (pp alarm-clocks (current-buffer)))))

(defun alarm-clock--kill-all ()
  "Kill all timers."
  (dolist (alarm alarm-clock--alist)
    (cancel-timer (plist-get alarm :timer))
    (setq alarm-clock--alist (delq alarm alarm-clock--alist))))

(defun alarm-clock--turn-autosave-on ()
  "Turn `alarm-clock-save' on."
  (alarm-clock-restore)
  (add-hook 'kill-emacs-hook #'alarm-clock-save))

(defun alarm-clock--turn-autosave-off ()
  "Turn `alarm-clock-save' off."
  (remove-hook 'kill-emacs-hook #'alarm-clock-save))

(defun alarm-clock--get-macos-sender ()
  "Get proper sender for notifying in MacOS"
  (when (not alarm-clock--macos-sender)
    (let* ((versions (split-string
                      (shell-command-to-string "sw_vers -productVersion")
                      "\\." t))
           (major-version (string-to-number (first versions)))
           (minor-version (string-to-number (second versions))))
      (unless (and (>= major-version 10)
                   (>= minor-version 15))
        (setq alarm-clock--macos-sender '("-sender" "org.gnu.Emacs")))))
  alarm-clock--macos-sender)

(provide 'alarm-clock)
;;; alarm-clock.el ends here
