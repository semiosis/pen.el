;; e:/usr/local/share/emacs/29.1.50/lisp/simple.el.gz

(defun shell-command-on-region (start end command
				                      &optional output-buffer replace
				                      error-buffer display-error-buffer
				                      region-noncontiguous-p)
  "Execute string COMMAND in inferior shell with region as input.
Normally display output (if any) in temp buffer specified
by `shell-command-buffer-name'; prefix arg means replace the region
with it.  Return the exit code of COMMAND.

To specify a coding system for converting non-ASCII characters
in the input and output to the shell command, use \\[universal-coding-system-argument]
before this command.  By default, the input (from the current buffer)
is encoded using coding-system specified by `process-coding-system-alist',
falling back to `default-process-coding-system' if no match for COMMAND
is found in `process-coding-system-alist'.

Noninteractive callers can specify coding systems by binding
`coding-system-for-read' and `coding-system-for-write'.

If the command generates output, the output may be displayed
in the echo area or in a buffer.
If the output is short enough to display in the echo area
\(determined by the variable `max-mini-window-height' if
`resize-mini-windows' is non-nil), it is shown there.
Otherwise it is displayed in the buffer named by `shell-command-buffer-name'.
The output is available in that buffer in both cases.
Note that if `shell-command-dont-erase-buffer' is non-nil,
the echo area could display more than just the output of the
last command.

If there is output and an error, a message about the error
appears at the end of the output.

Optional fourth arg OUTPUT-BUFFER specifies where to put the
command's output.  If the value is a buffer or buffer name,
erase that buffer and insert the output there; a non-nil value of
`shell-command-dont-erase-buffer' prevent to erase the buffer.
If the value is nil, use the buffer specified by `shell-command-buffer-name'.
Any other non-nil value means to insert the output in the
current buffer after START.

Optional fifth arg REPLACE, if non-nil, means to insert the
output in place of text from START to END, putting point and mark
around it.  If REPLACE is the symbol `no-mark', don't set the mark.

Optional sixth arg ERROR-BUFFER, if non-nil, specifies a buffer
or buffer name to which to direct the command's standard error
output.  If nil, error output is mingled with regular output.
When called interactively, `shell-command-default-error-buffer'
is used for ERROR-BUFFER.

Optional seventh arg DISPLAY-ERROR-BUFFER, if non-nil, means to
display the error buffer if there were any errors.  When called
interactively, this is t.

Non-nil REGION-NONCONTIGUOUS-P means that the region is composed of
noncontiguous pieces.  The most common example of this is a
rectangular region, where the pieces are separated by newline
characters."
  (interactive (let (string)
		         (unless (mark)
		           (user-error "The mark is not set now, so there is no region"))
		         ;; Do this before calling region-beginning
		         ;; and region-end, in case subprocess output
		         ;; relocates them while we are in the minibuffer.
		         (setq string (read-shell-command "Shell command on region: "))
		         ;; call-interactively recognizes region-beginning and
		         ;; region-end specially, leaving them in the history.
		         (list (region-beginning) (region-end)
		               string
		               current-prefix-arg
		               current-prefix-arg
		               shell-command-default-error-buffer
		               t
		               (region-noncontiguous-p))))
  (let ((error-file
	     (if error-buffer
	         (make-temp-file
	          (expand-file-name "scor"
				                (or small-temporary-file-directory
				                    temporary-file-directory)))
	       nil))
	    exit-status)
    ;; Unless a single contiguous chunk is selected, operate on multiple chunks.
    (if region-noncontiguous-p
        (let ((input (concat (funcall region-extract-function (when replace 'delete)) "\n"))
              output)
          (with-temp-buffer
            (insert input)
            (call-process-region (point-min) (point-max)
                                 shell-file-name t t
                                 nil shell-command-switch
                                 command)
            (setq output (split-string (buffer-substring
                                        (point-min)
                                        ;; Trim the trailing newline.
                                        (if (eq (char-before (point-max)) ?\n)
                                            (1- (point-max))
                                          (point-max)))
                                       "\n")))
          (cond
           (replace
            (goto-char start)
            (funcall region-insert-function output))
           (t
            (let ((buffer (get-buffer-create
                           (or output-buffer shell-command-buffer-name))))
              (with-current-buffer buffer
                (erase-buffer)
                (funcall region-insert-function output))
              (display-message-or-buffer buffer)))))
      (if (or replace
              (and output-buffer
                   (not (or (bufferp output-buffer) (stringp output-buffer)))))
          ;; Replace specified region with output from command.
          (let ((swap (and replace (< start end))))
            ;; Don't muck with mark unless REPLACE says we should.
            (goto-char start)
            (when (and replace
                       (not (eq replace 'no-mark)))
              (push-mark (point) 'nomsg))
            (setq exit-status
                  (call-shell-region start end command replace
                                     (if error-file
                                         (list t error-file)
                                       t)))
            ;; It is rude to delete a buffer that the command is not using.
            ;; (let ((shell-buffer (get-buffer shell-command-buffer-name)))
            ;;   (and shell-buffer (not (eq shell-buffer (current-buffer)))
            ;; 	 (kill-buffer shell-buffer)))
            ;; Don't muck with mark unless REPLACE says we should.
            (when (and replace swap
                       (not (eq replace 'no-mark)))
              (exchange-point-and-mark)))
        ;; No prefix argument: put the output in a temp buffer,
        ;; replacing its entire contents.
        (let ((buffer (get-buffer-create
                       (or output-buffer shell-command-buffer-name))))

          ;; I have disabled this
          ;; (set-buffer-major-mode buffer)
                                        ; Enable globalized modes (bug#38111)
          (unwind-protect
              (if (and (eq buffer (current-buffer))
                       (or (memq shell-command-dont-erase-buffer '(nil erase))
                           (and (not (eq buffer (get-buffer
                                                 shell-command-buffer-name)))
                                (not (region-active-p)))))
                  ;; If the input is the same buffer as the output,
                  ;; delete everything but the specified region,
                  ;; then replace that region with the output.
                  (progn (setq buffer-read-only nil)
                         (delete-region (max start end) (point-max))
                         (delete-region (point-min) (min start end))
                         (setq exit-status
                               (call-process-region (point-min) (point-max)
                                                    shell-file-name t
                                                    (if error-file
                                                        (list t error-file)
                                                      t)
                                                    nil shell-command-switch
                                                    command)))
                ;; Clear the output buffer, then run the command with
                ;; output there.
                (let ((directory default-directory))
                  (with-current-buffer buffer
                    (if (not output-buffer)
                        (setq default-directory directory))
                    (shell-command-save-pos-or-erase)))
                (setq exit-status
                      (call-shell-region start end command nil
                                         (if error-file
                                             (list buffer error-file)
                                           buffer))))
            ;; Report the output.
            (with-current-buffer buffer
              (setq-local revert-buffer-function
                          (lambda (&rest _)
                            (shell-command command)))
              (setq mode-line-process
                    (cond ((null exit-status)
                           " - Error")
                          ((stringp exit-status)
                           (format " - Signal [%s]" exit-status))
                          ((not (equal 0 exit-status))
                           (format " - Exit [%d]" exit-status)))))
            (if (with-current-buffer buffer (> (point-max) (point-min)))
                ;; There's some output, display it
                (progn
                  (display-message-or-buffer buffer)
                  (shell-command-set-point-after-cmd buffer))
              ;; No output; error?
              (let ((output
                     (if (and error-file
                              (< 0 (file-attribute-size
				                    (file-attributes error-file))))
                         (format "some error output%s"
                                 (if shell-command-default-error-buffer
                                     (format " to the \"%s\" buffer"
                                             shell-command-default-error-buffer)
                                   ""))
                       "no output")))
                (cond ((null exit-status)
                       (message "(Shell command failed with error)"))
                      ((equal 0 exit-status)
                       (message "(Shell command succeeded with %s)"
                                output))
                      ((stringp exit-status)
                       (message "(Shell command killed by signal %s)"
                                exit-status))
                      (t
                       (message "(Shell command failed with code %d and %s)"
                                exit-status output))))
              ;; Don't kill: there might be useful info in the undo-log.
              ;; (kill-buffer buffer)
              )))))

    (when (and error-file (file-exists-p error-file))
      (if (< 0 (file-attribute-size (file-attributes error-file)))
	      (with-current-buffer (get-buffer-create error-buffer)
            (goto-char (point-max))
            ;; Insert a separator if there's already text here.
	        (unless (bobp)
	          (insert "\f\n"))
	        ;; Do no formatting while reading error file,
	        ;; because that can run a shell command, and we
	        ;; don't want that to cause an infinite recursion.
	        (format-insert-file error-file nil)
	        (and display-error-buffer
		         (display-buffer (current-buffer)))))
      (delete-file error-file))
    exit-status))


(provide 'pen-simple)
