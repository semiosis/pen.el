(require 'ob-core)
(require 'ob-prolog)

;; org-babel-shell-names

;; I think this is just for setting up babel
(org-babel-do-load-languages
 'org-babel-load-languages
 '((shell . t)
   (python . t)
   (R . t)
   (js . t)
   ;; (problog . t)
   (dot . t)
   (go . t)
   ;; (show-dot . t)
   (tmux . t)
   (C . t)))

(defun inside-src-block ()
  "True if inside src block."
  (memq (org-element-type (org-element-context)) '(inline-src-block src-block)))

(defun org-babel-open-src-block-result-maybe ()
  (interactive)
  (if (inside-src-block)
      (progn
        (org-babel-open-src-block-result)
          )
    nil))

(setq org-src-window-setup 'current-window)

;; Not sure why this is not collecting the output
(defun org-babel-execute:powershell (body params)
  (let* ((coding-system-for-read 'utf-8) ;use utf-8 with sub-processes
         l         (coding-system-for-write 'utf-8)
         (in-file (org-babel-temp-file "psh-")))
    (with-temp-file in-file
      (insert (org-babel-expand-body:generic body params)))
    (org-babel-eval (concat "pwsh" " -f " (org-babel-process-file-name in-file)) "")
    nil))

(defun org-babel-get-named-block-contents (name)
  "Find a named source-code block.
Return the contents of the source block identified by source
NAME, or nil if no such block exists.  Set match data according
to `org-babel-named-src-block-regexp'."
  (save-excursion
    (goto-char (point-min))
    (goto-char (org-babel-find-named-block name))
    (org-get-src-block-here)
    ))

(defun org-babel-get-named-result-contents (name)
  "Find a named result block.
Return the contents of the source block identified by source
NAME, or nil if no such block exists.  Set match data according
to `org-babel-named-src-block-regexp'."
  (save-excursion
    (goto-char (point-min))
    (goto-char (org-babel-find-named-result name))
    (org-get-src-block-here)))


(defun org-babel-execute:generic (body params)
  ":interpreter executes body like 'interpreter file'
:interpreter filters the source like 'cat source | filter'"
  (let ((stdinblock (or (cdr (assoc :in params))
                        (cdr (assoc :inb params))
                        (cdr (assoc :ins params))
                        (cdr (assoc :insrc params))
                        ""))
        (stdinresult (or (cdr (assoc :inr params))
                         (cdr (assoc :inresult params))
                         ""))
        (stdincmd (or (cdr (assoc :input params))
                      (cdr (assoc :stdin params))
                      ))
        (interpreter (or (cdr (assoc :interpreter params))
                         (cdr (assoc :i params))
                         (cdr (assoc :sps params))
                         (cdr (assoc :sph params))
                         (cdr (assoc :spv params))
                         (cdr (assoc :comint params))
                         (cdr (assoc :nw params))
                         (cdr (assoc :esph params))
                         (cdr (assoc :espv params))
                         (cdr (assoc :enw params))))
        (tmp (or (cdr (assoc :t params))
                 (cdr (assoc :fp params))
                 (cdr (assoc :file params))
                 (org-babel-temp-file "generic-")))
        (args (or (cdr (assoc :args params))
                  (cdr (assoc :a params))))
        (filter (or (if (cdr (assq :spsf params))
                        (concat "pen-sps -E " (pen-q (cdr (assq :spsf params))))
                      nil)
                    (cdr (assoc :filter params))
                    (cdr (assoc :f params)))))

    (if (and (string-empty-p (or stdincmd ""))
             (not (string-empty-p (or stdinblock ""))))
        ;; Save the contents of stdinblock to a file
        ;; and overwrite stdincmd
        (let ((fp (org-babel-temp-file "stdin" "txt")))
          (write-string-to-file (org-babel-get-named-block-contents stdinblock) fp)
          (setq stdincmd (concat "cat " fp))))

    (if (and (string-empty-p (or stdincmd ""))
             (not (string-empty-p (or stdinresult ""))))
        (let ((fp (org-babel-temp-file "stdin" "txt")))
          (write-string-to-file (org-babel-get-named-result-contents stdinresult) fp)
          (setq stdincmd (concat "cat " fp))))


    (if (and (boundp 'stdincmd) stdincmd)
        (setq stdincmd (concat stdincmd " | "))
      (setq stdincmd ""))

    (if (not (and (boundp 'interpreter) interpreter))
        (setq interpreter "cat"))
    (write-string-to-file body tmp)
    (if (and (boundp 'args) args)
        (setq args (concat " " args))
      (setq args ""))
    (if (and (boundp 'filter) filter)
        (setq filter (concat "| " filter))
      (setq filter ""))

    ;; The str here are not superfluous. They check for nil
    (let* ((stdincmd (str stdincmd))
           (interpreter (str interpreter))
           (tmp (str tmp))
           (args (str args))
           (filter (str filter))
           (com (ds (format
                     ". ~/.profile; %s %s%s%s %s"
                     "ls -la /proc/$$/fd/2 2>/dev/null | grep -q pty && exec <&2;"
                     stdincmd
                     (if (string-match-p "{}" interpreter)
                         (s-replace "{}" tmp interpreter)
                       (concat
                        interpreter
                        " "
                        tmp))
                     args
                     filter) "babel")))
      (if (assoc :pak params)
          (setq com (concat com "; pen-pak")))
      (cond ((assoc :comint params) (comint-quick com))
            ((assoc :nw params) (pen-nw com))
            ((assoc :sps params) (pen-sps com))
            ((assoc :sph params) (pen-sph com))
            ((assoc :spv params) (pen-spv com))
            ((assoc :esph params) (sph-term com))
            ((assoc :espv params) (spv-term com))
            ((assoc :enw params) (nw-term com))
            (t (shell-command-to-string com))))))

(defun org-babel-execute-src-block (&optional arg info params)
  "Execute the current source code block.
Insert the results of execution into the buffer.  Source code
execution and the collection and formatting of results can be
controlled through a variety of header arguments.

With prefix argument ARG, force re-execution even if an existing
result cached in the buffer would otherwise have been returned.

Optionally supply a value for INFO in the form returned by
`org-babel-get-src-block-info'.

Optionally supply a value for PARAMS which will be merged with
the header arguments specified at the front of the source code
block."
  (interactive)
  (let* ((org-babel-current-src-block-location
          (or org-babel-current-src-block-location
              (nth 5 info)
              (org-babel-where-is-src-block-head)))
         (info (if info (copy-tree info) (org-babel-get-src-block-info))))
    ;; Merge PARAMS with INFO before considering source block
    ;; evaluation since both could disagree.
    (cl-callf org-babel-merge-params (nth 2 info) params)
    (when (org-babel-check-evaluate info)
      (cl-callf org-babel-process-params (nth 2 info))
      (let* ((params (nth 2 info))
             (interpreter (or (cdr (assq :interpreter params))
                              (cdr (assq :i params))
                              (cdr (assq :sps params))
                              (cdr (assq :sph params))
                              (cdr (assq :spv params))
                              (cdr (assq :comint params))
                              (cdr (assq :nw params))
                              (cdr (assq :esph params))
                              (cdr (assq :espv params))
                              (cdr (assq :enw params))))
             (args (or (cdr (assq :args params))
                       (cdr (assq :a params))))
             (resultslang (or (cdr (assq :lang params))
                              (cdr (assq :l params))
                              ;; Not sure why these are both broken
                              ;; (s-replace-regexp "-mode$" "" (cdr (assq :mode params)))
                              ;; (s-replace-regexp "-mode$" "" (cdr (assq :m params)))
                              ))
             (stdincmd (or (cdr (assq :input params))
                           (cdr (assq :stdin params))
                           ))
             (filter (or (if (cdr (assq :spsf params))
                             (concat "pen-sps -E " (pen-q (cdr (assq :spsf params))))
                           nil)
                         (cdr (assq :filter params))
                         (cdr (assq :f params))))
             (cache (let ((c (cdr (assq :cache params))))
                      (and (not arg) c (string= "yes" c))))
             (new-hash (and cache (org-babel-sha1-hash info)))
             (old-hash (and cache (org-babel-current-result-hash)))
             (current-cache (and new-hash (equal new-hash old-hash))))
        (cond
         (current-cache
          (save-excursion               ;Return cached result.
            (goto-char (org-babel-where-is-src-block-result nil info))
            (forward-line)
            (skip-chars-forward " \t")
            (let ((result (org-babel-read-result)))
              (message (replace-regexp-in-string "%" "%%" (format "%S" result)))
              result)))
         ((org-babel-confirm-evaluate info)
          (let* ((lang (nth 0 info))
                 (result-params (cdr (assq :result-params params)))
                 ;; Expand noweb references in BODY and remove any
                 ;; coderef.
                 (body
                  (let ((coderef (nth 6 info))
                        (expand
                         (if (org-babel-noweb-p params :eval)
                             (org-babel-expand-noweb-references info)
                           (nth 1 info))))
                    (if (not coderef) expand
                      (replace-regexp-in-string
                       (org-src-coderef-regexp coderef) "" expand nil nil 1))))
                 (dir (cdr (assq :dir params)))
                 (default-directory
                   (or (and dir (file-name-as-directory (expand-file-name dir)))
                       default-directory))
                 (cm (intern (concat "org-babel-execute:" lang)))
                 result)
            (if (and (not arg) (or interpreter filter))
              (setq cm 'org-babel-execute:generic))
            (unless (fboundp cm)
              (error "No org-babel-execute function for %s!" lang))
            (message "executing %s code block%s..."
                     (capitalize lang)
                     (let ((name (nth 4 info)))
                       (if name (format " (%s)" name) "")))
            (if (member "none" result-params)
                (progn (funcall cm body params)
                       (message "result silenced"))
              (setq result
                    (let ((r (funcall cm body params)))
                      (if (and (eq (cdr (assq :result-type params)) 'value)
                               (or (member "vector" result-params)
                                   (member "table" result-params))
                               (not (listp r)))
                          (list (list r))
                        r)))
              (let ((file (cdr (assq :file params))))
                ;; If non-empty result and :file then write to :file.
                (when file
                  (when result
                    (with-temp-file file
                      (insert (org-babel-format-result
                               result (cdr (assq :sep params))))))
                  (setq result file))
                ;; Possibly perform post process provided its
                ;; appropriate.  Dynamically bind "*this*" to the
                ;; actual results of the block.
                (let ((post (cdr (assq :post params))))
                  (when post
                    (let ((*this* (if (not file) result
                                    (org-babel-result-to-file
                                     file
                                     (let ((desc (assq :file-desc params)))
                                       (and desc (or (cdr desc) result)))))))
                      (setq result (org-babel-ref-resolve post))
                      (when file
                        (setq result-params (remove "file" result-params))))))
                (org-babel-insert-result
                 result result-params info new-hash (or resultslang lang))))
            (run-hooks 'org-babel-after-execute-hook)
            result)))))))

(defun test-mark-buffer ()
  (interactive)
  (progn (beginning-of-buffer) (activate-mark) (end-of-buffer)))

;; I had high hopes here
;; Not sure why activate-mark doesn't work
(defun org-babel-raise ()
  "Move the interior of a babel to the outside: remove the babel block chrome and keep only the source code."
  (interactive)
  (let (deactivate-mark)
    (evil-with-single-undo

      ;; =org-mark-element= behaves slightly differently with a quote block
      (cond ((org-in-block-p '("quote"))
             (progn
               (call-interactively 'org-mark-element)
               (call-interactively 'previous-line)
               (call-interactively 'cua-exchange-point-and-mark)
               (call-interactively 'next-line)
               (call-interactively 'cua-exchange-point-and-mark)))
            (t
             (call-interactively 'org-mark-element)))

      ;; cfilter breaks the mark
      (pen-region-pipe "sed -e /^#+/d -e 's/^  //'")

      (call-interactively 'cua-exchange-point-and-mark)
      (re-search-backward "[^[:space:]]")
      (call-interactively 'move-end-of-line))))

(defun org-babel-change-block-type ()
  (interactive)
  (cond ((or (org-in-src-block-p)
             (org-in-block-p '("src" "example" "verbatim" "clocktable" "quote")))
         (progn
           (call-interactively 'org-babel-raise)
           (call-interactively 'hydra-org-template/body)))
        (t
         (self-insert-command 1))))

(setq org-confirm-babel-evaluate nil)

(defun org-babel-execute-named-block ()
  (interactive)
  (save-excursion
    (goto-char
     (org-babel-find-named-block
      (completing-read "Code Block: " (org-babel-src-block-names))))
    (org-babel-execute-src-block-maybe)))

;; (defun org-edit-special-around-advice (proc &rest args)
;;   ;; (message "org-edit-special called with args %S" args)
;;   (let ((res (apply proc args)))
;;     (undo-tree-save-root ?')
;;     ;; (message "org-edit-special returned %S" res)
;;     res))
;; (advice-add 'org-edit-special :around #'org-edit-special-around-advice)
;; (advice-remove 'org-edit-special #'org-edit-special-around-advice)

(defun org-babel-add-src-args ()
  (interactive)
  (if (org-in-src-block-p)
      (org-babel-insert-header-arg "args" (read-string "arguments:"))))

(defun pen-org-babel-goto-block-head (p)
  "Go to the beginning of the current block.
   If called with a prefix, go to the end of the block"
  (interactive "P")
  (let* ((element (org-element-at-point)))
    (when (or (eq (org-element-type element) 'example-block)
              (eq (org-element-type element) 'src-block) )
      (let ((begin (org-element-property :begin element))
            (end (org-element-property :end element)))
        ;; Ensure point is not on a blank line after the block.
        (beginning-of-line)
        (skip-chars-forward " \r\t\n" end)
        (when (< (point) end)
          (goto-char
           (if p
               (org-element-property :end element)
             (org-element-property :begin element))))))))

(defun org-babel-add-name ()
  (interactive)
  (call-interactively 'pen-org-babel-goto-block-head)
  (if (looking-at-p "^#\\+NAME")
      (progn
        (re-search-forward ": ")
        (call-interactively 'cua-set-mark)
        (pen-org-end-of-line))
      (progn
        (insert "\n")
        (previous-line)
        (insert "n")
        (call-interactively 'pen-yas-complete))))

(defun org-babel-previous-src-name ()
  (save-excursion
    (org-babel-previous-src-block 1)
    (org-element-property :name (org-element-at-point))))

(defun org-babel-previous-results-name ()
  (save-excursion
    (org-babel-previous-src-block 1)
    (car (org-element-property :results (org-element-at-point)))))

(defun org-babel-add-stdin-arg-for-previous-block ()
  (interactive)
  (if (org-in-src-block-p)
      (let ((prevsrc (org-babel-previous-src-name))
            (prevres (org-babel-previous-results-name)))
        (if prevres
            (org-babel-insert-header-arg "inr" prevres)
          (if prevsrc
              (org-babel-insert-header-arg "inb" prevsrc))))))

(defun org-get-src-block-language ()
  (interactive)
  (let* ((info (org-babel-get-src-block-info))
         (lang (if info
                   (car info))))
    (if (called-interactively-p)
        (xc lang)
      lang)))

(defun get-src-block-language ()
  (interactive)
  ;; (markdown-code-block-lang)

  (cond
   ((derived-mode-p 'org-mode)
    (org-get-src-block-language))
   ((derived-mode-p 'markdown-mode)
    (or
     (markdown-code-block-lang)
     "markdown"))
   ((derived-mode-p 'eww-mode)
    (read-string-hist (concat "egr " query " lang: ")))
   (t (buffer-language))))

;; Use generic instead of this in templates
(defun org-babel-execute:awk (body params)
  (let* ((coding-system-for-read 'utf-8) ;use utf-8 with sub-processes
         l         (coding-system-for-write 'utf-8)
         (in-file (org-babel-temp-file "awk-")))
    (with-temp-file in-file
      (insert (org-babel-expand-body:generic body params)))
    (org-babel-eval (concat "awk -f " (org-babel-process-file-name in-file)) "")
    nil))

(defun org-copy-src-block ()
  (interactive)
  (shut-up (xc (org-get-src-block-here))))

(defun org-get-src-block-here ()
  (interactive)
  (org-edit-src-code)
  (mark-whole-buffer)
  (let ((contents (chomp (pen-selection))))
    (org-edit-src-abort)
    contents))

(defun org-copy-thing-here ()
  (interactive)
  (if (or (org-in-src-block-p)
          (org-in-block-p '("src" "example" "verbatim" "clocktable" "example")))
      (org-copy-src-block)
    (self-insert-command 1)))

(provide 'pen-babel)
