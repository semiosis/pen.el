;;; helm-proc.el --- Helm interface for managing system processes

;; Copyright (C) 2014 Markus Hauck

;; Author: Markus Hauck <markus1189@gmail.com>
;; Maintainer: Markus Hauck <markus1189@gmail.com>
;; Keywords: helm
;; Version: 0.0.4
;; Package-requires: ((helm "1.6.0") (cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides a helm source `helm-source-proc' and a
;; configured helm `helm-proc'.  It is meant to be used to manage
;; emacs-external unix processes.
;;
;; With `helm-proc' a helm session is launched and you can perform
;; various helm actions on processes like sending signals, changing to
;; the corresponding /proc dir, attach strace...
;;
;; Example:
;;
;; Call `helm-proc' and:
;; type 'firefox'
;; => lists all processes named firefox or with firefox in args
;; press RET to send TERM signal
;;  or
;; press TAB for list of possible actions

;;; Code:
(require 'helm)
(require 'helm-utils)
(require 'helm-help)
(require 'proced)
(require 'cl-lib)
(require 'thingatpt)
(require 'gdb-mi)

(defgroup helm-proc nil
  "Manage system processes with helm."
  :group 'helm)

(defcustom helm-proc-polite-delay 10
  "Number of seconds to wait when politely killing a process."
  :type 'number
  :group 'helm-proc)

(defcustom helm-proc-retrieve-pid-function 'helm-proc-system-pgrep
  "Function to retrieve a list of pids matching a pattern given as argument."
  :group 'helm-proc
  :type '(choice
          (function-item :tag "pgrep" :value helm-proc-system-pgrep)
          (function :tag "Custom function")))

(defcustom helm-proc-strace-buffer-name "*helm-proc-strace*"
  "Used as the buffer name for the output of strace when used by helm-proc."
  :type 'string
  :group 'helm-proc)

(defcustom helm-proc-strace-process-name "helm-proc-strace"
  "Used as the name for the strace process started by helm-proc."
  :type 'string
  :group 'helm-proc)

(defcustom helm-proc-lsof-buffer-name "*helm-proc-lsof*"
  "Name of the buffer used for the output of lsof used by helm-proc."
  :type 'string
  :group 'helm-proc)

(defcustom helm-proc-lsof-process-name "helm-proc-lsof"
  "Process name when executing lsof from helm-proc."
  :type 'string
  :group 'helm-proc)

(defcustom helm-proc-strace-executable "strace"
  "Name of the strace executable."
  :type 'string
  :group 'helm-proc
  :type '(choice
          (string :tag "strace" :value "strace")
          (string :tag "ltrace" :value "ltrace")
          (string :tag "Custom executable")))

(defcustom helm-proc-strace-seconds 10
  "Number of seconds to collect strace data before process is killed."
  :type 'number
  :group 'helm-proc)

(defcustom helm-proc-formatting-function 'helm-proc-format-candidate-for-display
  "Function used to display candidates.

It takes one argument, the pid and returns (DISPLAY . pid) where
DISPLAY can be any string."
  :group 'helm-proc
  :type '(choice
          (function-item  :tag "builtin-multiline" :value helm-proc-format-candidate-for-display)
          (function :tag "Custom function")))

(defun helm-proc-candidates ()
  "Generate the candidate list for the current `helm-pattern'.
Then format elements for display in helm."
  (cl-loop for candidate in (helm-proc-search helm-pattern)
           when (assoc-default 'comm (cdar (proced-process-attributes `(,candidate))))
           collect (funcall helm-proc-formatting-function candidate)))

(defun helm-proc-system-pgrep (pattern)
  "Use external pgrep command to retrieve list of pids matching PATTERN."
  (let ((to-number (string-to-number pattern)))
    (append nil
     (if (not (equal 0 to-number)) `(,to-number) nil)
     (cl-loop for result in (split-string
                             (shell-command-to-string
                              (format "pgrep -f %s" pattern)) "\n")
              unless (string= "" result)
              collect (string-to-number result)))))

(defun helm-proc-search (pattern)
  "Call `helm-proc-retrieve-pid-function' with PATTERN.
Return a list of pids as result."
  (funcall helm-proc-retrieve-pid-function pattern))

(defun helm-proc--resident-set-size (pid)
  "Determine the resident set size of a process given by PID."
  (with-temp-buffer
         (insert-file-contents-literally (format "/proc/%s/status" pid))
         (goto-char (point-min))
         (search-forward "VmRSS:" nil t)
         (forward-word)
         (file-size-human-readable
          (* (string-to-number (word-at-point)) 1024)
          'iec)))

(defun helm-proc-format-candidate-for-display (pid)
  "Format PID for display in helm."
  (if (not pid) nil
    (let* ((attr-alist
            (cdar (proced-process-attributes `(,pid))))
           (command (assoc-default 'comm attr-alist))
           (args (assoc-default 'args attr-alist))
           (time (proced-format-time (assoc-default 'time attr-alist)))
           (state (assoc-default 'state attr-alist))
           (nice (assoc-default 'nice attr-alist))
           (user (assoc-default 'user attr-alist))
           (mem (helm-proc--resident-set-size pid))
           (display (format
                     "%s %s\nTime: %s | State: %s | Nice: %s | User: %s | Mem: %s\nArgs: %s"
                     pid
                     command
                     time
                     state
                     nice
                     user
                     mem
                     args)))
      (cons display pid))))

(defun helm-proc-action-copy-pid (pid)
  "Copy PID."
  (kill-new (format "%s" pid)))

(defun helm-proc-action-term (pid)
  "Send TERM to PID."
  (signal-process pid 'TERM))

(defun helm-proc-action-kill (pid)
  "Send KILL to PID."
  (signal-process pid 'KILL))

(defun helm-proc-action-stop (pid)
  "Send STOP to PID to stop the process."
  (signal-process pid 'STOP))

(defun helm-proc-action-continue (pid)
  "Send CONT to PID to continue the process if stopped."
  (signal-process pid 'CONT))

(defun helm-proc-process-alive-p (pid)
  "If process with PID is alive return t else nil."
  (file-readable-p (format "/proc/%s/" pid)))

(defun helm-proc-action-polite-kill (pid)
  "Send TERM to PID, wait for `helm-proc-polite-delay' seconds, then send KILL."
  (helm-proc-action-term pid)
  (run-with-timer helm-proc-polite-delay nil
                  (lambda (pid)
                    (unless (not (helm-proc-process-alive-p pid))
                      (helm-proc-action-kill pid)
                      (message (format "Sent KILL to %s" pid))
                      (if helm-alive-p (helm-update))))
                  pid))

(defun helm-proc-action-find-dir (pid)
  "Open the /proc dir for PID."
  (find-file (format "/proc/%s/" pid)))

(defun helm-proc-action-timed-strace (pid)
  "Attach strace to PID, collect output `helm-proc-strace-seconds'."
  (if (get-buffer helm-proc-strace-buffer-name)
      (kill-buffer helm-proc-strace-buffer-name))
  (and (start-process-shell-command
        helm-proc-strace-process-name
        helm-proc-strace-buffer-name
        (concat "echo " (shell-quote-argument (read-passwd "Sudo Password: "))
                (format " | sudo -S strace -p %s" pid)))
       (switch-to-buffer helm-proc-strace-buffer-name)
       (run-with-timer helm-proc-strace-seconds nil
                       (lambda ()
                         (kill-process
                          (get-process helm-proc-strace-process-name))))))

(defun helm-proc-action-lsof (pid)
  "List all files opened by process with PID."
  (if (get-buffer helm-proc-lsof-buffer-name)
      (kill-buffer helm-proc-lsof-buffer-name))
  (start-process-shell-command
   helm-proc-lsof-process-name
   helm-proc-lsof-buffer-name
   (format "lsof -p %s" pid))
  (switch-to-buffer helm-proc-lsof-buffer-name)
  (setq buffer-read-only t))

(defun helm-proc-action-gdb (pid)
  "Attach gdb to PID."
  (add-to-list
    'gud-gdb-history
    (format
     "gdb -i=mi %s %s"
     (file-truename
      (format "/proc/%s/exe" pid))
     pid))
  (call-interactively 'gdb))

(defun helm-proc-run-kill ()
  "Execute kill action from `helm-source-proc'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-proc-action-kill)))

(defun helm-proc-run-polite ()
  "Execute polite kill action from `helm-source-proc'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-proc-action-polite-kill)))

(defun helm-proc-run-stop ()
  "Execute stop action from `helm-source-proc'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-proc-action-stop)))

(defun helm-proc-run-continue ()
  "Execute continue action from `helm-source-proc'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-proc-action-continue)))

(defun helm-proc-run-term ()
  "Execute term action from `helm-source-proc'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-proc-action-term)))

(defun helm-proc-action-polite-kill-and-update (candidate)
  "Run `helm-proc-action-polite-kill' on CANDIDATE and call `helm-update'."
  (helm-proc-action-polite-kill candidate)
  (helm-update))

(defvar helm-proc-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "C-c t") 'helm-proc-run-term)
    (define-key map (kbd "C-c k") 'helm-proc-run-kill)
    (define-key map (kbd "C-c p") 'helm-proc-run-polite)
    (define-key map (kbd "C-c s") 'helm-proc-run-stop)
    (define-key map (kbd "C-c c") 'helm-proc-run-continue)
    (define-key map (kbd "C-c ?") 'helm-proc-help)
    map))

(defvar helm-proc-help-message
  "== Helm proc ==\
\nSpecific commands for Helm proc:
\\<helm-proc-map>\
\\[helm-proc-help]\t\tShow this help.
\\[helm-proc-run-term]\t\tSend the TERM signal.
\\[helm-proc-run-kill]\t\tSend the KILL signal.
\\[helm-proc-run-polite]\t\tSend TERM to PID, wait for `helm-proc-polite-delay' seconds, then send KILL.
\\[helm-proc-run-stop]\t\tSend the STOP signal.
\\[helm-proc-run-continue]\t\tSend the CONT signal.
\n== Helm Map ==
\\{helm-map}")

(defun helm-proc-help ()
  "Display help for `helm-proc'."
  (interactive)
  (let ((helm-help-message helm-proc-help-message))
    (helm-help)))

(defvar helm-proc-mode-line-string '("Ps" "\
\\<helm-proc-map>\
\\[helm-proc-help]:Help|\
\\[helm-proc-run-term]:TERM \
\\[helm-proc-run-polite]:Polite KILL|\
\\[helm-proc-run-kill]:KILL|\
\\[helm-proc-run-stop]:STOP|\
\\[helm-proc-run-continue]:CONT")
  "Help string displayed in mode-line in `helm-proc'.")

(defvar helm-source-proc
  `((name . "Processes")
    (volatile)
    (requires-pattern . 2)
    (multiline)
    (match . ((lambda (x) t)))
    (action . (("Send TERM (C-c t)" . helm-proc-action-term)
               ("Copy the pid" . helm-proc-action-copy-pid)
               ("Polite KILL (TERM -> KILL) (C-c p)" . helm-proc-action-polite-kill)
               ("Just KILL (C-c k)" . helm-proc-action-kill)
               ("Stop process (C-c s)" . helm-proc-action-stop)
               ("Continue if stopped (C-c c)" . helm-proc-action-continue)
               ("Open corresponding /proc dir" . helm-proc-action-find-dir)
               ("Call strace to attach with time limit" . helm-proc-action-timed-strace)
               ("List opened files (lsof)" . helm-proc-action-lsof)
               ("Attach gdb to process" . helm-proc-action-gdb)))
    (keymap . ,helm-proc-map)
    (persistent-action . helm-proc-action-polite-kill-and-update)
    (persistent-help . "Politely kill process")
    (candidates . helm-proc-candidates)
    (mode-line . helm-proc-mode-line-string)))

;;;###autoload
(defun helm-proc ()
  "Preconfigured helm for processes."
  (interactive)
  (helm :sources '(helm-source-proc)))

(provide 'helm-proc)
;;; helm-proc.el ends here
