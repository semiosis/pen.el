;;; meson-mode.el --- Major mode for the Meson build system files  -*- lexical-binding: t; -*-

;; Copyright (C) 2017, 2020, 2021  Michal Sojka

;; Author: Michal Sojka <sojkam1@fel.cvut.cz>
;; Version: 0.2
;; Keywords: languages, tools
;; URL: https://github.com/wentasah/meson-mode
;; Package-Requires: ((emacs "26.1"))

;; This program is free software; you can redistribute it and/or modify
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

;; This is a major mode for Meson build system files.  Syntax
;; highlighting works reliably.  Indentation works too, but there are
;; probably cases, where it breaks.  Simple completion is supported
;; via `completion-at-point'.  To start completion, use either C-M-i
;; or install completion frameworks such as `company'.  To enable
;; `company' add the following to your .emacs:
;;
;;     (add-hook 'meson-mode-hook 'company-mode)


;;; Code:

(require 'compile)
(require 'seq)
(eval-when-compile (require 'subr-x))

(defvar meson-mode-syntax-table
  (let ((table (make-syntax-table))
	(list (list ?\# "<"
		    ?\n ">#"
		    ?\' "\"'" ; See also meson-syntax-propertize-function
		    ?\" "."
		    ?\$ "."
		    ?\& "."
		    ?\* "."
		    ?\+ "."
		    ?\- "."
		    ?\< "."
		    ?\> "."
		    ?\= "."
		    ?\/ "."
		    ?\| ".")))
    (while list
      (modify-syntax-entry (pop list) (pop list) table))
    table)
  "Syntax table used while in `meson-mode'.")

