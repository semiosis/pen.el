;;; cmake-font-lock.el --- Advanced, type aware, highlight support for CMake

;; Copyright (C) 2012-2021 Anders Lindgren

;; Author: Anders Lindgren
;; Keywords: faces, languages
;; Created: 2012-12-05
;; Package-Version: 20230304.2223
;; Package-Revision: a6038e916bcc
;; Package-Requires: ((cmake-mode "0.0"))
;; URL: https://github.com/Lindydancer/cmake-font-lock

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Advanced syntax coloring support for CMake scripts.
;;
;; The major feature of this package is to highlighting function
;; arguments according to their use. For example:
;;
;; ![Example CMake script](doc/demo.png)
;;
;; CMake, as a programming language, has a very simple syntax.
;; Unfortunately, this makes it hard to read CMake scripts. CMake
;; supports function calls, but they may not be nested. In addition,
;; the functions do not support return values like normal programming
;; languages, instead a function is capable of setting variables in
;; the scope of the parent. In other words, a parameter could be
;; anything like the name of a variable, a keyword, a property, or
;; even a plain string.
;;
;; By highlighting each argument, CMake scripts becomes much easier to
;; read, and also to write.
;;
;; This package is aware of all built-in CMake functions, as provided
;; by CMake 3.26.1.  In addition, it allows you to add function
;; signatures for your own functions.

;; The following is colored:
;;
;; * Function arguments are colored according to it's use, An argument
;;   can be colored as a *keyword*, a *variable*, a *property*, or a
;;   *target*. This package provides information on all built-in CMake
;;   functions. Information on user-defined functions can be added.
;;
;; * All function names are colored, however, special functions like
;;   `if', `while', `function', and `include' are colored using a
;;   different color.
;;
;; * The constants `true', `false', `yes', `no', `y', `n', `on', and
;;   `off'.
;;
;; * The constructs `${...}', `$ENV{...}', and `$<name:...>'.
;;
;; * In preprocessor definitions like `-DNAME', `NAME' is colored.
;;
;; * Comments and quoted strings.
;;

;; Background:
;;
;; This package is designed to be used together with a major mode for
;; editing CMake files. Once such package is `cmake-mode.el'
;; distributed by Kitware.  However this package is not dependent upon
;; or associated with any specific CMake major mode.  (Note that the
;; Kitware package contains rudimentary syntax coloring support, this
;; package replaces that part of the major mode.)

;; Installation:
;;
;; Install this package with Emacs' package manager.
;;
;; When installed, this package is automatically activated when using
;; CMake mode, or any other mode in the list `cmake-font-lock-modes'.
;; Set this variable to nil to disable automatic initialization.

