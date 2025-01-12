;;; ement-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ement" "ement.el" (0 0 0 0))
;;; Generated autoloads from ement.el

(autoload 'ement-connect "ement" "\
Connect to Matrix with USER-ID and PASSWORD, or using SESSION.
Interactively, with prefix, ignore a saved session and log in
again; otherwise, use a saved session if `ement-save-sessions' is
enabled and a saved session is available, or prompt to log in if
not enabled or available.

If USERID or PASSWORD are not specified, the user will be
prompted for them.

If URI-PREFIX is specified, it should be the prefix of the
server's API URI, including protocol, hostname, and optionally
the port, e.g.

  \"https://matrix-client.matrix.org\"
  \"http://localhost:8080\"

\(fn &key USER-ID PASSWORD URI-PREFIX SESSION)" t nil)

(register-definition-prefixes "ement" '("ement-"))

;;;***

;;;### (autoloads nil "ement-api" "ement-api.el" (0 0 0 0))
;;; Generated autoloads from ement-api.el

(register-definition-prefixes "ement-api" '("ement-api-error"))

;;;***

;;;### (autoloads nil "ement-lib" "ement-lib.el" (0 0 0 0))
;;; Generated autoloads from ement-lib.el

(register-definition-prefixes "ement-lib" '("ement-"))

;;;***

;;;### (autoloads nil "ement-macros" "ement-macros.el" (0 0 0 0))
;;; Generated autoloads from ement-macros.el

(register-definition-prefixes "ement-macros" '("ement-"))

;;;***

;;;### (autoloads nil "ement-notify" "ement-notify.el" (0 0 0 0))
;;; Generated autoloads from ement-notify.el

(register-definition-prefixes "ement-notify" '("ement-notify"))

;;;***

;;;### (autoloads nil "ement-room" "ement-room.el" (0 0 0 0))
;;; Generated autoloads from ement-room.el

(register-definition-prefixes "ement-room" '("ement-"))

;;;***

;;;### (autoloads nil "ement-room-list" "ement-room-list.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from ement-room-list.el

(autoload 'ement-room-list "ement-room-list" "\
Show buffer listing joined rooms.
Calls `pop-to-buffer-same-window'.  Interactively, with prefix,
call `pop-to-buffer'.

\(fn &rest IGNORE)" t nil)

(defalias 'ement-list-rooms 'ement-room-list)

(autoload 'ement-room-list-auto-update "ement-room-list" "\
Automatically update the room list buffer.
Does so when variable `ement-room-list-auto-update' is non-nil.
To be called in `ement-sync-callback-hook'.

\(fn SESSION)" nil nil)

(register-definition-prefixes "ement-room-list" '("ement-room-list-"))

;;;***

;;;### (autoloads nil "ement-taxy" "ement-taxy.el" (0 0 0 0))
;;; Generated autoloads from ement-taxy.el

(autoload 'ement-taxy-room-list "ement-taxy" "\
Show a buffer listing Ement rooms, grouped with Taxy KEYS.
The buffer is named BUFFER-NAME and is shown with
DISPLAY-BUFFER-ACTION.

\(fn &key (BUFFER-NAME \"*Ement Taxy*\") (KEYS ement-taxy-default-keys) (DISPLAY-BUFFER-ACTION \\='(display-buffer-same-window)))" t nil)

(autoload 'ement-taxy-auto-update "ement-taxy" "\
Automatically update the Taxy room list buffer.
+Does so when variable `ement-taxy-auto-update' is non-nil.
+To be called in `ement-sync-callback-hook'.

\(fn SESSION)" nil nil)

(register-definition-prefixes "ement-taxy" '("ement-taxy-"))

;;;***

;;;### (autoloads nil nil ("ement-pkg.el" "ement-structs.el") (0
;;;;;;  0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ement-autoloads.el ends here
