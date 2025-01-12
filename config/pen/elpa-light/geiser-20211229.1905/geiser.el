;;; geiser.el --- GNU Emacs and Scheme talk to each other -*- lexical-binding: t; -*-

;; Copyright (C) 2009, 2010, 2011, 2012, 2013, 2015, 2018, 2021 Jose Antonio Ortega Ruiz

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the Modified BSD License. You should
;; have received a copy of the license along with this program. If
;; not, see <http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5>.

;; Author: Jose Antonio Ortega Ruiz (jao@gnu.org)
;; Maintainer: Jose Antonio Ortega Ruiz (jao@gnu.org)
;; Keywords: languages, scheme, geiser
;; Homepage: https://gitlab.com/emacs-geiser/
;; Package-Requires: ((emacs "25.1") (transient "0.3"))
;; SPDX-License-Identifier: BSD-3-Clause
;; Version: 0.22

;;; Commentary:

;; Geiser is a generic Emacs/Scheme interaction mode, featuring an
;; enhanced REPL and a set of minor modes improving Emacs' basic scheme
;; major mode.

;; Geiser supports Guile, Chicken, Gauche, Chibi, MIT-Scheme, Gambit,
;; Racket, Stklos, Kawa and Chez.  Each one has a separate ELPA package
;; (geiser-guile, geiser-chicken, etc.) that you should install to use
;; your favourite scheme.


;; Main functionalities:
;;     - Evaluation of forms in the namespace of the current module.
;;     - Macro expansion.
;;     - File/module loading.
;;     - Namespace-aware identifier completion (including local bindings,
;;       names visible in the current module, and module names).
;;     - Autodoc: the echo area shows information about the signature of
;;       the procedure/macro around point automatically.
;;     - Jump to definition of identifier at point.
;;     - Direct access to documentation, including docstrings (when the
;;       implementation provides them) and user manuals.
;;     - Listings of identifiers exported by a given module (Guile).
;;     - Listings of callers/callees of procedures (Guile).
;;     - Rudimentary support for debugging (list of
;;       evaluation/compilation error in an Emacs' compilation-mode
;;       buffer).
;;     - Support for inline images in schemes, such as Racket, that treat
;;       them as first order values.

;; See http://www.nongnu.org/geiser/ for the full manual in HTML form, or
;; the the info manual installed by this package.


;;; Code:
;;; Locations:

;;;###autoload
(defconst geiser-elisp-dir (file-name-directory load-file-name)
  "Directory containing Geiser's Elisp files.")


;;; Autoloads:

;;;###autoload
(autoload 'geiser-version "geiser-version" "Echo Geiser's version." t)

;;;###autoload
(autoload 'geiser-unload "geiser-reload" "Unload all Geiser code." t)

;;;###autoload
(autoload 'geiser-reload "geiser-reload" "Reload Geiser code." t)

;;;###autoload
(autoload 'geiser "geiser-repl"
  "Start a Geiser REPL, or switch to a running one." t)

;;;###autoload
(autoload 'run-geiser "geiser-repl" "Start a Geiser REPL." t)

;;;###autoload
(autoload 'geiser-connect "geiser-repl"
  "Start a Geiser REPL connected to a remote server." t)

;;;###autoload
(autoload 'geiser-connect-local "geiser-repl"
  "Start a Geiser REPL connected to a remote server over a Unix-domain socket."
  t)

;;;###autoload
(autoload 'switch-to-geiser "geiser-repl"
  "Switch to a running one Geiser REPL." t)

;;;###autoload
(autoload 'geiser-mode "geiser-mode"
  "Minor mode adding Geiser REPL interaction to Scheme buffers." t)

;;;###autoload
(autoload 'turn-on-geiser-mode "geiser-mode"
  "Enable Geiser's mode (useful in Scheme buffers)." t)

;;;###autoload
(autoload 'turn-off-geiser-mode "geiser-mode"
  "Disable Geiser's mode (useful in Scheme buffers)." t)

;;;###autoload
(autoload 'geiser-activate-implementation "geiser-impl"
  "Register the given implementation as active.")

;;;###autoload
(autoload 'geiser-implementation-extension "geiser-impl"
  "Register a file extension as handled by a given implementation.")

;;;###autoload
(mapc (lambda (group)
        (custom-add-load group (symbol-name group))
        (custom-add-load 'geiser (symbol-name group)))
      '(geiser
        geiser-repl
        geiser-autodoc
        geiser-doc
        geiser-debug
        geiser-faces
        geiser-mode
        geiser-image
        geiser-implementation
        geiser-xref))


;;; Setup:

;;;###autoload
(autoload 'geiser-mode--maybe-activate "geiser-mode")

;;;###autoload
(add-hook 'scheme-mode-hook 'geiser-mode--maybe-activate)

(provide 'geiser)
;;; geiser.el ends here
