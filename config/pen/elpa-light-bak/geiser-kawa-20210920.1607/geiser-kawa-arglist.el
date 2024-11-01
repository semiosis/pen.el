;;; geiser-kawa-arglist.el --- Command-line arguments for Geiser support in Kawa -*- lexical-binding: t -*-

;; Copyright (C) 2019, 2020 spellcard199 <spellcard199@protonmail.com>

;; SPDX-License-Identifier: BSD-3-Clause

;;; Commentary:
;; Code for handling command line executable and arguments to obtain
;; geiser support in Kawa.
;; Since `kawa-geiser', the java package `geiser-kawa' depends on,
;; includes a version of Kawa, running Kawa without having downloaded
;; it is also supported by setting to non-nil the variable
;; `geiser-kawa-user-included-kawa'.

(require 'geiser-kawa-globals)
(require 'compile)

;;; Code:

(defun geiser-kawa--binary ()
  "Return the binary to call to start Kawa.
If `geiser-kawa-included-kawa' is non-nil, we need to call the Kawa
initialization method included in the jar file produced by
`geiser-kawa-deps-mvnw-package', so we need `java', not `kawa' as our
binary.
If `geiser-kawa-binary' is a list, take the first and ignore
`geiser-kawa-use-included-kawa'.
If `geiser-kawa-binary' is a string, just return it."
  (if geiser-kawa-use-included-kawa
      "java"
    (if (listp geiser-kawa-binary)
        (car geiser-kawa-binary)
      geiser-kawa-binary)))

(cl-defun geiser-kawa-arglist--make-classpath
    (&optional (geiser-kawa-use-included-kawa
                geiser-kawa-use-included-kawa)
               (geiser-kawa-binary
                geiser-kawa-binary)
               (geiser-kawa-deps-jar-path
                geiser-kawa-deps-jar-path))
  "If the following conditions are true...:
- `GEISER-KAWA-USE-INCLUDED-KAWA' is nil
- `GEISER-KAWA-BINARY' filepath exists
- the `lib' dir under `geiser-kawa-binary's parent dir exists
... then: add to classpath at repl startup:
- the 4 .jar files under the `lib' dir
- fat jar with `geiser-kawa' dependencies
... else: add to the classpath just:
- fat jar with `geiser-kawa' dependencies

GEISER-KAWA-DEPS-JAR-PATH defaults to the value of
`geiser-kawa-deps-jar-path'."
  (let ((jars
         (append
          (if (and
               (not geiser-kawa-use-included-kawa)
               (executable-find geiser-kawa-binary))
              (let ((lib-dir (expand-file-name
                              "../lib/"
                              (file-name-directory
                               (executable-find geiser-kawa-binary)))))
                (if (file-directory-p lib-dir)
                    (list
                     (concat lib-dir "kawa.jar")
                     (concat lib-dir "servlet.jar")
                     (concat lib-dir "domterm.jar")
                     (concat lib-dir "jline.jar"))
                  nil))
            nil)
          (list geiser-kawa-deps-jar-path))))
    (mapconcat #'identity jars ":")))

(defun geiser-kawa-arglist--make-classpath-arg (classpath)
  "Make -Djava.class.path argument from CLASSPATH.
Argument CLASSPATH is a string containing the classpath."
  (format "-Djava.class.path=%s" classpath))

(defun geiser-kawa-arglist ()
  "Return a list with all parameters needed to start Kawa Scheme."
  ;; Using append instead of semiquote so that if
  ;; `geiser-kawa-use-included-kawa' is `nil' it doesn't appear as
  ;; `nil' in the resulting arglist
  (append
   (list (geiser-kawa-arglist--make-classpath-arg
          (geiser-kawa-arglist--make-classpath)))
   (if geiser-kawa-use-included-kawa
       (list "kawa.repl"))
   geiser-kawa--arglist))

(defun geiser-kawa--version-command (binary)
  "Return version of Kawa as started by Geiser.
Argument BINARY is passed by Geiser."
  (let* ((program (if geiser-kawa-use-included-kawa
                      "java"
                    binary))
         (args  (if geiser-kawa-use-included-kawa
                    (list (geiser-kawa-arglist--make-classpath-arg
                           geiser-kawa-deps-jar-path)
                          "kawa.repl"
                          "--version")
                  (list "--version")))
         (output (apply #'process-lines
                        (cons program args)))
         (progname-plus-version (car output)))
    ;; `progname-plus-version' is something like:
    ;; "Kawa 3.1.1"
    (cadr (split-string progname-plus-version " "))))

(defun geiser-kawa--repl-startup (_remote)
  "Function used as Geiser's `repl-startup' method.
From `geiser-repl.el': Function called after the REPL has been
initialised.  All Geiser functionality is available to you at that
point.
Argument REMOTE passed by Geiser."
  ;; Does nothing for now.  Keeping for reference.
  ;; (let ((geiser-log-verbose-p t))
  ;; (compilation-setup t))
  )

(provide 'geiser-kawa-arglist)

;;; geiser-kawa-arglist.el ends here
