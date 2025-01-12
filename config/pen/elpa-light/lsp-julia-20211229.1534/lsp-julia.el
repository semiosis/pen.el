;;; lsp-julia.el --- Julia support for lsp-mode   -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Martin Wolke, 2018 Adam Beckmeyer, 2019-2021 Guido Kraemer

;; Author: Martin Wolke <vibhavp@gmail.com>
;;         Adam Beckmeyer <adam_git@thebeckmeyers.xyz>
;;         Guido Kraemer <gdkrmr@users.noreply.github.com>
;; Maintainer: Guido Kraemer <gdkrmr@users.noreply.github.com>
;; Keywords: languages, tools
;; Version: 0.7.0
;; Package-Requires: ((emacs "25.1") (lsp-mode "6.3") (julia-mode "0.3"))
;; Keywords: languages, tools
;; URL: https://github.com/gdkrmr/lsp-julia

;;; License:

;; The MIT License (MIT)

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.

;;; Commentary:

;; This version of lsp-julia requires julia 1.7 to run.
;; Manual installation:

;; (require 'julia-mode)
;; (push "/path/to/lsp-julia" load-path)
;; (require 'lsp-julia)
;; (require 'lsp-mode)
;; ;; Configure lsp + julia
;; (add-hook 'julia-mode-hook #'lsp-mode)
;; (add-hook 'julia-mode-hook #'lsp)


;;; Code:

(require 'lsp-mode)
(require 'find-func)

(defconst lsp-julia--self-path
  (file-name-directory (find-library-name "lsp-julia")))

(defcustom lsp-julia-package-dir (concat lsp-julia--self-path "languageserver")
  "The path where `LanguageServer.jl' and friends are installed.
Set to nil if you want to use the globally installed versions."
  :type 'string
  :group 'lsp-julia)

(defcustom lsp-julia-default-environment "~/.julia/environments/v1.0"
  "The path to the default environment."
  :type 'string
  :group 'lsp-julia)

(defcustom lsp-julia-command "julia"
  "Command to invoke julia with."
  :type 'string
  :group 'lsp-julia)

(defcustom lsp-julia-flags (if lsp-julia-package-dir
                               `(,(concat "--project=" lsp-julia-package-dir)
                                 "--startup-file=no"
                                 "--history-file=no")
                             '("--startup-file=no"
                               "--history-file=no"))
  "List of additional flags to call julia with."
  :type '(repeat (string :tag "argument"))
  :group 'lsp-julia)

(defcustom lsp-julia-symbol-server-store-path "~/.julia/symbolstorev2-lsp-julia"
  "The cache directory for `SymbolServer.jl'."
  :type 'directory
  ;; :initialize (lambda (sym expr)
  ;;               (print expr)
  ;;               (when expr (make-directory expr t) expr))
  :group 'lsp-julia)


(defcustom lsp-julia-timeout 30
  "Time before symbol `lsp-mode' should assume julia just ain't gonna start."
  :type 'number
  :group 'lsp-julia)

(defcustom lsp-julia-default-depot ""
  "The default depot path, used if `JULIA_DEPOT_PATH' is unset."
  :type 'string
  :group 'lsp-julia)

;;; Workspace options
(defcustom lsp-julia-format-indent 4
  "Indent size for formatting."
  :type 'integer
  :group 'lsp-julia)

(defcustom lsp-julia-format-indents t
  "Format file indents."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-ops t
  "Format whitespace around operators."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-tuples t
  "Format tuples."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-curly t
  "Format braces."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-calls t
  "Format function calls."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-iterops t
  "Format loop iterators."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-comments t
  "Format comments."
  :type 'boolean
  :group 'lsp-julia)
(defcustom lsp-julia-format-docs t
  "Format inline documentation."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-format-kw t
  "Remove spaces around = in function keywords."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-run t
  "Run the linter on active files."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-missingrefs "all"
  "Highlight unknown symbols. The `symbols` option will not mark
unknown fields."
  :type 'string
  :options '("none" "symbols" "all")
  :group 'lsp-julia)

(defcustom lsp-julia-lint-call t
  "This compares call signatures against all known methods for
the called function. Calls with too many or too few arguments, or
unknown keyword parameters are highlighted."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-iter t
  "Check iterator syntax of loops. Will identify, for example,
attempts to iterate over single values."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-constif t
  "Check for constant conditionals in if statements that result
in branches never being reached.."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-lazy t
  "Check for deterministic lazy boolean operators."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-datadecl t
  "Check variables used in type declarations are datatypes."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-typeparam t
  "Check parameters declared in `where` statements or datatype
declarations are used."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-modname t
  "Check submodule names do not shadow their parent's name."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-pirates t
  "Check for type piracy - the overloading of external functions
with methods specified for external datatypes. 'External' here
refers to imported code."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-useoffuncargs t
  "Check that all declared arguments are used within the function
body."
  :type 'boolean
  :group 'lsp-julia)

(defcustom lsp-julia-lint-nothingcomp t
  "Check for use of `==` rather than `===` when comparing against
`nothing`."
  :type 'boolean
  :group 'lsp-julia)

(lsp-register-custom-settings
 '(("julia.format.indent"      lsp-julia-format-indent)
   ("julia.format.indents"     lsp-julia-format-indents     t)
   ("julia.format.ops"         lsp-julia-format-ops         t)
   ("julia.format.tuples"      lsp-julia-format-tuples      t)
   ("julia.format.curly"       lsp-julia-format-curly       t)
   ("julia.format.calls"       lsp-julia-format-calls       t)
   ("julia.format.iterOps"     lsp-julia-format-iterops     t)
   ("julia.format.comments"    lsp-julia-format-comments    t)
   ("julia.format.docs"        lsp-julia-format-docs        t)
   ("julia.format.kw"          lsp-julia-format-kw          t)
   ("julia.lint.run"           lsp-julia-lint-run           t)
   ("julia.lint.missingrefs"   lsp-julia-lint-missingrefs)
   ("julia.lint.call"          lsp-julia-lint-call          t)
   ("julia.lint.iter"          lsp-julia-lint-iter          t)
   ("julia.lint.constif"       lsp-julia-lint-constif       t)
   ("julia.lint.lazyif"        lsp-julia-lint-lazy          t)
   ("julia.lint.datadecl"      lsp-julia-lint-datadecl      t)
   ("julia.lint.typeparam"     lsp-julia-lint-typeparam     t)
   ("julia.lint.modname"       lsp-julia-lint-modname       t)
   ("julia.lint.pirates"       lsp-julia-lint-pirates       t)
   ("julia.lint.useoffuncargs" lsp-julia-lint-useoffuncargs t)
   ("julia.lint.nothingcomp"   lsp-julia-lint-nothingcomp   t)))

;;; lsp-julia related functions setup
(defun lsp-julia--get-root ()
  "Get the (Julia) project root directory of the current file."
  (concat "\""
          (expand-file-name
           (or (locate-dominating-file buffer-file-name "Project.toml")
               (locate-dominating-file buffer-file-name "JuliaProject.toml")
               lsp-julia-default-environment))
          "\""))

(defun lsp-julia--get-depot-path ()
  "Get the (Julia) depot path."
  (let* ((dp (getenv "JULIA_DEPOT_PATH"))
         (dp2 (if dp dp lsp-julia-default-depot)))
    (concat "\"" dp2 "\"")))

(defun lsp-julia--symbol-server-store-path-to-jl ()
  "Convert the variable `lsp-julia-symbol-server-store-path' to a
  string or \"nothing\" if `nil'"
  (if lsp-julia-symbol-server-store-path
      (let ((sssp (expand-file-name lsp-julia-symbol-server-store-path)))
        (make-directory sssp t)
        (concat "\"" sssp "\""))
    "nothing"))

(defun lsp-julia--rls-command ()
  "The command to lauch the Julia Language Server."
  `(,lsp-julia-command
    ,@lsp-julia-flags
    ,(concat "-e"
             "import Pkg; Pkg.instantiate(); "
             "using LanguageServer, LanguageServer.SymbolServer;"
             ;; " Union{Int64, String}(x::String) = x; "
             " server = LanguageServer.LanguageServerInstance("
             " stdin, stdout,"
             (lsp-julia--get-root) ","
             (lsp-julia--get-depot-path) ","
             " nothing, "
             (lsp-julia--symbol-server-store-path-to-jl) ");"
             " run(server);")))

(defun lsp-julia-update-languageserver ()
  "The command to update the Julia Language Server."
  (interactive)
  (apply 'start-process
         "lsp-julia-languageserver-updater"
         "*lsp-julia-languageserver-updater*"
         lsp-julia-command
         (append lsp-julia-flags
                 '("-e import Pkg; println(Pkg.project().path); Pkg.update()"))
         ))

(defconst lsp-julia--handlers
  '(("window/setStatusBusy" .
     (lambda (w _p)))
    ("window/setStatusReady" .
     (lambda(w _p)))))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection 'lsp-julia--rls-command)
                  :major-modes '(julia-mode ess-julia-mode)
                  :server-id 'julia-ls
                  :multi-root t))

(provide 'lsp-julia)
;;; lsp-julia.el ends here
