;;; mermaid-docker-mode.el --- Render mermaid graphs with Docker service -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Peter Badida

;; Author: Peter Badida <keyweeusr@gmail.com>
;; Keywords: convenience, docker, mermaid, mmd, graph, design, jpg, image, api
;; Version: 1.2.0
;; Package-Requires: ((emacs "26.1") (mermaid-mode "1.0"))
;; Homepage: https://github.com/KeyWeeUsr/mermaid-docker-mode

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library attempts to create Mermaid graphs via mermaid-ink aka mermaid
;; as an API via a custom locally-built Docker image with restricted network
;; access, so that you are sure nothing gets out and your system is kept
;; isolated from random Node.js deps/files noise all around the filesystem.

;;; Code:

(require 'mermaid-mode)

(defgroup mermaid-docker
  nil
  "Customization group for `mermaid-docker-mode'."
  :group 'convenience
  :group 'external
  :group 'extensions
  :group 'x)

;; customization values
(defcustom mermaid-docker-verbose
  t
  "Emit messages when something's happening in the background."
  :group 'mermaid-docker
  :type 'boolean)

(defcustom mermaid-docker-always-check-deps
  t
  "Always look up binaries, libraries and other required tools."
  :group 'mermaid-docker
  :type 'boolean)

(defcustom mermaid-docker-tmp-folder
  "mermaid-docker"
  "Name for /tmp/<folder>."
  :group 'mermaid-docker
  :type 'string)

(defcustom mermaid-docker-git-repo
  "https://github.com/jihchi/mermaid.ink"
  "Address for the mermaid.ink repo."
  :group 'mermaid-docker
  :type 'string)

(defcustom mermaid-docker-image-name
  "md-ink-offline"
  "Name for mermaid-docker image."
  :group 'mermaid-docker
  :type 'string)

(defcustom mermaid-docker-header-size
  102400000
  "Node.js option --max-http-header-size."
  :group 'mermaid-docker
  :type 'number)

(defcustom mermaid-docker-port
  3000
  "Port mermaid-ink service listens on."
  :group 'mermaid-docker
  :type 'number)

(defcustom mermaid-docker-net
  "mermaid_no_internet"
  "Network name to use."
  :group 'mermaid-docker
  :type 'string)

(defcustom mermaid-docker-output
  ""
  "Default file output ('' / empty string)."
  :group 'mermaid-docker
  :type 'string)

(defcustom mermaid-docker-external-viewer-bin
  "/usr/bin/xviewer"
  "Path to external image viewer."
  :group 'mermaid-docker
  :type 'string)

(defcustom mermaid-docker-focus-steal-fix
  t
  "Should attempt to fix focus stealing?"
  :group 'mermaid-docker
  :type 'boolean)

(defcustom mermaid-docker-focus-steal-ms
  200
  "Milliseconds to wait before stealing focus back."
  :group 'mermaid-docker
  :type 'number)

(defcustom mermaid-docker-external
  t
  "Use external viewer to display rendered mermaid graph."
  :group 'mermaid-docker
  :type 'boolean)

(defcustom mermaid-docker-purge-on-exit
  t
  "Purge all running containers on Emacs exit."
  :group 'mermaid-docker
  :type 'boolean)

(defcustom mermaid-docker-http-attempts
  30
  "Default number of attempts to try contacting the container."
  :group 'mermaid-docker
  :type 'number)

(defcustom mermaid-docker-http-wait-ms
  0.2
  "Default time to wait between HTTP requests to the container."
  :group 'mermaid-docker
  :type 'number)

;; private/helper funcs
(defun mermaid-docker--log (format-string &rest args)
  "Logging func for symbol `mermaid-docker-mode'.
Argument FORMAT-STRING passed to `message' func as the first arg.
Optional argument ARGS passed to `message' func as the second arg."
  (message (format "mermaid-docker: %s" format-string) args))

(defun mermaid-docker--check-bin (buff-name cmd)
  "Check if a binary is present on the system.
Argument BUFF-NAME destination to write failure to.
Argument CMD name of the checked binary."
  (unless (executable-find cmd)
    (save-window-excursion
      (switch-to-buffer (get-buffer-create buff-name))
      (insert (format "'%s' not found\n" cmd)))
    t))

(defun mermaid-docker--call-cmd (buff-name cmd-list &optional input)
  "Call a command with optional INPUT piping and write result back.
Argument BUFF-NAME destination to write output to.
Argument CMD-LIST list of strings as a command+args to execute."
  (when (or (null input) (eq input t)) (setq input ""))
  (let ((args (list)))
    (dolist (item (list input nil (pop cmd-list) nil
                        (get-buffer-create buff-name) nil))
      (if (null args) (setq args (list item)) (push item args)))
    (dolist (arg cmd-list) (push arg args))
    (unless (eq 0 (apply #'call-process-region (reverse args))) t)))

(defun mermaid-docker--check-deps ()
  "Check if all deps are present on the system."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Checking deps for mermaid-docker"))
  (let ((buff-name "*mermaid-docker deps*")
        (failed nil)
        (net-name "mermaid-dummy"))
    ;; clean first
    (kill-buffer (get-buffer-create buff-name))

    ;; binaries
    (dolist (item '("git" "docker" "jq" "wmctrl"))
      (when (mermaid-docker--check-bin buff-name item) (setq failed t)))

    ;; permissions, network, etc
    (dolist
        (item (list
               (list nil "docker" "run" "--rm" "hello-world:latest")
               (list "FROM scratch\nENV x=1" "docker" "build" "-")
               (list nil "docker" "network" "create" "--internal" net-name)
               (list nil "docker" "run" "--rm" (format "--network=%s" net-name)
                     "hello-world:latest")
               (list nil "docker" "network" "rm" net-name)))
      (let ((tmp nil))
        (setq tmp (pop item))
        (when (mermaid-docker--call-cmd buff-name item tmp) (setq failed t))))

    (if (not failed)
        (kill-buffer (get-buffer-create buff-name))
      (switch-to-buffer (get-buffer-create buff-name))
      (user-error "Some deps are missing"))))

(defun mermaid-docker--create-temp-work-folder ()
  "Create temporary work folder."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Create temp work folder"))
  (let ((name (concat
               (temporary-file-directory)
               mermaid-docker-tmp-folder)))
    (unless (file-exists-p name)
      (make-directory name))))

(defun mermaid-docker--clone-mermaid-ink ()
  "Clone mermaid.ink repository to work folder."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Clone mermaid-ink"))
  (let ((name (concat
               (temporary-file-directory)
               mermaid-docker-tmp-folder))
        (buff-name "*mermaid-docker clone*"))
    (if (file-exists-p (concat name "/.git"))
        (when mermaid-docker-verbose
          (mermaid-docker--log "Skipping, already cloned"))
      (if (mermaid-docker--call-cmd
           (get-buffer-create buff-name)
           (list "git" "clone" "--quiet" "--depth" "1"
                 mermaid-docker-git-repo name))
          (switch-to-buffer buff-name)
        (kill-buffer buff-name)))))

(defun mermaid-docker--build-docker-image ()
  "Build mermaid.ink image in work folder."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Build Docker image"))
  (let ((name (concat
               (temporary-file-directory)
               mermaid-docker-tmp-folder))
        (buff-name "*mermaid-docker build*"))
    ;; clean first
    (kill-buffer (get-buffer-create buff-name))

    ;; patch upstream issue
    (let ((dockerignore (concat name "/.dockerignore")))
      (when (file-exists-p dockerignore)
        (delete-file dockerignore)))
    (if (not (mermaid-docker--call-cmd
           (get-buffer-create buff-name)
           (list "docker" "build" "--tag"
                 (concat mermaid-docker-image-name "-tmp") name)))
        (kill-buffer (get-buffer-create buff-name))
      (switch-to-buffer (get-buffer-create buff-name))
      (user-error "Failed to build image"))))

(defun mermaid-docker--initial-container-run ()
  "Run initial container to download deps and check rendering."
  (when mermaid-docker-verbose
    (mermaid-docker--log
     "Initial container run (necessary ping to the Internet)"))
  (let ((buff-name "*mermaid-docker initial run*")
        (cont-name "tmp-mermaid"))
    ;; clean first
    (kill-buffer (get-buffer-create buff-name))

    (when t ;; if mermaid-docker-image-name is not built
      (when t ;; if tmp-mermaid not active
        (call-process "docker" nil (get-buffer-create buff-name) nil
                      "rm" "--force" cont-name)
        (if (not (mermaid-docker--call-cmd
             (get-buffer-create buff-name)
             (list "docker" "run" "--name" cont-name "--detach"
                   ;; Failed to move to new namespace: PID namespaces
                   ;; supported, Network namespace supported, but failed:
                   ;; errno = Operation not permitted
                   ;;
                   ;; Error: Failed to launch the browser process!
                   "--cap-add=SYS_ADMIN"
                   "--env" (format "NODE_OPTIONS=\"--max-http-header-size=%s\""
                                   mermaid-docker-header-size)
                   "--publish" (format "127.0.0.1:%s:%s"
                                       mermaid-docker-port mermaid-docker-port)
                   (concat mermaid-docker-image-name "-tmp"))))
            (kill-buffer (get-buffer-create buff-name))
          (switch-to-buffer (get-buffer-create buff-name))
          (user-error "Failed to run init container"))))))

(defun mermaid-docker--http-request (url &optional output)
  "Send HTTP request to URL and dump rendered image to OUTPUT."
  (let ((attempts mermaid-docker-http-attempts)
        (ok nil))
    (while (and (not ok) (> attempts 0))
      (setq attempts (1- attempts))
      (condition-case
          err
          (progn
            (if (null output)
                (url-retrieve-synchronously url)
              (url-copy-file url output t))
            (setq ok t))
        (error
         (when mermaid-docker-verbose
           (mermaid-docker--log "Ignoring: %s" err))
         (sleep-for mermaid-docker-http-wait-ms))))
    (unless ok
      (error "Failed request: %s" url))))

(defun mermaid-docker--test-graph-rendering ()
  "Test graph rendering."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Test graph rendering"))
  (let ((buff-name "*mermaid-docker test graph*")
        (cont-name "tmp-mermaid")
        (failed nil))
    ;; clean first
    (kill-buffer (get-buffer-create buff-name))

    (when t ;; if final image is not built
      (mermaid-docker--http-request
       (format "http://127.0.0.1:%s/img/%s"
               mermaid-docker-port
               (base64-encode-string "graph LR;A-->B&C&D;")))

      (when (mermaid-docker--call-cmd (get-buffer-create buff-name)
                         (list "docker" "stop" cont-name))
        (setq failed t)))

    (if (not failed)
        (kill-buffer (get-buffer-create buff-name))
      (switch-to-buffer (get-buffer-create buff-name))
      (user-error "Failed to test graph rendering"))))

(defun mermaid-docker--create-image-for-offline-mode ()
  "Create new Docker image from initial container for offline running."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Create image for offline mode"))
  (let ((buff-name "*mermaid-docker offline image*")
        (cont-name "tmp-mermaid")
        (failed nil))
    ;; clean first
    (kill-buffer (get-buffer-create buff-name))

    (when t ;; if final image is not built
      (when (mermaid-docker--call-cmd
             (get-buffer-create buff-name)
             (list "docker" "commit" cont-name
                   mermaid-docker-image-name))
          (setq failed t))
      (mermaid-docker--call-cmd (get-buffer-create buff-name)
                   (list "docker" "rm" "--force" cont-name))
      (if (not failed)
          (kill-buffer (get-buffer-create buff-name))
        (switch-to-buffer (get-buffer-create buff-name))
        (user-error "Failed to create offline image")))))

(defun mermaid-docker-start-offline-mode ()
  "Start a Docker container with separate network and no Internet access."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Start offline mode"))
  (let ((buff-name "*mermaid-docker start offline*")
        (cont-name mermaid-docker-image-name)
        (net-name mermaid-docker-net)
        (failed nil))
    ;; clean first
    (kill-buffer (get-buffer-create buff-name))

    (when t ;; if mermaid not active
      (mermaid-docker--call-cmd (get-buffer-create buff-name)
                   (list "docker" "rm" "--force" cont-name))
      (mermaid-docker--call-cmd (get-buffer-create buff-name)
                   (list "docker" "network" "rm" net-name))

      (when (mermaid-docker--call-cmd
             (get-buffer-create buff-name)
             (list "docker" "network" "create" "--internal"
                   "--driver=bridge" mermaid-docker-net))
        (setq failed t))

      (when (mermaid-docker--call-cmd
             (get-buffer-create buff-name)
             (list "docker" "run" "--name" cont-name "--detach"
                   ;; Failed to move to new namespace: PID namespaces
                   ;; supported, Network namespace supported, but failed:
                   ;; errno = Operation not permitted
                   ;;
                   ;; Error: Failed to launch the browser process!
                   "--cap-add=SYS_ADMIN"
                   "--env" (format "NODE_OPTIONS=\"--max-http-header-size=%s\""
                                   mermaid-docker-header-size)
                   "--publish" (format "127.0.0.1:%s:%s"
                                       mermaid-docker-port mermaid-docker-port)
                   (format "--network=%s" mermaid-docker-net)
                   mermaid-docker-image-name))
        (setq failed t))

      (if (not failed)
          (kill-buffer (get-buffer-create buff-name))
        (switch-to-buffer (get-buffer-create buff-name))
        (user-error "Failed to start offline mode")))))

(defun mermaid-docker-get-ip ()
  "Get current IP of a running mermaid-docker container."
  (let ((cmd
         (format "docker inspect %s | jq -r %s"
                 (shell-quote-argument mermaid-docker-image-name)
                 (format ".[].NetworkSettings.Networks.%s.IPAddress"
                         (shell-quote-argument mermaid-docker-net)))))
    (replace-regexp-in-string "\n" "" (shell-command-to-string cmd))))

(defsubst mermaid-docker-get-url (body)
  "Assemble URL for rendering Mermaid graph.
Argument BODY raw string of a Mermaid graph."
  ;; TODO: support mermaid-mode's background width height theme
  (format "http://%s:%s/img/%s"
          (mermaid-docker-get-ip)
          mermaid-docker-port
          (base64-encode-string body)))

(defun mermaid-docker--test-graph-rendering-via-offline-mode ()
  "Test graph rendering with offline container."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Test graph rendering via offline mode"))
  (let ((out-file mermaid-docker-output)
        (out-buff "*mermaid-docker output*"))
    (when (string-equal "" out-file)
      (setq out-file (make-temp-file nil nil ".jpg" nil)))

    (mermaid-docker--http-request (mermaid-docker-get-url "graph LR;A-->B&C&D;")
                                 out-file)

    (when (string-equal "" out-file)
      (get-buffer-create out-buff)
      (save-window-excursion
        (switch-to-buffer out-buff)
        (insert-image (create-image out-file)))
      (delete-file out-file))))

(defun mermaid-docker--test-graph-rendering-via-external-editor ()
  "Test graph rendering via external editor."
  (when mermaid-docker-verbose
    (mermaid-docker--log "Test graph rendering via external editor"))
  (let ((out-file (when (string-equal "" mermaid-docker-output)
                    (format "%s/mermaid.jpg" (temporary-file-directory)))))

    (mermaid-docker--http-request (mermaid-docker-get-url "graph LR;A-->B&C&D;")
                                 out-file)

    (start-process
     "mermaid-docker-ext" nil
     mermaid-docker-external-viewer-bin
     out-file)
    (when mermaid-docker-focus-steal-fix
      (sleep-for 0 mermaid-docker-focus-steal-ms)
      (start-process "fix-focus-steal" nil "wmctrl" "-a" "emacs"))))

(defun mermaid-docker-install ()
  "Install everything for mermaid-docker."
  (interactive)
  (when mermaid-docker-always-check-deps
    (mermaid-docker--check-deps))
  (mermaid-docker--create-temp-work-folder)
  (mermaid-docker--clone-mermaid-ink)
  (mermaid-docker--build-docker-image)
  (mermaid-docker--initial-container-run)
  (mermaid-docker--test-graph-rendering)
  (mermaid-docker--create-image-for-offline-mode)
  (mermaid-docker-start-offline-mode)
  (unless (mermaid-docker--test-graph-rendering-via-offline-mode)
    (when mermaid-docker-verbose
      (mermaid-docker--log "Failed to display in Emacs, trying external program"))
    (mermaid-docker--test-graph-rendering-via-external-editor))
  (when mermaid-docker-verbose
    (mermaid-docker--log "Successfully installed")))

(defun mermaid-docker--render-external (filename)
  "Render a Mermaid graph via external program.
Argument FILENAME filename to save the output as."
  (let ((out-file (when (string-equal "" mermaid-docker-output)
                    (format "%s/mermaid.jpg" (temporary-file-directory)))))

    (mermaid-docker--http-request
     (mermaid-docker-get-url (with-temp-buffer
                               (insert-file-contents filename)
                               (buffer-string)))
                             out-file)
    (start-process
     "mermaid-docker-ext" nil
     mermaid-docker-external-viewer-bin
     out-file)
    (when mermaid-docker-focus-steal-fix
      (sleep-for 0 mermaid-docker-focus-steal-ms)
      (start-process "fix-focus-steal" nil "wmctrl" "-a" "emacs"))))

(defun mermaid-docker--render-internal (filename)
  "Render a Mermaid graph internally in Emacs.
Argument FILENAME (temporary) filename to save the output as."
  (let ((out-file mermaid-docker-output)
        (out-buff "*mermaid-docker output*"))

    (when (string-equal "" out-file)
      (setq out-file (make-temp-file nil nil ".jpg" nil)))

    (mermaid-docker--http-request
     (mermaid-docker-get-url (with-temp-buffer
                               (insert-file-contents filename)
                               (buffer-string)))
                             out-file)

    (when (string-equal "" out-file)
      (get-buffer-create out-buff)
      (save-window-excursion
        (switch-to-buffer out-buff)
        (insert-image (create-image out-file)))
      (delete-file out-file))))

(defun mermaid-docker-compile-file (filename)
  "Generic advice func to replace =mermaid-compile-file=.
Argument FILENAME =mermaid-compile-file= input arg."
  (if mermaid-docker-external
      (mermaid-docker--render-external filename)
    (mermaid-docker--render-internal filename)))

(defun mermaid-docker-mode--activate ()
  "Activate `mermaid-docker-mode` locally to a buffer."
  (advice-add
   'mermaid-compile-file
   :override #'mermaid-docker-compile-file))

(defun mermaid-docker-mode--deactivate ()
  "Dectivate `mermaid-docker-mode` locally to a buffer."
  (advice-remove
   'mermaid-compile-file
   #'mermaid-docker-compile-file))

;; public funcs
(defvar org-babel-default-header-args:mermaid-docker
  '((:file "file") (:exports . "results"))
  "Default arguments for evaluating a mermaid source block.")

(defun org-babel-execute:mermaid-docker (body params)
  "Execute command with BODY and PARAMS from src block."
  (let* ((out-file
          (or (cdr (assoc :file params))
              (error "Mermaid-docker requires a \":file\" header argument")))
         ;; TODO:
         ;; * mermaid syntax highlighting with mermaid-docker as dest
         ;; * insert to buffer as file
         ;; * (width (cdr (assoc :width params)))
         ;; * (height (cdr (assoc :height params)))
         ;; * (theme (cdr (assoc :theme params)))
         ;; * (background-color (cdr (assoc :background-color params)))
         )
    (mermaid-docker--http-request
     (mermaid-docker-get-url body) out-file)
    (format "file:%s" out-file)))

(define-minor-mode mermaid-docker-mode
  "Minor mode to patch `mermaid-mode' with Docker-enabled version."
  :lighter " mermaid-docker"
  (if mermaid-docker-mode
      (mermaid-docker-mode--activate)
    (mermaid-docker-mode--deactivate)))

(provide 'mermaid-docker-mode)

;;; mermaid-docker-mode.el ends here
