;;; helm-chronos.el --- helm interface for chronos timers

;; Copyright (C) 2015 David Knight

;; Author: David Knight <dxknight@opmbx.org>
;; Created: 20 May 2015
;; Package-Version: 1.1
;; Package-Requires: ((chronos "1.2") (helm "1.7.1"))
;; Version: 1.1
;; Keywords: calendar
;; URL: http://github.com/dxknight/helm-chronos

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; A helm interface to chronos.
;;
;; `helm-chronos-add-timer' is a replacement for `chronos-add-timer' that offers
;; two sources for predefined timers, or allows the entry of a new timer.
;;
;; The format for predefined and entered timers is:
;;
;; <expiry time specification>/<message>
;;
;; See the chronos documentation for details of the expiry time specification,
;;
;; Helm gets possible matches from two sources:
;;
;; * Standard timers
;;
;; There is a predefined list helm-chronos-standard-timers, empty by default,
;; which can be set in your init file like:
;;
;; (setq helm-chronos-standard-timers
;;       '( "     4/Tea"
;;          "=16:20/Time for tea"))
;;
;; In this example, two timers are offered as standard: one to go off in 4
;; minutes from when it is set, and another that will expire at 4:20pm today.
;;
;; * Recent timers
;;
;; As new timers are entered via helm-chronos, they are added to the recent
;; timers list in the same format as the standard timers.  This list is
;; persistent by being saved to helm-chronos-recent-timers-file.
;;
;; Installation
;;
;; Put this file somewhere Emacs can find it and (require 'helm-chronos)
;;
;; For more information, see the info manual or website.

;;; Code:

(require 'chronos)
(require 'helm)

(defgroup helm-chronos nil
  "Helm-chronos' customization group."
  :group 'chronos)

(defcustom helm-chronos-standard-timers nil
  "A list of 'expiry time/message' strings."
  :type  '(repeat string)
  :group 'helm-chronos)

(defcustom helm-chronos-recent-timers-file
  (expand-file-name ".helm-chronos-recent-timers" user-emacs-directory)
  "The file to save the recent non standard timers.  Nil means do
  not save when session closes."
  :type  '(choice (const :tag "No save" nil)
                  (file :tag "Save file"))
  :group 'helm-chronos)

(defcustom helm-chronos-recent-timers-limit nil
  "How many non standard timers to save at most.  Nil means no
  preset limit."
  :type  '(choice (const :tag "No limit" nil)
                  (integer :tag "limit"))
  :group 'helm-chronos)

(defvar helm-chronos--recent-timers nil
  "A list of expiry time/message strings entered by the user.")

(defvar helm-chronos--recent-timers-read-p nil
  "True if the recent timers file has been read in.")

(defvar helm-chronos--standard-timers-source
  '((name . "Standard timers")
    (candidates . helm-chronos-standard-timers)
    (action . (("Add timer" . helm-chronos--parse-string-and-add-timer))))
  "Helm source to select from standard timers list.")

(defvar helm-chronos--recent-timers-source
  '((name . "Recent timers")
    (candidates . helm-chronos--recent-timers)
    (action . (("Add timer" . helm-chronos--parse-string-and-add-timer))))
  "Helm source to select from recent non-standard timers list.")

(defvar helm-chronos--fallback-source
  '((name . "Enter <expiry time spec>/<message>")
    (dummy)
    (action . (("Add timer" . helm-chronos--parse-string-and-add-timer)))))

;;;###autoload
(defun helm-chronos-add-timer ()
  (interactive)
  (unless helm-chronos--recent-timers-read-p
    (setq helm-chronos--recent-timers (helm-chronos--read-recent-timers)
          helm-chronos--recent-timers-read-p t)
    (add-hook 'kill-emacs-hook 'helm-chronos--save-recent-timers))
  (helm :sources '(helm-chronos--standard-timers-source
                   helm-chronos--recent-timers-source
                   helm-chronos--fallback-source)))

(defun helm-chronos--normalize-timers-string (timers)
  "Normalize string representation of the list of timers TIMERS."
  (let* ((ns (mapconcat #'(lambda (ts)
                            (format "%s/%s"
                                    (car ts)
                                    (cadr ts)))
                        timers
                        " + "))
         (sep-pos  (string-match "/" ns))
         (spaces   (if (and (numberp sep-pos)
                            (< sep-pos 6))
                       (make-string (- 6 sep-pos) ?\s)
                     "")))
    (concat spaces ns)))

(defun helm-chronos--parse-string-and-add-timer (timers-string)
  "Parse string TIMERS-STRING which may contain multiple `+' separated
cumulative timer specifications in the format <expiry spec> /
<message>.

The resulting timer specifications are added with
`chronos--make-and-add-timer'."
  (interactive "p")
  (let ((timers-string-normalized
         (helm-chronos--normalize-timers-string
          (chronos-add-timers-from-string timers-string
                                          helm-current-prefix-arg))))
    (unless (member timers-string-normalized
                    helm-chronos-standard-timers)
      (add-to-list 'helm-chronos--recent-timers
                   timers-string-normalized))))

(defun helm-chronos--read-recent-timers ()
  "Read helm-chronos--recent-timers from the file
  helm-chronos-recent-timers-file.  Return nil if unreadable."
  (if (file-readable-p helm-chronos-recent-timers-file)
      (split-string (with-temp-buffer
                      (insert-file-contents helm-chronos-recent-timers-file)
                      (buffer-substring-no-properties (point-min) (point-max)))
                    "\n"
                    t)
    (message "Cannot read recent timers from %s"
             helm-chronos-recent-timers-file)
    nil))

(defun helm-chronos--save-recent-timers ()
  "Save at most helm-chronos-recent-timers-limit
  timers from helm-chronos--recent-timers."
  (if (file-writable-p helm-chronos-recent-timers-file)
      (with-temp-file helm-chronos-recent-timers-file
        (let ((max-items (or helm-chronos-recent-timers-limit most-positive-fixnum))
              (item-list helm-chronos--recent-timers))
          (while (and item-list
                      (> max-items 0))
            (insert (pop item-list))
            (newline)
            (setq max-items (1- max-items)))))
    (message "Cannot write recent timers to %s"
             helm-chronos-recent-timers-file)))

(provide 'helm-chronos)

;;; helm-chronos.el ends here
