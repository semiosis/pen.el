;;; hyperdrive-vars.el --- Shared (persist-)defvars, deffaces, defcustoms  -*- lexical-binding: t; -*-

;; Copyright (C) 2023, 2024  USHIN, Inc.

;; Author: Joseph Turner <joseph@ushin.org>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public
;; License along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

;;;; Requirements

(require 'persist)
(require 'dired)     ; For faces.
(require 'cus-edit)  ; For `custom-button' face.

;;;; Configuration:

(defgroup hyperdrive nil
  "P2P filesystem in Emacs."
  :link '(info-link :tag "Info Manual" "(hyperdrive)")
  :link '(url-link :tag "Website" "https://ushin.org/hyperdrive/hyperdrive-manual.html")
  :link '(emacs-library-link :tag "Library Source" "hyperdrive.el")
  :group 'communication
  :group 'external
  :prefix "hyperdrive-")

(defcustom h/gateway-directory (expand-file-name "~/.local/lib/hyperdrive.el")
  "Where the hyper-gateway executable is found.
If not found here, the \"PATH\" environment variable is checked
with `executable-find'.  Command `hyperdrive-install' installs to
this directory."
  :type 'directory)

(defcustom h/gateway-program "hyper-gateway-ushin"
  "Name of gateway executable.
Command `hyperdrive-install' installs to this name inside
`hyperdrive-gateway-directory'.  Function
`h//gateway-path' looks for executable by this name."
  :type 'string)

(defcustom h/gateway-command-args "run --writable true --silent true"
  "Arguments passed to the gateway.
Note that the \"--port\" argument should not be included here, as
it is added automatically at run-time using the value of
`hyperdrive-gateway-port'."
  :type 'string
  :group 'hyperdrive)

(define-obsolete-variable-alias
  ;; TODO(v0.5.0) Remove this alias.
  'hyperdrive-hyper-gateway-port 'hyperdrive-gateway-port "0.4.0")

(defcustom h/gateway-port 4973
  "Port to use to send requests to the gateway server."
  :type 'natnum)

(defcustom h/persist-location nil
  ;; TODO: Consider using XDG locations for this, as well as storing
  ;; -hyperdrives separately from -version-ranges.  (Note that xdg-state-home
  ;; is only in Emacs 29+ and is not in compat.)
  "Location where `persist' will store data.

- `hyperdrive-hyperdrives'
- `hyperdrive-existent-versions'"
  :type '(choice (const :tag "Use default persist location" nil)
                 (file :tag "Custom location")))

(defcustom h/download-directory
  (expand-file-name
   (if (bound-and-true-p eww-download-directory)
       (if (stringp eww-download-directory)
           eww-download-directory
         (funcall eww-download-directory))
     "~/"))
  "Location where `hyperdrive-download-url' will download files.
Defaults to `eww-download-directory'."
  :type '(file :must-match t))

(defvar h/timestamp-width)
(defcustom h/timestamp-format "%x %X"
  "Format string used for timestamps.
Passed to `format-time-string', which see."
  :type 'string
  :set (lambda (option value)
         (set-default option value)
         (setf h/timestamp-width
               ;; FIXME: This value varies based on current
               ;;        time. (format-time-string "%-I") will
               ;;        be one or two characters long
               ;;        depending on the time of day
               (string-width (format-time-string value)))))

(defcustom h/directory-display-buffer-action
  '(display-buffer-same-window)
  "Display buffer action for hyperdrive directories.
Passed to `display-buffer', which see."
  :type display-buffer--action-custom-type)

(defcustom h/directory-sort '(name . :ascending)
  "Column by which directory entries are sorted.
Internally, a cons cell of (COLUMN . DIRECTION), the COLUMN being
one of the directory listing columns (\\+`name', \\+`size', or
\\+`mtime') and DIRECTION being one of \\+`:ascending' or
\\+`:descending'."
  :type '(radio (cons :tag "By name" (const :format "" name)
                      (choice :tag "Direction" :value :ascending
                              (const :tag "Ascending" :ascending)
                              (const :tag "Descending" :descending)))
                (cons :tag "By size" (const :format "" size)
                      (choice :tag "Direction" :value :ascending
                              (const :tag "Ascending" :ascending)
                              (const :tag "Descending" :descending)))
                (cons :tag "By date" (const :format "" mtime)
                      (choice :tag "Direction" :value :ascending
                              (const :tag "Ascending" :ascending)
                              (const :tag "Descending" :descending)))))

(defcustom h/history-display-buffer-action
  '(display-buffer-same-window)
  "Display buffer action for hyperdrive history buffers.
Passed to `display-buffer', which see."
  :type display-buffer--action-custom-type)

(defcustom h/stream-player-command "mpv --force-window=immediate %s"
  "Command used to play streamable URLs externally.
In the command, \"%s\" is replaced with the URL (it should not be
quoted, because the arguments are passed directly rather than
through a shell)."
  :type '(choice (const :tag "MPV" "mpv --force-window=immediate %s")
                 (const :tag "VLC" "vlc %s")
                 (string :tag "Other command")))

(defcustom h/queue-limit 20
  "Default size of request queues."
  ;; TODO: Consider a separate option for metadata queue size (e.g. used in the dir handler).
  ;; TODO: Consider a separate option for upload queue size, etc.
  :type 'natnum)

(defcustom h/render-html t
  "Render HTML hyperdrive files with EWW."
  :type 'boolean)

;;;;;; Entry formatting

(defgroup hyperdrive-entry-format nil
  "Formatting of entries for buffer names, etc."
  :group 'hyperdrive)

(defcustom h/preferred-formats
  '(petname nickname domain seed short-key public-key)
  "Default format for displaying hyperdrive hostnames.
Each option is checked in order, and the first available type is
used."
  :type '(repeat
          (choice (const :tag "Petname" petname)
                  (const :tag "Nickname"
                         :doc "(Nickname specified by hyperdrive author)"
                         :format "%t %h"
                         nickname)
                  (const :tag "DNSLink domain" domain)
                  (const :tag "Seed" seed)
                  (const :tag "Shortened public key" short-key)
                  (const :tag "Full public key" public-key))))

(defcustom h/default-entry-format "[%H] %p%v"
  "Format string for displaying entries.
Specifiers:

%H  Preferred hyperdrive format (see `hyperdrive-preferred-formats')

To configure the format of the following specifiers, see `hyperdrive-formats':

%n  Entry name
%p  Entry path
%v  Entry version
%S  Hyperdrive seed
%P  Hyperdrive petname
%N  Hyperdrive nickname
%K  Hyperdrive public key (full)
%k  Hyperdrive public key (short)
%D  Hyperdrive domains"
  :type 'string)

(defvar h/default-entry-format-without-version "[%H] %p"
  "Format string for displaying entries without displaying the version.
The format of the following specifiers can be configured using
`hyperdrive-formats', which see.")

(defcustom h/buffer-name-format "[%H] %n%v"
  "Format string for buffer names.
Specifiers are as in `hyperdrive-default-entry-format', which
see."
  :type 'string)

(defvar h/raw-formats
  '(;; Entry metadata
    (name    . "%s")
    (path    . "%s")
    (version . "%s")
    ;; Hyperdrive metadata
    (petname    . "%s")
    (nickname   . "%s")
    (public-key . "%s")
    (short-key  . "%s")
    (seed       . "%s")
    (domains    . "%s"))
  "Like `hyperdrive-formats', without any special formatting.")

(defcustom h/formats
  '(;; Entry metadata
    (name       . "%s")
    (version    . " (version:%s)")
    (path       . "%s")
    ;; Hyperdrive metadata
    (petname    . "petname:%s")
    (nickname   . "nickname:%s")
    (public-key . "public-key:%s")
    (short-key  . "public-key:%.8s…")
    (seed       . "seed:%s")
    (domains    . "domains:%s"))
  "Alist mapping hyperdrive and hyperdrive entry metadata item to format string.
Each metadata item may be one of:

- \\+`name' (Entry name)
- \\+`path' (Entry path)
- \\+`version' (Entry version)
- \\+`petname' (Hyperdrive petname)
- \\+`nickname' (Hyperdrive nickname)
- \\+`domains' (Hyperdrive domains)
- \\+`public-key' (Hyperdrive public key)
- \\+`short-key' (Hyperdrive short key)
- \\+`seed' (Hyperdrive seed)

In each corresponding format string, \"%s\" is replaced with the
value (and should only be present once in the string).  Used in
`hyperdrive-buffer-name-format', which see."
  :type '(list (cons :tag "Entry name" (const name)
                     (string :tag "Format string"))
               (cons :tag "Entry version" (const version)
                     (string :tag "Format string"))
               (cons :tag "Entry path" (const path)
                     (string :tag "Format string"))
               (cons :tag "Hyperdrive petname" (const petname)
                     (string :tag "Format string"))
               (cons :tag "Hyperdrive nickname" (const nickname)
                     (string :tag "Format string"))
               (cons :tag "Hyperdrive public key" (const public-key)
                     (string :tag "Format string"))
               (cons :tag "Hyperdrive short key" (const short-key)
                     (string :tag "Format string"))
               (cons :tag "Hyperdrive seed" (const seed)
                     (string :tag "Format string"))
               (cons :tag "Hyperdrive domains" (const domains)
                     (string :tag "Format string"))))

;;;;;; Gateway configuration

(defgroup hyperdrive-gateway nil
  "Starting and stopping the gateway."
  :group 'hyperdrive)

(declare-function h//gateway-start-default "hyperdrive-lib")
(defcustom h/gateway-start-function #'h//gateway-start-default
  "Function called to start the gateway.
If this function signals an error, the `h/gateway-ready-hook'
will not be run; otherwise, the hook will be run when the gateway
appears to be ready."
  :type 'function)

(declare-function h//gateway-stop-default "hyperdrive-lib")
(defcustom h/gateway-stop-function #'h//gateway-stop-default
  "Function called to stop the gateway.
This function should signal an error if it fails to stop the
gateway process."
  :type 'function)

(declare-function h/gateway-live-p-default "hyperdrive-lib")
(defcustom h/gateway-live-predicate #'h/gateway-live-p-default
  "Predicate function which returns non-nil if the gateway process is live."
  :type 'function)

(defcustom h/gateway-ready-hook
  '( h/check-gateway-version
     h/announce-gateway-ready
     h/menu-refresh)
  "Hook called when gateway is ready after starting it.
This hook is called by `hyperdrive--gateway-wait-for-ready' after
`hyperdrive-start'."
  :type 'hook)

(defcustom h/gateway-dead-hook
  '( h//gateway-cleanup-default
     h/announce-gateway-stopped
     h/menu-refresh)
  "Hook called when gateway is ready after stopping it.
This hook is called by `hyperdrive--gateway-wait-for-dead' after
`hyperdrive-stop'."
  :type 'hook)

;;;;; Faces

(defgroup hyperdrive-faces nil
  "Faces shown in directory listings."
  :group 'hyperdrive)

(defface h/petname '((t :inherit font-lock-type-face))
  "Applied to hyperdrive petnames.")

(defface h/seed '((t :inherit font-lock-doc-face))
  "Applied to hyperdrive seeds.")

(defface h/domain '((t :inherit font-lock-keyword-face))
  "Applied to hyperdrive domains.")

(defface h/nickname '((t :inherit font-lock-warning-face))
  "Applied to hyperdrive nicknames.")

(defface h/public-key '((t :inherit font-lock-function-name-face))
  "Applied to hyperdrive public keys.")

(defface h/file-name '((t :inherit font-lock-keyword-face)) ; TODO theme
  "Applied to file names.")

(defface h/dimmed '((t :inherit shadow))
  "Applied to text in transient menus that should be dimmed.")

(defface h/header '((t (:inherit dired-header)))
  "Directory path.")

(defface h/column-header '((t (:inherit underline)))
  "Column header.")

(defface h/selected-column-header '((t ( :inherit underline
                                         :weight bold)))
  "Selected column header.")

(defface h/directory '((t (:inherit dired-directory)))
  "Subdirectories.")

(defface h/size '((t (:inherit font-lock-doc-face)))
  "File sizes.")

(defface h/safe '((t (:inherit success)))
  "File sizes for entries which have been fully downloaded.")

(defface h/unsafe '((t (:inherit error)))
  "File sizes for entries which have not been downloaded.")

(defface h/safe-unknown '((t (:inherit warning)))
  "File sizes for entries which have been partially downloaded.")

(defface h/size-fully-downloaded '((t (:inherit success :weight normal)))
  "File sizes for entries which have been fully downloaded.")

(defface h/size-not-downloaded '((t (:inherit error :weight normal)))
  "File sizes for entries which have not been downloaded.")

(defface h/size-partially-downloaded '((t (:inherit warning :weight normal)))
  "File sizes for entries which have been partially downloaded.")

(defface h/timestamp '((t (:inherit default)))
  "Entry timestamp.")

(defface h/header-arrow '((t (:inherit bold)))
  "Header arrows.")

(defface h/history-range '((t (:inherit font-lock-escape-face)))
  "Version range in `hyperdrive-history' buffers.")

(defface h/history-existent '((t :inherit success))
  "Marker for known existent entries in `hyperdrive-history'buffers.")

(defface h/history-nonexistent '((t :inherit error))
  "Marker for known nonexistent entries in `hyperdrive-history'buffers.")

(defface h/history-unknown '((t :inherit warning))
  "Marker for entries with unknown existence in `hyperdrive-history' buffers.")

;;;; Internals

(defvar h/gateway-version-expected
  '(:name "hyper-gateway-ushin" :version "3.14.0"))

(defvar h/gateway-version-checked-p nil
  "Non-nil if the gateway's version has been checked.
If the version was unexpected,
`hyperdrive-check-gateway-version' displayed a warning.")

(defvar h/gateway-process nil
  "Gateway process.")

(defvar h/install-process nil
  "When non-nil, the curl process downloading the gateway for install/upgrade.")

(defvar h//gateway-starting-timer nil
  "The timer used when the gateway is starting.")

(defvar h//gateway-stopping-timer nil
  "The timer used when the gateway is stopping.")

(defvar-local h/current-entry nil
  "Entry for current buffer.")
(put 'h/current-entry 'permanent-local t)

(defvar h/type-handlers
  `(
    ;; Directories are sent from the gateway as JSON arrays
    ("application/json" . h/handler-json)
    (,(rx bos "audio/") . h/handler-streamable)
    (,(rx bos "video/") . h/handler-streamable)
    (,(rx bos "image/") . h/handler-image)
    (,(rx (or "text/html" "application/xhtml+xml")) . h/handler-html))
  "Alist mapping MIME types to handler functions.
Keys are regexps matched against MIME types.")

(defvar h/dir-sort-fields
  '((size  :accessor he/size
           :ascending <
           :descending >
           :desc "Size")
    (mtime :accessor he/mtime
           :ascending time-less-p
           :descending h/time-greater-p
           :desc "Last Modified")
    (name  :accessor he/name
           :ascending string<
           :descending string>
           :desc "Name"))
  "Fields for sorting hyperdrive directory buffer columns.")

;;;;; Regular expressions

(eval-and-compile
  (defconst h//hyper-prefix "hyper://"
    "Hyperdrive URL prefix."))

(defconst h//public-key-re
  (rx (eval h//hyper-prefix) (group (= 52 alphanumeric)))
  "Regexp to match \"hyper://\" + public key.

Capture group matches public key.")

(defconst h//version-re
  (rx (eval h//hyper-prefix)
      (one-or-more alnum)
      (group "+" (one-or-more num)))
  "Regexp to match \"hyper://\" + public key or seed + version number.

Capture group matches version number.")

;;;;; Persisted variables

(persist-defvar h/hyperdrives (make-hash-table :test 'equal)
  "List of known hyperdrives."
  h/persist-location)

(persist-defvar h/existent-versions (make-hash-table :test 'equal)
  "Hash table of hyperdrive existent version.
Keys are generated by `hyperdrive--existent-versions-key', and
values are lists of known existent version range starts."
  h/persist-location)

;; TODO: Flesh out the persist hook.
;; (defvar hyperdrive-persist-hook nil
;;   :type 'hook)

;;;; Footer

(provide 'hyperdrive-vars)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-vars.el ends here