(defun meson--max-length (&rest args)
  "Return maximum length among strings in ARGS.
If some arguments are numbers, threat them as string lengths."
  (let ((lengths
	 (mapcar (lambda (x) (if (stringp x) (length x) x)) args)))
    (apply 'max lengths)))

(eval-and-compile
  (defconst meson-keywords
    '("true" "false" "if" "else" "elif" "endif" "and" "or" "not"
      "foreach" "endforeach" "in" "continue" "break")))

(defconst meson-keywords-regexp
  (rx symbol-start (eval `(or ,@meson-keywords)) symbol-end))

(require 'cl-lib)

(defconst meson-keywords-max-length
  (cl-reduce 'meson--max-length meson-keywords))

(eval-and-compile
  (defconst meson-builtin-functions
    '(("add_global_arguments" :doc "void add_global_arguments(arg1, arg2, ...)")
      ("add_global_link_arguments" :doc "void add_global_link_arguments(*arg1*, *arg2*, ...)")
      ("add_languages" :doc "bool add_languages(*langs*)")
      ("add_project_arguments" :doc "void add_project_arguments(arg1, arg2, ...)")
      ("add_project_link_arguments" :doc "void add_project_link_arguments(*arg1*, *arg2*, ...)")
      ("add_test_setup" :doc "void add_test_setup(*name*, ...)")
      ("alias_target")
      ("assert" :doc "void assert(*condition*, *message*)")
      ("benchmark" :doc "void benchmark(name, executable, ...)")
      ("both_libraries" :doc "buildtarget = both_libraries(library_name, list_of_sources, ...)")
      ("build_target" :doc nil)
      ("configuration_data" :doc "configuration_data_object = configuration_data(...)")
      ("configure_file" :doc "generated_file = configure_file(...)")
      ("custom_target" :doc "customtarget custom_target(*name*, ...)")
      ("declare_dependency" :doc "dependency_object declare_dependency(...)")
      ("dependency" :doc "dependency_object dependency(*dependency_name*, ...)")
      ("disabler" :doc nil)
      ("environment" :doc "environment_object environment(...)")
      ("error" :doc "void error(message)")
      ("executable" :doc "buildtarget executable(*exe_name*, *sources*, ...)")
      ("files" :doc "file_array files(list_of_filenames)")
      ("find_library" :doc nil)
      ("find_program" :doc "program find_program(program_name1, program_name2, ...)")
      ("generator" :doc "generator_object generator(*executable*, ...)")
      ("get_option" :doc "value get_option(option_name)")
      ("get_variable" :doc "value get_variable(variable_name, fallback)")
      ("gettext")
      ("import" :doc "module_object import(module_name)")
      ("include_directories" :doc "include_object include_directories(directory_names, ...)")
      ("install_data" :doc "void install_data(list_of_files, ...)")
      ("install_headers" :doc "void install_headers(list_of_headers, ...)")
      ("install_man" :doc "void install_man(list_of_manpages, ...)")
      ("install_subdir" :doc "void install_subdir(subdir_name, install_dir : ..., exclude_files : ..., exclude_directories : ..., strip_directory : ...)")
      ("is_disabler" :doc "bool is_disabler(var)")
      ("is_variable" :doc "bool is_variable(varname)")
      ("jar" :doc nil)
      ("join_paths" :doc "string join_paths(string1, string2, ...)")
      ("library" :doc "buildtarget library(library_name, list_of_sources, ...)")
      ("message" :doc "void message(text)")
      ("option")
      ("project" :doc "void project(project_name, list_of_languages, ...)")
      ("run_command" :doc "runresult run_command(command, list_of_args, ...)")
      ("run_target")
      ("set_variable" :doc "void set_variable(variable_name, value)")
      ("shared_library" :doc "buildtarget shared_library(library_name, list_of_sources, ...)")
      ("shared_module" :doc "buildtarget shared_module(module_name, list_of_sources, ...)")
      ("static_library" :doc "buildtarget static_library(library_name, list_of_sources, ...)")
      ("subdir" :doc "void subdir(dir_name, ...)")
      ("subdir_done" :doc "subdir_done()")
      ("subproject" :doc "subproject_object subproject(subproject_name, ...)")
      ("summary" :doc "void summary(key, value)")
      ("test" :doc "void test(name, executable, ...)")
      ("vcs_tag" :doc "customtarget vcs_tag(...)")
      ("warning" :doc "void warning(text)"))))

(defconst meson-builtin-functions-regexp
  (rx (or line-start (not (any ".")))
      symbol-start
      (group (eval `(or ,@(mapcar 'car meson-builtin-functions))))
      symbol-end
      (zero-or-more whitespace)
      (or "(" line-end)))

(eval-and-compile
  (defconst meson-builtin-vars
    '("meson" "build_machine" "host_machine" "target_machine")))

(defconst meson-builtin-vars-regexp
  (rx symbol-start
      (or (eval `(or ,@meson-builtin-vars)))
      symbol-end))

(defconst meson-var-assign-regexp
  (rx (group (any "_" "a-z" "A-Z") (zero-or-more (any "_" "a-z" "A-Z" "0-9")))
      (zero-or-more whitespace) "=" (not (any "="))))

(eval-and-compile
  (defconst meson-literate-tokens
    '( ;;"(" ")" "[" "]" ; Let syntactic parser handle these efficiently
      "\"" "," "+=" "." "+" "-" "*"
      "%" "/" ":" "==" "!=" "=" "<=" "<" ">=" ">" "?")))

(defconst meson-literate-tokens-max-length
  (cl-reduce 'meson--max-length meson-literate-tokens))

(defconst meson-literate-tokens-regexp
  (rx (eval `(or ,@meson-literate-tokens))))

(defconst meson-methods
  `(("meson\\."
     . ("get_compiler"
	"is_cross_build"
	"has_exe_wrapper"
	"is_unity"
	"is_subproject"
	"current_source_dir"
	"current_build_dir"
	"source_root"
	"build_root"
	"add_install_script"
	"add_postconf_script"
	"add_dist_script"
	"install_dependency_manifest"
	"override_find_program"
	"project_version"
	"project_license"
	"version"
	"project_name"
	"get_cross_property"
	"backend"))
    (,(regexp-opt '("build_machine."
		    "host_machine."
		    "target_machine."))
     . ("system"
	"cpu_family"
	"cpu"
	"endian"))
    (""
     . ( ;; class TryRunResultHolder
	"returncode"
	"compiled"
	"stdout"
	"stderr"

	;; class RunProcess
	"returncode"
	"stdout"
	"stderr"

	;; class EnvironmentVariablesHolder
	"set"
	"append"
	"prepend"

	;; class ConfigurationDataHolder
	"set"
	"set10"
	"set_quoted"
	"has"
	"get"

	;; class DependencyHolder
	"found"
	"type_name"
	"version"
	"get_pkgconfig_variable"

	;; class InternalDependencyHolder
	"found"
	"version"

	;; class ExternalProgramHolder
	"found"

	;; class ExternalLibraryHolder
	"found"

	;; class GeneratorHolder
	"process"

	;; class BuildMachine
	"system"
	"cpu_family"
	"cpu"
	"endian"

	;; class CrossMachineInfo
	"system"
	"cpu"
	"cpu_family"
	"endian"

	;; class BuildTargetHolder
	"extract_objects"
	"extract_all_objects"
	"get_id"
	"outdir"
	"full_path"
	"private_dir_include"

	;; class CustomTargetHolder
	"full_path"

	;; class SubprojectHolder
	"get_variable"

	;; class CompilerHolder
	"compiles"
	"links"
	"get_id"
	"compute_int"
	"sizeof"
	"has_header"
	"has_header_symbol"
	"run"
	"has_function"
	"has_member"
	"has_members"
	"has_type"
	"alignment"
	"version"
	"cmd_array"
	"find_library"
	"has_argument"
	"has_multi_arguments"
	"first_supported_argument"
	"unittest_args"
	"symbols_have_underscore_prefix"

	;; string
	"strip"
	"format"
	"to_upper"
	"to_lower"
	"underscorify"
	"split"
	"startswith"
	"endswith"
	"contains"
	"to_int"
	"join"
	"version_compare"

	;; number
	"is_even"
	"is_odd"

	;; boolean
	"to_string"
	"to_int"

	;; array
	"length"
	"contains"
	"get"))))

(defconst meson--pch-kwargs '("c_pch" "cpp_pch"))

(defconst meson--lang-arg-kwargs
  '("c_args"
    "cpp_args"
    "cuda_args"
    "d_args"
    "d_import_dirs"
    "d_unittest"
    "d_module_versions"
    "d_debug"
    "fortran_args"
    "java_args"
    "objc_args"
    "objcpp_args"
    "rust_args"
    "vala_args"
    "cs_args"))

(defconst meson--vala-kwargs '("vala_header"  "vala_gir"  "vala_vapi"))
(defconst meson--rust-kwargs '("rust_crate_type"))
(defconst meson--cs-kwargs '("resources"  "cs_args"))

(defconst meson--buildtarget-kwargs
  '("build_by_default"
    "build_rpath"
    "dependencies"
    "extra_files"
    "gui_app"
    "link_with"
    "link_whole"
    "link_args"
    "link_depends"
    "implicit_include_directories"
    "include_directories"
    "install"
    "install_rpath"
    "install_dir"
    "install_mode"
    "name_prefix"
    "name_suffix"
    "native"
    "objects"
    "override_options"
    "sources"
    "gnu_symbol_visibility"))

(defconst meson--known-build-target-kwargs
  `(,@meson--buildtarget-kwargs
    ,@meson--lang-arg-kwargs
    ,@meson--pch-kwargs
    ,@meson--vala-kwargs
    ,@meson--rust-kwargs
    ,@meson--cs-kwargs))

(defconst meson--known-exe-kwargs
  `(,@meson--known-build-target-kwargs "implib"  "export_dynamic"  "link_language"  "pie"))
(defconst meson--known-shlib-kwargs
  `(,@meson--known-build-target-kwargs "version"  "soversion"  "vs_module_defs"  "darwin_versions"))
(defconst meson--known-shmod-kwargs
  `(,@meson--known-build-target-kwargs "vs_module_defs"))
(defconst meson--known-stlib-kwargs
  `(,@meson--known-build-target-kwargs "pic"))
(defconst meson--known-jar-kwargs
  `(,@meson--known-exe-kwargs "main_class"))

(defconst meson--known-library-kwargs
  (cl-union meson--known-shlib-kwargs
	    meson--known-stlib-kwargs))

(defconst meson--base-test-args
  '("args" "depends" "env" "should_fail" "timeout" "workdir" "suite" "priority" "protocol"))

(defconst meson-kwargs
  `(("add_global_arguments"
     . ("language" "native"))
    ("add_global_link_arguments"
     . ("language" "native"))
    ("add_languages"
     . ("required"))
    ("add_project_link_arguments"
     . ("language" "native"))
    ("add_project_arguments"
     . ("language" "native"))
    ("add_test_setup"
     . ("exe_wrapper" "gdb" "timeout_multiplier" "env" "is_default"))
    ("benchmark"
     . ,meson--base-test-args)
    ("build_target"
     . ,meson--known-build-target-kwargs)
    ("configure_file"
     . ("input"
	"output"
	"configuration"
	"command"
	"copy"
	"depfile"
	"install_dir"
	"install_mode"
	"capture"
	"install"
	"format"
	"output_format"
	"encoding"))
    ("custom_target"
     . ("input"
	"output"
	"command"
	"install"
	"install_dir"
	"install_mode"
	"build_always"
	"capture"
	"depends"
	"depend_files"
	"depfile"
	"build_by_default"
	"build_always_stale"
	"console"))
    ("dependency"
     . ("default_options"
	"embed"
	"fallback"
	"language"
	"main"
	"method"
	"modules"
	"cmake_module_path"
	"optional_modules"
	"native"
	"not_found_message"
	"required"
	"static"
	"version"
	"private_headers"
	"cmake_args"
	"include_type"))
    ("declare_dependency"
     . ("include_directories"
	"link_with"
	"sources"
	"dependencies"
	"compile_args"
	"link_args"
	"link_whole"
	"version"
	"variables"))
    ("executable"
     . ,meson--known-exe-kwargs)
    ("find_program"
     . ("required" "native" "version" "dirs"))
    ("generator"
     . ("arguments"
	"output"
	"depends"
	"depfile"
	"capture"
	"preserve_path_from"))
    ("include_directories"
     . ("is_system"))
    ("install_data"
     . ("install_dir" "install_mode" "rename" "sources"))
    ("install_headers"
     . ("install_dir" "install_mode" "subdir"))
    ("install_man"
     . ("install_dir" "install_mode"))
    ("install_subdir"
     . ("exclude_files" "exclude_directories" "install_dir" "install_mode" "strip_directory"))
    ("jar"
     . ,meson--known-jar-kwargs)
    ("project"
     . ("version" "meson_version" "default_options" "license" "subproject_dir"))
    ("run_command"
     . ("check" "capture" "env"))
    ("run_target"
     . ("command" "depends"))
    ("shared_library"
     . ,meson--known-shlib-kwargs)
    ("shared_module"
     . ,meson--known-shmod-kwargs)
    ("static_library"
     . ,meson--known-stlib-kwargs)
    ("both_libraries"
     . ,meson--known-library-kwargs)
    ("library"
     . ,meson--known-library-kwargs)
    ("subdir"
     . ("if_found"))
    ("subproject"
     . ("version" "default_options" "required"))
    ("test"
     . (,meson--base-test-args "is_parallel"))
    ("vcs_tag"
     . ("input" "output" "fallback" "command" "replace_string"))))

(eval-and-compile
  (defconst meson-multiline-string-regexp
    (rx "'''" (minimal-match (zero-or-more anything)) "'''"))
  (defconst meson-string-regexp
    (rx "'"
	(zero-or-more
	 (or (not (any "'" "\\"))
	     (seq "\\" nonl)))
	"'")))

(defconst meson-string-regexp
  (rx (or (eval `(regexp ,meson-multiline-string-regexp))
			 (eval `(regexp ,meson-string-regexp)))))

(defconst meson-token-spec
  `(("ignore" . ,(rx (one-or-more (any " " "\t"))))
    ("id" . ,(rx (any "_" "a-z" "A-Z") (zero-or-more (any "_" "a-z" "A-Z" "0-9"))))
    ("number" . ,(rx (one-or-more (any digit))))
    ("eol_cont" . ,(rx "\\" "\n"))
    ("eol" . "\n")))

(defvar meson-mode-font-lock-keywords
  `((,meson-keywords-regexp . font-lock-keyword-face)
    (,meson-builtin-functions-regexp . (1 font-lock-builtin-face))
    (,meson-builtin-vars-regexp . font-lock-variable-name-face)
    (,meson-var-assign-regexp . (1 font-lock-variable-name-face))))

(defconst meson-syntax-propertize-function
  (syntax-propertize-rules
   ((rx (or "'''" "'")) (0 (ignore (meson--syntax-stringify))))))

(defsubst meson-syntax-count-quotes (&optional point limit)
  "Count number of quotes after point (max is 3).
POINT is the point where scan starts (defaults to current point),
and LIMIT is used to limit the scan."
  (let ((i 0)
	(p (or point (point))))
    (while (and (< i 3)
                (or (not limit) (< (+ p i) limit))
                (eq (char-after (+ p i)) ?\'))
      (setq i (1+ i)))
    i))

(defun meson--syntax-stringify ()
  "Put `syntax-table' property correctly on single/triple apostrophes."
  ;; Inspired by python-mode
  (let* ((num-quotes (length (match-string-no-properties 0)))
         (ppss (prog2
                   (backward-char num-quotes)
                   (syntax-ppss)
                 (forward-char num-quotes)))
	 (in-comment (nth 4 ppss))
         (string-start (and (not in-comment) (nth 8 ppss)))
         (quote-starting-pos (- (point) num-quotes))
         (quote-ending-pos (point))
	 (num-closing-quotes
          (and string-start
               (meson-syntax-count-quotes
                string-start quote-starting-pos))))
    (cond ((and string-start (= num-closing-quotes 0))
           ;; This set of quotes doesn't match the string starting
           ;; kind. Do nothing.
           nil)
          ((not string-start)
           ;; This set of quotes delimit the start of a string.
           (put-text-property quote-starting-pos (1+ quote-starting-pos)
                              'syntax-table (string-to-syntax "|")))
          ((= num-quotes num-closing-quotes)
           ;; This set of quotes delimit the end of a string.
           (put-text-property (1- quote-ending-pos) quote-ending-pos
                              'syntax-table (string-to-syntax "|")))
          ((> num-quotes num-closing-quotes)
           ;; This may only happen whenever a triple quote is closing
           ;; a single quoted string. Add string delimiter syntax to
           ;; all three quotes.
           (put-text-property quote-starting-pos quote-ending-pos
                              'syntax-table (string-to-syntax "|"))))))

(defun meson-function-at-point ()
  "Return name of the function under point.
The point can be anywhere within function name or argument list."
  (save-excursion
    (skip-syntax-backward "w_")
    (let ((ppss (syntax-ppss))
	  (functions (mapcar 'car meson-builtin-functions)))
      (cond
       ((or (nth 3 ppss)		; inside string
	    (nth 4 ppss))		; inside comment
	(goto-char (nth 8 ppss))	; go to the beginning
	(meson-function-at-point))
       ((cl-some (lambda (fname) (when (looking-at fname) fname)) functions))
       ((and (> (nth 0 ppss) 0)			 ; inside parentheses
	     (eq (char-after (nth 1 ppss)) ?\()) ; rounded parentheses
	(goto-char (nth 1 ppss))
	(cl-some (lambda (fname)
		   (when (looking-back (concat fname (rx (zero-or-more (any " " "\t"))))
				       (line-beginning-position))
		     fname))
		 functions))
       ((> (nth 0 ppss) 1)		; inside nested parentheses - other than rounded
	(goto-char (nth 1 ppss))
	(meson-function-at-point))))))

;;; Completion

(defun meson-completion-at-point-function ()
  "Return possible completion candidates."
  (save-excursion
    (let* ((end (progn (skip-syntax-forward "w_")
		       (point)))
	   (start (progn (skip-syntax-backward "w_")
			 (point)))
	   (ppss (syntax-ppss)))
      (cond
       ((or (nth 3 ppss)		; inside string
	    (nth 4 ppss))		; inside comment
	nil) ; nothing to complete

       ;; kwargs
       ((and (> (nth 0 ppss) 0)		; inside parentheses
	     (eq (char-after (nth 1 ppss)) ?\()) ; rounded parentheses
	(goto-char (nth 1 ppss))
	(let ((kwargs (cl-some (lambda (x)
				 (when (looking-back (concat (car x) (rx (zero-or-more (any " " "\t"))))
						     (line-beginning-position))
				   (cdr x)))
			       meson-kwargs)))
	  ;; complete mathing kwargs as well as built-in
	  ;; variables/functions
	  (list start end (append kwargs meson-builtin-vars
				  (mapcar 'car meson-builtin-functions)))))

       ;; methods
       ((eq (char-before) ?.)
	(let ((methods (cl-some
			(lambda (x)
			  (when (looking-back (car x) (line-beginning-position))
			    (cdr x)))
			meson-methods)))
	  (list start end methods)))
       ;; global things
       (t
        (list start end (append meson-keywords meson-builtin-vars
				(mapcar 'car meson-builtin-functions))))))))


;;; Indetation

(require 'smie)

(defun meson--comment-bolp (&optional syn-ppss)
  "Return non-nil if point is at the beginning of line, ignoring comments.
Optional SYN-PPSS is the value returned by `syntax-ppss'."
  (save-excursion
    (let ((ppss (or syn-ppss
		    (syntax-ppss))))
      (when (nth 4 ppss) 		; inside comment
	(goto-char (nth 8 ppss)))	; go to its beginning
      (smie-rule-bolp))))

(defun meson-smie-forward-token ()
  "Move forward by one lexer token."
  (let ((token 'unknown))
    (while (eq token 'unknown)
      (let ((ppss (syntax-ppss)))
	;; When inside or at start of a comment, goto end of line so
	;; that we can still return "eol" token there.
	(when (or (nth 4 ppss)
		  (and (not (nth 3 ppss)) ; not inside string
		       (looking-at "#")))
	  (end-of-line)
	  (setq ppss (syntax-ppss)))	; update ppss after move
	;; Determine token but do not move behind it
	(setq token
	      (cond
	       ;; Let syntactic parser handle parentheses (even inside
	       ;; strings - this ensures that parentheses are NOT
	       ;; indented inside strings according to meson
	       ;; indentation rules)
	       ((looking-at (rx (or (syntax open-parenthesis)
				    (syntax close-parenthesis))))
		"")
	       ;; After handling parentheses (inside strings), we can
	       ;; handle strings
	       ((or (when (nth 3 ppss)		; If inside string
		      (goto-char (nth 8 ppss))	; goto beginning
		      nil)
		    (looking-at meson-string-regexp)) ; Match the whole string
		"string")
	       ((looking-at meson-keywords-regexp) (match-string-no-properties 0))
	       ((cl-some (lambda (spec) (when (looking-at (cdr spec)) (car spec)))
			 meson-token-spec))
	       ((looking-at meson-literate-tokens-regexp)
		(match-string-no-properties 0))))
	;; Remember token end (except for parentheses)
	(let ((after-token (when (< 0 (length token)) (match-end 0))))
	  ;; Skip certain tokens
	  (when (or (equal token "ignore")
		    (equal token "eol_cont")
		    (and (equal token "eol")	; Skip EOL when:
			 (or (> (nth 0 ppss) 0) ; - inside parentheses
			     (and (looking-back	; - after operator but not inside comments
				   meson-literate-tokens-regexp
				   (- (point) meson-literate-tokens-max-length))
				  (not (nth 4 ppss)))
			     (meson--comment-bolp ppss)))) ; - at empty line
	    (setq token 'unknown))
	  (when after-token
	    (goto-char after-token)))))
    token))

(defun meson-smie-backward-token ()
  "Move backward by one lexer token."
  (let ((token 'unknown))
    (while (eq token 'unknown)
      (let ((eopl (max ;; end of previous line (to properly match "eol_cont" below it is actually a character before)
		   (1- (line-end-position 0))
		   (point-min)))
	    (ppss (syntax-ppss)))
	;; Skip comments
	(when (nth 4 ppss)		 ; We are in a comment
	  (goto-char (nth 8 ppss))	 ; goto its beginning
	  (setq ppss (syntax-ppss)))	 ; update ppss after move
	(setq token
	      ;; Determine token and move before it
	      (cond
	       ;; Let syntactic parser handle parentheses (even inside
	       ;; strings - this ensures that parentheses are NOT
	       ;; indented inside strings according to meson
	       ;; indentation rules)
	       ((looking-back (rx (or (syntax open-parenthesis)
				      (syntax close-parenthesis)))
			      (1- (point)))
		"")
	       ;; Check for strings. Relying on syntactic parser allows us to
	       ;; find the beginning of multi-line strings efficiently.
	       ((nth 3 ppss)		; We're inside string or
		(let ((string-start (nth 8 ppss)))
		  (when (not (equal (point) string-start))
		    (goto-char string-start)
		    "string")))
	       ((equal (char-before) ?\') ; We're just after a string
		(let* ((ppss- (syntax-ppss (1- (point)))))
		  (goto-char (nth 8 ppss-))
		  "string"))
	       ;; Regexp-based matching
	       (t (let ((tok
			 ;; Determine token but do not move before it
			 (cond
			  ((looking-back meson-keywords-regexp (- (point) meson-keywords-max-length) t)
			   (match-string-no-properties 0))
			  ((looking-back meson-literate-tokens-regexp
					 (- (point) meson-literate-tokens-max-length) t)
			   (match-string-no-properties 0))
			  ((cl-some (lambda (spec) (when (looking-back (cdr spec) eopl t) (car spec)))
				    meson-token-spec)))))
		    (when tok
		      (goto-char (match-beginning 0)) ; Go before token now
		      (setq ppss (syntax-ppss))) ; update ppss
		    tok))))
	(when (or (equal token "ignore")
		  (equal token "eol_cont")
		  (and (equal token "eol")  ; Skip EOL when:
		       (or (> (nth 0 ppss) 0) ; - inside parentheses
			   (and (looking-back ; - after operator but not inside comments
				 meson-literate-tokens-regexp
				 (- (point) meson-literate-tokens-max-length))
				(not (nth 4 ppss)))
			   (meson--comment-bolp ppss)))) ;- at empty line
	  (setq token 'unknown))))
    token))

(defconst meson-smie-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    '((id)
      (codeblock (line)
		 (codeblock "eol" codeblock))
      (line (exp)
	    ("if" ifblock "endif")
	    ("if" ifblock "else" codeblock "endif")
	    ("foreach" foreachblock "endforeach"))
      (foreachblock (id ":" exp "eol" codeblock))
      (ifblock (exp "eol" codeblock)
	       (exp "eol" codeblock "elif" ifblock))
      (exp (exp "," exp)
	   (id ":" exp)
	   (exp "+=" exp)
	   (exp "=" exp)
;; 	   (exp "?" exp ":" exp)
	   (exp "or" exp)
	   (exp "and" exp)
	   (exp "==" exp)
	   (exp "!=" exp)
	   (exp "<"  exp)
	   (exp "<=" exp)
	   (exp ">"  exp)
	   (exp ">=" exp)
	   (exp "+" exp)
	   (exp "-" exp)
	   (exp "*" exp)
	   (exp "/" exp)
	   (exp "%" exp)
;; 	   ("not" exp)
;; 	   ("-" exp)
;; 	   (exp "." methodcall)
;; 	   (exp "." exp)
;; 	   (exp "(" args ")")
;; 	   (exp "(" args ")" indexcall)
;; 	   ("[" array "]")
;; 	   ("true")
;; 	   ("false")
	   )
;;       (args (exp)

;; 	    (id ":" exp))
;;       (array (array "," array))
;;       (methodcall (exp "(" args ")" )
;; 		  ;; (exp "(" args ")" "." methodcall)
;; 		  )
      ;;      (indexcall ( "[" exp "]"))
      )
    `((assoc "eol" "elif")) ; FIXME: Solving eol/elif conflict this
			    ; way may cause problems in indetation.
			    ; Revisit this if it is the case.
    `((assoc "eol")
      (assoc ",")
      (assoc ":")
      (assoc "+=" "=")
      (assoc "or")
      (assoc "and")
      (assoc "==" "!=" "<" "<=" ">" ">=")
      (assoc "+" "-")
      (assoc "*" "/" "%")
      (assoc ".")))))

(defgroup meson nil
  "Meson build system mode for Emacs."
  :group 'tools
  :prefix "meson-")

(defcustom meson-indent-basic 2
  "Indentation offset for meson.build files."
  :type 'integer
  :safe 'integerp)

(defcustom meson-markdown-docs-dir (seq-find 'file-exists-p
					     '("/usr/share/doc/meson/markdown"
					       "~/src/meson/docs/markdown"))
  "Directory containing Meson markdown-formated documentation."
  :type 'directory)

(defcustom meson-doc-display-buffer-action
  '((display-buffer-reuse-window display-buffer-same-window))
  "The display action used, when displaying Meson documentation."
  :type display-buffer--action-custom-type)

(defun meson-smie-rules (kind token)
  "Indentation rules for the SMIE engine.
See the SMIE documentation for the meaning of KIND and TOKEN
arguments."
  (pcase (cons kind token)
    (`(:elem . basic) meson-indent-basic)
    (`(:elem . args) (- (save-excursion (beginning-of-line-text) (point)) (point)))
    (`(,_ . ",") (smie-rule-separator kind))
    (`(,(or :before :after) . "eol") (if (smie-rule-parent-p "if" "foreach" "elif" "else")
					 (smie-rule-parent meson-indent-basic)
				       (save-excursion
					 (smie-indent-forward-token)
					 (smie-backward-sexp 'halfsexp)
					 (cons 'column (current-column)))))
    (`(:list-intro . ,(or "eol" ":" "")) t) ; "" is actually "[" because that's what lexer returns
    (`(:after . ":") meson-indent-basic)
    (`(:after . ,(or "=" "+=")) meson-indent-basic)
    (`(:before . ,(or "[" "(" "{")) (if (smie-rule-hanging-p)
					(save-excursion
					  (smie-backward-sexp 'halfsexp) ; goto parent
					  (beginning-of-line-text)
					  (cons 'column (current-column)))))
    (`(:after . ,(or "[" "(" "{")) meson-indent-basic)
    (`(:before . "elif") (smie-rule-parent))
    (_ nil)))

;;; Documentation

(defun meson--eldoc-documentation-function ()
  "`eldoc-documentation-function' (which see) for Meson mode."
  (if-let* ((fname (meson-function-at-point))
	    (fspec (alist-get fname meson-builtin-functions)))
      (plist-get fspec :doc)))

(defun meson--find-reference-manual ()
  "Return the absolute filename of the Meson reference manual or nil."
  (let ((default-directory meson-markdown-docs-dir))
    (when-let (manual (seq-find #'file-exists-p '("Reference-manual.md"
                                                  "Reference-manual.md.gz")))
      (expand-file-name manual))))

(defun meson--make-lookup-regexp (identifier)
  "Make regexp for looking up IDENTIFIER in the Meson reference manual."
  ;; In Emacs 27 this could be simplified to (rx ... (literal identifier) ...).
  (rx-to-string
   `(seq bol (or (seq (+ "#") " " (? "`") ,identifier (or "(" "`" eol))
                 (seq (* blank) "- `" ,identifier "(")))))

(defun meson--search-in-reference-manual (identifier)
  "Search for the function or object IDENTIFIER in the current buffer.
The current buffer is assumed to contain the Meson reference manual.
Return either `line-beginning-position' of the matching line or nil."
  (goto-char (point-min))
  (and (re-search-forward (meson--make-lookup-regexp identifier) nil t)
       (line-beginning-position)))

(defun meson-lookup-doc (identifier)
  "Open Meson reference manual and find IDENTIFIER.
Return the buffer containing the reference manual.
IDENTIFIER is the name of a Meson function or object as a string.
Signal a `user-error' if the manual could not be found
or does not contain IDENTIFIER."
  (interactive (list (or (thing-at-point 'symbol)
                         (meson-function-at-point)
                         (user-error "No identifier at point"))))
  (let ((buf (find-file-noselect
              (or (meson--find-reference-manual)
                  (user-error "Meson reference manual not found")))))
    (with-current-buffer buf
      ;; Set up buffer only once after creation.
      (unless (string= (buffer-name) "*Meson Reference Manual*")
        (rename-buffer "*Meson Reference Manual*" 'unique)
        (read-only-mode)
        (when (and (require 'markdown-mode nil t)
                   (fboundp 'markdown-view-mode)
                   (not (eq major-mode 'markdown-view-mode)))
          (markdown-view-mode))
        (local-set-key (kbd "q") 'bury-buffer)
        (when (bound-and-true-p evil-mode)
          (evil-local-set-key 'normal (kbd "q") 'bury-buffer)))
      (let* ((position
	      (or (meson--search-in-reference-manual identifier)
		  (user-error "%s not found in Meson reference manual" identifier)))
	     (window (display-buffer buf meson-doc-display-buffer-action)))
	(with-selected-window window
	  (goto-char position)
	  (recenter 0))))
    buf))

(defalias 'meson-lookup-doc-at-point (symbol-function 'meson-lookup-doc))

;;; Mode definition

(defvar meson-mode-map
       (let ((map (make-sparse-keymap)))
         (define-key map [f1] 'meson-lookup-doc)
         map)
       "Keymap for `meson-mode'.")

;;;###autoload
(define-derived-mode meson-mode prog-mode "Meson"
  "Major mode for editing Meson build system files.
\\{meson-mode-map}"
  :abbrev-table nil
  (setq font-lock-defaults
	'(meson-mode-font-lock-keywords
	  nil nil nil nil))

  (set (make-local-variable 'syntax-propertize-function)
       meson-syntax-propertize-function)

  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-end) "")
  (setq indent-tabs-mode nil)
  (add-hook 'completion-at-point-functions
            #'meson-completion-at-point-function nil t)
  (smie-setup meson-smie-grammar #'meson-smie-rules
	      :forward-token #'meson-smie-forward-token
	      :backward-token #'meson-smie-backward-token)
  (add-function :before-until (local 'eldoc-documentation-function)
                #'meson--eldoc-documentation-function))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("/meson\\(\\.build\\|_options\\.txt\\)\\'" . meson-mode))
  (eval-after-load 'compile
    '(progn
       (add-to-list 'compilation-error-regexp-alist 'meson)
       (add-to-list 'compilation-error-regexp-alist-alist
		    '(meson "^Meson encountered an error in file \\(.*\\), line \\([0-9]+\\), column \\([0-9]+\\):" 1 2 3)))))

(provide 'meson-mode)
;;; meson-mode.el ends here

;;(progn (mapatoms (lambda (x) (when (string-prefix-p "meson" (symbol-name x)) (makunbound x)))) (eval-buffer))
