;;; flycheck-gradle.el --- Flycheck extension for Gradle. -*- lexical-binding: t -*-

;; Copyright (C) 2017 James Nguyen

;; Authors: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/flycheck-gradle
;; Package-Version: 20190315.234
;; Package-Commit: 1ca08bbc343362a923cbdc2010f66e41655e92ab
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (flycheck "0.25"))
;; Keywords: languages gradle

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Flycheck extension for Gradle.
;; (with-eval-after-load 'flycheck
;;   (flycheck-gradle-setup))

;;; Code:

(require 'flycheck)
(require 'cl-lib)

;; Compatibility
(eval-and-compile
  (with-no-warnings
    (if (version< emacs-version "26")
        (progn
          (defalias 'flycheck-gradle-if-let* #'if-let)
          (defalias 'flycheck-gradle-when-let* #'when-let)
          (function-put #'flycheck-gradle-if-let* 'lisp-indent-function 2)
          (function-put #'flycheck-gradle-when-let* 'lisp-indent-function 1))
      (defalias 'flycheck-gradle-if-let* #'if-let*)
      (defalias 'flycheck-gradle-when-let* #'when-let*))))

;; Customization

(defcustom flycheck-gradle-java-log-level "quiet"
  "The log level gradle should use.

This log level should match an actual gradle log level.

e.g. warn, info, or a custom log level.

Warn should be used to check for warnings but isn't available in gradle
versions below 3 so it's safer choice to use error."
  :type 'string
  :group 'flycheck)

(defcustom flycheck-gradle-kotlin-log-level "quiet"
  "The log level gradle should use.

This log level should match an actual gradle log level.

e.g. warn, info, or a custom log level.

Warn should be used to check for warnings but isn't available in gradle
versions below 3 so it's safer choice to use error."
  :type 'string
  :group 'flycheck)

(defcustom flycheck-gradle-kotlin-compile-function 'flycheck-gradle-kotlin-compile->smart
  "Function used to find build command for gradle.

ex. `flycheck-gradle-kotlin-compile->compile' may return '\(\"clean\" \"build\"\)
which will then change the final command to be \"gradle clean build\".

The function should return a list of commands to pass to gradle. Look at
`flycheck-gradle-kotlin-compile->compile' for more information."
  :type 'function
  :group 'flycheck)

(defcustom flycheck-gradle-java-compile-function 'flycheck-gradle-compile->build
  "Function used to find build command for gradle.

Look at `flycheck-gradle-kotlin-compile-function' for more details."
  :type 'function
  :group 'flycheck)

(defcustom flycheck-gradle-adjust-log-level-automatically nil
  "Whether or not to adjust gradle's log level automatically.

The log level variables are stored in `flycheck-gradle-java-log-level' and
`flycheck-gradle-kotlin-log-level'.

This needs to be set before `flycheck-gradle-setup' is called."
  :type 'boolean
  :group 'flycheck)

;;; Flycheck
(defvar flycheck-gradle-modes '(java-mode kotlin-mode)
  "A list of modes for use with `flycheck-gradle'.")

(flycheck-def-executable-var gradle "gradle")

(flycheck-def-option-var flycheck-gradle-extra-flags nil gradle
  "Extra flags prepended to arguments of gradle."
  :type '(repeat (string :tag "Flags"))
  :safe #'flycheck-string-list-p)

(defun flycheck-gradle--verify (checker targets)
  "Return list of `flycheck-verification-result' for CHECKER using TARGETS."
  (let ((gradle (flycheck-checker-executable checker))
        (default-directory (flycheck-gradle--find-gradle-project-directory checker)))
    (cons (flycheck-verification-result-new
           :label "project dir"
           :message (or default-directory "not found")
           :face (if default-directory 'success '(bold error)))
          (when default-directory
            (mapcar (lambda (target)
                      (let ((success (eq 0 (call-process gradle nil nil nil
                                                         "-quiet"
                                                         "--console"
                                                         "plain" "--dry-run" target))))
                        (flycheck-verification-result-new
                         :label target
                         :message (if success "present" "missing")
                         :face (if success 'success '(bold error)))))
                    targets)))))

(flycheck-define-checker gradle-kotlin
  "Flycheck plugin for for Gradle."
  :command ("./gradlew"
            (eval (funcall flycheck-gradle-kotlin-compile-function))
            (eval (flycheck-gradle--log-level))
            "--console"
            "plain"
            (eval flycheck-gradle-extra-flags))
  :error-patterns
  (;; e: /kotlin/MainActivity.kt: (10, 46): Expecting ')'
   (error line-start "e: " (file-name) ": (" line ", " column "): "
          (message) line-end)
   ;; w: /kotlin/MainActivity.kt: (12, 13): Variable 'a' is never used
   (warning line-start "w: " (file-name) ": (" line ", " column "): "
            (message) line-end))
  :verify (lambda (checker)
            (flycheck-gradle--verify checker (funcall flycheck-gradle-kotlin-compile-function)))
  :modes (kotlin-mode)
  :predicate
  (lambda ()
    (funcall #'flycheck-gradle--gradle-available-p))
  :working-directory
  (lambda (checker)
    (flycheck-gradle--find-gradle-project-directory checker)))

(flycheck-define-checker gradle-java
  "Flycheck plugin for for Gradle."
  :command ("./gradlew"
            (eval (funcall flycheck-gradle-java-compile-function))
            (eval (flycheck-gradle--log-level))
            "--console"
            "plain"
            (eval flycheck-gradle-extra-flags))
  :error-patterns
  (;; /java/MainActivity.java:11: error: ';' expected setContentView(R.layout.activity_main)
   (error line-start (file-name) ":" line ": error: " (message) line-end))
  :modes (java-mode)
  :verify (lambda (checker)
            (flycheck-gradle--verify checker (funcall flycheck-gradle-java-compile-function)))
  :predicate
  (lambda ()
    (funcall #'flycheck-gradle--gradle-available-p))
  :working-directory
  (lambda (checker)
    (flycheck-gradle--find-gradle-project-directory checker)))

;;;###autoload
(defun flycheck-gradle-setup ()
  "Setup Flycheck for Gradle."
  (interactive)
  (add-hook 'flycheck-before-syntax-check-hook
            #'flycheck-gradle--set-flychecker-executable)

  (when flycheck-gradle-adjust-log-level-automatically
    (mapc (lambda (mode)
            (add-hook (intern (format "%S-hook" mode))
                      #'flycheck-gradle-set-log-level--auto))
          flycheck-gradle-modes))

  (unless (memq 'gradle-java flycheck-checkers)
    (add-to-list 'flycheck-checkers 'gradle-java)
    (if (memq 'meghanada-live flycheck-checkers)
        ;; `flycheck-gradle-java' checker will go first.
        (flycheck-add-next-checker 'gradle-java 'meghanada-live)
      (with-eval-after-load 'flycheck-meghanada
        ;; `flycheck-java' will go first.
        (flycheck-add-next-checker 'meghanada-live 'gradle-java))))

  (unless (memq 'gradle-kotlin flycheck-checkers)
    (add-to-list 'flycheck-checkers 'gradle-kotlin)
    (if (memq 'kotlin-ktlint flycheck-checkers)
        ;; `flycheck-gradle-kotlin' checker will go first.
        (flycheck-add-next-checker 'gradle-kotlin 'kotlin-ktlint)
      (with-eval-after-load 'flycheck-kotlin
        ;; `flycheck-kotlin' will go first.
        (flycheck-add-next-checker 'kotlin-ktlint 'gradle-kotlin)))))

(defun flycheck-gradle--log-level ()
  "Return default LOG level for gradle."
  (if (eq major-mode 'java-mode)
      (format "-%s" flycheck-gradle-java-log-level)
    (format "-%s" flycheck-gradle-kotlin-log-level)))

(defun flycheck-gradle--gradle-available-p ()
  "Return whether or not current buffer is part of a Gradle project."
  (flycheck-gradle--find-build-gradle-file))

(defun flycheck-gradle--find-gradle-project-directory (&optional _checker)
  "Return directory containing project-related gradle files or nil."
  (or
   (locate-dominating-file buffer-file-name "gradlew")
   (locate-dominating-file buffer-file-name "settings.gradle")
   (locate-dominating-file buffer-file-name "build.gradle")
   (locate-dominating-file buffer-file-name "build.gradle.kts")))

(defun flycheck-gradle--find-build-gradle-file ()
  "Return whether or not a build.gradle file can be found.

We use the presence of a build.gradle file to infer that this project is
a gradle project."
  (or
   (locate-dominating-file buffer-file-name "build.gradle")
   (locate-dominating-file buffer-file-name "build.gradle.kts")))

(defun flycheck-gradle--set-flychecker-executable ()
  "Set `flycheck-gradle' executable according to gradle location."
  (when (and (memq major-mode flycheck-gradle-modes)
             (flycheck-gradle--gradle-available-p))
    (flycheck-gradle-if-let*
        ((gradlew-path (flycheck-gradle--find-gradlew-executable)))
        (progn
          (setq flycheck-gradle-java-executable gradlew-path)
          (setq flycheck-gradle-kotlin-executable gradlew-path))
      (setq flycheck-gradle-java-executable "gradle")
      (setq flycheck-gradle-kotlin-executable "gradle"))))

(defun flycheck-gradle--find-gradlew-executable ()
  "Return path containing gradlew, if it exists."
  (flycheck-gradle-when-let*
      ((path (locate-dominating-file buffer-file-name "gradlew")))
    (expand-file-name
     (concat path "gradlew"))))

(defun flycheck-gradle-set-log-level--auto ()
  "Automatically set the log level for gradle depending on gradle version."
  (let ((buffer (current-buffer)))
    (flycheck-gradle-when-let*
        ((gradlew-path (flycheck-gradle--find-gradlew-executable)))
      (flycheck-gradle--async-shell-command-to-string
       (format "%s -v" gradlew-path)
       (lambda (result)
         (let ((major-version (string-to-number
                               (substring (caddr (split-string result)) 0 1))))
           (with-current-buffer buffer
             (if (>= major-version 3)
                 (progn
                   (setq-local flycheck-gradle-java-log-level "warn")
                   (setq-local flycheck-gradle-kotlin-log-level "warn"))
               (setq-local flycheck-gradle-java-log-level "quiet")
               (setq-local flycheck-gradle-kotlin-log-level "quiet")))))))))

(defun flycheck-gradle--async-shell-command-to-string (command callback)
  "Execute shell command COMMAND asynchronously in the background.
Return the temporary output buffer which command is writing to
during execution.
When the command is finished, call CALLBACK with the resulting
output as a string."
  (let ((output-buffer (generate-new-buffer " *temp*")))
    (set-process-sentinel
     (start-process "Shell" output-buffer shell-file-name shell-command-switch command)
     (lambda (process _signal)
       (when (memq (process-status process) '(exit signal))
         (with-current-buffer output-buffer
           (let ((output-string
                  (buffer-substring-no-properties
                   (point-min)
                   (point-max))))
             (funcall callback output-string)))
         (kill-buffer output-buffer))))
    output-buffer))

(defun flycheck-gradle-android-project-p ()
  "Detect if Android project."
  (or
   (bound-and-true-p android-mode)
   (locate-dominating-file buffer-file-name "AndroidManifest.xml")
   (ignore-errors
     (file-exists-p (concat (car (split-string default-directory "src"))
                            "src/main/AndroidManifest.xml")))))

;; Compile Target Functions
(defun flycheck-gradle-compile->build ()
  "Target gradle build."
  (if (flycheck-has-current-errors-p 'error)
      '("build")
    '("clean" "build")))

(defun flycheck-gradle-kotlin-compile->compile ()
  "Target gradle compile for kotlin."
  (let ((cmd (if (and
                  buffer-file-name
                  (string-match-p "test" buffer-file-name))
                 "compileTestKotlin"
               "compileKotlin")))
    (if (flycheck-has-current-errors-p 'error)
        `(,cmd)
      `("clean" ,cmd))))

(defun flycheck-gradle-kotlin-compile->compile-android ()
  "Target gradle compile for kotlin android."
  (let ((cmd (if (and
                  buffer-file-name
                  (string-match-p "test" buffer-file-name))
                 "compileDebugUnitTestKotlin"
               "compileReleaseKotlin")))
    (if (flycheck-has-current-errors-p 'error)
        `(,cmd)
      `("clean" ,cmd))))

(defun flycheck-gradle-kotlin-compile->smart ()
  "Conditionally compile kotlin."
  (if (flycheck-gradle-android-project-p)
      (flycheck-gradle-kotlin-compile->compile-android)
    (flycheck-gradle-kotlin-compile->compile)))

(defun flycheck-gradle-java-compile->compile ()
  "Target gradle compile for java."
  (let ((cmd (if (and
                  buffer-file-name
                  (string-match-p "test" buffer-file-name))
                 "compileTestJava"
               "compileJava")))
    (if (flycheck-has-current-errors-p 'error)
        `(,cmd)
      `("clean" ,cmd))))

(defun flycheck-gradle-java-compile->android ()
  "Target gradle compile for android java."
  (let ((cmd
         (cond
          ((and buffer-file-name
                (string-match-p "androidTest" buffer-file-name))
           "compileDebugAndroidTestSources")
          ((and buffer-file-name
                (string-match-p "test" buffer-file-name))
           "compileDebugUnitTestSources")
          (:default
           "compileDebugSources"))))
    (if (flycheck-has-current-errors-p 'error)
        `(,cmd)
      `("clean" ,cmd))))

(provide 'flycheck-gradle)
;;; flycheck-gradle.el ends here
