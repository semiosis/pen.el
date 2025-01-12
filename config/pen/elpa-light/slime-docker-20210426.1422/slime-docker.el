;;; slime-docker.el --- Integration of SLIME with Docker containers -*- lexical-binding: t; -*-

;; URL: https://gitlab.common-lisp.net/cl-docker-images/slime-docker
;; Package-Requires: ((emacs "24.4") (slime "2.16") (docker-tramp "0.1"))
;; Keywords: docker, lisp, slime
;; Version: 0.8.3


;;; License:

;;  GPLv2+

;;  Copyright (c) 2016-2021 Eric Timmons

;;  This program is free software; you can redistribute it and/or modify it
;;  under the terms of the GNU General Public License as published by the Free
;;  Software Foundation; either version 2 of the License, or (at your option)
;;  any later version.

;;  This program is distributed in the hope that it will be useful, but WITHOUT
;;  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;;  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;;  more details.

;;  You should have received a copy of the GNU General Public License along with
;;  this program; if not, write to the Free Software Foundation, Inc., 51
;;  Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


;;; Commentary:

;; slime-docker provides an easy bridge between SLIME and Lisps running in
;; Docker containers.  It can launch a container from an image, start a Lisp,
;; connect to it using SLIME, and set up filename translations (if the
;; slime-tramp contrib is enabled).
;;
;; To get started, describe the Lisp implementations and Docker images you want
;; to use in the variable `slime-docker-implementations'.  Then, run
;; `slime-docker' and away you go.
;;
;; The default image used by this package is clfoundation/cl-devel:latest
;; (https://hub.docker.com/r/clfoundation/cl-devel/)
;;
;; SLIME is hard to use directly with Docker containers because its
;; initialization routine is not very flexible.  It requires that both Lisp and
;; Emacs have access to the same filesystem (so the port Swank is listening on
;; can be shared) and that the port Swank listens on is the same port to which
;; SLIME has to connect.  Neither of these are necessarily true with Docker.
;;
;; This works around this by watching the stdout of the Lisp process to figure
;; out when Swank is ready to accept connections.  It also queries the Docker
;; daemon to determine which port 4005 has been forwarded to.

;;; Code:

(require 'slime)
(require 'docker-tramp)
(require 'cl-lib)


;;;; Variable Definitions

(defvar slime-docker-implementations nil
  "A list of known Lisp implementations running on Docker.
The list should have the form:
  ((NAME (PROGRAM PROGRAM-ARGS ...) &key KEYWORD-ARGS) ...)

NAME is a symbol for the implementation.

PROGRAM and PROGRAM-ARGS are strings used to start
the Lisp
process inside the Docker container.

For KEYWORD-ARGS see `slime-docker-start'")

(defvar slime-docker-default-lisp nil
  "The name of the default Lisp implementation for `slime-docker'.
See `slime-docker-implementations'")

(defvar slime-docker--cid nil
  "A buffer local variable in the inferior proccess.")

(defvar slime-docker--cid-file nil
  "A buffer local variable in the inferior proccess.")

(defvar slime-docker--inferior-lisp-program-history '()
  "History list of command strings.  Used by `slime-docker'.")

(defvar slime-docker--path nil
  "Directory containing the slime-docker package.
The default value is automatically computed from the location of
the Emacs Lisp package.")
(setq slime-docker--path (file-name-directory load-file-name))

(defgroup slime-docker nil
  "The slime-docker group."
  :group 'slime)

(defcustom slime-docker-ensure-mount-folders-exist t
  "If non-NIL, ensure that mounted folders exist before starting container.

This ensures those folders are created owned by the current user
instead of root (which is the case if docker has to make the
folder)."
  :type 'boolean :group 'slime-docker)

(defcustom slime-docker-program nil
  "The default program to run in the container."
  :type '(choice (const :tag "Use `inferior-lisp-program'" nil)
                 string)
  :group 'slime-docker)

(defcustom slime-docker-program-args nil
  "The default arguments for the program to run in the container."
  :type '(repeat string)
  :group 'slime-docker)

(defcustom slime-docker-directory nil
  "The default working directory in the container."
  :type 'string
  :group 'slime-docker)

(defcustom slime-docker-image-name "clfoundation/cl-devel"
  "The default image to use."
  :type 'string
  :group 'slime-docker)

(defcustom slime-docker-image-tag "latest"
  "The default image tag."
  :type 'string
  :group 'slime-docker)

(defcustom slime-docker-rm t
  "If non-NIL, the container is removed after the Lisp is exited."
  :type 'boolean
  :group 'slime-docker)

(defcustom slime-docker-env nil
  "The default environment to start the container with."
  :type '(alist :key-type string :value-type string)
  :group 'slime-docker)

(defcustom slime-docker-mounts nil
  "The default mounts for the container."
  :type '(repeat
          (list (cons string string)
                (plist :key-type (const :read-only)
                       :value-type boolean)))
  :group 'slime-docker)

(defcustom slime-docker-slime-mount-path "/usr/local/share/common-lisp/source/slime/"
  "Where to mount the SLIME source code in the container."
  :type 'string
  :group 'slime-docker)

(defcustom slime-docker-slime-mount-read-only t
  "If non-NIL, SLIME is mounted into the container as read only."
  :type 'boolean
  :group 'slime-docker)

(defcustom slime-docker-docker-machine nil
  "If non-NIL, names the default docker-machine instance."
  :type '(choice (const nil)
                 string)
  :group 'slime-docker)

(defcustom slime-docker-docker-command "docker"
  "The command for the Docker CLI client."
  :type 'string
  :group 'slime-docker)

(defcustom slime-docker-machine-security-opts nil
  "Default security options to pass to the container."
  :type '(alist :key-type string :value-type string)
  :group 'slime-docker)

(defcustom slime-docker-userns nil
  "If non-NIL, names the default user namespace to use when starting the container."
  :type '(choice (const nil) string)
  :group 'slime-docker)

(defcustom slime-docker-dns nil
  "The default list of DNS servers to use in the container."
  :type '(repeat string)
  :group 'slime-docker)

(defcustom slime-docker-network nil
  "The network to run the container on."
  :type 'string
  :group 'slime-docker)

(defcustom slime-docker-ports nil
  "The default ports for the container."
  :type '(repeat
          (plist :value-type (choice string integer)))
  :group 'slime-docker)

(defcustom slime-docker-uid t
  "The default value for the UID argument to `slime-docker-start'.

If T (default), the UID of the current user is used.

If NIL, the UID of the container is not specified.

If an integer, that UID is used."
  :type '(choice boolean integer)
  :group 'slime-docker)

(defcustom slime-docker-gid t
  "The default value for the GID argument to `slime-docker-start'.

If T (default), the GID of the current user is used.

If NIL, the GID of the container is not specified.

If an integer, that GID is used."
  :type '(choice boolean integer)
  :group 'slime-docker)

(defvar slime-docker-machine-ssh-agent-helper-path nil
  "The location of the docker-run-ssh-agent-helper script.
This script is used to help share an SSH-Agent between the host
computer and a docker container running on docker-machine.
The default value is automatically computed.")

(defun slime-docker-find-ssh-agent-helper ()
  "Find the ssh agent helper if it exists."
  (cond
   ((file-exists-p (concat slime-docker--path "bin/docker-run-ssh-agent-helper"))
    (concat slime-docker--path "bin/docker-run-ssh-agent-helper"))
   ((file-exists-p (concat slime-docker--path "docker-run-ssh-agent-helper"))
    (concat slime-docker--path "docker-run-ssh-agent-helper"))
   (t
    nil)))

(setq slime-docker-machine-ssh-agent-helper-path
      (slime-docker-find-ssh-agent-helper))


;;;; Docker machine integration
(defun slime-docker--machine-get-env-string (machine)
  "Get the env string for MACHINE from docker-machine."
  (shell-command-to-string
   (format "docker-machine env --shell=sh %S" machine)))

(defun slime-docker--machine-variables-alist (machine)
  "Get the environment variables for MACHINE from docker-machine.

Returns an alist."
  (let ((env-string (slime-docker--machine-get-env-string machine))
        (out nil))
    (while (string-match "^\\(export .*=.*\\)$" env-string)
      (let ((subexpr (match-string 1 env-string)))
        (save-match-data
          (unless (string-match "^export \\(.*\\)=\"\\(.*\\)\"$" subexpr)
            (error "Format of environment variable from `docker-machine env' different than expected"))
          (push (cons (match-string 1 subexpr) (match-string 2 subexpr))
                out))
        (setq env-string (replace-match "" nil nil env-string 1))))
    out))

(defun slime-docker--machine-variables-string (machine)
  "Get the environment variables for MACHINE from docker-machine.

Returns a list of strings suitable for use with
`process-environment'."
  (mapcar (lambda (x) (concat (car x) "=" (cdr x)))
          (slime-docker--machine-variables-alist machine)))

(defun slime-docker--get-process-environment (args)
  "Get the `process-environment' to run Docker in.

ARGS is the plist of all args passed to top level function."
  (cl-destructuring-bind (&key docker-machine docker-machine-setenv &allow-other-keys)
      args
    (cond
     ((and docker-machine docker-machine-setenv)
      (mapc (lambda (x) (setenv (car x) (cdr x)))
            (slime-docker--machine-variables-alist docker-machine))
      process-environment)
     (docker-machine
      (append (slime-docker--machine-variables-string docker-machine)
              process-environment))
     (t
      process-environment))))

(defun slime-docker--machine-ip (machine)
  "Get the IP of MACHINE from docker-machine."
  (replace-regexp-in-string "\n\\'" ""
                            (shell-command-to-string
                             (concat "docker-machine ip " machine))))


;;;; Constructing Docker Containers

(defun slime-docker--sanitize-pathname (pathname)
  "If on Windows, sanitize PATHNAME by returning what the path would be in the docker machine."
  (cond ((string-equal system-type "windows-nt")
         (unless (string-match "^.\\(:\\)/.*" pathname)
           (error "Unable to sanitize %s" pathname))
         (concat "/" (replace-match "" nil t pathname 1)))
        (t pathname)))

(defun slime-docker--mount-to-arg (mount)
  "Convert a MOUNT description to a Docker argument.

Given a mount description of the form:

\((HOST-PATH . CONTAINER-PATH) &key READ-ONLY)

return the argument that should be passed to docker run to mount this volume."
  (cl-destructuring-bind ((host-vol . container-vol) &key read-only)
      mount
    (let ((base-string (format "--volume=%s:%s"
                               (slime-docker--sanitize-pathname host-vol)
                               container-vol)))
      (when read-only
        (setq base-string (concat base-string ":ro")))
      base-string)))

(defun slime-docker--env-to-arg (e)
  "Convert E, a pair, to a Docker argument.

Given an environment description of the form

\(VARIABLE . VALUE)

return the argument that should be passed to docker run to set variable to value."
  (cl-destructuring-bind (var . val) e
    (concat "--env=" var "=" val)))

(defun slime-docker--port-to-arg (p)
  "Convert P, a plist, to a Docker argument.

Recognized properties are :ip, :host-port, and :container-port."
  (cl-destructuring-bind (&key host-port ip container-port) p
    (concat "--publish="
            (if ip
                (concat ip ":")
              "")
            (if host-port
                (if (listp host-port)
                    (format "%s-%s" (car host-port) (cdr host-port))
                  (format "%s" host-port)))
            (if (or ip host-port)
                ":"
              "")
            (if container-port
                (if (listp container-port)
                    (format "%s-%s" (car container-port) (cdr container-port))
                  (format "%s" container-port))))))

(defun slime-docker--security-opt-to-arg (e)
  "Convert E, a pair, to a Docker argument.

Given an environment description of the form

\(SECURITY-OPTION . VALUE)

return the argument that should be passed to docker run to set the security option."
  (cl-destructuring-bind (var . val) e
    (concat "--security-opt=" var "=" val)))

(defun slime-docker---cid (proc)
  "Given a Docker PROC, return the container ID."
  (with-current-buffer (process-buffer proc)
    slime-docker--cid))

(defun slime-docker--port (proc args)
  "Given a Docker PROC, return the port that 4005 is mapped to.

ARGS is the plist of all args passed to top level function."
  (cl-destructuring-bind (&key docker-command &allow-other-keys) args
    (let* ((process-environment (slime-docker--get-process-environment args))
           (port-string (shell-command-to-string
                         (format "%s port %S 4005" docker-command (slime-docker---cid proc)))))
      (cl-assert (string-match ".*:\\([0-9]*\\)$" port-string)
                 "Unable to determine external port number.")
      (string-to-number (match-string 1 port-string)))))

(defun slime-docker--make-docker-args (args)
  "Return a list of arguments to be passed to Docker to start a container.

ARGS is the plist of all args passed to top level function."
  (cl-destructuring-bind (&key program program-args
                               cid-file
                               image-name image-tag
                               rm mounts env directory
                               uid
                               gid
                               docker-machine
                               security-opts
                               userns
                               dns
                               ports
                               network
                               &allow-other-keys) args
    `("run"
      "-i"
      ,@(when network
          (list (format "--network=%s" network)))
      ,(concat "--cidfile=" cid-file)
      "-p" ,(concat (if docker-machine "" "127.0.0.1::") "4005")
      ,(format "--rm=%s" (if rm "true" "false"))
      ,@(mapcar #'slime-docker--mount-to-arg mounts)
      ,@(mapcar #'slime-docker--env-to-arg env)
      ,@(mapcar #'slime-docker--security-opt-to-arg security-opts)
      ,@(mapcar #'slime-docker--port-to-arg ports)
      ,@(when uid
          (if gid
              (list (format "--user=%s:%s" uid gid))
            (list (format "--user=%s" uid))))
      ,@(when directory
          (list (format "--workdir=%s" directory)))
      ,@(when userns
          (list (format "--userns=%s" userns)))
      ,@(when dns
          (if (listp dns)
              (mapcar (lambda (x) (format "--dns=%s" x))
                      dns)
            (list (format "--dns=%s" dns))))
      ,(format "%s:%s" image-name image-tag)
      ,program
      ,@program-args)))

(defun slime-docker--read-cid (cid-file)
  "Given a CID-FILE where a continer ID has been written, read the container ID from it."
  (save-excursion
    (with-temp-buffer
      (insert-file-contents cid-file)
      (buffer-string))))

(defun slime-docker--ensure-mount-folder-exists (mount-description)
  "Ensures the host folder in requested MOUNT-DESCRIPTION exists."
  (cl-destructuring-bind ((host-vol . container-vol) &rest opts)
      mount-description
    (unless (file-exists-p host-vol)
      (make-directory host-vol t))))

(defun slime-docker--ensure-mount-folders-exist (args)
  "Ensures that all host folders in requested mounts of ARGS exist."
  (cl-destructuring-bind (&key mounts
                               &allow-other-keys) args
    (mapc #'slime-docker--ensure-mount-folder-exists mounts)))

(defun slime-docker--start-docker (buffer args)
  "Start a Docker container in the given BUFFER.  Return the process.

ARGS is the plist of all args passed to top level function.

The `slime-docker--cid-file' variable is made local in the BUFFER
and set to the file where the container ID will be written."
  (cl-destructuring-bind (&key docker-command &allow-other-keys) args
    (with-current-buffer (get-buffer-create buffer)
      (comint-mode)
      (erase-buffer)
      (let ((process-connection-type nil)
            (cid-file (make-temp-file "slime-docker"))
            (process-environment (slime-docker--get-process-environment args)))
        (delete-file cid-file)
        (when slime-docker-ensure-mount-folders-exist
          (slime-docker--ensure-mount-folders-exist args))
        (comint-exec (current-buffer) "docker-lisp" docker-command nil
                     (slime-docker--make-docker-args (cl-list* :cid-file cid-file args)))
        (make-local-variable 'slime-docker--cid)
        (make-local-variable 'slime-docker--cid-file)
        (setq slime-docker--cid-file cid-file))
      (lisp-mode-variables t)
      (let ((proc (get-buffer-process (current-buffer))))
        ;; TODO: deal with closing process when exiting?
        ;; TODO: Run hooks
        proc))))

(defun slime-docker--maybe-start-docker (args)
  "Return a new or existing docker process.

ARGS is the plist of all args passed to top level function."
  (cl-destructuring-bind (&key buffer &allow-other-keys) args
    (cond
     ((not (comint-check-proc buffer))
      (slime-docker--start-docker buffer args))
     ;; TODO: Prompt user to see if the existing process should be reinitialized.
     (t
      (slime-docker--start-docker (generate-new-buffer-name buffer)
                                 args)))))


;;;; Tramp Integration

(defun slime-docker--hostname (proc)
  "Given a Docker PROC, return its hostname."
  (substring (slime-docker---cid proc) 0 12))

(defun slime-docker--translate-filename->emacs (lisp-filename mounts hostname)
  "Translate LISP-FILENAME to a filename that Emacs can open.

MOUNTS is the mounts description that Docker was started with.

HOSTNAME is the hostname of the Docker container."
  ;; First, find the matching mount.
  (let ((matching-mount
         (cl-find-if (lambda (x) (string-match (concat "^" (cdr (car x))) lisp-filename))
                     mounts)))
    (if matching-mount
        (replace-match (car (car matching-mount)) nil t lisp-filename)
      ;; else, fall back to TRAMP
      (if (version< emacs-version "26.0.0")
          (tramp-make-tramp-file-name "docker" nil hostname lisp-filename)
        (tramp-make-tramp-file-name "docker" nil nil hostname nil lisp-filename)))))

(defun slime-docker--translate-filename->lisp (emacs-filename mounts)
  "Translate the EMACS-FILENAME into a filename that Lisp can open.

MOUNTS is the mounts description that Docker was started with."
  ;; First, find the matching mount.
  (let ((matching-mount
         (cl-find-if (lambda (x) (string-match (concat "^" (car (car x))) emacs-filename))
                     mounts)))
    (if matching-mount
        (replace-match (cdr (car matching-mount)) nil t emacs-filename)
      ;; else, fall back to TRAMP
      (if (tramp-tramp-file-p emacs-filename)
          (tramp-file-name-localname
           (tramp-dissect-file-name emacs-filename))
        "/dev/null"))))




(defun slime-docker--init-command (args)
  "Return a string to initialize Lisp.

ARGS is the plist of all args passed to top level function."
  (cl-destructuring-bind (&key slime-mount-path &allow-other-keys)
      args
    (let ((loader (if (file-name-absolute-p slime-backend)
                      slime-backend
                    (concat slime-mount-path "/" slime-backend))))
      (format "%S\n\n"
              `(progn
                 (load ,loader
                       :verbose t)
                 (funcall (read-from-string "swank-loader:init"))
                 (setf (symbol-value (read-from-string "swank::*loopback-interface*")) "0.0.0.0")
                 (funcall (read-from-string "swank:create-server")))))))

(defun slime-docker--start-swank-server (proc args)
  "Start a swank server in Docker PROC.

ARGS are the arguments `slime-docker-start' was called with."
  (cl-destructuring-bind (&key init &allow-other-keys) args
    (with-current-buffer (process-buffer proc)
      (let ((str (funcall init args)))
        (goto-char (process-mark proc))
        (insert-before-markers str)
        (process-send-string proc str)))))

(defun slime-docker--poll-stdout (proc attempt)
  "Return T when swank is ready for connections.

Get the PROC buffer contents, and try to find the string:
';; Swank started at port: [number].'

ATTEMPT is an integer describing which attempt we are on."
  (unless (active-minibuffer-window)
    (message "Polling Lisp stdout for Swank start message .. %d (Abort with `M-x slime-abort-connection'.)"
             attempt))
  (with-current-buffer (process-buffer proc)
    (let ((match (string-match-p ";; Swank started at port: 4005." (buffer-string))))
      (when match
        (message "match: %S" match)
        t))))

(defun slime-docker--connected-hook-function ()
  "A function that is run once SLIME is connected.

Unsets the inferior process for the connection once all other
hooks have run.  Needed to work around `slime-quit-lisp' killing
its inferior buffer, which doesn't give docker time to remove the
container."
  (let* ((c (slime-connection))
         (proc (slime-inferior-process c)))
    (when (slime-docker---cid proc)
      (slime-set-inferior-process c nil))))

(add-hook 'slime-connected-hook 'slime-docker--connected-hook-function t)

(cl-defun slime-docker--connect (proc args &optional (state 'waiting-for-cid-file) (attempt 0))
  "Implements a state machine to connect to SWANK in PROC.

ARGS is the plist of all args passed to top level function.

STATE is one of the following:

`waiting-for-cid-file'"
  (slime-cancel-connect-retry-timer)
  (with-current-buffer (process-buffer proc)
    (cl-case state
      (waiting-for-cid-file
       (when (file-exists-p slime-docker--cid-file)
         (setq state 'waiting-for-cid)))
      (waiting-for-cid
       (let ((cid (slime-docker--read-cid slime-docker--cid-file)))
         (unless (string-equal "" cid)
           (setq slime-docker--cid cid
                 state 'waiting-for-slime)
           (slime-docker--start-swank-server proc args))))
      (waiting-for-slime
       (let ((result (slime-docker--poll-stdout proc attempt)))
         (when result
           (cl-destructuring-bind (&key docker-machine mounts &allow-other-keys) args
             (let* ((ip (if docker-machine (slime-docker--machine-ip docker-machine) "127.0.0.1"))
                    (c (slime-connect ip (slime-docker--port proc args)))
                    (hostname (slime-docker--hostname proc)))
               (slime-set-inferior-process c proc)
               (when (boundp 'slime-filename-translations)
                 (push (list (concat "^" hostname "$")
                             (lambda (emacs-filename)
                               (slime-docker--translate-filename->lisp emacs-filename mounts))
                             (lambda (lisp-filename)
                               (slime-docker--translate-filename->emacs lisp-filename mounts hostname)))
                       slime-filename-translations))))
           (setq state 'done))
         (setq attempt (1+ attempt))))))
  (unless (eql state 'done)
    (setq slime-connect-retry-timer
          (run-with-timer 0.3 nil #'slime-timer-call
                          #'slime-docker--connect proc args state attempt))))

(defun slime-docker--canonicalize-mounts (mounts)
  "Canonicalize the mount names from MOUNTS."
  (mapcar (lambda (x)
            (cl-list* (cons (expand-file-name (car (cl-first x)))
                            (cdr (cl-first x)))
                      (cl-rest x)))
          mounts))

(defun slime-docker--slime-path ()
  "Return the path to the slime directory.

This will let us mount it into the container.  Normally we could
use `slime-path', but some package managers (straight.el) use
symlinks to separate the build folder from the actual repo.
Since the symlinks are invalid in the container, we check to see
if slime.el is a symlink and dereference it if it is."
  (let ((symlink-path (file-symlink-p (concat slime-path "slime.el"))))
    (if symlink-path
        (file-name-directory symlink-path)
      slime-path)))

(defun slime-docker--determine-uid (uid-arg docker-machine)
  "Determine the UID to use for the container.

If T, returns the UID of the current user or 1000 if docker
machine is being used.  Otherwise simply returns `uid-arg'."
  (if (eql uid-arg t)
      (if docker-machine
          1000
        (user-uid))
    uid-arg))

(defun slime-docker--determine-gid (gid-arg docker-machine)
  "Determine the GID to use for the container.

If T, returns the UID of the current user or 1000 if docker
machine is being used.  Otherwise simply returns `uid-arg'."
  (if (eql gid-arg t)
      (if docker-machine
          1000
        (group-gid))
    gid-arg))


;;;; User interaction

;;;###autoload
(cl-defun slime-docker-start (&key (program slime-docker-program)
                                   (program-args slime-docker-program-args)
                                   (directory slime-docker-directory)
                                   name
                                   (buffer "*docker-lisp*")
                                   (image-name slime-docker-image-name)
                                   (image-tag slime-docker-image-tag)
                                   (rm slime-docker-rm)
                                   (env slime-docker-env)
                                   (init 'slime-docker--init-command)
                                   (mounts slime-docker-mounts)
                                   (slime-mount-path slime-docker-slime-mount-path)
                                   (slime-mount-read-only slime-docker-slime-mount-read-only)
                                   (uid slime-docker-uid)
                                   (gid slime-docker-gid)
                                   (docker-machine slime-docker-docker-machine)
                                   (docker-command slime-docker-docker-command)
                                   (docker-machine-setenv t)
                                   (security-opts slime-docker-machine-security-opts)
                                   (userns slime-docker-userns)
                                   (dns slime-docker-dns)
                                   (ports slime-docker-ports)
                                   (network slime-docker-network))
  "Start a Docker container and Lisp process in the container then connect to it.

If the slime-tramp contrib is also loaded (highly recommended),
this will also set up the appropriate tramp translations to view
and edit files in the spawned container.

PROGRAM and PROGRAM-ARGS are the filename and argument strings
  for the Lisp process.
IMAGE-NAME is a string naming the image that should be used to
  start the container.
IMAGE-TAG is a string nameing the tag to use. Defaults to
  \"latest\".
INIT is a function that should return a string to load and start
  Swank. The function will be called with a plist of all
  arguments passed to `slime-docker-start'
ENV an alist of environment variables to set in the docker
  container.
BUFFER the name of the buffer to use for the subprocess.
NAME a symbol to describe the Lisp implementation.
DIRECTORY set this as the working directory in the container.
RM if true, the container is removed when the process closes.
MOUNTS a list describing the voluments to mount into the
  container. It is of the form:
  (((HOST-PATH . CONTAINER-PATH) &key READ-ONLY) ... )
UID sets the UID of the Lisp process in the container.
GID sets the GID of the Lisp process in the container.
SLIME-MOUNT-PATH the location where to mount SLIME into the
  container defaults to
  /usr/local/share/common-lisp/source/slime/
SLIME-MOUNT-READ-ONLY if non-NIL, SLIME is mounted into the
  container as read-only. Defaults to T.
DOCKER-MACHINE if non-NIL, must be a string naming a machine name
  known to docker-machine. If provided, used to set appropriate
  environment variables for the docker process to communicate
  with the desired machine. Does not start the machine if it is
  currently not running.
DOCKER-COMMAND is the command to use when interacting with
  docker. Defaults to \"docker\". See
  `slime-docker-machine-ssh-agent-helper-path' if you are using
  docker-machine and would like to share your SSH Agent with the
  container.
DOCKER-MACHINE-SETENV if non-NIL, uses `setenv' to set Emacs
  environment with the necessary variables from
  docker-machine. Should be non-NIL if you expect tramp to work
  with images running in docker machine.
SECURITY-OPTS specifies --security-opt options when running
  'docker run'. Must be an alist where keys and values are
  strings. See README for note on using this with SBCL.
USERNS specifies the user namespace to use when starting the
  container. See the --userns option to 'docker run' for more
  information.
DNS specifies a list of DNS servers to use in the container. If
  you're on a laptop, it's recommended to set this value as
  Docker does not update a container's DNS info while it is
  running (for example if you change networks).
PORTS is a list of port specifications to open in the docker
  container. The port specifications are plists with the
  properties :ip, :host-port, and :container-port. :ip must be a
  string. :host-port and :container-port must be a number or a
  cons cell."
  (let* ((mounts (cl-list* `((,(slime-docker--slime-path) . ,slime-mount-path)
                             :read-only ,slime-mount-read-only)
                           mounts))
         (args (list :program (or program inferior-lisp-program) :program-args program-args
                     :directory directory :name name :buffer buffer
                     :image-name image-name :image-tag image-tag
                     :rm rm :env env :init init
                     :mounts (slime-docker--canonicalize-mounts mounts)
                     :slime-mount-path slime-mount-path
                     :slime-read-only slime-mount-read-only
                     :uid (slime-docker--determine-uid uid docker-machine)
                     :gid (slime-docker--determine-gid gid docker-machine)
                     :docker-machine docker-machine
                     :docker-machine-setenv (and docker-machine docker-machine-setenv)
                     :docker-command docker-command
                     :security-opts security-opts
                     :userns userns
                     :network network
                     :dns dns
                     :ports ports))
         (proc (slime-docker--maybe-start-docker args)))
    (pop-to-buffer (process-buffer proc))
    (slime-docker--connect proc args)))

(defun slime-docker-start* (options)
  "Convenience to run `slime-docker-start' with OPTIONS."
  (apply #'slime-docker-start options))

(defun slime-docker--lisp-options (&optional name)
  (let ((slime-lisp-implementations slime-docker-implementations)
        (slime-default-lisp slime-docker-default-lisp))
    (slime-lisp-options name)))

(defun slime-docker--read-interactive-args ()
  "Return the list of args which should be passed to `slime-docker-start'.

The rules for selecting the arguments are rather complicated:

- In the most common case, i.e. if there's no `prefix-arg' in
  effect and if `slime-docker-implementations' is nil, use
  `slime-docker-program' as fallback.

- If the table `slime-docker-implementations' is non-nil use the
  implementation with name `slime-docker-default-lisp' or if
  that's nil the first entry in the table.

- If the `prefix-arg' is `-', prompt for one of the registered
  lisps.

- If the `prefix-arg' is positive, read the command to start the
  process."
  (let ((table slime-docker-implementations))
    (cond ((not current-prefix-arg) (slime-docker--lisp-options))
          ((eq current-prefix-arg '-)
           (let ((key (completing-read
                       "Lisp name: " (mapcar (lambda (x)
                                               (list (symbol-name (car x))))
                                             table)
                       nil t)))
             (slime-lookup-lisp-implementation table (intern key))))
          (t
           (cl-destructuring-bind (program &rest program-args)
               (split-string-and-unquote
                (read-shell-command "Run lisp: " (or slime-docker-program
                                                     inferior-lisp-program)
                                    'slime-docker--inferior-lisp-program-history))
             (list :program program :program-args program-args))))))

;;;###autoload
(defun slime-docker (&optional command)
  "Launch a Lisp process in a Docker container and connect SLIME to it.

The normal entry point to slime-docker.el. Similar to `slime'
function. Tries to guess the correct Lisp to start based on
prefix arguments and the values of `slime-docker-implementations'
and `slime-docker-default-lisp'.

COMMAND is the command to run in the Docker container."
  (interactive)
  (let ((inferior-lisp-program (or command slime-docker-program inferior-lisp-program)))
    (slime-docker-start* (cond ((and command (symbolp command))
                                (slime-docker--lisp-options command))
                               (t (slime-docker--read-interactive-args))))))

(provide 'slime-docker)

;;; slime-docker.el ends here