;; Customizing:
;;
;; In order to perform syntax coloring correctly, this package has to
;; be aware of the keywords and types of the CMake functions used. To
;; add information about non-standard CMake function, the following
;; functions can be used:
;;
;; `cmake-font-lock-add-keywords' -- Add keyword information:
;;
;; Adding the list of keywords to a function is a simple way to get
;; basic coloring correct. For most functions, this is sufficient.
;; For example:
;;
;;     (cmake-font-lock-add-keywords
;;        "my-func" '("FILE" "RESULT" "OTHER"))
;;
;; `cmake-font-lock-set-signature' -- Set full function type:
;;
;; Set the signature (the type of the arguments) for a function. For
;; example:
;;
;;     (cmake-font-lock-set-signature
;;        "my-func" '(:var nil :prop) '(("FILE" :file) ("RESULT" :var)))
;;
;; Custom types:
;;
;; The signatures of CMake functions provided by this package use a
;; number of types (see `cmake-font-lock-function-signatures'
;; for details). However, when adding new signatures, it's possible to
;; use additional types. In that case, the variable
;; `cmake-font-lock-argument-kind-face-alist' must be modified
;; to map the CMake type to a concrete Emacs face. For example:
;;
;; (cmake-font-lock-set-signature "my_warn" (:warning))
;; (add-to-list '(:warning . font-lock-warning-face)
;;              cmake-font-lock-argument-kind-face-alist)
;;

;; Problems:
;;
;; * In CMake, function taking expressions, like `if' and `while',
;;   treat any string as the name of a variable, if one exists. This
;;   mode fontifies all such as variables, whether or not they
;;   actually refer to variable. You can quote the arguments to
;;   fontify them as strings (even though that will not prevent CMake
;;   from interpreting them as variables).
;;
;; * Normally, keywords are written explicitly when calling a
;;   function. However, it is legal to assigning them to a variable,
;;   which is expanded at the time the function is called. In this
;;   case, remaining arguments will not be colored correctly. For
;;   example:
;;
;;         set(def DEFINITION var2)
;;         get_directory_property(var1 ${def} my_property)

;;; Code:

;; Naming:
;;
;; The package `cmake-mode' use the prefix `cmake-', this package use
;; the prefix `cmake-font-lock'. The only indentifier where this could
;; have been a problem is the constant `cmake-font-lock-keywords',
;; provided by `cmake-mode'. To avoid a collision, this package
;; provide `cmake-font-lock-advanced-keywords' instead.

;; Ideas for the future:
;;
;; - rename "cmake-font-lock-xxx" to "cmfl-xxx"?
;;
;; - Join keywords and signature datastructures? (Hard work for the
;;   generator.)
;;
;; - Grey-out the arguments to the "endxxx()" functions?
;;
;; - Highlight misplaced arguments using warning face?
;;
;; - Better logger.
;;
;; - Use consistent naming (keyword).
;;
;; - Allow `cmake-font-lock-function-signatures' to contain a
;;   function to call for the cases where a signature isn't powerful
;;   enough to describe a function.



(defvar cmake-font-lock-function-keywords-alist
  '(("add_custom_command"          . ("APPEND"
                                      "ARGS"
                                      "BYPRODUCTS"
                                      "COMMAND"
                                      "COMMAND_EXPAND_LISTS"
                                      "COMMENT"
                                      "DEPENDS"
                                      "DEPFILE"
                                      "IMPLICIT_DEPENDS"
                                      "JOB_POOL"
                                      "MAIN_DEPENDENCY"
                                      "OUTPUT"
                                      "POST_BUILD"
                                      "PRE_BUILD"
                                      "PRE_LINK"
                                      "TARGET"
                                      "USES_TERMINAL"
                                      "VERBATIM"
                                      "WORKING_DIRECTORY"))
    ("add_custom_target"           . ("ALL"
                                      "BYPRODUCTS"
                                      "COMMAND"
                                      "COMMAND_EXPAND_LISTS"
                                      "COMMENT"
                                      "DEPENDS"
                                      "JOB_POOL"
                                      "SOURCES"
                                      "USES_TERMINAL"
                                      "VERBATIM"
                                      "WORKING_DIRECTORY"))
    ("add_executable"              . ("ALIAS"
                                      "EXCLUDE_FROM_ALL"
                                      "GLOBAL"
                                      "IMPORTED"
                                      "MACOSX_BUNDLE"
                                      "WIN32"))
    ("add_library"                 . ("ALIAS"
                                      "EXCLUDE_FROM_ALL"
                                      "GLOBAL"
                                      "IMPORTED"
                                      "INTERFACE"
                                      "MODULE"
                                      "OBJECT"
                                      "SHARED"
                                      "STATIC"
                                      "UNKNOWN"))
    ("add_subdirectory"            . ("EXCLUDE_FROM_ALL"
                                      "SYSTEM"))
    ("add_test"                    . ("COMMAND"
                                      "COMMAND_EXPAND_LISTS"
                                      "CONFIGURATIONS"
                                      "NAME"
                                      "WORKING_DIRECTORY"))
    ("block"                       . ("POLICIES"
                                      "SCOPE_FOR"
                                      "VARIABLES"))
    ("build_command"               . ("CONFIGURATION"
                                      "PARALLEL_LEVEL"
                                      "PROJECT_NAME"
                                      "TARGET"))
    ("cmake_host_system_information" . ("ERROR_VARIABLE"
                                        "QUERY"
                                        "RESULT"
                                        "SEPARATOR"
                                        "SUBKEYS"
                                        "VALUE"
                                        "VALUE_NAMES"
                                        "VIEW"
                                        "WINDOWS_REGISTRY"
                                        ;; Suboptions to VIEW
                                        "32"
                                        "64"
                                        "64_32"
                                        "32_64"
                                        "BOTH"
                                        "HOST"
                                        "TARGET"))
    ("cmake_language"               . ("CANCEL_CALL"
                                       "CODE"
                                       "DEFER"
                                       "DIRECTORY"
                                       "EVAL"
                                       "FETCHCONTENT_MAKEAVAILABE_SERIAL"
                                       "FIND_PACKAGE"
                                       "GET_CALL"
                                       "GET_CALL_IDS"
                                       "ID"
                                       "ID_VAR"
                                       "SUPPORTED_METHODS"))
    ("cmake_minimum_required"      . ("FATAL_ERROR"
                                      "VERSION"))
    ("cmake_parse_arguments"       . ("PARSE_ARGV"))
    ("cmake_path"                  . ("ABSOLUTE_PATH"
                                      "APPEND"
                                      "APPEND_STRING"
                                      "BASE_DIRECTORY"
                                      "COMPARE"
                                      "CONVERT"
                                      "EQUAL"
                                      "EXTENSION"
                                      "FILENAME"
                                      "GET"
                                      "HAS_EXTENSION"
                                      "HAS_FILENAME"
                                      "HAS_PARENT_PATH"
                                      "HAS_STEM"
                                      "HAS_RELATIVE_PART"
                                      "HAS_ROOT_DIRECTORY"
                                      "HAS_ROOT_NAME"
                                      "HAS_ROOT_PATH"
                                      "HASH"
                                      "IS_ABSOLUTE"
                                      "IS_PREFIX"
                                      "IS_RELATIVE"
                                      "LAST_ONLY"
                                      "NATIVE_PATH"
                                      "NORMAL_PATH"
                                      "NORMALIZE"
                                      "NOT_RQUAL"
                                      "OUTPUT_VARIABLE"
                                      "PARENT_PATH"
                                      "RELATIVE_PART"
                                      "RELATIVE_PATH"
                                      "REMOVE_EXTENSION"
                                      "REMOVE_FILENAME"
                                      "REPLACE_EXTENSION"
                                      "REPLACE_FILENAME"
                                      "ROOT_DIRECTORY"
                                      "ROOT_NAME"
                                      "ROOT_PATH"
                                      "SET"
                                      "STEM"
                                      "TO_CMAKE_PATH_LIST"
                                      "TO_NATIVE_PATH_LIST"))
    ("cmake_policy"                . ("GET"
                                      "NEW"
                                      "OLD"
                                      "POP"
                                      "PUSH"
                                      "SET"
                                      "VERSION"))
    ("configure_file"              . ("@ONLY"
                                      "COPYONLY"
                                      "CRLF"
                                      "DOS"
                                      "ESCAPE_QUOTES"
                                      "FILE_PERMISSIONS"
                                      "GROUP_EXECUTE"
                                      "GROUP_READ"
                                      "GROUP_WRITE"
                                      "LF"
                                      "NEWLINE_STYLE"
                                      "NO_SOURCE_PERMISSIONS"
                                      "OWNER_EXECUTE"
                                      "OWNER_READ"
                                      "OWNER_WRITE"
                                      "UNIX"
                                      "USE_SOURCE_PERMISSIONS"
                                      "WIN32"
                                      "WORLD_EXECUTE"
                                      "WORLD_READ"
                                      "WORLD_WRITE"))
    ("create_test_sourcelist"      . ("EXTRA_INCLUDE"
                                      "FUNCTION"))
    ("define_property"             . ("BRIEF_DOCS"
                                      "CACHED_VARIABLE"
                                      "DIRECTORY"
                                      "FULL_DOCS"
                                      "GLOBAL"
                                      "INHERITED"
                                      "PROPERTY"
                                      "SOURCE"
                                      "TARGET"
                                      "TEST"
                                      "VARIABLE"))
    ("enable_language"             . ("OPTIONAL"))
    ("exec_program"                . ("ARGS"
                                      "OUTPUT_VARIABLE"
                                      "RETURN_VALUE"))
    ("execute_process"             . ("ANSI"
                                      "ANY"
                                      "AUTO"
                                      "COMMAND"
                                      "COMMAND_ECHO"
                                      "COMMAND_ERROR_IS_FATAL"
                                      "ECHO_ERROR_VARIABLE"
                                      "ECHO_OUTPUT_VARIABLE"
                                      "ENCODING"
                                      "ERROR_FILE"
                                      "ERROR_QUIET"
                                      "ERROR_STRIP_TRAILING_WHITESPACE"
                                      "ERROR_VARIABLE"
                                      "INPUT_FILE"
                                      "LAST"
                                      "NONE"
                                      "OEM"
                                      "OUTPUT_FILE"
                                      "OUTPUT_QUIET"
                                      "OUTPUT_STRIP_TRAILING_WHITESPACE"
                                      "OUTPUT_VARIABLE"
                                      "RESULT_VARIABLE"
                                      "RESULTS_VARIABLE"
                                      "STDERR"
                                      "STDOUT"
                                      "TIMEOUT"
                                      "UTF8"
                                      "UTF-8"
                                      "WORKING_DIRECTORY"))
    ("export"                      . ("ANDROID_MK"
                                      "APPEND"
                                      "EXPORT"
                                      "EXPORT_LINK_INTERFACE_LIBRARIES"
                                      "FILE"
                                      "NAMESPACE"
                                      "PACKAGE"
                                      "TARGETS"))
    ("export_library_dependencies" . ("APPEND"))
    ("file"                        . ("@ONLY"
                                      "APPEND"
                                      "ARCHIVE_CREATE"
                                      "ARCHIVE_EXTRACT"
                                      "BASE_DIRECTORY"
                                      "BUNDLE_EXECUTABLE"
                                      "CHMOD"
                                      "CHMOD_RECURSE"
                                      "CONDITION"
                                      "COMPRESSION"
                                      "COMPRESSION_LEVEL"
                                      "CONFLICTING_DEPENDENCIES_PREFIX"
                                      "CONFIGURE"
                                      "CONFIGURE_DEPENDS"
                                      "CONTENT"
                                      "COPY"
                                      "COPY_ON_ERROR"
                                      "CREATE_LINK"
                                      "CRLF"
                                      "DESTINATION"
                                      "DIRECTORIES"
                                      "DIRECTORY"
                                      "DIRECTORY_PERMISSIONS"
                                      "DOS"
                                      "DOWNLOAD"
                                      "ENCODING"
                                      "ESCAPE_QUOTES"
                                      "EXCLUDE"
                                      "EXECUTABLES"
                                      "EXPAND_TILDE"
                                      "EXPECTED_HASH"
                                      "EXPECTED_MD5"
                                      "FILE"
                                      "FILES"
                                      "FILES_MATCHING"
                                      "FILE_PERMISSIONS"
                                      "FOLLOW_SYMLINKS"
                                      "FOLLOW_SYMLINK_CHAIN"
                                      "FORMAT"
                                      "FUNCTION"
                                      "GENERATE"
                                      "GET_RUNTIME_DEPENDENCIES"
                                      "GLOB"
                                      "GLOB_RECURSE"
                                      "GROUP_EXECUTE"
                                      "GROUP_READ"
                                      "GROUP_WRITE"
                                      "GUARD"
                                      "HEX"
                                      "HTTPHEADER"
                                      "INACTIVITY_TIMEOUT"
                                      "IGNORED"
                                      "INSTALL"
                                      "INPUT"
                                      "INPUT_MAY_BE_RECENT"
                                      "LENGTH_MAXIMUM"
                                      "LENGTH_MINIMUM"
                                      "LF"
                                      "LIBRARIES"
                                      "LIMIT"
                                      "LIMIT_COUNT"
                                      "LIMIT_INPUT"
                                      "LIMIT_OUTPUT"
                                      "LIST_DIRECTORIES"
                                      "LIST_ONLY"
                                      "LOCK"
                                      "LOG"
                                      "MD5"
                                      "MODULES"
                                      "MTIME"
                                      "NETRC"
                                      "NETRC_FILE"
                                      "NEWLINE_CONSUME"
                                      "NEWLINE_STYLE"
                                      "NO_HEX_CONVERSION"
                                      "NO_REPLACE"
                                      "NO_SOURCE_PERMISSIONS"
                                      "OFFSET"
                                      "ONLY_IF_DIFFERENT"
                                      "OPTIONAL"
                                      "OUTPUT"
                                      "OWNER_EXECUTE"
                                      "OWNER_READ"
                                      "OWNER_WRITE"
                                      "PATHS"
                                      "PATTERN"
                                      "PATTERNS"
                                      "PERMISSIONS"
                                      "POST_EXCLUDE_REGEXES"
                                      "POST_INCLUDE_REGEXES"
                                      "PRE_EXCLUDE_REGEXES"
                                      "PRE_INCLUDE_REGEXES"
                                      "PROCESS"
                                      "READ"
                                      "READ_SYMLINK"
                                      "REAL_PATH"
                                      "REGEX"
                                      "RELATIVE"
                                      "RELATIVE_PATH"
                                      "RELEASE"
                                      "REMOVE"
                                      "REMOVE_RECURSE"
                                      "RENAME"
                                      "REQUIRED"
                                      "RESOLVED_DEPENDENCIES_VAR"
                                      "RESULT"
                                      "RESULT_VARIABLE"
                                      "SHA1"
                                      "SHA224"
                                      "SHA256"
                                      "SHA384"
                                      "SHA512"
                                      "SHOW_PROGRESS"
                                      "SIZE"
                                      "SETUID"
                                      "SETGID"
                                      "STATUS"
                                      "STRINGS"
                                      "SYMBOLIC"
                                      "TARGET"
                                      "TIMEOUT"
                                      "TIMESTAMP"
                                      "TLS_VERIFY"
                                      "TLS_CAINFO"
                                      "TO_CMAKE_PATH"
                                      "TO_NATIVE_PATH"
                                      "TOUCH"
                                      "TOUCH_NOCREATE"
                                      "TYPE"
                                      "UNIX"
                                      "UNRESOLVED_DEPENDENCIES_VAR"
                                      "UPLOAD"
                                      "USE_SOURCE_PERMISSIONS"
                                      "USERPWD"
                                      "UTC"
                                      "VERBOSE"
                                      "WIN32"
                                      "WORLD_EXECUTE"
                                      "WORLD_READ"
                                      "WORLD_WRITE"
                                      "WRITE"
                                      ;; Additional options to DOWNLOAD
                                      "EXPECTED_HASH"
                                      "EXPECTED_MD5"
                                      "RANGE_START"
                                      "RANGE_END"))
    ("find_file"                   . ("CMAKE_FIND_ROOT_PATH_BOTH"
                                      "DOC"
                                      "ENV"
                                      "NAMES"
                                      "NO_CACHE"
                                      "NO_CMAKE_ENVIRONMENT_PATH"
                                      "NO_CMAKE_FIND_ROOT_PATH"
                                      "NO_CMAKE_INSTALL_PREFIX"
                                      "NO_CMAKE_PATH"
                                      "NO_CMAKE_SYSTEM_PATH"
                                      "NO_DEFAULT_PATH"
                                      "NO_PACKAGE_ROOT_PATH"
                                      "NO_SYSTEM_ENVIRONMENT_PATH"
                                      "ONLY_CMAKE_FIND_ROOT_PATH"
                                      "PATH_SUFFIXES"
                                      "REGISTRY_VIEW"
                                      "REQUIRED"
                                      ;; Additional options to REGISTRY_VIEW
                                      "64"
                                      "32"
                                      "64_32"
                                      "32_64"
                                      "HOST"
                                      "TARGET"
                                      "BOTH"))
    ("find_library"                . ("CMAKE_FIND_ROOT_PATH_BOTH"
                                      "DOC"
                                      "ENV"
                                      "HINTS"
                                      "NAMES"
                                      "NAMES_PER_DIR"
                                      "NO_CMAKE_ENVIRONMENT_PATH"
                                      "NO_CMAKE_FIND_ROOT_PATH"
                                      "NO_CMAKE_INSTALL_PREFIX"
                                      "NO_CMAKE_PATH"
                                      "NO_CMAKE_SYSTEM_PATH"
                                      "NO_DEFAULT_PATH"
                                      "NO_PACKAGE_ROOT_PATH"
                                      "NO_SYSTEM_ENVIRONMENT_PATH"
                                      "ONLY_CMAKE_FIND_ROOT_PATH"
                                      "PATHS"
                                      "PATH_SUFFIXES"
                                      "REGISTRY_VIEW"
                                      "REQUIRED"
                                      "VALIDATOR"
                                      ;; Additional options to REGISTRY_VIEW
                                      "64"
                                      "32"
                                      "64_32"
                                      "32_64"
                                      "HOST"
                                      "TARGET"
                                      "BOTH"))
    ("find_package"                . ("BYPASS_PROVIDER"
                                      "CMAKE_FIND_ROOT_PATH_BOTH"
                                      "COMPONENTS"
                                      "CONFIG"
                                      "CONFIGS"
                                      "EXACT"
                                      "GLOBAL"
                                      "HINTS"
                                      "MODULE"
                                      "NAMES"
                                      "NO_CMAKE_BUILDS_PATH"
                                      "NO_CMAKE_ENVIRONMENT_PATH"
                                      "NO_CMAKE_FIND_ROOT_PATH"
                                      "NO_CMAKE_PACKAGE_REGISTRY"
                                      "NO_CMAKE_PATH"
                                      "NO_CMAKE_SYSTEM_PACKAGE_REGISTRY"
                                      "NO_CMAKE_SYSTEM_PATH"
                                      "NO_DEFAULT_PATH"
                                      "NO_MODULE"
                                      "NO_PACKAGE_ROOT_PATH"
                                      "NO_POLICY_SCOPE"
                                      "NO_SYSTEM_ENVIRONMENT_PATH"
                                      "ONLY_CMAKE_FIND_ROOT_PATH"
                                      "OPTIONAL_COMPONENTS"
                                      "PATHS"
                                      "PATH_SUFFIXES"
                                      "QUIET"
                                      "REQUIRED"
                                      "REGISTRY_VIEW"
                                      ;; Additional options to REGISTRY_VIEW
                                      "64"
                                      "32"
                                      "64_32"
                                      "32_64"
                                      "HOST"
                                      "TARGET"
                                      "BOTH"))
    ("find_path"                   . ("CMAKE_FIND_ROOT_PATH_BOTH"
                                      "DOC"
                                      "ENV"
                                      "HINTS"
                                      "NAMES"
                                      "NO_CACHE"
                                      "NO_CMAKE_ENVIRONMENT_PATH"
                                      "NO_CMAKE_FIND_ROOT_PATH"
                                      "NO_CMAKE_INSTALL_PREFIX"
                                      "NO_CMAKE_PATH"
                                      "NO_CMAKE_SYSTEM_PATH"
                                      "NO_DEFAULT_PATH"
                                      "NO_PACKAGE_ROOT_PATH"
                                      "NO_SYSTEM_ENVIRONMENT_PATH"
                                      "ONLY_CMAKE_FIND_ROOT_PATH"
                                      "PATHS"
                                      "PATH_SUFFIXES"
                                      "REQUIRED"
                                      "REGISTRY_VIEW"
                                      "VALIDATOR"
                                      ;; Additional options to REGISTRY_VIEW
                                      "64"
                                      "32"
                                      "64_32"
                                      "32_64"
                                      "HOST"
                                      "TARGET"
                                      "BOTH"))
    ("find_program"                . ("CMAKE_FIND_ROOT_PATH_BOTH"
                                      "DOC"
                                      "ENV"
                                      "HINTS"
                                      "NAMES"
                                      "NAMES_PER_DIR"
                                      "NO_CACHE"
                                      "NO_CMAKE_ENVIRONMENT_PATH"
                                      "NO_CMAKE_FIND_ROOT_PATH"
                                      "NO_CMAKE_INSTALL_PREFIX"
                                      "NO_CMAKE_PATH"
                                      "NO_CMAKE_SYSTEM_PATH"
                                      "NO_DEFAULT_PATH"
                                      "NO_PACKAGE_ROOT_PATH"
                                      "NO_SYSTEM_ENVIRONMENT_PATH"
                                      "ONLY_CMAKE_FIND_ROOT_PATH"
                                      "PATHS"
                                      "PATH_SUFFIXES"
                                      "REGISTRY_VIEW"
                                      "REQUIRED"
                                      "VALIDATOR"
                                      ;; Additional options to REGISTRY_VIEW
                                      "64"
                                      "32"
                                      "64_32"
                                      "32_64"
                                      "HOST"
                                      "TARGET"
                                      "BOTH"))
    ("foreach"                     . ("IN"
                                      "ITEMS"
                                      "LISTS"
                                      "RANGE"
                                      "ZIP_LISTS"))
    ("get_directory_property"      . ("DEFINITION"
                                      "DIRECTORY"))
    ("get_filename_component"      . ("ABSOLUTE"
                                      "BASE_DIR"
                                      "CACHE"
                                      "DIRECTORY"
                                      "EXT"
                                      "LAST_EXT"
                                      "NAME"
                                      "NAME_WE"
                                      "NAME_WLE"
                                      "PATH"
                                      "PROGRAM"
                                      "PROGRAM_ARGS"
                                      "REALPATH"))
    ("get_property"                . ("BRIEF_DOCS"
                                      "CACHE"
                                      "DEFINED"
                                      "DIRECTORY"
                                      "FULL_DOCS"
                                      "GLOBAL"
                                      "INSTALL"
                                      "PROPERTY"
                                      "SET"
                                      "SOURCE"
                                      "TARGET"
                                      "TARGET_DIRECTORY"
                                      "TEST"
                                      "VARIABLE"))
    ("get_source_file_property"    . ("DIRECTORY"
                                      "TARGET_DIRECTORY"))
    ("include"                     . ("NO_POLICY_SCOPE"
                                      "OPTIONAL"
                                      "RESULT_VARIABLE"))
    ("include_directories"         . ("AFTER"
                                      "BEFORE"
                                      "SYSTEM"))
    ("include_external_msproject"  . ("GUID"
                                      "PLATFORM"
                                      "TYPE"))
    ("include_guard"               . ("DIRECTORY"
                                      "GLOBAL"))
    ("install"                     . ("ALL_COMPONENTS"
                                      "ARCHIVE"
                                      "BUNDLE"
                                      "CODE"
                                      "COMPONENT"
                                      "CONFIGURATIONS"
                                      "CXX_MODULES_BMI"
                                      "CXX_MODULES_DIRECTORY"
                                      "DESTINATION"
                                      "DIRECTORY"
                                      "DIRECTORY_PERMISSIONS"
                                      "EXCLUDE"
                                      "EXCLUDE_FROM_ALL"
                                      "EXPORT"
                                      "EXPORT_ANDROID_MK"
                                      "EXPORT_LINK_INTERFACE_LIBRARIES"
                                      "FILE"
                                      "FILE_SET"
                                      "FILES"
                                      "FILES_MATCHING"
                                      "FILE_PERMISSIONS"
                                      "FRAMEWORK"
                                      "GROUP_EXECUTE"
                                      "GROUP_READ"
                                      "GROUP_WRITE"
                                      "INCLUDES"
                                      "LIBRARY"
                                      "MESSAGE"
                                      "MESSAGE_NEVER"
                                      "NAMELINK_COMPONENT"
                                      "NAMELINK_ONLY"
                                      "NAMELINK_SKIP"
                                      "NAMESPACE"
                                      "OBJECTS"
                                      "OPTIONAL"
                                      "OWNER_EXECUTE"
                                      "OWNER_READ"
                                      "OWNER_WRITE"
                                      "PATTERN"
                                      "PERMISSIONS"
                                      "PRIVATE_HEADER"
                                      "PROGRAMS"
                                      "PUBLIC_HEADER"
                                      "REGEX"
                                      "RENAME"
                                      "RESOURCE"
                                      "RUNTIME"
                                      "RUNTIME_DEPENDENCIES"
                                      "RUNTIME_DEPENDENCY_SET"
                                      "SETGID"
                                      "SETUID"
                                      "SCRIPT"
                                      "TARGETS"
                                      "TYPE"
                                      "USE_SOURCE_PERMISSIONS"
                                      "WORLD_EXECUTE"
                                      "WORLD_READ"
                                      "WORLD_WRITE"
                                      ;; Arguments to RUNTIME_DEPENDENCY_SET
                                      "DIRECTORIES"
                                      "PRE_INCLUDE_REGEXES"
                                      "PRE_EXCLUDE_REGEXES"
                                      "POST_INCLUDE_REGEXES"
                                      "POST_EXCLUDE_REGEXES"
                                      "POST_INCLUDE_FILES"
                                      "POST_EXCLUDE_FILES"))
    ("install_files"               . ("FILES"))
    ("install_programs"            . ("FILES"))
    ("install_targets"             . ("RUNTIME_DIRECTORY"))
    ("link_directories"            . ("AFTER"
                                      "BEFORE"))
    ("link_libraries"              . ("debug"
                                      "general"
                                      "optimized"))
    ("list"                        . ("APPEND"
                                      "ASCENDING"
                                      "AT"
                                      "CASE"
                                      "COMPARE"
                                      "DESCENDING"
                                      "EXCLUDE"
                                      "FILE_BASENAME"
                                      "FILTER"
                                      "FIND"
                                      "FOR"
                                      "GENEX_STRIP"
                                      "GET"
                                      "INCLUDE"
                                      "INSENSITIVE"
                                      "INSERT"
                                      "JOIN"
                                      "LENGTH"
                                      "NATURAL"
                                      "ORDER"
                                      "POP_BACK"
                                      "POP_FRONT"
                                      "PREPEND"
                                      "REGEX"
                                      "REMOVE_AT"
                                      "REMOVE_DUPLICATES"
                                      "REMOVE_ITEM"
                                      "REPLACE"
                                      "REVERSE"
                                      "SENSITIVE"
                                      "SORT"
                                      "STRING"
                                      "STRIP"
                                      "SUBLIST"
                                      "TOLOWER"
                                      "TOUPPER"
                                      "TRANSFORM"
                                      "OUTPUT_VARIABLE"))
    ("load_cache"                  . ("EXCLUDE"
                                      "INCLUDE_INTERNALS"
                                      "READ_WITH_PREFIX"))
    ("load_command"                . ("COMMAND_NAME"))
    ("mark_as_advanced"            . ("CLEAR"
                                      "FORCE"))
    ("math"                        . ("EXPR"
                                      "DECIMAL"
                                      "HEXADECIMAL"
                                      "INPUT_FORMAT"
                                      "OUTPUT_FORMAT"))
    ("message"                     . ("AUTHOR_WARNING"
                                      "CHECK_FAIL"
                                      "CHECK_PASS"
                                      "CHECK_START"
                                      "CONFIGURE_LOG"
                                      "DEPRECATION"
                                      "DEBUG"
                                      "FATAL_ERROR"
                                      "NOTICE"
                                      "SEND_ERROR"
                                      "STATUS"
                                      "TRACE"
                                      "VERBOSE"
                                      "WARNING"))
    ("project"                     . ("DESCRIPTION"
                                      "HOMEPAGE_URL"
                                      "LANGUAGES"
                                      "VERSION"))
    ("separate_arguments"          . ("NATIVE_COMMAND"
                                      "PROGRAM"
                                      "SEPARATE_ARGS"
                                      "UNIX_COMMAND"
                                      "WINDOWS_COMMAND"))
    ("set"                         . ("BOOL"
                                      "CACHE"
                                      "FILEPATH"
                                      "FORCE"
                                      "INTERNAL"
                                      "PARENT_SCOPE"
                                      "PATH"
                                      "STRING"))
    ("set_directory_properties"    . ("PROPERTIES"))
    ("set_property"                . ("APPEND"
                                      "APPEND_STRING"
                                      "CACHE"
                                      "DIRECTORY"
                                      "GLOBAL"
                                      "INSTALL"
                                      "PROPERTY"
                                      "SOURCE"
                                      "TARGET"
                                      "TARGET_DIRECTORY"
                                      "TEST"))
    ("set_source_files_properties" . ("DIRECTORY"
                                      "PROPERTIES"
                                      "TARGET_DIRECTORY"))
    ("set_target_properties"       . ("PROPERTIES"))
    ("set_tests_properties"        . ("PROPERTIES"))
    ("source_group"                . ("FILES"
                                      "PREFIX"
                                      "REGULAR_EXPRESSION"
                                      "TREE"))
    ("string"                      . ("@ONLY"
                                      "ALPHABET"
                                      "APPEND"
                                      "ASCII"
                                      "COMPARE"
                                      "CONCAT"
                                      "CONFIGURE"
                                      "EQUAL"
                                      "ERROR_VARIABLE"
                                      "ESCAPE_QUOTES"
                                      "FIND"
                                      "GENEX_STRIP"
                                      "GET"
                                      "GREATER"
                                      "GREATER_EQUAL"
                                      "HEX"
                                      "JOIN"
                                      "JSON"
                                      "LENGTH"
                                      "LESS"
                                      "LESS_EQUAL"
                                      "MAKE_C_IDENTIFIER"
                                      "MATCH"
                                      "MATCHALL"
                                      "MATCHES"
                                      "MD5"
                                      "MEMBER"
                                      "NAME"
                                      "NAMESPACE"
                                      "NOTEQUAL"
                                      "PREPEND"
                                      "RANDOM"
                                      "RANDOM_SEED"
                                      "REGEX"
                                      "REMOVE"
                                      "REPEAT"
                                      "REPLACE"
                                      "REVERSE"
                                      "SET"
                                      "SHA1"
                                      "SHA224"
                                      "SHA256"
                                      "SHA384"
                                      "SHA512"
                                      "SHA3_224"
                                      "SHA3_256"
                                      "SHA3_384"
                                      "SHA3_512"
                                      "STRIP"
                                      "SUBSTRING"
                                      "TIMESTAMP"
                                      "TOLOWER"
                                      "TOUPPER"
                                      "TYPE"
                                      "UPPER"
                                      "UTC"
                                      "UUID"))
    ("subdirs"                     . ("EXCLUDE_FROM_ALL"
                                      "PREORDER"))
    ("target_compile_definitions"  . ("INTERFACE"
                                      "PRIVATE"
                                      "PUBLIC"))
    ("target_compile_features"     . ("INTERFACE"
                                      "PRIVATE"
                                      "PUBLIC"))
    ("target_compile_options"      . ("BEFORE"
                                      "INTERFACE"
                                      "PRIVATE"
                                      "PUBLIC"))
    ("target_include_directories"  . ("AFTER"
                                      "BEFORE"
                                      "INTERFACE"
                                      "PRIVATE"
                                      "PUBLIC"
                                      "SYSTEM"))
    ("target_link_directories"     . ("BEFORE"
                                      "INTERFACE"
                                      "PRIVATE"
                                      "PUBLIC"))
    ("target_link_libraries"       . ("INTERFACE"
                                      "LINK_INTERFACE_LIBRARIES"
                                      "LINK_PRIVATE"
                                      "LINK_PUBLIC"
                                      "PRIVATE"
                                      "PUBLIC"
                                      "debug"
                                      "general"
                                      "optimized"))
    ("target_link_options"         . ("BEFORE"
                                      "INTERFACE"
                                      "PRIVATE"
                                      "PUBLIC"))
    ("target_precompile_headers"   . ("INTERFACE"
                                      "PRIVATE"
                                      "PUBLIC"
                                      "REUSE_FROM"))
    ("target_sources"              . ("INTERFACE"
                                      "PRIVATE"
                                      "PUBLIC"))
    ("try_compile"                 . ("BINARY_DIR"
                                      "CMAKE_FLAGS"
                                      "COMPILE_DEFINITIONS"
                                      "COPY_FILE"
                                      "COPY_FILE_ERROR"
                                      "CUDA_EXTENSIONS"
                                      "CUDA_STANDARD"
                                      "CUDA_STANDARD_REQUIRED"
                                      "CXX_EXTENSIONS"
                                      "CXX_STANDARD"
                                      "CXX_STANDARD_REQUIRED"
                                      "C_EXTENSIONS"
                                      "C_STANDARD"
                                      "C_STANDARD_REQUIRED"
                                      "HIP_EXTENSIONS"
                                      "HIP_STANDARD"
                                      "HIP_STANDARD_REQUIRED"
                                      "OBJC_EXTENSIONS"
                                      "OBJC_STANDARD"
                                      "OBJC_STANDARD_REQUIRED"
                                      "OBJCXX_EXTENSIONS"
                                      "OBJCXX_STANDARD"
                                      "OBJCXX_STANDARD_REQUIRED"
                                      "INCLUDE_DIRECTORIES"
                                      "LINK_DIRECTORIES"
                                      "LINK_LIBRARIES"
                                      "LINK_OPTIONS"
                                      "LOG_DESCRIPTION"
                                      "NO_CACHE"
                                      "NO_LOG"
                                      "OUTPUT_VARIABLE"
                                      "PROJECT"
                                      "SOURCE_DIR"
                                      "SOURCE_FROM_CONTENT"
                                      "SOURCE_FROM_VAR"
                                      "SOURCE_FROM_FILE"
                                      "SOURCES"))
    ("try_run"                     . ("ARGS"
                                      "CMAKE_FLAGS"
                                      "COMPILE_DEFINITIONS"
                                      "COMPILE_OUTPUT_VARIABLE"
                                      "COPY_FILE"
                                      "COPY_FILE_ERROR"
                                      "CUDA_EXTENSIONS"
                                      "CUDA_STANDARD"
                                      "CUDA_STANDARD_REQUIRED"
                                      "CXX_EXTENSIONS"
                                      "CXX_STANDARD"
                                      "CXX_STANDARD_REQUIRED"
                                      "C_EXTENSIONS"
                                      "C_STANDARD"
                                      "C_STANDARD_REQUIRED"
                                      "HIP_EXTENSIONS"
                                      "HIP_STANDARD"
                                      "HIP_STANDARD_REQUIRED"
                                      "OBJC_EXTENSIONS"
                                      "OBJC_STANDARD"
                                      "OBJC_STANDARD_REQUIRED"
                                      "OBJCXX_EXTENSIONS"
                                      "OBJCXX_STANDARD"
                                      "OBJCXX_STANDARD_REQUIRED"
                                      "LINK_LIBRARIES"
                                      "LINK_OPTIONS"
                                      "LOG_DESCRIPTION"
                                      "NO_CACHE"
                                      "NO_LOG"
                                      "OUTPUT_VARIABLE"
                                      "RUN_OUTPUT_VARIABLE"
                                      "RUN_OUTPUT_STDOUT_VARIABLE"
                                      "RUN_OUTPUT_STDERR_VARIABLE"
                                      "SOURCE_FROM_CONTENT"
                                      "SOURCE_FROM_VAR"
                                      "SOURCE_FROM_FILE"
                                      "SOURCES"
                                      "WORKING_DIRECTORY"))
    ("unset"                       . ("CACHE"
                                      "PARENT_SCOPE"))
    ("use_mangled_mesa"            . ("OUTPUT_DIRECTORY"
                                      "PATH_TO_MESA"))
    ("variable_requires"           . ("REQUIRED_VARIABLE1"
                                      "REQUIRED_VARIABLE2"
                                      "RESULT_VARIABLE"
                                      "TEST_VARIABLE"))
    ("write_file"                  . ("APPEND"))))




(defvar cmake-font-lock-function-alias-alist
  '(("else"        . "if")
    ("elseif"      . "if")
    ("endif"       . "if")
    ("while"       . "if")
    ("endwhile"    . "if")
    ("endblock"    . "block")
    ("endforeach"  . "foreach")
    ("endfunction" . "function")
    ("endmacro"    . "macro"))
  "*Alias function names.

This is used to keep down the size of
`cmake-font-lock-function-keywords-alist' and
`cmake-font-lock-function-signatures'.")


(defvar cmake-font-lock-function-signatures
  '(("add_custom_command"     ()     (("BYPRODUCTS" :repeat :path)
                                      ("DEPENDS" :repeat :path)
                                      ("DEPFILE" :path)
                                      ("IMPLICIT_DEPENDS" :repeat nil :path)
                                      ("MAIN_DEPENDENCY" :path)
                                      ("TARGET" :tgt)))
    ("add_custom_target"      (:tgt) (("BYPRODUCTS" :repeat :path)
                                      ("DEPENDS" :repeat :path)
                                      ("SOURCES" :repeat :path)))
    ("add_dependencies"       (:repeat :tgt))
    ("add_executable"         (:tgt) (("ALIAS" :tgt)))
    ("add_library"            (:tgt) (("ALIAS" :tgt)))
    ("aux_source_directory"   (nil :var))
    ("block"                  () (("PROPAGATE" :repeat :var)))
    ("build_command"          (:var) (("TARGET" :tgt)))
    ("cmake_host_system_information" () (("ERROR_VARIABLE" :var)
                                         ("RESULT" :var)))
    ("cmake_language"                () (("CALL" :func :repeat :var)
                                         ("GET_MESSAGE_LOG_LEVEL" :var)
                                         ("SET_DEPENDENCY_PROVIDER" :func)))
    ("cmake_policy"           () (("GET" :policy :var)
                                  ("SET" :policy)))
    ("cmake_path"             () (("ABSOLUTE_PATH" :var)
                                  ("APPEND" :var)
                                  ("APPEND_STRING" :var)
                                  ("GET" :var)
                                  ("HAS_EXTENSION" :var :var)
                                  ("HAS_FILENAME" :var :var)
                                  ("HAS_PARENT_PATH" :var :var)
                                  ("HAS_RELATIVE_PART" :var :var)
                                  ("HAS_ROOT_DIRECTORY" :var :var)
                                  ("HAS_ROOT_NAME" :var :var)
                                  ("HAS_ROOT_PATH" :var :var)
                                  ("HAS_STEM" :var :var)
                                  ("HASH" :var)
                                  ("IS_ABSSOLUTE" :var :var)
                                  ("IS_PREFIX" :var)
                                  ("IS_RELATIVE" :var :var)
                                  ("NATIVE_PATH" :var)
                                  ("NORMAL_PATH" :var)
                                  ("RELATIVE_PATH" :var)
                                  ("REMOVE_EXTENSION" :var)
                                  ("REMOVE_FILENAME" :var)
                                  ("REPLACE_EXTENSION" :var)
                                  ("REPLACE_FILENAME" :var)
                                  ("SET" :var)))
    ("define_property"        () (("PROPERTY" :prop)
                                  ("INITIALIZE_FROM_VARIABLE" :var)))
    ("execute_process"        () (("RESULT_VARIABLE"  :var)
                                  ("RESULTS_VARIABLE" :var)
                                  ("OUTPUT_VARIABLE"  :var)
                                  ("ERROR_VARIABLE"   :var)
                                  ("INPUT_FILE"       :path)
                                  ("OUTPUT_FILE"      :path)
                                  ("ERROR_FILE"       :path)))
    ("export"                 () (("TARGETS" :repeat :tgt)
                                  ("CXX_MODULES_DIRECTORY" :path)))
    ("file"                   ()     (("LOCK"            :path)
                                      ("CHMOD"           :repeat :path)
                                      ("CHMOD_RECURSE"   :repeat :path)
                                      ("COPY_FILE"       :path :path)
                                      ("MAKE_DIRECTORY"  :repeat :path)
                                      ("POST_EXCLUDE_FILES" :repeat :path)
                                      ("POST_INCLUDE_FILES" :repeat :path)
                                      ("READ"            :path :var)
                                      ("REAL_PATH"       :path :var)
                                      ("REMOVE"          :repeat :path)
                                      ("REMOVE_RECURSE"  :repeat :path)
                                      ("RENAME"          :path :path)
                                      ("MD5"             :path :var)
                                      ("SHA1"            :path :var)
                                      ("SHA224"          :path :var)
                                      ("SHA256"          :path :var)
                                      ("SHA384"          :path :var)
                                      ("SHA512"          :path :var)
                                      ("SHA3_224"        :path :var)
                                      ("SHA3_256"        :path :var)
                                      ("SHA3_384"        :path :var)
                                      ("SHA3_512"        :path :var)
                                      ("STRINGS"         :path :var)
                                      ("TIMESTAMP"       :path :var)
                                      ("RESOLVED_DEPENDENCIES_VAR"   :var)
                                      ("UNRESOLVED_DEPENDENCIES_VAR" :var)
                                      ("CONFLICTING_DEPENDENCIES_PREFIX" nil)
                                      ("EXECUTABLES"     :repeat :path)
                                      ("LIBRARIES"       :repeat :path)
                                      ("MODULES"         :repeat :path)
                                      ("DIRECTORIES"     :repeat :path)
                                      ("PATHS"           :repeat :path)
                                      ("BUNDLE_EXECUTABLE" :path)
                                      ("GLOB"            :var)
                                      ("GLOB_RECURSE"    :var)
                                      ("RESULT"          :var)
                                      ("RESULT_VARIABLE" :var)
                                      ("RELATIVE_PATH"   :var :path :path)
                                      ("TO_CMAKE_PATH"   :path :var)
                                      ("TO_NATIVE_PATH"  :path :var)
                                      ("INPUT"           :path)
                                      ("OUTPUT"          :path)
                                      ("FILES"           :repeat :path)
                                      ("DIRECTORY"       :repeat :path)
                                      ("DESTINATION"     :path)))
    ("find_file"              (:var :optional nil :repeat :path)
     ;; Note: Paths and "ENV var" can be mixed, as in:
     ;;
     ;;    "HINTS ENV x y".
     ;;
     ;; This is not currently supported, as "ENV" is treated as a
     ;; keyword and this breaks the parsing of path arguments.
     (("HINTS" :repeat :path)
      ("PATHS" :repeat :path)
      ("VALIDATOR" :func)))
    ("find_library"           (:var :optional nil :repeat :path)
     ;; Note: See comment in "fild_file".
     (("HINTS" :repeat :path)
      ("PATHS" :repeat :path)
      ("VALIDATOR" :func)))
    ("find_path"              (:var :optional nil :repeat :path)
     ;; Note: See comment in "fild_file".
     (("HINTS" :repeat :path)
      ("PATHS" :repeat :path)
      ("VALIDATOR" :func)))
    ("find_program"           (:var :optional nil :repeat :path)
     ;; Note: See comment in "fild_file".
     (("HINTS" :repeat :path)
      ("PATHS" :repeat :path)
      ("VALIDATOR" :func)))
    ("foreach"                (:var) (("LISTS" :repeat :var)
                                      ("ZIP_LISTS" :repeat :var)))
    ("function"               (:func :repeat :var))
    ("get_cmake_property"     (:var :prop))
    ;; Note: This falls outside the standard form, as "DIRECTORY dir"
    ;; can be optional in the middle of the argument list. Work-around
    ;; is to see :prop as an extra argument to the keywords.
    ("get_directory_property" (:var :optional :prop)
     (("DIRECTORY"  :path :optional :prop)
      ("DEFINITION" :var :optional :prop)))
    ("get_filename_component" (:var :path))
    ("get_property"           (:var) (("PROPERTY"  :prop)
                                      ("DIRECTORY" :optional :path)
                                      ("INSTALL"   :path)
                                      ("SOURCE"    :path)
                                      ("TARGET"    :tgt)
                                      ("TEST"      :tst)))
    ("get_source_file_property" (:var :path :prop))
    ("get_target_property"    (:var :tgt :prop))
    ("get_test_property"      (:test :prop :var))
    ;; Note: "(" is treated as a keyword, however, it will never be
    ;; fontified as such, thanks to
    ;; `cmake-font-lock-argument-kind-regexp-alist'.
    ;;
    ;; This works for all keywords except "IS_NEWER_THAN", since it is
    ;; the only keyword that does not take a variable on its left hand
    ;; side. Fortunately, file names typically don't look like a
    ;; variable, so in most cases it will not be fontified at all.
    ;;
    ;; The ":optional :var" is needed to match both "(x OR y)" and the
    ;; more complex "(x OR ( y AND z ))"
    ("if"  (:optional :var)
     (("("                     :optional :var)
      ("AND"                   :optional :var)
      ("COMMAND"               :func)
      ("DEFINED"               :var)
      ("EQUAL"                 :var)
      ("EXISTS"                :path)
      ("GREATER"               :var)
      ("GREATER_EQUAL"         :var)
      ("IN_LIST"               :var)
      ("IS_ABSOLUTE"           :path)
      ("IS_DIRECTORY"          :path)
      ("IS_NEWER_THAN"         :path)
      ("IS_SYMLINK"            :path)
      ("LESS"                  :var)
      ("LESS_EQUAL"            :var)
      ("MATCHES"               :regexp)
      ("NOT"                   :optional :var)
      ("OR"                    :optional :var)
      ("PATH_EQUAL"            :var)
      ("POLICY"                :policy)
      ("STREQUAL"              :var)
      ("STRGREATER"            :var)
      ("STRGREATER_EQUAL"      :var)
      ("STRLESS"               :var)
      ("STRLESS_EQUAL"         :var)
      ("TARGET"                :tgt)
      ("TEST"                  :tst)
      ("VERSION_EQUAL"         :var)
      ("VERSION_GREATER"       :var)
      ("VERSION_GREATER_EQUAL" :var)
      ("VERSION_LESS"          :var)
      ("VERSION_LESS_EQUAL"    :var)))
    ("include"                ()     (("RESULT_VARIABLE"   :var)))
    ("include_external_msproject" (:tgt :path))
    ("install"                () (("TARGETS"           :repeat :tgt))
     (("DIRECTORY"                  :repeat :path)
      ("FILES"                      :repeat :path)
      ("IMPORTED_RUNTIME_ARTIFACTS" :repeat :tgt)
      ("PROGRAMS"                   :repeat :path)
      ("SCRIPT"                     :path)
      ("TARGETS"                    :repeat :tgt)))
    ("list"                   () (("FILTER"            :var)
                                  ("LENGTH"            :var :var)
                                  ("GET"               :var :repeat nil :var)
                                  ("APPEND"            :var)
                                  ("FIND"              :var nil :var)
                                  ("INSERT"            :var)
                                  ("JOIN"              :var nil :var)
                                  ("POP_BACK"          :repeat :var)
                                  ("POP_FRONT"         :repeat :var)
                                  ("PREPEND"           :var)
                                  ("REMOVE_ITEM"       :var)
                                  ("REMOVE_AT"         :var)
                                  ("REMOVE_DUPLICATES" :var)
                                  ("REVERSE"           :var)
                                  ("SORT"              :var)
                                  ("SUBLIST"           :var nil nil :var)
                                  ("TRANSFORM"         :var)))
    ("macro"                  (:func :repeat :var))
    ("mark_as_advanced"       (:repeat :var) (("CLEAR" :repeat :var)
                                              ("FORCE" :repeat :var)))
    ("math"                   () (("EXPR" :var)))
    ("option"                 (:var))
    ("return"                 () (("PROPAGATE" :repeat :var)))
    ("separate_arguments"     (:var))
    ("set"                    (:var))
    ("set_directory_properties" ()    (("PROPERTIES" :repeat (:prop nil))))
    ("set_property"           ()      (("PROPERTY"         :prop)
                                       ("DIRECTORY"        :repeat :path)
                                       ("INSTALL"          :repeat :path)
                                       ("SOURCE"           :repeat :path)
                                       ("TARGET"           :repeat :tgt)
                                       ("TARGET_DIRECTORY" :repeat :tgt)
                                       ("TEST"             :repeat :tst)))
    ("set_source_files_properties" () (("PROPERTIES" :repeat (:prop nil))
                                       ("DIRECTORY"  :repeat :path)
                                       ("TARGET_DIRECTORY" :repeat :tgt)))
    ("set_target_properties"  (:repeat :tgt)
     (("PROPERTIES" :repeat (:prop nil))))
    ("set_test_properties"    (:repeat :tst)
     (("PROPERTIES" :repeat (:prop nil))))
    ("site_name"              (:var))
    ("string"                 ()      (("CONCAT"    :var)
                                       ("GENEX_STRIP" nil :var)
                                       ("JSON"      :var)
                                       ("ERROR_VARIABLE" :var)
                                       ("MATCH"     nil :var)
                                       ("MATCHALL"  nil :var)
                                       ("REPLACE"   nil nil :var)
                                       ("MD5"       :var)
                                       ("SHA1"      :var)
                                       ("SHA224"    :var)
                                       ("SHA256"    :var)
                                       ("SHA384"    :var)
                                       ("SHA512"    :var)
                                       ("SHA3_224"  :var)
                                       ("SHA3_256"  :var)
                                       ("SHA3_384"  :var)
                                       ("SHA3_512"  :var)
                                       ("EQUAL"     nil nil :var)
                                       ("NOTEQUAL"  nil nil :var)
                                       ("LESS"      nil nil :var)
                                       ("GREATER"   nil nil :var)
                                       ("ASCII"     :repeat nil :var)
                                       ("CONFIGURE" nil :var)
                                       ("JOIN"      nil :var)
                                       ("TOUPPER"   nil :var)
                                       ("TOLOWER"   nil :var)
                                       ;; Note: This is not correct
                                       ;; for JSON LENGTH.
                                       ("LENGTH"    nil :var)
                                       ("REPEAT"    nil nil :var)
                                       ("SUBSTRING" nil nil nil :var)
                                       ("STRIP"     nil :var)
                                       ("TIMESTAMP" :var)
                                       ("MAKE_C_IDENTIFIER" nil :var)
                                       ("RANDOM"    :repeat nil :var)
                                       ("FIND"      nil nil :var)
                                       ("UUID"      :var)
                                       ("HEX"       nil :var)))
    ("target_compile_features"    (:tgt))
    ("target_compile_options"     (:tgt))
    ("target_compile_definitions" (:tgt) (("INTERFACE" :repeat :def)
                                          ("PUBLIC"    :repeat :def)
                                          ("PRIVATE"   :repeat :def)))
    ("target_include_directories" (:tgt) (("INTERFACE" :repeat :path)
                                          ("PUBLIC"    :repeat :path)
                                          ("PRIVATE"   :repeat :path)))
    ("target_link_directories"    (:tgt) (("INTERFACE" :repeat :path)
                                          ("PUBLIC"    :repeat :path)
                                          ("PRIVATE"   :repeat :path)))
    ("target_link_libraries"      (:tgt))
    ("target_link_options"        (:tgt))
    ("target_precompile_headers"  (:tgt) (("INTERFACE" :repeat :path)
                                          ("PUBLIC"    :repeat :path)
                                          ("PRIVATE"   :repeat :path)
                                          ("REUSE_FROM" :tgt)))
    ("target_sources"             (:tgt) (("BASE_DIR" :repeat :path)
                                          ("FILE_SET" nil)
                                          ("FILES"    :repeat :path)
                                          ("TYPE"     nil)))
    ;; Placement of :optional is to allow "try_compile(var dir SOURCES ...)"
    ("try_compile"                (:var nil :optional nil nil :tgt)
     (("OUTPUT_VARIABLE"     :var)
      ("COMPILE_DEFINITIONS" :repeat :def)
      ("COPY_FILE_ERROR"     :var)
      ("SOURCE_FROM_CONTENT" nil nil)
      ("SOURCE_FROM_FILE"    nil :path)
      ("SOURCE_FROM_VAR"     nil :var)
      ("TARGET"              :tgt)))
    ("try_run"                    (:var :var)
     (("COMPILE_DEFINITIONS"        :repeat :def)
      ("COMPILE_OUTPUT_VARIABLE"    :var)
      ("OUTPUT_VARIABLE"            :var)
      ("RUN_OUTPUT_STDOUT_VARIABLE" :var)
      ("RUN_OUTPUT_STDERR_VARIABLE" :var)
      ("RUN_OUTPUT_VARIABLE"        :var)
      ("SOURCE_FROM_CONTENT"        nil nil)
      ("SOURCE_FROM_FILE"           nil :path)
      ("SOURCE_FROM_VAR"            nil :var)))
    ("unset"                      (:var))
    ("variable_watch"             (:var)))
  "*List of function signatures.

