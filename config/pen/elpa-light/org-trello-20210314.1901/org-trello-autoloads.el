;;; org-trello-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "org-trello" "org-trello.el" (0 0 0 0))
;;; Generated autoloads from org-trello.el

(autoload 'org-trello-version "org-trello" "\
Org-trello version." t nil)

(autoload 'org-trello-abort-sync "org-trello" "\
Control first, then if ok, add a comment to the current card." t nil)

(autoload 'org-trello-add-card-comment "org-trello" "\
Control first, then if ok, add a comment to the current card.
When FROM is set, this will delete the current card's comments.

\(fn &optional FROM)" t nil)

(autoload 'org-trello-delete-card-comment "org-trello" "\
Control first, then if ok, delete the comment at point.
This will only work if you are the owner of the comment." t nil)

(autoload 'org-trello-show-board-labels "org-trello" "\
Control, then if ok, show a simple buffer with the current board's labels." t nil)

(autoload 'org-trello-sync-card "org-trello" "\
Execute the sync of an entity and its structure to trello.
If FROM is non nil, execute the sync entity and its structure from trello.

\(fn &optional FROM)" t nil)

(autoload 'org-trello-sync-comment "org-trello" "\
Execute the sync of the card's comment at point.
If FROM is non nil, remove the comment at point.

\(fn &optional FROM)" t nil)

(autoload 'org-trello-sync-buffer "org-trello" "\
Execute the sync of the entire buffer to trello.
If FROM is non nil, execute the sync of the entire buffer from trello.

\(fn &optional FROM)" t nil)

(autoload 'org-trello-kill-entity "org-trello" "\
Execute the entity removal from trello and the buffer.
If FROM is non nil, execute all entities removal from trello and buffer.

\(fn &optional FROM)" t nil)

(autoload 'org-trello-kill-cards "org-trello" "\
Execute all entities removal from trello and buffer." t nil)

(autoload 'org-trello-archive-card "org-trello" "\
Execute archive card at point." t nil)

(autoload 'org-trello-archive-cards "org-trello" "\
Execute archive all the DONE cards from buffer." t nil)

(autoload 'org-trello-install-key-and-token "org-trello" "\
No control, trigger setup installation of key and read/write token." t nil)

(autoload 'org-trello-install-board-metadata "org-trello" "\
Control, if ok, trigger setup installation of trello board to sync with." t nil)

(autoload 'org-trello-update-board-metadata "org-trello" "\
Control first, then if ok, trigger the update of the informations about the board." t nil)

(autoload 'org-trello-jump-to-trello-card "org-trello" "\
Jump from current card to trello card in browser.
If FROM is not nil, jump from current card to board.

\(fn &optional FROM)" t nil)

(autoload 'org-trello-jump-to-trello-board "org-trello" "\
Jump to current trello board." t nil)

(autoload 'org-trello-create-board-and-install-metadata "org-trello" "\
Control first, then if ok, trigger the board creation." t nil)

(autoload 'org-trello-assign-me "org-trello" "\
Assign oneself to the card.
If UNASSIGN is not nil, unassign oneself from the card.

\(fn &optional UNASSIGN)" t nil)

(autoload 'org-trello-toggle-assign-me "org-trello" "\
Toggling assign/unassign oneself to a card." t nil)

(autoload 'org-trello-toggle-assign-user "org-trello" "\
Toggling assign one user to a card." t nil)

(autoload 'org-trello-check-setup "org-trello" "\
Check the current setup." t nil)

(autoload 'org-trello-delete-setup "org-trello" "\
Delete the current setup." t nil)

(autoload 'org-trello-help-describing-bindings "org-trello" "\
A simple message to describe the standard bindings used." t nil)

(autoload 'org-trello-clean-org-trello-data "org-trello" "\
Clean up org-trello data." t nil)

(autoload 'org-trello-close-board "org-trello" "\
Propose a list of board to and let the user choose which to close." t nil)

(autoload 'org-trello-mode "org-trello" "\
Sync your org-mode and your trello together.

If called interactively, toggle `Org-Trello mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "org-trello" '("org-trello"))

;;;***

;;;### (autoloads nil "org-trello-action" "org-trello-action.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from org-trello-action.el

(register-definition-prefixes "org-trello-action" '("orgtrello-action-"))

;;;***

;;;### (autoloads nil "org-trello-api" "org-trello-api.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from org-trello-api.el

(register-definition-prefixes "org-trello-api" '("orgtrello-api-"))

;;;***

;;;### (autoloads nil "org-trello-backend" "org-trello-backend.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from org-trello-backend.el

(register-definition-prefixes "org-trello-backend" '("orgtrello-backend-"))

;;;***

;;;### (autoloads nil "org-trello-buffer" "org-trello-buffer.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from org-trello-buffer.el

(register-definition-prefixes "org-trello-buffer" '("orgtrello-buffer-"))

;;;***

;;;### (autoloads nil "org-trello-cbx" "org-trello-cbx.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from org-trello-cbx.el

(register-definition-prefixes "org-trello-cbx" '("orgtrello-cbx-"))

;;;***

;;;### (autoloads nil "org-trello-controller" "org-trello-controller.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from org-trello-controller.el

(register-definition-prefixes "org-trello-controller" '("orgtrello-controller-"))

;;;***

;;;### (autoloads nil "org-trello-data" "org-trello-data.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from org-trello-data.el

(register-definition-prefixes "org-trello-data" '("orgtrello-"))

;;;***

;;;### (autoloads nil "org-trello-date" "org-trello-date.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from org-trello-date.el

(register-definition-prefixes "org-trello-date" '("orgtrello-date-"))

;;;***

;;;### (autoloads nil "org-trello-deferred" "org-trello-deferred.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from org-trello-deferred.el

(register-definition-prefixes "org-trello-deferred" '("orgtrello-deferred-"))

;;;***

;;;### (autoloads nil "org-trello-entity" "org-trello-entity.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from org-trello-entity.el

(register-definition-prefixes "org-trello-entity" '("orgtrello-entity-"))

;;;***

;;;### (autoloads nil "org-trello-hash" "org-trello-hash.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from org-trello-hash.el

(register-definition-prefixes "org-trello-hash" '("orgtrello-hash-"))

;;;***

;;;### (autoloads nil "org-trello-input" "org-trello-input.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-trello-input.el

(register-definition-prefixes "org-trello-input" '("orgtrello-input-"))

;;;***

;;;### (autoloads nil "org-trello-log" "org-trello-log.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from org-trello-log.el

(register-definition-prefixes "org-trello-log" '("orgtrello-log-"))

;;;***

;;;### (autoloads nil "org-trello-proxy" "org-trello-proxy.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-trello-proxy.el

(register-definition-prefixes "org-trello-proxy" '("orgtrello-proxy-"))

;;;***

;;;### (autoloads nil "org-trello-query" "org-trello-query.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-trello-query.el

(register-definition-prefixes "org-trello-query" '("orgtrello-query-"))

;;;***

;;;### (autoloads nil "org-trello-setup" "org-trello-setup.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-trello-setup.el

(defvar org-trello-current-prefix-keybinding nil "\
The default prefix keybinding to execute org-trello commands.")

(custom-autoload 'org-trello-current-prefix-keybinding "org-trello-setup" nil)

(register-definition-prefixes "org-trello-setup" '("*ORGTRELLO/MODE-PREFIX-KEYBINDING*" "*org-trello-interactive-command-binding-couples*" "org"))

;;;***

;;;### (autoloads nil "org-trello-utils" "org-trello-utils.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from org-trello-utils.el

(register-definition-prefixes "org-trello-utils" '("orgtrello-utils-"))

;;;***

;;;### (autoloads nil nil ("org-trello-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; org-trello-autoloads.el ends here
