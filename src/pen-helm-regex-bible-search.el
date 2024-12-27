(require 'helm-fzf)

(defcustom helm-regex-bible-search-executable "regex-bible-search"
  "Default executable for regex-bible-search"
  :type 'stringp
  :group 'helm-regex-bible-search)

(defun helm-regex-bible-search (&optional init)
  (interactive)
  (helm :sources '(helm-regex-bible-search-source)

        :buffer "*helm-regex-bible-search*"
        :input init
        ;; :prompt "example: /\.el/&c/pen | query: "
        :prompt "example: blessed.*is | query: "))

(defun helm-regex-bible-search--do-candidate-process ()
  (let* ((cmd-args (-filter 'identity (list helm-regex-bible-search-executable
                                            ;; "--tac"
                                            ;; "--no-sort"
                                            ;; "-f"
                                            "BSB"
                                            helm-pattern)))
         (proc (apply 'start-file-process "helm-regex-bible-search" helm-buffer cmd-args)))
    (prog1 proc
      (set-process-sentinel
       (get-buffer-process helm-buffer)
       #'(lambda (process event)
         (helm-process-deferred-sentinel-hook
          process event (helm-default-directory)))))))

(defset helm-regex-bible-search-source
  (helm-build-async-source "fzf"
    :candidates-process 'helm-regex-bible-search--do-candidate-process
    :filter-one-by-one 'identity
    ;; Don't let there be a minimum. it's annoying
    :requires-pattern 0
    :action 'helm-find-file-or-marked
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
