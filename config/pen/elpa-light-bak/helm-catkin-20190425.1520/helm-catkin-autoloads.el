;;; helm-catkin-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-catkin" "helm-catkin.el" (0 0 0 0))
;;; Generated autoloads from helm-catkin.el

(autoload 'helm-catkin-no-workspace "helm-catkin" "\
Clear the `helm-catkin-workspace' variable.
This can be used to fallback to \"per-buffer\" workspaces." t nil)

(autoload 'helm-catkin-set-workspace "helm-catkin" "\
Prompt to set the current catkin workspace to `helm-catkin-workspace'." t nil)

(autoload 'helm-catkin-init "helm-catkin" "\
(Re-)Initialize a catkin workspace at PATH.
If PATH is nil tries to initialize `helm-catkin-workspace'. If this is
also nil, the folder containing the current buffer will be used as workspace.
Creates the folder if it does not exist and also a child 'src' folder.

\(fn &optional PATH)" t nil)

(autoload 'helm-catkin-clean "helm-catkin" "\
Clean the build/ devel/ and install/ folder for the catkin workspace." t nil)

(autoload 'helm-catkin-config-show "helm-catkin" "\
Print the current configuration of the catkin workspace.
The config goes to a new buffer called *Catkin Config*. This can be dismissed by pressing `q'." t nil)

(autoload 'helm-catkin-config-open "helm-catkin" "\
Open the config file for the default profile of the catkin workspace." nil nil)

(autoload 'helm-catkin-config-set-devel-layout "helm-catkin" "\
Set the devel layout to either 'link', 'merge' or 'isolate'.
Prompt the user if TYPE is nil.

\(fn &optional TYPE)" t nil)

(autoload 'helm-catkin "helm-catkin" "\
Helm command for catkin.
For more information use `C-h v helm-catkin-helm-help-message' or
press `C-c ?' in the helm-catkin helm query.

See `helm-catkin-helm-help-string'" t nil)

(autoload 'helm-catkin-build "helm-catkin" "\
Prompt the user via a helm dialog to select one or more packages to build.

  See `helm-catkin-helm-help-string'" t nil)

(register-definition-prefixes "helm-catkin" '("helm-catkin-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-catkin-autoloads.el ends here
