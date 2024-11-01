;;; geiser-kawa-globals.el --- Global variables for geiser-kawa sub-packages -*- lexical-binding:t -*-

;; Copyright (C) 2019, 2020 spellcard199 <spellcard199@protonmail.com>

;; SPDX-License-Identifier: BSD-3-Clause

;;; Commentary:
;; Global variables that geiser-kawa's sub-packages can require.
;; The reason these variables are in a stand-alone file is so that:
;; - they can be require'd by any of the geiser-kawa sub-packages
;;   without causing circular dependency errors.
;; - flycheck is happy.

(require 'geiser-impl)

;;; Code:

;;; Adaptations for making this package separate from geiser

;; Adapted from geiser.el
;;;###autoload
(defconst geiser-kawa-elisp-dir
  (file-name-directory (or load-file-name (buffer-file-name)))
  "Directory containing geiser-kawa's Elisp files.")

;; Adapted from geiser.el
;;;###autoload
(defconst geiser-kawa-dir
  (if (string-suffix-p "elisp/" geiser-kawa-elisp-dir)
      (expand-file-name "../" geiser-kawa-elisp-dir)
    geiser-kawa-elisp-dir)
  "Directory where geiser-kawa is located.")

;; Adapted from geiser.el
(custom-add-load 'geiser-kawa (symbol-name 'geiser-kawa))
(custom-add-load 'geiser      (symbol-name 'geiser-kawa))

;; Moved from geiser.el
;;;###autoload
(autoload 'run-kawa "geiser-kawa" "Start a Geiser Kawa Scheme REPL." t)

;;;###autoload
(autoload 'switch-to-kawa "geiser-kawa"
  "Start a Geiser Kawa Scheme REPL, or switch to a running one." t)

;; `geiser-active-implementations' is defined in `geiser-impl.el'
(add-to-list 'geiser-active-implementations 'kawa)

;; End of adaptations for making this package separate from geiser

(defgroup geiser-kawa nil
  "Customization for Geiser's Kawa Scheme flavour."
  :group 'geiser)

(geiser-custom--defcustom
    geiser-kawa-binary "kawa"
  "Name to use to call the Kawa Scheme executable when starting a REPL."
  :type '(choice string (repeat string))
  :group 'geiser-kawa)

(defcustom geiser-kawa-deps-jar-path
  (expand-file-name
   "./target/kawa-geiser-0.1-SNAPSHOT-jar-with-dependencies.jar"
   geiser-kawa-dir)
  "Path to the kawa-geiser fat jar."
  :type 'string
  :group 'geiser-kawa)

(defcustom geiser-kawa-use-included-kawa
  nil
  "Use the Kawa included with `geiser-kawa' instead of the `kawa' binary.
Instead of downloading kawa yourself, you can use the Kawa version
included in `geiser-kawa'."
  :type 'boolean
  :group 'geiser-kawa)

(defvar geiser-kawa--arglist
  `(;; jline "invisibly" echoes user input and prints ansi chars that
    ;; makes harder detecting end of output and finding the correct
    ;; prompt regexp.
    "console:use-jline=no"
    "--console"    ; required on windows
    "-e"
    "(require <kawageiser.Geiser>)"
    "--")
  "Variable containing the parameters to pass to Kawa at startup.
If you really want to customize this, note that the default ones
are all required for `geiser-kawa' to work.")

(defconst geiser-kawa--prompt-regexp
  "#|kawa:[0-9]+|# ")

(provide 'geiser-kawa-globals)

;;; geiser-kawa-globals.el ends here
