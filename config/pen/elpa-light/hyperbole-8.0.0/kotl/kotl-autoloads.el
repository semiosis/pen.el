;;; kotl-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads nil "kcell" "kcell.el" (0 0 0 0))
;;; Generated autoloads from kcell.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kcell" '("kcell")))

;;;***

;;;### (autoloads nil "kexport" "kexport.el" (0 0 0 0))
;;; Generated autoloads from kexport.el

(autoload 'kexport:koutline "kexport" "\
Export the current buffer's koutline to the same named file with a \".html\" suffix.
Return the pathname of the html file created.

By default, this retains newlines within cells as they are.  With optional prefix arg, SOFT-NEWLINES-FLAG,
hard newlines are not used.  Also converts Urls and Klinks into Html hyperlinks.

\(fn &optional SOFT-NEWLINES-FLAG)" t nil)

(autoload 'kexport:display "kexport" "\
Export the current buffer's koutline to the same named file with a \".html\" suffix and display it in a web browser.
Return the pathname of the html file created.

By default, this retains newlines within cells as they are.  With optional prefix arg, SOFT-NEWLINES-FLAG,
hard newlines are not used.  Also converts Urls and Klinks into Html hyperlinks.

\(fn &optional SOFT-NEWLINES-FLAG)" t nil)

(autoload 'kexport:html "kexport" "\
Export a koutline buffer or file in EXPORT-FROM to html format in OUTPUT-TO.
By default, this retains newlines within cells as they are.  With optional prefix arg, SOFT-NEWLINES-FLAG,
hard newlines are not used.  Also converts Urls and Klinks into Html hyperlinks.
!! STILL TODO:
  Make delimited pathnames into file links (but not if within klinks).
  Copy attributes stored in cell 0 and attributes from each cell.

\(fn EXPORT-FROM OUTPUT-TO &optional SOFT-NEWLINES-FLAG)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kexport" '("kexport:")))

;;;***

;;;### (autoloads nil "kfile" "kfile.el" (0 0 0 0))
;;; Generated autoloads from kfile.el

(autoload 'kfile:find "kfile" "\
Find a file FILE-NAME containing a kotl or create one if none exists.
Return the new kview.

\(fn FILE-NAME)" t nil)

(autoload 'kfile:is-p "kfile" "\
Iff current buffer contains an unformatted or formatted koutline, return file format version string, else nil." nil nil)

(autoload 'kfile:view "kfile" "\
View an existing kotl version-2 file FILE-NAME in a read-only mode.

\(fn FILE-NAME)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kfile" '("kfile:")))

;;;***

;;;### (autoloads nil "kfill" "kfill.el" (0 0 0 0))
;;; Generated autoloads from kfill.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kfill" '("kfill:" "prior-fill-prefix" "set-fill-prefix")))

;;;***

;;;### (autoloads nil "kimport" "kimport.el" (0 0 0 0))
;;; Generated autoloads from kimport.el

(defvar kimport:mode-alist '((t . kimport:text) (outline-mode . kimport:star-outline)) "\
Alist of (major-mode . importation-function) elements.
This determines the type of importation done on a file when `kimport:file' is
called if the major mode of the import file matches the car of an element in
this list.  If there is no match, then `kimport:suffix-alist' is checked.  If
that yields no match, the element in this list whose car is 't is used.  It
normally does an import of a koutline or text file.

Each importation-function must take two arguments, a buffer/file to import
and a buffer/file into which to insert the imported elements and a third
optional argument, CHILDREN-P, which when non-nil means insert imported cells
as the initial set of children of the current cell, if any.

   `outline-mode'  - imported as an Emacs outline whose entries begin with
                     asterisks; 
   .kot
   .kotl           - imported as a structured koutline

   all others      - imported as text.")

(defvar kimport:suffix-alist '(("\\.org$" . kimport:star-outline) ("\\.otl$" . kimport:star-outline) ("\\.aug$" . kimport:aug-post-outline)) "\
Alist of (buffer-name-suffix-regexp . importation-function) elements.
This determines the type of importation done on a file when `kimport:file' is
called.  Each importation-function must take two arguments, a buffer/file to
import and a buffer/file into which to insert the imported elements.
A third optional argument, CHILDREN-P, may be given; when non-nil, insert
imported cells as the initial set of children of the current cell, if any.

   .org  - import format is an Emacs outline whose entries begin with asterisks;
   .otl  - import format is an Emacs outline whose entries begin with asterisks;
   .kot
   .kotl - import format is a Koutline
   .aug  - import format is an Augment post-numbered outline
           (see https://dougengelbart.org/content/view/148/).")

(autoload 'kimport:file "kimport" "\
Import a buffer or file IMPORT-FROM into the koutline in buffer or file OUTPUT-TO.

Any suffix in IMPORT-FROM's buffer name is used to determine the type of
importation.  All others are imported as text, one paragraph per cell.

See the documentation for the variable, `kimport:suffix-alist' for
information on specific importation formats.

\(fn IMPORT-FROM OUTPUT-TO &optional CHILDREN-P)" t nil)

(autoload 'kimport:insert-file "kimport" "\
Insert each element in IMPORT-FROM as a separate cell in the current view.
Insert as sibling cells following the current cell unless prefix arg,
CHILDREN-P is non-nil, then insert as the initial children of the current
cell.

IMPORT-FROM may be a buffer name or file name (file name completion is
provided).

See documentation for `kimport:file' for information on how the type of
importation is determined.

\(fn IMPORT-FROM CHILDREN-P)" t nil)

(autoload 'kimport:insert-register "kimport" "\
Insert contents of register REGISTER at point in current cell.
REGISTER is a character naming the register to insert.
Normally puts point before and mark after the inserted text.
If optional second arg is non-nil, puts mark before and point after.
Interactively, second arg is non-nil if prefix ARG is supplied.

\(fn REGISTER &optional ARG)" t nil)

(autoload 'kimport:aug-post-outline "kimport" "\
Insert Augment outline statements from IMPORT-FROM into koutline OUTPUT-TO.
Displays and leaves point in OUTPUT-TO.  See documentation for
`kimport:initialize' for valid values of IMPORT-FROM and OUTPUT-TO and for
an explanation of where imported cells are placed.

If OUTPUT-TO is a new koutline, the first statement inserted will be the
first cell.  Otherwise, it will be the successor of the current cell.

Each statement to be imported is delimited by an Augment relative id at the
end of the statement.  \"1\" = level 1, \"1a\" = level 2 in outline and so
on.

\(fn IMPORT-FROM OUTPUT-TO &optional CHILDREN-P)" t nil)

(autoload 'kimport:star-outline "kimport" "\
Insert star outline nodes from IMPORT-FROM into koutline OUTPUT-TO.
Displays and leaves point in OUTPUT-TO.  See documentation for
`kimport:initialize' for valid values of IMPORT-FROM and OUTPUT-TO and for
an explanation of where imported cells are placed.

\"* \" = level 1, \"** \" = level 2 in outline and so on.

\(fn IMPORT-FROM OUTPUT-TO &optional CHILDREN-P)" t nil)

(autoload 'kimport:text "kimport" "\
Insert text paragraphs from IMPORT-FROM into koutline OUTPUT-TO.
Displays and leaves point in OUTPUT-TO.  See documentation for
`kimport:initialize' for valid values of IMPORT-FROM and OUTPUT-TO and for
an explanation of where imported cells are placed.

Text paragraphs are imported as a sequence of same level cells.  Koutlines
are imported with their structure intact.

The variable, `paragraph-start,' is used to determine paragraphs.

\(fn IMPORT-FROM OUTPUT-TO &optional CHILDREN-P)" t nil)

(autoload 'kimport:copy-and-set-buffer "kimport" "\
Copy and untabify SOURCE, set copy buffer as current buffer for this command and return the copy buffer.
SOURCE may be a buffer name, a buffer or a file name.
If SOURCE buffer name begins with a space, it is not copied under the
assumption that it already has been.  If SOURCE is a koutline, it is not
copied since there is no need to copy it to import it.

\(fn SOURCE)" nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kimport" '("kimport:")))

;;;***

;;;### (autoloads nil "klabel" "klabel.el" (0 0 0 0))
;;; Generated autoloads from klabel.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "klabel" '("klabel" "kotl-label:")))

;;;***

;;;### (autoloads nil "klink" "klink.el" (0 0 0 0))
;;; Generated autoloads from klink.el

(autoload 'klink:create "klink" "\
Insert at point an implicit link to REFERENCE.
REFERENCE should be a cell-ref or a string containing \"filename, cell-ref\".
See documentation for `kcell:ref-to-id' for valid cell-ref formats.

\(fn REFERENCE)" t nil)

(autoload 'klink:at-p "klink" "\
Return non-nil iff point is within a klink.
See documentation for the `actypes::link-to-kotl' function for valid klink
formats.  Value returned is a list of: link-label, link-start-position, and
link-end-position, (including delimiters)." nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "klink" '("klink" "link-to-kotl")))

;;;***

;;;### (autoloads nil "kmenu" "kmenu.el" (0 0 0 0))
;;; Generated autoloads from kmenu.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kmenu" '("id-" "kotl-")))

;;;***

;;;### (autoloads nil "kotl-mode" "kotl-mode.el" (0 0 0 0))
;;; Generated autoloads from kotl-mode.el

(autoload 'kotl-mode "kotl-mode" "\
The major mode used to edit and view koutlines.
It provides the following keys:
\\{kotl-mode-map}" t nil)

(autoload 'kotl-mode:example "kotl-mode" "\
Display the optional Koutliner EXAMPLE file for demonstration and editing use by a user.
With optional REPLACE-FLAG non-nil, archive any existing file,
and replace it with the latest Hyperbole EXAMPLE.

EXAMPLE may be a file or directory name (\"EXAMPLE.kotl\" is appended).

If EXAMPLE is omitted or nil, create or edit the \"~/EXAMPLE.kotl\" file.

When called interactively, prompt for EXAMPLE if given a prefix
argument, archive any existing file, and replace it with the latest
Hyperbole EXAMPLE.

\(fn &optional EXAMPLE REPLACE-FLAG)" t nil)

(autoload 'kotl-mode:overview "kotl-mode" "\
Show the first line of each cell.
With optional prefix ARG, toggle display of blank lines between cells.

\(fn &optional ARG)" t nil)

(autoload 'kotl-mode:show-all "kotl-mode" "\
Show (expand) all cells in the current view.
With optional prefix ARG, toggle display of blank lines between cells.

\(fn &optional ARG)" t nil)

(autoload 'kotl-mode:top-cells "kotl-mode" "\
Collapse all level 1 cells in view and hide any deeper sublevels.
With optional prefix ARG, toggle display of blank lines between cells.

\(fn &optional ARG)" t nil)

(autoload 'kotl-mode:hide-tree "kotl-mode" "\
Collapse tree rooted at optional CELL-REF (defaults to cell at point).
With optional SHOW-FLAG, expand the tree instead.

\(fn &optional CELL-REF SHOW-FLAG)" t nil)

(autoload 'kotl-mode:show-tree "kotl-mode" "\
Display fully expanded tree rooted at CELL-REF.

\(fn &optional CELL-REF)" t nil)

(autoload 'kotl-mode:is-p "kotl-mode" "\
Signal an error if current buffer is not a Hyperbole outline, else return t." nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kotl-mode" '("delete-selection-pre-hook" "kotl-" "yank-")))

;;;***

;;;### (autoloads nil "kotl-orgtbl" "kotl-orgtbl.el" (0 0 0 0))
;;; Generated autoloads from kotl-orgtbl.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kotl-orgtbl" '("kotl-mode:transpose-lines-" "orgtbl-")))

;;;***

;;;### (autoloads nil "kproperty" "kproperty.el" (0 0 0 0))
;;; Generated autoloads from kproperty.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kproperty" '("kproperty:")))

;;;***

;;;### (autoloads nil "kview" "kview.el" (0 0 0 0))
;;; Generated autoloads from kview.el

(autoload 'kview:char-invisible-p "kview" "\
Return t if the character after point is invisible/hidden, else nil.

\(fn &optional POS)" nil nil)

(autoload 'kview:char-visible-p "kview" "\
Return t if the character after point is visible, else nil.

\(fn &optional POS)" nil nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kview" '("kcell-view:" "kview:")))

;;;***

;;;### (autoloads nil "kvspec" "kvspec.el" (0 0 0 0))
;;; Generated autoloads from kvspec.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "kvspec" '("kvspec:")))

;;;***

(provide 'kotl-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; kotl-autoloads.el ends here
