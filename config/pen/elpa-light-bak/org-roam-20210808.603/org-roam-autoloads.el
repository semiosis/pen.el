;;; org-roam-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "org-roam" "org-roam.el" (0 0 0 0))
;;; Generated autoloads from org-roam.el

(autoload 'org-roam-setup "org-roam" "\
Setup Org-roam and initialize its database.
This will install the needed hooks and advices to keep everything
in sync with the connected databases." t nil)

(register-definition-prefixes "org-roam" '("org-roam-"))

;;;***

;;;### (autoloads nil "org-roam-capture" "org-roam-capture.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-roam-capture.el

(autoload 'org-roam-capture- "org-roam-capture" "\
Main entry point of `org-roam-capture' module.
GOTO and KEYS correspond to `org-capture' arguments.
INFO is a plist for filling up Org-roam's capture templates.
NODE is an `org-roam-node' construct containing information about the node.
PROPS is a plist containing additional Org-roam properties for each template.
TEMPLATES is a list of org-roam templates.

\(fn &key GOTO KEYS NODE INFO PROPS TEMPLATES)" nil nil)

(autoload 'org-roam-capture "org-roam-capture" "\
Launches an `org-capture' process for a new or existing node.
This uses the templates defined at `org-roam-capture-templates'.
Arguments GOTO and KEYS see `org-capture'.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.
The TEMPLATES, if provided, override the list of capture templates (see
`org-roam-capture-'.)

\(fn &optional GOTO KEYS &key FILTER-FN TEMPLATES)" t nil)

(register-definition-prefixes "org-roam-capture" '("org-roam-capture-"))

;;;***

;;;### (autoloads nil "org-roam-compat" "org-roam-compat.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from org-roam-compat.el

(register-definition-prefixes "org-roam-compat" '("org-roam--directory-files-recursively"))

;;;***

;;;### (autoloads nil "org-roam-dailies" "org-roam-dailies.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-roam-dailies.el

(autoload 'org-roam-dailies-capture-today "org-roam-dailies" "\
Create an entry in the daily-note for today.
When GOTO is non-nil, go the note without creating an entry.

\(fn &optional GOTO)" t nil)

(autoload 'org-roam-dailies-goto-today "org-roam-dailies" "\
Find the daily-note for today, creating it if necessary." t nil)

(autoload 'org-roam-dailies-capture-tomorrow "org-roam-dailies" "\
Create an entry in the daily-note for tomorrow.

With numeric argument N, use the daily-note N days in the future.

With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry.

\(fn N &optional GOTO)" t nil)

(autoload 'org-roam-dailies-goto-tomorrow "org-roam-dailies" "\
Find the daily-note for tomorrow, creating it if necessary.

With numeric argument N, use the daily-note N days in the
future.

\(fn N)" t nil)

(autoload 'org-roam-dailies-capture-yesterday "org-roam-dailies" "\
Create an entry in the daily-note for yesteday.

With numeric argument N, use the daily-note N days in the past.

When GOTO is non-nil, go the note without creating an entry.

\(fn N &optional GOTO)" t nil)

(autoload 'org-roam-dailies-goto-yesterday "org-roam-dailies" "\
Find the daily-note for yesterday, creating it if necessary.

With numeric argument N, use the daily-note N days in the
future.

\(fn N)" t nil)

(autoload 'org-roam-dailies-capture-date "org-roam-dailies" "\
Create an entry in the daily-note for a date using the calendar.
Prefer past dates, unless PREFER-FUTURE is non-nil.
With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry.

\(fn &optional GOTO PREFER-FUTURE)" t nil)

(autoload 'org-roam-dailies-goto-date "org-roam-dailies" "\
Find the daily-note for a date using the calendar, creating it if necessary.
Prefer past dates, unless PREFER-FUTURE is non-nil.

\(fn &optional PREFER-FUTURE)" t nil)

(autoload 'org-roam-dailies-find-directory "org-roam-dailies" "\
Find and open `org-roam-dailies-directory'." t nil)

(register-definition-prefixes "org-roam-dailies" '("org-roam-dailies-"))

;;;***

;;;### (autoloads nil "org-roam-db" "org-roam-db.el" (0 0 0 0))
;;; Generated autoloads from org-roam-db.el

(autoload 'org-roam-db-sync "org-roam-db" "\
Synchronize the cache state with the current Org files on-disk.
If FORCE, force a rebuild of the cache from scratch.

\(fn &optional FORCE)" t nil)

(register-definition-prefixes "org-roam-db" '("emacsql-constraint" "org-roam-"))

;;;***

;;;### (autoloads nil "org-roam-graph" "org-roam-graph.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from org-roam-graph.el

(autoload 'org-roam-graph "org-roam-graph" "\
Build and possibly display a graph for NODE.
ARG may be any of the following values:
  - nil       show the graph.
  - `\\[universal-argument]'     show the graph for NODE.
  - `\\[universal-argument]' N   show the graph for NODE limiting nodes to N steps.

\(fn &optional ARG NODE)" t nil)

(register-definition-prefixes "org-roam-graph" '("org-roam-graph-"))

;;;***

;;;### (autoloads nil "org-roam-migrate" "org-roam-migrate.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-roam-migrate.el

(autoload 'org-roam-migrate-wizard "org-roam-migrate" "\
Migrate all notes from to be compatible with Org-roam v2.
1. Convert all notes from v1 format to v2.
2. Rebuild the cache.
3. Replace all file links with ID links." t nil)

(register-definition-prefixes "org-roam-migrate" '("org-roam-"))

;;;***

;;;### (autoloads nil "org-roam-mode" "org-roam-mode.el" (0 0 0 0))
;;; Generated autoloads from org-roam-mode.el

(autoload 'org-roam-buffer-display-dedicated "org-roam-mode" "\
Launch NODE dedicated Org-roam buffer.
Unlike the persistent `org-roam-buffer', the contents of this
buffer won't be automatically changed and will be held in place.

In interactive calls prompt to select NODE, unless called with
`universal-argument', in which case NODE will be set to
`org-roam-node-at-point'.

\(fn NODE)" t nil)

(register-definition-prefixes "org-roam-mode" '("org-roam-"))

;;;***

;;;### (autoloads nil "org-roam-node" "org-roam-node.el" (0 0 0 0))
;;; Generated autoloads from org-roam-node.el

(autoload 'org-roam-node-find "org-roam-node" "\
Find and open an Org-roam node by its title or alias.
INITIAL-INPUT is the initial input for the prompt.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.
If OTHER-WINDOW, visit the NODE in another window.
The TEMPLATES, if provided, override the list of capture templates (see
`org-roam-capture-'.)

\(fn &optional OTHER-WINDOW INITIAL-INPUT FILTER-FN &key TEMPLATES)" t nil)

(autoload 'org-roam-node-random "org-roam-node" "\
Find and open a random Org-roam node.
With prefix argument OTHER-WINDOW, visit the node in another
window instead.

\(fn &optional OTHER-WINDOW)" t nil)

(autoload 'org-roam-node-insert "org-roam-node" "\
Find an Org-roam node and insert (where the point is) an \"id:\" link to it.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.
The TEMPLATES, if provided, override the list of capture templates (see
`org-roam-capture-'.)

\(fn &optional FILTER-FN &key TEMPLATES)" t nil)

(autoload 'org-roam-refile "org-roam-node" "\
Refile node at point to an Org-roam node.
If region is active, then use it instead of the node at point." t nil)

(autoload 'org-roam-extract-subtree "org-roam-node" "\
Convert current subtree at point to a node, and extract it into a new file." t nil)

(autoload 'org-roam-ref-find "org-roam-node" "\
Find and open an Org-roam node that's dedicated to a specific ref.
INITIAL-INPUT is the initial input to the prompt.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.

\(fn &optional INITIAL-INPUT FILTER-FN)" t nil)

(register-definition-prefixes "org-roam-node" '("org-roam-"))

;;;***

;;;### (autoloads nil "org-roam-overlay" "org-roam-overlay.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-roam-overlay.el

(register-definition-prefixes "org-roam-overlay" '("org-roam-overlay-"))

;;;***

;;;### (autoloads nil "org-roam-protocol" "org-roam-protocol.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from org-roam-protocol.el

(register-definition-prefixes "org-roam-protocol" '("org-roam-"))

;;;***

;;;### (autoloads nil "org-roam-utils" "org-roam-utils.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from org-roam-utils.el

(autoload 'org-roam-version "org-roam-utils" "\
Return `org-roam' version.
Interactively, or when MESSAGE is non-nil, show in the echo area.

\(fn &optional MESSAGE)" t nil)

(autoload 'org-roam-diagnostics "org-roam-utils" "\
Collect and print info for `org-roam' issues." t nil)

(register-definition-prefixes "org-roam-utils" '("org-roam-"))

;;;***

;;;### (autoloads nil nil ("org-roam-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; org-roam-autoloads.el ends here
