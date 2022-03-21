(require 'helm-fzf)

;; Show dotfiles
;; export FZF_DEFAULT_COMMAND="find -L"
;; ag --hidden --ignore .git -f -g ""

;; TODO Implement maxdepth, I will need to learn how to configure helm in more detail
;; $MYGIT/jkitchin/jkitchin.github.com/org/2015/02/03/helm-and-prefix-functions.org
(defun helm-fzf-d2 (directory &optional init)
  (interactive "D")
  (let ((default-directory directory))
    (helm :sources '(helm-fzf-source-d2)

          :buffer "*helm-fzf*"
          :input init)))

(defun helm-fzf (directory &optional init)
  (interactive "D")
  (let ((default-directory directory))
    (helm :sources '(helm-fzf-source)

          :buffer "*helm-fzf*"
          :input init)))

(defun helm-fzf--do-candidate-process-d2 ()
  (let* ((cmd-args (-filter 'identity (list helm-fzf-executable-d2
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

(defset helm-fzf-source-d2
  (helm-build-async-source "fzf"
    :candidates-process 'helm-fzf--do-candidate-process-d2
    :filter-one-by-one 'identity
    ;; Don't let there be a minimum. it's annoying
    :requires-pattern 0
    :action 'helm-find-file-or-marked
    :candidate-number-limit 9999))

;; TODO Make it so 2 prefixes M-u M-u will give it a maxdepth of 2
(defun pen-helm-fzf (&optional top depth)
  (interactive)
  (let ((dir (if (or top (equalp current-prefix-arg '(4)))
                 (vc-get-top-level)
               (pen-pwd))))
    (if (equalp current-prefix-arg '(16))
        (progn
          (let ((current-prefix-arg nil))
            (helm-fzf-d2 dir
                         (if (pen-selected-p)
                             (concat "'" (pen-selection))))))
      (let ((current-prefix-arg nil))
        (helm-fzf dir
                  (if (pen-selected-p)
                      (concat "'" (pen-selection))))))))

(defun pen-helm-fzf-top ()
  (interactive)
  (pen-helm-fzf t))

;; (setq helm-fzf-executable (sh-notty "alt -q fzf"))
(setq helm-fzf-executable "pen-helm-fzf.sh")
(setq helm-fzf-executable-d2 "pen-helm-fzf-d2.sh")

(defun pen-helm-fzf (&optional top depth)
  (interactive)
  (let ((dir (if (or top (equalp current-prefix-arg '(4)))
                 (vc-get-top-level)
               (pen-pwd))))
    (if (equalp current-prefix-arg '(16))
        (progn
          (helm-fzf-d2 dir
                       (if (pen-selected-p)
                           (concat "'" (pen-selection)))))
      (helm-fzf dir
                (if (pen-selected-p)
                    (concat "'" (pen-selection)))))))

(provide 'pen-helm-fzf)
