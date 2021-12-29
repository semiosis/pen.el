;;; helm-fzf.el --- helm binding for FZF

;; Copyright (C) 2011 Free Software Foundation, Inc.

;; Author: Ivan Buda Mandura (ivan.mandura93@gmail.com)

;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))
;; Keywords: helm fzf

;;; Commentary:

;;; Code:

(require 'helm)
(require 'helm-files)
(require 's)
(require 'dash)

(defcustom helm-fzf-executable "fzf"
  "Default executable for fzf"
  :type 'stringp
  :group 'helm-fzf)

(defun helm-fzf--project-root ()
  (cl-loop for dir in '(".git/" ".hg/" ".svn/" ".git")
           when (locate-dominating-file default-directory dir)
           return it))

(defset helm-fzf-source
  (helm-build-async-source "fzf"
    :candidates-process 'helm-fzf--do-candidate-process
    :filter-one-by-one 'identity
    ;; Don't let there be a minimum. it's annoying
    :requires-pattern 0
    :action 'helm-find-file-or-marked
    :candidate-number-limit 9999))

(defun helm-fzf--do-candidate-process ()
  (let* ((cmd-args (-filter 'identity (list helm-fzf-executable
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

;;;###autoload
(defun helm-fzf (directory)
  (interactive "D")
  (let ((default-directory directory))
    (helm :sources '(helm-fzf-source)
          :buffer "*helm-fzf*")))

(defun helm-fzf-project-root ()
  (interactive)
  (let ((default-directory (helm-fzf--project-root)))
    (unless default-directory
      (error "Could not find the project root."))
    (helm :sources '(helm-fzf-source)
          :buffer "*helm-fzf*")))

(provide 'helm-fzf)

;;; helm-fzf.el ends here
