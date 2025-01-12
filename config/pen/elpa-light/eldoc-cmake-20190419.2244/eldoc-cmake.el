;;; eldoc-cmake.el --- Eldoc support for CMake -*- lexical-binding: t -*-
;;
;; Author: Kirill Ignatiev
;; URL: https://github.com/ikirill/eldoc-cmake
;; Package-Version: 20190419.2244
;; Package-Revision: 4453c03b5c95
;; Package-Requires: ((emacs "25.1"))
;;
;;; Commentary:
;;
;; CMake eldoc support, using a pre-generated set of docstrings from
;; CMake's documentation source.
;;
;; See function `eldoc-cmake-enable'.
;;
;;; Code:

(require 'thingatpt)
(require 'subr-x)
(require 'cl-lib)

(defvar eldoc-cmake--docstrings)

;;;###autoload
(defun eldoc-cmake-enable ()
  "Enable eldoc support for a CMake file."
  (setq-local eldoc-documentation-function
              #'eldoc-cmake--function)
  (unless eldoc-mode (eldoc-mode)))

(defun eldoc-cmake--function ()
  "`eldoc-documentation-function` for CMake (`cmake-mode`)."
  (when-let
      ((cursor (thing-at-point 'symbol))
       (docstring (assoc-string cursor eldoc-cmake--docstrings t)))
    (let ((synopsis (cadr docstring))
          (example (caddr docstring)))
      (if eldoc-echo-area-use-multiline-p
          (concat synopsis "\n" example)
        (replace-regexp-in-string "\n" " " synopsis)))))

(defconst eldoc-cmake--langs
  '("ASM"
    "ASM-ATT"
    "ASM-MASM"
    "ASM-NASM"
    "C"
    "CSharp"
    "CUDA"
    "CXX"
    "Fortran"
    "Java"
    "RC"
    "Swift")
  "CMake's known languages, substituted for \"<LANG>\".")

(defun eldoc-cmake--extract-command (path)
  "Extract documentation from an .rst file in CMake.

Extremely hacky: relies on whitespace, paragraphs, etc.  It tries
to take the first English paragraph and the first code block as
the synopsis and code example for a command/variable.

To get better docstrings, the results \"may\" need to be examined
by hand and potentially adjusted.

Argument PATH is the path to a .rst file in CMake's source that
describes a single command."
  (with-temp-buffer
    (insert-file-contents path)
    (let (synopsis example name)
      ;; (message (buffer-string))
      (goto-char (point-min))
      (when (and
             (search-forward "\n\n")
             (search-forward-regexp (rx line-start (any alpha ?`)) nil t))
        (setq synopsis (thing-at-point 'sentence t))
        (when (search-forward "::" nil t)
          (forward-line)
          (let ((start (point)))
            (when (search-forward "\n\n" nil t)
              (setq example (string-trim (buffer-substring start (point)) "\n+"))))))
      ;; (message "Synopsis: %S" synopsis)
      ;; (message "Example: %S" example)
      (setq name (file-name-sans-extension (file-name-nondirectory path)))
      (cond
       ((string-match (rx string-start (group (+? (any "A-Z" ?_))) "_LANG_" (group (+? (any "A-Z" ?_))) string-end) name)
        (cl-loop
         for lang in eldoc-cmake--langs
         collect
         (let ((rep (concat (match-string 1 name) "_" lang "_" (match-string 2 name))))
           (list rep synopsis example))))
       (t
        (list (list name synopsis example)))))))

