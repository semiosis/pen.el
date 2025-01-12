;;; mlgud.el --- parts of gud.el for matlab-shell -*- lexical-binding:t -*-

;; This contains parts of gud.el prefixed with matlab and modified to support `matlab-shell'. gud
;; does not support multiple debuggers. For matlab-shell, we'd need to be able to debug MATLAB in
;; `matlab-shell', while in another buffer uses `gud-gdb' or `gdb' from gud.el to debug C++ code.

;; Emacs 24 gud.el info:

;;; gud.el --- Grand Unified Debugger mode for running GDB and other debuggers

;; Copyright (C) 1992-1996, 1998, 2000-2015 Free Software Foundation,
;; Inc.

;; Author: Eric S. Raymond <esr@snark.thyrsus.com>
;; Maintainer: emacs-devel@gnu.org
;; Keywords: unix, tools

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The ancestral gdb.el was by W. Schelter <wfs@rascal.ics.utexas.edu>.
;; It was later rewritten by rms.  Some ideas were due to Masanobu.  Grand
;; Unification (sdb/dbx support) by Eric S. Raymond <esr@thyrsus.com> Barry
;; Warsaw <bwarsaw@cen.com> hacked the mode to use comint.el.  Shane Hartman
;; <shane@spr.com> added support for xdb (HPUX debugger).  Rick Sladkey
;; <jrs@world.std.com> wrote the GDB command completion code.  Dave Love
;; <d.love@dl.ac.uk> added the IRIX kluge, re-implemented the Mips-ish variant
;; and added a menu. Brian D. Carlstrom <bdc@ai.mit.edu> combined the IRIX
;; kluge with the gud-xdb-directories hack producing gud-dbx-directories.
;; Derek L. Davies <ddavies@world.std.com> added support for jdb (Java
;; debugger.)

;;; Code:

(require 'comint)

(defvar gdb-active-process)
(defvar gdb-define-alist)
(defvar gdb-macro-info)
(defvar gdb-show-changed-values)
(defvar gdb-source-window)
(defvar gdb-var-list)
(defvar hl-line-mode)
(defvar hl-line-sticky-flag)


;; ======================================================================
;; MLGUD commands must be visible in C buffers visited by MLGUD

(defgroup mlgud nil
  "The \"Grand Unified Debugger\" interface.
Supported debuggers include gdb, sdb, dbx, xdb, perldb,
pdb (Python), and jdb."
  :group 'processes
  :group 'tools)




(defvar mlgud-marker-filter nil)
(put 'mlgud-marker-filter 'permanent-local t)
(defvar mlgud-find-file nil)
(put 'mlgud-find-file 'permanent-local t)

(defun mlgud-marker-filter (&rest args)
  (apply mlgud-marker-filter args))

(defvar mlgud-minor-mode nil)
(put 'mlgud-minor-mode 'permanent-local t)

(defvar mlgud-comint-buffer nil)

(defvar mlgud-keep-buffer nil)

(defun mlgud-symbol (sym &optional soft minor-mode)
  "Return the symbol used for SYM in MINOR-MODE.
MINOR-MODE defaults to `mlgud-minor-mode'.
The symbol returned is `mlgud-<MINOR-MODE>-<SYM>'.
If SOFT is non-nil, returns nil if the symbol doesn't already exist."
  (unless (or minor-mode mlgud-minor-mode) (error "mlGud internal error"))
  (funcall (if soft 'intern-soft 'intern)
	   (format "mlgud-%s-%s" (or minor-mode mlgud-minor-mode) sym)))

(defun mlgud-val (sym &optional minor-mode)
  "Return the value of `mlgud-symbol' SYM.  Default to nil."
  (let ((sym (mlgud-symbol sym t minor-mode)))
    (if (boundp sym) (symbol-value sym))))

