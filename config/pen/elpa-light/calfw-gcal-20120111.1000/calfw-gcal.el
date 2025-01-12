;;; calfw-gcal.el --- edit Google calendar for calfw.el.

;; Filename: calfw-gcal.el
;; Description: some utilities for calfw.el.
;; Author: myuhe <yuhei.maeda_at_gmail.com>
;; Maintainer: myuhe
;; Copyright (C) :2010,2011,2012 myuhe , all rights reserved.
;; Created: :2011-01-16
;; Version: 0.0.3
;; Keywords: convenience, calendar, calfw.el
;; URL: https://github.com/myuhe/calfw-gcal.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 0:110-1301, USA.

;;; Commentary:
;;
;; It is necessary to calfw.el Configurations
;;
;; Installation:

;; ============================================= 

;; Put the calfw-gcal.el to your
;; load-path.

;; Add to .emacs:
;; (require 'calfw-gcal)
;;

;;; Changelog:

;; 2012-01-10 new command `cfw:gcal-gdata-add' add event via gdata-python-client.

(require 'calfw)

(defvar cfw:gcal-buffer-name "*cfw:gcal-edit*" "[internal]")
(defvar cfw:gcal-user nil)       
(defvar cfw:gcal-pass nil)       
(defvar cfw:gcal-py-dir nil)
(defvar cfw:gcal-py-alias "python")
(defvar cfw:gcal-skk-use nil)

(defsubst cfw:gcal-edit-mode-p ()
  "Check if the current buffer is in Org-mode."
  (eq major-mode 'cfw:gcal-edit-mode))

(define-derived-mode cfw:gcal-edit-mode text-mode "cfw:gcal-edit"
  (use-local-map cfw:gcal-edit-mode-map))

(define-key cfw:gcal-edit-mode-map (kbd "C-c C-c") 'cfw:gcal-add)
(define-key cfw:gcal-edit-mode-map (kbd "C-c C-d") 'cfw:gcal-delete)
(define-key cfw:gcal-edit-mode-map (kbd "C-c C-k") 'cfw:gcal-quit)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;internal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cfw:gcal-edit-extract-status ()
  (if (eq major-mode 'cfw:gcal-edit-mode)
      (buffer-substring-no-properties (point-min) (point-max))
    ""))

(defun cfw:gcal-format-status (status)
  (let ((desc  ( nth 0 (split-string status " ")))
        (start ( nth 1 (split-string status " ")))
        (end   ( nth 2 (split-string status " "))))
    (cond
     (end   (concat desc " " cfw:gcal-month "/" cfw:gcal-day " " start "-" end " JST"))
     (start (concat desc " " cfw:gcal-month "/" cfw:gcal-day " " start " JST"))
     (t     (concat desc " " cfw:gcal-month "/" cfw:gcal-day)))))

(defun cfw:gcal-quit ()
  "Kill buffer and delete window."
  (interactive)
  (let ((win-num (length (window-list)))
        (next-win (get-buffer-window cfw:main-buf)))
    (when (and (not (one-window-p))
               (> win-num cfw:before-win-num))
      (delete-window))
    (kill-buffer cfw:gcal-buffer-name)
    (when next-win (select-window next-win))))

(defun cfw:gcal-help ()
  (let* ((help-str (format (substitute-command-keys
                            "Keymap:
  \\[cfw:gcal-add]: Add a schedule to Google calendar
  \\[cfw:gcal-delete]: Delete a schedule from Google calendar
  \\[cfw:gcal-quit]: cancel
---- text above this line is ignored ----
")))
         (help-overlay
          (make-overlay 1 1 nil nil nil)))
    (add-text-properties 0 (length help-str) '(face font-lock-comment-face)
                         help-str)
    (overlay-put help-overlay 'before-string help-str)))

(defun cfw:gcal-popup (y m d)
  (let ((buf (get-buffer cfw:gcal-buffer-name))
        (before-win-num (length (window-list)))
        (main-buf (current-buffer)))
    (unless (and buf (eq (buffer-local-value 'major-mode buf)
                         'cfw:gcal-edit-mode))
      (setq buf (get-buffer-create cfw:gcal-buffer-name))
      (with-current-buffer buf
        (cfw:gcal-edit-mode)
        (set (make-local-variable 'cfw:before-win-num) before-win-num)))
    (with-current-buffer buf
      ;;(let (buffer-read-only)
      (set (make-local-variable 'cfw:main-buf) main-buf)
      (set (make-local-variable 'cfw:gcal-year) y)
      (set (make-local-variable 'cfw:gcal-month) m)
      (set (make-local-variable 'cfw:gcal-day) d)
      (cfw:gcal-help)
      (pop-to-buffer buf))
    (fit-window-to-buffer (get-buffer-window buf) cfw:details-window-size)))

(defun cfw:gcal-skk-read-from-minibuffer (PROMPT &optional INITIAL-CONTENTS KEYMAP READ
                                                 HIST DEFAULT-VALUE INHERIT-INPUT-METHOD)
  (when cfw:gcal-skk-use
    (skk-mode)
    (add-hook 'minibuffer-setup-hook 'skk-j-mode-on)
    (add-hook 'minibuffer-setup-hook 'skk-add-skk-pre-command))
  (read-from-minibuffer PROMPT INITIAL-CONTENTS KEYMAP READ
                        HIST DEFAULT-VALUE INHERIT-INPUT-METHOD))

(defun cfw:gcal-blank-check (str)
  (if (string= "" str)  "no_data" str))

(defun cfw:gcal-format-string (time day month year)
  (format-time-string
   "%Y-%m-%d-%H-%M"
   (seconds-to-time
    (- (float-time 
        (encode-time 
         00 
         (string-to-number 
          (substring time 2 4))
         (string-to-number 
          (substring time 0 2))
         day 
         month 
         year)) 
       (car (current-time-zone))))))

(defun cfw:gcal-format-ed (ed)
  (format-time-string
   "%Y-%m-%d"
   (seconds-to-time
    (+ (float-time 
        (encode-time
         00 00 00
         (string-to-number (caddr (split-string ed "-")))
         (string-to-number (cadr  (split-string ed "-")))
         (string-to-number (car   (split-string ed "-"))))) 
       86400))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;interactive
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cfw:gcal-main ()
  "Show details on the selected date."
  (interactive)
  (let* ((mdy (cfw:cursor-to-nearest-date))
         (y (number-to-string
             (calendar-extract-year mdy)))
         (m (number-to-string
             (calendar-extract-month mdy)))
         (d (number-to-string
             (calendar-extract-day mdy))))
    (when mdy
      (cfw:gcal-popup y m d))))

(defun cfw:gcal-add ()
  (interactive)
  (let ((date (concat cfw:gcal-month "/" cfw:gcal-day))
        (status (cfw:gcal-edit-extract-status)))
    (start-process "cfw-gcal-send" nil "google" "calendar" "add" (cfw:gcal-format-status status))
    (cfw:gcal-quit)))

(defun cfw:gcal-delete ()
  (interactive)
  (let ((date (concat cfw:gcal-year "-" cfw:gcal-month "-" cfw:gcal-day))
        (status (cfw:gcal-edit-extract-status)))
    (start-process "cfw:gcal-send" nil "google" "calendar" "delete" status "--date" date )
    (cfw:gcal-quit)))

(defun cfw:gcal-gdata-add  (&optional multiple where desc)
  (interactive)
  (let* ((mdy   (cfw:cursor-to-nearest-date))
         (year  (calendar-extract-year  mdy))
         (month (calendar-extract-month mdy))
         (day   (calendar-extract-day   mdy))
         (title (cfw:gcal-blank-check
                 (cfw:gcal-skk-read-from-minibuffer "Event : ")))
         (wh (if where "no_data" (cfw:gcal-blank-check
                                  (cfw:gcal-skk-read-from-minibuffer "Where : "))))
         (de (if desc "no_data"  (cfw:gcal-blank-check
                                  (cfw:gcal-skk-read-from-minibuffer "Description : "))))
         (ad "Y")
         (sd  (setq sd (concat (number-to-string year) "-" 
                               (format "%02d" month) "-"
                               (format "%02d" day))))
         (ed sd)
         (st (format-time-string "%Y-%m-%d-%H-%M" (current-time)))
         (et (format-time-string "%Y-%m-%d-%H-%M" (current-time))))

    (when (equal cfw:gcal-user nil)
      (setq cfw:gcal-user 
            (read-from-minibuffer "Type Google Account : " )))
    (when (equal cfw:gcal-pass nil)
      (setq cfw:gcal-pass 
            (read-passwd (concat "Type the password for the Google Account "
                                 cfw:gcal-user))))
    (if (y-or-n-p "All day event ?: ")
        ;; All day
        (if multiple
            (setq ed (cfw:gcal-format-ed
                      (read-from-minibuffer "End day? : " sd)))
          (setq ed (cfw:gcal-format-ed sd)))
      ;; separated by time
      (progn
        (setq st (cfw:gcal-format-string
                  (read-from-minibuffer "Start [HHMM] : ") day month year))
        (setq ad "N")
        (if multiple
            (progn
              (setq et (read-from-minibuffer "End day? : " sd))
              (setq et (cfw:gcal-format-string 
                        (read-from-minibuffer "End [HHMM] : ") 
                        (string-to-number (caddr (split-string et "-")))
                        (string-to-number (cadr  (split-string et "-")))
                        (string-to-number (car   (split-string et "-"))))))
          (progn
            (setq et (cfw:gcal-format-string
                      (read-from-minibuffer "End [HHMM] : ") day month year))))))
    (message "Sending Google Calendar...")
    (set-process-sentinel
     (start-process 
      "cfw-gcal-send" nil cfw:gcal-py-alias
      (concat (expand-file-name cfw:gcal-py-dir) "/insertEvent.py")
      "--user" cfw:gcal-user
      "--pw" cfw:gcal-pass
      "--t" title 
      "--c" de	
      "--w" wh
      "--ad" ad 
      "--sd" sd 
      "--ed" ed 
      "--st" st 
      "--et" et)
     (lambda (process event)
       (message "Send Google Calendar successfully!!")))))

(defun cfw:gcal-gdata-add-simple ()
  (interactive)
  (cfw:gcal-gdata-add nil t t))

(defun cfw:gcal-gdata-add-multiple ()
  (interactive)
  (cfw:gcal-gdata-add t nil nil))

(provide 'calfw-gcal)

;;; calfw-gcal.el ends here
