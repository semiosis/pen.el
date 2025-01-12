;;; universal-sidecar.el --- A universal sidecar buffer -*- lexical-binding: t -*-

;; Copyright (C) 2023-2024 Samuel W. Flint <me@samuelwflint.com>

;; Author: Samuel W. Flint <me@samuelwflint.com>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; URL: https://git.sr.ht/~swflint/emacs-universal-sidecar
;; Version: 1.5.2
;; Package-Requires: ((emacs "26.1") (magit-section "3.0.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:
;;
;;; Installation
;;
;; This package has one main requirement: `magit', for
;; `magit-section'.  Assuming this package is satisfied, the
;; `universal-sidecar.el' file may be placed on the load path and
;; `require'd.
;;
;;; Usage
;;
;; The `universal-sidecar-toggle' command will bring up a per-frame
;; "sidecar" buffer.  These sidecar buffers are used to show
;; information about or related to the focused buffer.  Information is
;; shown in *sections*, which are configured using the
;; `universal-sidecar-sections' variable.  The behavior of this
;; variable, and expected interface is described below in
;; configuration.
;;
;; Additionally, to make sure that the sidecar buffer is updated, it's
;; necessary to advise several functions.  This can be done
;; automatically using the `universal-sidecar-insinuate' function,
;; which will advise functions listed in
;; `universal-sidecar-advise-commands'.  This may be undone with
;; `universal-sidecar-uninsinuate'.  Additionally,
;; `universal-sidecar-insinuate' will add `universal-sidecar-refresh'
;; to the `focus-in-hook', and will set an idle timer to refresh all
;; sidecar buffers (idle time configured with
;; `universal-sidecar-refresh-time').  Buffers can be ignored by
;; modifying the `universal-sidecar-ignore-buffer-regexp', or using
;; the (irregular) `universal-sidecar-ignore-buffer-functions' hook.
;; This hook will be run with an argument (the buffer) and run until a
;; non-nil result.
;;
;;;; Configuration
;;
;; The name of the sidecar buffer is configured using
;; `universal-sidecar-buffer-name-format', which must contain `%F', a
;; representation of the description of the frame.
;;
;; Which sections are shown is configured using
;; `universal-sidecar-sections', which is a list of functions or
;; functions-with-arguments.  For example, let's consider the section
;; `buffer-git-status', which shows git status.  This section allows a
;; keyword argument, `:show-renames', which defaults to t.  If we want
;; the default behavior, we would configure it using
;;
;;     (add-to-list 'universal-sidecar-sections 'buffer-git-status)
;;
;; However, if we want the opposite behavior (don't show renames),
;; we'd configure it as shown below.
;;
;; (add-to-list 'universal-sidecar-sections '(buffer-git-status :show-renames t))
;;
;; Note that using `add-to-list' is generally bad practice, as the
;; sections will be run in the order they're present in the list.
;;
;; Next, the displayed buffer name is generated using
;; `universal-sidecar-buffer-id-format' and
;; `universal-sidecar-buffer-id-formatters'.  These may be customized
;; to your liking.  Note: `universal-sidecar-buffer-id-formatters' is
;; an alist of character/function pairs.  The functions should take as
;; their first (and only mandatory) argument the buffer for which the
;; sidecar is being displayed.
;;
;; Finally, sidecar buffers are displayed using `display-window'.
;; This means that how the buffer is displayed is easily configurable
;; from `display-buffer-alist'.  The author's configuration is shown
;; below as an example.  In particular, using the
;; `display-buffer-in-side-window' display action is suggested, as
;; it's generally not helpful to select the sidecar window through
;; normal window motion commands
;;
;;     (add-to-list 'display-buffer-alist
;;                  '("\\*sidecar\\*"
;;                    (display-buffer-in-side-window)
;;                    (slot . 0)
;;                    (window-width . 0.2)
;;                    (window-height . 0.2)
;;                    (preserve-size t . t)
;;                    (window-parameters . ((no-other-window . t)
;;                                          (no-delete-other-windows . t)))))
;;
;;
;; Finally, errors in sections or section definitions are by default
;; logged to the *Warnings* buffer.  This is done in a way to allow
;; for debugging.  Moreover, the logging can be disabled by setting
;; `universal-sidecar-inhibit-section-error-log' to non-nil, in which
;; case (unless debugging is enabled) these errors will be ignored.
;;
;;; Section Functions
;;
;; The basic installation of `universal-sidecar' does not include any
;; section functions.  This is to reduce the number of dependencies of
;; the package itself so that it may be used as a library for others,
;; or to help integrate multiple packages.  A
;; `universal-sidecar-sections.el' package is available as well, which
;; will have simple section definitions that may be of use.

;; However, implementation of functions is generally straight-forward.
;; First, sections are simply functions which take a minimum of two
;; arguments, `buffer', or the buffer we're generating a sidecar for,
;; and `sidecar', the sidecar buffer.  When writing these section
;; functions, it is recommended to avoid writing content to `sidecar'
;; until it's verified that the information needed is available.  That
;; is **don't write sections without bodies**.

;; To aid in defining sections, the `universal-sidecar-define-section'
;; and `universal-sidecar-insert-section' macros are available.  The
;; first defines a section which can be added to
;; `universal-sidecar-sections'.  The second simplifies writing
;; sections by adding proper separators and headers to the sidecar
;; buffer.  We will demonstrate both below.
;;
;;     (universal-sidecar-define-section fortune-section (file title)
;;                                       (:major-modes org-mode
;;                                                     :predicate (not (buffer-modified-p)))
;;       (let ((title (or title
;;                        (and file
;;                             (format "Fortune: %s" file))
;;                        "Fortune"))
;;             (fortune (shell-command-to-string (format "fortune%s"
;;                                                       (if file
;;                                                           (format " %s" file)
;;                                                         "")))))
;;         (universal-sidecar-insert-section fortune-section title
;;           (insert fortune))))
;;
;; Note: the arguments (`file' and `title') are *keyword* arguments.
;; Additionally, you specify that this section only applies when
;; `buffer' is a descendent of `:major-modes' which can be either a
;; symbol or a list of symbols.  `:predicate' is used to specify a
;; somewhat more complex predicate to determine if the section should
;; be generated.
;;
;; This section could be added in any of the following ways:
;;
;;     (add-to-list 'universal-sidecar-sections 'fortune-section)
;;     (add-to-list 'universal-sidecar-sections '(fortune-section :file "definitions"))
;;     (add-to-list 'universal-sidecar-sections '(fortune-section :title "O Fortuna!"))
;;     (add-to-list 'universal-sidecar-sections '(fortune-section :file "definitions" :title "Random Definition"))
;;
;; Finally, section text can be formatted and fontified as if it was
;; in some other mode, for instance, `org-mode' using
;; `universal-sidecar-fontify-as'.  An example is shown below.
;;
;;     (universal-sidecar-fontify-as org-mode ((org-fold-core-style 'overlays))
;;       (some-function-that-generates-org-text)
;;       (some-post-processing-of-org-text))
;;
;;
;;;; Changelog
;;
;; v1.2.3 (2023-06-24): Pass package-lint and byte-compile-file with
;; minimal errors.
;;
;; v1.2.4 (2023-07-17): Allow the sidecar's displayed buffer
;; identifier to be autogenerated using
;; `universal-sidecar-buffer-id-format' and
;; `universal-sidecar-buffer-id-formatters'.
;;
;; v1.2.6 (2023-09-04): Fix type error in
;; `universal-sidecar-format-buffer-id'.
;;
;; v1.2.7 (2023-09-04): Fix a byte compilation issue.
;;
;; v1.3.0 (2023-09-14): Log errors, don't ignore them.
;;
;; v1.4.0 (2023-09-22): Add
;; `universal-sidecar-inhibit-section-error-log' to control when
;; sidecar section errors are logged.
;;
;; v1.4.3 (2024-01-03): Buffers can now be ignored using the
;; `universal-sidecar-ignore-buffer-regexp' and
;; `universal-sidecar-ignore-buffer-functions' variables.
;;
;; v1.5.0 (2024-01-06): The macro `universal-sidecar-fontify-as' is
;; now available to fontify code as if in some major mode.
;;
;; v1.5.1 (2024-01-14): `universal-sidecar-advise-commands' and
;; `universal-sidecar-unadvise-commands' now take arguments to allow
;; programmatic advising.
;;
;; v1.5.2 (2024-01-15): `universal-sidecar-buffer-mode-hook' is now
;; customizable.

;;; Code:

(require 'cl-lib)
(require 'magit-section)


;;; Customizations

(defgroup universal-sidecar nil
  "Customization for universal-sidecar, showing relevant information for the focused buffer."
  :group 'convenience
  :prefix "universal-sidecar-"
  :link '(url-link :tag "Sourcehut" "https://git.sr.ht/~swflint/emacs-universal-sidecar")
  :link '(emacs-library-link :tag "Library Source" "universal-sidecar.el"))

(defcustom universal-sidecar-buffer-name-format "*sidecar* (%F)"
  "Format for universal sidecar name.

Must contain %F, which is a string describing the current frame."
  :group 'universal-sidecar
  :type 'string)

(defcustom universal-sidecar-buffer-id-format "*sidecar* (%b)"
  "Format for displayed name of universal sidecar.

Formatting is done by the format specifiers in
`universal-sidecar-buffer-id-formatters'."
  :group 'universal-sidecar
  :type 'string)

