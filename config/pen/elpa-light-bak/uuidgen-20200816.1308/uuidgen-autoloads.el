;;; uuidgen-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "uuidgen" "uuidgen.el" (0 0 0 0))
;;; Generated autoloads from uuidgen.el

(autoload 'insert-uuid-cid "uuidgen" "\
Insert UUID string in CID format that is suitable for COM definition.
If UUID is nil will generate UUIDGEN-4 automatically.
You customize `uuidgen-cid-format-string' to change the default format.

\(fn UUID)" t nil)

(autoload 'uuidgen "uuidgen" "\
Insert UUIDv4 at point. If TIME-BASED is non-nil, insert UUIDv1 instead.

\(fn TIME-BASED)" t nil)

(register-definition-prefixes "uuidgen" '("uuidgen-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; uuidgen-autoloads.el ends here
