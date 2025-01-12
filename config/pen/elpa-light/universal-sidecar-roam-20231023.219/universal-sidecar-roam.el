;;; universal-sidecar-roam.el --- Integrate universal-sidecar and org-roam -*- lexical-binding: t -*-

;; Copyright (C) 2023 Samuel W. Flint <me@samuelwflint.com>

;; Author: Samuel W. Flint <me@samuelwflint.com>
;; SPDX-License-Identifier: GPL-3.0-or-later
;; URL: https://git.sr.ht/~swflint/emacs-universal-sidecar
;; Version: 1.0.4
;; Package-Requires: ((emacs "26.1") (universal-sidecar "1.0.0") (org-roam "2.0.0"))

;;; Commentary:
;;
;; This file can be used to show sections from the `org-roam-mode'
;; buffer in `universal-sidecar'.  This can be done either through
;; manual use of the `universal-sidecar-roam-section' function, or
;; through taking an existing configuration
;; (`org-roam-mode-sections').
;;
;; To use `universal-sidecar-roam-section', a minimum configuration
;; is:
;;
;; (add-to-list 'universal-sidecar-sections
;;              '(universal-sidecar-roam-section org-roam-backlinks-section))
;;
;; Note, that if you would pass arguments to the normal org-roam
;; section, you may do so after the section name in
;; `universal-sidecar-org-roam-section'.
;;
;; Finally, your sections can be added en-masse with:
;;
;; (setq universal-sidecar-sections
;;       (universal-sidecar-roam-convert-roam-sections org-roam-mode-sections))
;;
;; Additionally, the `universal-sidecar-buffer-id-formatters' variable
;; can have a "node title or buffer name" formatter, using the
;; `universal-sidecar-roam-buffer-name' function.

(require 'org-roam-node)
(require 'universal-sidecar)

;;; Code:

(defun universal-sidecar-roam-section (buffer sidecar roam-section &rest args)
  "Run ROAM-SECTION with ARGS for BUFFER in SIDECAR."
  (when (with-current-buffer buffer (derived-mode-p 'org-mode))
    (when-let* ((node (with-current-buffer buffer (org-roam-node-at-point nil)))
                (title  (org-roam-node-title node)))
      (universal-sidecar-set-title (propertize title 'font-lock-face 'bold))
      (with-current-buffer sidecar
        (apply roam-section (cons node args))))))

(defun universal-sidecar-roam-convert-roam-sections (sections-definition)
  "Convert SECTIONS-DEFINITION to `universal-sidecar-org-section'."
  (mapcar (lambda (defn)
            (if (listp defn)
                (cons 'universal-sidecar-roam-section defn)
              (list 'universal-sidecar-roam-section defn)))
          sections-definition))

(defun universal-sidecar-roam-buffer-name (&optional buffer)
  "Get BUFFER name, title if is a Roam node."
  (let ((buffer (or buffer (current-buffer))))
    (with-current-buffer buffer
      (if-let* ((buffer-name (buffer-name))
                (buffer-org-derived-p (derived-mode-p 'org-mode))
                (node (org-roam-node-at-point nil))
                (title (org-roam-node-title node)))
          title
        buffer-name))))

(provide 'universal-sidecar-roam)

;;; universal-sidecar-roam.el ends here
