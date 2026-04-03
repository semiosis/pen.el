;; Don't use the script because it breaks when an info-page exists
;; v +/"echo \"Info for" "$EMACSD/pen.el/scripts/container/man"
;; (setq manual-program "man")
;; (setq manual-program "/usr/bin/man")
(setq manual-program "emacs-man-bin")

(defun man-page-p (args)
  (sn-true (concat "/usr/bin/man " args)))

(defun iman (page)
  (interactive (list (let ((cand (pen-word-at-point)))
                       (if (man-page-p cand)
                           cand
                         (pen-ask cand
                                  "man page:")))))
  (let* ((query ;; (concat "3 " (pen-thing-at-point))
          (concat page))
         (exists (pen-snq (pen-cmd "man-page-exists-p" page))))
    (if exists
        (progn
          (deactivate-mark)
          (if (man-page-p query)
              (man query)
            (error "page does not exist")))
      (pen-sps (pen-cmd "iman" page)))))
(defalias 'man-thing-at-point 'iman)

(defun man-thing-at-point-cpp ()
  (interactive)
  (let ((query (concat "3 " (pen-thing-at-point))))
    (deactivate-mark)
    (if (man-page-p query)
        (man query)
      (error "page does not exist"))))

(setq manual-program "emacs-internal-man")

;; Because I'm redefining defun man, I need to also manually load (load-library "man") or it will error
(load-library "man")

;; I changed it so it doesn't display a blank first entry in ivy
(defun man (man-args)
  "Get a Un*x manual page and put it in a buffer.
This command is the top-level command in the man package.
It runs a Un*x command to retrieve and clean a manpage in the
background and places the results in a `Man-mode' browsing
buffer.  The variable `Man-width' defines the number of columns in
formatted manual pages.  The buffer is displayed immediately.
The variable `Man-notify-method' defines how the buffer is displayed.
If a buffer already exists for this man page, it will be displayed
without running the man command.

For a manpage from a particular section, use either of the
following.  \"cat(1)\" is how cross-references appear and is
passed to man as \"1 cat\".

    cat(1)
    1 cat

To see manpages from all sections related to a subject, use an
\"all pages\" option (which might be \"-a\" if it's not the
default), then step through with `Man-next-manpage' (\\<Man-mode-map>\\[Man-next-manpage]) etc.
Add to `Man-switches' to make this option permanent.

    -a chmod

An explicit filename can be given too.  Use -l if it might
otherwise look like a page name.

    /my/file/name.1.gz
    -l somefile.1

An \"apropos\" query with -k gives a buffer of matching page
names or descriptions.  The pattern argument is usually an
\"grep -E\" style regexp.

    -k pattern

Note that in some cases you will need to use \\[quoted-insert] to quote the
SPC character in the above examples, because this command attempts
to auto-complete your input based on the installed manual pages."

  (interactive
   (list (let* ((default-entry (first (Man-completion-table "" nil t)))
                ;; (default-entry (Man-default-man-entry))
		        ;; ignore case because that's friendly for bizarre
		        ;; caps things like the X11 function names and because
		        ;; "man" itself is case-insensitive on the command line
		        ;; so you're accustomed not to bother about the case
		        ;; ("man -k" is case-insensitive similarly, so the
		        ;; table has everything available to complete)
		        (completion-ignore-case t)
		        Man-completion-cache    ;Don't cache across calls.
		        (input (completing-read
			            (format-prompt "Manual entry"
                                       (and (not (equal default-entry ""))
                                            default-entry))
                        'Man-completion-table
			            nil nil nil 'Man-topic-history default-entry)))
	       (if (string= input "")
	           (error "No man args given")
	         input))))

  ;; Possibly translate the "subject(section)" syntax into the
  ;; "section subject" syntax and possibly downcase the section.
  (setq man-args (Man-translate-references man-args))

  (Man-getpage-in-background man-args))

(provide 'pen-man)
