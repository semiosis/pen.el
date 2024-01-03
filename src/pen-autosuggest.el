;;; pen-autosuggest.el --- Language model autosuggestions for pen.el -*- lexical-binding: t; -*-

;; Adapted from:
;; https://github.com/dieggsy/esh-autosuggest

(require 'company)
(require 'cl-lib)

(defgroup pen-autosuggest nil
  "Fish-like autosuggestions for penel."
  :group 'company)

(defcustom pen-autosuggest-delay 0
  "Delay for history autosuggestion."
  :group 'pen-autosuggest
  :type 'number)

(defcustom pen-autosuggest-use-company-map nil
  "Instead of overriding `company-active-map', use as-is.

This is disabled by default, as bindings in `company-active-map'
to RET and TAB may interfere with command input and completion
respectively."
  :group 'pen-autosuggest
  :type 'boolean)

;; Fibonacci function
;; https
;; (defun pen-autosuggest--fib (n)
;;   )

;; How do I want this to work?
;; It might currently be worth only generating one
(defun pen-set-autosuggestions ()
  (setq pen-autosuggest-candidates-list
        ;; (pen-no-select (pen-line-complete (pen-complete-function (pen-preceding-text))))
        (mapcar (lambda (s) (concat (pen-preceding-text-line) s))
                (pen-no-select (pen-line-complete (pen-one (pen-complete-function (pen-preceding-text)))))))
  (message (pp-oneline pen-autosuggest-candidates-list))
  pen-autosuggest-candidates-list)

(defvar pen-autosuggest-active-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "<right>") 'company-complete-selection)
    (define-key keymap (kbd "C-f") 'company-complete-selection)
    (define-key keymap (kbd "M-<right>") 'pen-autosuggest-complete-word)
    (define-key keymap (kbd "M-f") 'pen-autosuggest-complete-word)
    keymap)
  "Keymap that is enabled during an active history
  autosuggestion.")

(defset pen-autosuggest-candidates-list '())
(defset penel-prompt-regexp "")

(defun pen-autosuggest-candidates (prefix)
  "Select the first penel history candidate that starts with PREFIX."
  (let* ((history
          (delete-dups
           (mapcar (lambda (str)
                     (string-trim (substring-no-properties str)))
                   pen-autosuggest-candidates-list)))
         (most-similar (cl-find-if
                        (lambda (str)
                          (string-prefix-p prefix str))
                        history)))
    (when most-similar
      `(,most-similar))))

(defun pen-autosuggest-complete-word ()
  (interactive)
  (save-excursion
    (let ((pos (point)))
      (company-complete-selection)
      (goto-char pos)
      (forward-word)
      (unless (or (eobp) (eolp))
        (kill-line))))
  (end-of-line)
  (ignore-errors
    (let ((inhibit-message t))
      (company-begin-backend 'pen-autosuggest))))

(defun pen-autosuggest-bol ()
  ;; This should really go to the semantic start of the line than literal
  ;; based on j:eshell-bol
  (beginning-of-line)
  (point))

(defun pen-autosuggest--prefix ()
  "Get current penel input."
  ;; (let* ((input-start
  ;;         (progn
  ;;           (save-excursion
  ;;             (beginning-of-line)
  ;;             (while (not (looking-at-p penel-prompt-regexp))
  ;;               (forward-line -1))
  ;;             (re-search-forward penel-prompt-regexp nil 'noerror)
  ;;             (pen-autosuggest-bol)))
  ;;         )
  ;;        (prefix
  ;;         (string-trim-left
  ;;          (buffer-substring-no-properties
  ;;           input-start
  ;;           (line-end-position)))))
  ;;   (if (not (string-empty-p prefix))
  ;;       prefix
  ;;     'stop))
  (pen-preceding-text-line))

;;;###autoload
(defun pen-autosuggest (command &optional arg &rest ignored)
  "`company-mode' backend to provide penel history suggestion."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'pen-autosuggest))
    (prefix (and ;; (eq major-mode 'penel-mode)
             (minor-mode-enabled pen)
             (pen-autosuggest--prefix)))
    (candidates (pen-autosuggest-candidates arg))
    (require-match 'never)))

;;;###autoload
(define-minor-mode pen-autosuggest-mode
  "Enable fish-like autosuggestions in penel.

You can use <right> to select the suggestion. This is
customizable through `pen-autosuggest-active-map'. If
you prefer to use the default value of `company-active-map', you
may set the variable
`pen-autosuggest-use-company-map', though this isn't
recommended as RET and TAB may not work as expected (send input,
trigger completions, respectively) when there is an active
suggestion.

The delay defaults to 0 seconds to emulate fish shell's
instantaneous suggestions, but is customizable with
`pen-autosuggest-delay'.

Note: This assumes you want to use something other than company
for shell completion, e.g. `penel-pcomplete',
`completion-at-point', or helm-pen-pcomplete, since
`company-active-map', `company-backends', and `company-frontends'
will be locally overriden and company will be used solely for
history autosuggestions."
  :init-value nil
  :group 'pen-autosuggest
  (if pen-autosuggest-mode
      (progn
        (company-mode 1)
        (unless pen-autosuggest-use-company-map
          (setq-local company-active-map pen-autosuggest-active-map))
        (setq-local company-idle-delay pen-autosuggest-delay)
        (setq-local company-backends '(pen-autosuggest))
        (setq-local company-frontends '(company-preview-frontend)))
    (company-mode -1)
    (kill-local-variable 'company-active-map)
    (kill-local-variable 'company-idle-delay)
    (kill-local-variable 'company-backends)
    (kill-local-variable 'company-frontends)))

;; Yeah, sadly can't do this
(defun pen-suggest-on-change (start end length &optional content-change-event-fn)
  (if (minor-mode-enabled pen-autosuggest-mode)
    nil
    (run-with-idle-timer 0.1 0 'pen-set-autosuggestions)
    (pen-set-autosuggestions)))

;; Hell

;; (add-hook 'after-change-functions 'pen-suggest-on-change nil t)
;; (remove-hook 'after-change-functions 'pen-suggest-on-change)

(provide 'pen-autosuggest)

;;; pen-autosuggest.el ends here