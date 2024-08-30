(require 'helm-fzf)

(defcustom helm-broot-grep-executable "broot-grep"
  "Default executable for broot-grep"
  :type 'stringp
  :group 'helm-broot-grep)

(defun helm-broot-grep (directory &optional init)
  (interactive "D")
  (let ((default-directory directory))
    (helm :sources '(helm-broot-grep-source)

          :buffer "*helm-broot-grep*"
          :input init)))

(defun helm-broot-grep--do-candidate-process ()
  (let* ((cmd-args (-filter 'identity (list helm-broot-grep-executable
                                            ;; "--tac"
                                            ;; "--no-sort"
                                            ;; "-f"
                                            helm-pattern)))
         (proc (apply 'start-file-process "helm-broot-grep" helm-buffer cmd-args)))
    (prog1 proc
      (set-process-sentinel
       (get-buffer-process helm-buffer)
       #'(lambda (process event)
         (helm-process-deferred-sentinel-hook
          process event (helm-default-directory)))))))

(defset helm-broot-grep-source
  (helm-build-async-source "fzf"
    :candidates-process 'helm-broot-grep--do-candidate-process
    :filter-one-by-one 'identity
    ;; Don't let there be a minimum. it's annoying
    :requires-pattern 0
    :action 'helm-find-file-or-marked
    :candidate-number-limit 9999))

;; TODO Make it so 2 prefixes M-u M-u will give it a maxdepth of 2
(defun pen-helm-broot-grep (&optional top depth)
  (interactive)
  (let ((dir (if (or top (equalp current-prefix-arg '(4)))
                 (vc-get-top-level)
               (pen-pwd))))
    (let ((current-prefix-arg nil))
      (helm-broot-grep dir
                (if (pen-selected-p)
                    (concat "'" (pen-selection)))))))

(defun pen-helm-broot-grep-top ()
  (interactive)
  (pen-helm-broot-grep t))

(setq helm-broot-grep-executable "broot-grep")

(provide 'pen-helm-broot-grep)