Each element of the list is a list with two or three elements.
The first is the (lower-case form of the) name of the function.
The second is a list of argument kinds (see below). The third,
optional, is an alist from keywords to lists of argument kinds.

An argument kind is:

 - nil            A plain argument that should not be fontified.
 - :var           A variable
 - :func          A function
 - :prop          A property
 - :policy        A CMake policy
 - :path          A file or a directory
 - :tgt           A target
 - :def           A preprocessor definition
 - :optional      The rest of the elements are not mandatory
 - :repeat what   Repeat the element `what'
 - :repeat (...)  Repeat the elements is the list.
 - Anything else  A custom type

Elements are fontified as specified by
`cmake-font-lock-argument-kind-face-alist'.")

;; Filled in by `cmake-font-lock-setup'.
(defvar cmake-font-lock-advanced-keywords nil)

;; --------------------------------------------------
;; Public functions
;;

;;;###autoload
(defvar cmake-font-lock-modes
  '(cmake-mode)
  "List of major modes this package should be activated for.

Set this to nil to disable automatic activation.")


;;;###autoload
(defun cmake-font-lock-activate ()
  "Activate advanced CMake colorization.

To activate this every time a CMake file is opened, use the following:

    (add-hook 'cmake-mode-hook 'cmake-font-lock-activate)"
  (interactive)
  (cmake-font-lock-setup)
  ;; If this function is called after font-lock is up and running,
  ;; refresh it. (This does not work on older Emacs versions.)
  (if (and font-lock-mode
           (fboundp 'font-lock-refresh-defaults))
      (font-lock-refresh-defaults)))


;; This ensures that this package is enabled automatically when
;; installed as a package (when cmake-mode is installed).

;; Note: Personally, I dislike adding lambda expressions to hooks.
;; However, in this case it's required to ensure that this package
;; isn't loaded until it's actually used.

;;;###autoload
(add-hook 'change-major-mode-after-body-hook
          (lambda ()
            (when (apply #'derived-mode-p cmake-font-lock-modes)
              (cmake-font-lock-activate))))


(defun cmake-font-lock-add-keywords (name keywords)
  "Add keywords to a CMake function."
  (setq name (downcase name))
  (let ((pair (assoc name cmake-font-lock-function-keywords-alist)))
    (unless pair
      (setq pair (cons name ()))
      (push pair cmake-font-lock-function-keywords-alist))
    (dolist (kw keywords)
      (unless (member kw (cdr pair))
        (setcdr pair (cons kw (cdr pair)))))))

(defun cmake-font-lock-set-signature (name sig
                                              &optional keyword-sig-alist)
  "Set the signature of a CMake function.

`sig' and `keyword-sig-alist' should be on the same form as the
second and third element of each entry in the list
`cmake-font-lock-function-signatures'."
  (setq name (downcase name))
  (let ((entry (assoc name cmake-font-lock-function-signatures)))
    (if entry
        (setcdr entry (list sig keyword-sig-alist))
      (push (list name sig keyword-sig-alist)
            cmake-font-lock-function-signatures))))


;; --------------------------------------------------
;; Font-lock support functions
;;



(defun cmake-font-lock-normalize-function-name (name)
  "Normalize function name, or name alias."
  (setq name (downcase name))
  (let ((alias-pair (assoc name
                           cmake-font-lock-function-alias-alist)))
    (if alias-pair
        (cdr alias-pair)
      name)))


(defun cmake-font-lock-is-in-comment ()
  "Return non-nil if point is in a comment.

This assumes that Font Lock is active and has fontified comments."
  (let ((props (text-properties-at (point)))
        (faces '()))
    (while props
      (let ((pr (pop props))
            (value (pop props)))
        (if (eq pr 'face)
            (setq faces value))))
    (unless (listp faces)
      (setq faces (list faces)))
    (memq 'font-lock-comment-face faces)))


(defun cmake-font-lock-search-forward-ignore-comments (re limit)
  "Search forward for regexp RE but ignore occurences in comments.
LIMIT is search limit."
  (let (res)
    (while
        (progn
          (setq res (re-search-forward re limit t))
          (and res
               (cmake-font-lock-is-in-comment))))
    res))


;; ----------------------------------------
;; Support for ${...} constructs.
;;
;; In addition, the following is handled:
;; - $name{...}  -- "name" (typically ENV)
;; - name{...}   -- Used by set() and unset().
;;

(defun cmake-font-lock-skip-braces ()
  "Move point past the end of a (possibly nested) ${...} construct.
Return nil if the matching closing brace was not found."
  ;; Skip initial optional dollar.
  (if (eq (following-char) ?$)
      (forward-char))
  ;; Skip initial identifier (typically ENV).
  (skip-chars-forward "a-zA-Z@0-9_")
  ;; Skip a { } brace pair, possibly containing other pairs.
  (and (eq (following-char) ?{)
       (let ((depth 0)
             (res nil)
             (done nil))
         (while (not done)
           (cond ((eq (following-char) ?{)
                  (setq depth (+ depth 1))
                  (forward-char))
                 ((eq (following-char) ?})
                  (setq depth (- depth 1))
                  (forward-char)
                  (when (equal depth 0)
                    (setq done t)
                    (setq res t)))
                 (t
                  (if (equal (skip-chars-forward "a-zA-Z@0-9_$") 0)
                      (setq done t)))))
         res)))

(defvar cmake-font-lock-match-dollar-braces-has-name nil
  "True when the current brace construct is a hash, like ENV.")

(defun cmake-font-lock-match-dollar-braces-content (lim)
  "Match (part of) the content of a ${...} construct.
In the case of nested ${...} construct, repeated calls to this
match next top-level part.

If the current construct is without a name (typically a
variable), subexpression 1 of the match-data is set.
Otherwise (typically ENV), subexpression 2 is set.

For example, the numbers below indicate the parts that are
matched in subsequent call:

    ${abd${def}ghi}
      111      222"
  ;; Skip embedded ${...} constructs.
  (while (eq (following-char) ?$)
    (cmake-font-lock-skip-braces))
  (let ((p (point)))
    (if (> (skip-chars-forward "a-zA-Z@0-9_") 0)
        ;; Create match data.
        (let* ((md (list p (point)))
               (md-full md))
          (if cmake-font-lock-match-dollar-braces-has-name
              (setq md-full (append md-full '(nil nil))))
          (setq md-full (append md-full md))
          (set-match-data md-full)
          t)
      nil)))

(defun cmake-font-lock-match-dollar-braces (lim)
  "Match a $xxx{...} construct.

Place point after the opening brace, to prepare for calls to
`cmake-font-lock-match-dollar-braces-content'.

