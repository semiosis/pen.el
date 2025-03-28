;;; org-gtd-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from org-gtd.el

(register-definition-prefixes "org-gtd" '("org-gtd-"))


;;; Generated autoloads from org-gtd-agenda.el

(autoload 'org-gtd-engage "org-gtd-agenda" "\
Display `org-agenda' customized by org-gtd." t)
(autoload 'org-gtd-engage-grouped-by-context "org-gtd-agenda" "\
Show all `org-gtd-next' actions grouped by context (tag prefixed with @)." t)
(autoload 'org-gtd-show-all-next "org-gtd-agenda" "\
Show all next actions from all agenda files in a single list.
This assumes all GTD files are also agenda files." t)
(register-definition-prefixes "org-gtd-agenda" '("org-gtd-"))


;;; Generated autoloads from org-gtd-archive.el

(autoload 'org-gtd-archive-completed-items "org-gtd-archive" "\
Archive everything that needs to be archived in your org-gtd." t)
(register-definition-prefixes "org-gtd-archive" '("org-gtd-"))


;;; Generated autoloads from org-gtd-areas-of-focus.el

(register-definition-prefixes "org-gtd-areas-of-focus" '("org-gtd-"))


;;; Generated autoloads from org-gtd-backward-compatibility.el

(register-definition-prefixes "org-gtd-backward-compatibility" '("org-gtd--"))


;;; Generated autoloads from org-gtd-calendar.el

(register-definition-prefixes "org-gtd-calendar" '("org-gtd-calendar"))


;;; Generated autoloads from org-gtd-capture.el

(autoload 'org-gtd-capture "org-gtd-capture" "\
Capture something into the GTD inbox.

Wraps the function `org-capture' to ensure the inbox exists.
For GOTO and KEYS, see `org-capture' documentation for the variables of the
same name.

(fn &optional GOTO KEYS)" t)
(autoload 'org-gtd-inbox-path "org-gtd-capture" "\
Return the full path to the inbox file.")
(register-definition-prefixes "org-gtd-capture" '("org-gtd-" "with-org-gtd-capture"))


;;; Generated autoloads from org-gtd-clarify.el

(defvar org-gtd-clarify-map (make-sparse-keymap) "\
Keymap for command `org-gtd-clarify-mode', a minor mode.")
(autoload 'org-gtd-clarify-mode "org-gtd-clarify" "\
Minor mode for org-gtd.

This is a minor mode.  If called interactively, toggle the
`Org-Gtd-Clarify mode' mode.  If the prefix argument is positive,
enable the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `org-gtd-clarify-mode'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

(fn &optional ARG)" t)
(autoload 'org-gtd-clarify-item "org-gtd-clarify" "\
Process item at point through org-gtd." t)
(function-put 'org-gtd-clarify-item 'command-modes '(org-mode))
(register-definition-prefixes "org-gtd-clarify" '("org-gtd-clarify-"))


;;; Generated autoloads from org-gtd-core.el

(autoload 'with-org-gtd-context "org-gtd-core" "\
Wrap BODY... in this macro to inherit the org-gtd settings for your logic.

(fn &rest BODY)" nil t)
(function-put 'with-org-gtd-context 'lisp-indent-function 2)
(register-definition-prefixes "org-gtd-core" '("org-gtd-"))


;;; Generated autoloads from org-gtd-delegate.el

(autoload 'org-gtd-delegate-agenda-item "org-gtd-delegate" "\
Delegate item at point on agenda view." t)
(function-put 'org-gtd-delegate-agenda-item 'command-modes '(org-agenda-mode))
(autoload 'org-gtd-delegate-item-at-point "org-gtd-delegate" "\
Delegate item at point.  Use this if you do not want to refile the item.

You can pass DELEGATED-TO as the name of the person to whom this was delegated
and CHECKIN-DATE as the YYYY-MM-DD string of when you want `org-gtd' to remind
you if you want to call this non-interactively.
If you call this interactively, the function will ask for the name of the
person to whom to delegate by using `org-gtd-delegate-read-func'.

(fn &optional DELEGATED-TO CHECKIN-DATE)" t)
(function-put 'org-gtd-delegate-item-at-point 'command-modes '(org-mode))
(register-definition-prefixes "org-gtd-delegate" '("org-gtd-delegate"))


;;; Generated autoloads from org-gtd-files.el

(register-definition-prefixes "org-gtd-files" '("org-gtd-"))


;;; Generated autoloads from org-gtd-habit.el

(register-definition-prefixes "org-gtd-habit" '("org-gtd-habit"))


;;; Generated autoloads from org-gtd-horizons.el

(register-definition-prefixes "org-gtd-horizons" '("org-gtd-"))


;;; Generated autoloads from org-gtd-id.el

(register-definition-prefixes "org-gtd-id" '("org-gtd-id-"))


;;; Generated autoloads from org-gtd-incubate.el

(register-definition-prefixes "org-gtd-incubate" '("org-gtd-incubate"))


;;; Generated autoloads from org-gtd-knowledge.el

(register-definition-prefixes "org-gtd-knowledge" '("org-gtd-knowledge"))


;;; Generated autoloads from org-gtd-mode.el

(defvar org-gtd-mode nil "\
Non-nil if Org-GTD mode is enabled.
See the `org-gtd-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `org-gtd-mode'.")
(custom-autoload 'org-gtd-mode "org-gtd-mode" nil)
(autoload 'org-gtd-mode "org-gtd-mode" "\
Global minor mode to bound `org-agenda' to the org-gtd settings.

This is a global minor mode.  If called interactively, toggle the
`Org-GTD mode' mode.  If the prefix argument is positive, enable
the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='org-gtd-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

(fn &optional ARG)" t)
(register-definition-prefixes "org-gtd-mode" '("org-gtd-"))


;;; Generated autoloads from org-gtd-oops.el

(register-definition-prefixes "org-gtd-oops" '("org-gtd-oops"))


;;; Generated autoloads from org-gtd-organize.el

(register-definition-prefixes "org-gtd-organize" '("org-gtd-"))


;;; Generated autoloads from org-gtd-process.el

(autoload 'org-gtd-process-inbox "org-gtd-process" "\
Start the inbox processing item, one heading at a time." t)
(register-definition-prefixes "org-gtd-process" '("org-gtd-process--stop"))


;;; Generated autoloads from org-gtd-projects.el

(autoload 'org-gtd-project-cancel "org-gtd-projects" "\
With point on topmost project heading, mark all undone tasks canceled." t)
(autoload 'org-gtd-project-cancel-from-agenda "org-gtd-projects" "\
Cancel the project that has the highlighted task." t)
(function-put 'org-gtd-project-cancel-from-agenda 'command-modes '(org-agenda-mode))
(register-definition-prefixes "org-gtd-projects" '("org-"))


;;; Generated autoloads from org-gtd-quick-action.el

(register-definition-prefixes "org-gtd-quick-action" '("org-gtd-quick-action"))


;;; Generated autoloads from org-gtd-refile.el

(register-definition-prefixes "org-gtd-refile" '("org-gtd-refile-" "with-org-gtd-refile"))


;;; Generated autoloads from org-gtd-review.el

(autoload 'org-gtd-review-area-of-focus "org-gtd-review" "\
Generate an overview agenda for a given area of focus.

You can pass an optional AREA (must be a member of `org-gtd-areas-of-focus') to
skip the menu to choose one.
START-DATE tells the code what to use as the first day for the agenda.  It is
mostly of value for testing purposes.

(fn &optional AREA START-DATE)" t)
(autoload 'org-gtd-review-stuck-projects "org-gtd-review" "\
Show all projects that do not have a next action." t)
(register-definition-prefixes "org-gtd-review" '("org-gtd-"))


;;; Generated autoloads from org-gtd-single-action.el

(register-definition-prefixes "org-gtd-single-action" '("org-gtd-"))


;;; Generated autoloads from org-gtd-skip.el

(register-definition-prefixes "org-gtd-skip" '("org-gtd-"))


;;; Generated autoloads from org-gtd-trash.el

(register-definition-prefixes "org-gtd-trash" '("org-gtd-trash"))


;;; Generated autoloads from org-gtd-upgrades.el

(register-definition-prefixes "org-gtd-upgrades" '("org-gtd-upgrade"))

;;; End of scraped data

(provide 'org-gtd-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; org-gtd-autoloads.el ends here
