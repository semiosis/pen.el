(require 'prodigy)

;; elinks "http://localhost:8000/README.html"

;; TODO Make a handler to view the service but based on the type of service.
;; So do something like this:
;; - j:pen-server-suggest

;; ev:prodigy-services

(define-key prodigy-mode-map (kbd "v") #'prodigy-display-process)
(prodigy-define-service
  :name "theology@localhost"
  :command "python2"
  :args '("-m" "SimpleHTTPServer" "8000")
  :cwd "/volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/"
  :tags '(file-server)
  :stop-signal 'sigkill
  :kill-process-buffer-on-stop t)

(comment
 (prodigy-define-service
   :name "start-background-processes"
   :command "start-background-processes"
   :args '()
   :cwd "~/"
   :tags '(bash init)
   :stop-signal 'sigint
   :kill-process-buffer-on-stop t)

 (prodigy-define-service
   :name "datomic"
   :command "datomic-start-local-transactor"
   :args '()
   :cwd "~/"
   :port 4334
   :tags '(bash init)
   :stop-signal 'sigint
   :kill-process-buffer-on-stop t)

 (prodigy-define-service
   :name "pydoc3.5"
   :command "pydoc3.5"
   :args '("-p" "7035")
   :cwd "~/"
   :tags '(python)
   :stop-signal 'sigkill
   :kill-process-buffer-on-stop t)

 (prodigy-define-service
   :name "pydoc3.6"
   :command "pydoc3.6"
   :args '("-p" "7036")
   :cwd "~/"
   :tags '(python)
   :stop-signal 'sigkill
   :kill-process-buffer-on-stop t)

 (prodigy-define-service
   :name "pydoc3.7"
   :command "pydoc3.7"
   :args '("-p" "7037")
   :cwd "~/"
   :tags '(python)
   :stop-signal 'sigkill
   :kill-process-buffer-on-stop t)

 (prodigy-define-service
   :name "start hugo server"
   :command "start-hugo-server"
   :args '("-p" "8580")
   :cwd "/home/shane/dump/home/shane/notes/ws/blog/blog"
   :tags '(hugo)
   :stop-signal 'sigkill
   :kill-process-buffer-on-stop t)

 (prodigy-define-service
   :name "start fortescue hugo server"
   :command "start-fmg-hugo-server"
   :args '("-p" "8680")
   :cwd "/home/shane/dump/home/shane/notes/ws/fmg-fortesque-metals-group/blog-hugo"
   :tags '(hugo)
   :stop-signal 'sigkill
   :kill-process-buffer-on-stop t)

 (prodigy-define-service
   :name "port-forward to k8s elasticsearch"
   :command "k8s-es-port-forward"
   :args '()
   :cwd "/home/shane"
   :tags '(es k8s)
   :stop-signal 'sigint
   :kill-process-buffer-on-stop t))

;; prodigy isn't really appropriate for this
;; (prodigy-define-service
;;   :name "google for coffee"
;;   :command "gl"
;;   :args '("-notty" "-loop" "5" "coffee" "near" "me")
;;   :cwd "/home/shane"
;;   :tags '(coffee)
;;   :stop-signal 'sigint
;;   :kill-process-buffer-on-stop t)

;; How to add an elisp function?
;; clomacs-httpd-start

;; Added support for callback
(defun prodigy-start (&optional callback)
  "Start service at line or marked services."
  (interactive)
  (prodigy-with-refresh
   (-each (prodigy-relevant-services)
     (if callback
         (lambda (service)
           (prodigy-start-service service callback))
       'prodigy-start-service))))

(defun org-link--prodigy (service-name)
  (save-window-excursion
    (prodigy)

    (prodigy-first)
    ;; (pen-tv (pps service-name))
    (search-forward (concat "     " service-name "  "))
    ;; (prodigy-start)
    (prodigy-start (eval
                    `(lambda () (message (format "Started %S" ,service-name)))))
    (pen-prodigy-copy 0)
    ;; (ekm "r")
    ))

(org-add-link-type "prodigy" 'org-link--prodigy)

(defun prodigy-copy-name ()
  (interactive)
  (xc (concat "[[prodigy:" (prodigy--imenu-extract-index-name) "]]")))

(defun pen-prodigy-copy (arg)
  (interactive "P")

  (if (not arg)
      (setq arg 7))

  (cond
   ((= arg 0) (prodigy-copy-url))
   (t (prodigy-copy-name))))

(define-key prodigy-mode-map (kbd "w") 'pen-prodigy-copy)

(defun pen-prodigy-mouse-click (event)
  (interactive (list (get-pos-for-x-popup-menu)))

  (let* ((ec (event-start event))
         (choice ;; (x-popup-menu event prodigy-mode-menu)
          (popup-menu prodigy-mode-menu event))
         ;; (action (lookup-key prodigy-mode-menu (apply 'vector choice)))
         )))

;; prodigy-unmark-all

(provide 'pen-prodigy)
