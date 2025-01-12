;;; notmuch-bookmarks-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "flycheck_notmuch-bookmarks" "flycheck_notmuch-bookmarks.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from flycheck_notmuch-bookmarks.el

(autoload 'notmuch-bookmarks-jump-handler "flycheck_notmuch-bookmarks" "\
Open BOOKMARK or switch to its visiting buffer.

\(fn BOOKMARK)" nil nil)

(autoload 'notmuch-bookmarks-edit-name "flycheck_notmuch-bookmarks" "\
Edit current buffer's bookmark name.

\(fn BOOKMARK-NAME)" t nil)

(autoload 'notmuch-bookmarks-edit-query "flycheck_notmuch-bookmarks" "\
Edit current buffer's bookmark query.

\(fn BOOKMARK-NAME)" t nil)

(defvar notmuch-bookmarks-mode nil "\
Non-nil if Notmuch-Bookmarks mode is enabled.
See the `notmuch-bookmarks-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `notmuch-bookmarks-mode'.")

(custom-autoload 'notmuch-bookmarks-mode "flycheck_notmuch-bookmarks" nil)

(autoload 'notmuch-bookmarks-mode "flycheck_notmuch-bookmarks" "\
Add notmuch specific bookmarks to the bookmarking system.

This is a minor mode.  If called interactively, toggle the
`Notmuch-Bookmarks mode' mode.  If the prefix argument is
positive, enable the mode, and if it is zero or negative, disable
the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='notmuch-bookmarks-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(defvar notmuch-bookmarks-annotation-mode nil "\
Non-nil if Notmuch-Bookmarks-Annotation mode is enabled.
See the `notmuch-bookmarks-annotation-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `notmuch-bookmarks-annotation-mode'.")

(custom-autoload 'notmuch-bookmarks-annotation-mode "flycheck_notmuch-bookmarks" nil)

(autoload 'notmuch-bookmarks-annotation-mode "flycheck_notmuch-bookmarks" "\
Add annotations for notmuch bookmarks.

This is a minor mode.  If called interactively, toggle the
`Notmuch-Bookmarks-Annotation mode' mode.  If the prefix argument
is positive, enable the mode, and if it is zero or negative,
disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='notmuch-bookmarks-annotation-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "flycheck_notmuch-bookmarks" '("notmuch-bookmarks-"))

;;;***

;;;### (autoloads nil "notmuch-bookmarks" "notmuch-bookmarks.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from notmuch-bookmarks.el

(autoload 'notmuch-bookmarks-jump-handler "notmuch-bookmarks" "\
Open BOOKMARK or switch to its visiting buffer.

\(fn BOOKMARK)" nil nil)

(autoload 'notmuch-bookmarks-edit-name "notmuch-bookmarks" "\
Edit current buffer's bookmark name.

\(fn BOOKMARK-NAME)" t nil)

(autoload 'notmuch-bookmarks-edit-query "notmuch-bookmarks" "\
Edit current buffer's bookmark query.

\(fn BOOKMARK-NAME)" t nil)

(defvar notmuch-bookmarks-mode nil "\
Non-nil if Notmuch-Bookmarks mode is enabled.
See the `notmuch-bookmarks-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `notmuch-bookmarks-mode'.")

(custom-autoload 'notmuch-bookmarks-mode "notmuch-bookmarks" nil)

(autoload 'notmuch-bookmarks-mode "notmuch-bookmarks" "\
Add notmuch specific bookmarks to the bookmarking system.

This is a minor mode.  If called interactively, toggle the
`Notmuch-Bookmarks mode' mode.  If the prefix argument is
positive, enable the mode, and if it is zero or negative, disable
the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='notmuch-bookmarks-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(defvar notmuch-bookmarks-annotation-mode nil "\
Non-nil if Notmuch-Bookmarks-Annotation mode is enabled.
See the `notmuch-bookmarks-annotation-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `notmuch-bookmarks-annotation-mode'.")

(custom-autoload 'notmuch-bookmarks-annotation-mode "notmuch-bookmarks" nil)

(autoload 'notmuch-bookmarks-annotation-mode "notmuch-bookmarks" "\
Add annotations for notmuch bookmarks.

This is a minor mode.  If called interactively, toggle the
`Notmuch-Bookmarks-Annotation mode' mode.  If the prefix argument
is positive, enable the mode, and if it is zero or negative,
disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='notmuch-bookmarks-annotation-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "notmuch-bookmarks" '("notmuch-bookmarks-"))

;;;***


;;; Generated autoloads from notmuch-bookmarks.el

(autoload 'notmuch-bookmarks-jump-handler "notmuch-bookmarks" "\
Open BOOKMARK or switch to its visiting buffer.

(fn BOOKMARK)")
(autoload 'notmuch-bookmarks-edit-name "notmuch-bookmarks" "\
Edit current buffer's bookmark name.

(fn BOOKMARK-NAME)" t)
(autoload 'notmuch-bookmarks-edit-query "notmuch-bookmarks" "\
Edit current buffer's bookmark query.

(fn BOOKMARK-NAME)" t)
(defvar notmuch-bookmarks-mode nil "\
Non-nil if Notmuch-Bookmarks mode is enabled.
See the `notmuch-bookmarks-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `notmuch-bookmarks-mode'.")
(custom-autoload 'notmuch-bookmarks-mode "notmuch-bookmarks" nil)
(autoload 'notmuch-bookmarks-mode "notmuch-bookmarks" "\
Add notmuch specific bookmarks to the bookmarking system.

This is a global minor mode.  If called interactively, toggle the
`Notmuch-Bookmarks mode' mode.  If the prefix argument is
positive, enable the mode,  and if it is zero or negative,
disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='notmuch-bookmarks-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

(fn &optional ARG)" t)
(defvar notmuch-bookmarks-annotation-mode nil "\
Non-nil if Notmuch-Bookmarks-Annotation mode is enabled.
See the `notmuch-bookmarks-annotation-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `notmuch-bookmarks-annotation-mode'.")
(custom-autoload 'notmuch-bookmarks-annotation-mode "notmuch-bookmarks" nil)
(autoload 'notmuch-bookmarks-annotation-mode "notmuch-bookmarks" "\
Add annotations for notmuch bookmarks.

This is a global minor mode.  If called interactively, toggle the
`Notmuch-Bookmarks-Annotation mode' mode.  If the prefix argument
is positive, enable the mode,  and if it is zero or negative,
disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='notmuch-bookmarks-annotation-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

(fn &optional ARG)" t)
(register-definition-prefixes "notmuch-bookmarks" '("notmuch-bookmarks-"))

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; notmuch-bookmarks-autoloads.el ends here
