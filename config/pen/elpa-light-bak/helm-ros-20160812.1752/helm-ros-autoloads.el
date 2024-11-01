;;; helm-ros-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-ros" "helm-ros.el" (0 0 0 0))
;;; Generated autoloads from helm-ros.el

(autoload 'ros-process-mode "helm-ros" "\
Major mode for handling the output of ROS processes.

\(fn)" t nil)

(autoload 'helm-ros-set-master-uri "helm-ros" "\
Set the ROS_MASTER_URI environment variable to URI

\(fn URI)" t nil)

(autoload 'helm-ros-roscore "helm-ros" "\
Start a roscore in the *roscore* buffer.  Create it if it doesn't exist." t nil)

(autoload 'helm-ros-launchfiles "helm-ros" "\
Launch helm with ros launchfiles as the only source." t nil)

(autoload 'helm-ros-run-node "helm-ros" "\
Run ros NODE that is in PACKAGE.

\(fn PACKAGE NODE)" t nil)

(autoload 'helm-ros-rosnode-info "helm-ros" "\
Print the informations of NODE.

\(fn NODE)" t nil)

(autoload 'helm-ros-kill-node "helm-ros" "\
Kill the process of NODE.

\(fn NODE)" t nil)

(autoload 'helm-ros-rosnode-list "helm-ros" "\
Print a list of running nodes in a new buffer." t nil)

(autoload 'helm-ros-rostopic-list "helm-ros" nil t nil)

(autoload 'helm-ros-rostopic-echo "helm-ros" "\
Echo TOPIC in a new buffer.

\(fn TOPIC)" t nil)

(autoload 'helm-ros-rostopic-hz "helm-ros" "\
Run ros topic hz on TOPIC.

\(fn TOPIC)" t nil)

(autoload 'helm-ros-rostopic-info "helm-ros" "\
Run rostopic info on TOPIC.

\(fn TOPIC)" t nil)

(autoload 'helm-ros-topics "helm-ros" nil t nil)

(autoload 'helm-ros "helm-ros" "\
Launch ros-helm with all available sources." t nil)

(autoload 'helm-ros-invalidate-cache "helm-ros" "\
Invalidates the cache of all helm-ros sources." t nil)

(defvar global-helm-ros-mode t "\
Non-nil if Global Helm-Ros mode is enabled.
See the `global-helm-ros-mode' command
for a description of this minor mode.")

(custom-autoload 'global-helm-ros-mode "helm-ros" nil)

(autoload 'global-helm-ros-mode "helm-ros" "\
A minor mode that enables the keybindings for helm-ros.

If called interactively, toggle `Global Helm-Ros mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "helm-ros" '("helm-" "ros-process-mode-"))

;;;***

;;;### (autoloads nil nil ("helm-ros-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-ros-autoloads.el ends here