(defcustom universal-sidecar-buffer-id-formatters (list (cons ?b 'buffer-name))
  "Format specifiers for `universal-sidecar-buffer-id-format'.

Format specifiers should be cons cells of character/function
pairs.  The function should take one argument, the buffer which
the sidecar is being shown for."
  :group 'universal-sidecar
  :type '(repeat (cons :tag "Specifier"
                       (character :tag "Character")
                       (function :tag "Function"))))

(defcustom universal-sidecar-buffer-mode-hook (list)
  "Major mode hook to run in the sidecar.

This is run after `magit-section-mode-hook'."
  :group 'universal-sidecar
  :type 'hook)

(defcustom universal-sidecar-sections (list)
  "A list of sections that may be shown in the universal sidecar buffer.

Sections are functions that take a minimum of two arguments: a
BUFFER-FOR-SIDECAR (the buffer the sidecar is shown for), and
SIDECAR (the buffer holding sidecar sections).

A section may be described as either a function or a function and
arguments to be passed after the BUFFER-FOR-SIDECAR and SIDECAR
arguments."
  :group 'universal-sidecar
  :type '(repeat (choice (symbol :tag "Function")
                         (list :tag "Function with arguments"
                               (symbol :tag "Function")
                               (repeat :tag "Arguments"
                                       :inline t
                                       (sexp :tag "Argument"))))))

(defcustom universal-sidecar-advise-commands
  (list 'switch-to-buffer
        'other-window
        'display-buffer
        'find-file
        'find-file-read-only)
  "A list of commands which should be advised to update the sidecar buffer.

Commands can either be symbols (which have the advice run after),
or `(symbol location)' lists.  Location should be `:after',
`:before', `:interactive-after', or `:interactive-before'."
  :group 'universal-sidecar
  :type (let ((fn '(symbol :tag "Function Name")))
          `(repeat (choice ,fn
                           (list :tag "After" ,fn (const :after))
                           (list :tag "Before" ,fn (const :before))
                           (list :tag "Interactive (After)" ,fn (const :interactive-after))
                           (list :tag "Interactive (Before)" ,fn (const :interactive-before))))))

(defcustom universal-sidecar-refresh-time 5
  "How many seconds Emacs should be idle before sidecars are auto-refreshed."
  :group 'universal-sidecar
  :type 'number)

(defcustom universal-sidecar-inhibit-section-error-log nil
  "When non-nil, broken sections will not log to the *Warnings* buffer."
  :group 'universal-sidecar
  :type 'boolean)

(defcustom universal-sidecar-ignore-buffer-regexp (rx  " *")
  "Pattern describing buffers to ignore on automatic refresh."
  :group 'universal-sidecar
  :type 'regexp)

(defcustom universal-sidecar-ignore-buffer-functions (list)
  "Irregular hook to determine if a buffer should be ignored.

Return non-nil if the buffer should be ignored.  Hook will be run
until non-nil."
  :group 'universal-sidecar
  :type 'hook)


;;; Sidecar Buffer Mode

(defvar-local universal-sidecar-current-buffer nil
  "What is the current buffer for the sidecar, before refresh?")

(defvar universal-sidecar-buffer-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map magit-section-mode-map)
    (define-key map (kbd "g") #'universal-sidecar-refresh)
    map)
  "Keymap for Sidecar Buffers.")

(define-derived-mode universal-sidecar-buffer-mode magit-section-mode "Sidecar"
  "Major mode for displaying information relevant to the current buffer."
  :group 'universal-sidecar)


;;; Opening Sidecars

(defun universal-sidecar-get-name (&optional frame)
  "Get the name of the sidecar buffer for FRAME.

If FRAME is nil, use `selected-frame'."
  (let* ((frame (or frame (selected-frame)))
         (id (frame-parameter frame 'window-id)))
    (format-spec universal-sidecar-buffer-name-format (list (cons ?F id)))))

(defun universal-sidecar-get-buffer (&optional frame)
  "Get the sidecar buffer for FRAME."
  (get-buffer (universal-sidecar-get-name frame)))

(defun universal-sidecar-get-buffer-create (&optional frame)
  "Get or create a sidecar buffer for FRAME."
  (let ((frame (or frame (selected-frame))))
    (or (universal-sidecar-get-buffer frame)
        (with-current-buffer (get-buffer-create (universal-sidecar-get-name frame))
          (universal-sidecar-buffer-mode)
          (current-buffer)))))

(defun universal-sidecar-visible-p (&optional frame)
  "Determine visibility of current sidecar visibility in FRAME."
  (when-let ((buffer (universal-sidecar-get-buffer frame)))
    (windowp (get-buffer-window buffer))))

(defun universal-sidecar-toggle (&optional frame)
  "Toggle showing sidecar buffer for FRAME."
  (interactive)
  (if (universal-sidecar-visible-p frame)
      (quit-window nil (get-buffer-window (universal-sidecar-get-buffer frame)))
    (display-buffer (universal-sidecar-get-buffer-create frame))
    (universal-sidecar-refresh)))


;;; Sidecar Display

(defun universal-sidecar-set-title (title &optional sidecar)
  "Set the header TITLE in SIDECAR."
  (with-current-buffer (or sidecar
                           (universal-sidecar-get-buffer))
    (setq-local header-line-format (concat (propertize " " 'display '(space :align-to 0))
                                           title))))

(defun universal-sidecar-format-buffer-id (buffer)
  "Format `mode-line-buffer-identification' for BUFFER."
  (let* ((specifiers (cl-remove-if #'null
                                   (mapcar (lambda (pair)
                                             (cl-destructuring-bind (character . function) pair
                                               (when (string-match-p (format "%%%c" character) universal-sidecar-buffer-id-format)
                                                 (cons character (or (funcall function buffer) "")))))
                                           universal-sidecar-buffer-id-formatters))))
    (propertize (format-spec universal-sidecar-buffer-id-format specifiers) 'face 'mode-line-buffer-id)))

(defun universal-sidecar-refresh (&optional buffer sidecar)
  "Refresh sections for BUFFER in SIDECAR.

If BUFFER is non-nil, use the currently focused buffer.
If SIDECAR is non-nil, use sidecar for the current frame."
  (interactive)
  (save-mark-and-excursion
    (when (universal-sidecar-visible-p)
      (let* ((sidecar (or sidecar
                          (universal-sidecar-get-buffer)))
             (buffer (or buffer
                         (if-let ((buf (window-buffer (selected-window)))
                                  (buffer-is-ignored-p
                                   (or (equal buf sidecar)
                                       (string-match-p universal-sidecar-ignore-buffer-regexp
                                                       (buffer-name buf))
                                       (run-hook-with-args-until-success 'universal-sidecar-ignore-buffer-functions
                                                                         buf))))
                             (with-current-buffer sidecar universal-sidecar-current-buffer)
                           buf))))
        (with-current-buffer sidecar
          (let ((inhibit-read-only t))
            (universal-sidecar-buffer-mode)
            (erase-buffer)
            (setq-local mode-line-buffer-identification (universal-sidecar-format-buffer-id buffer))
            (setq-local universal-sidecar-current-buffer buffer)
            (universal-sidecar-set-title (propertize (buffer-name buffer) 'face 'bold) sidecar)
            (dolist (section universal-sidecar-sections)
              (condition-case-unless-debug err
                  (pcase section
                    ((pred functionp)
                     (funcall section buffer sidecar))
                    (`(,section . ,args)
                     (apply section (append (list buffer sidecar) args)))
                    (_
                     (user-error "Invalid section definition `%S' in `universal-sidecar-sections'" section)))
                (t
                 (unless universal-sidecar-inhibit-section-error-log
                   (display-warning 'universal-sidecar (format "Error encountered in displaying section %S: %S" section err) :error)))))
            (goto-char 0)))))))

;;; Updating the Sidecar

(defun universal-sidecar-command-advice (&rest _)
  "Before/after certain commands are run, refresh the sidecar."
  (universal-sidecar-refresh))

(defun universal-sidecar-interactive-after-command-advice (original &rest arguments)
  "Call ORIGINAL with ARGUMENTS, refreshing sidecar if interactive."
  (if (called-interactively-p 'interactive)
      (progn
        (call-interactively original)
        (universal-sidecar-refresh))
    (apply original arguments)))

(defun universal-sidecar-interactive-before-command-advice (original &rest arguments)
  "Call ORIGINAL with ARGUMENTS, refreshing sidecar if interactive."
  (if (called-interactively-p 'interactive)
      (progn
        (universal-sidecar-refresh)
        (call-interactively original))
    (apply original arguments)))

(defun universal-sidecar-advise-commands (&optional commands-list)
  "Automatically advise COMMANDS-LIST to update the sidecar buffer.

If COMMANDS-LIST is nil, `universal-sidecar-advise-commands' will
be used (which, see for format of COMMANDS-LIST)."
  (dolist (command-spec (or commands-list universal-sidecar-advise-commands))
    (pcase command-spec
      (`(,command :after)
       (advice-add command :after #'universal-sidecar-command-advice))
      (`(,command :before)
       (advice-add command :before #'universal-sidecar-command-advice))
      (`(,command :interactive-after)
       (advice-add command :around #'universal-sidecar-interactive-after-command-advice))
      (`(,command :interactive-before)
       (advice-add command :around #'universal-sidecar-interactive-before-command-advice))
      (`,command
       (advice-add command :after #'universal-sidecar-command-advice)))))

(defun universal-sidecar-unadvise-commands (&optional commands-list)
  "Unadvise COMMANDS-LIST to no longer update the sidecar buffer.

If COMMANDS-LIST is nil, `universal-sidecar-advise-commands' will
be used (which, see for format of COMMANDS-LIST)."
  (dolist (command-spec (or commands-list universal-sidecar-advise-commands))
    (let ((command (or (and (listp command-spec) (car command-spec))
                       command-spec)))
      (cond
       ((advice-member-p #'universal-sidecar-command-advice
                         command)
        (advice-remove command
                       #'universal-sidecar-command-advice))
       ((advice-member-p #'universal-sidecar-interactive-after-command-advice
                         command)
        (advice-remove command
                       #'universal-sidecar-interactive-after-command-advice))
       ((advice-member-p #'universal-sidecar-interactive-before-command-advice
                         command)
        (advice-remove command
                       #'universal-sidecar-interactive-before-command-advice))))))

(defvar universal-sidecar-refresh-timer nil
  "Idle timer for refreshing the universal sidecar buffer.")

(defun universal-sidecar-refresh-all ()
  "Refresh all sidecar buffers."
  (dolist (frame (frame-list))
    (save-mark-and-excursion
      (with-selected-frame frame
        (universal-sidecar-refresh)))))

(defun universal-sidecar-insinuate ()
  "Insinuate (i.e., enable) automatic refresh of sidecars."
  (universal-sidecar-advise-commands)
  (when (timerp universal-sidecar-refresh-timer)
    (cancel-timer universal-sidecar-refresh-timer))
  (setf universal-sidecar-refresh-timer (run-with-idle-timer universal-sidecar-refresh-time t
                                                             #'universal-sidecar-refresh-all)))

(defun universal-sidecar-uninsinuate ()
  "Uninsinuate (i.e., disable) automatic refresh of sidecars."
  (universal-sidecar-unadvise-commands)
  (when (timerp universal-sidecar-refresh-timer)
    (cancel-timer universal-sidecar-refresh-timer)
    (setf universal-sidecar-refresh-timer nil)))


;;; Defining Sidecar Sections

(cl-defun universal-sidecar--generate-major-modes-expression (major-modes)
  "Generate the expression to check if the selected BUFFER is one of MAJOR-MODES."
  `(derived-mode-p ,@(mapcar (lambda (mode) `',mode)
                             (or (and (listp major-modes)
                                      major-modes)
                                 (list major-modes)))))

(cl-defun universal-sidecar--generate-predicate (major-modes predicate &optional (buffer 'buffer))
  "Generate predicate expression for MAJOR-MODES and PREDICATE.

Use BUFFER as the checked buffer."
  (when (or major-modes predicate)
    `(with-current-buffer ,buffer
       ,(cond
         ((and predicate major-modes)
          `(and
            ,(universal-sidecar--generate-major-modes-expression major-modes)
            ,predicate))
         (predicate predicate)
         (major-modes (universal-sidecar--generate-major-modes-expression major-modes))))))

(cl-defmacro universal-sidecar-define-section (name (&rest args-list)
                                                    (&key predicate major-modes &allow-other-keys)
                                                    &body body
                                                    &aux
                                                    (docstring (and (stringp (car body))
                                                                    (car body))))
  "Define a sidecar section NAME with ARGS-LIST (implicit &key).

BODY is wrapped in PREDICATE if present, including checking
MAJOR-MODES.

The arguments BUFFER and SIDECAR are bound in BODY.

If BODY has a string as the first element, this is used as the
DOCSTRING for the generated function."
  (declare (indent 3) (doc-string 4))
  (let* ((body-no-docstring (if docstring
                                (cdr body)
                              body))
         (generated-predicate (universal-sidecar--generate-predicate major-modes predicate))
         (body-with-predicate (if generated-predicate
                                  `(when ,generated-predicate ,@body-no-docstring)
                                `(progn ,@body-no-docstring))))
    `(cl-defun ,name (buffer sidecar &key ,@args-list &allow-other-keys)
       ,docstring
       (ignore buffer sidecar)
       ,body-with-predicate)))


;;; Section generation utilities

(defvar universal-sidecar-section-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map universal-sidecar-buffer-mode-map)
    map))

(defclass universal-sidecar-section (magit-section)
  ((keymap :initform 'universal-sidecar-section-map)))

(cl-defmacro universal-sidecar-insert-section (name header &body body)
  "Insert section NAME as generated by running BODY with HEADER.

Note, this macro ensures that a separating double-newline is
inserted by default."
  (declare (indent 2))
  `(magit-insert-section ,name (universal-sidecar-section)
     (ignore ,name)
     (magit-insert-heading ,header)
     ,@body
     (insert "\n\n")))

(cl-defmacro universal-sidecar-fontify-as (mode (&rest local-bindings) string-expression &body after-insert)
  "Fontify STRING-EXPRESSION as MODE.

Before inserting results of STRING-EXPRESSION, LOCAL-BINDINGS are
set via `setq-local'.  Note, LOCAL-BINDINGS should be of the
form (VARIABLE VALUE-EXPRESSION).

After inserting results of STRING-EXPRESSION, AFTER-INSERT is run."
  (declare (indent 2))
  (let ((local-bindings (mapcar (lambda (binding)
                                  `(setq-local ,(nth 0 binding) ,(nth 1 binding)))
                                local-bindings)))
    `(with-temp-buffer
       (,mode)
       ,@local-bindings
       (insert ,string-expression)
       ,@after-insert
       (font-lock-ensure)
       (buffer-string))))

(provide 'universal-sidecar)

;;; universal-sidecar.el ends here
