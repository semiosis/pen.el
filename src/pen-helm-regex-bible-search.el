(require 'helm-fzf)
(require 'pen-bible-mode)

(defset pen-helm-regex-bible-search-translation "BSB")

(defcustom helm-regex-bible-search-executable "regex-bible-search"
  "Default executable for regex-bible-search"
  :type 'stringp
  :group 'helm-regex-bible-search)

(defun helm-regex-bible-search (&optional init)
  (interactive)

  (let ((translations '("AKJV" "AMP" "ASV" "BBE" "BSB" "DBY" "ESV" "GEN" "KJV" "MSG" "NASB" "UKJV" "WBT" "WEB" "YLT"))
        (modname (and (major-mode-p 'bible-mode)
                      (s-upcase (bible-shorten-module-name bible-mode-book-module)))))
    (setq pen-helm-regex-bible-search-translation
          (if (and (major-mode-p 'bible-mode)
                   (member modname translations))
              modname
            (fz translations
                nil nil "pen-helm-regex-bible-search in translation:")))

    (helm :sources '(helm-regex-bible-search-source)

          :buffer "*helm-regex-bible-search*"
          :input init
          ;; :prompt "example: /\.el/&c/pen | query: "
          :prompt (concat "[" pen-helm-regex-bible-search-translation "] eg: blessed.*is | query: "))))

(defun helm-regex-bible-search--do-candidate-process ()
  (let* ((cmd-args (-filter 'identity (list helm-regex-bible-search-executable
                                            ;; "--tac"
                                            ;; "--no-sort"
                                            ;; "-f"
                                            pen-helm-regex-bible-search-translation
                                            helm-pattern)))
         (proc (apply 'start-file-process "helm-regex-bible-search" helm-buffer cmd-args)))
    (prog1 proc
      (set-process-sentinel
       (get-buffer-process helm-buffer)
       #'(lambda (process event)
         (helm-process-deferred-sentinel-hook
          process event (helm-default-directory)))))))

(defun helm-regex-bible-search-format-results (line)
  (if (sor line)
      (let* ((cols (s-split "\t" line))
             (book (string-to-int (car cols)))
             (chapter (string-to-int (second cols)))
             (versecount (string-to-int (third cols)))
             (verse (fourth cols)))
    
        (message "%s" line)
        (concat (bible-book-tinyname (bible-book-name-from-number book))
                " " (int-to-string chapter)
                ":"
                (int-to-string versecount)
                " - "
                verse)
        ;; line
        ;; (bible-book-name-from-number 65)
        )))

;; It's a little annoying that after adding this formatter, it prints nil as the last result
(defun pen-helm-tegex-bible-search-goto-result (result)
  (sor (let* ((cols (s-split " - " result))
              (ref (car cols)))
         (bible-mode-lookup-ref ref))))

(defset helm-regex-bible-search-source
        (helm-build-async-source "fzf"
          :candidates-process 'helm-regex-bible-search--do-candidate-process
          :filter-one-by-one 'helm-regex-bible-search-format-results
          ;; :filter-one-by-one 'identity
          ;; Don't let there be a minimum. it's annoying
          :requires-pattern 0
          :action 'pen-helm-tegex-bible-search-goto-result
          :candidate-number-limit 9999))

;; TODO Make it so 2 prefixes M-u M-u will give it a maxdepth of 2
(defun pen-helm-regex-bible-search (&optional top depth)
  (interactive)
  (let ((dir (if (or top (equalp current-prefix-arg '(4)))
                 (vc-get-top-level)
               (pen-pwd))))
    (let ((current-prefix-arg nil))
      (helm-regex-bible-search dir
                (if (pen-selected-p)
                    (concat "'" (pen-selection)))))))

(defun pen-helm-regex-bible-search-top ()
  (interactive)
  (pen-helm-regex-bible-search t))

(setq helm-regex-bible-search-executable "regex-bible-search")

(provide 'pen-helm-regex-bible-search)
