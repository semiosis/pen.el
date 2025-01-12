;;; flymake-hledger.el --- Flymake module to check hledger journals  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Url: https://github.com/DamienCassou/flymake-hledger
;; Package-requires: ((emacs "28.2"))
;; Version: 0.1.0

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

;; This package adds an hledger [1] checker to Flymake.
;;
;; [1] https://hledger.org/

;;; Code:
(require 'flymake)

(defgroup flymake-hledger nil
  "Flymake module to check hledger journals."
  :group 'flymake)

(defcustom flymake-hledger-command '("hledger")
  "List of a program and its arguments to start hledger."
  :type '(repeat string))

(defcustom flymake-hledger-checks '("accounts" "commodities" "balancednoautoconversion")
  "List of tests to run on the journal.
See URL `https://hledger.org/1.30/hledger.html#check' for the meaning of each check."
  :type '(set
          (const "accounts")
          (const "commodities")
          (const "balancednoautoconversion")
          (const "ordereddates")
          (const "payees")
          (const "recentassertions")
          (const "tags")
          (const "uniqueleafnames")))

(defvar-local flymake-hledger--process nil
  "The process executing hledger for the current buffer.")

;;;###autoload
(defun flymake-hledger-enable ()
  "Enable checking the hledger journal in the current buffer."
  (interactive)
  (flymake-mode t)
  (add-hook 'flymake-diagnostic-functions #'flymake-hledger-check-buffer nil t))

(defun flymake-hledger-disable ()
  "Stop checking the hledger journal in the current buffer."
  (interactive)
  (flymake-mode -1)
  (remove-hook 'flymake-diagnostic-functions #'flymake-hledger-check-buffer t))

;;;###autoload
(defun flymake-hledger-check-buffer (report-fn &rest _)
  "Start a hledger process on the current buffer and report to Flymake.
This function is meant to be added to `flymake-diagnostic-functions'.

REPORT-FN is Flymake's callback."
  (unless (flymake-hledger--should-enable-p)
    (user-error "The flymake-hledger backend is not meant for this buffer"))
  (when (process-live-p flymake-hledger--process)
    (kill-process flymake-hledger--process))
  (flymake-hledger--start-hledger-process report-fn))

(defun flymake-hledger--should-enable-p ()
  "Return non-nil if flymake-hledger should be enabled in the current buffer."
  (or
   ;; Either the user is using `hledger-mode':
   (derived-mode-p 'hledger-mode)
   ;; or the user is using `ledger-mode' with the binary path pointing
   ;; to "hledger":
   (and (bound-and-true-p ledger-binary-path)
        (string-suffix-p "hledger" ledger-binary-path))))

(defun flymake-hledger--start-hledger-process (report-fn)
  "Start hledger and report problems through REPORT-FN.

REPORT-FN is Flymake's callback."
  (let ((error-buffer (generate-new-buffer "*flymake-hledger*"))
        (source-buffer (current-buffer)))
    (setq flymake-hledger--process
          (make-process
           :name "flymake-hledger"
           :buffer error-buffer
           :command `(,@flymake-hledger-command "-f" "-" "check" ,@flymake-hledger-checks)
           :noquery t
           :connection-type 'pipe
           :sentinel (apply-partially #'flymake-hledger--sentinel source-buffer report-fn)))
    (save-restriction
      (widen)
      (process-send-region flymake-hledger--process (point-min) (point-max)))
    (process-send-eof flymake-hledger--process)))

(defun flymake-hledger--sentinel (source-buffer report-fn process _)
  "Parse output of the hledger process if finished.

SOURCE-BUFFER is the buffer containing the hledger journal to check.
REPORT-FN is Flymake's callback.  PROCESS is the system process running
hledger."
  (unwind-protect
      (when (and (buffer-live-p source-buffer) (eq 'exit (process-status process)))
        (flymake-hledger--handle-process-exit source-buffer report-fn process))
    (unless (process-live-p process)
      (kill-buffer (process-buffer process)))))

(defun flymake-hledger--handle-process-exit (source-buffer report-fn process)
  "Parse output of hledger in the PROCESS' buffer and report diagnostics.

SOURCE-BUFFER is the buffer containing the hledger journal to check.
REPORT-FN is Flymake's callback.  PROCESS is the system process running
hledger."
  (when (with-current-buffer source-buffer (eq process flymake-hledger--process))
    (with-current-buffer (process-buffer process)
      (let ((diags (flymake-hledger--make-diagnostics source-buffer)))
        (if (or diags (zerop (process-exit-status process)))
            (funcall report-fn diags)
          (funcall report-fn
                   :panic
                   :explanation
                   (buffer-substring (point-min) (point-max))))))))

(defconst flymake-hledger--error-regexp
  (rx bol "hledger" (optional ".exe") ": Error: "
      (+ (not ":")) ":" ; filename (normally "-" to indicate stdin
      (or
       ;; <start-line>-<end-line>:
       (seq (group-n 1 (one-or-more (any digit)))
            "-"
            (group-n 3 (one-or-more (any digit)))
            ":\n")
       ;; <start-line>:<start-column>-<end-column>:
       (seq (group-n 1 (one-or-more (any digit)))
            ":"
            (group-n 2 (one-or-more (any digit)))
            "-"
            (group-n 4 (one-or-more (any digit)))
            ":\n")
       ;; <start-line>:<start-column>:
       (seq (group-n 1 (one-or-more (any digit)))
            ":"
            (group-n 2 (one-or-more (any digit)))
            ":\n")
       ;; <start-line>:
       (seq (group-n 1 (one-or-more (any digit)))
            ":\n"))
      ;; excerpt lines:
      (one-or-more bol (any space digit) (zero-or-more not-newline) "\n")
      ;; message lines:
      (group-n 5 (one-or-more bol (zero-or-more not-newline) "\n")))
  "Regular expression matching hledger errors.

Group 1 is for the starting line.
Group 2 is for the starting column.
Group 3 is for the ending line.
Group 4 is for the ending column.
Group 5 is for the error message.")

(defun flymake-hledger--make-diagnostics (source-buffer)
  "Return diagnostics of hledger errors listed in the current buffer.

SOURCE-BUFFER should contain the ledger being checked.  The current buffer
should contain hledger error messages."
  ;; The code below parses error messages from the end to the beginning of the
  ;; buffer. This is easier than using the usual re-search-forward because
  ;; hledger has a clear way to indicate the beginning of an error message but
  ;; no clear ending.
  (goto-char (point-max))
  (save-match-data
    (cl-loop
     while (and (> (point) (point-min)) (re-search-backward flymake-hledger--error-regexp nil t))
     for start-line = (string-to-number (match-string 1))
     for start-column = (when (match-string 2) (string-to-number (match-string 2)))
     for end-line = (if (match-string 3)
                        (string-to-number (match-string 3))
                      start-line)
     for end-column = (when (match-string 4) (string-to-number (match-string 4)))
     for message = (match-string 5)
     for start-positions = (flymake-diag-region source-buffer start-line start-column)
     for end-positions = (flymake-diag-region source-buffer end-line end-column)
     for diagnostic = (flymake-make-diagnostic
                       source-buffer
                       (car start-positions)
                       (cdr end-positions)
                       :error
                       message)
     collect diagnostic into diagnostics
     finally return (nreverse diagnostics))))

(provide 'flymake-hledger)
;;; flymake-hledger.el ends here

;; LocalWords:  Flymake flymake hledger backend ordereddates REPORT-FN
;; LocalWords:  balancednoautoconversion recentassertions uniqueleafnames
