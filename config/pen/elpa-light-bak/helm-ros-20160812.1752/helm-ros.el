;;; helm-ros.el ---  Interfaces ROS with helm  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  David Landry

;; Author: David Landry <davidlandry93@gmail.com>
;; Keywords: helm, ROS
;; Package-Version: 20160812.1752
;; Package-Commit: 92b0b215f6a017f0f57f1af15466cc0b2a5a0135
;; Version: 0.1.0
;; Package-Requires: ((helm "1.9.9") (xterm-color "1.0") (cl-lib "0.5"))
;; URL: https://www.github.com/davidlandry93/helm-ros

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

;; helm-ros is a package that interfaces ROS with the helm completion facilities.
;; For more information go to https://www.github.com/davidlandry93/helm-ros

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'xterm-color)


;; ros-process-mode


(defvar ros-process-mode-hook nil)

(defvar ros-process-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "k") 'helm-ros-kill-ros-process)
    (define-key map (kbd "c") 'helm-ros-interrupt-ros-process)
    (define-key map (kbd "q") (lambda () (interactive) (delete-window)))
    map)
  "Keymap for the ros process major mode")

(defun helm-ros-interrupt-ros-process ()
  "Interrupts the ros process associated with the current buffer."
  (interactive)
  (let ((ros-node-process (get-buffer-process (current-buffer))))
    (interrupt-process ros-node-process)))

(defun helm-ros-kill-ros-process ()
  "Kills the ros process associated with the current buffer."
  (interactive)
  (let ((ros-node-process (get-buffer-process (current-buffer))))
    (kill-process ros-node-process)))

(defun helm-ros--ros-process-filter (process string)
  "Apply `xterm-color-filter' to the text in STRING before outputting it to the PROCESS buffer."
  (when (buffer-live-p (process-buffer process))
    (with-current-buffer (process-buffer process)
      (let ((moving (= (point) (process-mark process))))
        (save-excursion
          (goto-char (process-mark process))
          (insert (xterm-color-filter string))
          (set-marker (process-mark process) (point)))
        (if moving (goto-char (process-mark process)))))))

