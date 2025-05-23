;;; org-multi-wiki-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from org-multi-wiki.el

(defvar org-multi-wiki-global-mode nil "\
Non-nil if Org-Multi-Wiki-Global mode is enabled.
See the `org-multi-wiki-global-mode' command
for a description of this minor mode.")
(custom-autoload 'org-multi-wiki-global-mode "org-multi-wiki" nil)
(autoload 'org-multi-wiki-global-mode "org-multi-wiki" "\
Toggle Org-Multi-Wiki-Global mode on or off.

This is a global minor mode.  If called interactively, toggle the
`Org-Multi-Wiki-Global mode' mode.  If the prefix argument is
positive, enable the mode,  and if it is zero or negative,
disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='org-multi-wiki-global-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

(fn &optional ARG)" t)
(autoload 'org-multi-wiki-add-namespaces "org-multi-wiki" "\
Add entries to `org-multi-wiki-namespace-list'.

This is a convenient function for adding an entry to the namespace list.

NAMESPACES should be a list of entries to add to the
variable. There won't be duplicate namespaces, and hooks for the
variable is run if necessary.

(fn NAMESPACES)")
(autoload 'org-multi-wiki-entry-file-p "org-multi-wiki" "\
Check if FILE is a wiki entry.

If the file is a wiki entry, this functions returns a plist.

If FILE is omitted, the current buffer is assumed.

(fn &optional FILE)")
(defsubst org-multi-wiki-recentf-file-p (filename) "\
Test if FILENAME matches the recentf exclude pattern.

This is not exactly the same as
`org-multi-wiki-entry-file-p'. This one tries to be faster by
using a precompiled regular expression, at the cost of accuracy." (when org-multi-wiki-recentf-regexp (string-match-p org-multi-wiki-recentf-regexp filename)))
(autoload 'org-multi-wiki-in-namespace-p "org-multi-wiki" "\
Check if a file/directory is in a particular namespace.

This checks if the directory is in/on a wiki NAMESPACE, which is
a symbol. If the directory is in/on the namespace, this function
returns non-nil.

By default, the directory is `default-directory', but you can
explicitly give it as DIR.

(fn NAMESPACE &optional DIR)")
(autoload 'org-multi-wiki-entry-files "org-multi-wiki" "\
Get a list of Org files in a namespace.

If NAMESPACE is omitted, the current namespace is used, as in
`org-multi-wiki-directory'.

If AS-BUFFERS is non-nil, this function returns a list of buffers
instead of file names.

(fn &optional NAMESPACE &key AS-BUFFERS)")
(autoload 'org-multi-wiki-follow-link "org-multi-wiki" "\
Follow a wiki LINK.

(fn LINK)")
(autoload 'org-multi-wiki-store-link "org-multi-wiki" "\
Store a link.")
(autoload 'org-multi-wiki-switch "org-multi-wiki" "\
Set the current wiki to NAMESPACE.

(fn NAMESPACE)" t)
(autoload 'org-multi-wiki-visit-entry "org-multi-wiki" "\
Visit an entry of the heading.

HEADING in the root heading of an Org file to create or look
for. It looks for an existing entry in NAMESPACE or create a new
one if none. A file is determined based on
`org-multi-wiki-escape-file-name-fn', unless you explicitly
specify a FILENAME.

(fn HEADING &key NAMESPACE FILENAME)" t)
(autoload 'org-multi-wiki-create-entry-from-subtree "org-multi-wiki" "\
Create a new entry from the current subtree.

This command creates a new entry in the selected NAMESPACE, from
an Org subtree outside of any wiki.

After successful operation, the original subtree is deleted from
the source file.

(fn NAMESPACE)" t)
(register-definition-prefixes "org-multi-wiki" '("org-multi-wiki-"))

;;; End of scraped data

(provide 'org-multi-wiki-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; org-multi-wiki-autoloads.el ends here
