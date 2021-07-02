;;; pen.el --- Prompt Engineering functions

(require 'pen-support)
(require 'dash)
(require 'iedit)
(require 'ht)
(require 'helm)
(require 'ivy)
(require 'pp)
(require 's)
(require 'cl-macs)
(require 'helm)
(require 'company)
(require 'selected)

(defvar my-completion-engine 'company-pen-filetype)

(defvar pen-map (make-sparse-keymap)
  "Keymap for `pen.el'.")
;; (makunbound 'pen.el)
(defvar-local pen.el nil)

(define-minor-mode pen
  "Mode for working with language models in your  buffers."
  :global t
  :init-value t
  :lighter " pen"
  :keymap pen-map)

(defcustom pen-prompt-directory ""
  "Directory where .prompt files are located"
  :type 'string
  :group 'prompt-engineer
  :initialize #'custom-initialize-default)

(defset pen-prompt-functions nil)
(defset pen-prompt-functions-meta nil)

(defun pen-yaml-test (yaml key)
  (ignore-errors
    (if (and yaml
             (sor key))
        (let ((c (ht-get yaml key)))
          (and (sor c)
               (string-equal c "on"))))))

(defun pen-generate-prompt-functions ()
  "Generate prompt functions for the files in the prompts directory
Function names are prefixed with pen-pf- for easy searching"
  (interactive)
  (noupd
   (let ((paths
          (-non-nil (mapcar 'sor (glob (concat pen-prompt-directory "/*.prompt"))))))
     (cl-loop for path in paths do
              (message (concat "pen-mode: Loading .prompt file " path))

              ;; results in a hash table
              (let* ((yaml (yamlmod-read-file path))
                     (title (ht-get yaml "title"))
                     (title-slug (slugify title))
                     (doc (ht-get yaml "doc"))
                     (cache (pen-yaml-test yaml "cache"))
                     (needs-work (pen-yaml-test yaml "needs-work"))
                     (disabled (pen-yaml-test yaml "disabled"))
                     (prefer-external (pen-yaml-test yaml "prefer-external"))
                     (conversation-mode (pen-yaml-test yaml "conversation-mode"))
                     (filter (pen-yaml-test yaml "filter"))
                     ;; Don't actually use this. But I can toggle to use the prettifier with a bool
                     (prettifier (ht-get yaml "prettifier"))
                     (completion (pen-yaml-test yaml "completion"))
                     (n-collate (ht-get yaml "n-collate"))
                     (vars (vector2list (ht-get yaml "vars")))
                     (aliases (vector2list (ht-get yaml "aliases")))
                     (alias-slugs (mapcar 'str2sym (mapcar (lambda (s) (concat "pen-pf-" s)) (mapcar 'slugify aliases))))
                     (examples (vector2list (ht-get yaml "examples")))
                     (preprocessors (vector2list (ht-get yaml "pen-preprocessors")))
                     (var-slugs (mapcar 'slugify vars))
                     (var-syms
                      (let ((ss (mapcar 'str2sym var-slugs)))
                        (message (concat "_" prettifier))
                        (if (sor prettifier)
                            (setq ss (append ss '(&key prettify))))
                        ss))
                     (pen-defaults (vector2list (ht-get yaml "pen-defaults")))
                     (completion (pen-yaml-test yaml "completion"))
                     (func-name (concat "pen-pf-" title-slug))
                     (func-sym (intern func-name))
                     (iargs
                      (let ((iteration 0))
                        (cl-loop for v in vars
                                 collect
                                 (let ((example (or (sor (nth iteration examples)
                                                         "")
                                                    "")))
                                   (message "%s" (concat "Example " (str iteration) ": " example))
                                   (if (equal 0 iteration)
                                       ;; The first argument may be captured through selection
                                       `(if (selected)
                                            (pen-selected-text)
                                          (if ,(> (length (s-lines example)) 1)
                                              (etv ,example)
                                            (read-string-hist ,(concat v ": ") ,example)))
                                     `(if ,(> (length (s-lines example)) 1)
                                          (etv ,example)
                                        (read-string-hist ,(concat v ": ") ,example))))
                                 do
                                 (progn
                                   (setq iteration (+ 1 iteration))
                                   (message (str iteration)))))))

                (setq n-collate (or n-collate 1))

                (add-to-list 'pen-prompt-functions-meta yaml)

                ;; var names will have to be slugged, too

                (if alias-slugs
                    (cl-loop for a in alias-slugs do
                             (progn
                               (defalias a func-sym)
                               (add-to-list 'pen-prompt-functions a))))

                (if (not needs-work)
                    (add-to-list 'pen-prompt-functions
                                 (eval
                                  `(cl-defun ,func-sym ,var-syms
                                     ,(sor doc title)
                                     (interactive ,(cons 'list iargs))
                                     (let* ((sh-update
                                             (or sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
                                            (shcmd (concat
                                                    ,(if (sor prettifier)
                                                         '(if prettify
                                                              "PRETTY_PRINT=y "
                                                            ""))
                                                    ,(flatten-once
                                                      (list
                                                       (list 'concat
                                                             (if cache
                                                                 "OAI_CACHE=y "
                                                               "")
                                                             "openai-complete "
                                                             (pen-q path))
                                                       (flatten-once
                                                        (cl-loop for vs in var-slugs collect
                                                                 (list " "
                                                                       (list 'pen-q (intern vs)))))))))
                                            (result
                                             (chomp
                                              (mapconcat 'identity
                                                         (cl-loop for i in (number-sequence ,n-collate)
                                                                  collect
                                                                  (progn
                                                                    (message (concat ,func-name " query " (int-to-string i) "..."))
                                                                    (let ((ret (sn shcmd)))
                                                                      (message (concat ,func-name " done " (int-to-string i)))
                                                                      ret)))
                                                         ""))))
                                       (if (interactive-p)
                                           (cond
                                            ((and ,filter
                                                  (selected))
                                             (replace-region (concat (selection) result)))
                                            (,completion
                                             (etv result))
                                            ((or ,(not filter)
                                                 (>= (prefix-numeric-value current-prefix-arg) 4)
                                                 (not (selected)))
                                             (etv result))
                                            (t
                                             (replace-region result)))
                                         result))))))
                (message (concat "pen-mode: Loaded prompt function " func-name)))))))

;; Initial load of prompt functions
(pen-generate-prompt-functions)

(defun pen-filter-with-prompt-function ()
  (interactive)
  (let ((f (fz pen-prompt-functions nil nil "pen filter: ")))
    (if f
        (filter-selected-region-through-function (intern f)))))

(defun pen-run-prompt-function ()
  (interactive)
  (let* ((sh-update (or sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
         (f (fz pen-prompt-functions nil nil "pen run: ")))
    (if f
        (call-interactively (intern f)))))

(defun company-pen-filetype--candidates (prefix)
  (let* ((preceding-text (pen-preceding-text))
         (response
          (->>
              preceding-text
            (pen-pf-generic-file-type-completion (detect-language))))
         (res
          (list response)))
    (mapcar (lambda (s) (concat (company-pen-filetype--prefix) s))
            res)))

(defun my-completion-at-point ()
  (interactive)
  (call-interactively 'completion-at-point)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'company-pen-filetype)
    (call-interactively 'completion-at-point)))

(defun pen-complete-long (preceding-text &optional tv)
  "Long-form completion. This will generate lots of text.
May use to generate code from comments."
  (interactive (list (str (buffer-substring (point) (max 1 (- (point) 1000))))
                     t))
  (let* ((response (pen-pf-generic-file-type-completion (detect-language) preceding-text)))
    (if tv
        (etv response)
      response)))

;; http://github.com/semiosis/pen.el/blob/master/pen-core.el
(require 'pen-core)

;; http://github.com/semiosis/pen.el/blob/master/pen-ivy.el
(require 'pen-ivy)

;; http://github.com/semiosis/pen.el/blob/master/pen-company.el
(require 'pen-company)

;; http://github.com/semiosis/pen.el/blob/master/pen-library.el
(require 'pen-library)

;; http://github.com/semiosis/pen.el/blob/master/pen-contrib.el
(require 'pen-contrib)

;; http://github.com/semiosis/pen.el/blob/master/pen-prompt-description.el
(require 'pen-prompt-description)

(provide 'pen)