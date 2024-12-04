;; For some reason, it wasn't loading properly
(add-hook 'after-init-hook (lambda () (load-library "pen-org-agenda")))

;; Why isn't this working?
;; (add-hook 'after-make-frame-functions (lambda (frame) (load-library "pen-org-link-types")))

(defun after-init-loads ()
  (interactive)
  (load-library "ol-info")
  (load-library "pen-org-link-types"))

(add-hook 'after-init-hook 'after-init-loads)

(defun pen-tcp-server-get-port ()
  (if (f-dir-p "/root/.pen/")
      (progn    
        (mkdir-p "/root/.pen/emacs-tcp-server-ports")
        (let* ((port
                (+ 5000 
                   (/ (hex2dec (crc32 (daemonp))) 10000000)))
               (fp (f-join "/root/.pen/emacs-tcp-server-ports" (daemonp))))
          (f-touch fp)
          (write-to-file (str port) fp)
          port))))

(defun pen-start-tcp-server-repl ()
  (interactive)
  (sps (cmd-f "zrepl" "pen-tcp-server" (str (pen-tcp-server-get-port)) "(tetris)")))

;; [[sh:"pen-tcp-server" "5369" "(pen-disable-all-faces)"]]
;; [[sh:"pen-tcp-server" "5369" "(pen-enable-all-faces)"]]

(defun pen-start-tcp-server ()
  (interactive)
  ;; I should also save the ports somewhere.
  ;; This way I can send commands to emacs from shell scripts, such as toggling black and white mode
  
  (ignore-errors
    (let ((port (pen-tcp-server-get-port)))
      (tcp-server-start port))))

(add-hook 'after-init-hook 'pen-start-tcp-server)

(provide 'pen-after-init)
