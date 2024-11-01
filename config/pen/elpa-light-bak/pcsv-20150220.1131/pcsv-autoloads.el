;;; pcsv-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "pcsv" "pcsv.el" (0 0 0 0))
;;; Generated autoloads from pcsv.el

(autoload 'pcsv-parse-region "pcsv" "\
Parse region as a csv.

\(fn START END)" nil nil)

(autoload 'pcsv-parse-buffer "pcsv" "\
Parse a BUFFER as a csv. BUFFER defaults to `current-buffer'.

\(fn &optional BUFFER)" nil nil)

(autoload 'pcsv-parse-file "pcsv" "\
Parse FILE as a csv file with CODING-SYSTEM.
To handle huge file, please try `pcsv-file-parser' function.

\(fn FILE &optional CODING-SYSTEM)" nil nil)

(autoload 'pcsv-parser "pcsv" "\
Get a CSV parser to parse BUFFER.
This function supported only Emacs 24 or later.


Example:
\(setq parser (pcsv-parser))
\(let (tmp)
  (while (setq tmp (funcall parser))
    (print tmp)))

\(fn &optional BUFFER)" nil nil)

(autoload 'pcsv-file-parser "pcsv" "\
Create a csv parser to read huge FILE.
This csv parser accept a optional arg.
 You must call this parser with optional non-nil arg to terminate the parser.

Optional arg BLOCK-SIZE indicate bytes to read FILE each time.

Example:
\(let ((parser (pcsv-file-parser \"/path/to/csv\")))
  (unwind-protect
      (let (tmp)
        (while (setq tmp (funcall parser))
          (print tmp)))
    ;; Must close the parser
    (funcall parser t)))

\(fn FILE &optional CODING-SYSTEM BLOCK-SIZE)" nil nil)

(register-definition-prefixes "pcsv" '("pcsv-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; pcsv-autoloads.el ends here
