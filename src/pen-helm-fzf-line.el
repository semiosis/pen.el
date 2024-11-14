;; TODO Make an fzf alternative to j:pen-swipe

;; TODO
;; I need to pass the file path if it exists to the fzf command
;;; If the file path doesn't exist then I should pass the

;; e:pen-helm-fzf-line.sh

(defun helm-fzf-line (directory &optional init)
  (interactive "D")
  (let ((default-directory directory))
    (helm :sources '(helm-fzf-line-source)

          :buffer "*helm-fzf*"
          :input init)))

(defun helm-fzf-line--do-candidate-process ()
  (let* ((cmd-args (-filter 'identity (list helm-fzf-line-executable
                                            "--tac"
                                            "--no-sort"
                                            "-f"
                                            helm-pattern)))
         (proc (apply 'start-file-process "helm-fzf" helm-buffer cmd-args)))
    (prog1 proc
      (set-process-sentinel
       (get-buffer-process helm-buffer)
       #'(lambda (process event)
         (helm-process-deferred-sentinel-hook
          process event (helm-default-directory)))))))

(defset helm-fzf-line-source
  (helm-build-async-source "fzf"
    :candidates-process 'helm-fzf-line--do-candidate-process
    :filter-one-by-one 'identity
    ;; Don't let there be a minimum. it's annoying
    :requires-pattern 0
    :action 'helm-find-file-or-marked
    :candidate-number-limit 9999))


(defun pen-helm-fzf-line (&optional top depth)
  (interactive)
  (let ((dir (if (or top (equalp current-prefix-arg '(4)))
                 (vc-get-top-level)
               (pen-pwd))))

    (let ((gparg (prefix-numeric-value current-prefix-arg))
          (current-prefix-arg nil))

      (let ((current-prefix-arg nil))
        (helm-fzf-line dir
                     (if (pen-selected-p)
                         (concat "'" (pen-selection))))))))

(setq helm-fzf-line-executable "pen-helm-fzf-line.sh")

(provide 'pen-helm-fzf-line)