(defvar mlgud-running nil
  "Non-nil if debugged program is running.
Used to gray out relevant toolbar icons.")

(defvar mlgud-target-name "--unknown--"
  "The apparent name of the program being debugged in a mlgud buffer.")

;; Use existing Info buffer, if possible.
(defun mlgud-goto-info ()
  "Go to relevant Emacs info node."
  (interactive)
  (if (eq mlgud-minor-mode 'gdbmi)
      (info-other-window "(emacs)GDB Graphical Interface")
    (info-other-window "(emacs)Debuggers")))

(defun mlgud-tool-bar-item-visible-no-fringe ()
  (not (or (eq (buffer-local-value 'major-mode (window-buffer)) 'speedbar-mode)
	   (eq (buffer-local-value 'major-mode (window-buffer)) 'gdb-memory-mode)
	   (and (eq mlgud-minor-mode 'gdbmi)
		(> (car (window-fringes)) 0)))))

(declare-function gdb-gud-context-command "gdb-mi.el")

(defun mlgud-stop-subjob ()
  (interactive)
  (with-current-buffer mlgud-comint-buffer
    (cond ((string-equal mlgud-target-name "emacs")
           (comint-stop-subjob))
          ((eq mlgud-minor-mode 'jdb)
           (mlgud-call "suspend"))
          ((eq mlgud-minor-mode 'gdbmi)
           (mlgud-call (gdb-gud-context-command "-exec-interrupt")))
          (t
           (comint-interrupt-subjob)))))

(defvar mlgud-tool-bar-map
  (let ((map (make-sparse-keymap)))
    (dolist (x '((mlgud-break . "gud/break")
		 (mlgud-remove . "gud/remove")
		 (mlgud-print . "gud/print")
		 (mlgud-pstar . "gud/pstar")
		 (mlgud-pp . "gud/pp")
		 (mlgud-watch . "gud/watch")
		 (mlgud-run . "gud/run")
		 (mlgud-go . "gud/go")
		 (mlgud-stop-subjob . "gud/stop")
		 (mlgud-cont . "gud/cont")
		 (mlgud-until . "gud/until")
		 (mlgud-next . "gud/next")
		 (mlgud-step . "gud/step")
		 (mlgud-finish . "gud/finish")
		 (mlgud-nexti . "gud/nexti")
		 (mlgud-stepi . "gud/stepi")
		 (mlgud-up . "gud/up")
		 (mlgud-down . "gud/down")
		 (mlgud-goto-info . "info"))
	       map)
      (tool-bar-local-item-from-menu
       (car x) (cdr x) map))))

(defun mlgud-file-name (f)
  "Transform a relative file name to an absolute file name.
Uses `mlgud-<MINOR-MODE>-directories' to find the source files."
  ;; When `default-directory' is a remote file name, prepend its
  ;; remote part to f, which is the local file name.  Fortunately,
  ;; `file-remote-p' returns exactly this remote file name part (or
  ;; nil otherwise).
  (setq f (concat (or (file-remote-p default-directory) "") f))
  (if (file-exists-p f) (expand-file-name f)
    (let ((directories (mlgud-val 'directories))
	  (result nil))
      (while directories
	(let ((path (expand-file-name f (car directories))))
	  (if (file-exists-p path)
	      (setq result path
		    directories nil)))
	(setq directories (cdr directories)))
      result)))

(declare-function gdb-create-define-alist "gdb-mi" ())

(defun mlgud-find-file (file)
  ;; Don't get confused by double slashes in the name that comes from GDB.
  (while (string-match "//+" file)
    (setq file (replace-match "/" t t file)))
  (let ((minor-mode mlgud-minor-mode)
	(buf (funcall (or mlgud-find-file 'mlgud-file-name) file)))
    (when (stringp buf)
      (setq buf (and (file-readable-p buf) (find-file-noselect buf 'nowarn))))
    (when buf
      ;; Copy `mlgud-minor-mode' to the found buffer to turn on the menu.
      (with-current-buffer buf
	(setq-local mlgud-minor-mode minor-mode)
	(if (boundp 'tool-bar-map)      ; not --without-x
	    (setq-local tool-bar-map mlgud-tool-bar-map))
	(when (and mlgud-tooltip-mode
		   (eq mlgud-minor-mode 'gdbmi))
	  (make-local-variable 'gdb-define-alist)
	  (unless  gdb-define-alist (gdb-create-define-alist))
	  (add-hook 'after-save-hook 'gdb-create-define-alist nil t))
	(make-local-variable 'mlgud-keep-buffer))
      buf)))

;; ======================================================================
;; command definition

;; This macro is used below to define some basic debugger interface commands.
;; Of course you may use `mlgud-def' with any other debugger command, including
;; user defined ones.

;; A macro call like (mlgud-def FUNC CMD KEY DOC) expands to a form
;; which defines FUNC to send the command CMD to the debugger, gives
;; it the docstring DOC, and binds that function to KEY in the MLGUD
;; major mode.  The function is also bound in the global keymap with the
;; MLGUD prefix.

(defmacro mlgud-def (func cmd &optional doc)
  "Define FUNC to be a command sending CMD, with
optional doc string DOC.  Certain %-escapes in the string arguments
are interpreted specially if present.  These are:

  %f -- Name (without directory) of current source file.
  %F -- Name (without directory or extension) of current source file.
  %d -- Directory of current source file.
  %l -- Number of current source line.
  %e -- Text of the C lvalue or function-call expression surrounding point.
  %a -- Text of the hexadecimal address surrounding point.
  %p -- Prefix argument to the command (if any) as a number.
  %c -- Fully qualified class name derived from the expression
        surrounding point (jdb only).

  The `current' source file is the file of the current buffer (if
we're in a C file) or the source file current at the last break or
step (if we're in the MLGUD buffer).
  The `current' line is that of the current buffer (if we're in a
source file) or the source line number at the last break or step (if
we're in the MLGUD buffer)."
  `(progn
     (defalias ',func (lambda (arg)
       ,@(if doc (list doc))
       (interactive "p")
       (if (not mlgud-running)
	 ,(if (stringp cmd)
	      `(mlgud-call ,cmd arg)
	    cmd))))
     ))

;; Where mlgud-display-frame should put the debugging arrow; a cons of
;; (filename . line-number).  This is set by the marker-filter, which scans
;; the debugger's output for indications of the current program counter.
(defvar mlgud-last-frame nil)

;; Used by mlgud-refresh, which should cause mlgud-display-frame to redisplay
;; the last frame, even if it's been called before and mlgud-last-frame has
;; been set to nil.
(defvar mlgud-last-last-frame nil)

;; All debugger-specific information is collected here.
;; Here's how it works, in case you ever need to add a debugger to the mode.
;;
;; Each entry must define the following at startup:
;;
;;<name>
;; comint-prompt-regexp
;; mlgud-<name>-massage-args
;; mlgud-<name>-marker-filter
;; mlgud-<name>-find-file
;;
;; The job of the massage-args method is to modify the given list of
;; debugger arguments before running the debugger.
;;
;; The job of the marker-filter method is to detect file/line markers in
;; strings and set the global mlgud-last-frame to indicate what display
;; action (if any) should be triggered by the marker.  Note that only
;; whatever the method *returns* is displayed in the buffer; thus, you
;; can filter the debugger's output, interpreting some and passing on
;; the rest.
;;
;; The job of the find-file method is to visit and return the buffer indicated
;; by the car of mlgud-tag-frame.  This may be a file name, a tag name, or
;; something else.

;; ======================================================================
;; speedbar support functions and variables.
(eval-when-compile (require 'dframe)) ; for dframe-with-attached-buffer

(defvar mlgud-last-speedbar-stackframe nil
  "Description of the currently displayed MLGUD stack.
The value t means that there is no stack, and we are in display-file mode.")

(defvar mlgud-speedbar-key-map nil
  "Keymap used when in the buffers display mode.")

;; At runtime, will be pulled in as a require of speedbar.
(declare-function dframe-message "dframe" (fmt &rest args))

(defun mlgud-speedbar-item-info ()
  "Display the data type of the watch expression element."
  (let ((var (nth (- (line-number-at-pos (point)) 2) gdb-var-list)))
    (if (nth 7 var)
	(dframe-message "%s: %s" (nth 7 var) (nth 3 var))
      (dframe-message "%s" (nth 3 var)))))

(declare-function speedbar-make-specialized-keymap "speedbar" ())
(declare-function speedbar-add-expansion-list "speedbar" (new-list))
(defvar speedbar-mode-functions-list)

(defun mlgud-install-speedbar-variables ()
  "Install those variables used by speedbar to enhance mlgud/gdb."
  (unless mlgud-speedbar-key-map
    (setq mlgud-speedbar-key-map (speedbar-make-specialized-keymap))
    (define-key mlgud-speedbar-key-map "j" 'speedbar-edit-line)
    (define-key mlgud-speedbar-key-map "e" 'speedbar-edit-line)
    (define-key mlgud-speedbar-key-map "\C-m" 'speedbar-edit-line)
    (define-key mlgud-speedbar-key-map " " 'speedbar-toggle-line-expansion)
    (define-key mlgud-speedbar-key-map "D" 'gdb-var-delete)
    (define-key mlgud-speedbar-key-map "p" 'mlgud-pp))

  (speedbar-add-expansion-list '("mlMLGUD" mlgud-speedbar-menu-items
				 mlgud-speedbar-key-map
				 mlgud-expansion-speedbar-buttons))

  (add-to-list
   'speedbar-mode-functions-list
   '("mlMLGUD" (speedbar-item-info . mlgud-speedbar-item-info)
     (speedbar-line-directory . ignore))))

(defvar mlgud-speedbar-menu-items
  '(["Jump to stack frame" speedbar-edit-line
     :visible (not (eq (buffer-local-value 'mlgud-minor-mode mlgud-comint-buffer)
		    'gdbmi))]
    ["Edit value" speedbar-edit-line
     :visible (eq (buffer-local-value 'mlgud-minor-mode mlgud-comint-buffer)
		    'gdbmi)]
    ["Delete expression" gdb-var-delete
     :visible (eq (buffer-local-value 'mlgud-minor-mode mlgud-comint-buffer)
		    'gdbmi)]
    ["Auto raise frame" gdb-speedbar-auto-raise
     :style toggle :selected gdb-speedbar-auto-raise
     :visible (eq (buffer-local-value 'mlgud-minor-mode mlgud-comint-buffer)
		    'gdbmi)]
    ("Output Format"
     :visible (eq (buffer-local-value 'mlgud-minor-mode mlgud-comint-buffer)
		    'gdbmi)
     ["Binary" (gdb-var-set-format "binary") t]
     ["Natural" (gdb-var-set-format  "natural") t]
     ["Hexadecimal" (gdb-var-set-format "hexadecimal") t]))
  "Additional menu items to add to the speedbar frame.")

;; Make sure our special speedbar mode is loaded
(if (featurep 'speedbar)
    (mlgud-install-speedbar-variables)
  (add-hook 'speedbar-load-hook 'mlgud-install-speedbar-variables))

(defun mlgud-expansion-speedbar-buttons (_directory _zero)
  "Wrapper for call to `speedbar-add-expansion-list'.
DIRECTORY and ZERO are not used, but are required by the caller."
  (mlgud-speedbar-buttons mlgud-comint-buffer))

(declare-function speedbar-make-tag-line "speedbar"
                  (type char func data tag tfunc tdata tface depth))
(declare-function speedbar-remove-localized-speedbar-support "speedbar"
                  (buffer))
(declare-function speedbar-insert-button "speedbar"
		  (text face mouse function &optional token prevline))

(defun mlgud-speedbar-buttons (buffer)
  "Create a speedbar display based on the current state of MLGUD.
If the MLGUD BUFFER is not running a supported debugger, then turn
off the specialized speedbar mode.  BUFFER is not used, but is
required by the caller."
  (when (and mlgud-comint-buffer
	     ;; mlgud-comint-buffer might be killed
	     (buffer-name mlgud-comint-buffer))
    (let* ((minor-mode (with-current-buffer buffer mlgud-minor-mode))
	  (window (get-buffer-window (current-buffer) 0))
	  (start (window-start window))
	  (p (window-point window)))
      (cond
       ((eq minor-mode 'gdbmi)
	(erase-buffer)
	(insert "Watch Expressions:\n")
	(let ((var-list gdb-var-list) parent)
	  (while var-list
	    (let* (char (depth 0) (start 0) (var (car var-list))
			(varnum (car var)) (expr (nth 1 var))
			(type (if (nth 3 var) (nth 3 var) " "))
			(value (nth 4 var)) (status (nth 5 var))
			(has-more (nth 6 var)))
	      (put-text-property
	       0 (length expr) 'face font-lock-variable-name-face expr)
	      (put-text-property
	       0 (length type) 'face font-lock-type-face type)
	      (while (string-match "\\." varnum start)
		(setq depth (1+ depth)
		      start (1+ (match-beginning 0))))
	      (if (eq depth 0) (setq parent nil))
	      (if (and (or (not has-more) (string-equal has-more "0"))
		       (or (equal (nth 2 var) "0")
			   (and (equal (nth 2 var) "1")
			   (string-match "char \\*$" type)) ))
		  (speedbar-make-tag-line
		   'bracket ?? nil nil
		   (concat expr "\t" value)
		   (if (or parent (eq status 'out-of-scope))
		       nil 'gdb-edit-value)
		   nil
		   (if gdb-show-changed-values
		       (or parent (pcase status
				    (`changed 'font-lock-warning-face)
				    (`out-of-scope 'shadow)
				    (_ t)))
		     t)
		   depth)
		(if (eq status 'out-of-scope) (setq parent 'shadow))
		(if (and (nth 1 var-list)
			 (string-match (concat varnum "\\.")
				       (car (nth 1 var-list))))
		    (setq char ?-)
		  (setq char ?+))
		(if (string-match "\\*$\\|\\*&$" type)
		    (speedbar-make-tag-line
		     'bracket char
		     'gdb-speedbar-expand-node varnum
		     (concat expr "\t" type "\t" value)
		     (if (or parent (eq status 'out-of-scope))
			 nil 'gdb-edit-value)
		     nil
		     (if gdb-show-changed-values
			 (or parent (pcase status
				      (`changed 'font-lock-warning-face)
				      (`out-of-scope 'shadow)
				      (_ t)))
		       t)
		     depth)
		  (speedbar-make-tag-line
		   'bracket char
		   'gdb-speedbar-expand-node varnum
		   (concat expr "\t" type)
		   nil nil
		   (if (and (or parent status) gdb-show-changed-values)
		       'shadow t)
		   depth))))
	    (setq var-list (cdr var-list)))))
       (t (unless (and (save-excursion
			 (goto-char (point-min))
			 (looking-at "Current Stack:"))
		       (equal mlgud-last-last-frame mlgud-last-speedbar-stackframe))
	    (let ((mlgud-frame-list
	    (cond 		  ;; Add more debuggers here!
		  (t (speedbar-remove-localized-speedbar-support buffer)
		     nil))))
	      (erase-buffer)
	      (if (not mlgud-frame-list)
		  (insert "No Stack frames\n")
		(insert "Current Stack:\n"))
	      (dolist (frame mlgud-frame-list)
		(insert (nth 1 frame) ":\n")
		(if (= (length frame) 2)
		(progn
		  (speedbar-insert-button (car frame)
					  'speedbar-directory-face
					  nil nil nil t))
		(speedbar-insert-button
		 (car frame)
		 'speedbar-file-face
		 'speedbar-highlight-face
		 (cond ((memq minor-mode '(gdbmi gdb))
			'mlgud-gdb-goto-stackframe)
		       (t (error "Should never be here")))
		 frame t))))
	    (setq mlgud-last-speedbar-stackframe mlgud-last-last-frame))))
      (set-window-start window start)
      (set-window-point window p))))


;; When we send a command to the debugger via mlgud-call, it's annoying
;; to see the command and the new prompt inserted into the debugger's
;; buffer; we have other ways of knowing the command has completed.
;;
;; If the buffer looks like this:
;; --------------------
;; (gdb) set args foo bar
;; (gdb) -!-
;; --------------------
;; (the -!- marks the location of point), and we type `C-x SPC' in a
;; source file to set a breakpoint, we want the buffer to end up like
;; this:
;; --------------------
;; (gdb) set args foo bar
;; Breakpoint 1 at 0x92: file make-docfile.c, line 49.
;; (gdb) -!-
;; --------------------
;; Essentially, the old prompt is deleted, and the command's output
;; and the new prompt take its place.
;;
;; Not echoing the command is easy enough; you send it directly using
;; process-send-string, and it never enters the buffer.  However,
;; getting rid of the old prompt is trickier; you don't want to do it
;; when you send the command, since that will result in an annoying
;; flicker as the prompt is deleted, redisplay occurs while Emacs
;; waits for a response from the debugger, and the new prompt is
;; inserted.  Instead, we'll wait until we actually get some output
;; from the subprocess before we delete the prompt.  If the command
;; produced no output other than a new prompt, that prompt will most
;; likely be in the first chunk of output received, so we will delete
;; the prompt and then replace it with an identical one.  If the
;; command produces output, the prompt is moving anyway, so the
;; flicker won't be annoying.
;;
;; So - when we want to delete the prompt upon receipt of the next
;; chunk of debugger output, we position mlgud-delete-prompt-marker at
;; the start of the prompt; the process filter will notice this, and
;; delete all text between it and the process output marker.  If
;; mlgud-delete-prompt-marker points nowhere, we leave the current
;; prompt alone.
(defvar mlgud-delete-prompt-marker nil)


(put 'mlgud-mode 'mode-class 'special)

(define-derived-mode mlgud-mode comint-mode "Debugger"
  "Major mode for interacting with an inferior debugger process.

   You start it up with one of the commands M-x gdb, M-x sdb, M-x dbx,
M-x perldb, M-x xdb, or M-x jdb.  Each entry point finishes by executing a
hook; `gdb-mode-hook', `sdb-mode-hook', `dbx-mode-hook',
`perldb-mode-hook', `xdb-mode-hook', or `jdb-mode-hook' respectively.

After startup, the following commands are available in both the MLGUD
interaction buffer and any source buffer MLGUD visits due to a breakpoint stop
or step operation:

\\[mlgud-break] sets a breakpoint at the current file and line.  In the
MLGUD buffer, the current file and line are those of the last breakpoint or
step.  In a source buffer, they are the buffer's file and current line.

\\[mlgud-remove] removes breakpoints on the current file and line.

\\[mlgud-refresh] displays in the source window the last line referred to
in the mlgud buffer.

\\[mlgud-step], \\[mlgud-next], and \\[mlgud-stepi] do a step-one-line,
step-one-line (not entering function calls), and step-one-instruction
and then update the source window with the current file and position.
\\[mlgud-cont] continues execution.

\\[mlgud-print] tries to find the largest C lvalue or function-call expression
around point, and sends it to the debugger for value display.

The above commands are common to all supported debuggers except xdb which
does not support stepping instructions.

Under gdb, sdb and xdb, \\[mlgud-tbreak] behaves exactly like \\[mlgud-break],
except that the breakpoint is temporary; that is, it is removed when
execution stops on it.

Under gdb, dbx, and xdb, \\[mlgud-up] pops up through an enclosing stack
frame.  \\[mlgud-down] drops back down through one.

If you are using gdb or xdb, \\[mlgud-finish] runs execution to the return from
the current function and stops.

All the keystrokes above are accessible in the MLGUD buffer
with the prefix C-c, and in all buffers through the prefix C-x C-a.

All pre-defined functions for which the concept make sense repeat
themselves the appropriate number of times if you give a prefix
argument.

You may use the `mlgud-def' macro in the initialization hook to define other
commands.

Other commands for interacting with the debugger process are inherited from
comint mode, which see."
  (setq mode-line-process '(":%s"))
  (define-key (current-local-map) "\C-c\C-l" 'mlgud-refresh)
  (set (make-local-variable 'mlgud-last-frame) nil)
  (if (boundp 'tool-bar-map)            ; not --without-x
      (setq-local tool-bar-map mlgud-tool-bar-map))
  (make-local-variable 'comint-prompt-regexp)
  ;; Don't put repeated commands in command history many times.
  (set (make-local-variable 'comint-input-ignoredups) t)
  (make-local-variable 'paragraph-start)
  (set (make-local-variable 'mlgud-delete-prompt-marker) (make-marker))
  (add-hook 'kill-buffer-hook 'mlgud-kill-buffer-hook nil t))

(defun mlgud-set-buffer ()
  (when (derived-mode-p 'mlgud-mode)
    (setq mlgud-comint-buffer (current-buffer))))

(defvar mlgud-filter-defer-flag nil
  "Non-nil means don't process anything from the debugger right now.
It is saved for when this flag is not set.")

;; These functions are responsible for inserting output from your debugger
;; into the buffer.  The hard work is done by the method that is
;; the value of mlgud-marker-filter.


(defvar mlgud-filter-pending-text nil
  "Non-nil means this is text that has been saved for later in `mlgud-filter'.")

(defun mlgud-filter (proc string)
  ;; Here's where the actual buffer insertion is done
  (let (output process-window)
    (if (buffer-name (process-buffer proc))
	(if mlgud-filter-defer-flag
	    ;; If we can't process any text now,
	    ;; save it for later.
	    (setq mlgud-filter-pending-text
		  (concat (or mlgud-filter-pending-text "") string))

	  ;; If we have to ask a question during the processing,
	  ;; defer any additional text that comes from the debugger
	  ;; during that time.
	  (let ((mlgud-filter-defer-flag t))
	    ;; Process now any text we previously saved up.
	    (if mlgud-filter-pending-text
		(setq string (concat mlgud-filter-pending-text string)
		      mlgud-filter-pending-text nil))

	    (with-current-buffer (process-buffer proc)
	      ;; If we have been so requested, delete the debugger prompt.
	      (save-restriction
		(widen)
		(if (marker-buffer mlgud-delete-prompt-marker)
		    (let ((inhibit-read-only t))
		      (delete-region (process-mark proc)
				     mlgud-delete-prompt-marker)
		      (comint-update-fence)
		      (set-marker mlgud-delete-prompt-marker nil)))
		;; Save the process output, checking for source file markers.
		(setq output (mlgud-marker-filter string))
		;; Check for a filename-and-line number.
		;; Don't display the specified file
		;; unless (1) point is at or after the position where output appears
		;; and (2) this buffer is on the screen.
		(setq process-window
		      (and mlgud-last-frame
			   (>= (point) (process-mark proc))
			   (get-buffer-window (current-buffer)))))

	      ;; Let the comint filter do the actual insertion.
	      ;; That lets us inherit various comint features.
	      (comint-output-filter proc output))

	    ;; Put the arrow on the source line.
	    ;; This must be outside of the save-excursion
	    ;; in case the source file is our current buffer.
	    (if process-window
		(with-selected-window process-window
		  (mlgud-display-frame))
	      ;; We have to be in the proper buffer, (process-buffer proc),
	      ;; but not in a save-excursion, because that would restore point.
	      (with-current-buffer (process-buffer proc)
		(mlgud-display-frame))))

	  ;; If we deferred text that arrived during this processing,
	  ;; handle it now.
	  (if mlgud-filter-pending-text
	      (mlgud-filter proc ""))))))

(defvar mlgud-minor-mode-type nil)
(defvar mlgud-overlay-arrow-position nil)
(add-to-list 'overlay-arrow-variable-list 'mlgud-overlay-arrow-position)

(declare-function gdb-reset "gdb-mi" ())
(declare-function speedbar-change-initial-expansion-list "speedbar" (new))
(defvar speedbar-previously-used-expansion-list-name)

(defun mlgud-sentinel (proc msg)
  (cond ((null (buffer-name (process-buffer proc)))
	 ;; buffer killed
	 ;; Stop displaying an arrow in a source file.
	 (setq mlgud-overlay-arrow-position nil)
	 (set-process-buffer proc nil)
	 (if (and (boundp 'speedbar-initial-expansion-list-name)
		  (string-equal speedbar-initial-expansion-list-name "mlMLGUD"))
	     (speedbar-change-initial-expansion-list
	      speedbar-previously-used-expansion-list-name))
	 (if (eq mlgud-minor-mode-type 'gdbmi)
	     (gdb-reset)
	   (mlgud-reset)))
	((memq (process-status proc) '(signal exit))
	 ;; Stop displaying an arrow in a source file.
	 (setq mlgud-overlay-arrow-position nil)
	 (if (eq (buffer-local-value 'mlgud-minor-mode mlgud-comint-buffer)
		   'gdbmi)
	     (gdb-reset)
	   (mlgud-reset))
	 (let* ((obuf (current-buffer)))
	   ;; save-excursion isn't the right thing if
	   ;;  process-buffer is current-buffer
	   (unwind-protect
	       (progn
		 ;; Write something in the MLGUD buffer and hack its mode line,
		 (set-buffer (process-buffer proc))
		 ;; Fix the mode line.
		 (setq mode-line-process
		       (concat ":"
			       (symbol-name (process-status proc))))
		 (force-mode-line-update)
		 (if (eobp)
		     (insert ?\n mode-name " " msg)
		   (save-excursion
		     (goto-char (point-max))
		     (insert ?\n mode-name " " msg)))
		 ;; If buffer and mode line will show that the process
		 ;; is dead, we can delete it now.  Otherwise it
		 ;; will stay around until M-x list-processes.
		 (delete-process proc))
	     ;; Restore old buffer, but don't restore old point
	     ;; if obuf is the mlgud buffer.
	     (set-buffer obuf))))))

(defun mlgud-kill-buffer-hook ()
  (setq mlgud-minor-mode-type mlgud-minor-mode)
  (condition-case nil
      (progn
	(kill-process (get-buffer-process (current-buffer)))
	(delete-process (get-process "gdb-inferior")))
    (error nil)))

(defun mlgud-reset ()
  (dolist (buffer (buffer-list))
    (unless (eq buffer mlgud-comint-buffer)
      (with-current-buffer buffer
	(when mlgud-minor-mode
	  (setq mlgud-minor-mode nil)
	  (kill-local-variable 'tool-bar-map))))))

(defun mlgud-display-frame ()
  "Find and obey the last filename-and-line marker from the debugger.
Obeying it means displaying in another window the specified file and line."
  (interactive)
  (when mlgud-last-frame
    (mlgud-set-buffer)
    (mlgud-display-line (car mlgud-last-frame) (cdr mlgud-last-frame))
    (setq mlgud-last-last-frame mlgud-last-frame
	  mlgud-last-frame nil)))

(declare-function global-hl-line-highlight  "hl-line" ())
(declare-function hl-line-highlight         "hl-line" ())
(declare-function gdb-display-source-buffer "gdb-mi"  (buffer))

;; Make sure the file named TRUE-FILE is in a buffer that appears on the screen
;; and that its line LINE is visible.
;; Put the overlay-arrow on the line LINE in that buffer.
;; Most of the trickiness in here comes from wanting to preserve the current
;; region-restriction if that's possible.  We use an explicit display-buffer
;; to get around the fact that this is called inside a save-excursion.

(defun mlgud-display-line (true-file line)
  (let* ((last-nonmenu-event t)	 ; Prevent use of dialog box for questions.
	 (buffer
	  (with-current-buffer mlgud-comint-buffer
	    (mlgud-find-file true-file)))
	 (window (and buffer
		      (or (get-buffer-window buffer)
			  (display-buffer buffer))))
	 (pos))
    (when buffer
      (with-current-buffer buffer
	(unless (or (verify-visited-file-modtime buffer) mlgud-keep-buffer)
	  (if (yes-or-no-p
	       (format "File %s changed on disk.  Reread from disk? "
		       (buffer-name)))
	      (revert-buffer t t)
	    (setq mlgud-keep-buffer t)))
	(save-restriction
	  (widen)
	  (goto-char (point-min))
	  (forward-line (1- line))
	  (setq pos (point))
	  (or mlgud-overlay-arrow-position
	      (setq mlgud-overlay-arrow-position (make-marker)))
	  (set-marker mlgud-overlay-arrow-position (point) (current-buffer))
	  ;; If they turned on hl-line, move the hl-line highlight to
	  ;; the arrow's line.
	  (when (featurep 'hl-line)
	    (cond
	     (global-hl-line-mode
	      (global-hl-line-highlight))
	     ((and hl-line-mode hl-line-sticky-flag)
	      (hl-line-highlight)))))
	(cond ((or (< pos (point-min)) (> pos (point-max)))
	       (widen)
	       (goto-char pos))))
      (when window
	(set-window-point window mlgud-overlay-arrow-position)
	(if (eq mlgud-minor-mode 'gdbmi)
	    (setq gdb-source-window window))))))

;; The mlgud-call function must do the right thing whether its invoking
;; keystroke is from the MLGUD buffer itself (via major-mode binding)
;; or a C buffer.  In the former case, we want to supply data from
;; mlgud-last-frame.  Here's how we do it:

(defun mlgud-format-command (str arg)
  (let ((insource (not (eq (current-buffer) mlgud-comint-buffer)))
	(frame (or mlgud-last-frame mlgud-last-last-frame))
	result)
    (while (and str
		(let ((case-fold-search nil))
		  (string-match "\\([^%]*\\)%\\([adefFlpc]\\)" str)))
      (let ((key (string-to-char (match-string 2 str)))
	    subst)
	(cond
	 ((eq key ?f)
	  (setq subst (file-name-nondirectory (if insource
						  (buffer-file-name)
						(car frame)))))
	 ((eq key ?F)
	  (setq subst (file-name-base (if insource
                                          (buffer-file-name)
                                        (car frame)))))
	 ((eq key ?d)
	  (setq subst (file-name-directory (if insource
					       (buffer-file-name)
					     (car frame)))))
	 ((eq key ?l)
	  (setq subst (int-to-string
		       (if insource
			   (save-restriction
			     (widen)
			     (+ (count-lines (point-min) (point))
				(if (bolp) 1 0)))
			 (cdr frame)))))
	 ((eq key ?e)
	  (setq subst (mlgud-find-expr)))
	 ((eq key ?a)
	  (setq subst (mlgud-read-address)))

	 ((eq key ?p)
	  (setq subst (if arg (int-to-string arg)))))
	(setq result (concat result (match-string 1 str) subst)))
      (setq str (substring str (match-end 2))))
    ;; There might be text left in STR when the loop ends.
    (concat result str)))

(defun mlgud-read-address ()
  "Return a string containing the core-address found in the buffer at point."
  (save-match-data
    (save-excursion
      (let ((pt (point)) found begin)
	(setq found (if (search-backward "0x" (- pt 7) t) (point)))
	(cond
	 (found (forward-char 2)
		(buffer-substring found
				  (progn (re-search-forward "[^0-9a-f]")
					 (forward-char -1)
					 (point))))
	 (t (setq begin (progn (re-search-backward "[^0-9]")
			       (forward-char 1)
			       (point)))
	    (forward-char 1)
	    (re-search-forward "[^0-9]")
	    (forward-char -1)
	    (buffer-substring begin (point))))))))

(defun mlgud-call (fmt &optional arg)
  (let ((msg (mlgud-format-command fmt arg)))
    (message "Command: %s" msg)
    (sit-for 0)
    (mlgud-basic-call msg)))

(defun mlgud-basic-call (command)
  "Invoke the debugger COMMAND displaying source in other window."
  (interactive)
  (mlgud-set-buffer)
  (let ((proc (get-buffer-process mlgud-comint-buffer)))
    (or proc (error "Current buffer has no process"))
    ;; Arrange for the current prompt to get deleted.
    (with-current-buffer mlgud-comint-buffer
      (save-excursion
        (save-restriction
          (widen)
          (if (marker-position mlgud-delete-prompt-marker)
              ;; We get here when printing an expression.
              (goto-char mlgud-delete-prompt-marker)
            (goto-char (process-mark proc))
            (forward-line 0))
          (if (looking-at comint-prompt-regexp)
              (set-marker mlgud-delete-prompt-marker (point)))
          (if (eq mlgud-minor-mode 'gdbmi)
              (apply comint-input-sender (list proc command))
            (process-send-string proc (concat command "\n"))))))))

(defun mlgud-refresh (&optional arg)
  "Fix up a possibly garbled display, and redraw the arrow."
  (interactive "P")
  (or mlgud-last-frame (setq mlgud-last-frame mlgud-last-last-frame))
  (mlgud-display-frame)
  (recenter arg))

;; Code for parsing expressions out of C or Fortran code.  The single entry
;; point is mlgud-find-expr, which tries to return an lvalue expression from
;; around point.

(defvar mlgud-find-expr-function 'mlgud-find-c-expr)

(defun mlgud-find-expr (&rest args)
  (let ((expr (if (and transient-mark-mode mark-active)
		  (buffer-substring (region-beginning) (region-end))
		(apply mlgud-find-expr-function args))))
    (save-match-data
      (if (string-match "\n" expr)
	  (error "Expression must not include a newline"))
      (with-current-buffer mlgud-comint-buffer
	(save-excursion
	  (goto-char (process-mark (get-buffer-process mlgud-comint-buffer)))
	  (forward-line 0)
	  (when (looking-at comint-prompt-regexp)
	    (set-marker mlgud-delete-prompt-marker (point))
	    (set-marker-insertion-type mlgud-delete-prompt-marker t))
	  (unless (eq (buffer-local-value 'mlgud-minor-mode mlgud-comint-buffer)
		      'jdb)
	    (insert (concat  expr " = "))))))
    expr))

;; The next eight functions are hacked from gdbsrc.el by
;; Debby Ayers <ayers@asc.slb.com>,
;; Rich Schaefer <schaefer@asc.slb.com> Schlumberger, Austin, Tx.

(defun mlgud-find-c-expr ()
  "Returns the expr that surrounds point."
  (interactive)
  (save-excursion
    (let ((p (point))
	  (expr (mlgud-innermost-expr))
	  (test-expr (mlgud-prev-expr)))
      (while (and test-expr (mlgud-expr-compound test-expr expr))
	(let ((prev-expr expr))
	  (setq expr (cons (car test-expr) (cdr expr)))
	  (goto-char (car expr))
	  (setq test-expr (mlgud-prev-expr))
	  ;; If we just pasted on the condition of an if or while,
	  ;; throw it away again.
	  (if (member (buffer-substring (car test-expr) (cdr test-expr))
		      '("if" "while" "for"))
	      (setq test-expr nil
		    expr prev-expr))))
      (goto-char p)
      (setq test-expr (mlgud-next-expr))
      (while (mlgud-expr-compound expr test-expr)
	(setq expr (cons (car expr) (cdr test-expr)))
	(setq test-expr (mlgud-next-expr)))
      (buffer-substring (car expr) (cdr expr)))))

(defun mlgud-innermost-expr ()
  "Returns the smallest expr that point is in; move point to beginning of it.
The expr is represented as a cons cell, where the car specifies the point in
the current buffer that marks the beginning of the expr and the cdr specifies
the character after the end of the expr."
  (let ((p (point)) begin end)
    (mlgud-backward-sexp)
    (setq begin (point))
    (mlgud-forward-sexp)
    (setq end (point))
    (if (>= p end)
	(progn
	 (setq begin p)
	 (goto-char p)
	 (mlgud-forward-sexp)
	 (setq end (point)))
      )
    (goto-char begin)
    (cons begin end)))

(defun mlgud-backward-sexp ()
  "Version of `backward-sexp' that catches errors."
  (condition-case nil
      (backward-sexp)
    (error t)))

(defun mlgud-forward-sexp ()
  "Version of `forward-sexp' that catches errors."
  (condition-case nil
     (forward-sexp)
    (error t)))

(defun mlgud-prev-expr ()
  "Returns the previous expr, point is set to beginning of that expr.
The expr is represented as a cons cell, where the car specifies the point in
the current buffer that marks the beginning of the expr and the cdr specifies
the character after the end of the expr"
  (let ((begin) (end))
    (mlgud-backward-sexp)
    (setq begin (point))
    (mlgud-forward-sexp)
    (setq end (point))
    (goto-char begin)
    (cons begin end)))

(defun mlgud-next-expr ()
  "Returns the following expr, point is set to beginning of that expr.
The expr is represented as a cons cell, where the car specifies the point in
the current buffer that marks the beginning of the expr and the cdr specifies
the character after the end of the expr."
  (let ((begin) (end))
    (mlgud-forward-sexp)
    (mlgud-forward-sexp)
    (setq end (point))
    (mlgud-backward-sexp)
    (setq begin (point))
    (cons begin end)))

(defun mlgud-expr-compound-sep (span-start span-end)
  "Scan from SPAN-START to SPAN-END for punctuation characters.
If `->' is found, return `?.'.  If `.' is found, return `?.'.
If any other punctuation is found, return `??'.
If no punctuation is found, return `? '."
  (let ((result ?\s)
	(syntax))
    (while (< span-start span-end)
      (setq syntax (char-syntax (char-after span-start)))
      (cond
       ((= syntax ?\s) t)
       ((= syntax ?.) (setq syntax (char-after span-start))
	(cond
	 ((= syntax ?.) (setq result ?.))
	 ((and (= syntax ?-) (= (char-after (+ span-start 1)) ?>))
	  (setq result ?.)
	  (setq span-start (+ span-start 1)))
	 (t (setq span-start span-end)
	    (setq result ??)))))
      (setq span-start (+ span-start 1)))
    result))

(defun mlgud-expr-compound (first second)
  "Non-nil if concatenating FIRST and SECOND makes a single C expression.
The two exprs are represented as a cons cells, where the car
specifies the point in the current buffer that marks the beginning of the
expr and the cdr specifies the character after the end of the expr.
Link exprs of the form:
      Expr -> Expr
      Expr . Expr
      Expr (Expr)
      Expr [Expr]
      (Expr) Expr
      [Expr] Expr"
  (let ((span-start (cdr first))
	(span-end (car second))
	(syntax))
    (setq syntax (mlgud-expr-compound-sep span-start span-end))
    (cond
     ((= (car first) (car second)) nil)
     ((= (cdr first) (cdr second)) nil)
     ((= syntax ?.) t)
     ((= syntax ?\s)
      (setq span-start (char-after (- span-start 1)))
      (setq span-end (char-after span-end))
      (cond
       ((= span-start ?\)) t)
      ((= span-start ?\]) t)
     ((= span-end ?\() t)
      ((= span-end ?\[) t)
       (t nil)))
     (t nil))))




;;; tooltips for MLGUD

;;; Customizable settings

(defvar tooltip-mode)

;;;###autoload
(define-minor-mode mlgud-tooltip-mode
  "Toggle the display of MLGUD tooltips.
With a prefix argument ARG, enable the feature if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
it if ARG is omitted or nil."
  :global t
  :group 'mlgud
  :group 'tooltip
  (require 'tooltip)
  (if mlgud-tooltip-mode
      (progn
	(add-hook 'change-major-mode-hook 'mlgud-tooltip-change-major-mode)
	(add-hook 'pre-command-hook 'tooltip-hide)
	(add-hook 'tooltip-functions 'mlgud-tooltip-tips)
	(define-key global-map [mouse-movement] 'mlgud-tooltip-mouse-motion))
    (unless tooltip-mode (remove-hook 'pre-command-hook 'tooltip-hide)
    (remove-hook 'change-major-mode-hook 'mlgud-tooltip-change-major-mode)
    (remove-hook 'tooltip-functions 'mlgud-tooltip-tips)
    (define-key global-map [mouse-movement] 'ignore)))
  (mlgud-tooltip-activate-mouse-motions-if-enabled)
  (if (and mlgud-comint-buffer
	   (buffer-name mlgud-comint-buffer); mlgud-comint-buffer might be killed
	   (eq (buffer-local-value 'mlgud-minor-mode mlgud-comint-buffer)
		 'gdbmi))
      (if mlgud-tooltip-mode
	  (progn
	    (dolist (buffer (buffer-list))
	      (unless (eq buffer mlgud-comint-buffer)
		(with-current-buffer buffer
		  (when (and (eq mlgud-minor-mode 'gdbmi)
			     (not (string-match "\\`\\*.+\\*\\'"
						(buffer-name))))
		    (make-local-variable 'gdb-define-alist)
		    (gdb-create-define-alist)
		    (add-hook 'after-save-hook
			      'gdb-create-define-alist nil t))))))
	(kill-local-variable 'gdb-define-alist)
	(remove-hook 'after-save-hook 'gdb-create-define-alist t))))

(defcustom mlgud-tooltip-modes '(mlgud-mode c-mode c++-mode fortran-mode
					python-mode)
  "List of modes for which to enable MLGUD tooltips."
  :type 'sexp
  :group 'mlgud
  :group 'tooltip)

(defcustom mlgud-tooltip-display
  '((eq (tooltip-event-buffer mlgud-tooltip-event)
	(marker-buffer mlgud-overlay-arrow-position)))
  "List of forms determining where MLGUD tooltips are displayed.

Forms in the list are combined with AND.  The default is to display
only tooltips in the buffer containing the overlay arrow."
  :type 'sexp
  :group 'mlgud
  :group 'tooltip)

(defcustom mlgud-tooltip-echo-area nil
  "Use the echo area instead of frames for MLGUD tooltips."
  :type 'boolean
  :group 'mlgud
  :group 'tooltip)

(make-obsolete-variable 'mlgud-tooltip-echo-area
			"disable Tooltip mode instead" "24.4" 'set)

;;; Reacting on mouse movements

(defun mlgud-tooltip-change-major-mode ()
  "Function added to `change-major-mode-hook' when tooltip mode is on."
  (add-hook 'post-command-hook 'mlgud-tooltip-activate-mouse-motions-if-enabled))

(defun mlgud-tooltip-activate-mouse-motions-if-enabled ()
  "Reconsider for all buffers whether mouse motion events are desired."
  (remove-hook 'post-command-hook
	       'mlgud-tooltip-activate-mouse-motions-if-enabled)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (if (and mlgud-tooltip-mode
	       (memq major-mode mlgud-tooltip-modes))
	  (mlgud-tooltip-activate-mouse-motions t)
	(mlgud-tooltip-activate-mouse-motions nil)))))

(defvar mlgud-tooltip-mouse-motions-active nil
  "Locally t in a buffer if tooltip processing of mouse motion is enabled.")

;; We don't set track-mouse globally because this is a big redisplay
;; problem in buffers having a pre-command-hook or such installed,
;; which does a set-buffer, like the summary buffer of Gnus.  Calling
;; set-buffer prevents redisplay optimizations, so every mouse motion
;; would be accompanied by a full redisplay.

(defun mlgud-tooltip-activate-mouse-motions (activatep)
  "Activate/deactivate mouse motion events for the current buffer.
ACTIVATEP non-nil means activate mouse motion events."
  (if activatep
      (progn
        (set (make-local-variable 'mlgud-tooltip-mouse-motions-active) t)
        (set (make-local-variable 'track-mouse) t))
    (when mlgud-tooltip-mouse-motions-active
      (kill-local-variable 'mlgud-tooltip-mouse-motions-active)
      (kill-local-variable 'track-mouse))))

(defvar tooltip-last-mouse-motion-event)
(declare-function tooltip-hide "tooltip" (&optional ignored-arg))
(declare-function tooltip-start-delayed-tip "tooltip" ())

(defun mlgud-tooltip-mouse-motion (event)
  "Command handler for mouse movement events in `global-map'."
  (interactive "e")
  (tooltip-hide)
  (when (car (mouse-pixel-position))
    (setq tooltip-last-mouse-motion-event (copy-sequence event))
    (tooltip-start-delayed-tip)))

;;; Tips for `mlgud'

(defvar mlgud-tooltip-dereference nil
  "Non-nil means print expressions with a `*' in front of them.
For C this would dereference a pointer expression.")

(defvar mlgud-tooltip-event nil
  "The mouse movement event that led to a tooltip display.
This event can be examined by forms in `mlgud-tooltip-display'.")

(defun mlgud-tooltip-dereference (&optional arg)
  "Toggle whether tooltips should show `* expr' or `expr'.
With arg, dereference expr if ARG is positive, otherwise do not dereference."
 (interactive "P")
  (setq mlgud-tooltip-dereference
	(if (null arg)
	    (not mlgud-tooltip-dereference)
	  (> (prefix-numeric-value arg) 0)))
  (message "Dereferencing is now %s."
	   (if mlgud-tooltip-dereference "on" "off")))

(defvar tooltip-use-echo-area)
(declare-function tooltip-show "tooltip" (text &optional use-echo-area))
(declare-function tooltip-strip-prompt "tooltip" (process output))

; This will only display data that comes in one chunk.
; Larger arrays (say 400 elements) are displayed in
; the tooltip incompletely and spill over into the mlgud buffer.
; Switching the process-filter creates timing problems and
; it may be difficult to do better. Using GDB/MI as in
; gdb-mi.el gets around this problem.
(defun mlgud-tooltip-process-output (process output)
  "Process debugger output and show it in a tooltip window."
  (remove-function (process-filter process) #'mlgud-tooltip-process-output)
  (tooltip-show (tooltip-strip-prompt process output)
		(or mlgud-tooltip-echo-area tooltip-use-echo-area
                    (not tooltip-mode))))

(defun mlgud-tooltip-print-command (expr)
  "Return a suitable command to print the expression EXPR."
  (pcase mlgud-minor-mode
    (`gdbmi (concat "-data-evaluate-expression \"" expr "\""))
    (`dbx (concat "print " expr))
    ((or `xdb `pdb) (concat "p " expr))
    (`sdb (concat expr "/"))))

(declare-function gdb-input "gdb-mi" (command handler &optional trigger))
(declare-function tooltip-expr-to-print "tooltip" (event))
(declare-function tooltip-event-buffer "tooltip" (event))

(defun mlgud-tooltip-tips (event)
  "Show tip for identifier or selection under the mouse.
The mouse must either point at an identifier or inside a selected
region for the tip window to be shown.  If `mlgud-tooltip-dereference' is t,
add a `*' in front of the printed expression.  In the case of a C program
controlled by GDB, show the associated #define directives when program is
not executing.

This function must return nil if it doesn't handle EVENT."
  (let (process)
    (when (and (eventp event)
	       mlgud-tooltip-mode
	       mlgud-comint-buffer
	       (buffer-name mlgud-comint-buffer); might be killed
	       (setq process (get-buffer-process mlgud-comint-buffer))
	       (posn-point (event-end event))
	       (or (and (eq mlgud-minor-mode 'gdbmi) (not gdb-active-process))
		   (progn (setq mlgud-tooltip-event event)
			  (eval (cons 'and mlgud-tooltip-display)))))
      (let ((expr (tooltip-expr-to-print event)))
	(when expr
	  (if (and (eq mlgud-minor-mode 'gdbmi)
		   (not gdb-active-process))
	      (progn
		(with-current-buffer (tooltip-event-buffer event)
		  (let ((define-elt (assoc expr gdb-define-alist)))
		    (unless (null define-elt)
		      (tooltip-show
		       (cdr define-elt)
		       (or mlgud-tooltip-echo-area tooltip-use-echo-area
                           (not tooltip-mode)))
		      expr))))
	    (when mlgud-tooltip-dereference
	      (setq expr (concat "*" expr)))
	    (let ((cmd (mlgud-tooltip-print-command expr)))
	      (when (and mlgud-tooltip-mode (eq mlgud-minor-mode 'gdb))
		(mlgud-tooltip-mode -1)
		;; The blank before the newline is for MS-Windows,
		;; whose emulation of message box removes newlines and
		;; displays a single long line.
		(message-box "Using MLGUD tooltips in this mode is unsafe \n\
so they have been disabled."))
	      (unless (null cmd) ; CMD can be nil if unknown debugger
		(if (eq mlgud-minor-mode 'gdbmi)
                    (if gdb-macro-info
                        (gdb-input
                         (concat
			  "server macro expand " expr "\n")
			 `(lambda () (gdb-tooltip-print-1 ,expr)))
                      (gdb-input
		       (concat cmd "\n")
		       `(lambda () (gdb-tooltip-print ,expr))))
                  (add-function :override (process-filter process)
                                #'mlgud-tooltip-process-output)
		  (mlgud-basic-call cmd))
		expr))))))))

(provide 'mlgud)

;;; mlgud.el ends here