(defun eldoc-cmake--extract-commands (path)
  "Extract docstrings from CMake source.

Run this to regenerate the docstrings when they eventually go out
of date.

Example usage:

    (append
     (eldoc-cmake--extract-commands \"~/software/CMake/Help/command\")
     (eldoc-cmake--extract-commands \"~/software/CMake/Help/variable\"))

Argument PATH is the path to a directory full of .rst doc files
in CMake's source."
  (cl-loop
   for fn in (directory-files path)
   when (string-match-p (rx ".rst" string-end) fn)
   append (eldoc-cmake--extract-command (concat (file-name-as-directory path) fn))))

;; (insert (format "\n\n%S" (eldoc-cmake--extract-commands "~/software/CMake/Help/command")))
;; (insert (format "\n\n%S" (eldoc-cmake--extract-commands "~/software/CMake/Help/variable")))

(defconst eldoc-cmake--docstrings
  '(("add_compile_definitions" "Add preprocessor definitions to the compilation of source files." "  add_compile_definitions(<definition> ...)") ("add_compile_options" "Add options to the compilation of source files." "  add_compile_options(<option> ...)") ("add_custom_command" "Add a custom build rule to the generated build system." "  add_custom_command(OUTPUT output1 [output2 ...]
                     COMMAND command1 [ARGS] [args1...]
                     [COMMAND command2 [ARGS] [args2...] ...]
                     [MAIN_DEPENDENCY depend]
                     [DEPENDS [depends...]]
                     [BYPRODUCTS [files...]]
                     [IMPLICIT_DEPENDS <lang1> depend1
                                      [<lang2> depend2] ...]
                     [WORKING_DIRECTORY dir]
                     [COMMENT comment]
                     [DEPFILE depfile]
                     [VERBATIM] [APPEND] [USES_TERMINAL]
                     [COMMAND_EXPAND_LISTS])") ("add_custom_target" "Add a target with no output so it will always be built." "  add_custom_target(Name [ALL] [command1 [args1...]]
                    [COMMAND command2 [args2...] ...]
                    [DEPENDS depend depend depend ... ]
                    [BYPRODUCTS [files...]]
                    [WORKING_DIRECTORY dir]
                    [COMMENT comment]
                    [VERBATIM] [USES_TERMINAL]
                    [COMMAND_EXPAND_LISTS]
                    [SOURCES src1 [src2...]])") ("add_definitions" "Add -D define flags to the compilation of source files." "  add_definitions(-DFOO -DBAR ...)") ("add_dependencies" "Add a dependency between top-level targets." "  add_dependencies(<target> [<target-dependency>]...)") ("add_executable" "Add an executable to the project using the specified source files." "  add_executable(<name> [WIN32] [MACOSX_BUNDLE]
                 [EXCLUDE_FROM_ALL]
                 [source1] [source2 ...])") ("add_library" "Add a library to the project using the specified source files." "  add_library(<name> [STATIC | SHARED | MODULE]
              [EXCLUDE_FROM_ALL]
              [source1] [source2 ...])") ("add_link_options" "Add options to the link of shared library, module and executable targets." "  add_link_options(<option> ...)") ("add_subdirectory" "Add a subdirectory to the build." "  add_subdirectory(source_dir [binary_dir] [EXCLUDE_FROM_ALL])") ("add_test" "Add a test to the project to be run by :manual:`ctest(1)`." "  add_test(NAME <name> COMMAND <command> [<arg>...]
           [CONFIGURATIONS <config>...]
           [WORKING_DIRECTORY <dir>])") ("aux_source_directory" "Find all source files in a directory." "  aux_source_directory(<dir> <variable>)") ("break" "Break from an enclosing foreach or while loop." "  break()") ("build_command" "Get a command line to build the current project." "  build_command(<variable>
                [CONFIGURATION <config>]
                [TARGET <target>]
                [PROJECT_NAME <projname>] # legacy, causes warning
               )") ("build_name" "Disallowed since version 3.0." "  build_name(variable)") ("cmake_host_system_information" "Query host system specific information." "  cmake_host_system_information(RESULT <variable> QUERY <key> ...)") ("cmake_minimum_required" "Require a minimum version of cmake." "  cmake_minimum_required(VERSION <min>[...<max>] [FATAL_ERROR])") ("cmake_parse_arguments" "Parse function or macro arguments." "  cmake_parse_arguments(<prefix> <options> <one_value_keywords>
                        <multi_value_keywords> <args>...)") ("cmake_policy" "Manage CMake Policy settings." "  cmake_policy(VERSION <min>[...<max>])") ("configure_file" "Copy a file to another location and modify its contents." "  configure_file(<input> <output>
                 [COPYONLY] [ESCAPE_QUOTES] [@ONLY]
                 [NEWLINE_STYLE [UNIX|DOS|WIN32|LF|CRLF] ])") ("continue" "Continue to the top of enclosing foreach or while loop." "  continue()") ("create_test_sourcelist" "Create a test driver and source list for building test programs." "  create_test_sourcelist(sourceListName driverName
                         test1 test2 test3
                         EXTRA_INCLUDE include.h
                         FUNCTION function)") ("ctest_build" "Perform the :ref:`CTest Build Step` as a :ref:`Dashboard Client`." "  ctest_build([BUILD <build-dir>] [APPEND]
              [CONFIGURATION <config>]
              [FLAGS <flags>]
              [PROJECT_NAME <project-name>]
              [TARGET <target-name>]
              [NUMBER_ERRORS <num-err-var>]
              [NUMBER_WARNINGS <num-warn-var>]
              [RETURN_VALUE <result-var>]
              [CAPTURE_CMAKE_ERROR <result-var>]
              )") ("ctest_configure" "Perform the :ref:`CTest Configure Step` as a :ref:`Dashboard Client`." "  ctest_configure([BUILD <build-dir>] [SOURCE <source-dir>] [APPEND]
                  [OPTIONS <options>] [RETURN_VALUE <result-var>] [QUIET]
                  [CAPTURE_CMAKE_ERROR <result-var>])") ("ctest_coverage" "Perform the :ref:`CTest Coverage Step` as a :ref:`Dashboard Client`." "  ctest_coverage([BUILD <build-dir>] [APPEND]
                 [LABELS <label>...]
                 [RETURN_VALUE <result-var>]
                 [CAPTURE_CMAKE_ERROR <result-var]
                 [QUIET]
                 )") ("ctest_empty_binary_directory" "empties the binary directory" "  ctest_empty_binary_directory( directory )") ("ctest_memcheck" "Perform the :ref:`CTest MemCheck Step` as a :ref:`Dashboard Client`." "  ctest_memcheck([BUILD <build-dir>] [APPEND]
                 [START <start-number>]
                 [END <end-number>]
                 [STRIDE <stride-number>]
                 [EXCLUDE <exclude-regex>]
                 [INCLUDE <include-regex>]
                 [EXCLUDE_LABEL <label-exclude-regex>]
                 [INCLUDE_LABEL <label-include-regex>]
                 [EXCLUDE_FIXTURE <regex>]
                 [EXCLUDE_FIXTURE_SETUP <regex>]
                 [EXCLUDE_FIXTURE_CLEANUP <regex>]
                 [PARALLEL_LEVEL <level>]
                 [TEST_LOAD <threshold>]
                 [SCHEDULE_RANDOM <ON|OFF>]
                 [STOP_TIME <time-of-day>]
                 [RETURN_VALUE <result-var>]
                 [DEFECT_COUNT <defect-count-var>]
                 [QUIET]
                 )") ("ctest_read_custom_files" "read CTestCustom files." "  ctest_read_custom_files( directory ... )") ("ctest_run_script" "runs a ctest -S script" "  ctest_run_script([NEW_PROCESS] script_file_name script_file_name1
              script_file_name2 ... [RETURN_VALUE var])") ("ctest_sleep" "sleeps for some amount of time" "  ctest_sleep(<seconds>)") ("ctest_start" "Starts the testing for a given model" "  ctest_start(<model> [<source> [<binary>]] [TRACK <track>] [QUIET])") ("ctest_submit" "Perform the :ref:`CTest Submit Step` as a :ref:`Dashboard Client`." "  ctest_submit([PARTS <part>...] [FILES <file>...]
               [SUBMIT_URL <url>]
               [HTTPHEADER <header>]
               [RETRY_COUNT <count>]
               [RETRY_DELAY <delay>]
               [RETURN_VALUE <result-var>]
               [CAPTURE_CMAKE_ERROR <result-var>]
               [QUIET]
               )") ("ctest_test" "Perform the :ref:`CTest Test Step` as a :ref:`Dashboard Client`." "  ctest_test([BUILD <build-dir>] [APPEND]
             [START <start-number>]
             [END <end-number>]
             [STRIDE <stride-number>]
             [EXCLUDE <exclude-regex>]
             [INCLUDE <include-regex>]
             [EXCLUDE_LABEL <label-exclude-regex>]
             [INCLUDE_LABEL <label-include-regex>]
             [EXCLUDE_FIXTURE <regex>]
             [EXCLUDE_FIXTURE_SETUP <regex>]
             [EXCLUDE_FIXTURE_CLEANUP <regex>]
             [PARALLEL_LEVEL <level>]
             [TEST_LOAD <threshold>]
             [SCHEDULE_RANDOM <ON|OFF>]
             [STOP_TIME <time-of-day>]
             [RETURN_VALUE <result-var>]
             [CAPTURE_CMAKE_ERROR <result-var>]
             [QUIET]
             )") ("ctest_update" "Perform the :ref:`CTest Update Step` as a :ref:`Dashboard Client`." "  ctest_update([SOURCE <source-dir>]
               [RETURN_VALUE <result-var>]
               [CAPTURE_CMAKE_ERROR <result-var>]
               [QUIET])") ("ctest_upload" "Upload files to a dashboard server as a :ref:`Dashboard Client`." "  ctest_upload(FILES <file>... [QUIET] [CAPTURE_CMAKE_ERROR <result-var>])") ("define_property" "Define and document custom properties." "  define_property(<GLOBAL | DIRECTORY | TARGET | SOURCE |
                   TEST | VARIABLE | CACHED_VARIABLE>
                   PROPERTY <name> [INHERITED]
                   BRIEF_DOCS <brief-doc> [docs...]
                   FULL_DOCS <full-doc> [docs...])") ("else" "Starts the else portion of an if block." "  else([<condition>])") ("elseif" "Starts an elseif portion of an if block." "  elseif(<condition>)") ("enable_language" "Enable a language (CXX/C/Fortran/etc)" "  enable_language(<lang> [OPTIONAL] )") ("enable_testing" "Enable testing for current directory and below." "  enable_testing()") ("endforeach" "Ends a list of commands in a foreach block." "  endforeach([<loop_var>])") ("endfunction" "Ends a list of commands in a function block." "  endfunction([<name>])") ("endif" "Ends a list of commands in an if block." "  endif([<condition>])") ("endmacro" "Ends a list of commands in a macro block." "  endmacro([<name>])") ("endwhile" "Ends a list of commands in a while block." "  endwhile([<condition>])") ("exec_program" "Run an executable program during the processing of the CMakeList.txt
file." "  exec_program(Executable [directory in which to run]
               [ARGS <arguments to executable>]
               [OUTPUT_VARIABLE <var>]
               [RETURN_VALUE <var>])") ("execute_process" "Execute one or more child processes." "  execute_process(COMMAND <cmd1> [<arguments>]
                  [COMMAND <cmd2> [<arguments>]]...
                  [WORKING_DIRECTORY <directory>]
                  [TIMEOUT <seconds>]
                  [RESULT_VARIABLE <variable>]
                  [RESULTS_VARIABLE <variable>]
                  [OUTPUT_VARIABLE <variable>]
                  [ERROR_VARIABLE <variable>]
                  [INPUT_FILE <file>]
                  [OUTPUT_FILE <file>]
                  [ERROR_FILE <file>]
                  [OUTPUT_QUIET]
                  [ERROR_QUIET]
                  [OUTPUT_STRIP_TRAILING_WHITESPACE]
                  [ERROR_STRIP_TRAILING_WHITESPACE]
                  [ENCODING <name>])") ("export" "Export targets from the build tree for use by outside projects." "  export(EXPORT <export-name> [NAMESPACE <namespace>] [FILE <filename>])") ("export_library_dependencies" "Disallowed since version 3.0." "  export_library_dependencies(<file> [APPEND])") ("file" "File manipulation command." "  `Reading`_
    file(`READ`_ <filename> <out-var> [...])
    file(`STRINGS`_ <filename> <out-var> [...])
    file(`\\<HASH\\> <HASH_>`_ <filename> <out-var>)
    file(`TIMESTAMP`_ <filename> <out-var> [...])") ("find_file" nil nil)
    ("find_library"
"This command is used to find a library. A cache entry named by <VAR> is created to store the result of this command."
"find_library (<VAR> name | NAMES name1 [name2 ...] [NAMES_PER_DIR]
          [HINTS path1 [path2 ... ENV var]]
          [PATHS path1 [path2 ... ENV var]] [PATH_SUFFIXES suffix1 [suffix2 ...]]
          [DOC \"cache documentation string\"]
          [NO_DEFAULT_PATH] [NO_PACKAGE_ROOT_PATH] [NO_CMAKE_PATH]
          [NO_CMAKE_ENVIRONMENT_PATH] [NO_SYSTEM_ENVIRONMENT_PATH] [NO_CMAKE_SYSTEM_PATH]
          [CMAKE_FIND_ROOT_PATH_BOTH | ONLY_CMAKE_FIND_ROOT_PATH | NO_CMAKE_FIND_ROOT_PATH])") ("find_package" "Find an external project, and load its settings." "  find_package(<PackageName> [version] [EXACT] [QUIET] [MODULE]
               [REQUIRED] [[COMPONENTS] [components...]]
               [OPTIONAL_COMPONENTS components...]
               [NO_POLICY_SCOPE])")
          ("find_path" "When searching for frameworks, if the file is specified as ``A/b.h``, then
the framework search will look for ``A.framework/Headers/b.h``."
"find_path (<VAR> name | NAMES name1 [name2 ...]
          [HINTS path1 [path2 ... ENV var]] [PATHS path1 [path2 ... ENV var]]
          [PATH_SUFFIXES suffix1 [suffix2 ...]]
          [DOC \"cache documentation string\"]
          [NO_DEFAULT_PATH] [NO_PACKAGE_ROOT_PATH] [NO_CMAKE_PATH] [NO_CMAKE_ENVIRONMENT_PATH] [NO_SYSTEM_ENVIRONMENT_PATH] [NO_CMAKE_SYSTEM_PATH]
          [CMAKE_FIND_ROOT_PATH_BOTH | ONLY_CMAKE_FIND_ROOT_PATH | NO_CMAKE_FIND_ROOT_PATH])") ("find_program" "When more than one value is given to the ``NAMES`` option this command by
default will consider one name at a time and search every directory
for it." nil) ("fltk_wrap_ui" "Create FLTK user interfaces Wrappers." "  fltk_wrap_ui(resultingLibraryName source1
               source2 ... sourceN )") ("foreach" "Evaluate a group of commands for each value in a list." "  foreach(<loop_var> <items>)
    <commands>
  endforeach()") ("function" "Start recording a function for later invocation as a command." "  function(<name> [<arg1> ...])
    <commands>
  endfunction()") ("get_cmake_property" "Get a global property of the CMake instance." "  get_cmake_property(<var> <property>)") ("get_directory_property" "Get a property of ``DIRECTORY`` scope." "  get_directory_property(<variable> [DIRECTORY <dir>] <prop-name>)") ("get_filename_component" "Get a specific component of a full filename." "  get_filename_component(<var> <FileName> <mode> [CACHE])") ("get_property" "Get a property." "  get_property(<variable>
               <GLOBAL             |
                DIRECTORY [<dir>]  |
                TARGET    <target> |
                SOURCE    <source> |
                INSTALL   <file>   |
                TEST      <test>   |
                CACHE     <entry>  |
                VARIABLE           >
               PROPERTY <name>
               [SET | DEFINED | BRIEF_DOCS | FULL_DOCS])") ("get_source_file_property" "Get a property for a source file." "  get_source_file_property(VAR file property)") ("get_target_property" "Get a property from a target." "  get_target_property(VAR target property)") ("get_test_property" "Get a property of the test." "  get_test_property(test property VAR)") ("if" "Conditionally execute a group of commands." "  if(<condition>)
    <commands>
  elseif(<condition>) # optional block, can be repeated
    <commands>
  else()              # optional block
    <commands>
  endif()") ("include" "Load and run CMake code from a file or module." "  include(<file|module> [OPTIONAL] [RESULT_VARIABLE <var>]
                        [NO_POLICY_SCOPE])") ("include_directories" "Add include directories to the build." "  include_directories([AFTER|BEFORE] [SYSTEM] dir1 [dir2 ...])") ("include_external_msproject" "Include an external Microsoft project file in a workspace." "  include_external_msproject(projectname location
                             [TYPE projectTypeGUID]
                             [GUID projectGUID]
                             [PLATFORM platformName]
                             dep1 dep2 ...)") ("include_guard" "Provides an include guard for the file currently being processed by CMake." "  include_guard([DIRECTORY|GLOBAL])") ("include_regular_expression" "Set the regular expression used for dependency checking." "  include_regular_expression(regex_match [regex_complain])") ("install" "Specify rules to run at install time." "  install(`TARGETS`_ <target>... [...])
  install({`FILES`_ | `PROGRAMS`_} <file>... [DESTINATION <dir>] [...])
  install(`DIRECTORY`_ <dir>... [DESTINATION <dir>] [...])
  install(`SCRIPT`_ <file> [...])
  install(`CODE`_ <code> [...])
  install(`EXPORT`_ <export-name> DESTINATION <dir> [...])") ("install_files" "This command has been superceded by the :command:`install` command." "  install_files(<dir> extension file file ...)") ("install_programs" "This command has been superceded by the :command:`install` command." "  install_programs(<dir> file1 file2 [file3 ...])
  install_programs(<dir> FILES file1 [file2 ...])") ("install_targets" "This command has been superceded by the :command:`install` command." "  install_targets(<dir> [RUNTIME_DIRECTORY dir] target target)") ("link_directories" "Add directories in which the linker will look for libraries." "  link_directories([AFTER|BEFORE] directory1 [directory2 ...])") ("link_libraries" "Link libraries to all targets added later." "  link_libraries([item1 [item2 [...]]]
                 [[debug|optimized|general] <item>] ...)") ("list" "List operations." "  `Reading`_
    list(`LENGTH`_ <list> <out-var>)
    list(`GET`_ <list> <element index> [<index> ...] <out-var>)
    list(`JOIN`_ <list> <glue> <out-var>)
    list(`SUBLIST`_ <list> <begin> <length> <out-var>)") ("load_cache" "Load in the values from another project's CMake cache." "  load_cache(pathToCacheFile READ_WITH_PREFIX prefix entry1...)") ("load_command" "Disallowed since version 3.0." "  load_command(COMMAND_NAME <loc1> [loc2 ...])") ("macro" "Start recording a macro for later invocation as a command" "  macro(<name> [<arg1> ...])
    <commands>
  endmacro()") ("make_directory" "Creates the specified directory." nil) ("mark_as_advanced" "Mark cmake cached variables as advanced." "  mark_as_advanced([CLEAR|FORCE] <var1> ...)") ("math" "Evaluate a mathematical expression." "  math(EXPR <variable> \"<expression>\" [OUTPUT_FORMAT <format>])") ("message" "Display a message to the user." "  message([<mode>] \"message to display\" ...)") ("option" "Provide an option that the user can optionally select." "  option(<variable> \"<help_text>\" [value])") ("output_required_files" "Disallowed since version 3.0." "  output_required_files(srcfile outputfile)") ("project" "Set the name of the project." " project(<PROJECT-NAME> [<language-name>...])
 project(<PROJECT-NAME>
         [VERSION <major>[.<minor>[.<patch>[.<tweak>]]]]
         [DESCRIPTION <project-description-string>]
         [HOMEPAGE_URL <url-string>]
         [LANGUAGES <language-name>...])") ("qt_wrap_cpp" "Manually create Qt Wrappers." "  qt_wrap_cpp(resultingLibraryName DestName SourceLists ...)") ("qt_wrap_ui" "Manually create Qt user interfaces Wrappers." "  qt_wrap_ui(resultingLibraryName HeadersDestName
             SourcesDestName SourceLists ...)") ("remove" "Removes ``VALUE`` from the variable ``VAR``." nil) ("remove_definitions" "Remove -D define flags added by :command:`add_definitions`." "  remove_definitions(-DFOO -DBAR ...)") ("return" "Return from a file, directory or function." "  return()") ("separate_arguments" "Parse command-line arguments into a semicolon-separated list." "  separate_arguments(<variable> <mode> <args>)") ("set" "Set a normal, cache, or environment variable to a given value." "  set(<variable> <value>... [PARENT_SCOPE])") ("set_directory_properties" "Set properties of the current directory and subdirectories." "  set_directory_properties(PROPERTIES prop1 value1 [prop2 value2] ...)") ("set_property" "Set a named property in a given scope." "  set_property(<GLOBAL                      |
                DIRECTORY [<dir>]           |
                TARGET    [<target1> ...]   |
                SOURCE    [<src1> ...]      |
                INSTALL   [<file1> ...]     |
                TEST      [<test1> ...]     |
                CACHE     [<entry1> ...]    >
               [APPEND] [APPEND_STRING]
               PROPERTY <name> [value1 ...])") ("set_source_files_properties" "Source files can have properties that affect how they are built." "  set_source_files_properties([file1 [file2 [...]]]
                              PROPERTIES prop1 value1
                              [prop2 value2 [...]])") ("set_target_properties" "Targets can have properties that affect how they are built." "  set_target_properties(target1 target2 ...
                        PROPERTIES prop1 value1
                        prop2 value2 ...)") ("set_tests_properties" "Set a property of the tests." "  set_tests_properties(test1 [test2...] PROPERTIES prop1 value1 prop2 value2)") ("site_name" "Set the given variable to the name of the computer." nil) ("source_group" "Define a grouping for source files in IDE project generation." "  source_group(<name> [FILES <src>...] [REGULAR_EXPRESSION <regex>])
  source_group(TREE <root> [PREFIX <prefix>] [FILES <src>...])") ("string" "String operations." "  `Search and Replace`_
    string(`FIND`_ <string> <substring> <out-var> [...])
    string(`REPLACE`_ <match-string> <replace-string> <out-var> <input>...)") ("subdir_depends" "Disallowed since version 3.0." "  subdir_depends(subdir dep1 dep2 ...)") ("subdirs" "Add a list of subdirectories to the build." "  subdirs(dir1 dir2 ...[EXCLUDE_FROM_ALL exclude_dir1 exclude_dir2 ...]
          [PREORDER] )") ("target_compile_definitions" "Add compile definitions to a target." "  target_compile_definitions(<target>
    <INTERFACE|PUBLIC|PRIVATE> [items1...]
    [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])") ("target_compile_features" "Add expected compiler features to a target." "  target_compile_features(<target> <PRIVATE|PUBLIC|INTERFACE> <feature> [...])") ("target_compile_options" "Add compile options to a target." "  target_compile_options(<target> [BEFORE]
    <INTERFACE|PUBLIC|PRIVATE> [items1...]
    [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])") ("target_include_directories" "Add include directories to a target." "  target_include_directories(<target> [SYSTEM] [BEFORE]
    <INTERFACE|PUBLIC|PRIVATE> [items1...]
    [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])") ("target_link_directories" "Add link directories to a target." "  target_link_directories(<target> [BEFORE]
    <INTERFACE|PUBLIC|PRIVATE> [items1...]
    [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])") ("target_link_libraries" "Specify libraries or flags to use when linking a given target and/or
its dependents." "  target_link_libraries(<target> ... <item>... ...)") ("target_link_options" "Add link options to a target." "  target_link_options(<target> [BEFORE]
    <INTERFACE|PUBLIC|PRIVATE> [items1...]
    [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])") ("target_sources" "Add sources to a target." "  target_sources(<target>
    <INTERFACE|PUBLIC|PRIVATE> [items1...]
    [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])") ("try_compile" "Try building some code." "  try_compile(RESULT_VAR <bindir> <srcdir>
              <projectName> [<targetName>] [CMAKE_FLAGS <flags>...]
              [OUTPUT_VARIABLE <var>])") ("try_run" "Try compiling and then running some code." "  try_run(RUN_RESULT_VAR COMPILE_RESULT_VAR
          bindir srcfile [CMAKE_FLAGS <flags>...]
          [COMPILE_DEFINITIONS <defs>...]
          [LINK_OPTIONS <options>...]
          [LINK_LIBRARIES <libs>...]
          [COMPILE_OUTPUT_VARIABLE <var>]
          [RUN_OUTPUT_VARIABLE <var>]
          [OUTPUT_VARIABLE <var>]
          [ARGS <args>...])") ("unset" "Unset a variable, cache variable, or environment variable." "  unset(<variable> [CACHE | PARENT_SCOPE])") ("use_mangled_mesa" "Disallowed since version 3.0." "  use_mangled_mesa(PATH_TO_MESA OUTPUT_DIRECTORY)") ("utility_source" "Disallowed since version 3.0." "  utility_source(cache_entry executable_name
                 path_to_source [file1 file2 ...])") ("variable_requires" "Disallowed since version 3.0." "  variable_requires(TEST_VARIABLE RESULT_VARIABLE
                    REQUIRED_VARIABLE1
                    REQUIRED_VARIABLE2 ...)") ("variable_watch" "Watch the CMake variable for change." "  variable_watch(<variable> [<command>])") ("while" "Evaluate a group of commands while a condition is true" "  while(<condition>)
    <commands>
  endwhile()") ("write_file" "The first argument is the file name, the rest of the arguments are
messages to write." nil)

  ("ANDROID" "Set to ``1`` when the target system (:variable:`CMAKE_SYSTEM_NAME`) is
``Android``." nil) ("APPLE" "Set to ``True`` when the target system is an Apple platform
(macOS, iOS, tvOS or watchOS)." nil) ("BORLAND" "``True`` if the Borland compiler is being used." nil) ("BUILD_SHARED_LIBS" "Global flag to cause :command:`add_library` to create shared libraries if on." nil) ("CACHE" "Operator to read cache variables." nil) ("CMAKE_ABSOLUTE_DESTINATION_FILES" "List of files which have been installed using an ``ABSOLUTE DESTINATION`` path." nil) ("CMAKE_ANDROID_ANT_ADDITIONAL_OPTIONS" "Default value for the :prop_tgt:`ANDROID_ANT_ADDITIONAL_OPTIONS` target property." nil) ("CMAKE_ANDROID_API" "When :ref:`Cross Compiling for Android with NVIDIA Nsight Tegra Visual Studio
Edition`, this variable may be set to specify the default value for the
:prop_tgt:`ANDROID_API` target property." nil) ("CMAKE_ANDROID_API_MIN" "Default value for the :prop_tgt:`ANDROID_API_MIN` target property." nil) ("CMAKE_ANDROID_ARCH" "When :ref:`Cross Compiling for Android with NVIDIA Nsight Tegra Visual Studio
Edition`, this variable may be set to specify the default value for the
:prop_tgt:`ANDROID_ARCH` target property." nil) ("CMAKE_ANDROID_ARCH_ABI" "When :ref:`Cross Compiling for Android`, this variable specifies the
target architecture and ABI to be used." nil) ("CMAKE_ANDROID_ARM_MODE" "When :ref:`Cross Compiling for Android` and :variable:`CMAKE_ANDROID_ARCH_ABI`
is set to one of the ``armeabi`` architectures, set ``CMAKE_ANDROID_ARM_MODE``
to ``ON`` to target 32-bit ARM processors (``-marm``)." nil) ("CMAKE_ANDROID_ARM_NEON" "When :ref:`Cross Compiling for Android` and :variable:`CMAKE_ANDROID_ARCH_ABI`
is set to ``armeabi-v7a`` set ``CMAKE_ANDROID_ARM_NEON`` to ``ON`` to target
ARM NEON devices." nil) ("CMAKE_ANDROID_ASSETS_DIRECTORIES" "Default value for the :prop_tgt:`ANDROID_ASSETS_DIRECTORIES` target property." nil) ("CMAKE_ANDROID_GUI" "Default value for the :prop_tgt:`ANDROID_GUI` target property of
executables." nil) ("CMAKE_ANDROID_JAR_DEPENDENCIES" "Default value for the :prop_tgt:`ANDROID_JAR_DEPENDENCIES` target property." nil) ("CMAKE_ANDROID_JAR_DIRECTORIES" "Default value for the :prop_tgt:`ANDROID_JAR_DIRECTORIES` target property." nil) ("CMAKE_ANDROID_JAVA_SOURCE_DIR" "Default value for the :prop_tgt:`ANDROID_JAVA_SOURCE_DIR` target property." nil) ("CMAKE_ANDROID_NATIVE_LIB_DEPENDENCIES" "Default value for the :prop_tgt:`ANDROID_NATIVE_LIB_DEPENDENCIES` target
property." nil) ("CMAKE_ANDROID_NATIVE_LIB_DIRECTORIES" "Default value for the :prop_tgt:`ANDROID_NATIVE_LIB_DIRECTORIES` target
property." nil) ("CMAKE_ANDROID_NDK" "When :ref:`Cross Compiling for Android with the NDK`, this variable holds
the absolute path to the root directory of the NDK." nil) ("CMAKE_ANDROID_NDK_DEPRECATED_HEADERS" "When :ref:`Cross Compiling for Android with the NDK`, this variable
may be set to specify whether to use the deprecated per-api-level
headers instead of the unified headers." nil) ("CMAKE_ANDROID_NDK_TOOLCHAIN_HOST_TAG" "When :ref:`Cross Compiling for Android with the NDK`, this variable
provides the NDK's \"host tag\" used to construct the path to prebuilt
toolchains that run on the host." nil) ("CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION" "When :ref:`Cross Compiling for Android with the NDK`, this variable
may be set to specify the version of the toolchain to be used
as the compiler." nil) ("CMAKE_ANDROID_PROCESS_MAX" "Default value for the :prop_tgt:`ANDROID_PROCESS_MAX` target property." nil) ("CMAKE_ANDROID_PROGUARD" "Default value for the :prop_tgt:`ANDROID_PROGUARD` target property." nil) ("CMAKE_ANDROID_PROGUARD_CONFIG_PATH" "Default value for the :prop_tgt:`ANDROID_PROGUARD_CONFIG_PATH` target property." nil) ("CMAKE_ANDROID_SECURE_PROPS_PATH" "Default value for the :prop_tgt:`ANDROID_SECURE_PROPS_PATH` target property." nil) ("CMAKE_ANDROID_SKIP_ANT_STEP" "Default value for the :prop_tgt:`ANDROID_SKIP_ANT_STEP` target property." nil) ("CMAKE_ANDROID_STANDALONE_TOOLCHAIN" "When :ref:`Cross Compiling for Android with a Standalone Toolchain`, this
variable holds the absolute path to the root directory of the toolchain." nil) ("CMAKE_ANDROID_STL_TYPE" "When :ref:`Cross Compiling for Android with NVIDIA Nsight Tegra Visual Studio
Edition`, this variable may be set to specify the default value for the
:prop_tgt:`ANDROID_STL_TYPE` target property." nil) ("CMAKE_APPBUNDLE_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for macOS application bundles used by the :command:`find_program`, and
:command:`find_package` commands." nil) ("CMAKE_AR" "Name of archiving tool for static libraries." nil) ("CMAKE_ARCHIVE_OUTPUT_DIRECTORY" "Where to put all the :ref:`ARCHIVE <Archive Output Artifacts>`
target files when built." nil) ("CMAKE_ARCHIVE_OUTPUT_DIRECTORY_CONFIG" "Where to put all the :ref:`ARCHIVE <Archive Output Artifacts>`
target files when built for a specific configuration." nil) ("CMAKE_ARGC" "Number of command line arguments passed to CMake in script mode." nil) ("CMAKE_ARGV0" "Command line argument passed to CMake in script mode." nil) ("CMAKE_AUTOGEN_ORIGIN_DEPENDS" "Switch for forwarding origin target dependencies to the corresponding
``_autogen`` targets." nil) ("CMAKE_AUTOGEN_PARALLEL" "Number of parallel ``moc`` or ``uic`` processes to start when using
:prop_tgt:`AUTOMOC` and :prop_tgt:`AUTOUIC`." nil) ("CMAKE_AUTOGEN_VERBOSE" "Sets the verbosity of :prop_tgt:`AUTOMOC`, :prop_tgt:`AUTOUIC` and
:prop_tgt:`AUTORCC`." nil) ("CMAKE_AUTOMOC" "Whether to handle ``moc`` automatically for Qt targets." nil) ("CMAKE_AUTOMOC_COMPILER_PREDEFINES" "This variable is used to initialize the :prop_tgt:`AUTOMOC_COMPILER_PREDEFINES`
property on all the targets. See that target property for additional
information." nil) ("CMAKE_AUTOMOC_DEPEND_FILTERS" "Filter definitions used by :variable:`CMAKE_AUTOMOC`
to extract file names from source code as additional dependencies
for the ``moc`` file." nil) ("CMAKE_AUTOMOC_MACRO_NAMES" ":ref:`Semicolon-separated list <CMake Language Lists>` list of macro names used by
:variable:`CMAKE_AUTOMOC` to determine if a C++ file needs to be
processed by ``moc``." nil) ("CMAKE_AUTOMOC_MOC_OPTIONS" "Additional options for ``moc`` when using :variable:`CMAKE_AUTOMOC`." nil) ("CMAKE_AUTOMOC_RELAXED_MODE" "Switch between strict and relaxed automoc mode." nil) ("CMAKE_AUTORCC" "Whether to handle ``rcc`` automatically for Qt targets." nil) ("CMAKE_AUTORCC_OPTIONS" "Additional options for ``rcc`` when using :variable:`CMAKE_AUTORCC`." nil) ("CMAKE_AUTOUIC" "Whether to handle ``uic`` automatically for Qt targets." nil) ("CMAKE_AUTOUIC_OPTIONS" "Additional options for ``uic`` when using :variable:`CMAKE_AUTOUIC`." nil) ("CMAKE_AUTOUIC_SEARCH_PATHS" "Search path list used by :variable:`CMAKE_AUTOUIC` to find included
``.ui`` files." nil) ("CMAKE_BACKWARDS_COMPATIBILITY" "Deprecated." nil) ("CMAKE_BINARY_DIR" "The path to the top level of the build tree." nil) ("CMAKE_BUILD_RPATH" ":ref:`Semicolon-separated list <CMake Language Lists>` specifying runtime path (``RPATH``)
entries to add to binaries linked in the build tree (for platforms that
support it)." nil) ("CMAKE_BUILD_RPATH_USE_ORIGIN" "Whether to use relative paths for the build ``RPATH``." nil) ("CMAKE_BUILD_TOOL" "This variable exists only for backwards compatibility." nil) ("CMAKE_BUILD_TYPE" "Specifies the build type on single-configuration generators." nil) ("CMAKE_BUILD_WITH_INSTALL_NAME_DIR" "Whether to use :prop_tgt:`INSTALL_NAME_DIR` on targets in the build tree." nil) ("CMAKE_BUILD_WITH_INSTALL_RPATH" "Use the install path for the ``RPATH``." nil) ("CMAKE_CACHEFILE_DIR" "The directory with the ``CMakeCache.txt`` file." nil) ("CMAKE_CACHE_MAJOR_VERSION" "Major version of CMake used to create the ``CMakeCache.txt`` file" nil) ("CMAKE_CACHE_MINOR_VERSION" "Minor version of CMake used to create the ``CMakeCache.txt`` file" nil) ("CMAKE_CACHE_PATCH_VERSION" "Patch version of CMake used to create the ``CMakeCache.txt`` file" nil) ("CMAKE_CFG_INTDIR" "Build-time reference to per-configuration output subdirectory." "  $(ConfigurationName) = Visual Studio 9
  $(Configuration)     = Visual Studio 10
  $(CONFIGURATION)     = Xcode
  .                    = Make-based tools") ("CMAKE_CL_64" "Discouraged." nil) ("CMAKE_CODEBLOCKS_COMPILER_ID" "Change the compiler id in the generated CodeBlocks project files." nil) ("CMAKE_CODEBLOCKS_EXCLUDE_EXTERNAL_FILES" "Change the way the CodeBlocks generator creates project files." nil) ("CMAKE_CODELITE_USE_TARGETS" "Change the way the CodeLite generator creates projectfiles." nil) ("CMAKE_COLOR_MAKEFILE" "Enables color output when using the :ref:`Makefile Generators`." nil) ("CMAKE_COMMAND" "The full path to the :manual:`cmake(1)` executable." nil) ("CMAKE_COMPILER_2005" "Using the Visual Studio 2005 compiler from Microsoft" nil) ("CMAKE_COMPILER_IS_GNUCC" "True if the ``C`` compiler is GNU." nil) ("CMAKE_COMPILER_IS_GNUCXX" "True if the C++ (``CXX``) compiler is GNU." nil) ("CMAKE_COMPILER_IS_GNUG77" "True if the ``Fortran`` compiler is GNU." nil) ("CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY" "Output directory for MS debug symbol ``.pdb`` files
generated by the compiler while building source files." nil) ("CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY_CONFIG" "Per-configuration output directory for MS debug symbol ``.pdb`` files
generated by the compiler while building source files." nil) ("CMAKE_CONFIGURATION_TYPES" "Specifies the available build types on multi-config generators." nil) ("CMAKE_CONFIG_POSTFIX" "Default filename postfix for libraries under configuration ``<CONFIG>``." nil) ("CMAKE_CPACK_COMMAND" "Full path to :manual:`cpack(1)` command installed with CMake." nil) ("CMAKE_CROSSCOMPILING" "Intended to indicate whether CMake is cross compiling, but note limitations
discussed below." nil) ("CMAKE_CROSSCOMPILING_EMULATOR" "This variable is only used when :variable:`CMAKE_CROSSCOMPILING` is on. It
should point to a command on the host system that can run executable built
for the target system." nil) ("CMAKE_CTEST_COMMAND" "Full path to :manual:`ctest(1)` command installed with CMake." nil) ("CMAKE_CUDA_EXTENSIONS" "Default value for :prop_tgt:`CUDA_EXTENSIONS` property of targets." nil) ("CMAKE_CUDA_HOST_COMPILER" "Executable to use when compiling host code when compiling ``CUDA`` language
files. Maps to the nvcc -ccbin option." nil) ("CMAKE_CUDA_SEPARABLE_COMPILATION" "Default value for :prop_tgt:`CUDA_SEPARABLE_COMPILATION` target property." nil) ("CMAKE_CUDA_STANDARD" "Default value for :prop_tgt:`CUDA_STANDARD` property of targets." nil) ("CMAKE_CUDA_STANDARD_REQUIRED" "Default value for :prop_tgt:`CUDA_STANDARD_REQUIRED` property of targets." nil) ("CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES" "When the ``CUDA`` language has been enabled, this provides a
:ref:`semicolon-separated list <CMake Language Lists>` of include directories provided
by the CUDA Toolkit." nil) ("CMAKE_CURRENT_BINARY_DIR" "The path to the binary directory currently being processed." nil) ("CMAKE_CURRENT_LIST_DIR" "Full directory of the listfile currently being processed." nil) ("CMAKE_CURRENT_LIST_FILE" "Full path to the listfile currently being processed." nil) ("CMAKE_CURRENT_LIST_LINE" "The line number of the current file being processed." nil) ("CMAKE_CURRENT_SOURCE_DIR" "The path to the source directory currently being processed." nil) ("CMAKE_CXX_COMPILE_FEATURES" "List of features known to the C++ compiler" nil) ("CMAKE_CXX_EXTENSIONS" "Default value for :prop_tgt:`CXX_EXTENSIONS` property of targets." nil) ("CMAKE_CXX_STANDARD" "Default value for :prop_tgt:`CXX_STANDARD` property of targets." nil) ("CMAKE_CXX_STANDARD_REQUIRED" "Default value for :prop_tgt:`CXX_STANDARD_REQUIRED` property of targets." nil) ("CMAKE_C_COMPILE_FEATURES" "List of features known to the C compiler" nil) ("CMAKE_C_EXTENSIONS" "Default value for :prop_tgt:`C_EXTENSIONS` property of targets." nil) ("CMAKE_C_STANDARD" "Default value for :prop_tgt:`C_STANDARD` property of targets." nil) ("CMAKE_C_STANDARD_REQUIRED" "Default value for :prop_tgt:`C_STANDARD_REQUIRED` property of targets." nil) ("CMAKE_DEBUG_POSTFIX" "See variable :variable:`CMAKE_<CONFIG>_POSTFIX`." nil) ("CMAKE_DEBUG_TARGET_PROPERTIES" "Enables tracing output for target properties." nil) ("CMAKE_DEPENDS_IN_PROJECT_ONLY" "When set to ``TRUE`` in a directory, the build system produced by the
:ref:`Makefile Generators` is set up to only consider dependencies on source
files that appear either in the source or in the binary directories." nil) ("CMAKE_DIRECTORY_LABELS" "Specify labels for the current directory." nil) ("CMAKE_DISABLE_FIND_PACKAGE_PackageName" "Variable for disabling :command:`find_package` calls." nil) ("CMAKE_DL_LIBS" "Name of library containing ``dlopen`` and ``dlclose``." nil) ("CMAKE_DOTNET_TARGET_FRAMEWORK_VERSION" "Default value for :prop_tgt:`DOTNET_TARGET_FRAMEWORK_VERSION`
property of targets." nil) ("CMAKE_ECLIPSE_GENERATE_LINKED_RESOURCES" "This cache variable is used by the Eclipse project generator." nil) ("CMAKE_ECLIPSE_GENERATE_SOURCE_PROJECT" "This cache variable is used by the Eclipse project generator." nil) ("CMAKE_ECLIPSE_MAKE_ARGUMENTS" "This cache variable is used by the Eclipse project generator." nil) ("CMAKE_ECLIPSE_VERSION" "This cache variable is used by the Eclipse project generator." nil) ("CMAKE_EDIT_COMMAND" "Full path to :manual:`cmake-gui(1)` or :manual:`ccmake(1)`." nil) ("CMAKE_ENABLE_EXPORTS" "Specify whether an executable exports symbols for loadable modules." nil) ("CMAKE_ERROR_DEPRECATED" "Whether to issue errors for deprecated functionality." nil) ("CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION" "Ask ``cmake_install.cmake`` script to error out as soon as a file with
absolute ``INSTALL DESTINATION`` is encountered." nil) ("CMAKE_EXECUTABLE_SUFFIX" "The suffix for executables on this platform." nil) ("CMAKE_EXE_LINKER_FLAGS" "Linker flags to be used to create executables." nil) ("CMAKE_EXE_LINKER_FLAGS_CONFIG" "Flags to be used when linking an executable." nil) ("CMAKE_EXE_LINKER_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_EXE_LINKER_FLAGS_<CONFIG>`
cache entry the first time a build tree is configured." nil) ("CMAKE_EXE_LINKER_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_EXE_LINKER_FLAGS`
cache entry the first time a build tree is configured." nil) ("CMAKE_EXPORT_COMPILE_COMMANDS" "Enable/Disable output of compile commands during generation." "  [
    {
      \"directory\": \"/home/user/development/project\",
      \"command\": \"/usr/bin/c++ ... -c ../foo/foo.cc\",
      \"file\": \"../foo/foo.cc\"
    },") ("CMAKE_EXPORT_NO_PACKAGE_REGISTRY" "Disable the :command:`export(PACKAGE)` command." nil) ("CMAKE_EXTRA_GENERATOR" "The extra generator used to build the project." nil) ("CMAKE_EXTRA_SHARED_LIBRARY_SUFFIXES" "Additional suffixes for shared libraries." nil) ("CMAKE_FIND_APPBUNDLE" "This variable affects how ``find_*`` commands choose between
macOS Application Bundles and unix-style package components." nil) ("CMAKE_FIND_FRAMEWORK" "This variable affects how ``find_*`` commands choose between
macOS Frameworks and unix-style package components." nil) ("CMAKE_FIND_LIBRARY_CUSTOM_LIB_SUFFIX" "Specify a ``<suffix>`` to tell the :command:`find_library` command to
search in a ``lib<suffix>`` directory before each ``lib`` directory that
would normally be searched." nil) ("CMAKE_FIND_LIBRARY_PREFIXES" "Prefixes to prepend when looking for libraries." nil) ("CMAKE_FIND_LIBRARY_SUFFIXES" "Suffixes to append when looking for libraries." nil) ("CMAKE_FIND_NO_INSTALL_PREFIX" "Exclude the values of the :variable:`CMAKE_INSTALL_PREFIX` and
:variable:`CMAKE_STAGING_PREFIX` variables from
:variable:`CMAKE_SYSTEM_PREFIX_PATH`." nil) ("CMAKE_FIND_PACKAGE_NAME" "Defined by the :command:`find_package` command while loading
a find module to record the caller-specified package name." nil) ("CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY" "Skip :ref:`User Package Registry` in :command:`find_package` calls." nil) ("CMAKE_FIND_PACKAGE_NO_SYSTEM_PACKAGE_REGISTRY" "Skip :ref:`System Package Registry` in :command:`find_package` calls." nil) ("CMAKE_FIND_PACKAGE_RESOLVE_SYMLINKS" "Set to ``TRUE`` to tell :command:`find_package` calls to resolve symbolic
links in the value of ``<PackageName>_DIR``." nil) ("CMAKE_FIND_PACKAGE_SORT_DIRECTION" "The sorting direction used by :variable:`CMAKE_FIND_PACKAGE_SORT_ORDER`." nil) ("CMAKE_FIND_PACKAGE_SORT_ORDER" "The default order for sorting packages found using :command:`find_package`." "  set(CMAKE_FIND_PACKAGE_SORT_ORDER NATURAL)
  find_package(libX CONFIG)") ("CMAKE_FIND_PACKAGE_WARN_NO_MODULE" "Tell :command:`find_package` to warn if called without an explicit mode." nil) ("CMAKE_FIND_ROOT_PATH" "This variable is most useful when cross-compiling. CMake uses the paths in
this list as alternative roots to find filesystem items with
:command:`find_package`, :command:`find_library` etc." nil) ("CMAKE_FIND_ROOT_PATH_MODE_INCLUDE" nil nil) ("CMAKE_FIND_ROOT_PATH_MODE_LIBRARY" nil nil) ("CMAKE_FIND_ROOT_PATH_MODE_PACKAGE" nil nil) ("CMAKE_FIND_ROOT_PATH_MODE_PROGRAM" nil nil) ("CMAKE_FOLDER" "Set the folder name. Use to organize targets in an IDE." nil) ("CMAKE_FRAMEWORK_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for macOS frameworks used by the :command:`find_library`,
:command:`find_package`, :command:`find_path`, and :command:`find_file`
commands." nil) ("CMAKE_Fortran_FORMAT" "Set to ``FIXED`` or ``FREE`` to indicate the Fortran source layout." nil) ("CMAKE_Fortran_MODDIR_DEFAULT" "Fortran default module output directory." nil) ("CMAKE_Fortran_MODDIR_FLAG" "Fortran flag for module output directory." nil) ("CMAKE_Fortran_MODOUT_FLAG" "Fortran flag to enable module output." nil) ("CMAKE_Fortran_MODULE_DIRECTORY" "Fortran module output directory." nil) ("CMAKE_GENERATOR" "The generator used to build the project." nil) ("CMAKE_GENERATOR_INSTANCE" "Generator-specific instance specification provided by user." nil) ("CMAKE_GENERATOR_PLATFORM" "Generator-specific target platform specification provided by user." nil) ("CMAKE_GENERATOR_TOOLSET" "Native build system toolset specification provided by user." nil) ("CMAKE_GHS_NO_SOURCE_GROUP_FILE" "``ON`` / ``OFF`` boolean to control if the project file for a target should
be one single file or multiple files." nil) ("CMAKE_GLOBAL_AUTOGEN_TARGET" "Switch to enable generation of a global ``autogen`` target." nil) ("CMAKE_GLOBAL_AUTOGEN_TARGET_NAME" "Change the name of the global ``autogen`` target." nil) ("CMAKE_GLOBAL_AUTORCC_TARGET" "Switch to enable generation of a global ``autorcc`` target." nil) ("CMAKE_GLOBAL_AUTORCC_TARGET_NAME" "Change the name of the global ``autorcc`` target." nil) ("CMAKE_GNUtoMS" "Convert GNU import libraries (``.dll.a``) to MS format (``.lib``)." nil) ("CMAKE_HOME_DIRECTORY" "Path to top of source tree. Same as :variable:`CMAKE_SOURCE_DIR`." nil) ("CMAKE_HOST_APPLE" "``True`` for Apple macOS operating systems." nil) ("CMAKE_HOST_SOLARIS" "``True`` for Oracle Solaris operating systems." nil) ("CMAKE_HOST_SYSTEM" "Composite Name of OS CMake is being run on." nil) ("CMAKE_HOST_SYSTEM_NAME" "Name of the OS CMake is running on." nil) ("CMAKE_HOST_SYSTEM_PROCESSOR" "The name of the CPU CMake is running on." nil) ("CMAKE_HOST_SYSTEM_VERSION" "The OS version CMake is running on." nil) ("CMAKE_HOST_UNIX" "``True`` for UNIX and UNIX like operating systems." nil) ("CMAKE_HOST_WIN32" "``True`` if the host system is running Windows, including Windows 64-bit and MSYS." nil) ("CMAKE_IGNORE_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories to be *ignored* by
the :command:`find_program`, :command:`find_library`, :command:`find_file`,
and :command:`find_path` commands." nil) ("CMAKE_IMPORT_LIBRARY_PREFIX" "The prefix for import libraries that you link to." nil) ("CMAKE_IMPORT_LIBRARY_SUFFIX" "The suffix for import libraries that you link to." nil) ("CMAKE_INCLUDE_CURRENT_DIR" "Automatically add the current source and build directories to the include path." nil) ("CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE" "Automatically add the current source and build directories to the
:prop_tgt:`INTERFACE_INCLUDE_DIRECTORIES` target property." nil) ("CMAKE_INCLUDE_DIRECTORIES_BEFORE" "Whether to append or prepend directories by default in
:command:`include_directories`." nil) ("CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE" "Whether to force prepending of project include directories." nil) ("CMAKE_INCLUDE_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for the :command:`find_file` and :command:`find_path` commands." nil) ("CMAKE_INSTALL_DEFAULT_COMPONENT_NAME" "Default component used in :command:`install` commands." nil) ("CMAKE_INSTALL_DEFAULT_DIRECTORY_PERMISSIONS" "Default permissions for directories created implicitly during installation
of files by :command:`install` and :command:`file(INSTALL)`." nil) ("CMAKE_INSTALL_MESSAGE" "Specify verbosity of installation script code generated by the
:command:`install` command (using the :command:`file(INSTALL)` command)." "  -- Installing: /some/destination/path") ("CMAKE_INSTALL_NAME_DIR" "macOS directory name for installed targets." nil) ("CMAKE_INSTALL_PREFIX" "Install directory used by :command:`install`." nil) ("CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT" "CMake sets this variable to a ``TRUE`` value when the
:variable:`CMAKE_INSTALL_PREFIX` has just been initialized to
its default value, typically on the first run of CMake within
a new build tree." nil) ("CMAKE_INSTALL_RPATH" "The rpath to use for installed targets." nil) ("CMAKE_INSTALL_RPATH_USE_LINK_PATH" "Add paths to linker search and installed rpath." nil) ("CMAKE_INTERNAL_PLATFORM_ABI" "An internal variable subject to change." nil) ("CMAKE_INTERPROCEDURAL_OPTIMIZATION" "Default value for :prop_tgt:`INTERPROCEDURAL_OPTIMIZATION` of targets." nil) ("CMAKE_INTERPROCEDURAL_OPTIMIZATION_CONFIG" "Default value for :prop_tgt:`INTERPROCEDURAL_OPTIMIZATION_<CONFIG>` of targets." nil) ("CMAKE_IOS_INSTALL_COMBINED" "Default value for :prop_tgt:`IOS_INSTALL_COMBINED` of targets." nil) ("CMAKE_JOB_POOLS" "If the :prop_gbl:`JOB_POOLS` global property is not set, the value
of this variable is used in its place." nil) ("CMAKE_JOB_POOL_COMPILE" "This variable is used to initialize the :prop_tgt:`JOB_POOL_COMPILE`
property on all the targets. See :prop_tgt:`JOB_POOL_COMPILE`
for additional information." nil) ("CMAKE_JOB_POOL_LINK" "This variable is used to initialize the :prop_tgt:`JOB_POOL_LINK`
property on all the targets. See :prop_tgt:`JOB_POOL_LINK`
for additional information." nil) ("CMAKE_ASM_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_ASM-ATT_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_ASM-MASM_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_ASM-NASM_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_C_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_CSharp_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_CUDA_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_CXX_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_Fortran_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_Java_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_RC_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_Swift_ANDROID_TOOLCHAIN_MACHINE" "When :ref:`Cross Compiling for Android` this variable contains the
toolchain binutils machine name (e.g. ``gcc -dumpmachine``)." nil) ("CMAKE_ASM_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_ASM-ATT_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_ASM-MASM_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_ASM-NASM_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_C_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_CSharp_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_CUDA_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_CXX_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_Fortran_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_Java_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_RC_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_Swift_ANDROID_TOOLCHAIN_PREFIX" "When :ref:`Cross Compiling for Android` this variable contains the absolute
path prefixing the toolchain GNU compiler and its binutils." nil) ("CMAKE_ASM_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_ASM-ATT_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_ASM-MASM_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_ASM-NASM_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_C_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_CSharp_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_CUDA_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_CXX_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_Fortran_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_Java_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_RC_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_Swift_ANDROID_TOOLCHAIN_SUFFIX" "When :ref:`Cross Compiling for Android` this variable contains the
host platform suffix of the toolchain GNU compiler and its binutils." nil) ("CMAKE_ASM_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_ASM-ATT_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_ASM-MASM_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_ASM-NASM_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_C_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_CSharp_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_CUDA_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_CXX_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_Fortran_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_Java_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_RC_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_Swift_ARCHIVE_APPEND" "Rule variable to append to a static archive." nil) ("CMAKE_ASM_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_ASM-ATT_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_ASM-MASM_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_ASM-NASM_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_C_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_CSharp_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_CUDA_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_CXX_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_Fortran_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_Java_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_RC_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_Swift_ARCHIVE_CREATE" "Rule variable to create a new static archive." nil) ("CMAKE_ASM_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_ASM-ATT_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_ASM-MASM_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_ASM-NASM_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_C_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_CSharp_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_CUDA_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_CXX_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_Fortran_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_Java_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_RC_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_Swift_ARCHIVE_FINISH" "Rule variable to finish an existing static archive." nil) ("CMAKE_ASM_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_ASM-ATT_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_ASM-MASM_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_ASM-NASM_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_C_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_CSharp_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_CUDA_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_CXX_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_Fortran_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_Java_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_RC_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_Swift_CLANG_TIDY" "Default value for :prop_tgt:`<LANG>_CLANG_TIDY` target property
when ``<LANG>`` is ``C`` or ``CXX``." nil) ("CMAKE_ASM_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_ASM-ATT_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_ASM-MASM_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_ASM-NASM_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_C_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_CSharp_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_CUDA_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_CXX_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_Fortran_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_Java_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_RC_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_Swift_COMPILER" "The full path to the compiler for ``LANG``." nil) ("CMAKE_ASM_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_ASM-ATT_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_ASM-MASM_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_ASM-NASM_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_C_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_CSharp_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_CUDA_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_CXX_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_Fortran_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_Java_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_RC_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_Swift_COMPILER_ABI" "An internal variable subject to change." nil) ("CMAKE_ASM_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_ASM-ATT_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_ASM-MASM_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_ASM-NASM_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_C_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_CSharp_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_CUDA_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_CXX_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_Fortran_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_Java_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_RC_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_Swift_COMPILER_AR" "A wrapper around ``ar`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_ASM_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_ASM-ATT_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_ASM-MASM_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_ASM-NASM_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_C_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_CSharp_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_CUDA_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_CXX_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_Fortran_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_Java_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_RC_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_Swift_COMPILER_ARCHITECTURE_ID" "An internal variable subject to change." nil) ("CMAKE_ASM_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_ASM-ATT_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_ASM-MASM_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_ASM-NASM_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_CSharp_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_CUDA_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_Fortran_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_Java_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_RC_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_Swift_COMPILER_EXTERNAL_TOOLCHAIN" "The external toolchain for cross-compiling, if supported." nil) ("CMAKE_ASM_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_ASM-ATT_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_ASM-MASM_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_ASM-NASM_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_C_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_CSharp_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_CUDA_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_CXX_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_Fortran_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_Java_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_RC_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_Swift_COMPILER_ID" "Compiler identification string." "  Absoft = Absoft Fortran (absoft.com)
  ADSP = Analog VisualDSP++ (analog.com)
  AppleClang = Apple Clang (apple.com)
  ARMCC = ARM Compiler (arm.com)
  Bruce = Bruce C Compiler
  CCur = Concurrent Fortran (ccur.com)
  Clang = LLVM Clang (clang.llvm.org)
  Cray = Cray Compiler (cray.com)
  Embarcadero, Borland = Embarcadero (embarcadero.com)
  Flang = Flang LLVM Fortran Compiler
  G95 = G95 Fortran (g95.org)
  GNU = GNU Compiler Collection (gcc.gnu.org)
  GHS = Green Hills Software (www.ghs.com)
  HP = Hewlett-Packard Compiler (hp.com)
  IAR = IAR Systems (iar.com)
  Intel = Intel Compiler (intel.com)
  MIPSpro = SGI MIPSpro (sgi.com)
  MSVC = Microsoft Visual Studio (microsoft.com)
  NVIDIA = NVIDIA CUDA Compiler (nvidia.com)
  OpenWatcom = Open Watcom (openwatcom.org)
  PGI = The Portland Group (pgroup.com)
  PathScale = PathScale (pathscale.com)
  SDCC = Small Device C Compiler (sdcc.sourceforge.net)
  SunPro = Oracle Solaris Studio (oracle.com)
  TI = Texas Instruments (ti.com)
  TinyCC = Tiny C Compiler (tinycc.org)
  XL, VisualAge, zOS = IBM XL (ibm.com)") ("CMAKE_ASM_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_ASM-ATT_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_ASM-MASM_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_ASM-NASM_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_C_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_CSharp_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_CUDA_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_CXX_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_Fortran_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_Java_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_RC_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_Swift_COMPILER_LAUNCHER" "Default value for :prop_tgt:`<LANG>_COMPILER_LAUNCHER` target property." nil) ("CMAKE_ASM_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_ASM-ATT_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_ASM-MASM_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_ASM-NASM_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_C_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_CSharp_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_CUDA_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_CXX_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_Fortran_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_Java_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_RC_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_Swift_COMPILER_LOADED" "Defined to true if the language is enabled." nil) ("CMAKE_ASM_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_ASM-ATT_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_ASM-MASM_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_ASM-NASM_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_C_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_CSharp_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_CUDA_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_CXX_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_Fortran_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_Java_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_RC_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_Swift_COMPILER_PREDEFINES_COMMAND" "Command that outputs the compiler pre definitions." nil) ("CMAKE_ASM_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_ASM-ATT_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_ASM-MASM_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_ASM-NASM_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_C_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_CSharp_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_CUDA_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_CXX_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_Fortran_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_Java_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_RC_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_Swift_COMPILER_RANLIB" "A wrapper around ``ranlib`` adding the appropriate ``--plugin`` option for the
compiler." nil) ("CMAKE_ASM_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_ASM-ATT_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_ASM-MASM_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_ASM-NASM_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_C_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_CSharp_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_CUDA_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_CXX_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_Fortran_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_Java_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_RC_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_Swift_COMPILER_TARGET" "The target for cross-compiling, if supported." nil) ("CMAKE_ASM_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_ASM-ATT_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_ASM-MASM_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_ASM-NASM_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_C_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_CSharp_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_CUDA_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_CXX_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_Fortran_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_Java_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_RC_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_Swift_COMPILER_VERSION" "Compiler version string." nil) ("CMAKE_ASM_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_ASM-ATT_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_ASM-MASM_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_ASM-NASM_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_C_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_CSharp_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_CUDA_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_CXX_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_Fortran_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_Java_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_RC_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_Swift_COMPILER_VERSION_INTERNAL" "An internal variable subject to change." nil) ("CMAKE_ASM_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_ASM-ATT_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_ASM-MASM_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_ASM-NASM_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_C_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_CSharp_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_CUDA_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_CXX_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_Fortran_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_Java_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_RC_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_Swift_COMPILE_OBJECT" "Rule variable to compile a single object file." nil) ("CMAKE_ASM_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_ASM-ATT_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_ASM-MASM_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_ASM-NASM_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_C_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_CSharp_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_CUDA_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_CXX_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_Fortran_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_Java_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_RC_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_Swift_CPPCHECK" "Default value for :prop_tgt:`<LANG>_CPPCHECK` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_ASM_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_ASM-ATT_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_ASM-MASM_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_ASM-NASM_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_C_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_CSharp_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_CUDA_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_CXX_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_Fortran_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_Java_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_RC_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_Swift_CPPLINT" "Default value for :prop_tgt:`<LANG>_CPPLINT` target property. This variable
is used to initialize the property on each target as it is created." nil) ("CMAKE_ASM_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_ASM-ATT_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_ASM-MASM_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_ASM-NASM_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_C_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_CSharp_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_CUDA_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_CXX_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_Fortran_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_Java_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_RC_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_Swift_CREATE_SHARED_LIBRARY" "Rule variable to create a shared library." nil) ("CMAKE_ASM_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_ASM-ATT_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_ASM-MASM_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_ASM-NASM_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_C_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_CSharp_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_CUDA_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_CXX_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_Fortran_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_Java_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_RC_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_Swift_CREATE_SHARED_MODULE" "Rule variable to create a shared module." nil) ("CMAKE_ASM_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_ASM-ATT_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_ASM-MASM_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_ASM-NASM_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_C_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_CSharp_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_CUDA_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_CXX_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_Fortran_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_Java_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_RC_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_Swift_CREATE_STATIC_LIBRARY" "Rule variable to create a static library." nil) ("CMAKE_ASM_FLAGS" "Flags for all build types." nil) ("CMAKE_ASM-ATT_FLAGS" "Flags for all build types." nil) ("CMAKE_ASM-MASM_FLAGS" "Flags for all build types." nil) ("CMAKE_ASM-NASM_FLAGS" "Flags for all build types." nil) ("CMAKE_C_FLAGS" "Flags for all build types." nil) ("CMAKE_CSharp_FLAGS" "Flags for all build types." nil) ("CMAKE_CUDA_FLAGS" "Flags for all build types." nil) ("CMAKE_CXX_FLAGS" "Flags for all build types." nil) ("CMAKE_Fortran_FLAGS" "Flags for all build types." nil) ("CMAKE_Java_FLAGS" "Flags for all build types." nil) ("CMAKE_RC_FLAGS" "Flags for all build types." nil) ("CMAKE_Swift_FLAGS" "Flags for all build types." nil) ("CMAKE_ASM_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_ASM-ATT_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_ASM-MASM_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_ASM-NASM_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_C_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_CSharp_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_CUDA_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_CXX_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_Fortran_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_Java_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_RC_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_Swift_FLAGS_CONFIG" "Flags for language ``<LANG>`` when building for the ``<CONFIG>`` configuration." nil) ("CMAKE_ASM_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_ASM-ATT_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_ASM-MASM_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_ASM-NASM_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_C_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_CSharp_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_CUDA_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_CXX_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_Fortran_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_Java_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_RC_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_Swift_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` cache
entry the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_ASM_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-ATT_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-MASM_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-NASM_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_C_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CSharp_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CUDA_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CXX_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Fortran_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Java_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_RC_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Swift_FLAGS_DEBUG" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-ATT_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-MASM_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-NASM_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_C_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CSharp_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CUDA_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CXX_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Fortran_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Java_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_RC_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Swift_FLAGS_DEBUG_INIT" "This variable is the ``Debug`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_ASM-ATT_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_ASM-MASM_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_ASM-NASM_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_C_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_CSharp_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_CUDA_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_CXX_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_Fortran_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_Java_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_RC_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_Swift_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_<LANG>_FLAGS` cache entry
the first time a build tree is configured for language ``<LANG>``." nil) ("CMAKE_ASM_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-ATT_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-MASM_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-NASM_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_C_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CSharp_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CUDA_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CXX_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Fortran_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Java_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_RC_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Swift_FLAGS_MINSIZEREL" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-ATT_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-MASM_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-NASM_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_C_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CSharp_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CUDA_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CXX_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Fortran_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Java_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_RC_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Swift_FLAGS_MINSIZEREL_INIT" "This variable is the ``MinSizeRel`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-ATT_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-MASM_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-NASM_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_C_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CSharp_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CUDA_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CXX_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Fortran_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Java_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_RC_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Swift_FLAGS_RELEASE" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-ATT_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-MASM_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-NASM_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_C_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CSharp_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CUDA_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CXX_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Fortran_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Java_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_RC_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Swift_FLAGS_RELEASE_INIT" "This variable is the ``Release`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-ATT_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-MASM_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM-NASM_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_C_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CSharp_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CUDA_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_CXX_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Fortran_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Java_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_RC_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_Swift_FLAGS_RELWITHDEBINFO" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>` variable." nil) ("CMAKE_ASM_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-ATT_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-MASM_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM-NASM_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_C_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CSharp_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CUDA_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Fortran_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Java_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_RC_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_Swift_FLAGS_RELWITHDEBINFO_INIT" "This variable is the ``RelWithDebInfo`` variant of the
:variable:`CMAKE_<LANG>_FLAGS_<CONFIG>_INIT` variable." nil) ("CMAKE_ASM_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_ASM-ATT_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_ASM-MASM_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_ASM-NASM_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_C_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_CSharp_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_CUDA_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_CXX_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_Fortran_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_Java_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_RC_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_Swift_IGNORE_EXTENSIONS" "File extensions that should be ignored by the build." nil) ("CMAKE_ASM_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_ASM-ATT_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_ASM-MASM_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_ASM-NASM_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_CSharp_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_CUDA_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_Fortran_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_Java_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_RC_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_Swift_IMPLICIT_INCLUDE_DIRECTORIES" "Directories implicitly searched by the compiler for header files." nil) ("CMAKE_ASM_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_ASM-ATT_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_ASM-MASM_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_ASM-NASM_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_C_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_CSharp_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_Fortran_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_Java_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_RC_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_Swift_IMPLICIT_LINK_DIRECTORIES" "Implicit linker search path detected for language ``<LANG>``." nil) ("CMAKE_ASM_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_ASM-ATT_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_ASM-MASM_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_ASM-NASM_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_C_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_CSharp_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_CUDA_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_CXX_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_Fortran_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_Java_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_RC_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_Swift_IMPLICIT_LINK_FRAMEWORK_DIRECTORIES" "Implicit linker framework search path detected for language ``<LANG>``." nil) ("CMAKE_ASM_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_ASM-ATT_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_ASM-MASM_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_ASM-NASM_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_C_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_CSharp_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_CXX_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_Java_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_RC_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_Swift_IMPLICIT_LINK_LIBRARIES" "Implicit link libraries and flags detected for language ``<LANG>``." nil) ("CMAKE_ASM_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_ASM-ATT_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_ASM-MASM_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_ASM-NASM_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_C_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_CSharp_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_CUDA_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_CXX_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_Fortran_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_Java_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_RC_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_Swift_INCLUDE_WHAT_YOU_USE" "Default value for :prop_tgt:`<LANG>_INCLUDE_WHAT_YOU_USE` target property." nil) ("CMAKE_ASM_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_ASM-ATT_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_ASM-MASM_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_ASM-NASM_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_C_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_CSharp_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_CUDA_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_CXX_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_Fortran_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_Java_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_RC_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_Swift_LIBRARY_ARCHITECTURE" "Target architecture library directory name detected for ``<LANG>``." nil) ("CMAKE_ASM_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_ASM-ATT_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_ASM-MASM_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_ASM-NASM_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_C_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_CSharp_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_CUDA_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_CXX_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_Fortran_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_Java_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_RC_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_Swift_LINKER_PREFERENCE" "Preference value for linker language selection." nil) ("CMAKE_ASM_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_ASM-ATT_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_ASM-MASM_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_ASM-NASM_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_C_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_CSharp_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_CUDA_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_CXX_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_Fortran_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_Java_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_RC_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_Swift_LINKER_PREFERENCE_PROPAGATES" "True if :variable:`CMAKE_<LANG>_LINKER_PREFERENCE` propagates across targets." nil) ("CMAKE_ASM_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_ASM-ATT_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_ASM-MASM_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_ASM-NASM_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_C_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_CSharp_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_CUDA_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_CXX_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_Fortran_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_Java_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_RC_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_Swift_LINKER_WRAPPER_FLAG" "Defines the syntax of compiler driver option to pass options to the linker
tool. It will be used to translate the ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." "  set (CMAKE_C_LINKER_WRAPPER_FLAG \"-Xlinker\" \" \")") ("CMAKE_ASM_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_ASM-ATT_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_ASM-MASM_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_ASM-NASM_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_C_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_CSharp_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_CUDA_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_CXX_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_Fortran_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_Java_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_RC_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_Swift_LINKER_WRAPPER_FLAG_SEP" "This variable is used with :variable:`CMAKE_<LANG>_LINKER_WRAPPER_FLAG`
variable to format ``LINKER:`` prefix in the link options
(see :command:`add_link_options` and :command:`target_link_options`)." nil) ("CMAKE_ASM_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_ASM-ATT_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_ASM-MASM_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_ASM-NASM_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_C_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_CSharp_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_CUDA_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_CXX_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_Fortran_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_Java_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_RC_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_Swift_LINK_EXECUTABLE" "Rule variable to link an executable." nil) ("CMAKE_ASM_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_ASM-ATT_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_ASM-MASM_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_ASM-NASM_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_C_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_CSharp_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_CUDA_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_CXX_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_Fortran_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_Java_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_RC_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_Swift_OUTPUT_EXTENSION" "Extension for the output of a compile for a single file." nil) ("CMAKE_ASM_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_ASM-ATT_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_ASM-MASM_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_ASM-NASM_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_C_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_CSharp_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_CUDA_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_CXX_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_Fortran_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_Java_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_RC_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_Swift_PLATFORM_ID" "An internal variable subject to change." nil) ("CMAKE_ASM_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_ASM-ATT_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_ASM-MASM_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_ASM-NASM_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_C_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_CSharp_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_CUDA_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_CXX_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_Fortran_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_Java_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_RC_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_Swift_SIMULATE_ID" "Identification string of \"simulated\" compiler." nil) ("CMAKE_ASM_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_ASM-ATT_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_ASM-MASM_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_ASM-NASM_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_C_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_CSharp_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_CUDA_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_CXX_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_Fortran_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_Java_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_RC_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_Swift_SIMULATE_VERSION" "Version string of \"simulated\" compiler." nil) ("CMAKE_ASM_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_ASM-ATT_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_ASM-MASM_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_ASM-NASM_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_C_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_CSharp_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_CUDA_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_CXX_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_Fortran_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_Java_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_RC_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_Swift_SIZEOF_DATA_PTR" "Size of pointer-to-data types for language ``<LANG>``." nil) ("CMAKE_ASM_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_ASM-ATT_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_ASM-MASM_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_ASM-NASM_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_C_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_CSharp_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_CUDA_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_CXX_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_Fortran_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_Java_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_RC_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_Swift_SOURCE_FILE_EXTENSIONS" "Extensions of source files for the given language." nil) ("CMAKE_ASM_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_ASM-ATT_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_ASM-MASM_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_ASM-NASM_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_C_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_CSharp_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_CUDA_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_Fortran_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_Java_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_RC_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_Swift_STANDARD_INCLUDE_DIRECTORIES" "Include directories to be used for every source file compiled with
the ``<LANG>`` compiler." nil) ("CMAKE_ASM_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_ASM-ATT_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_ASM-MASM_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_ASM-NASM_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_C_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_CSharp_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_CUDA_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_CXX_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_Fortran_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_Java_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_RC_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_Swift_STANDARD_LIBRARIES" "Libraries linked into every executable and shared library linked
for language ``<LANG>``." nil) ("CMAKE_ASM_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_ASM-ATT_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_ASM-MASM_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_ASM-NASM_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_C_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_CSharp_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_CUDA_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_CXX_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_Fortran_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_Java_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_RC_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_Swift_VISIBILITY_PRESET" "Default value for the :prop_tgt:`<LANG>_VISIBILITY_PRESET` target
property when a target is created." nil) ("CMAKE_LIBRARY_ARCHITECTURE" "Target architecture library directory name, if detected." nil) ("CMAKE_LIBRARY_ARCHITECTURE_REGEX" "Regex matching possible target architecture library directory names." nil) ("CMAKE_LIBRARY_OUTPUT_DIRECTORY" "Where to put all the :ref:`LIBRARY <Library Output Artifacts>`
target files when built." nil) ("CMAKE_LIBRARY_OUTPUT_DIRECTORY_CONFIG" "Where to put all the :ref:`LIBRARY <Library Output Artifacts>`
target files when built for a specific configuration." nil) ("CMAKE_LIBRARY_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for the :command:`find_library` command." nil) ("CMAKE_LIBRARY_PATH_FLAG" "The flag to be used to add a library search path to a compiler." nil) ("CMAKE_LINK_DEF_FILE_FLAG" "Linker flag to be used to specify a ``.def`` file for dll creation." nil) ("CMAKE_LINK_DEPENDS_NO_SHARED" "Whether to skip link dependencies on shared library files." nil) ("CMAKE_LINK_DIRECTORIES_BEFORE" "Whether to append or prepend directories by default in
:command:`link_directories`." nil) ("CMAKE_LINK_INTERFACE_LIBRARIES" "Default value for :prop_tgt:`LINK_INTERFACE_LIBRARIES` of targets." nil) ("CMAKE_LINK_LIBRARY_FILE_FLAG" "Flag to be used to link a library specified by a path to its file." nil) ("CMAKE_LINK_LIBRARY_FLAG" "Flag to be used to link a library into an executable." nil) ("CMAKE_LINK_LIBRARY_SUFFIX" "The suffix for libraries that you link to." nil) ("CMAKE_LINK_SEARCH_END_STATIC" "End a link line such that static system libraries are used." nil) ("CMAKE_LINK_SEARCH_START_STATIC" "Assume the linker looks for static libraries by default." nil) ("CMAKE_LINK_WHAT_YOU_USE" "Default value for :prop_tgt:`LINK_WHAT_YOU_USE` target property." nil) ("CMAKE_MACOSX_BUNDLE" "Default value for :prop_tgt:`MACOSX_BUNDLE` of targets." nil) ("CMAKE_MACOSX_RPATH" "Whether to use rpaths on macOS and iOS." nil) ("CMAKE_MAJOR_VERSION" "First version number component of the :variable:`CMAKE_VERSION`
variable." nil) ("CMAKE_MAKE_PROGRAM" "Tool that can launch the native build system." nil) ("CMAKE_MAP_IMPORTED_CONFIG_CONFIG" "Default value for :prop_tgt:`MAP_IMPORTED_CONFIG_<CONFIG>` of targets." nil) ("CMAKE_MATCH_COUNT" "The number of matches with the last regular expression." nil) ("CMAKE_MATCH_n" "Capture group ``<n>`` matched by the last regular expression, for groups
0 through 9." nil) ("CMAKE_MAXIMUM_RECURSION_DEPTH" "Maximum recursion depth for CMake scripts. It is intended to be set on the
command line with ``-DCMAKE_MAXIMUM_RECURSION_DEPTH=<x>``, or within
``CMakeLists.txt`` by projects that require a large recursion depth. Projects
that set this variable should provide the user with a way to override it. For
example:" "  # About to perform deeply recursive actions
  if(NOT CMAKE_MAXIMUM_RECURSION_DEPTH)
    set(CMAKE_MAXIMUM_RECURSION_DEPTH 2000)
  endif()") ("CMAKE_MFC_FLAG" "Use the MFC library for an executable or dll." nil) ("CMAKE_MINIMUM_REQUIRED_VERSION" "The ``<min>`` version of CMake given to the most recent call to the
:command:`cmake_minimum_required(VERSION)` command." nil) ("CMAKE_MINOR_VERSION" "Second version number component of the :variable:`CMAKE_VERSION`
variable." nil) ("CMAKE_MODULE_LINKER_FLAGS" "Linker flags to be used to create modules." nil) ("CMAKE_MODULE_LINKER_FLAGS_CONFIG" "Flags to be used when linking a module." nil) ("CMAKE_MODULE_LINKER_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_MODULE_LINKER_FLAGS_<CONFIG>`
cache entry the first time a build tree is configured." nil) ("CMAKE_MODULE_LINKER_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_MODULE_LINKER_FLAGS`
cache entry the first time a build tree is configured." nil) ("CMAKE_MODULE_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for CMake modules to be loaded by the :command:`include` or
:command:`find_package` commands before checking the default modules that come
with CMake." nil) ("CMAKE_MSVCIDE_RUN_PATH" "Extra PATH locations that should be used when executing
:command:`add_custom_command` or :command:`add_custom_target` when using the
:generator:`Visual Studio 9 2008` (or above) generator. This allows
for running commands and using dll's that the IDE environment is not aware of." nil) ("CMAKE_NETRC" "This variable is used to initialize the ``NETRC`` option for
:command:`file(DOWNLOAD)` and :command:`file(UPLOAD)` commands and the
module :module:`ExternalProject`. See those commands for additional
information." nil) ("CMAKE_NETRC_FILE" "This variable is used to initialize the ``NETRC_FILE`` option for
:command:`file(DOWNLOAD)` and :command:`file(UPLOAD)` commands and the
module :module:`ExternalProject`. See those commands for additional
information." nil) ("CMAKE_NINJA_OUTPUT_PATH_PREFIX" "Set output files path prefix for the :generator:`Ninja` generator." "  cd top-build-dir/sub &&
  cmake -G Ninja -DCMAKE_NINJA_OUTPUT_PATH_PREFIX=sub/ path/to/source") ("CMAKE_NOT_USING_CONFIG_FLAGS" "Skip ``_BUILD_TYPE`` flags if true." nil) ("CMAKE_NO_BUILTIN_CHRPATH" "Do not use the builtin ELF editor to fix RPATHs on installation." nil) ("CMAKE_NO_SYSTEM_FROM_IMPORTED" "Default value for :prop_tgt:`NO_SYSTEM_FROM_IMPORTED` of targets." nil) ("CMAKE_OBJECT_PATH_MAX" "Maximum object file full-path length allowed by native build tools." nil) ("CMAKE_OSX_ARCHITECTURES" "Target specific architectures for macOS and iOS." nil) ("CMAKE_OSX_DEPLOYMENT_TARGET" "Specify the minimum version of the target platform (e.g. macOS or iOS)
on which the target binaries are to be deployed." nil) ("CMAKE_OSX_SYSROOT" "Specify the location or name of the macOS platform SDK to be used." nil) ("CMAKE_PARENT_LIST_FILE" "Full path to the CMake file that included the current one." nil) ("CMAKE_PATCH_VERSION" "Third version number component of the :variable:`CMAKE_VERSION`
variable." nil) ("CMAKE_PDB_OUTPUT_DIRECTORY" "Output directory for MS debug symbol ``.pdb`` files generated by the
linker for executable and shared library targets." nil) ("CMAKE_PDB_OUTPUT_DIRECTORY_CONFIG" "Per-configuration output directory for MS debug symbol ``.pdb`` files
generated by the linker for executable and shared library targets." nil) ("CMAKE_POLICY_DEFAULT_CMPNNNN" "Default for CMake Policy ``CMP<NNNN>`` when it is otherwise left unset." nil) ("CMAKE_POLICY_WARNING_CMPNNNN" "Explicitly enable or disable the warning when CMake Policy ``CMP<NNNN>``
is not set." nil) ("CMAKE_POSITION_INDEPENDENT_CODE" "Default value for :prop_tgt:`POSITION_INDEPENDENT_CODE` of targets." nil) ("CMAKE_PREFIX_PATH" "Each command will add appropriate
subdirectories (like ``bin``, ``lib``, or ``include``) as specified in its own
documentation." nil) ("CMAKE_PROGRAM_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for the :command:`find_program` command." nil) ("CMAKE_PROJECT_DESCRIPTION" "The description of the top level project." "  cmake_minimum_required(VERSION 3.0)
  project(First DESCRIPTION \"I am First\")
  project(Second DESCRIPTION \"I am Second\")
  add_subdirectory(sub)
  project(Third DESCRIPTION \"I am Third\")") ("CMAKE_PROJECT_HOMEPAGE_URL" "The homepage URL of the top level project." "  cmake_minimum_required(VERSION 3.0)
  project(First HOMEPAGE_URL \"http://first.example.com\")
  project(Second HOMEPAGE_URL \"http://second.example.com\")
  add_subdirectory(sub)
  project(Third HOMEPAGE_URL \"http://third.example.com\")") ("CMAKE_PROJECT_NAME" "The name of the top level project." "  cmake_minimum_required(VERSION 3.0)
  project(First)
  project(Second)
  add_subdirectory(sub)
  project(Third)") ("CMAKE_PROJECT_PROJECT-NAME_INCLUDE" "A CMake language file or module to be included by the :command:`project`
command." nil) ("CMAKE_PROJECT_VERSION" "The version of the top level project." "  cmake_minimum_required(VERSION 3.0)
  project(First VERSION 1.2.3)
  project(Second VERSION 3.4.5)
  add_subdirectory(sub)
  project(Third VERSION 6.7.8)") ("CMAKE_PROJECT_VERSION_MAJOR" "The major version of the top level project." nil) ("CMAKE_PROJECT_VERSION_MINOR" "The minor version of the top level project." nil) ("CMAKE_PROJECT_VERSION_PATCH" "The patch version of the top level project." nil) ("CMAKE_PROJECT_VERSION_TWEAK" "The tweak version of the top level project." nil) ("CMAKE_RANLIB" "Name of randomizing tool for static libraries." nil) ("CMAKE_ROOT" "Install directory for running cmake." nil) ("CMAKE_RULE_MESSAGES" "Specify whether to report a message for each make rule." nil) ("CMAKE_RUNTIME_OUTPUT_DIRECTORY" "Where to put all the :ref:`RUNTIME <Runtime Output Artifacts>`
target files when built." nil) ("CMAKE_RUNTIME_OUTPUT_DIRECTORY_CONFIG" "Where to put all the :ref:`RUNTIME <Runtime Output Artifacts>`
target files when built for a specific configuration." nil) ("CMAKE_SCRIPT_MODE_FILE" "Full path to the :manual:`cmake(1)` ``-P`` script file currently being
processed." nil) ("CMAKE_SHARED_LIBRARY_PREFIX" "The prefix for shared libraries that you link to." nil) ("CMAKE_SHARED_LIBRARY_SUFFIX" "The suffix for shared libraries that you link to." nil) ("CMAKE_SHARED_LINKER_FLAGS" "Linker flags to be used to create shared libraries." nil) ("CMAKE_SHARED_LINKER_FLAGS_CONFIG" "Flags to be used when linking a shared library." nil) ("CMAKE_SHARED_LINKER_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_SHARED_LINKER_FLAGS_<CONFIG>`
cache entry the first time a build tree is configured." nil) ("CMAKE_SHARED_LINKER_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_SHARED_LINKER_FLAGS`
cache entry the first time a build tree is configured." nil) ("CMAKE_SHARED_MODULE_PREFIX" "The prefix for loadable modules that you link to." nil) ("CMAKE_SHARED_MODULE_SUFFIX" "The suffix for shared libraries that you link to." nil) ("CMAKE_SIZEOF_VOID_P" "Size of a ``void`` pointer." nil) ("CMAKE_SKIP_BUILD_RPATH" "Do not include RPATHs in the build tree." nil) ("CMAKE_SKIP_INSTALL_ALL_DEPENDENCY" "Don't make the ``install`` target depend on the ``all`` target." nil) ("CMAKE_SKIP_INSTALL_RPATH" "Do not include RPATHs in the install tree." nil) ("CMAKE_SKIP_INSTALL_RULES" "Whether to disable generation of installation rules." nil) ("CMAKE_SKIP_RPATH" "If true, do not add run time path information." nil) ("CMAKE_SOURCE_DIR" "The path to the top level of the source tree." nil) ("CMAKE_STAGING_PREFIX" "This variable may be set to a path to install to when cross-compiling. This can
be useful if the path in :variable:`CMAKE_SYSROOT` is read-only, or otherwise
should remain pristine." nil) ("CMAKE_STATIC_LIBRARY_PREFIX" "The prefix for static libraries that you link to." nil) ("CMAKE_STATIC_LIBRARY_SUFFIX" "The suffix for static libraries that you link to." nil) ("CMAKE_STATIC_LINKER_FLAGS" "Linker flags to be used to create static libraries." nil) ("CMAKE_STATIC_LINKER_FLAGS_CONFIG" "Flags to be used when linking a static library." nil) ("CMAKE_STATIC_LINKER_FLAGS_CONFIG_INIT" "Value used to initialize the :variable:`CMAKE_STATIC_LINKER_FLAGS_<CONFIG>`
cache entry the first time a build tree is configured." nil) ("CMAKE_STATIC_LINKER_FLAGS_INIT" "Value used to initialize the :variable:`CMAKE_STATIC_LINKER_FLAGS`
cache entry the first time a build tree is configured." nil) ("CMAKE_SUBLIME_TEXT_2_ENV_SETTINGS" "This variable contains a list of env vars as a list of tokens with the
syntax ``var=value``." "  set(CMAKE_SUBLIME_TEXT_2_ENV_SETTINGS
     \"FOO=FOO1\\;FOO2\\;FOON\"
     \"BAR=BAR1\\;BAR2\\;BARN\"
     \"BAZ=BAZ1\\;BAZ2\\;BAZN\"
     \"FOOBAR=FOOBAR1\\;FOOBAR2\\;FOOBARN\"
     \"VALID=\"
     )") ("CMAKE_SUBLIME_TEXT_2_EXCLUDE_BUILD_TREE" "If this variable evaluates to ``ON`` at the end of the top-level
``CMakeLists.txt`` file, the :generator:`Sublime Text 2` extra generator
excludes the build tree from the ``.sublime-project`` if it is inside the
source tree." nil) ("CMAKE_SUPPRESS_REGENERATION" "If CMAKE_SUPPRESS_REGENERATION is ``OFF``, which is default, then CMake adds a
special target on which all other targets depend that checks the build system
and optionally re-runs CMake to regenerate the build system when the target
specification source changes." nil) ("CMAKE_SYSROOT" "Path to pass to the compiler in the ``--sysroot`` flag." nil) ("CMAKE_SYSROOT_COMPILE" "Path to pass to the compiler in the ``--sysroot`` flag when compiling source
files." nil) ("CMAKE_SYSROOT_LINK" "Path to pass to the compiler in the ``--sysroot`` flag when linking." nil) ("CMAKE_SYSTEM" "Composite name of operating system CMake is compiling for." nil) ("CMAKE_SYSTEM_APPBUNDLE_PATH" "Search path for macOS application bundles used by the :command:`find_program`,
and :command:`find_package` commands." nil) ("CMAKE_SYSTEM_FRAMEWORK_PATH" "Search path for macOS frameworks used by the :command:`find_library`,
:command:`find_package`, :command:`find_path`, and :command:`find_file`
commands." nil) ("CMAKE_SYSTEM_IGNORE_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories to be *ignored* by
the :command:`find_program`, :command:`find_library`, :command:`find_file`,
and :command:`find_path` commands." nil) ("CMAKE_SYSTEM_INCLUDE_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for the :command:`find_file` and :command:`find_path` commands." nil) ("CMAKE_SYSTEM_LIBRARY_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for the :command:`find_library` command." nil) ("CMAKE_SYSTEM_NAME" "The name of the operating system for which CMake is to build." nil) ("CMAKE_SYSTEM_PREFIX_PATH" "Each command will add appropriate
subdirectories (like ``bin``, ``lib``, or ``include``) as specified in its own
documentation." nil) ("CMAKE_SYSTEM_PROCESSOR" "The name of the CPU CMake is building for." nil) ("CMAKE_SYSTEM_PROGRAM_PATH" ":ref:`Semicolon-separated list <CMake Language Lists>` of directories specifying a search path
for the :command:`find_program` command." nil) ("CMAKE_SYSTEM_VERSION" "The version of the operating system for which CMake is to build." nil) ("CMAKE_Swift_LANGUAGE_VERSION" "Set to the Swift language version number." nil) ("CMAKE_TOOLCHAIN_FILE" "Path to toolchain file supplied to :manual:`cmake(1)`." nil) ("CMAKE_TRY_COMPILE_CONFIGURATION" "Build configuration used for :command:`try_compile` and :command:`try_run`
projects." nil) ("CMAKE_TRY_COMPILE_PLATFORM_VARIABLES" "List of variables that the :command:`try_compile` command source file signature
must propagate into the test project in order to target the same platform as
the host project." "  set(CMAKE_SYSTEM_NAME ...)
  set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES MY_CUSTOM_VARIABLE)
  # ... use MY_CUSTOM_VARIABLE ...") ("CMAKE_TRY_COMPILE_TARGET_TYPE" "Type of target generated for :command:`try_compile` calls using the
source file signature." nil) ("CMAKE_TWEAK_VERSION" "Defined to ``0`` for compatibility with code written for older
CMake versions that may have defined higher values." nil) ("CMAKE_USER_MAKE_RULES_OVERRIDE" "Specify a CMake file that overrides platform information." nil) ("CMAKE_USER_MAKE_RULES_OVERRIDE_LANG" "Specify a CMake file that overrides platform information for ``<LANG>``." nil) ("CMAKE_USE_RELATIVE_PATHS" "This variable has no effect." nil) ("CMAKE_VERBOSE_MAKEFILE" "Enable verbose output from Makefile builds." nil) ("CMAKE_VERSION" "The CMake version string as three non-negative integer components
separated by ``.`` and possibly followed by ``-`` and other information." "  <major>.<minor>.<patch>[-rc<n>]") ("CMAKE_VISIBILITY_INLINES_HIDDEN" "Default value for the :prop_tgt:`VISIBILITY_INLINES_HIDDEN` target
property when a target is created." nil) ("CMAKE_VS_DEVENV_COMMAND" "The generators for :generator:`Visual Studio 9 2008` and above set this
variable to the ``devenv.com`` command installed with the corresponding
Visual Studio version." nil) ("CMAKE_VS_GLOBALS" "List of ``Key=Value`` records to be set per target as target properties
:prop_tgt:`VS_GLOBAL_<variable>` with ``variable=Key`` and value ``Value``." "  set(CMAKE_VS_GLOBALS
    \"DefaultLanguage=en-US\"
    \"MinimumVisualStudioVersion=14.0\"
    )") ("CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD" "Include ``INSTALL`` target to default build." nil) ("CMAKE_VS_INCLUDE_PACKAGE_TO_DEFAULT_BUILD" "Include ``PACKAGE`` target to default build." nil) ("CMAKE_VS_INTEL_Fortran_PROJECT_VERSION" "When generating for :generator:`Visual Studio 9 2008` or greater with the Intel
Fortran plugin installed, this specifies the ``.vfproj`` project file format
version." nil) ("CMAKE_VS_MSBUILD_COMMAND" "The generators for :generator:`Visual Studio 10 2010` and above set this
variable to the ``MSBuild.exe`` command installed with the corresponding
Visual Studio version." nil) ("CMAKE_VS_NsightTegra_VERSION" "When using a Visual Studio generator with the
:variable:`CMAKE_SYSTEM_NAME` variable set to ``Android``,
this variable contains the version number of the
installed NVIDIA Nsight Tegra Visual Studio Edition." nil) ("CMAKE_VS_PLATFORM_NAME" "Visual Studio target platform name." nil) ("CMAKE_VS_PLATFORM_TOOLSET" "Visual Studio Platform Toolset name." nil) ("CMAKE_VS_PLATFORM_TOOLSET_CUDA" "NVIDIA CUDA Toolkit version whose Visual Studio toolset to use." nil) ("CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE" "Visual Studio preferred tool architecture." nil) ("CMAKE_VS_PLATFORM_TOOLSET_VERSION" "Visual Studio Platform Toolset version." nil) ("CMAKE_VS_SDK_EXCLUDE_DIRECTORIES" "This variable allows to override Visual Studio default Exclude Directories." nil) ("CMAKE_VS_SDK_EXECUTABLE_DIRECTORIES" "This variable allows to override Visual Studio default Executable Directories." nil) ("CMAKE_VS_SDK_INCLUDE_DIRECTORIES" "This variable allows to override Visual Studio default Include Directories." nil) ("CMAKE_VS_SDK_LIBRARY_DIRECTORIES" "This variable allows to override Visual Studio default Library Directories." nil) ("CMAKE_VS_SDK_LIBRARY_WINRT_DIRECTORIES" "This variable allows to override Visual Studio default Library WinRT
Directories." nil) ("CMAKE_VS_SDK_REFERENCE_DIRECTORIES" "This variable allows to override Visual Studio default Reference Directories." nil) ("CMAKE_VS_SDK_SOURCE_DIRECTORIES" "This variable allows to override Visual Studio default Source Directories." nil) ("CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION" "Visual Studio Windows Target Platform Version." nil) ("CMAKE_VS_WINRT_BY_DEFAULT" "Tell :ref:`Visual Studio Generators` for VS 2010 and above that the
target platform compiles as WinRT by default (compiles with ``/ZW``)." nil) ("CMAKE_WARN_DEPRECATED" "Whether to issue warnings for deprecated functionality." nil) ("CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION" "Ask ``cmake_install.cmake`` script to warn each time a file with absolute
``INSTALL DESTINATION`` is encountered." nil) ("CMAKE_WIN32_EXECUTABLE" "Default value for :prop_tgt:`WIN32_EXECUTABLE` of targets." nil) ("CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS" "Default value for :prop_tgt:`WINDOWS_EXPORT_ALL_SYMBOLS` target property." nil) ("CMAKE_XCODE_ATTRIBUTE_an-attribute" "Set Xcode target attributes directly." nil) ("CMAKE_XCODE_GENERATE_SCHEME" "If enabled, the Xcode generator will generate schema files. Those are
are useful to invoke analyze, archive, build-for-testing and test
actions from the command line." "  The Xcode Schema Generator is still experimental and subject to
  change.") ("CMAKE_XCODE_GENERATE_TOP_LEVEL_PROJECT_ONLY" "If enabled, the :generator:`Xcode` generator will generate only a
single Xcode project file for the topmost :command:`project()` command
instead of generating one for every ``project()`` command." nil) ("CMAKE_XCODE_PLATFORM_TOOLSET" "Xcode compiler selection." nil) ("CMAKE_XCODE_SCHEME_ADDRESS_SANITIZER" "Whether to enable ``Address Sanitizer`` in the Diagnostics
section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_ADDRESS_SANITIZER_USE_AFTER_RETURN" "Whether to enable ``Detect use of stack after return``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_DISABLE_MAIN_THREAD_CHECKER" "Whether to disable the ``Main Thread Checker``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_DYNAMIC_LIBRARY_LOADS" "Whether to enable ``Dynamic Library Loads``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_DYNAMIC_LINKER_API_USAGE" "Whether to enable ``Dynamic Linker API usage``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_GUARD_MALLOC" "Whether to enable ``Guard Malloc``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_MAIN_THREAD_CHECKER_STOP" "Whether to enable the ``Main Thread Checker`` option
``Pause on issues``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_MALLOC_GUARD_EDGES" "Whether to enable ``Malloc Guard Edges``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_MALLOC_SCRIBBLE" "Whether to enable ``Malloc Scribble``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_MALLOC_STACK" "Whether to enable ``Malloc Stack`` in the Diagnostics
section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_THREAD_SANITIZER" "Whether to enable ``Thread Sanitizer`` in the Diagnostics
section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_THREAD_SANITIZER_STOP" "Whether to enable ``Thread Sanitizer - Pause on issues``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_UNDEFINED_BEHAVIOUR_SANITIZER" "Whether to enable ``Undefined Behavior Sanitizer``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_UNDEFINED_BEHAVIOUR_SANITIZER_STOP" "Whether to enable ``Undefined Behavior Sanitizer`` option
``Pause on issues``
in the Diagnostics section of the generated Xcode scheme." nil) ("CMAKE_XCODE_SCHEME_ZOMBIE_OBJECTS" "Whether to enable ``Zombie Objects``
in the Diagnostics section of the generated Xcode scheme." nil) ("CPACK_ABSOLUTE_DESTINATION_FILES" "List of files which have been installed using an ``ABSOLUTE DESTINATION`` path." nil) ("CPACK_COMPONENT_INCLUDE_TOPLEVEL_DIRECTORY" "Boolean toggle to include/exclude top level directory (component case)." nil) ("CPACK_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION" "Ask CPack to error out as soon as a file with absolute ``INSTALL DESTINATION``
is encountered." nil) ("CPACK_INCLUDE_TOPLEVEL_DIRECTORY" "Boolean toggle to include/exclude top level directory." nil) ("CPACK_INSTALL_DEFAULT_DIRECTORY_PERMISSIONS" "Default permissions for implicitly created directories during packaging." nil) ("CPACK_INSTALL_SCRIPT" "Extra CMake script provided by the user." nil) ("CPACK_PACKAGING_INSTALL_PREFIX" "The prefix used in the built package." "  set(CPACK_PACKAGING_INSTALL_PREFIX \"/opt\")") ("CPACK_SET_DESTDIR" "Boolean toggle to make CPack use ``DESTDIR`` mechanism when packaging." " make DESTDIR=/home/john install") ("CPACK_WARN_ON_ABSOLUTE_INSTALL_DESTINATION" "Ask CPack to warn each time a file with absolute ``INSTALL DESTINATION`` is
encountered." nil) ("CTEST_BINARY_DIRECTORY" "Specify the CTest ``BuildDirectory`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_BUILD_COMMAND" "Specify the CTest ``MakeCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_BUILD_NAME" "Specify the CTest ``BuildName`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_BZR_COMMAND" "Specify the CTest ``BZRCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_BZR_UPDATE_OPTIONS" "Specify the CTest ``BZRUpdateOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_CHANGE_ID" "Specify the CTest ``ChangeId`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_CHECKOUT_COMMAND" "Tell the :command:`ctest_start` command how to checkout or initialize
the source directory in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_CONFIGURATION_TYPE" "Specify the CTest ``DefaultCTestConfigurationType`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_CONFIGURE_COMMAND" "Specify the CTest ``ConfigureCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_COVERAGE_COMMAND" "Specify the CTest ``CoverageCommand`` setting
in a :manual:`ctest(1)` dashboard client script." "  set(CTEST_COVERAGE_COMMAND .../run-coverage-and-consolidate.sh)") ("CTEST_COVERAGE_EXTRA_FLAGS" "Specify the CTest ``CoverageExtraFlags`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_CURL_OPTIONS" "Specify the CTest ``CurlOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_CUSTOM_COVERAGE_EXCLUDE" "A list of regular expressions which will be used to exclude files by their
path from coverage output by the :command:`ctest_coverage` command." nil) ("CTEST_CUSTOM_ERROR_EXCEPTION" "A list of regular expressions which will be used to exclude when detecting
error messages in build outputs by the :command:`ctest_test` command." nil) ("CTEST_CUSTOM_ERROR_MATCH" "A list of regular expressions which will be used to detect error messages in
build outputs by the :command:`ctest_test` command." nil) ("CTEST_CUSTOM_ERROR_POST_CONTEXT" "The number of lines to include as context which follow an error message by the
:command:`ctest_test` command. The default is 10." nil) ("CTEST_CUSTOM_ERROR_PRE_CONTEXT" "The number of lines to include as context which precede an error message by
the :command:`ctest_test` command. The default is 10." nil) ("CTEST_CUSTOM_MAXIMUM_FAILED_TEST_OUTPUT_SIZE" "When saving a failing test's output, this is the maximum size, in bytes, that
will be collected by the :command:`ctest_test` command. Defaults to 307200
(300 KiB)." nil) ("CTEST_CUSTOM_MAXIMUM_NUMBER_OF_ERRORS" "The maximum number of errors in a single build step which will be detected." nil) ("CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS" "The maximum number of warnings in a single build step which will be detected." nil) ("CTEST_CUSTOM_MAXIMUM_PASSED_TEST_OUTPUT_SIZE" "When saving a passing test's output, this is the maximum size, in bytes, that
will be collected by the :command:`ctest_test` command. Defaults to 1024
(1 KiB)." nil) ("CTEST_CUSTOM_MEMCHECK_IGNORE" "A list of regular expressions to use to exclude tests during the
:command:`ctest_memcheck` command." nil) ("CTEST_CUSTOM_POST_MEMCHECK" "A list of commands to run at the end of the :command:`ctest_memcheck` command." nil) ("CTEST_CUSTOM_POST_TEST" "A list of commands to run at the end of the :command:`ctest_test` command." nil) ("CTEST_CUSTOM_PRE_MEMCHECK" "A list of commands to run at the start of the :command:`ctest_memcheck`
command." nil) ("CTEST_CUSTOM_PRE_TEST" "A list of commands to run at the start of the :command:`ctest_test` command." nil) ("CTEST_CUSTOM_TESTS_IGNORE" "A list of regular expressions to use to exclude tests during the
:command:`ctest_test` command." nil) ("CTEST_CUSTOM_WARNING_EXCEPTION" "A list of regular expressions which will be used to exclude when detecting
warning messages in build outputs by the :command:`ctest_test` command." nil) ("CTEST_CUSTOM_WARNING_MATCH" "A list of regular expressions which will be used to detect warning messages in
build outputs by the :command:`ctest_test` command." nil) ("CTEST_CVS_CHECKOUT" "Deprecated." nil) ("CTEST_CVS_COMMAND" "Specify the CTest ``CVSCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_CVS_UPDATE_OPTIONS" "Specify the CTest ``CVSUpdateOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_DROP_LOCATION" "Specify the CTest ``DropLocation`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_DROP_METHOD" "Specify the CTest ``DropMethod`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_DROP_SITE" "Specify the CTest ``DropSite`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_DROP_SITE_CDASH" "Specify the CTest ``IsCDash`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_DROP_SITE_PASSWORD" "Specify the CTest ``DropSitePassword`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_DROP_SITE_USER" "Specify the CTest ``DropSiteUser`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_EXTRA_COVERAGE_GLOB" "A list of regular expressions which will be used to find files which should be
covered by the :command:`ctest_coverage` command." nil) ("CTEST_GIT_COMMAND" "Specify the CTest ``GITCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_GIT_INIT_SUBMODULES" "Specify the CTest ``GITInitSubmodules`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_GIT_UPDATE_CUSTOM" "Specify the CTest ``GITUpdateCustom`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_GIT_UPDATE_OPTIONS" "Specify the CTest ``GITUpdateOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_HG_COMMAND" "Specify the CTest ``HGCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_HG_UPDATE_OPTIONS" "Specify the CTest ``HGUpdateOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_LABELS_FOR_SUBPROJECTS" "Specify the CTest ``LabelsForSubprojects`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_MEMORYCHECK_COMMAND" "Specify the CTest ``MemoryCheckCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_MEMORYCHECK_COMMAND_OPTIONS" "Specify the CTest ``MemoryCheckCommandOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_MEMORYCHECK_SANITIZER_OPTIONS" "Specify the CTest ``MemoryCheckSanitizerOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_MEMORYCHECK_SUPPRESSIONS_FILE" "Specify the CTest ``MemoryCheckSuppressionFile`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_MEMORYCHECK_TYPE" "Specify the CTest ``MemoryCheckType`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_NIGHTLY_START_TIME" "Specify the CTest ``NightlyStartTime`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_P4_CLIENT" "Specify the CTest ``P4Client`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_P4_COMMAND" "Specify the CTest ``P4Command`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_P4_OPTIONS" "Specify the CTest ``P4Options`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_P4_UPDATE_OPTIONS" "Specify the CTest ``P4UpdateOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_RUN_CURRENT_SCRIPT" "Setting this to 0 prevents :manual:`ctest(1)` from being run again when it
reaches the end of a script run by calling ``ctest -S``." nil) ("CTEST_SCP_COMMAND" "Legacy option." nil) ("CTEST_SITE" "Specify the CTest ``Site`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_SOURCE_DIRECTORY" "Specify the CTest ``SourceDirectory`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_SUBMIT_URL" "Specify the CTest ``SubmitURL`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_SVN_COMMAND" "Specify the CTest ``SVNCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_SVN_OPTIONS" "Specify the CTest ``SVNOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_SVN_UPDATE_OPTIONS" "Specify the CTest ``SVNUpdateOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_TEST_LOAD" "Specify the ``TestLoad`` setting in the :ref:`CTest Test Step`
of a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_TEST_TIMEOUT" "Specify the CTest ``TimeOut`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_TRIGGER_SITE" "Legacy option." nil) ("CTEST_UPDATE_COMMAND" "Specify the CTest ``UpdateCommand`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_UPDATE_OPTIONS" "Specify the CTest ``UpdateOptions`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_UPDATE_VERSION_ONLY" "Specify the CTest ``UpdateVersionOnly`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CTEST_USE_LAUNCHERS" "Specify the CTest ``UseLaunchers`` setting
in a :manual:`ctest(1)` dashboard client script." nil) ("CYGWIN" "``True`` for Cygwin." nil) ("ENV" "Operator to read environment variables." nil) ("EXECUTABLE_OUTPUT_PATH" "Old executable location variable." nil) ("GHS-MULTI" "``True`` when using :generator:`Green Hills MULTI` generator." nil) ("LIBRARY_OUTPUT_PATH" "Old library location variable." nil) ("MINGW" "``True`` when using MinGW" nil) ("MSVC" "Set to ``true`` when the compiler is some version of Microsoft Visual
C++ or another compiler simulating Visual C++." nil) ("MSVC10" "Discouraged." nil) ("MSVC11" "Discouraged." nil) ("MSVC12" "Discouraged." nil) ("MSVC14" "Discouraged." nil) ("MSVC60" "Discouraged." nil) ("MSVC70" "Discouraged." nil) ("MSVC71" "Discouraged." nil) ("MSVC80" "Discouraged." nil) ("MSVC90" "Discouraged." nil) ("MSVC_IDE" "``True`` when using the Microsoft Visual C++ IDE." nil) ("MSVC_TOOLSET_VERSION" "The toolset version of Microsoft Visual C/C++ being used if any." "  80        = VS 2005 (8.0)
  90        = VS 2008 (9.0)
  100       = VS 2010 (10.0)
  110       = VS 2012 (11.0)
  120       = VS 2013 (12.0)
  140       = VS 2015 (14.0)
  141       = VS 2017 (15.0)") ("MSVC_VERSION" "The version of Microsoft Visual C/C++ being used if any." "  1200      = VS  6.0
  1300      = VS  7.0
  1310      = VS  7.1
  1400      = VS  8.0 (v80 toolset)
  1500      = VS  9.0 (v90 toolset)
  1600      = VS 10.0 (v100 toolset)
  1700      = VS 11.0 (v110 toolset)
  1800      = VS 12.0 (v120 toolset)
  1900      = VS 14.0 (v140 toolset)
  1910-1919 = VS 15.0 (v141 toolset)
  1920-1929 = VS 16.0 (v142 toolset)") ("MSYS" "``True`` when using the :generator:`MSYS Makefiles` generator." nil) ("PROJECT-NAME_BINARY_DIR" "Top level binary directory for the named project." nil) ("PROJECT-NAME_DESCRIPTION" "Value given to the ``DESCRIPTION`` option of the most recent call to the
:command:`project` command with project name ``<PROJECT-NAME>``, if any." nil) ("PROJECT-NAME_HOMEPAGE_URL" "Value given to the ``HOMEPAGE_URL`` option of the most recent call to the
:command:`project` command with project name ``<PROJECT-NAME>``, if any." nil) ("PROJECT-NAME_SOURCE_DIR" "Top level source directory for the named project." nil) ("PROJECT-NAME_VERSION" "Value given to the ``VERSION`` option of the most recent call to the
:command:`project` command with project name ``<PROJECT-NAME>``, if any." nil) ("PROJECT-NAME_VERSION_MAJOR" "First version number component of the :variable:`<PROJECT-NAME>_VERSION`
variable as set by the :command:`project` command." nil) ("PROJECT-NAME_VERSION_MINOR" "Second version number component of the :variable:`<PROJECT-NAME>_VERSION`
variable as set by the :command:`project` command." nil) ("PROJECT-NAME_VERSION_PATCH" "Third version number component of the :variable:`<PROJECT-NAME>_VERSION`
variable as set by the :command:`project` command." nil) ("PROJECT-NAME_VERSION_TWEAK" "Fourth version number component of the :variable:`<PROJECT-NAME>_VERSION`
variable as set by the :command:`project` command." nil) ("PROJECT_BINARY_DIR" "Full path to build directory for project." nil) ("PROJECT_DESCRIPTION" "Short project description given to the project command." nil) ("PROJECT_HOMEPAGE_URL" "The homepage URL of the project." nil) ("PROJECT_NAME" "Name of the project given to the project command." nil) ("PROJECT_SOURCE_DIR" "Top level source directory for the current project." nil) ("PROJECT_VERSION" "Value given to the ``VERSION`` option of the most recent call to the
:command:`project` command, if any." nil) ("PROJECT_VERSION_MAJOR" "First version number component of the :variable:`PROJECT_VERSION`
variable as set by the :command:`project` command." nil) ("PROJECT_VERSION_MINOR" "Second version number component of the :variable:`PROJECT_VERSION`
variable as set by the :command:`project` command." nil) ("PROJECT_VERSION_PATCH" "Third version number component of the :variable:`PROJECT_VERSION`
variable as set by the :command:`project` command." nil) ("PROJECT_VERSION_TWEAK" "Fourth version number component of the :variable:`PROJECT_VERSION`
variable as set by the :command:`project` command." nil) ("PackageName_ROOT" "Calls to :command:`find_package(<PackageName>)` will search in prefixes
specified by the ``<PackageName>_ROOT`` CMake variable, where
``<PackageName>`` is the name given to the ``find_package`` call
and ``_ROOT`` is literal." nil) ("UNIX" "Set to ``True`` when the target system is UNIX or UNIX-like
(e.g. :variable:`APPLE` and :variable:`CYGWIN`)." nil) ("WIN32" "Set to ``True`` when the target system is Windows, including Win64." nil) ("WINCE" "True when the :variable:`CMAKE_SYSTEM_NAME` variable is set
to ``WindowsCE``." nil) ("WINDOWS_PHONE" "True when the :variable:`CMAKE_SYSTEM_NAME` variable is set
to ``WindowsPhone``." nil) ("WINDOWS_STORE" "True when the :variable:`CMAKE_SYSTEM_NAME` variable is set
to ``WindowsStore``." nil) ("XCODE" "``True`` when using :generator:`Xcode` generator." nil) ("XCODE_VERSION" "Version of Xcode (:generator:`Xcode` generator only)." nil)

  ))

(provide 'eldoc-cmake)
;;; eldoc-cmake.el ends here
