;;; alarm-clock-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "alarm-clock" "alarm-clock.el" (0 0 0 0))
;;; Generated autoloads from alarm-clock.el

(autoload 'alarm-clock-set "alarm-clock" "\
Set an alarm clock at time TIME.
MESSAGE will be shown when notifying in the status bar.

\(fn TIME MESSAGE)" t nil)

(autoload 'alarm-clock-list-view "alarm-clock" "\
Display the alarm clocks." t nil)

(autoload 'alarm-clock-restore "alarm-clock" "\
Restore alarm clocks on startup." t nil)

(autoload 'alarm-clock-save "alarm-clock" "\
Save alarm clocks to local file." t nil)

(register-definition-prefixes "alarm-clock" '("alarm-clock-"))

;;;***

;;;### (autoloads nil nil ("alarm-clock-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; alarm-clock-autoloads.el ends here