Subexpressions of the match-data are as follows:

 $   1 (if present)
 xxx 2 (if present)
 {   3
 }   4 (if present)"
  (let ((id "[a-zA-Z@_][a-zA-Z@_0-9]*")
        (ws "\\s-*"))
     (if (cmake-font-lock-search-forward-ignore-comments
          (concat "\\(\\$\\)?" ws "\\(" id ws "\\)?" "\\({\\)") lim)
         (let ((md (list (match-beginning 0) (match-end 0)
                         (match-beginning 1) (match-end 1)
                         (match-beginning 2) (match-end 2)
                         (match-beginning 3) (match-end 3))))
           (setq cmake-font-lock-match-dollar-braces-has-name
                 (match-beginning 2))
           (save-excursion
             (goto-char (match-end 0))
             (while
                 (cmake-font-lock-match-dollar-braces-content lim))
             (if (eq (following-char) ?})
                 (nconc md (list (point) (+ (point) 1))))
             ;; Patch slot 0.
             (setcar (cdr md) (+ (point) 1))
             (set-match-data md))
           t)
       nil)))


;; ----------------------------------------
;; Function matcher.
;;

(defvar cmake-font-lock-arguments-begin nil)
(defvar cmake-font-lock-arguments-end   nil
  "The point after the closing parenthesis of the current function.")
