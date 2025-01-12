;;; lentic-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "lentic" "lentic.el" (0 0 0 0))
;;; Generated autoloads from lentic.el

(defvar lentic-init-functions nil "\
All functions that can be used as `lentic-init' function.")

(autoload 'lentic-default-init "lentic" "\
Default init function.
see `lentic-init' for details." nil nil)

(register-definition-prefixes "lentic" '("lentic-"))

;;;***

;;;### (autoloads nil "lentic-asciidoc" "lentic-asciidoc.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from lentic-asciidoc.el

(autoload 'lentic-clojure-asciidoc-init "lentic-asciidoc" nil nil nil)

(autoload 'lentic-asciidoc-clojure-init "lentic-asciidoc" nil nil nil)

(add-to-list 'lentic-init-functions #'lentic-asciidoc-clojure-init)

(autoload 'lentic-asciidoc-el-init "lentic-asciidoc" nil nil nil)

(add-to-list 'lentic-init-functions #'lentic-asciidoc-el-init)

(register-definition-prefixes "lentic-asciidoc" '("lentic-"))

;;;***

;;;### (autoloads nil "lentic-chunk" "lentic-chunk.el" (0 0 0 0))
;;; Generated autoloads from lentic-chunk.el

(register-definition-prefixes "lentic-chunk" '("lentic-"))

;;;***

;;;### (autoloads nil "lentic-cookie" "lentic-cookie.el" (0 0 0 0))
;;; Generated autoloads from lentic-cookie.el

(register-definition-prefixes "lentic-cookie" '("lentic-cookie-"))

;;;***

;;;### (autoloads nil "lentic-dev" "lentic-dev.el" (0 0 0 0))
;;; Generated autoloads from lentic-dev.el

(autoload 'lentic-dev-after-change-function "lentic-dev" "\
Run the change functions out of the command loop.
Using this function is the easiest way to test an new
`lentic-clone' method, as doing so in the command loop is
painful for debugging. Set variable `lentic-emergency' to
true to disable command loop functionality." t nil)

(autoload 'lentic-dev-post-command-hook "lentic-dev" "\
Run the post-command functions out of the command loop.
Using this function is the easiest way to test an new
`lentic-convert' method, as doing so in the command loop is
painful for debugging. Set variable `lentic-emergency' to
true to disable command loop functionality." t nil)

(autoload 'lentic-dev-after-save-hook "lentic-dev" nil t nil)

(autoload 'lentic-dev-mode-buffer-list-update-hook "lentic-dev" nil t nil)

(autoload 'lentic-dev-kill-buffer-hook "lentic-dev" nil t nil)

(autoload 'lentic-dev-kill-emacs-hook "lentic-dev" nil t nil)

(autoload 'lentic-dev-reinit "lentic-dev" "\
Recall the init function regardless of current status.
This can help if you have change the config object and need
to make sure there is a new one." t nil)

(autoload 'lentic-dev-random-face "lentic-dev" "\
Change the insertion face to a random one." t nil)

(defvar lentic-dev-enable-insertion-marking nil "\
Non-nil if Lentic-Dev-Enable-Insertion-Marking mode is enabled.
See the `lentic-dev-enable-insertion-marking' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `lentic-dev-enable-insertion-marking'.")

(custom-autoload 'lentic-dev-enable-insertion-marking "lentic-dev" nil)

(autoload 'lentic-dev-enable-insertion-marking "lentic-dev" "\
Enable font locking properties for inserted text.

If called interactively, toggle
`Lentic-Dev-Enable-Insertion-Marking mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(defvar lentic-dev-enable-insertion-pulse nil "\
Non-nil if Lentic-Dev-Enable-Insertion-Pulse mode is enabled.
See the `lentic-dev-enable-insertion-pulse' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `lentic-dev-enable-insertion-pulse'.")

(custom-autoload 'lentic-dev-enable-insertion-pulse "lentic-dev" nil)

(autoload 'lentic-dev-enable-insertion-pulse "lentic-dev" "\
Enable momentary pulsing for inserted text.

If called interactively, toggle
`Lentic-Dev-Enable-Insertion-Pulse mode'.  If the prefix argument
is positive, enable the mode, and if it is zero or negative,
disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "lentic-dev" '("lentic-dev-"))

;;;***

;;;### (autoloads nil "lentic-doc" "lentic-doc.el" (0 0 0 0))
;;; Generated autoloads from lentic-doc.el

(register-definition-prefixes "lentic-doc" '("lentic-"))

;;;***

;;;### (autoloads nil "lentic-latex-code" "lentic-latex-code.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from lentic-latex-code.el

(autoload 'lentic-clojure-latex-init "lentic-latex-code" nil nil nil)

(autoload 'lentic-latex-clojure-init "lentic-latex-code" nil nil nil)

(autoload 'lentic-clojure-latex-delayed-init "lentic-latex-code" nil nil nil)

(autoload 'lentic-haskell-latex-init "lentic-latex-code" nil nil nil)

(register-definition-prefixes "lentic-latex-code" '("lentic-"))

;;;***

;;;### (autoloads nil "lentic-markdown" "lentic-markdown.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from lentic-markdown.el

(autoload 'lentic-clojure-markdown-init "lentic-markdown" nil nil nil)

(register-definition-prefixes "lentic-markdown" '("lentic-"))

;;;***

;;;### (autoloads nil "lentic-mode" "lentic-mode.el" (0 0 0 0))
;;; Generated autoloads from lentic-mode.el

(autoload 'lentic-mode-create-from-init "lentic-mode" "\


\(fn &optional FORCE)" t nil)

(autoload 'lentic-mode-next-lentic-buffer "lentic-mode" "\
Move the lentic buffer into the current window, creating if necessary." t nil)

(autoload 'lentic-mode-split-window-below "lentic-mode" "\
Move lentic buffer to the window below, creating if needed." t nil)

(autoload 'lentic-mode-split-window-right "lentic-mode" "\
Move lentic buffer to the window right, creating if needed." t nil)

(autoload 'lentic-mode-show-all-lentic "lentic-mode" nil t nil)

(autoload 'lentic-mode-move-lentic-window "lentic-mode" "\
Move the next lentic buffer into the current window.
If the lentic is currently being displayed in another window,
then the current-buffer will be moved into that window. See also
`lentic-mode-swap-buffer-windows' and `lentic-mode-next-buffer'." t nil)

(autoload 'lentic-mode-swap-lentic-window "lentic-mode" "\
Swap the window of the buffer and lentic.
If both are current displayed, swap the windows they
are displayed in, which keeping current buffer.
See also `lentic-mode-move-lentic-window'." t nil)

(autoload 'lentic-mode-create-new-view-in-selected-window "lentic-mode" nil t nil)

(autoload 'lentic-mode-toggle-auto-sync-point "lentic-mode" nil t nil)

(autoload 'lentic-mode-doc-eww-view "lentic-mode" nil t nil)

(autoload 'lentic-mode-doc-external-view "lentic-mode" nil t nil)

(autoload 'lentic-mode "lentic-mode" "\
Documentation

If called interactively, toggle `Lentic mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'lentic-mode-insert-file-local "lentic-mode" "\


\(fn INIT-FUNCTION)" t nil)

(put 'global-lentic-mode 'globalized-minor-mode t)

(defvar global-lentic-mode nil "\
Non-nil if Global Lentic mode is enabled.
See the `global-lentic-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-lentic-mode'.")

(custom-autoload 'global-lentic-mode "lentic-mode" nil)

(autoload 'global-lentic-mode "lentic-mode" "\
Toggle Lentic mode in all buffers.
With prefix ARG, enable Global Lentic mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Lentic mode is enabled in all buffers where
`lentic-mode-on' would do it.

See `lentic-mode' for more information on
Lentic mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "lentic-mode" '("lentic-mode-"))

;;;***

;;;### (autoloads nil "lentic-org" "lentic-org.el" (0 0 0 0))
;;; Generated autoloads from lentic-org.el

(autoload 'lentic-org-el-init "lentic-org" nil nil nil)

(autoload 'lentic-el-org-init "lentic-org" nil nil nil)

(autoload 'lentic-org-orgel-init "lentic-org" nil nil nil)

(autoload 'lentic-orgel-org-init "lentic-org" nil nil nil)

(autoload 'lentic-org-clojure-init "lentic-org" nil nil nil)

(autoload 'lentic-clojure-org-init "lentic-org" nil nil nil)

(autoload 'lentic-org-python-init "lentic-org" nil nil nil)

(autoload 'lentic-python-org-init "lentic-org" nil nil nil)

(register-definition-prefixes "lentic-org" '("lentic-org"))

;;;***

;;;### (autoloads nil "lentic-ox" "lentic-ox.el" (0 0 0 0))
;;; Generated autoloads from lentic-ox.el

(register-definition-prefixes "lentic-ox" '("lentic-ox-"))

;;;***

;;;### (autoloads nil "lentic-rot13" "lentic-rot13.el" (0 0 0 0))
;;; Generated autoloads from lentic-rot13.el

(register-definition-prefixes "lentic-rot13" '("lentic-rot13-"))

;;;***

;;;### (autoloads nil "lentic-script" "lentic-script.el" (0 0 0 0))
;;; Generated autoloads from lentic-script.el

(eval '(defun lentic-script-hook (mode-hook init) (add-to-list 'lentic-init-functions init) (add-hook mode-hook (lambda nil (unless (bound-and-true-p lentic-init) (setq lentic-init init))))) t)

(autoload 'lentic-python-script-init "lentic-script" nil nil nil)

(lentic-script-hook 'python-mode-hook 'lentic-python-script-init)

(autoload 'lentic-bash-script-init "lentic-script" nil nil nil)

(lentic-script-hook 'shell-mode-hook 'lentic-bash-script-init)

(autoload 'lentic-lua-script-init "lentic-script" nil nil nil)

(lentic-script-hook 'lua-mode-hook #'lentic-lua-script-init)

(register-definition-prefixes "lentic-script" '("lentic-script-"))

;;;***

;;;### (autoloads nil nil ("lentic-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; lentic-autoloads.el ends here
