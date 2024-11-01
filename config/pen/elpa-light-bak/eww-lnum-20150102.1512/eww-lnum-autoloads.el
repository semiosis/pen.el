;;; eww-lnum-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "eww-lnum" "eww-lnum.el" (0 0 0 0))
;;; Generated autoloads from eww-lnum.el

(autoload 'eww-lnum-follow "eww-lnum" "\
Turn on link numbers, ask for one and execute appropriate action on it.
If link - visit it; button - press; input - move to it.
With prefix ARG visit link in new session.
With `-' prefix ARG, visit in background.
With double prefix ARG, prompt for url to visit.
With triple prefix ARG, prompt for url and visit in new session.

\(fn ARG)" t nil)

(autoload 'eww-lnum-universal "eww-lnum" "\
Turn on link numbers, ask for one and offer actions over it depending on selection.
Actions may be selected either by hitting corresponding key,
pressing <return> over the action line or left clicking." t nil)

(register-definition-prefixes "eww-lnum" '("eww-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; eww-lnum-autoloads.el ends here
