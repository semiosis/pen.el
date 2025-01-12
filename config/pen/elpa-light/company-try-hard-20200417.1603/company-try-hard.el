;;; company-try-hard.el --- get all completions from company backends

;; Copyright (C) 2015 Wilfred Hughes

;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Homepage: https://github.com/Wilfred/company-try-hard
;; Version: 0.1
;; Package-Version: 20200417.1603
;; Package-Commit: 2b41136b5ed6e02032d99bcdb0599ecf00394fa5
;; Keywords: matching
;; Package-Requires: ((emacs "24.3") (company "0.8.0") (dash "2.0"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A `company-complete' alternative that tries much harder to find
;; completions.  If none of the current completions look good, call the
;; command again to try the next backend.
;;
;;; Usage:
;;
;; You will need to bind this function globally and in the active company keymap. For example:
;; 
;; (global-set-key (kbd "C-z") #'company-try-hard)
;; (define-key company-active-map (kbd "C-z") #'company-try-hard)

;;; Rationale:
;;
;; If any company backend returns a prefix, company will only try
;; other backends with the same prefix. See
;; https://github.com/company-mode/company-mode/issues/142#issuecomment-46589054
;;
;; This is intended to encourage backends that are precise. However,
;; this isn't always appropriate (it's hard to find all completion
;; candidates in very dynamic languages).
;;
;; Users may simply prefer aggressive completion candidate discovery,
;; especially people migrating from `hippie-expand', using
;; `hippie-expand-try-functions-list'.

;;; Code:

(require 'dash)
(require 'company)

(defvar-local company-try-hard--last-index nil
  "The index of the last backend used by `company-try-hard'.")

;;;###autoload
(defun company-try-hard ()
  "Offer completions from the first backend in `company-backends' that
offers candidates. If called again, use the next backend, and so on."
  (interactive)
  ;; If the last command wasn't `company-try-hard', reset the index so
  ;; we start at the first backend.
  (unless (eq last-command 'company-try-hard)
    (setq company-try-hard--last-index nil))
  ;; Close company if it's active, so `company-begin-backend' works.
  (company-abort)
  (catch 'break
    ;; Try every backend until we find one that returns some
    ;; candidates.
    (--map-indexed
     (catch 'continue
       ;; If we've tried this backend before, do nothing.
       (when (and (numberp company-try-hard--last-index)
                  (<= it-index company-try-hard--last-index))
         (throw 'continue nil))
       ;; Try this backend, ignoring a 'no completions here' error.
       (when (ignore-errors (company-begin-backend it))
         ;; We've found completions here, so remember this backend and
         ;; terminate for now.
         (message "company-try-hard: using %s" it)
         (setq company-try-hard--last-index it-index)
         (throw 'break nil)))
     company-backends)
    ;; If we haven't thrown 'break at this point, enable the user to
    ;; cycle through again.
    (setq company-try-hard--last-index nil)))

(provide 'company-try-hard)
;;; company-try-hard.el ends here
