;;; geiser-kawa-deps.el --- Manage geiser-kawa's java dependencies -*- lexical-binding:t -*-

;; Copyright (C) 2019, 2020 spellcard199 <spellcard199@protonmail.com>

;; SPDX-License-Identifier: BSD-3-Clause

;;; Commentary:
;; This file contains code related to the download, compilation
;; and packaging of `kawa-geiser', the java dependency (with its
;; recursive dependencies) that `geiser-kawa' depends on.
;; The functions here provide utilities around the command
;; `mvnw package', which uses the pom.xml for the `kawa-geiser'
;; project, included in the `geiser-kawa-dir' directory.

;; Depends on global vars:
;; `geiser-kawa-dir'
;; `geiser-kawa-deps-jar-path'

;;; Code:

(require 'cl-lib)
(require 'geiser-repl)
(require 'geiser-kawa-globals)

(cl-defun geiser-kawa-deps-mvnw-package
    (&optional (geiser-kawa-dir geiser-kawa-dir))
  "Download, Compile and Package `geiser-kawa's java dependencies.
When called, this function runs `mvnw package' from the path specified
by the variable `GEISER-KAWA-DIR'.
The result is a fat jar that is added to the java classpath of Kawa
at REPL startup."
  ;; Using `mvn package' from the pom.xml's directory should produce a
  ;; jar containing all the java dependencies.
  (interactive)
  (let* ((mvnw-package
          (if (string-equal system-type "windows-nt")
              "mvnw.cmd package"
            "./mvnw package"))
         (default-directory geiser-kawa-dir)
         (mvn-buf (compile mvnw-package)))
    (when mvn-buf
      (let ((save-buf (current-buffer)))
        (switch-to-buffer-other-window mvn-buf)
        (goto-char (point-max))
        (switch-to-buffer-other-window save-buf)))))

(defun geiser-kawa-deps--run-kawa--compile-hook(_buf _desc)
  "Hook to run Kawa when the next compilation finishes.
Only starts Kawa if after compilation is done file at
`geiser-kawa-deps-jar-path' exists.
Removes itself from `compilation-finish-functions' so that Kawa is
started only for the next compilation.
Argument BUF is passed by Emacs when compilation finishes.
Argument DESC is passed by Emacs when compilation finishes."
  (when (file-exists-p geiser-kawa-deps-jar-path)
    ;; Using `run-geiser' instead of `run-kawa' so that callers can
    ;; also be advices of `run-kawa' without it becoming an infinite
    ;; recursion.
    (run-geiser 'kawa))
  (remove-hook 'compilation-finish-functions
               #'geiser-kawa-deps--run-kawa--compile-hook))

(defun geiser-kawa-deps-mvnw-package--and-run-kawa ()
  "Run `mvn package' and run Kawa if resulting jar exists."
  (add-hook 'compilation-finish-functions
            #'geiser-kawa-deps--run-kawa--compile-hook)
  (geiser-kawa-deps-mvnw-package geiser-kawa-dir))

(provide 'geiser-kawa-deps)

;;; geiser-kawa-deps.el ends here
