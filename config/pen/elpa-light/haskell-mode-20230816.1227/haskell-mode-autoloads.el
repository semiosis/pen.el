;;; haskell-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ghc-core" "ghc-core.el" (0 0 0 0))
;;; Generated autoloads from ghc-core.el

(autoload 'ghc-core-create-core "ghc-core" "\
Compile and load the current buffer as tidy core." t nil)

(add-to-list 'auto-mode-alist '("\\.hcr\\'" . ghc-core-mode))

(add-to-list 'auto-mode-alist '("\\.dump-simpl\\'" . ghc-core-mode))

(autoload 'ghc-core-mode "ghc-core" "\
Major mode for GHC Core files.

\(fn)" t nil)

(register-definition-prefixes "ghc-core" '("ghc-core-"))

;;;***

;;;### (autoloads nil "ghci-script-mode" "ghci-script-mode.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from ghci-script-mode.el

(autoload 'ghci-script-mode "ghci-script-mode" "\
Major mode for working with .ghci files.

\(fn)" t nil)

(add-to-list 'auto-mode-alist '("\\.ghci\\'" . ghci-script-mode))

(register-definition-prefixes "ghci-script-mode" '("ghci-script-mode-"))

;;;***

;;;### (autoloads nil "haskell" "haskell.el" (0 0 0 0))
;;; Generated autoloads from haskell.el

(autoload 'interactive-haskell-mode "haskell" "\
Minor mode for enabling haskell-process interaction.

If called interactively, toggle `Interactive-Haskell mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'haskell-interactive-mode-return "haskell" "\
Handle the return key." t nil)

(autoload 'haskell-session-kill "haskell" "\
Kill the session process and buffer, delete the session.
1. Kill the process.
2. Kill the interactive buffer unless LEAVE-INTERACTIVE-BUFFER is not given.
3. Walk through all the related buffers and set their haskell-session to nil.
4. Remove the session from the sessions list.

\(fn &optional LEAVE-INTERACTIVE-BUFFER)" t nil)

(autoload 'haskell-interactive-kill "haskell" "\
Kill the buffer and (maybe) the session." t nil)

(autoload 'haskell-session "haskell" "\
Get the Haskell session, prompt if there isn't one or fail." nil nil)

(autoload 'haskell-interactive-switch "haskell" "\
Switch to the interactive mode for this session." t nil)

(autoload 'haskell-session-change "haskell" "\
Change the session for the current buffer." t nil)

(autoload 'haskell-kill-session-process "haskell" "\
Kill the process.

\(fn &optional SESSION)" t nil)

(autoload 'haskell-interactive-mode-visit-error "haskell" "\
Visit the buffer of the current (or last) error message." t nil)

(autoload 'haskell-mode-jump-to-tag "haskell" "\
Jump to the tag of the given identifier.

Give optional NEXT-P parameter to override value of
`xref-prompt-for-identifier' during definition search.

\(fn &optional NEXT-P)" t nil)

(autoload 'haskell-mode-after-save-handler "haskell" "\
Function that will be called after buffer's saving." nil nil)

(autoload 'haskell-mode-tag-find "haskell" "\
The tag find function, specific for the particular session.

\(fn &optional NEXT-P)" t nil)

(autoload 'haskell-interactive-bring "haskell" "\
Bring up the interactive mode for this session." t nil)

(autoload 'haskell-process-load-file "haskell" "\
Load the current buffer file." t nil)

(autoload 'haskell-process-reload "haskell" "\
Re-load the current buffer file." t nil)

(autoload 'haskell-process-reload-file "haskell" nil nil nil)

(autoload 'haskell-process-load-or-reload "haskell" "\
Load or reload. Universal argument toggles which.

\(fn &optional TOGGLE)" t nil)

(autoload 'haskell-process-cabal-build "haskell" "\
Build the Cabal project." t nil)

(autoload 'haskell-process-cabal "haskell" "\
Prompts for a Cabal command to run.

\(fn P)" t nil)

(autoload 'haskell-process-minimal-imports "haskell" "\
Dump minimal imports." t nil)

(register-definition-prefixes "haskell" '("haskell-" "interactive-haskell-mode-map" "xref-prompt-for-identifier"))

;;;***

;;;### (autoloads nil "haskell-align-imports" "haskell-align-imports.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-align-imports.el

(autoload 'haskell-align-imports "haskell-align-imports" "\
Align all the imports in the buffer." t nil)

(register-definition-prefixes "haskell-align-imports" '("haskell-align-imports-"))

;;;***

;;;### (autoloads nil "haskell-c2hs" "haskell-c2hs.el" (0 0 0 0))
;;; Generated autoloads from haskell-c2hs.el

(add-to-list 'auto-mode-alist '("\\.chs\\'" . haskell-c2hs-mode))

(autoload 'haskell-c2hs-mode "haskell-c2hs" "\
Mode for editing *.chs files of the c2hs haskell tool.

\(fn)" t nil)

(register-definition-prefixes "haskell-c2hs" '("haskell-c2hs-font-lock-keywords"))

;;;***

;;;### (autoloads nil "haskell-cabal" "haskell-cabal.el" (0 0 0 0))
;;; Generated autoloads from haskell-cabal.el

(add-to-list 'auto-mode-alist '("\\.cabal\\'\\|/cabal\\.project\\|/\\.cabal/config\\'" . haskell-cabal-mode))

(autoload 'haskell-cabal-mode "haskell-cabal" "\
Major mode for Cabal package description files.

\(fn)" t nil)

(autoload 'haskell-cabal-get-field "haskell-cabal" "\
Read the value of field with NAME from project's cabal file.
If there is no valid .cabal file to get the setting from (or
there is no corresponding setting with that name in the .cabal
file), then this function returns nil.

\(fn NAME)" t nil)

(autoload 'haskell-cabal-get-dir "haskell-cabal" "\
Get the Cabal dir for a new project.
Various ways of figuring this out, and indeed just prompting the user.  Do them
all.

\(fn &optional USE-DEFAULTS)" nil nil)

(autoload 'haskell-cabal-visit-file "haskell-cabal" "\
Locate and visit package description file for file visited by current buffer.
This uses `haskell-cabal-find-file' to locate the closest
\".cabal\" file and open it.  This command assumes a common Cabal
project structure where the \".cabal\" file is in the top-folder
of the project, and all files related to the project are in or
below the top-folder.  If called with non-nil prefix argument
OTHER-WINDOW use `find-file-other-window'.

\(fn OTHER-WINDOW)" t nil)

(register-definition-prefixes "haskell-cabal" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-collapse" "haskell-collapse.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from haskell-collapse.el

(autoload 'haskell-collapse-mode "haskell-collapse" "\
Minor mode to collapse and expand haskell expressions

If called interactively, toggle `Haskell-Collapse mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "haskell-collapse" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-commands" "haskell-commands.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from haskell-commands.el

(autoload 'haskell-process-restart "haskell-commands" "\
Restart the inferior Haskell process." t nil)

(autoload 'haskell-process-clear "haskell-commands" "\
Clear the current process." t nil)

(autoload 'haskell-process-interrupt "haskell-commands" "\
Interrupt the process (SIGINT)." t nil)

(autoload 'haskell-describe "haskell-commands" "\
Describe the given identifier IDENT.

\(fn IDENT)" t nil)

(autoload 'haskell-rgrep "haskell-commands" "\
Grep the effective project for the symbol at point.
Very useful for codebase navigation.

Prompts for an arbitrary regexp given a prefix arg PROMPT.

\(fn &optional PROMPT)" t nil)

(autoload 'haskell-process-do-info "haskell-commands" "\
Print info on the identifier at point.
If PROMPT-VALUE is non-nil, request identifier via mini-buffer.

\(fn &optional PROMPT-VALUE)" t nil)

(autoload 'haskell-process-do-type "haskell-commands" "\
Print the type of the given expression.

Given INSERT-VALUE prefix indicates that result type signature
should be inserted.

\(fn &optional INSERT-VALUE)" t nil)

(autoload 'haskell-mode-jump-to-def-or-tag "haskell-commands" "\
Jump to the definition.
Jump to definition of identifier at point by consulting GHCi, or
tag table as fallback.

Remember: If GHCi is busy doing something, this will delay, but
it will always be accurate, in contrast to tags, which always
work but are not always accurate.
If the definition or tag is found, the location from which you jumped
will be pushed onto `xref--marker-ring', so you can return to that
position with `xref-pop-marker-stack'.

\(fn &optional NEXT-P)" t nil)

(autoload 'haskell-mode-goto-loc "haskell-commands" "\
Go to the location of the thing at point.
Requires the :loc-at command from GHCi." t nil)

(autoload 'haskell-mode-jump-to-def "haskell-commands" "\
Jump to definition of identifier IDENT at point.

\(fn IDENT)" t nil)

(autoload 'haskell-process-cd "haskell-commands" "\
Change directory.

\(fn &optional NOT-INTERACTIVE)" t nil)

(autoload 'haskell-process-cabal-macros "haskell-commands" "\
Send the cabal macros string." t nil)

(autoload 'haskell-mode-show-type-at "haskell-commands" "\
Show type of the thing at point or within active region asynchronously.
This function requires GHCi 8+ or GHCi-ng.

\\<haskell-interactive-mode-map>
To make this function works sometimes you need to load the file in REPL
first using command `haskell-process-load-file' bound to
\\[haskell-process-load-file].

Optional argument INSERT-VALUE indicates that
recieved type signature should be inserted (but only if nothing
happened since function invocation).

\(fn &optional INSERT-VALUE)" t nil)

(autoload 'haskell-process-unignore "haskell-commands" "\
Unignore any ignored files.
Do not ignore files that were specified as being ignored by the
inferior GHCi process." t nil)

(autoload 'haskell-session-change-target "haskell-commands" "\
Set the build TARGET for cabal REPL.

\(fn TARGET)" t nil)

(autoload 'haskell-mode-stylish-buffer "haskell-commands" "\
Apply stylish-haskell to the current buffer.

Use `haskell-mode-stylish-haskell-path' to know where to find
stylish-haskell executable.  This function tries to preserve
cursor position and markers by using
`haskell-mode-buffer-apply-command'." t nil)

(autoload 'haskell-mode-find-uses "haskell-commands" "\
Find use cases of the identifier at point and highlight them all." t nil)

(register-definition-prefixes "haskell-commands" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-compile" "haskell-compile.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from haskell-compile.el

(autoload 'haskell-compile "haskell-compile" "\
Run a compile command for the current Haskell buffer.
Obeys haskell-compiler-type to choose the appropriate build command.

If prefix argument EDIT-COMMAND is non-nil (and not a negative
prefix `-'), prompt for a custom compile command.

If EDIT-COMMAND contains the negative prefix argument `-', call
the alternative command defined in
`haskell-compile-stack-build-alt-command' /
`haskell-compile-cabal-build-alt-command'.

If there is no prefix argument, the most recent custom compile
command is used, falling back to
`haskell-compile-stack-build-command' for stack builds
`haskell-compile-cabal-build-command' for cabal builds, and
`haskell-compile-command' otherwise.

'% characters in the `-command' templates are replaced by the
base directory for build tools, or the current buffer for
`haskell-compile-command'.

\(fn &optional EDIT-COMMAND)" t nil)

(register-definition-prefixes "haskell-compile" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-complete-module" "haskell-complete-module.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-complete-module.el

(register-definition-prefixes "haskell-complete-module" '("haskell-complete-module"))

;;;***

;;;### (autoloads nil "haskell-completions" "haskell-completions.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-completions.el

(autoload 'haskell-completions-completion-at-point "haskell-completions" "\
Provide completion list for thing at point.
This function is used in non-interactive `haskell-mode'.  It
provides completions for haskell keywords, language pragmas,
GHC's options, and language extensions, but not identifiers." nil nil)

(register-definition-prefixes "haskell-completions" '("haskell-completions-"))

;;;***

;;;### (autoloads nil "haskell-customize" "haskell-customize.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-customize.el

(register-definition-prefixes "haskell-customize" '("haskell-" "inferior-haskell-root-dir"))

;;;***

;;;### (autoloads nil "haskell-debug" "haskell-debug.el" (0 0 0 0))
;;; Generated autoloads from haskell-debug.el

(register-definition-prefixes "haskell-debug" '("haskell-debug"))

;;;***

;;;### (autoloads nil "haskell-decl-scan" "haskell-decl-scan.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-decl-scan.el

(autoload 'haskell-ds-create-imenu-index "haskell-decl-scan" "\
Function for finding `imenu' declarations in Haskell mode.
Finds all declarations (classes, variables, imports, instances and
datatypes) in a Haskell file for the `imenu' package." nil nil)

(autoload 'turn-on-haskell-decl-scan "haskell-decl-scan" "\
Unconditionally activate `haskell-decl-scan-mode'." t nil)

(autoload 'haskell-decl-scan-mode "haskell-decl-scan" "\
Toggle Haskell declaration scanning minor mode on or off.
With a prefix argument ARG, enable minor mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil, and toggle it if ARG is `toggle'.

See also info node `(haskell-mode)haskell-decl-scan-mode' for
more details about this minor mode.

Top-level declarations are scanned and listed in the menu item
\"Declarations\" (if enabled via option
`haskell-decl-scan-add-to-menubar').  Selecting an item from this
menu will take point to the start of the declaration.

\\[beginning-of-defun] and \\[end-of-defun] move forward and backward to the start of a declaration.

This may link with `haskell-doc-mode'.

For non-literate and LaTeX-style literate scripts, we assume the
common convention that top-level declarations start at the first
column.  For Bird-style literate scripts, we assume the common
convention that top-level declarations start at the third column,
ie. after \"> \".

Anything in `font-lock-comment-face' is not considered for a
declaration.  Therefore, using Haskell font locking with comments
coloured in `font-lock-comment-face' improves declaration scanning.

Literate Haskell scripts are supported: If the value of
`haskell-literate' (set automatically by `haskell-literate-mode')
is `bird', a Bird-style literate script is assumed.  If it is nil
or `tex', a non-literate or LaTeX-style literate script is
assumed, respectively.

Invokes `haskell-decl-scan-mode-hook' on activation.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "haskell-decl-scan" '("haskell-d" "literate-haskell-ds-"))

;;;***

;;;### (autoloads nil "haskell-doc" "haskell-doc.el" (0 0 0 0))
;;; Generated autoloads from haskell-doc.el

(autoload 'haskell-doc-mode "haskell-doc" "\
Enter `haskell-doc-mode' for showing fct types in the echo area.

If called interactively, toggle `Haskell-Doc mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

When enabled, shows the type of the function near point or a related comment.

If the identifier near point is a Haskell keyword and the variable
`haskell-doc-show-reserved' is non-nil show a one line summary
of the syntax.

If the identifier near point is a Prelude or one of the standard library
functions and `haskell-doc-show-prelude' is non-nil show its type.

If the identifier near point is local (i.e. defined in this module) check
the `imenu' list of functions for the type.  This obviously requires that
your language mode uses `imenu'.

If the identifier near point is global (i.e. defined in an imported module)
and the variable `haskell-doc-show-global-types' is non-nil show the type of its
function.

If the identifier near point is a standard strategy or a function, type related
related to strategies and `haskell-doc-show-strategy' is non-nil show the type
of the function.  Strategies are special to the parallel execution of Haskell.
If you're not interested in that just turn it off.

If the identifier near point is a user defined function that occurs as key
in the alist `haskell-doc-user-defined-ids' and the variable
`haskell-doc-show-user-defined' is non-nil show the type of the function.

This variable is buffer-local.

\(fn &optional ARG)" t nil)

(defalias 'turn-on-haskell-doc-mode 'haskell-doc-mode)

(defalias 'turn-on-haskell-doc 'haskell-doc-mode)

(autoload 'haskell-doc-eldoc-function "haskell-doc" "\
Function for use by eldoc.

By accepting CALLBACK, it is designed to be used in
`eldoc-documentation-functions' in Emacs >= 28.1, but by making
that argument optional it can also be set directly as
`eldoc-documentation-function' in older Emacsen.

\(fn &optional CALLBACK)" nil nil)

(autoload 'haskell-doc-current-info "haskell-doc" "\
Return the info about symbol at point.
Meant for `eldoc-documentation-function'." nil nil)

(autoload 'haskell-doc-show-type "haskell-doc" "\
Show the type of the function near point or given symbol SYM.
For the function under point, show the type in the echo area.
This information is extracted from the `haskell-doc-prelude-types' alist
of prelude functions and their types, or from the local functions in the
current buffer.

\(fn &optional SYM)" t nil)

(register-definition-prefixes "haskell-doc" '("haskell-" "inferior-haskell-" "turn-off-haskell-doc"))

;;;***

;;;### (autoloads nil "haskell-font-lock" "haskell-font-lock.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-font-lock.el

(register-definition-prefixes "haskell-font-lock" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-ghc-support" "haskell-ghc-support.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-ghc-support.el

(register-definition-prefixes "haskell-ghc-support" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-hoogle" "haskell-hoogle.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from haskell-hoogle.el

(autoload 'haskell-hoogle "haskell-hoogle" "\
Do a Hoogle search for QUERY.

If prefix argument INFO is given, then `haskell-hoogle-command'
is asked to show extra info for the items matching QUERY..

\(fn QUERY &optional INFO)" t nil)

(defalias 'hoogle 'haskell-hoogle)

(autoload 'haskell-hoogle-lookup-from-website "haskell-hoogle" "\
Lookup QUERY at `haskell-hoogle-url'.

\(fn QUERY)" t nil)

(autoload 'haskell-hoogle-lookup-from-local "haskell-hoogle" "\
Lookup QUERY on local hoogle server." t nil)

(register-definition-prefixes "haskell-hoogle" '("haskell-hoogle-" "hoogle-prompt"))

;;;***

;;;### (autoloads nil "haskell-indent" "haskell-indent.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from haskell-indent.el

(autoload 'turn-on-haskell-indent "haskell-indent" "\
Turn on ``intelligent'' Haskell indentation mode." nil nil)

(autoload 'haskell-indent-mode "haskell-indent" "\
``Intelligent'' Haskell indentation mode.
This deals with the layout rule of Haskell.
\\[haskell-indent-cycle] starts the cycle which proposes new
possibilities as long as the TAB key is pressed.  Any other key
or mouse click terminates the cycle and is interpreted except for
RET which merely exits the cycle.
Other special keys are:
    \\[haskell-indent-insert-equal]
      inserts an =
    \\[haskell-indent-insert-guard]
      inserts an |
    \\[haskell-indent-insert-otherwise]
      inserts an | otherwise =
these functions also align the guards and rhs of the current definition
    \\[haskell-indent-insert-where]
      inserts a where keyword
    \\[haskell-indent-align-guards-and-rhs]
      aligns the guards and rhs of the region
    \\[haskell-indent-put-region-in-literate]
      makes the region a piece of literate code in a literate script

If `ARG' is falsey, toggle `haskell-indent-mode'.  Else sets
`haskell-indent-mode' to whether `ARG' is greater than 0.

Invokes `haskell-indent-hook' if not nil.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "haskell-indent" '("haskell-indent-" "turn-off-haskell-indent"))

;;;***

;;;### (autoloads nil "haskell-indentation" "haskell-indentation.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-indentation.el

(autoload 'haskell-indentation-mode "haskell-indentation" "\
Haskell indentation mode that deals with the layout rule.
It rebinds RET, DEL and BACKSPACE, so that indentations can be
set and deleted as if they were real tabs.

If called interactively, toggle `Haskell-Indentation mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-haskell-indentation "haskell-indentation" "\
Turn on the haskell-indentation minor mode." t nil)

(register-definition-prefixes "haskell-indentation" '("haskell-indentation-"))

;;;***

;;;### (autoloads nil "haskell-interactive-mode" "haskell-interactive-mode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-interactive-mode.el

(autoload 'haskell-interactive-mode-reset-error "haskell-interactive-mode" "\
Reset the error cursor position.

\(fn SESSION)" t nil)

(autoload 'haskell-interactive-mode-echo "haskell-interactive-mode" "\
Echo a read only piece of text before the prompt.

\(fn SESSION MESSAGE &optional MODE)" nil nil)

(autoload 'haskell-process-show-repl-response "haskell-interactive-mode" "\
Send LINE to the GHCi process and echo the result in some fashion.
Result will be printed in the minibuffer or presented using
function `haskell-presentation-present', depending on variable
`haskell-process-use-presentation-mode'.

\(fn LINE)" nil nil)

(register-definition-prefixes "haskell-interactive-mode" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-lexeme" "haskell-lexeme.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from haskell-lexeme.el

(register-definition-prefixes "haskell-lexeme" '("haskell-lexeme-"))

;;;***

;;;### (autoloads nil "haskell-load" "haskell-load.el" (0 0 0 0))
;;; Generated autoloads from haskell-load.el

(autoload 'haskell-process-reload-devel-main "haskell-load" "\
Reload the module `DevelMain' and then run `DevelMain.update'.

This is for doing live update of the code of servers or GUI
applications.  Put your development version of the program in
`DevelMain', and define `update' to auto-start the program on a
new thread, and use the `foreign-store' package to access the
running context across :load/:reloads in GHCi." t nil)

(register-definition-prefixes "haskell-load" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-menu" "haskell-menu.el" (0 0 0 0))
;;; Generated autoloads from haskell-menu.el

(autoload 'haskell-menu "haskell-menu" "\
Launch the Haskell sessions menu." t nil)

(register-definition-prefixes "haskell-menu" '("haskell-menu-"))

;;;***

;;;### (autoloads nil "haskell-mode" "haskell-mode.el" (0 0 0 0))
;;; Generated autoloads from haskell-mode.el

(autoload 'haskell-version "haskell-mode" "\
Show the `haskell-mode` version in the echo area.
With prefix argument HERE, insert it at point.

\(fn &optional HERE)" t nil)

(autoload 'haskell-mode-view-news "haskell-mode" "\
Display information on recent changes to haskell-mode." t nil)

(autoload 'haskell-mode "haskell-mode" "\
Major mode for editing Haskell programs.

\\<haskell-mode-map>

Literate Haskell scripts are supported via `haskell-literate-mode'.
The variable `haskell-literate' indicates the style of the script in the
current buffer.  See the documentation on this variable for more details.

Use `haskell-version' to find out what version of Haskell mode you are
currently using.

Additional Haskell mode modules can be hooked in via `haskell-mode-hook'.

Indentation modes:

    `haskell-indentation-mode', Kristof Bastiaensen, Gergely Risko
      Intelligent semi-automatic indentation Mk2

    `haskell-indent-mode', Guy Lapalme
      Intelligent semi-automatic indentation.

Interaction modes:

    `interactive-haskell-mode'
      Interact with per-project GHCi processes through a REPL and
      directory-aware sessions.

Other modes:

    `haskell-decl-scan-mode', Graeme E Moss
      Scans top-level declarations, and places them in a menu.

    `haskell-doc-mode', Hans-Wolfgang Loidl
      Sets up eldoc to echo types of functions or syntax of keywords
      when the cursor is idle.

To activate a minor-mode, simply run the interactive command. For
example, `M-x haskell-doc-mode'. Run it again to disable it.

To enable a mode for every `haskell-mode' buffer, add a hook in
your Emacs configuration. To do that you can customize
`haskell-mode-hook' or add lines to your .emacs file. For
example, to enable `interactive-haskell-mode', use the following:

    (add-hook \\='haskell-mode-hook \\='interactive-haskell-mode)

Minor modes that work well with `haskell-mode':

- `smerge-mode': show and work with diff3 conflict markers used
  by git, svn and other version control systems.

\(fn)" t nil)

(autoload 'haskell-forward-sexp "haskell-mode" "\
Haskell specific version of `forward-sexp'.

Move forward across one balanced expression (sexp).  With ARG, do
it that many times.  Negative arg -N means move backward across N
balanced expressions.  This command assumes point is not in a
string or comment.

If unable to move over a sexp, signal `scan-error' with three
arguments: a message, the start of the obstacle (a parenthesis or
list marker of some kind), and end of the obstacle.

\(fn &optional ARG)" t nil)

(autoload 'haskell-literate-mode "haskell-mode" "\
As `haskell-mode' but for literate scripts.

\(fn)" t nil)

(define-obsolete-function-alias 'literate-haskell-mode 'haskell-literate-mode "2020-04")

(add-to-list 'auto-mode-alist '("\\.[gh]s\\'" . haskell-mode))

(add-to-list 'auto-mode-alist '("\\.hsig\\'" . haskell-mode))

(add-to-list 'auto-mode-alist '("\\.l[gh]s\\'" . haskell-literate-mode))

(add-to-list 'auto-mode-alist '("\\.hsc\\'" . haskell-mode))

(add-to-list 'interpreter-mode-alist '("runghc" . haskell-mode))

(add-to-list 'interpreter-mode-alist '("runhaskell" . haskell-mode))

(add-to-list 'completion-ignored-extensions ".hi")

(autoload 'haskell-mode-generate-tags "haskell-mode" "\
Generate tags using Hasktags.  This is synchronous function.

If optional AND-THEN-FIND-THIS-TAG argument is present it is used
with function `xref-find-definitions' after new table was
generated.

\(fn &optional AND-THEN-FIND-THIS-TAG)" t nil)

(register-definition-prefixes "haskell-mode" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-modules" "haskell-modules.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from haskell-modules.el

(autoload 'haskell-session-installed-modules "haskell-modules" "\
Get the modules installed in the current package set.

\(fn SESSION &optional DONTCREATE)" nil nil)

(autoload 'haskell-session-all-modules "haskell-modules" "\
Get all modules -- installed or in the current project.
If DONTCREATE is non-nil don't create a new session.

\(fn SESSION &optional DONTCREATE)" nil nil)

(autoload 'haskell-session-project-modules "haskell-modules" "\
Get the modules of the current project.
If DONTCREATE is non-nil don't create a new session.

\(fn SESSION &optional DONTCREATE)" nil nil)

(register-definition-prefixes "haskell-modules" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-move-nested" "haskell-move-nested.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-move-nested.el

(autoload 'haskell-move-nested "haskell-move-nested" "\
Shift the nested off-side-rule block adjacent to point.
It shift the nested off-side-rule block adjacent to point by COLS
columns to the right.

In Transient Mark mode, if the mark is active, operate on the contents
of the region instead.

\(fn COLS)" nil nil)

(autoload 'haskell-move-nested-right "haskell-move-nested" "\
Increase indentation of the following off-side-rule block adjacent to point.

Use a numeric prefix argument to indicate amount of indentation to apply.

In Transient Mark mode, if the mark is active, operate on the contents
of the region instead.

\(fn COLS)" t nil)

(autoload 'haskell-move-nested-left "haskell-move-nested" "\
Decrease indentation of the following off-side-rule block adjacent to point.

Use a numeric prefix argument to indicate amount of indentation to apply.

In Transient Mark mode, if the mark is active, operate on the contents
of the region instead.

\(fn COLS)" t nil)

(register-definition-prefixes "haskell-move-nested" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-navigate-imports" "haskell-navigate-imports.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-navigate-imports.el

(autoload 'haskell-navigate-imports "haskell-navigate-imports" "\
Cycle the Haskell import lines or return to point (with prefix arg).

\(fn &optional RETURN)" t nil)

(autoload 'haskell-navigate-imports-go "haskell-navigate-imports" "\
Go to the first line of a list of consecutive import lines. Cycles." t nil)

(autoload 'haskell-navigate-imports-return "haskell-navigate-imports" "\
Return to the non-import point we were at before going to the module list.
   If we were originally at an import list, we can just cycle through easily." t nil)

(register-definition-prefixes "haskell-navigate-imports" '("haskell-navigate-imports-"))

;;;***

;;;### (autoloads nil "haskell-presentation-mode" "haskell-presentation-mode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-presentation-mode.el

(register-definition-prefixes "haskell-presentation-mode" '("haskell-presentation-"))

;;;***

;;;### (autoloads nil "haskell-process" "haskell-process.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from haskell-process.el

(register-definition-prefixes "haskell-process" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-repl" "haskell-repl.el" (0 0 0 0))
;;; Generated autoloads from haskell-repl.el

(register-definition-prefixes "haskell-repl" '("haskell-interactive-"))

;;;***

;;;### (autoloads nil "haskell-sandbox" "haskell-sandbox.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from haskell-sandbox.el

(register-definition-prefixes "haskell-sandbox" '("haskell-sandbox-"))

;;;***

;;;### (autoloads nil "haskell-session" "haskell-session.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from haskell-session.el

(autoload 'haskell-session-maybe "haskell-session" "\
Maybe get the Haskell session, return nil if there isn't one." nil nil)

(autoload 'haskell-session-process "haskell-session" "\
Get the session process.

\(fn S)" nil nil)

(register-definition-prefixes "haskell-session" '("haskell-session"))

;;;***

;;;### (autoloads nil "haskell-sort-imports" "haskell-sort-imports.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-sort-imports.el

(autoload 'haskell-sort-imports "haskell-sort-imports" "\
Sort the import list at point. It sorts the current group
i.e. an import list separated by blank lines on either side.

If the region is active, it will restrict the imports to sort
within that region." t nil)

(register-definition-prefixes "haskell-sort-imports" '("haskell-sort-imports-"))

;;;***

;;;### (autoloads nil "haskell-string" "haskell-string.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from haskell-string.el

(register-definition-prefixes "haskell-string" '("haskell-"))

;;;***

;;;### (autoloads nil "haskell-svg" "haskell-svg.el" (0 0 0 0))
;;; Generated autoloads from haskell-svg.el

(register-definition-prefixes "haskell-svg" '("haskell-svg-"))

;;;***

;;;### (autoloads nil "haskell-unicode-input-method" "haskell-unicode-input-method.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from haskell-unicode-input-method.el

(autoload 'haskell-unicode-input-method-enable "haskell-unicode-input-method" "\
Set input method `haskell-unicode'." t nil)

(define-obsolete-function-alias 'turn-on-haskell-unicode-input-method 'haskell-unicode-input-method-enable "2020-04")

;;;***

;;;### (autoloads nil "haskell-utils" "haskell-utils.el" (0 0 0 0))
;;; Generated autoloads from haskell-utils.el

(register-definition-prefixes "haskell-utils" '("haskell-"))

;;;***

;;;### (autoloads nil "highlight-uses-mode" "highlight-uses-mode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from highlight-uses-mode.el

(autoload 'highlight-uses-mode "highlight-uses-mode" "\
Minor mode for highlighting and jumping between uses.

If called interactively, toggle `Highlight-Uses mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "highlight-uses-mode" '("highlight-uses-mode-"))

;;;***

;;;### (autoloads nil "inf-haskell" "inf-haskell.el" (0 0 0 0))
;;; Generated autoloads from inf-haskell.el

(autoload 'run-haskell "inf-haskell" "\
Show the inferior-haskell buffer.  Start the process if needed." t nil)

(register-definition-prefixes "inf-haskell" '("haskell-" "inf"))

;;;***

;;;### (autoloads nil "w3m-haddock" "w3m-haddock.el" (0 0 0 0))
;;; Generated autoloads from w3m-haddock.el

(register-definition-prefixes "w3m-haddock" '("haskell-w3m-" "w3m-haddock-"))

;;;***

;;;### (autoloads nil nil ("haskell-mode-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; haskell-mode-autoloads.el ends here
