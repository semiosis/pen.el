;;; lsp-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "lsp-actionscript" "lsp-actionscript.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from lsp-actionscript.el

(register-definition-prefixes "lsp-actionscript" '("lsp-actionscript-"))

;;;***

;;;### (autoloads nil "lsp-ada" "lsp-ada.el" (0 0 0 0))
;;; Generated autoloads from lsp-ada.el

(register-definition-prefixes "lsp-ada" '("lsp-ada-"))

;;;***

;;;### (autoloads nil "lsp-angular" "lsp-angular.el" (0 0 0 0))
;;; Generated autoloads from lsp-angular.el

(register-definition-prefixes "lsp-angular" '("lsp-client"))

;;;***

;;;### (autoloads nil "lsp-bash" "lsp-bash.el" (0 0 0 0))
;;; Generated autoloads from lsp-bash.el

(register-definition-prefixes "lsp-bash" '("lsp-bash-"))

;;;***

;;;### (autoloads nil "lsp-beancount" "lsp-beancount.el" (0 0 0 0))
;;; Generated autoloads from lsp-beancount.el

(register-definition-prefixes "lsp-beancount" '("lsp-beancount-"))

;;;***

;;;### (autoloads nil "lsp-clangd" "lsp-clangd.el" (0 0 0 0))
;;; Generated autoloads from lsp-clangd.el

(autoload 'lsp-cpp-flycheck-clang-tidy-error-explainer "lsp-clangd" "\
Explain a clang-tidy ERROR by scraping documentation from llvm.org.

\(fn ERROR)" nil nil)

(register-definition-prefixes "lsp-clangd" '("lsp-c"))

;;;***

;;;### (autoloads nil "lsp-clojure" "lsp-clojure.el" (0 0 0 0))
;;; Generated autoloads from lsp-clojure.el

(register-definition-prefixes "lsp-clojure" '("lsp-clojure-"))

;;;***

;;;### (autoloads nil "lsp-completion" "lsp-completion.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from lsp-completion.el

(define-obsolete-variable-alias 'lsp-prefer-capf 'lsp-completion-provider "lsp-mode 7.0.1")

(define-obsolete-variable-alias 'lsp-enable-completion-at-point 'lsp-completion-enable "lsp-mode 7.0.1")

(autoload 'lsp-completion-at-point "lsp-completion" "\
Get lsp completions." nil nil)

(autoload 'lsp-completion--enable "lsp-completion" "\
Enable LSP completion support." nil nil)

(autoload 'lsp-completion-mode "lsp-completion" "\
Toggle LSP completion support.

If called interactively, toggle `Lsp-Completion mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(add-hook 'lsp-configure-hook (lambda nil (when (and lsp-auto-configure lsp-completion-enable) (lsp-completion--enable))))

(register-definition-prefixes "lsp-completion" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-crystal" "lsp-crystal.el" (0 0 0 0))
;;; Generated autoloads from lsp-crystal.el

(register-definition-prefixes "lsp-crystal" '("lsp-clients-crystal-executable"))

;;;***

;;;### (autoloads nil "lsp-csharp" "lsp-csharp.el" (0 0 0 0))
;;; Generated autoloads from lsp-csharp.el

(register-definition-prefixes "lsp-csharp" '("lsp-csharp-"))

;;;***

;;;### (autoloads nil "lsp-css" "lsp-css.el" (0 0 0 0))
;;; Generated autoloads from lsp-css.el

(register-definition-prefixes "lsp-css" '("lsp-css-"))

;;;***

;;;### (autoloads nil "lsp-diagnostics" "lsp-diagnostics.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from lsp-diagnostics.el

(define-obsolete-variable-alias 'lsp-diagnostic-package 'lsp-diagnostics-provider "lsp-mode 7.0.1")

(define-obsolete-variable-alias 'lsp-flycheck-default-level 'lsp-diagnostics-flycheck-default-level "lsp-mode 7.0.1")

(autoload 'lsp-diagnostics-lsp-checker-if-needed "lsp-diagnostics" nil nil nil)

(autoload 'lsp-diagnostics--enable "lsp-diagnostics" "\
Enable LSP checker support." nil nil)

(autoload 'lsp-diagnostics-mode "lsp-diagnostics" "\
Toggle LSP diagnostics integration.

If called interactively, toggle `Lsp-Diagnostics mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(add-hook 'lsp-configure-hook (lambda nil (when lsp-auto-configure (lsp-diagnostics--enable))))

(register-definition-prefixes "lsp-diagnostics" '("lsp-diagnostics-"))

;;;***

;;;### (autoloads nil "lsp-dired" "lsp-dired.el" (0 0 0 0))
;;; Generated autoloads from lsp-dired.el

(defvar lsp-dired-mode nil "\
Non-nil if Lsp-Dired mode is enabled.
See the `lsp-dired-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `lsp-dired-mode'.")

(custom-autoload 'lsp-dired-mode "lsp-dired" nil)

(autoload 'lsp-dired-mode "lsp-dired" "\
Display `lsp-mode' icons for each file in a dired buffer.

If called interactively, toggle `Lsp-Dired mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "lsp-dired" '("lsp-dired-"))

;;;***

;;;### (autoloads nil "lsp-dockerfile" "lsp-dockerfile.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from lsp-dockerfile.el

(register-definition-prefixes "lsp-dockerfile" '("lsp-dockerfile-language-server-command"))

;;;***

;;;### (autoloads nil "lsp-elixir" "lsp-elixir.el" (0 0 0 0))
;;; Generated autoloads from lsp-elixir.el

(register-definition-prefixes "lsp-elixir" '("lsp-elixir-"))

;;;***

;;;### (autoloads nil "lsp-elm" "lsp-elm.el" (0 0 0 0))
;;; Generated autoloads from lsp-elm.el

(register-definition-prefixes "lsp-elm" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-erlang" "lsp-erlang.el" (0 0 0 0))
;;; Generated autoloads from lsp-erlang.el

(register-definition-prefixes "lsp-erlang" '("lsp-erlang-server-"))

;;;***

;;;### (autoloads nil "lsp-eslint" "lsp-eslint.el" (0 0 0 0))
;;; Generated autoloads from lsp-eslint.el

(register-definition-prefixes "lsp-eslint" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-fortran" "lsp-fortran.el" (0 0 0 0))
;;; Generated autoloads from lsp-fortran.el

(register-definition-prefixes "lsp-fortran" '("lsp-clients-"))

;;;***

;;;### (autoloads nil "lsp-fsharp" "lsp-fsharp.el" (0 0 0 0))
;;; Generated autoloads from lsp-fsharp.el

(autoload 'lsp-fsharp--workspace-load "lsp-fsharp" "\
Load all of the provided PROJECTS.

\(fn PROJECTS)" nil nil)

(register-definition-prefixes "lsp-fsharp" '("lsp-fsharp-"))

;;;***

;;;### (autoloads nil "lsp-gdscript" "lsp-gdscript.el" (0 0 0 0))
;;; Generated autoloads from lsp-gdscript.el

(register-definition-prefixes "lsp-gdscript" '("lsp-gdscript-"))

;;;***

;;;### (autoloads nil "lsp-go" "lsp-go.el" (0 0 0 0))
;;; Generated autoloads from lsp-go.el

(register-definition-prefixes "lsp-go" '("lsp-go-"))

;;;***

;;;### (autoloads nil "lsp-groovy" "lsp-groovy.el" (0 0 0 0))
;;; Generated autoloads from lsp-groovy.el

(register-definition-prefixes "lsp-groovy" '("lsp-groovy-"))

;;;***

;;;### (autoloads nil "lsp-hack" "lsp-hack.el" (0 0 0 0))
;;; Generated autoloads from lsp-hack.el

(register-definition-prefixes "lsp-hack" '("lsp-clients-hack-command"))

;;;***

;;;### (autoloads nil "lsp-haxe" "lsp-haxe.el" (0 0 0 0))
;;; Generated autoloads from lsp-haxe.el

(register-definition-prefixes "lsp-haxe" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-headerline" "lsp-headerline.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from lsp-headerline.el

(autoload 'lsp-headerline-breadcrumb-mode "lsp-headerline" "\
Toggle breadcrumb on headerline.

If called interactively, toggle `Lsp-Headerline-Breadcrumb mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'lsp-breadcrumb-go-to-symbol "lsp-headerline" "\
Go to the symbol on breadcrumb at SYMBOL-POSITION.

\(fn SYMBOL-POSITION)" t nil)

(autoload 'lsp-breadcrumb-narrow-to-symbol "lsp-headerline" "\
Narrow to the symbol range on breadcrumb at SYMBOL-POSITION.

\(fn SYMBOL-POSITION)" t nil)

(register-definition-prefixes "lsp-headerline" '("lsp-headerline-"))

;;;***

;;;### (autoloads nil "lsp-html" "lsp-html.el" (0 0 0 0))
;;; Generated autoloads from lsp-html.el

(register-definition-prefixes "lsp-html" '("lsp-html-"))

;;;***

;;;### (autoloads nil "lsp-icons" "lsp-icons.el" (0 0 0 0))
;;; Generated autoloads from lsp-icons.el

(register-definition-prefixes "lsp-icons" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-ido" "lsp-ido.el" (0 0 0 0))
;;; Generated autoloads from lsp-ido.el

(autoload 'lsp-ido-workspace-symbol "lsp-ido" "\
`ido' for lsp workspace/symbol.
When called with prefix ARG the default selection will be symbol at point.

\(fn ARG)" t nil)

(register-definition-prefixes "lsp-ido" '("lsp-ido-"))

;;;***

;;;### (autoloads nil "lsp-iedit" "lsp-iedit.el" (0 0 0 0))
;;; Generated autoloads from lsp-iedit.el

(autoload 'lsp-iedit-highlights "lsp-iedit" "\
Start an `iedit' operation on the documentHighlights at point.
This can be used as a primitive `lsp-rename' replacement if the
language server doesn't support renaming.

See also `lsp-enable-symbol-highlighting'." t nil)

(autoload 'lsp-evil-multiedit-highlights "lsp-iedit" "\
Start an `evil-multiedit' operation on the documentHighlights at point.
This can be used as a primitive `lsp-rename' replacement if the
language server doesn't support renaming.

See also `lsp-enable-symbol-highlighting'." t nil)

(register-definition-prefixes "lsp-iedit" '("lsp-iedit--on-ranges"))

;;;***

;;;### (autoloads nil "lsp-javascript" "lsp-javascript.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from lsp-javascript.el

(register-definition-prefixes "lsp-javascript" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-json" "lsp-json.el" (0 0 0 0))
;;; Generated autoloads from lsp-json.el

(register-definition-prefixes "lsp-json" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-kotlin" "lsp-kotlin.el" (0 0 0 0))
;;; Generated autoloads from lsp-kotlin.el

(register-definition-prefixes "lsp-kotlin" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-lens" "lsp-lens.el" (0 0 0 0))
;;; Generated autoloads from lsp-lens.el

(autoload 'lsp-lens--enable "lsp-lens" "\
Enable lens mode." nil nil)

(autoload 'lsp-lens-show "lsp-lens" "\
Display lenses in the buffer." t nil)

(autoload 'lsp-lens-hide "lsp-lens" "\
Delete all lenses." t nil)

(autoload 'lsp-lens-mode "lsp-lens" "\
Toggle code-lens overlays.

If called interactively, toggle `Lsp-Lens mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'lsp-avy-lens "lsp-lens" "\
Click lsp lens using `avy' package." t nil)

(register-definition-prefixes "lsp-lens" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-lua" "lsp-lua.el" (0 0 0 0))
;;; Generated autoloads from lsp-lua.el

(register-definition-prefixes "lsp-lua" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-markdown" "lsp-markdown.el" (0 0 0 0))
;;; Generated autoloads from lsp-markdown.el

(register-definition-prefixes "lsp-markdown" '("lsp-markdown-"))

;;;***

;;;### (autoloads nil "lsp-mode" "lsp-mode.el" (0 0 0 0))
;;; Generated autoloads from lsp-mode.el
(put 'lsp-enable-file-watchers 'safe-local-variable #'booleanp)
(put 'lsp-file-watch-threshold 'safe-local-variable (lambda (i) (or (numberp i) (not i))))

(autoload 'lsp-load-vscode-workspace "lsp-mode" "\
Load vscode workspace from FILE

\(fn FILE)" t nil)

(autoload 'lsp-save-vscode-workspace "lsp-mode" "\
Save vscode workspace to FILE

\(fn FILE)" t nil)

(autoload 'lsp-install-server "lsp-mode" "\
Interactively install server.
When prefix UPDATE? is t force installation even if the server is present.

\(fn UPDATE\\=\\? &optional SERVER-ID)" t nil)

(autoload 'lsp-ensure-server "lsp-mode" "\
Ensure server SERVER-ID

\(fn SERVER-ID)" nil nil)

(autoload 'lsp "lsp-mode" "\
Entry point for the server startup.
When ARG is t the lsp mode will start new language server even if
there is language server which can handle current language. When
ARG is nil current file will be opened in multi folder language
server if there is such. When `lsp' is called with prefix
argument ask the user to select which language server to start.

\(fn &optional ARG)" t nil)

(autoload 'lsp-deferred "lsp-mode" "\
Entry point that defers server startup until buffer is visible.
`lsp-deferred' will wait until the buffer is visible before invoking `lsp'.
This avoids overloading the server with many files when starting Emacs." nil nil)

(register-definition-prefixes "lsp-mode" '("lsp-" "make-lsp-client" "when-lsp-workspace" "with-lsp-workspace"))

;;;***

;;;### (autoloads nil "lsp-modeline" "lsp-modeline.el" (0 0 0 0))
;;; Generated autoloads from lsp-modeline.el

(define-obsolete-variable-alias 'lsp-diagnostics-modeline-scope 'lsp-modeline-diagnostics-scope "lsp-mode 7.0.1")

(autoload 'lsp-modeline-code-actions-mode "lsp-modeline" "\
Toggle code actions on modeline.

If called interactively, toggle `Lsp-Modeline-Code-Actions mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(define-obsolete-function-alias 'lsp-diagnostics-modeline-mode 'lsp-modeline-diagnostics-mode "lsp-mode 7.0.1")

(autoload 'lsp-modeline-diagnostics-mode "lsp-modeline" "\
Toggle diagnostics modeline.

If called interactively, toggle `Lsp-Modeline-Diagnostics mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'lsp-modeline-workspace-status-mode "lsp-modeline" "\
Toggle workspace status on modeline.

If called interactively, toggle `Lsp-Modeline-Workspace-Status
mode'.  If the prefix argument is positive, enable the mode, and
if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "lsp-modeline" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-nix" "lsp-nix.el" (0 0 0 0))
;;; Generated autoloads from lsp-nix.el

(register-definition-prefixes "lsp-nix" '("lsp-nix-server-path"))

;;;***

;;;### (autoloads nil "lsp-ocaml" "lsp-ocaml.el" (0 0 0 0))
;;; Generated autoloads from lsp-ocaml.el

(register-definition-prefixes "lsp-ocaml" '("lsp-ocaml-l"))

;;;***

;;;### (autoloads nil "lsp-perl" "lsp-perl.el" (0 0 0 0))
;;; Generated autoloads from lsp-perl.el

(register-definition-prefixes "lsp-perl" '("lsp-perl-"))

;;;***

;;;### (autoloads nil "lsp-php" "lsp-php.el" (0 0 0 0))
;;; Generated autoloads from lsp-php.el

(register-definition-prefixes "lsp-php" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-prolog" "lsp-prolog.el" (0 0 0 0))
;;; Generated autoloads from lsp-prolog.el

(register-definition-prefixes "lsp-prolog" '("lsp-prolog-server-command"))

;;;***

;;;### (autoloads nil "lsp-protocol" "lsp-protocol.el" (0 0 0 0))
;;; Generated autoloads from lsp-protocol.el

(register-definition-prefixes "lsp-protocol" '("dash-expand:&RangeToPoint" "lsp"))

;;;***

;;;### (autoloads nil "lsp-purescript" "lsp-purescript.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from lsp-purescript.el

(register-definition-prefixes "lsp-purescript" '("lsp-purescript-"))

;;;***

;;;### (autoloads nil "lsp-pwsh" "lsp-pwsh.el" (0 0 0 0))
;;; Generated autoloads from lsp-pwsh.el

(register-definition-prefixes "lsp-pwsh" '("lsp-pwsh-"))

;;;***

;;;### (autoloads nil "lsp-pyls" "lsp-pyls.el" (0 0 0 0))
;;; Generated autoloads from lsp-pyls.el

(register-definition-prefixes "lsp-pyls" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-pylsp" "lsp-pylsp.el" (0 0 0 0))
;;; Generated autoloads from lsp-pylsp.el

(register-definition-prefixes "lsp-pylsp" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-r" "lsp-r.el" (0 0 0 0))
;;; Generated autoloads from lsp-r.el

(register-definition-prefixes "lsp-r" '("lsp-clients-r-server-command"))

;;;***

;;;### (autoloads nil "lsp-racket" "lsp-racket.el" (0 0 0 0))
;;; Generated autoloads from lsp-racket.el

(register-definition-prefixes "lsp-racket" '("lsp-racket-lang"))

;;;***

;;;### (autoloads nil "lsp-rf" "lsp-rf.el" (0 0 0 0))
;;; Generated autoloads from lsp-rf.el

(register-definition-prefixes "lsp-rf" '("expand-start-command" "lsp-rf-language-server-" "parse-rf-language-server-"))

;;;***

;;;### (autoloads nil "lsp-rust" "lsp-rust.el" (0 0 0 0))
;;; Generated autoloads from lsp-rust.el

(register-definition-prefixes "lsp-rust" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-semantic-tokens" "lsp-semantic-tokens.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from lsp-semantic-tokens.el

(autoload 'lsp--semantic-tokens-initialize-buffer "lsp-semantic-tokens" "\
Initialize the buffer for semantic tokens.
IS-RANGE-PROVIDER is non-nil when server supports range requests." nil nil)

(autoload 'lsp--semantic-tokens-initialize-workspace "lsp-semantic-tokens" "\
Initialize semantic tokens for WORKSPACE.

\(fn WORKSPACE)" nil nil)

(autoload 'lsp-semantic-tokens--warn-about-deprecated-setting "lsp-semantic-tokens" "\
Warn about deprecated semantic highlighting variable." nil nil)

(autoload 'lsp-semantic-tokens--enable "lsp-semantic-tokens" "\
Enable semantic tokens mode." nil nil)

(autoload 'lsp-semantic-tokens-mode "lsp-semantic-tokens" "\
Toggle semantic-tokens support.

If called interactively, toggle `Lsp-Semantic-Tokens mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "lsp-semantic-tokens" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-solargraph" "lsp-solargraph.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from lsp-solargraph.el

(register-definition-prefixes "lsp-solargraph" '("lsp-solargraph-"))

;;;***

;;;### (autoloads nil "lsp-sorbet" "lsp-sorbet.el" (0 0 0 0))
;;; Generated autoloads from lsp-sorbet.el

(register-definition-prefixes "lsp-sorbet" '("lsp-sorbet-"))

;;;***

;;;### (autoloads nil "lsp-sqls" "lsp-sqls.el" (0 0 0 0))
;;; Generated autoloads from lsp-sqls.el

(register-definition-prefixes "lsp-sqls" '("lsp-sql"))

;;;***

;;;### (autoloads nil "lsp-steep" "lsp-steep.el" (0 0 0 0))
;;; Generated autoloads from lsp-steep.el

(register-definition-prefixes "lsp-steep" '("lsp-steep-"))

;;;***

;;;### (autoloads nil "lsp-svelte" "lsp-svelte.el" (0 0 0 0))
;;; Generated autoloads from lsp-svelte.el

(register-definition-prefixes "lsp-svelte" '("lsp-svelte-plugin-"))

;;;***

;;;### (autoloads nil "lsp-terraform" "lsp-terraform.el" (0 0 0 0))
;;; Generated autoloads from lsp-terraform.el

(register-definition-prefixes "lsp-terraform" '("lsp-terraform-"))

;;;***

;;;### (autoloads nil "lsp-tex" "lsp-tex.el" (0 0 0 0))
;;; Generated autoloads from lsp-tex.el

(register-definition-prefixes "lsp-tex" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-v" "lsp-v.el" (0 0 0 0))
;;; Generated autoloads from lsp-v.el

(register-definition-prefixes "lsp-v" '("lsp-v-vls-executable"))

;;;***

;;;### (autoloads nil "lsp-vala" "lsp-vala.el" (0 0 0 0))
;;; Generated autoloads from lsp-vala.el

(register-definition-prefixes "lsp-vala" '("lsp-clients-vala-ls-executable"))

;;;***

;;;### (autoloads nil "lsp-verilog" "lsp-verilog.el" (0 0 0 0))
;;; Generated autoloads from lsp-verilog.el

(register-definition-prefixes "lsp-verilog" '("lsp-clients-"))

;;;***

;;;### (autoloads nil "lsp-vetur" "lsp-vetur.el" (0 0 0 0))
;;; Generated autoloads from lsp-vetur.el

(register-definition-prefixes "lsp-vetur" '("lsp-"))

;;;***

;;;### (autoloads nil "lsp-vhdl" "lsp-vhdl.el" (0 0 0 0))
;;; Generated autoloads from lsp-vhdl.el

(register-definition-prefixes "lsp-vhdl" '("ghdl-ls-bin-name" "hdl-checker-bin-name" "lsp-vhdl-" "vhdl-"))

;;;***

;;;### (autoloads nil "lsp-vimscript" "lsp-vimscript.el" (0 0 0 0))
;;; Generated autoloads from lsp-vimscript.el

(register-definition-prefixes "lsp-vimscript" '("lsp-clients-vim-"))

;;;***

;;;### (autoloads nil "lsp-xml" "lsp-xml.el" (0 0 0 0))
;;; Generated autoloads from lsp-xml.el

(register-definition-prefixes "lsp-xml" '("lsp-xml-"))

;;;***

;;;### (autoloads nil "lsp-yaml" "lsp-yaml.el" (0 0 0 0))
;;; Generated autoloads from lsp-yaml.el

(register-definition-prefixes "lsp-yaml" '("lsp-yaml-"))

;;;***

;;;### (autoloads nil "lsp-zig" "lsp-zig.el" (0 0 0 0))
;;; Generated autoloads from lsp-zig.el

(register-definition-prefixes "lsp-zig" '("lsp-zig-zls-executable"))

;;;***

;;;### (autoloads nil nil ("lsp-cmake.el" "lsp-d.el" "lsp-dhall.el"
;;;;;;  "lsp-mode-pkg.el" "lsp-nim.el" "lsp.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; lsp-mode-autoloads.el ends here
