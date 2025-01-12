;;; nix-env-install.el --- Install packages using nix-env -*- lexical-binding: t -*-

;; Copyright (C) 2019 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1
;; Package-Version: 20200812.1305
;; Package-Commit: 79c34bc117ba1cebeb67fab32c364951d2ec37a0
;; Package-Requires: ((emacs "25.1"))
;; Keywords: processes tools
;; URL: https://github.com/akirak/nix-env-install

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library lets you install packages using nix-env.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'json)

(declare-function xterm-color-filter "ext:xterm-color")
(declare-function ansi-color-filter-apply "ext:ansi-color")

(defgroup nix-env-install nil
  "Install packages using nix-env."
  :group 'nix)

(when (memq system-type '(ms-dos windows-nt cygwin))
  (user-error "Nix doesn't run on non-UNIX systems"))

(defcustom nix-env-install-display-process-buffers t
  "Whether to display process buffers."
  :group 'nix-env-install
  :type 'boolean)

(defcustom nix-env-install-window-height 15
  "Window height of process buffers."
  :group 'nix-env-install
  :type 'number)

(defcustom nix-env-install-display-buffer
  'nix-env-install--display-buffer-default
  "Function used to display process buffers."
  :group 'nix-env-install
  :type 'function)

(defcustom nix-env-install-cachix-executable "cachix"
  "Executable of cachix."
  :group 'nix-env-install
  :type 'file)

(defcustom nix-env-install-process-environment '("NIX_BUILD_SHELL")
  "Additional environment variables for processes.

The entries in this variables are added to `process-environment'
and possibly overrides existing ones.

If you set NIX_BUILD_SHELL to something like zsh in your shell,
you need to unset it when you run commands in \"nix-shell\".
This variable allows that."
  :group 'nix-env-install
  :type '(repeat string))

(defcustom nix-env-install-process-filter #'nix-env-install-default-process-filter
  "Filter function for processes."
  :group 'nix-env-install
  :type 'function)

(defcustom nix-env-install-process-output-filter
  (cond
   ;; Function from xterm-color package.
   ;; Seems to properly propertizes colorized output from terminal
   ;; commands.
   ((fboundp #'xterm-color-filter)
    #'xterm-color-filter)
   ;; Function from ansi-color package.
   ;; Doesn't colorize terminal commands when TERM is set to dumb,
   ;; but it gets rid of ugly escape sequences.
   ((fboundp #'ansi-color-filter-apply)
    #'ansi-color-filter-apply))
  "Function used to handle output from processes."
  :group 'nix-env-install
  :type '(choice function nil))

(defcustom nix-env-install-delete-process-window t
  "When non-nil, delete the process window on success."
  :group 'nix-env-install
  :type 'boolean)

(defcustom nix-env-install-npm-node2nix-options "--nodejs-10"
  "Additional command line arguments for node2nix."
  :group 'nix-env-install
  :type 'string)

(defvar nix-env-install-start-process-hook nil
  "Hook to run immediately after creating a process in this package.

This hook is run in process buffers, so you can use it to
convert the output of each program, for example.")

(defvar nix-env-install-process-window nil)

;;;; Utility functions
(cl-defun nix-env-install--start-process (name buffer command
                                &key
                                clear-buffer
                                (display-buffer nix-env-install-display-process-buffers)
                                on-finished on-error
                                cleanup)
  "Start an asynchronous process for running a system command.

NAME, BUFFER, and COMMAND are the same as in `make-process'.
COMMAND is a list of an executable name and arguments.

When CLEAR-BUFFER is non-nil, the buffer is erased before the
process starts.

When DISPLAY-BUFFER is non-nil, the buffer is displayed.
If it is a function, it is used to display the buffer.
Otherwise, `nix-env-install-display-buffer' is used.

ON-FINISHED is a function called after a successful exit of the
command.  ON-ERROR is a function called when the process exits
with a non-zero exit code.

CLEANUP is a function whenever the process exits."
  (declare (indent 1))
  (when (and clear-buffer
             (get-buffer buffer))
    (with-current-buffer buffer
      (erase-buffer)))
  (let* ((sentinel (lambda (proc event)
                     (with-current-buffer (process-buffer proc)
                       (goto-char (point-max)))
                     (unless (process-live-p proc)
                       (when cleanup
                         (funcall cleanup)))
                     (cond
                      ((and (equal event "finished\n")
                            on-finished)
                       (funcall on-finished))
                      ((or (string-match (rx "exited abnormally with code " (group (+ digit)))
                                         event)
                           (string-match (rx "failed with code " (group (+ digit)))
                                         event))
                       (if on-error
                           (funcall on-error)
                         (message "Process %s has exited with %s" name
                                  (match-string 1 event)))))))
         (proc (let ((process-environment (nix-env-install--make-process-environment)))
                 (make-process :name name
                               :buffer buffer
                               :command command
                               :filter nix-env-install-process-filter
                               :sentinel sentinel))))
    (with-current-buffer (process-buffer proc)
      (setq-local header-line-format nil)
      (run-hooks 'nix-env-install-start-process-hook)
      (when display-buffer
        (funcall (if (functionp display-buffer)
                     display-buffer
                   nix-env-install-display-buffer)
                 (current-buffer))))))

(defun nix-env-install-default-process-filter (proc str)
  "Default process filter.

PROC is the process, and STR is the string."
  (let* ((buf (process-buffer proc))
         (window (get-buffer-window buf)))
    (when window
      (with-selected-window window
        (goto-char (point-max))
        (insert (if nix-env-install-process-output-filter
                    (funcall nix-env-install-process-output-filter str)
                  str))
        (recenter -1)))))

(defun nix-env-install--make-process-environment ()
  "Make a new value of `process-enviroment' with `nix-env-install-process-environment' merged."
  (let ((alist (mapcar (lambda (raw-form)
                         (cons (car (nix-env-install--parse-environment raw-form)) raw-form))
                       process-environment)))
    (dolist (raw-form nix-env-install-process-environment)
      (let* ((our-env (nix-env-install--parse-environment raw-form))
             (base-env (assoc (car our-env) alist)))
        (if base-env
            (setcdr base-env (cdr our-env))
          (push (cons (car our-env) raw-form) alist))))
    (mapcar #'cdr alist)))

(defun nix-env-install--parse-environment (raw-form)
  "Return a cell of key and value from the RAW-FORM of a key=value pair.

If the equal sign is not contained in the form, it returns a cell
where the key is the form and the value is nil."
  (if (string-match (rx bol (group (+ (not (any "="))))
                        "=" (group (+? anything)) eol)
                    raw-form)
      (cons (match-string 1 raw-form)
            (match-string 2 raw-form))
    (cons raw-form nil)))

(defun nix-env-install--delete-process-window ()
  "Delete the window for processes."
  (when (and nix-env-install-delete-process-window
             nix-env-install-process-window
             (window-live-p nix-env-install-process-window))
    (delete-window nix-env-install-process-window)))

(defun nix-env-install--display-buffer-default (buffer)
  "Display BUFFER in a new dedicated window."
  (if-let ((window (and nix-env-install-process-window
                        (window-live-p nix-env-install-process-window)
                        nix-env-install-process-window)))
      (progn
        (when (window-dedicated-p window)
          (set-window-dedicated-p window nil))
        (set-window-buffer window buffer)
        (set-window-dedicated-p window t))
    (setq nix-env-install-process-window
          (display-buffer-in-side-window
           buffer
           `((side . bottom)
             (height . ,nix-env-install-window-height))))))

;;;; Cachix support
(defconst nix-env-install-cachix-buffer "*nix-env-install cachix*")

(defun nix-env-install-cachix-exists-p ()
  "Return non-nil if there is cachix executable."
  (or (file-executable-p nix-env-install-cachix-executable)
      (executable-find nix-env-install-cachix-executable)))

(cl-defun nix-env-install-cachix (&key (on-finished #'nix-env-install-cachix-setup))
  "Install cachix, if you haven't already.

When the installation process is finished, ON-FINISHED is called."
  (interactive)
  (if (nix-env-install-cachix-exists-p)
      (when (called-interactively-p 'interactive)
        (message "Cachix is already installed"))
    (nix-env-install--start-process
        "nix-env" nix-env-install-cachix-buffer
        '("nix-env" "-iA" "cachix"
          "-f" "https://cachix.org/api/v1/install")
        :on-finished on-finished)))

(defun nix-env-install-cachix-setup ()
  "Start an interactive setup of cachix."
  (browse-url "https://cachix.org/")
  (message "After cachix is installed, follow the instructions to set up your account."))

;;;###autoload
(defun nix-env-install-cachix-use (name)
  "Enable binary cache of NAME."
  (interactive "sCachix: ")
  (if (nix-env-install-cachix-exists-p)
      (nix-env-install--start-process
          "cachix" nix-env-install-cachix-buffer
          (list nix-env-install-cachix-executable "use" name)
          :display-buffer nil
          :on-finished
          (lambda ()
            (nix-env-install--delete-process-window)
            (message "Successfully enabled cachix from %s" name)))
    (when (yes-or-no-p "Cachix is not installed yet. Install it? ")
      (nix-env-install-cachix :on-finished `(lambda () (nix-env-install-cachix-use ,name))))))

;;;; Uninstallation command
;;;###autoload
(defun nix-env-install-uninstall (package)
  "Uninstall PACKAGE installed by nix-env."
  (interactive (list (completing-read "Package: "
                                      (process-lines "nix-env" "-q"))))
  (message (shell-command-to-string
            (format "nix-env -e %s" (shell-quote-argument package)))))

;;;; NPM for JavaScript/TypeScript
(defconst nix-env-install-npm-buffer "*nix-env-install npm*")

(defcustom nix-env-install-npm-install-hook nil
  "Hooks called after installation of npm packages."
  :type 'hook
  :group 'nix-env-install)

(defun nix-env-install--node2nix-temp-dir ()
  "Generate a temporary directory for node2nix."
  (string-trim-right
   (shell-command-to-string "mktemp -d -t emacs-node2nix-XXX")))

;;;###autoload
(defun nix-env-install-npm (packages)
  "Install PACKAGES from npm using Nix."
  (interactive (list (split-string (read-string "npm packages: ") " ")))
  (unless packages
    (user-error "PACKAGES cannot be nil"))
  (let* ((tmpdir (nix-env-install--node2nix-temp-dir))
         (default-directory tmpdir)
         (packages-json-file (expand-file-name "npm-packages.json" tmpdir)))
    (with-temp-buffer
      (insert (json-encode (cl-typecase packages
                             (list packages)
                             (string (list packages)))))
      (write-region (point-min) (point-max) packages-json-file))
    (message "Generating Nix expressions using node2nix for %s..." packages)
    (nix-env-install--start-process
        "nix-env-install-node2nix" nix-env-install-npm-buffer
        `("nix-shell" "-p" "nodePackages.node2nix"
          "--run" ,(format "node2nix -i %s %s" packages-json-file
                           nix-env-install-npm-node2nix-options))
        :clear-buffer t
        :on-finished
        `(lambda ()
           (message "Installing npm packages using nix-env...")
           (nix-env-install--start-process
               "nix-env"
             nix-env-install-npm-buffer
             ',(apply #'append
                      (list "nix-env"
                            "-f" (expand-file-name "default.nix" tmpdir)
                            "-i")
                      (mapcar (lambda (it) (list "-A"
                                                 ;; Quote explicitly to support packages including dots, e.g. mermaid.cli
                                                 (format "\"%s\"" it)))
                              (cl-etypecase packages
                                (list packages)
                                (string (list packages)))))
             :on-finished
             ,`(lambda ()
                 (nix-env-install--delete-process-window)
                 (message "Finished installing npm packages: %s" (quote ,packages))
                 (run-hooks 'nix-env-install-npm-install-hook))
             :cleanup
             ,`(lambda () (delete-directory ,tmpdir t)))))))

(provide 'nix-env-install)
;;; nix-env-install.el ends here
