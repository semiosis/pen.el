;;; json-mode.el --- Major mode for editing JSON files.

;; Copyright (C) 2011-2014 Josh Johnston

;; Author: Josh Johnston
;; URL: https://github.com/joshwnj/json-mode
;; Package-Version: 20211011.630
;; Package-Commit: eedb4560034f795a7950fa07016bd4347c368873
;; Version: 1.6.0
;; Package-Requires: ((json-snatcher "1.0.0") (emacs "24.4"))

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

;; extend the builtin js-mode's syntax highlighting

;;; Code:

(require 'js)
(require 'rx)
(require 'json-snatcher)

(defgroup json-mode '()
  "Major mode for editing JSON files."
  :group 'js)

;;;###autoload
(defconst json-mode-standard-file-ext '(".json" ".jsonld")
  "List of JSON file extensions.")

;; This is to be sure the customization is loaded.  Otherwise,
;; autoload discards any defun or defcustom.
;;;###autoload
(defsubst json-mode--update-auto-mode (filenames)
  "Update the `json-mode' entry of `auto-mode-alist'.

FILENAMES should be a list of file as string.
Return the new `auto-mode-alist' entry"
  (let* ((new-regexp
          (rx-to-string
           `(seq (eval
                  (cons 'or
                        (append json-mode-standard-file-ext
                                ',filenames))) eot)))
         (new-entry (cons new-regexp 'json-mode))
         (old-entry (when (boundp 'json-mode--auto-mode-entry)
                      json-mode--auto-mode-entry)))
    (setq auto-mode-alist (delete old-entry auto-mode-alist))
    (add-to-list 'auto-mode-alist new-entry)
    new-entry))

;;; make byte-compiler happy
(defvar json-mode--auto-mode-entry)

;;;###autoload
(defcustom json-mode-auto-mode-list '(
                                      ".babelrc"
                                      ".bowerrc"
                                      "composer.lock"
                                      )
  "List of filenames for the JSON entry of `auto-mode-alist'.

Note however that custom `json-mode' entries in `auto-mode-alist'
won’t be affected."
  :group 'json-mode
  :type '(repeat string)
  :set (lambda (symbol value)
         "Update SYMBOL with a new regexp made from VALUE.

This function calls `json-mode--update-auto-mode' to change the
`json-mode--auto-mode-entry' entry in `auto-mode-alist'."
         (set-default symbol value)
         (setq json-mode--auto-mode-entry (json-mode--update-auto-mode value))))

;; Autoload needed to initalize the the `auto-list-mode' entry.
;;;###autoload
(defvar json-mode--auto-mode-entry (json-mode--update-auto-mode json-mode-auto-mode-list)
  "Regexp generated from the `json-mode-auto-mode-list'.")

(defconst json-mode-quoted-string-re
  (rx (group (char ?\")
             (zero-or-more (or (seq ?\\ ?\\)
                               (seq ?\\ ?\")
                               (seq ?\\ (not (any ?\" ?\\)))
                               (not (any ?\" ?\\))))
             (char ?\"))))
(defconst json-mode-quoted-key-re
  (rx (group (char ?\")
             (zero-or-more (or (seq ?\\ ?\\)
                               (seq ?\\ ?\")
                               (seq ?\\ (not (any ?\" ?\\)))
                               (not (any ?\" ?\\))))
             (char ?\"))
      (zero-or-more blank)
      ?\:))
(defconst json-mode-number-re (rx (group (one-or-more digit)
                                         (optional ?\. (one-or-more digit)))))
(defconst json-mode-keyword-re  (rx (group (or "true" "false" "null"))))

(defconst json-font-lock-keywords-1
  (list
   (list json-mode-keyword-re 1 font-lock-constant-face)
   (list json-mode-number-re 1 font-lock-constant-face))
  "Level one font lock.")

(defvar json-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Objects
    (modify-syntax-entry ?\{ "(}" st)
    (modify-syntax-entry ?\} "){" st)
    ;; Arrays
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")[" st)
    ;; Strings
    (modify-syntax-entry ?\" "\"" st)
    st))

(defvar jsonc-mode-syntax-table
  (let ((st (copy-syntax-table json-mode-syntax-table)))
    ;; Comments
    (modify-syntax-entry ?/ ". 124" st)
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?\^m ">" st)
    (modify-syntax-entry ?* ". 23bn" st)
    st))

(defun json-mode--syntactic-face (state)
  "Return syntactic face function for the position represented by STATE.
STATE is a `parse-partial-sexp' state, and the returned function is the
json font lock syntactic face function."
  (cond
   ((nth 3 state)
      ;; This might be a string or a name
    (let ((startpos (nth 8 state)))
      (save-excursion
        (goto-char startpos)
        (if (looking-at-p json-mode-quoted-key-re)
            font-lock-keyword-face
          font-lock-string-face))))
   ((nth 4 state) font-lock-comment-face)))

;;;###autoload
(define-derived-mode json-mode javascript-mode "JSON"
  "Major mode for editing JSON files"
  :syntax-table json-mode-syntax-table
  (set (make-local-variable 'font-lock-defaults)
       '(json-font-lock-keywords-1
         nil nil nil nil
         (font-lock-syntactic-face-function . json-mode--syntactic-face))))

;;;###autoload
(define-derived-mode jsonc-mode json-mode "JSONC"
  "Major mode for editing JSON files with comments"
  :syntax-table jsonc-mode-syntax-table)

;; Well formatted JSON files almost always begin with “{” or “[”.
;;;###autoload
(add-to-list 'magic-fallback-mode-alist '("^[{[]$" . json-mode))

;;;###autoload
(defun json-mode-show-path ()
  "Print the path to the node at point to the minibuffer."
  (interactive)
  (message (jsons-print-path)))

(define-key json-mode-map (kbd "C-c C-p") 'json-mode-show-path)

;;;###autoload
(defun json-mode-kill-path ()
  "Save JSON path to object at point to kill ring."
  (interactive)
    (kill-new (jsons-print-path)))

(define-key json-mode-map (kbd "C-c P") 'json-mode-kill-path)

;;;###autoload
(defun json-mode-beautify (begin end)
  "Beautify / pretty-print the active region (or the entire buffer if no active region)."
  (interactive "r")
  (unless (use-region-p)
    (setq begin (point-min)
          end (point-max)))
  (json-pretty-print begin end))

(define-key json-mode-map (kbd "C-c C-f") 'json-mode-beautify)

(defun json-toggle-boolean ()
  "If point is on `true' or `false', toggle it."
  (interactive)
  (unless (nth 8 (syntax-ppss)) ; inside a keyword, string or comment
    (let* ((bounds (bounds-of-thing-at-point 'symbol))
           (string (and bounds (buffer-substring-no-properties (car bounds) (cdr bounds))))
           (pt (point)))
      (when (and bounds (member string '("true" "false")))
        (delete-region (car bounds) (cdr bounds))
        (cond
         ((string= "true" string)
          (insert "false")
          (goto-char (if (= pt (cdr bounds)) (1+ pt) pt)))
         (t
          (insert "true")
          (goto-char (if (= pt (cdr bounds)) (1- pt) pt))))))))

(define-key json-mode-map (kbd "C-c C-t") 'json-toggle-boolean)

(defun json-nullify-sexp ()
  "Replace the sexp at point with `null'."
  (interactive)
  (let ((syntax (syntax-ppss)) symbol)
    (cond
     ((nth 4 syntax) nil)               ; inside a comment
     ((nth 3 syntax)                    ; inside a string
      (goto-char (nth 8 syntax))
      (when (save-excursion (forward-sexp) (skip-chars-forward "[:space:]") (eq (char-after) ?:))
        ;; sexp is an object key, so we nullify the entire object
        (goto-char (nth 1 syntax)))
      (kill-sexp)
      (insert "null"))
     ((setq symbol (bounds-of-thing-at-point 'symbol))
      (cond
       ((looking-at-p "null"))
       ((save-excursion (skip-chars-backward "[0-9.]") (looking-at json-mode-number-re))
        (kill-region (match-beginning 0) (match-end 0))
        (insert "null"))
       (t (kill-region (car symbol) (cdr symbol)) (insert "null"))))
     ((< 0 (nth 0 syntax))
      (goto-char (nth 1 syntax))
      (kill-sexp)
      (insert "null"))
     (t nil))))

(define-key json-mode-map (kbd "C-c C-k") 'json-nullify-sexp)

(defun json-increment-number-at-point (&optional delta)
  "Add DELTA to the number at point; DELTA defaults to 1."
  (interactive)
  (when (save-excursion (skip-chars-backward "[0-9.]") (looking-at json-mode-number-re))
    (let ((num (+ (or delta 1)
                  (string-to-number (buffer-substring-no-properties (match-beginning 0) (match-end 0)))))
          (pt (point)))
      (delete-region (match-beginning 0) (match-end 0))
      (insert (number-to-string num))
      (goto-char pt))))

(define-key json-mode-map (kbd "C-c C-i") 'json-increment-number-at-point)

(defun json-decrement-number-at-point ()
  "Decrement the number at point."
  (interactive)
  (json-increment-number-at-point -1))

(define-key json-mode-map (kbd "C-c C-d") 'json-decrement-number-at-point)

(provide 'json-mode)
;;; json-mode.el ends here
