;;; helm-rg-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-rg" "helm-rg.el" (0 0 0 0))
;;; Generated autoloads from helm-rg.el

(autoload 'helm-rg "helm-rg" "\
Search for the PCRE regexp RG-PATTERN extremely quickly with ripgrep.

When invoked interactively with a prefix argument, or when PFX is non-nil,
set the cwd for the ripgrep process to `default-directory'. Otherwise use the
cwd as described by `helm-rg-default-directory'.

If PATHS is non-nil, ripgrep will search only those paths, relative to the
process's cwd. Otherwise, the process's cwd will be searched.

Note that ripgrep respects glob patterns from .gitignore, .rgignore, and .ignore
files, excluding files matching those patterns. This composes with the glob
defined by `helm-rg-default-glob-string', which only finds files matching the
glob, and can be overridden with `helm-rg--set-glob', which is defined in
`helm-rg-map'.

There are many more `defcustom' forms, which are visible by searching for \"defcustom\" in the
`helm-rg' source (which can be located using `find-function'). These `defcustom' forms set defaults
for options which can be modified while invoking `helm-rg' using the keybindings listed below.

The ripgrep command's help output can be printed into its own buffer for
reference with the interactive command `helm-rg-display-help'.

\\{helm-rg-map}

\(fn RG-PATTERN &optional PFX PATHS)" t nil)

(autoload 'helm-rg-display-help "helm-rg" "\
Display a buffer with the ripgrep command's usage help.

The help buffer will be reused if it was already created. A prefix argument when
invoked interactively, or a non-nil value for PFX, will display the help buffer
in the current window. Otherwise, if the help buffer is already being displayed
in some window, select that window, or else display the help buffer with
`pop-to-buffer'.

\(fn &optional PFX)" t nil)

(autoload 'helm-rg-from-isearch "helm-rg" "\
Invoke `helm-rg' from isearch." t nil)

(register-definition-prefixes "helm-rg" '("helm-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-rg-autoloads.el ends here
