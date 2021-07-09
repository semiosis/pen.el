;;; pen.el --- Prompt Engineering functions

;; For string-empty-p
(require 'subr-x)
(require 'pen-support)
(require 'pen-global-prefix)
(require 'dash)
(require 'projectile)
(require 'iedit)
(require 'ht)
(require 'helm)
(require 'memoize)
(require 'ivy)
(require 'pp)
(require 's)
(require 'cl-macs)
(require 'company)
(require 'selected)
(require 'pcsv)

(require 'pen-custom)

(defvar my-completion-engine 'company-pen-filetype)

(defvar pen-map (make-sparse-keymap)
  "Keymap for `pen.el'.")
(defvar-local pen.el nil)

(defvar pen-current-lighter " ⊚")
(defun pen-compose-mode-line ()
  ;; Only change every second
  (let* ((m (mod (second (org-time-since 0)) 10))
         (newlighter
          (cond
           ((eq 0 m) " ☆")
           ((eq 1 m) " ○")
           ((eq 2 m) " ◎")
           ((eq 3 m) " ⊙")
           ((eq 4 m) " ⊚")
           ((eq 5 m) " ◎")
           ((eq 6 m) " ⊙")
           ((eq 7 m) " ⊚")
           ((eq 8 m) " ◎")
           ((eq 9 m) " ○")
           (t " ⊚"))))
    (setq pen-current-lighter newlighter)
    newlighter))

(define-minor-mode pen
  "Mode for working with language models in your buffers."
  :global t
  :init-value t
  ;; zone plate
  :lighter (:eval (pen-compose-mode-line))
  :keymap pen-map)

(defset pen-prompt-functions nil)
(defset pen-prompt-functions-meta nil)

(defun pen-yaml-test (yaml key)
  (ignore-errors
    (if (and yaml
             (sor key))
        (let ((c (ht-get yaml key)))
          (and (sor c)
               (string-equal c "on"))))))

;; Q: How to send arrays to bash?
;; A: Delimit
(defvar 'pen-export-flags
  '(conversation-mode
    completion))

(defvar 'pen-export-variables
  '(max-tokens
    temperature
    prompt
    cache
    collation-postprocessor completion
    vars aliases alias-slugs
    examples preprocessors var-slugs
    var-syms func-name))

(defun define-prompt-function (func-name func-sym var-syms doc
                               title iargs prettify
                               cache path var-slugs n-collate
                               filter completion)
  (eval
   `(cl-defun ,func-sym ,var-syms
      ,(sor doc title)
      (interactive ,(cons 'list iargs))
      (let* ((pen-sh-update
              (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
             (shcmd (concat
                     (if (sor prettifier)
                         (concat
                          (sh-construct-envs `(("DO_PRETTY_PRINT" ,(if prettify "y" ""))))
                          " ")
                       "")
                     ,(flatten-once
                       (list
                        (list 'concat
                              (sh-construct-envs `(("LM_CACHE" ,(if cache "y" ""))))
                              " lm-complete "
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
                                     (let ((ret (pen-sn shcmd)))
                                       (message (concat ,func-name " done " (int-to-string i)))
                                       ret)))
                          ""))))
        (if (interactive-p)
            (cond
             ((and ,filter
                   mark-active)
              (replace-region (concat (pen-selected-text) result)))
             (,completion
              (etv result))
             ((or ,(not filter)
                  (>= (prefix-numeric-value current-prefix-arg) 4)
                  (not mark-active))
              (etv result))
             (t
              (replace-region result)))
          result)))))

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

                     ;; function
                     (title (ht-get yaml "title"))
                     (title-slug (slugify title))
                     (aliases (vector2list (ht-get yaml "aliases")))
                     (alias-slugs (mapcar 'intern (mapcar (lambda (s) (concat "pen-pf-" s)) (mapcar 'slugify aliases))))

                     ;; lm-complete
                     (cache (pen-yaml-test yaml "cache"))
                     ;; openai-complete.sh is the default LM completion command
                     ;; but the .prompt may specify a different one
                     (lm-command (or (ht-get yaml "lm-command")
                                     "openai-complete.sh"))

                     (in-development (pen-yaml-test yaml "in-development"))

                     ;; internals
                     (prompt (ht-get prompt "doc"))
                     (prefer-external (pen-yaml-test yaml "prefer-external"))
                     (conversation-mode (pen-yaml-test yaml "conversation-mode"))
                     (filter (pen-yaml-test yaml "filter"))
                     ;; Don't actually use this.
                     ;; But I can toggle to use the prettifier with a bool
                     (prettifier (ht-get yaml "prettifier"))
                     (collation-postprocessor (ht-get yaml "pen-collation-postprocessor"))
                     (completion (pen-yaml-test yaml "completion"))
                     (n-collate (ht-get yaml "n-collate"))

                     ;; API
                     (max-tokens (ht-get yaml "max-tokens"))
                     (temperature (ht-get yaml "temperature"))

                     ;; docs
                     (doc (ht-get yaml "doc"))
                     (problems (vector2list (ht-get yaml "problems")))
                     (design-patterns (vector2list (ht-get yaml "design-patterns")))
                     (todo (vector2list (ht-get yaml "todo")))
                     (aims (vector2list (ht-get yaml "aims")))
                     (future-titles (vector2list (ht-get yaml "future-titles")))

                     ;; variables
                     (vars (vector2list (ht-get yaml "vars")))
                     (examples (vector2list (ht-get yaml "examples")))
                     (preprocessors (vector2list (ht-get yaml "pen-preprocessors")))
                     (var-slugs (mapcar 'slugify vars))
                     (var-syms
                      (let ((ss (mapcar 'intern var-slugs)))
                        (message (concat "_" prettifier))
                        (if (sor prettifier)
                            ;; Add to the function definition the prettify key if the .prompt file specifies a prettifier
                            (setq ss (append ss '(&key prettify))))
                        ss))
                     (pen-defaults (vector2list (ht-get yaml "pen-defaults")))
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
                                       `(if mark-active
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

                (if (not in-development)
                    (let ((funcsym (define-prompt-function
                                     func-name func-sym var-syms doc
                                     title iargs prettify
                                     cache path var-slugs n-collate
                                     filter completion)))
                      (add-to-list 'pen-prompt-functions funcsym)
                      ;; Using memoization here is the more efficient way to memoize.
                      ;; TODO I'll sort it out later. I want an updating mechanism, which exists already using LM_CACHE.
                      ;; (if cache (memoize funcsym))
                      ))
                (message (concat "pen-mode: Loaded prompt function " func-name)))))))

(defun pen-filter-with-prompt-function ()
  (interactive)
  (let ((f (fz pen-prompt-functions nil nil "pen filter: ")))
    (if f
        (filter-selected-region-through-function (intern f)))))

(defun pen-run-prompt-function ()
  (interactive)
  (let* ((pen-sh-update (or pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 4)))
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

;; TODO
(require 'pen-openai)
(require 'pen-ocean)
(require 'pen-huggingface)

(provide 'pen)