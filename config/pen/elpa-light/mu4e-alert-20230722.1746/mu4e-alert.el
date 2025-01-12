;;; mu4e-alert.el --- Desktop notification for mu4e  -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2017  Iqbal Ansari
;; Copyright (C) 2021-2022  Mikhail Rudenko

;; Author: Iqbal Ansari <iqbalansari02@yahoo.com>
;; Maintainer: Mikhail Rudenko <mike.rudenko@gmail.com>
;; URL: https://github.com/iqbalansari/mu4e-alert
;; Keywords: mail, convenience
;; Version: 1.0
;; Package-Requires: ((alert "1.2") (s "1.10.0") (ht "2.0") (emacs "24.4"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.



;;; Commentary:

;; This package provides desktop notifications for mu4e, additionally it can
;; display the number of unread emails in the modeline



;;; Code:

(require 'mu4e)
(require 'alert)
(require 's)
(require 'ht)

(require 'timer)
(require 'time)
(require 'advice)
(require 'pcase)
(require 'cl-lib)

;; Customizations

(defgroup mu4e-alert nil
  "Customization options for mu4e-alert."
  :group 'mail
  :prefix "mu4e-alert-")

(defcustom mu4e-alert-interesting-mail-query
  "flag:unread AND NOT flag:trashed"
  "The query to get count of unread (read interesting) emails.
By default only unread emails are considered interesting, it should
be string to be sent to the mu's find command."
  :type 'string
  :group 'mu4e-alert)

(defcustom mu4e-alert-modeline-formatter
  #'mu4e-alert-default-mode-line-formatter
  "The function used to get the string to be displayed in the mode-line.
It should be a function that accepts a single argument the current count of
unread emails and should return the string to be displayed in the mode-line."
  :type 'function
  :group 'mu4e-alert)

(defcustom mu4e-alert-email-count-notification-formatter
  #'mu4e-alert-default-email-count-notification-formatter
  "The function used to get the message for the desktop notification.
It should be a function that accepts a single argument the current count of
unread emails and should return the string to be used for the notification."
  :type 'function
  :group 'mu4e-alert)

(defcustom mu4e-alert-max-messages-to-process 500
  "Limit searching and processing given number of messages."
  :type 'integer
  :group 'mu4e-alert)

(defcustom mu4e-alert-email-count-title "mu4e"
  "The title to use for desktop notifications."
  :type 'string
  :group 'mu4e-alert)

(defcustom mu4e-alert-group-by :from
  "Field to group messages to be displayed in notifications by.

This should be one of :from, :to, :maildir, :priority and :flags or a function.
If set to a function, the function should accept a single argument the list of
messages and return a list of list of messages, where each individual list of
messages should grouped together in one notification."
  :type '(radio :tag "Field to group messages to be displayed in notifications"
                (const :tag "Sender" :from)
                (const :tag "Recipient" :to)
                (const :tag "Maildir" :maildir)
                (const :tag "Priority" :priority)
                (const :tag "Flags" :flags))
  :group 'mu4e-alert)

(defcustom mu4e-alert-mail-grouper
  #'mu4e-alert-default-mails-grouper
  "The function used to get arrange similar mails in to a group.

It should accept a list of mails and return a list of lists, where each list is
a group of messages that user should be notified about in one notification."
  :type 'function)

(defcustom mu4e-alert-grouped-mail-sorter
  #'mu4e-alert-default-grouped-mail-sorter
  "The function used to sort the emails after grouping them."
  :type 'function)

(defcustom mu4e-alert-grouped-mail-notification-formatter
  #'mu4e-alert-default-grouped-mail-notification-formatter
  "The function used to get the notification for a group of mails.

The function is used get the notification to be displayed for a group of emails.
It should return a plist with keys :title and :body with the value of title and
body for the notification respectively."
  :type 'function)

(defcustom mu4e-alert-email-notification-types '(count subjects)
  "The types of notifications to be displayed for emails.

It is a list of types of notifications to be issues for emails.  The list can
have following elements
count    - Notify the total email count to the user
subjects - Notify with some content of the email, by default the emails are
           grouped by the sender.  And one notification is issued per sender
           with the subject of the emails is displayed in the notification."
  :type 'symbol)

(defcustom mu4e-alert-set-window-urgency t
  "Set window urgency on recieving unread emails.

If non-nil `mu4e-alert' will set the WM_URGENT on detecting unread messages."
  :type 'boolean)

(defcustom mu4e-alert-notify-repeated-mails nil
  "Notify about interesting mails that were notified about earlier.

By default `mu4e-alert' does not notify about mails it has notified about
earlier.  For example, suppose you get two unread emails you read one and leave
the other unread, next time the when mu4e-alert checks for unread emails, it
will filter out the second message and show notifications only for mails that
have arrived after the first check.  Set this option to a non-nil value if you
wish to be notified of all emails at each check irrespective of whether you have
been notified of the an email earlier or no."
  :type 'boolean)

(defcustom mu4e-alert-icon nil
  "Full path to icon to show in notification.

Note that not all 'alert' notification backends support this."
  :type 'string
  :group 'mu4e-alert)

;;;###autoload
(defun mu4e-alert-set-default-style (value)
  "Set the default style for unread email notifications.

VALUE is the value to be used as the default style."
  (let ((notification-style (if (consp value)
                                (eval value)
                              value)))
    (unless (assoc value alert-styles)
      (user-error "[mu4e-alert] Do not know how to use `%s' style, please one of %s"
                  value
                  (mapcar #'car alert-styles)))
    (alert-add-rule :category "mu4e-alert" :style notification-style)
    (setq-default mu4e-alert-style notification-style)))

(defcustom mu4e-alert-style alert-default-style
  "The default style to use for notifying the user about unread emails.

This should be one of `alert-styles'.  Setting this directly from Lisp will not
work, to customize this value from Lisp use the function
`mu4e-alert-set-default-style', if you want more fine grained customizations you
can use alert's API and add rules for the category \"mu4e-alert\"

See also https://github.com/jwiegley/alert."
  :type (alert-styles-radio-type 'radio)
  :set (lambda (_ value) (mu4e-alert-set-default-style value))
  :group 'mu4e-alert)

;; deal with mu4e versions above 1.7
;; need to know whether on mu4e 1.7.x because its API changed.
(defconst mu4e-alert--mu-is-17
  (version-list-<= '(1 7) (version-to-list mu4e-mu-version))
  "Non-nil if we are using mu 1.7.4 or newer.")

;; declare functions to keep byte-compiler quiet
(declare-function mu4e-running-p "mu4e-server" nil t)
(declare-function mu4e~proc-running-p "mu4e" nil t)
(declare-function mu4e--server-find "mu4e-server" nil t)
(declare-function mu4e~proc-find "mu4e" nil t)
(declare-function mu4e--init-handlers "mu4e" nil t)
(declare-function mu4e-search "mu4e-search" nil t)

;; supress byte-compiler warning in mu4e v1.7
(eval-when-compile
  (cl-remprop 'mu4e-headers-search 'byte-obsolete-info))

;; make sure mu4e handlers are initialized in v1.7
(when mu4e-alert--mu-is-17
  (mu4e--init-handlers))

;; create aliases for mu4e functions and variables
(defvaralias 'mu4e-alert-mu4e-header-func-var
  (if mu4e-alert--mu-is-17 'mu4e-headers-append-func 'mu4e-header-func)
  "mu4e variable storing function to process emails in header view.")

(defvaralias 'mu4e-alert--mu4e-context-current
  (if mu4e-alert--mu-is-17 'mu4e--context-current 'mu4e~context-current)
  "mu4e variables to store the current context.")

(defalias 'mu4e-alert--mu4e-search
  (if mu4e-alert--mu-is-17 #'mu4e-search #'mu4e-headers-search)
  "mu4e function to search for mail.")

(defalias 'mu4e-alert--mu4e-proc-running-p-func
  (if mu4e-alert--mu-is-17 #'mu4e-running-p #'mu4e~proc-running-p)
  "Function that checks whether mu4e process is running.")

(defalias 'mu4e-alert--mu4e-proc-find-func
  (if mu4e-alert--mu-is-17 #'mu4e--server-find #'mu4e~proc-find)
  "Function that searches for mail using mu4e.")

;; Core functions

(defvar mu4e-alert-log-buffer " *mu4e-alert-logs*"
  "Buffer where mu4e-alert's internal logs are stored.")

(defun mu4e-alert--sanity-check ()
  "Sanity check run before attempting to fetch unread emails."
  (unless (and (bound-and-true-p mu4e-mu-binary)
               (stringp mu4e-mu-binary)
               (file-executable-p mu4e-mu-binary))
    (user-error "Please set `mu4e-mu-binary' to the full path to the mu binary, before attempting to enable `mu4e-alert'")))

(defvar mu4e-alert--header-func-save mu4e-alert-mu4e-header-func-var
  "Saved :header handler from mu4e.")

(defvar mu4e-alert--found-func-save mu4e-found-func
  "Saved :found handler from mu4e.")

(defvar mu4e-alert--erase-func-save mu4e-erase-func
  "Saved :erase handler from mu4e.")

(defvar mu4e-alert--messages
  "List of messages received by :header callback.")

(defvar mu4e-alert--finding-p nil
  "Whether `find' request is in progress.")

(defun mu4e-alert--erase-func ()
  "Erase handler for mu process.")

(defun mu4e-alert--found-func (_found)
  "Found handler for mu process."
  (mu4e-alert--find-end)
  (mu4e-alert--email-processor mu4e-alert--messages)
  (setq mu4e-alert-mu4e-header-func-var mu4e-alert--header-func-save
        mu4e-found-func mu4e-alert--found-func-save
        mu4e-erase-func mu4e-alert--erase-func-save))

(defun mu4e-alert--header-func (msg)
  "Message header handler for mu process.
MSG argument is message plist."
  (if mu4e-alert--mu-is-17
      (setq mu4e-alert--messages msg)
    (push msg mu4e-alert--messages)))

(defvar mu4e-alert--fetch-timer nil
  "The scheduled fetching of mails from mu.")

(defun mu4e-alert--get-mu-unread-emails-1 ()
  "Get messages from mu and invoke scheduled callbacks."
  (when (mu4e-alert--mu4e-proc-running-p-func)
    (if mu4e-alert--finding-p
        (setq mu4e-alert--fetch-timer
              (run-at-time 1.0
                           nil
                           #'mu4e-alert--get-mu-unread-emails-1))
      (setq mu4e-alert-mu4e-header-func-var #'mu4e-alert--header-func
            mu4e-found-func #'mu4e-alert--found-func
            mu4e-erase-func #'mu4e-alert--erase-func)
      (setq mu4e-alert--messages nil)
      (mu4e-alert--mu4e-proc-find-func mu4e-alert-interesting-mail-query
                      nil
                      :date
                      'descending
                      mu4e-alert-max-messages-to-process
                      nil
                      nil))))

(defvar mu4e-alert--callback-queue nil
  "Callbacks queued for running after fetching mails from mu.")

(defun mu4e-alert--email-processor (mails)
  "Process the MAILS fetched from mu.

This simply runs queued callbacks one by one, any errors occurring while running
are logged in the `mu4e-alert-log-buffer'"
  (let ((callback-queue mu4e-alert--callback-queue))
    (setq mu4e-alert--callback-queue nil)
    (dolist (callback callback-queue)
      (condition-case err
          (funcall callback mails)
        (error (with-current-buffer (get-buffer-create mu4e-alert-log-buffer)
                 (insert "Failed to execute a queued callback because: %s"
                         (error-message-string err))))))))

(defun mu4e-alert--get-mu-unread-mails (callback)
  "Get the count of interesting emails asynchronously.
CALLBACK is called with one argument the interesting emails."
  (mu4e-alert--sanity-check)
  (when (and (timerp mu4e-alert--fetch-timer)
             (not (timer--triggered mu4e-alert--fetch-timer)))
    (cancel-timer mu4e-alert--fetch-timer))
  (push callback mu4e-alert--callback-queue)
  (setq mu4e-alert--fetch-timer
        (run-at-time 0.5 nil
                     #'mu4e-alert--get-mu-unread-emails-1)))



;; Mode-line indicator for unread emails

(defvar mu4e-alert-mode-line "" "The mode-line indicator to display the count of unread emails.")

(defun mu4e-alert-default-mode-line-formatter (mail-count)
  "Default formatter used to get the string to be displayed in the mode-line.
MAIL-COUNT is the count of mails for which the string is to displayed."
  (when (not (zerop mail-count))
    (concat " "
            (propertize
             "Mail"
             'display (when (display-graphic-p)
                        display-time-mail-icon)
             'face display-time-mail-face
             'help-echo (concat (if (= mail-count 1)
                                    "You have an unread email"
                                  (format "You have %s unread emails" mail-count))
                                "\nClick here to view "
                                (if (= mail-count 1) "it" "them"))
             'mouse-face 'mode-line-highlight
             'keymap '(mode-line keymap
                                 (mouse-1 . mu4e-alert-view-unread-mails)
                                 (mouse-2 . mu4e-alert-view-unread-mails)
                                 (mouse-3 . mu4e-alert-view-unread-mails)))
            (if (zerop mail-count)
                " "
              (format " [%d] " mail-count)))))

(defun mu4e-alert-view-unread-mails ()
  "View unread mails.
This is primarily used to enable viewing unread emails by default mode-line
formatter when user clicks on mode-line indicator."
  (interactive)
  (mu4e-alert--mu4e-search mu4e-alert-interesting-mail-query))

(defun mu4e-alert-update-mail-count-modeline ()
  "Send a desktop notification about currently unread email."
  (mu4e-alert--get-mu-unread-mails (lambda (mails)
                                     (setq mu4e-alert-mode-line (funcall mu4e-alert-modeline-formatter
                                                                         (length mails)))
                                     (force-mode-line-update))))


;; Desktop notifications for unread emails

;;;; Setting urgency hint for Emacs frames
(defun mu4e-alert--set-x-urgency-hint (frame arg)
  "Set window urgency hint for given FRAME.

ARG should be non-nil to set the flag or nil to clear the flag.

Taken from: http://www.emacswiki.org/emacs/JabberEl#toc17"
  (let* ((wm-hints (append (x-window-property "WM_HINTS" frame "WM_HINTS" nil nil t) nil))
         (flags (car wm-hints)))
    (setcar wm-hints
            (if arg
                (logior flags #x00000100)
              (logand flags #x1ffffeff)))
    (x-change-window-property "WM_HINTS" wm-hints frame "WM_HINTS" 32 t)))

(defvar mu4e-alert-urgent-window-flag "mu4e-alert-urgent")

(defun mu4e-alert-set-x-urgency-hint (frame)
  "Set urgency hint for given FRAME.

It also marks the frame, so that we can clear it later."
  (mu4e-alert--set-x-urgency-hint frame t)
  ;; Remember that we have set an urgency hint on this frame
  (x-change-window-property mu4e-alert-urgent-window-flag "true" frame))

(defun mu4e-alert-clear-urgency-hints ()
  "Clear urgency hint for all frames.

This only removes the hints added by `mu4e-alert'"
  (dolist (frame (frame-list))
    (when (and (frame-live-p frame)
               ;; Wrapped in ignore-errors to prevent errors for
               ;; frames that do not support x-window-property
               (ignore-errors (x-window-property mu4e-alert-urgent-window-flag
                                                 frame)))
      (mu4e-alert--set-x-urgency-hint frame nil)
      (x-delete-window-property mu4e-alert-urgent-window-flag frame))))

(defun mu4e-alert--get-mu4e-frame ()
  "Try getting a frame containing a mu4e buffer."
  (car (delq nil (mapcar (lambda (buffer)
                           (when (and buffer
                                      (get-buffer-window buffer t))
                             (window-frame (get-buffer-window buffer t))))
                         (list mu4e-main-buffer-name)))))

(defun mu4e-alert--setup-clear-urgency ()
  "Setup hooks to clear the urgency hooks."
  ;; if focus-in-hook (pre Emacs 24.4) is not defined hook into
  ;; post-command-hook instead
  (add-hook (if (boundp 'focus-in-hook) 'focus-in-hook 'post-command-hook)
            #'mu4e-alert-clear-urgency-hints))

(defun mu4e-alert-set-window-urgency-maybe ()
  "Set urgency hint to current frame."
  (when (and mu4e-alert-set-window-urgency
             (display-graphic-p)
             (memql system-type '(gnu gnu/linux)))
    (let ((frame (or (mu4e-alert--get-mu4e-frame)
                     (selected-frame))))
      ;; Do not set urgency hint if the frame is visible
      (mu4e-alert-set-x-urgency-hint frame)
      (mu4e-alert--setup-clear-urgency))))

(defvar mu4e-alert-repeated-mails (ht-create #'equal))

(defun mu4e-alert-filter-repeated-mails (mails)
  "Filters the MAILS that have been seen already."
  (cl-remove-if (lambda (mail)
                  (prog1 (and (not mu4e-alert-notify-repeated-mails)
                              (ht-get mu4e-alert-repeated-mails
                                      (plist-get mail :message-id)))
                    (ht-set! mu4e-alert-repeated-mails
                             (plist-get mail :message-id)
                             t)))
                mails))

(defun mu4e-alert--message-address (mail key)
  "Get a string representing address specified by KEY in MAIL."
  (let ((addr (car (plist-get mail key))))
    (or
     (plist-get addr :name)
     (plist-get addr :email)
     (car addr)
     (cdr addr))))

(defun mu4e-alert--get-group (mail)
  "Get the group the given MAIL should be put in.

This is an internal function used by `mu4e-alert-default-mails-grouper'."
  (pcase mu4e-alert-group-by
    (`:from (mu4e-alert--message-address mail :from))
    (`:to (mu4e-alert--message-address mail :to))
    (`:maildir (plist-get mail :maildir))
    (`:priority (symbol-value (plist-get mail :maildir)))
    (`:flags (s-join ", " (mapcar #'symbol-value
                                  (plist-get mail :flags))))))

(defun mu4e-alert-default-email-count-notification-formatter (mail-count)
  "Default formatter for unread email count.
MAIL-COUNT is the count of mails for which the string is to displayed."
  (when (not (zerop mail-count))
    (if (= mail-count 1)
        "You have an unread email"
      (format "You have %s unread emails" mail-count))))

(defun mu4e-alert-default-grouped-mail-sorter (group1 group2)
  "The default function to sort the groups for notification.

GROUP1 and GROUP2 are the group of mails to be sorted.  This function groups
by the date of first mail of group."
  (not (time-less-p (plist-get (car group1) :date)
                    (plist-get (car group2) :date))))

(defun mu4e-alert-default-mails-grouper (mails)
  "Default function to group MAILS for notification."
  (let ((mail-hash (ht-create #'equal)))
    (dolist (mail mails)
      (let ((mail-group (mu4e-alert--get-group mail)))
        (puthash mail-group
                 (cons mail (gethash mail-group mail-hash))
                 mail-hash)))
    (ht-values mail-hash)))

(defun mu4e-alert-default-grouped-mail-notification-formatter (mail-group all-mails)
  "Default function to format MAIL-GROUP for notification.

ALL-MAILS are the all the unread emails"
  (let* ((mail-count (length mail-group))
         (total-mails (length all-mails))
         (first-mail (car mail-group))
         (title-prefix (format "You have [%d/%d] unread email%s"
                               mail-count
                               total-mails
                               (if (> mail-count 1) "s" "")))
         (field-value (mu4e-alert--get-group first-mail))
         (title-suffix (format (pcase mu4e-alert-group-by
                                 (`:from "from %s:")
                                 (`:to "to %s:")
                                 (`:maildir "in %s:")
                                 (`:priority "with %s priority:")
                                 (`:flags "with %s flags:"))
                               field-value))
         (title (format "%s %s\n" title-prefix title-suffix)))
    (list :title title
          :body (concat "• "
                        (s-join "\n• "
                                (mapcar (lambda (mail)
                                          (plist-get mail :subject))
                                        mail-group))))))

(defun mu4e-alert-notify-unread-messages (mails)
  "Display desktop notification for given MAILS."
  (let* ((mail-groups (funcall mu4e-alert-mail-grouper
                               mails))
         (sorted-mail-groups (sort mail-groups
                                   mu4e-alert-grouped-mail-sorter))
         (notifications (mapcar (lambda (group)
                                  (funcall mu4e-alert-grouped-mail-notification-formatter
                                           group
                                           mails))
                                sorted-mail-groups)))
    (dolist (notification (cl-subseq notifications 0 (min 5 (length notifications))))
      (alert (plist-get notification :body)
             :title (plist-get notification :title)
             :category "mu4e-alert"
             :icon mu4e-alert-icon))
    (when notifications
      (mu4e-alert-set-window-urgency-maybe))))

(defun mu4e-alert-notify-unread-messages-count (mail-count)
  "Display desktop notification for given MAIL-COUNT."
  (when (not (zerop mail-count))
    (alert (funcall mu4e-alert-email-count-notification-formatter
                    mail-count)
           :title mu4e-alert-email-count-title
           :category "mu4e-alert"
           :icon mu4e-alert-icon)))

(defun mu4e-alert-notify-unread-mail-async ()
  "Send a desktop notification about currently unread email."
  (mu4e-alert--get-mu-unread-mails (lambda (mails)
                                     (let ((new-mails (mu4e-alert-filter-repeated-mails mails)))
                                       (when (memql 'count mu4e-alert-email-notification-types)
                                         (mu4e-alert-notify-unread-messages-count (length new-mails)))
                                       (when (memql 'subjects mu4e-alert-email-notification-types)
                                         (mu4e-alert-notify-unread-messages new-mails))))))



;; Tying all the above together

(defun mu4e-alert--context-switch (orig &rest args)
  "Advice to update mode-line after changing the context.
ORIG is the original function to be called with ARGS."
  (let ((context mu4e-alert--mu4e-context-current))
    (apply orig args)
    (unless (equal context mu4e-alert--mu4e-context-current)
      (mu4e-alert-update-mail-count-modeline))))

(defun mu4e-alert--find-start (&rest _)
  "Advice to track `find' request start."
  (setq mu4e-alert--finding-p t))

(defun mu4e-alert--find-end (&rest _)
  "Advice to track `find' request start."
  (setq mu4e-alert--finding-p nil))

(advice-add (symbol-function #'mu4e-alert--mu4e-proc-find-func) :before #'mu4e-alert--find-start)
(advice-add mu4e-alert--found-func-save :before #'mu4e-alert--find-end)

;;;###autoload
(defun mu4e-alert-enable-mode-line-display ()
  "Enable display of unread emails in mode-line."
  (interactive)
  (add-to-list 'global-mode-string '(:eval mu4e-alert-mode-line) t)
  (add-hook 'mu4e-index-updated-hook #'mu4e-alert-update-mail-count-modeline)
  (add-hook 'mu4e-message-changed-hook #'mu4e-alert-update-mail-count-modeline)
  (advice-add #'mu4e-context-switch :around #'mu4e-alert--context-switch)
  (mu4e-alert-update-mail-count-modeline))

(defun mu4e-alert-disable-mode-line-display ()
  "Disable display of unread emails in mode-line."
  (interactive)
  (setq global-mode-string (delete '(:eval mu4e-alert-mode-line) global-mode-string))
  (remove-hook 'mu4e-index-updated-hook #'mu4e-alert-update-mail-count-modeline)
  (remove-hook 'mu4e-message-changed-hook #'mu4e-alert-update-mail-count-modeline)
  (advice-remove #'mu4e-context-switch #'mu4e-alert--context-switch))

;;;###autoload
(defun mu4e-alert-enable-notifications ()
  "Enable desktop notifications for unread emails."
  (interactive)
  (add-hook 'mu4e-index-updated-hook #'mu4e-alert-notify-unread-mail-async)
  (mu4e-alert-notify-unread-mail-async))

(defun mu4e-alert-disable-notifications ()
  "Disable desktop notifications for unread emails."
  (interactive)
  (remove-hook 'mu4e-index-updated-hook #'mu4e-alert-notify-unread-mail-async))

(provide 'mu4e-alert)
;;; mu4e-alert.el ends here
