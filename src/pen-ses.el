(require 'ses)

;; Added the header line indent.
;; And added header-line-indent-mode to pen-manage-minor-mode.el for j:ses-mode 
;; See j:tabulated-list-init-header for an example
;; j:ses-create-header-string

(defun ses-create-header-string ()
  "Set up `ses--header-string' as the buffer's header line.
Based on the current set of columns and `window-hscroll' position."

  (let ((width (header-line-indent--line-number-width)))
    (setq header-line-indent-width width)
    (setq header-line-indent (make-string width ?\s)))

  (let ((totwidth (- (window-hscroll)))
        result width x)
    ;; Leave room for the left-side fringe and scrollbar.
    (push (propertize (concat header-line-indent " ") 'display '((space :align-to header-line-indent-width))) result)
    ;; (push (propertize header-line-indent 'display '((space :align-to 0))) result)
    (dotimes (col ses--numcols)
      (setq width (ses-col-width col)
            totwidth (+ totwidth width 1))
      (if (= totwidth 1)
          ;; Scrolled so intercolumn space is leftmost.
          (push " " result))
      (when (> totwidth 1)
        (if (> ses--header-row 0)
            (save-excursion
              (ses-goto-print (1- ses--header-row) col)
              (setq x (buffer-substring-no-properties (point)
                                                      (+ (point) width)))
              ;; Strip trailing space.
              (if (string-match "[ \t]+\\'" x)
                  (setq x (substring x 0 (match-beginning 0))))
              ;; Cut off excess text.
              (if (>= (length x) totwidth)
                  (setq x (substring x 0 (- totwidth -1)))))
          (setq x (ses-column-letter col)))
        (push (propertize x 'face ses-box-prop) result)
        (push (propertize "."
                          'display `((space :align-to (+ ,(1- totwidth)
                                                         header-line-indent-width)))
                          'face ses-box-prop)
              result)
        ;; Allow the following space to be squished to make room for the 3-D box
        ;; Coverage test ignores properties, thinks this is always a space!
        (push (1value (propertize " " 'display `((space :align-to ,totwidth))))
              result)))
    (if (> ses--header-row 0)
        (push (propertize (format "  [row %d]" ses--header-row)
                          'display '((height (- 1))))
              result))
    ;; (setq ses--header-string (concat header-line-indent
    ;;                                  (apply #'concat (nreverse result))))
    ;; (tv result)
    (setq ses--header-string (apply #'concat (nreverse result)))))

(defun ses-print-cell (row col)
  "Format and print the value of cell (ROW,COL) to the print area.
Use the cell's printer function.  If the cell's new print form is too wide,
it will spill over into the following cell, but will not run off the end of the
row or overwrite the next non-nil field.  Result is nil for normal operation,
or the error signal if the printer function failed and the cell was formatted
with \"%s\".  If the cell's value is *skip*, nothing is printed because the
preceding cell has spilled over."
  (catch 'ses-print-cell
    (let* ((cell (ses-get-cell row col))
           (value (ses-cell-value cell))
           (printer (ses-cell-printer cell))
           (maxcol (1+ col))
           text sig startpos x)
      ;; Create the string to print.
      (cond
       ((eq value '*skip*)
        ;; Don't print anything.
        (throw 'ses-print-cell nil))
       ((eq value '*error*)
        (setq text (make-string (ses-col-width col) ?#)))
       (t
        ;; Deferred safety-check on printer.
        (if (eq (car-safe printer) 'ses-safe-printer)
            (ses-set-cell row col 'printer
                          (setq printer (ses-safe-printer (cadr printer)))))
        ;; Print the value.
        (setq text
              (let ((ses--row row)
                    (ses--col col))
                (ses-call-printer (or printer
                                      (ses-col-printer col)
                                      ses--default-printer)
                                  value)))
        (if (consp ses-call-printer-return)
            ;; Printer returned an error.
            (setq sig ses-call-printer-return))))
      ;; Adjust print width to match column width.
      (let ((width (ses-col-width col))
            (len (string-width text)))
        (cond
         ((< len width)
          ;; Fill field to length with spaces.
          (setq len (make-string (- width len) ?\s)
                text (if (eq ses-call-printer-return t)
                         (concat text len)
                       (concat len text))))
         ((> len width)
          ;; Spill over into following cells, if possible.
          (let ((maxwidth width))
            (while (and (> len maxwidth)
                        (< maxcol ses--numcols)
                        (or (not (setq x (ses-cell-value row maxcol)))
                            (eq x '*skip*)))
              (unless x
                ;; Set this cell to '*skip* so it won't overwrite our spillover.
                (ses-set-cell row maxcol 'value '*skip*))
              (setq maxwidth (+ maxwidth (ses-col-width maxcol) 1)
                    maxcol (1+ maxcol)))
            (if (<= len maxwidth)
                ;; Fill to complete width of all the fields spanned.
                (setq text (concat text (make-string (- maxwidth len) ?\s)))
              ;; Not enough room to end of line or next non-nil field.  Truncate
              ;; if string or decimal; otherwise fill with error indicator.
              (setq sig `(error "Too wide" ,text))
              (cond
               ((stringp value)
                (setq text (truncate-string-to-width text maxwidth 0 ?\s)))
               ((and (numberp value)
                     (string-match "\\.[0-9]+" text)
                     (>= 0 (setq width
                                 (- len maxwidth
                                    (- (match-end 0) (match-beginning 0))))))
                ;; Turn 6.6666666666e+49 into 6.66e+49.  Rounding is too hard!
                (setq text (concat (substring text
                                              0
                                              (- (match-beginning 0) width))
                                   (substring text (match-end 0)))))
               (t
                (setq text (make-string maxwidth ?#)))))))))
      ;; Substitute question marks for tabs and newlines.  Newlines are used as
      ;; row-separators; tabs could confuse the reimport logic.
      (setq text (replace-regexp-in-string "[\t\n]" "?" text))
      (ses-goto-print row col)
      (setq startpos (point))
      ;; Install the printed result.  This is not interruptible.
      (let ((inhibit-read-only t)
            (inhibit-quit t))
        (delete-region (point) (progn
                                 (move-to-column (+ (current-column)
                                                    (string-width text)))
                                 (1+ (point))))
        ;; We use concat instead of inserting separate strings in order to
        ;; reduce the number of cells in the undo list.
        (setq x (concat text (if (< maxcol ses--numcols) " " "\n")))
        ;; We use set-text-properties to prevent a wacky print function from
        ;; inserting rogue properties, and to ensure that the keymap property is
        ;; inherited (is it a bug that only unpropertized strings actually
        ;; inherit from surrounding text?)
        (set-text-properties 0 (length x) nil x)

        ;; TODO Try to highlight the cells
        ;; (message "xy %d %d" row col)
        (if (zerop (mod (+ row col) 2))
            (put-text-property 0 (length x) 'face '(:background "#225522") x)
          (put-text-property 0 (length x) 'face '(:background "#222255") x))

        ;; Why did the original code use 'insert-and-inherit ?
        ;; (insert-and-inherit x)
        (insert x)
        
        (put-text-property startpos (point) 'cursor-intangible
                           (ses-cell-symbol cell))

        (when (and (zerop row) (zerop col))
          ;; (put-text-property (point-min) (point) 'face '(:background "#222222"))
          ;; Reconstruct special beginning-of-buffer attributes.
          (put-text-property (point-min) (point) 'keymap 'ses-mode-print-map)
          (put-text-property (point-min) (point) 'read-only 'ses)
          (put-text-property (point-min) (1+ (point-min))
                             ;; `cursor-intangible' shouldn't be sticky at BOB.
                             'front-sticky '(read-only keymap))))
      (if (= row (1- ses--header-row))
          ;; This line is part of the header --- force recalc.
          (ses-reset-header-string))
      ;; If this cell (or a preceding one on the line) previously spilled over
      ;; and has gotten shorter, redraw following cells on line recursively.
      (when (and (< maxcol ses--numcols)
                 (eq (ses-cell-value row maxcol) '*skip*))
        (ses-set-cell row maxcol 'value nil)
        (ses-print-cell row maxcol))
      ;; Return to start of cell.
      (goto-char startpos)
      sig)))

(define-key ses-mode-edit-map (kbd "C-h C-p") nil)
(define-key ses-mode-edit-map (kbd "C-h C-n") nil)
(define-key ses-mode-edit-map (kbd "C-h") nil)
(define-key ses-mode-edit-map (kbd "<help> p") 'ses-list-local-printers)
(define-key ses-mode-edit-map (kbd "<help> n") 'ses-list-named-cells)

(provide 'pen-ses)