(defvar cmake-font-lock-current-function nil
  "Name of function being fontified.")

(defun cmake-font-lock-match-plain-function (lim)
  "Search for a CMake function and setup for argument list matching.

Point is placed after the parenthesis that starts the argument list.
Return the name of the matched function."
  (let ((ws "\\s-*")
        (id "\\<[a-z@_][a-z@_0-9]*\\>"))
    (if (re-search-forward (concat "^" ws "\\(" id "\\)" ws "(") lim t)
        (let ((name (match-string 1)))
          (setq cmake-font-lock-current-function name)
          (setq cmake-font-lock-arguments-begin
                (match-end 0))
          (setq cmake-font-lock-arguments-end
                (save-excursion
                  ;; Right before the opening parenthesis.
                  (goto-char (match-end 1))
                  ;; Search limit. Pick the first of:
                  (or
                   ;; Closing parethesis.
                   (ignore-errors
                     (forward-sexp)
                     (point))
                   ;; Next line starting in column zero.
                   (save-match-data
                     (and (re-search-forward "^[^ \t]" lim t)
                          (match-beginning 0)))
                   ;; End of buffer.
                   (point-max))))
          ;; Return function name.
          name)
      ;; Name not found.
      nil)))

(defun cmake-font-lock-arguments-bound ()
  "Set point at the start of the argument list and return the end.
This is useful as a font-lock pre-match form."
  (goto-char cmake-font-lock-arguments-begin)
  cmake-font-lock-arguments-end)


