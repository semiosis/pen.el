;;; evil-text-object-python-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "evil-text-object-python" "evil-text-object-python.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from evil-text-object-python.el
 (autoload 'evil-text-object-python-inner-statement "evil-text-object-python" nil t)
 (autoload 'evil-text-object-python-outer-statement "evil-text-object-python" nil t)
 (autoload 'evil-text-object-python-function "evil-text-object-python" nil t)

(autoload 'evil-text-object-python-add-bindings "evil-text-object-python" "\
Add text object key bindings.

This function should be added to a major mode hook.  It modifies
buffer-local keymaps and adds bindings for Python text objects for
both operator state and visual state." t nil)

(register-definition-prefixes "evil-text-object-python" '("evil-text-object-python-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; evil-text-object-python-autoloads.el ends here
