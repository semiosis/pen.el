(use-package persp-mode
  :ensure t)

;; This isn't really going to work because it needs a notion of which frame created it so it knows what to garbage collect
;; This is almost done. It needs a little more work
(defun on-frame-quit-write (path outvalue)
  (let* ((framename (frame-parameter termframe 'name))
         ;; (fun (str2sym (concat (slugify path) "-frame-quit-write-fun")))
         (fun (str2sym (concat (slugify framename) "-frame-quit-write-fun"))))
    (eval `(progn (defun ,fun (frame)
                    (interactive)
                    (message "%s" (concat "Running: " (sym2str ',fun)))
                    (write-string-to-file (str (eval-string ,outvalue)) ,path)
                    (remove-hook 'delete-frame-hook ',fun)
                    (fmakunbound ',fun))
                  (add-hook 'delete-frame-hook ',fun)))))

(defun on-kill-write-and-close-frame (path &optional outvalue)
  (write-to-file-on-buffer-exit path outvalue)
  (close-frame-on-buffer-exit))

(defun write-termfile ()
  ;; (interactive)

  (let ((outvalue (if (and (variable-p 'outvalue-local)
                           outvalue-local)
                      (str (eval-string outvalue-local))
                    (buffer-string))))
    (if (and (variable-p 'termfile-local)
             termfile-local)
        (write-string-to-file outvalue termfile-local))))

(defun write-to-file-on-buffer-exit (path &optional outvalue)
  (interactive)
  (defset-local termfile-local path)
  (defset-local outvalue-local outvalue)

  (add-hook 'kill-buffer-hook 'write-termfile))

(defun close-frame-on-buffer-exit ()
  (interactive)
  (defset-local termframe-local termframe))



;; This is the magic that closes frames automatically when killing an associated buffer
(defun close-local-termframe ()
  ;; (interactive)
  (if (and (variable-p 'termframe-local)
           termframe-local)
      (delete-frame termframe-local t)))
(add-hook 'kill-buffer-hook 'close-local-termframe t)



(defun after-make-frame-close-frame (frame)
  (remove-hook 'after-make-frame-functions 'after-make-frame-close-frame)
  (delete-frame frame t))
;; (add-hook 'after-make-frame-functions 'after-make-frame-close-frame)

(defun cancel-next-frame ()
  "The next frame opened will close immediately."
  (interactive)
  (add-hook 'after-make-frame-functions 'after-make-frame-close-frame))

;; This only needs to run once
(defvar pen-graphic-theme-set nil)
(defun after-make-frame-set-theme (frame)
  (if (and (display-graphic-p frame)
           (not pen-graphic-theme-set))

      (set-face-bold 'default t)
    (never (progn
             (reload-spacemacs-dark)
             (setq pen-graphic-theme-set t)))
    (message "skipping after-make-frame-set-theme")))

;; (add-hook 'after-make-frame-functions 'after-make-frame-set-theme)
(remove-hook 'after-make-frame-functions 'after-make-frame-set-theme)


(defun close-all-other-buffers-and-frames ()
  "Destroy all frames except this one, kill all buffers, display `*scratch*'."
  (interactive)
  (set-buffer "*scratch*")
  (delete-other-frames)
  ;; (let ((l (buffer-list)) b)
  ;;   (while l
  ;;     (setq b (car l)
  ;;           l (cdr l) )
  ;;     (and (buffer-file-name b)
  ;;          (kill-buffer b))))
  )


(defun kill-other-clients (&optional including-this-client)
  "Kills the emacsclient frames for clients"
  (interactive)
  (let ((this-frame (selected-frame)))
    (dolist (p
             (-filter 'identity
                      (mapcar
                       (lambda (f)
                         (frame-parameter f 'client))
                       (-filter
                        (lambda (f) (or including-this-client
                                        (not (equal this-frame f))))
                        (frame-list)))))
      (delete-process p))))


(define-key global-map (kbd "C-x 5 c") 'kill-other-clients)

(advice-add 'persp-restore-window-conf :around #'ignore-errors-around-advice)

(defset make-frame-created-frame nil)

;; Or I can learn to make j:make-terminal-frame start an emacsclient on a different tty.
;; This might be the only way.
;; (make-terminal-frame '((tty . "/dev/pts/5") (tty-type . "xterm")))

(comment
 (make-terminal-frame '((tty . "/dev/pts/2") (tty-type . "xterm")))

 ;; https://unix.stackexchange.com/questions/170063/start-a-process-on-a-different-tty
 ;; It works much the same way as this to start bash on pts 39
 ;; Therefore, I should try to figure this out.
 ;; "setsid -c /usr/local/bin/bash </dev/pts/39 >/dev/pts/39 2>&1"
 ;; runontty vim /dev/pts/42
 )

(defun make-frame-setup ()
  (setq make-frame-created-frame (selected-frame))
  (scratch-buffer))

(defun make-frame-tmux (&rest args)
  (interactive)
  (tpop (concat "pen-e -D " (show-workerp) " -e \"(make-frame-setup)\""))
  ;; Now I need to ensure that there is an appropriate wait time before returning
  ;; However, this might be an impossible ask because the shell script needs to create the
  ;; frame first.
  ;; Therefore, perhaps I should create the frame first.

  ;; Hmm. Yes. Use (make-frame) to create the frame in advance?
  ;; make-frame-created-frame

  ;; That seems too difficult as the frame must contain important parameters.
  ;; Instead, just 
  )


;; TODO 
;; - Make the make-frame function use tmux as well

;; (frame-list)
;;
;; j:delete-other-frames

;; Override the original function
;; But this needs to return the new frame
;; (defun make-terminal-frame (&rest args)
;;   (let ((frame 
;;          (make-frame)))))

(provide 'pen-frame)