;;;###autoload
(define-derived-mode ros-process-mode fundamental-mode "ROS Process Mode"
  "Major mode for handling the output of ROS processes."
  (let ((ros-process (get-buffer-process (current-buffer))))
    (if ros-process
        (set-process-filter (get-buffer-process (current-buffer)) 'helm-ros--ros-process-filter))))


;; helm-ros


(defvar helm-ros--package-path
  (mapconcat 'identity (cl-remove-if-not 'file-exists-p
                                      (split-string
                                       (getenv "ROS_PACKAGE_PATH") ":")) " "))


(defun helm-ros--open-file-action (filename)
  (interactive) (find-file filename))

(defun helm-ros--launch-launchfile (filename)
  (let* ((launchfile-name (file-name-nondirectory
                           (file-name-sans-extension filename)))
         (buffer (get-buffer-create (format "*roslaunch %s*" launchfile-name))))
    (with-current-buffer buffer
      (start-process launchfile-name buffer "roslaunch" filename)
      (ros-process-mode)
      (pop-to-buffer buffer))))

(defun helm-ros--displayed-real-pair-of-path (fullpath)
  (cons (file-name-nondirectory (file-name-sans-extension fullpath)) fullpath))

(defun helm-ros--list-of-command-output (command)
  (with-temp-buffer
    (call-process-shell-command command nil t)
    (split-string (buffer-string) "\n" t)))

(defun helm-ros--start-ros-process (command)
  (let ((buffer-name (format "*%s*" command)))
    (with-current-buffer (get-buffer-create buffer-name)
      (start-process-shell-command command buffer-name command))
    (pop-to-buffer buffer-name)
    (ros-process-mode)))

(defun helm-ros--ros-shell-command (command)
  (let ((buffer-name "*ROS Command Output*"))
    (with-current-buffer (get-buffer-create buffer-name)
      (erase-buffer)
      (start-process-shell-command "ROS Command" buffer-name command)
      (pop-to-buffer buffer-name)
      (ros-process-mode))))

;;;###autoload
(defun helm-ros-set-master-uri (uri)
  "Set the ROS_MASTER_URI environment variable to URI"
  (interactive "sNew ROS Master URI: ")
  (setenv "ROS_MASTER_URI" uri))

;;;###autoload
(defun helm-ros-roscore ()
  "Start a roscore in the *roscore* buffer.  Create it if it doesn't exist."
  (interactive)
  (with-current-buffer (get-buffer-create "*roscore*")
    (start-process "roscore" (current-buffer) "roscore")
    (pop-to-buffer (current-buffer))
    (ros-process-mode)))


;; Launchfiles


(defvar helm-ros--launchfile-candidate-list-cache nil)

(defun helm-ros--launchfile-candidate-list ()
  (if helm-ros--launchfile-candidate-list-cache
      helm-ros--launchfile-candidate-list-cache
    (set 'helm-ros--launchfile-candidate-list-cache
         (mapcar 'helm-ros--displayed-real-pair-of-path
                 (helm-ros--list-of-command-output
                  (format "find -L %s -type f -name \"*.launch\"" helm-ros--package-path))))))


(defvar helm-source-ros-launchfiles
  (helm-build-sync-source "Launchfiles"
    :candidates 'helm-ros--launchfile-candidate-list
    :action '(("Edit" . helm-ros--open-file-action)
             ("Launch" . helm-ros--launch-launchfile))))

;;;###autoload
(defun helm-ros-launchfiles ()
  "Launch helm with ros launchfiles as the only source."
  (interactive)
  (helm :sources '(helm-source-ros-launchfiles)))

;; Services


(defvar helm-ros--service-candidate-list-cache nil)

(defun helm-ros--service-candidate-list ()
  (if helm-ros--service-candidate-list-cache
      helm-ros--service-candidate-list-cache
    (set 'helm-ros--service-candidate-list-cache
         (mapcar 'helm-ros--displayed-real-pair-of-path
                 (helm-ros--list-of-command-output
                  (format "find -L %s -type f -name \"*.srv\"" helm-ros--package-path))))))

(defvar helm-source-ros-services
  (helm-build-sync-source "Services"
    :candidates 'helm-ros--service-candidate-list
    :action '(("Open file" . helm-ros--open-file-action))))


;; Actions

(defvar helm-ros--action-candidate-list-cache nil)

(defun helm-ros--action-candidate-list ()
  (if helm-ros--action-candidate-list-cache
      helm-ros--action-candidate-list-cache
    (set 'helm-ros--action-candidate-list-cache
         (mapcar 'helm-ros--displayed-real-pair-of-path
                 (helm-ros--list-of-command-output
                  (format "find -L %s -type f -name \"*.action\"" helm-ros--package-path))))))

(defvar helm-source-ros-actions
  (helm-build-sync-source "Action Services"
    :candidates 'helm-ros--action-candidate-list
    :action '(("Open file" . helm-ros--open-file-action))))


;; Packages


(defvar helm-ros--package-candidate-list-cache nil)

(defun helm-ros--parsed-rospack-entry (entry)
  (let ((splitted-string (split-string entry)) )
    (cons (car splitted-string) (car (cdr splitted-string)))))

(defun helm-ros--package-candidate-list ()
  "Outputs a list of dotted pairs having the name of the package as
the car and the path to the package root as the cdr."
  (if helm-ros--package-candidate-list-cache
      helm-ros--package-candidate-list-cache
    (set 'helm-ros--package-candidate-list-cache
         (mapcar 'helm-ros--parsed-rospack-entry
                 (helm-ros--list-of-command-output "rospack list")))))

(defvar helm-source-ros-packages
  (helm-build-sync-source "Packages"
    :candidates 'helm-ros--package-candidate-list
    :action '(("Open folder" . (lambda (candidate) (interactive) (dired candidate))))))


;; Nodes


(defvar helm-ros--nodes-candidate-list-cache nil)

(defun helm-ros--input-node ()
  (completing-read "Node: " (helm-ros--list-of-running-nodes)))

(defun helm-ros--list-of-packages ()
  (helm-ros--list-of-command-output "rospack list"))

(defun helm-ros--list-of-package-names ()
  (mapcar (lambda (x)
            (let ((parsed-entry (helm-ros--parsed-rospack-entry x)))
              (car parsed-entry)))
          (helm-ros--list-of-packages)))

(defun helm-ros--exec-folders-of-package (package)
  (helm-ros--list-of-command-output (format "catkin_find --libexec %s" package)))

(defun helm-ros--nodes-of-package (package)
  (let ((list-of-exec-folders (helm-ros--exec-folders-of-package package)))
    (if list-of-exec-folders
        (mapcar 'file-name-nondirectory
                (helm-ros--list-of-command-output
                 (format "find -L %s -type f -executable"
                         (mapconcat 'identity list-of-exec-folders " ")))))))

(defun helm-ros--list-of-package-node-pairs ()
  (let (list-of-pairs)
    (message "Building list of nodes (this may take a while)")
    (dolist (package (helm-ros--list-of-package-names))
      (dolist (node (helm-ros--nodes-of-package package))
        (push (cons package node) list-of-pairs)))
    list-of-pairs))

(defun helm-ros--pretty-string-of-package-node-pair (pair)
  (format "%s/%s" (car pair) (cdr pair)))

(defun helm-ros--real-string-of-package-node-pair (pair)
  (format "%s %s" (car pair) (cdr pair)))

(defun helm-ros--node-candidate-list ()
  (if helm-ros--nodes-candidate-list-cache
      helm-ros--nodes-candidate-list-cache
    (set 'helm-ros--nodes-candidate-list-cache
         (mapcar (lambda (pair) (cons (helm-ros--pretty-string-of-package-node-pair pair)
                                      (helm-ros--real-string-of-package-node-pair pair)))
                 (helm-ros--list-of-package-node-pairs)))))

;;;###autoload
(defun helm-ros-run-node (package node)
  "Run ros NODE that is in PACKAGE."
  (interactive
   (let ((package (completing-read "Package: " (helm-ros--list-of-package-names))))
     (list
      package
      (completing-read "Node: " (helm-ros--nodes-of-package package)))))
  (let ((node-buffer (get-buffer-create (format "*%s*" node))))
    (start-process "rosrun" node-buffer "rosrun" package node)
    (pop-to-buffer node-buffer)
    (ros-process-mode)))

(defun helm-ros--list-of-running-nodes ()
  "List of the nodes currently running."
  (helm-ros--list-of-command-output "rosnode list"))

;;;###autoload
(defun helm-ros-rosnode-info (node)
  "Print the informations of NODE."
  (interactive (list (helm-ros--input-node)))
  (helm-ros--ros-shell-command (format "rosnode info %s" node)))

;;;###autoload
(defun helm-ros-kill-node (node)
  "Kill the process of NODE."
  (interactive
   (list (helm-ros--input-node)))
  (shell-command (format "rosnode kill %s" node)))

;;;###autoload
(defun helm-ros-rosnode-list ()
  "Print a list of running nodes in a new buffer."
  (interactive)
  (helm-ros--ros-shell-command "rosnode list"))

(defvar helm-source-ros-nodes
  (helm-build-sync-source "Nodes"
    :candidates 'helm-ros--list-of-running-nodes
    :action (helm-make-actions "Info" 'helm-ros-rosnode-info
                               "Kill" 'helm-ros-kill-node)))


;; Topics


(defun helm-ros--list-of-running-topics ()
  (helm-ros--list-of-command-output "rostopic list"))

;;;###autoload
(defun helm-ros-rostopic-list ()
  (interactive)
  (helm-ros--ros-shell-command "rostopic list"))

(defun helm-ros--input-topic ()
  (completing-read "Topic: " (helm-ros--list-of-running-topics)))

;;;###autoload
(defun helm-ros-rostopic-echo (topic)
  "Echo TOPIC in a new buffer."
  (interactive
   (list (helm-ros--input-topic)))
  (helm-ros--start-ros-process (format "rostopic echo %s" topic)))

;;;###autoload
(defun helm-ros-rostopic-hz (topic)
  "Run ros topic hz on TOPIC."
  (interactive (list (helm-ros--input-topic)))
  (helm-ros--start-ros-process (format "rostopic hz %s" topic)))

;;;###autoload
(defun helm-ros-rostopic-info (topic)
  "Run rostopic info on TOPIC."
  (interactive (list (helm-ros--input-topic)))
  (helm-ros--start-ros-process (format "rostopic info %s" topic)))

(defvar helm-source-ros-topics
  (helm-build-sync-source "Topics"
    :candidates 'helm-ros--list-of-running-topics
    :action (helm-make-actions "Echo" 'helm-ros-rostopic-echo
                               "Hz" 'helm-ros-rostopic-hz
                               "Info" 'helm-ros-rostopic-info)))

;;;###autoload
(defun helm-ros-topics ()
  (interactive)
  (helm :sources '(helm-source-ros-topics)))


;;;###autoload
(defun helm-ros ()
  "Launch ros-helm with all available sources."
  (interactive)
  (helm :sources '(helm-source-ros-services
                   helm-source-ros-launchfiles
                   helm-source-ros-packages
                   helm-source-ros-actions
                   helm-source-ros-topics
                   helm-source-ros-nodes)))

;;;###autoload
(defun helm-ros-invalidate-cache ()
  "Invalidates the cache of all helm-ros sources."
  (interactive)
  (setq helm-ros--package-candidate-list-cache nil
        helm-ros--launchfile-candidate-list-cache nil
        helm-ros--nodes-candidate-list-cache nil
        helm-ros--service-candidate-list-cache nil
        helm-ros--action-candidate-list-cache nil))

;;;###autoload
(define-minor-mode global-helm-ros-mode
  "A minor mode that enables the keybindings for helm-ros."
  :init-value t
  :lighter " ROS"
  :keymap (let ((keymap (make-sparse-keymap)))
            (define-key keymap (kbd "C-x C-r i") 'helm-ros-invalidate-cache)
            (define-key keymap (kbd "C-x C-r h") 'helm-ros)
            (define-key keymap (kbd "C-x C-r m") 'helm-ros-roscore)
            keymap)
  :global t)

(provide 'helm-ros)

;;; helm-ros.el ends here