;; ----------------------------------------
;; Argument matcher.
;;

(defun cmake-font-lock-skip-whitespace ()
  (let ((spc 32))
    (while (and (not (eobp))
                (member (following-char) (list spc  ?\t ?# ?\n)))
      ;; Skip comments.
      (if (eq (following-char) ?#)
          (forward-line))
      ;; Skip whitespace.
      (skip-chars-forward " \t\n"))))

(defun cmake-font-lock-this-argument (&optional limit)
  "Set point at the current argument and return the end.

Parameter `limit' points the before the closing parenthesis of
the function call.

Return nil if there are no more arguments.

Treats parenthesis as individual tokens. A token can contain a
${var} construct."
  (cmake-font-lock-skip-whitespace)
  (if (and limit
           (>= (point) limit))
      nil
    (save-excursion
      (let ((p (point)))
        (if (memq (following-char) '( ?\( ?\) ))
            ;; Parentheses are tokens by themselves.
            ;;
            ;; set(x (y))  == set(x "(;y;)")
            (forward-char)
          (while
              (and (not (eobp))
                   (cond ((memq (char-syntax (following-char))
                                '(?w ?. ?_))
                          (forward-char)
                          t)
                         ((eq (following-char) ?\\)
                          (forward-char)
                          (unless (equal (point) limit)
                            (forward-char))
                          t)
                         ((eq (following-char) ?\")
                          (condition-case nil
                              (forward-sexp)
                            (error (forward-char)))
                          t)
                         ((memq (following-char) '(?$ ?{ ?}))
                          (forward-char)
                          t)
                         (t
                          nil)))))
        (if (> (point) p)
            (point)
          nil)))))

(defvar cmake-font-lock-argument-kind-face-alist
  '((:def     . font-lock-constant-face)
    (:var     . font-lock-variable-name-face)
    (:func    . font-lock-function-name-face)
    (:prop    . font-lock-constant-face)
    (:policy  . font-lock-constant-face)
    (:keyword . font-lock-type-face)
    (:tgt     . font-lock-constant-face)
    (:tst     . font-lock-constant-face))
  "*Map from argument kind to face used to highlight that kind.")


(defvar cmake-font-lock-arguments-with-type '()
  "Function arguments collected but not yet fontified.

Each entry is in the form `(kind beg end)', where `kind'
corresponds to the kinds described by
`cmake-font-lock-function-signatures'. `beg' and `end'
are the start and end points of the argument.")


(defun cmake-font-lock-minimun-number-of-arguments (signature)
  "The least number of arguments needed to match the signature."
  (let ((res 0))
    (while signature
      (if (eq (car signature) :optional)
          (setq signature nil)
        (if (eq (car signature) :repeat)
            (setq signature (cdr-safe (cdr signature)))
          (setq res (+ 1 res))
          (pop signature))))
    res))


(defun cmake-font-lock-collect-all-arguments (function-name limit)
  "Find and categorize all arguments.

`function-name' is the name of the function and `limit' is the
point after the closing parenthesis of the argument list (or, if
not found, another suitable point).

The point is assumed to be positioned after the parenthesis that
start the argument list.

Return a list of `(kind beg end)', where `kind' is the type of
the argument (variable, property etc.), `beg' and `end' are the
location in the buffer where the argument is located."
  (setq function-name
        (cmake-font-lock-normalize-function-name function-name))
  (let ((all-arguments '()))
    ;; ----------
    ;; Collect all arguments into `all-arguments'.
    ;;
    (while
        (let ((end-point (cmake-font-lock-this-argument (- limit 1))))
          (if end-point
              (let ((argument (buffer-substring-no-properties
                               (point) end-point)))
                (push (list argument (point) end-point) all-arguments)
                ;; Continue looping
                (goto-char end-point)
                t)
            ;; else, end loop
            nil)))
    (setq all-arguments (nreverse all-arguments))
    ;; ----------
    ;; partition the arguments into groups, where the all except the
    ;; first group start with a keyword.
    ;;
    ;; Note that not all arguments that match a keyword should be
    ;; treated as a keyword, in case is it is in a position to mean
    ;; something else.
    (let ((signature-to-args-alist '()))
      (let ((triplet (assoc function-name
                            cmake-font-lock-function-signatures))
            (signature          '())
            (keyword-signatures '())
            (function-keywords
             (cdr-safe
              (assoc function-name
                     cmake-font-lock-function-keywords-alist))))
        ;; Start with the signature of arguments in front of any
        ;; keyword.
        (when triplet
          (setq signature      (nth 1 triplet))
          (setq keyword-signatures (nth 2 triplet)))
        (while all-arguments
          (let ((least-number-of-arguments
                 (cmake-font-lock-minimun-number-of-arguments
                  signature))
                (args '()))
            (while (and all-arguments
                        (> least-number-of-arguments 0))
              (push (pop all-arguments) args)
              (setq least-number-of-arguments (- least-number-of-arguments 1)))
            (while (and all-arguments
                        ;; Check keywords both in the plain list...
                        (not (member (nth 0 (car all-arguments))
                                     function-keywords))
                        ;; ...and in the function signature.
                        (not (assoc (nth 0 (car all-arguments))
                                    keyword-signatures)))
              (push (pop all-arguments) args))
            (if args
                (push (cons signature (nreverse args))
                      signature-to-args-alist))
            ;; Continue with the next keyword and its arguments (if
            ;; there are any left).
            (if all-arguments
                (let ((keyword-signature-pair
                       (assoc (nth 0 (car all-arguments)) keyword-signatures)))
                  (setq signature
                        (cons :keyword (cdr-safe keyword-signature-pair))))))))
      (setq signature-to-args-alist (nreverse signature-to-args-alist))
      ;; ----------
      ;; Assign types to arguments. Start at the beginning of each
      ;; group. When a :repeat part is found, match the rest of the
      ;; arguments from the end, finish with matching the remaining
      ;; arguments with the repeat signature.
      (let ((arguments-with-type '()))
        (dolist (signature-args-pair signature-to-args-alist)
          (let ((signature (car signature-args-pair))
                (args (cdr signature-args-pair))
                (repeat-signature nil))
            (while (and (not repeat-signature)
                        args
                        signature)
              (if (eq (car signature) :repeat)
                  (progn
                    (pop signature)       ; :repeat
                    (setq repeat-signature (pop signature))
                    ;; Ensure it's a list.
                    ;;
                    ;; Note: ":repeat nil" is a valid signature,
                    ;; `repeat-signature' should in this case be
                    ;; "(nil)".
                    (if (or (not (listp repeat-signature))
                            (null repeat-signature))
                        (setq repeat-signature (list repeat-signature))))
                (if (eq (car signature) :optional)
                    ;; Ignore :optional (it played out it's part in the
                    ;; grouping above.
                    (pop signature)
                  ;; Plain argument.
                  (push (cons (pop signature) (cdr (pop args)))
                        arguments-with-type))))
            ;; If there are any arguments left, we have found a repeat
            ;; block.
            (if repeat-signature
                (let ((types-from-the-back '()))
                  ;; Match arguments with signatures from the end
                  (setq args (nreverse args))
                  (setq signature (nreverse signature))
                  (while (and args
                              signature)
                    (push (cons (pop signature) (cdr (pop args)))
                          types-from-the-back))
                  ;; Match the middle (repeat) arguments.
                  (setq args (nreverse args))
                  (setq signature repeat-signature)
                  (while args
                    (if (null signature)
                        (setq signature repeat-signature))
                    (push (cons (pop signature) (cdr (pop args)))
                          arguments-with-type))
                  ;; Combine all arguments, in the correct order.
                  (setq arguments-with-type
                        (nconc (nreverse types-from-the-back)
                               arguments-with-type))))))
        (nreverse arguments-with-type)))))


(defun cmake-font-lock-collect-all-arguments-pre-match-form ()
  "Collect all arguments of the current matched function.

Set the point to the beginning of the argument list and return
the end, making this function suitable for a font-lock
pre-match-form."
  (setq cmake-font-lock-arguments-with-type
        (cmake-font-lock-collect-all-arguments
         cmake-font-lock-current-function
         cmake-font-lock-arguments-end))
  (cmake-font-lock-arguments-bound))


;; The regexp match an identifier, possibly containing an ${...}
;; constructs.
(defvar cmake-font-lock-argument-kind-regexp-alist
  '((:var     . "\\`[a-z@_$][a-z@_0-9${}]*\\'")
    (:keyword . "\\`[a-z@_$][a-z@_0-9${}]*\\'")
    (:prop    . "\\`[a-z@_$][a-z@_0-9${}]*\\'")
    (:policy  . "\\`[a-z@_$][a-z@_0-9${}]*\\'")))


(defvar cmake-font-lock-this-argument-face nil
  "The font-lock face (color) that should be used an argument.

This is set by `cmake-font-lock-next-collected-argument'
to correspond to the type of the argument.")


(defun cmake-font-lock-next-collected-argument (lim)
  "Match the next argument.

When there are arguments to match, set the active match data to
correspond to the type of the argument, as specified by
`cmake-font-lock-argument-kind-face-alist', and
return non-nil. Return nil if there are no more arguments to
match."
  (let ((res nil))
    (while
        (let ((match (and cmake-font-lock-arguments-with-type
                          (pop cmake-font-lock-arguments-with-type))))
;          (message "next: %s" match)
          (if match
              (let* ((kind (nth 0 match))
                     (type-regexp-pair
                      (assoc
                       kind
                       cmake-font-lock-argument-kind-regexp-alist)))
                (if (or (null type-regexp-pair)
                        (string-match (cdr type-regexp-pair)
                                      (buffer-substring-no-properties
                                       (nth 1 match)
                                       (nth 2 match))))
                    (let ((type-face-pair
                           (assoc
                            kind
                            cmake-font-lock-argument-kind-face-alist)))
                      (if type-face-pair
                          (progn
                            (setq cmake-font-lock-this-argument-face
                                  (cdr type-face-pair))
                            (set-match-data (list (nth 1 match)
                                                  (nth 2 match)))
                            (setq res t)
                            nil)                ; Stop loop
                        t))                 ; Uninteresting match, continue.
                  ;; Match, argument can't possibly be of this type.
                  t))
            ;; Else, no more matches, stop loop.
            nil)))
;    (message "next -> %s" res)
    res))


;; ----------------------------------------
;; Setup.
;;

(defvar cmake-font-lock-saved-point nil)

(defun cmake-font-lock-setup ()
  "Initialize cmake font-lock rules."

  ;;----------
  ;; Syntax
  ;;
  ;; In cmake, you can write strings without quotes, for example:
  ;;
  ;;  if (EXISTS /my/target/directory)
  ;;    ..
  ;;  endif()
  ;;
  ;; This makes font-lock see all symbols and punctuation characters
  ;; as parts of words. This ensures that the individual words (like
  ;; "target" in the example above) are not considered words (and this
  ;; fontified) when matching with "\\<" and "\\>".
  ;;
  ;; Keep "=" as a non-word character to allow us to match "-DFOO" in
  ;; "-DFOO=BAR", which is used when fontifying preprocessor definitions.
  ;;
  ;; Ensure that "_" is treated as a word by font-lock. By default,
  ;; cmake-mode defines this as a word, but users may (and is
  ;; encouraged to) redefine this to "symbol".
  ;;
  ;; Note: The cmake documentation does not include the exact syntax
  ;; for quote-less strings, but this seems to work for typical cases.
  (let ((syntax-alist '())
        (ch 0))
    (while (< ch 256)
      (if (and (not (equal ch ?=))
               (or (equal ch ?_)
                   (member (char-syntax ch) '(?. ?_))))
          (push (cons ch "w") syntax-alist))
      (setq ch (+ ch 1)))

    ;; ----------
    ;; The third argument sets case-independent font-lock rules.
    (setq font-lock-defaults
          (list 'cmake-font-lock-advanced-keywords nil t syntax-alist)))

  ;; ----------
  ;; New font-lock rules.
  ;;

  (setq font-lock-multiline t)
  (let* ((keywords '("block"      "endblock"
                     "break"
                     "continue"
                     "foreach"    "endforeach"
                     "function"   "endfunction"
                     "else"
                     "elseif"
                     "if"         "endif"
                     "include"
                     "macro"      "endmacro"
                     "return"
                     "while"      "endwhile"))
         (constants '("true"
                      "false"
                      "yes"
                      "no"
                      "y"
                      "n"
                      "on"
                      "off"))
         ;; Regexp snippets used to make larger regexps more readable.
         (id "[a-z@_][a-z@_0-9]*")
         (ws "\\s-*"))
    (setq
     cmake-font-lock-advanced-keywords
     (list
      ;; Keywords -- Basic language features like flow control.
      (cons (concat "\\<"
                    (regexp-opt keywords t)
                    "\\>" ws "(")
            '(1 'font-lock-keyword-face))
      ;; Constants.
      (cons (concat "\\<"
                    (regexp-opt constants t)
                    "\\>")
            '(1 'font-lock-constant-face))
      ;; Preprocessor definitions.
      (cons (concat "\\<-D\\([a-z_][a-z0-9_]*\\)\\>")
            '(1 'font-lock-constant-face))
      ;; Expression generator $<name:...>
      (cons (concat "\\$<\\(" id "\\)[:>]")
            '(1 'font-lock-preprocessor-face))
      ;; Variables embedded in ${...} and $name{...} (where "name"
      ;; typically is ENV).
      ;;
      ;; In the ${...} case, the interior is colored as a variable.
      ;;
      ;; In the $name{...} case, "name" is colored like a variable and
      ;; the content as a constant.
      ;;
      ;; The "${" and "}" are not fontified (unless as part of a
      ;; string).
      ;;
      ;; Nested constructs like "${abc${def}ghi}" are handled by using
      ;; an anchored rule, where the inner match function
      ;; `cmake-font-lock-match-dollar-braces-content'
      ;; repeatedly match the non-${} parts, in this case "abc" and
      ;; "ghi".
      ;;
      ;; Implementation node: The following will fontify ${ and }
      ;; using the face "default" (unless it's part of a string). This
      ;; stops it from being painted over by the arguments fontifier
      ;; below, which use the "keep" construct to paint the rest of
      ;; each argument.
      ;;
      ;; The pre- and post-match forms are used to back up the point,
      ;; to ensure that nested constructs work.
      '(cmake-font-lock-match-dollar-braces
        (1 'default nil t)
        (2 'font-lock-variable-name-face nil t)
        (3 'default)
        (4 'default nil t)
        (cmake-font-lock-match-dollar-braces-content
         ;; PRE-MATCH-FORM:
         (setq cmake-font-lock-saved-point (point))
         ;; POST-MATCH-FORM:
         (goto-char cmake-font-lock-saved-point)
         ;; Highlight.
         (1 'font-lock-variable-name-face prepend t)
         (2 'font-lock-constant-face prepend t)))
      ;; Function calls and arguments.
      '(cmake-font-lock-match-plain-function
        (1 'font-lock-function-name-face)
        ;; Arguments passed to functions, like "WARNING" in
        ;; "message(WARNING ...). This can fontify keywords,
        ;; variables, properties, and function names -- but only if
        ;; the function type is known.
        (cmake-font-lock-next-collected-argument
         ;; PRE-MATCH-FORM:
         (cmake-font-lock-collect-all-arguments-pre-match-form)
         ;; POST-MATCH-FORM:
         nil
         ;; Highlight
         (0 cmake-font-lock-this-argument-face keep t)))
      ))))


;; ------------------------------------------------------------
;; The end
;;

(provide 'cmake-font-lock)

;;; cmake-font-lock.el ends here
