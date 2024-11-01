;;; helm-circe-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-circe" "helm-circe.el" (0 0 0 0))
;;; Generated autoloads from helm-circe.el

(autoload 'helm-circe "helm-circe" "\
Custom helm buffer for circe channel and server buffers only." t nil)

(autoload 'helm-circe-new-activity "helm-circe" "\
Displays a candidate list of channels with new activity since last view" t nil)

(autoload 'helm-circe-by-server "helm-circe" "\
Displays a candidate list of channels by listed by server" t nil)

(autoload 'helm-circe-channels "helm-circe" "\
Displays a candidate list consisting of all channels from every server" t nil)

(autoload 'helm-circe-servers "helm-circe" "\
Displays a candidate list consiting of all servers" t nil)

(autoload 'helm-circe-queries "helm-circe" "\
Displays a candidate list consistin of all queries" t nil)

(register-definition-prefixes "helm-circe" '("helm-circe/"))

;;;***

;;;### (autoloads nil nil ("helm-circe-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-circe-autoloads.el ends here
