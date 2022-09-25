(require 'docker-compose)

;; # Because of lexical-binding, I must edit the plugin directly
;; Although that seems to no longer be required

;; v +/";;; docker-machine.el --- Emacs interface to docker-machine  -\*- lexical-binding: t -\*-" "$EMACSD/manual-packages/docker.el/docker-machine.el"

(defun docker-container-copy-ip ()
  "Copy the IP address of on the containers selection."
  (interactive)
  (docker-utils-ensure-items)
  (--each
      (docker-utils-get-marked-items-ids)
    (pen-copy (chomp (pen-sn (concat "docker inspect " it " | jq -r \".[].NetworkSettings.IPAddress\""))))))

(defun docker-container-commit (container)
  "Open a zrepl with docker commit."
  (interactive
   (list
    (docker-container-read-name)))
  (zrepl
   (concat "docker commit " container " ")))

;; I don't think exec uses --entrypoint
(defun docker-container-sh (container &optional prefix)
  "Open `sh' in CONTAINER."
  (interactive
   (list
    (docker-container-read-name)))
  (sps
   (concat "docker exec -it " container " sh -c \"/bin/bash || /bin/zsh || sh\"; pen-pak")))

;; Also must decide on the user to use. Default, root
(defun docker-container-py (container &optional prefix)
  "Open `python / ipython / ptpython' in CONTAINER."
  (interactive
   (list
    (docker-container-read-name)))
  (pen-sn (concat "docker exec -it " container " pip3 install ptpython"))
  (pen-sn (concat "docker cp /home/shane/.ptpython " container ":$HOME/.ptpython"))
  (pen-sn (concat "docker cp $PENEL/scripts/container-start-ptpython " container ":$HOME/container-start-ptpython"))
  (sps
   (concat "docker exec -it " container " $HOME/container-start-ptpython")))

(defun docker-container-sh-fmg (container &optional prefix)
  "Open `sh' in CONTAINER with FMG environment set."
  (interactive
   (list
    (docker-container-read-name)))
  (pen-sn (concat "docker cp $PENEL/scripts/container-start-fmg-env " container ":$HOME/container-start-fmg-env"))
  (sps
   (concat "docker exec -it " container " $HOME/container-start-fmg-env")))

(defun docker-container-sh-selection (prefix)
  "Run `docker-container-sh' on the containers selection."
  (interactive "P")
  (docker-utils-ensure-items)
  (--each
      (docker-utils-get-marked-items-ids)
    (docker-container-sh it prefix)))

(defun docker-container-sh-fmg-selection (prefix)
  "Run `docker-container-sh-fmg' on the containers selection."
  (interactive "P")
  (docker-utils-ensure-items)
  (--each
      (docker-utils-get-marked-items-ids)
    (docker-container-sh-fmg it prefix)))

(defun docker-container-py-selection (prefix)
  "Run `docker-container-py' on the containers selection."
  (interactive "P")
  (docker-utils-ensure-items)
  (--each
      (docker-utils-get-marked-items-ids)
    (docker-container-py it prefix)))

(defun docker-container-dive (container)
  "Open `dive' on CONTAINER."
  (interactive (list (docker-container-read-name)))
  (pen-sps (concat "edive -C " container)))

(defun docker-container-dive-selection nil "Run `dive' on the containers selection."
       (interactive)
       (docker-utils-ensure-items)
       (let
           ((list
             (docker-utils-get-marked-items-ids))
            (it-index 0))
         (while list
           (let
               ((it
                 (car list)))
             (docker-container-dive it))
           (setq it-index
                 (1+ it-index))
           (setq list
                 (cdr list)))))

(defun docker-image-dive-selection ()
  "Run edive on selection."
  (interactive)
  (docker-utils-ensure-items)
  (let
      ((list
        (docker-utils-get-marked-items-ids))
       (it-index 0))
    (while list
      (let
          ((it
            (car list)))
        (sps
         (concat "edive " it)))
      (setq it-index
            (1+ it-index))
      (setq list
            (cdr list)))))

(defun docker-image-run-sh-selection ()
  "Run docker-run-sh on selection."
  (interactive)
  (docker-utils-ensure-items)
  (let
      ((list
        (docker-utils-get-marked-items-ids))
       (it-index 0))
    (while list
      (let
          ((it
            (car list)))
        (sps
         (concat "docker-run-sh " it)))
      (setq it-index
            (1+ it-index))
      (setq list
            (cdr list)))))

(defun docker-image-tags ()
  "Run docker-run-sh on selection."
  (interactive)
  (docker-utils-ensure-items)
  (let
      ((list
        (docker-utils-get-marked-items-ids))
       (it-index 0))
    (while list
      (let
          ((it
            (car list)))
        (sps
         (concat "dockerhub-list-tags " it)))
      (setq it-index
            (1+ it-index))
      (setq list
            (cdr list)))))

(defun docker-image-run-default-selection ()
  "Run docker-run-default on selection."
  (interactive)
  (docker-utils-ensure-items)
  (let
      ((list
        (docker-utils-get-marked-items-ids))
       (it-index 0))
    (while list
      (let
          ((it
            (car list)))
        (sps
         (concat "docker-run-default " it)))
      (setq it-index
            (1+ it-index))
      (setq list
            (cdr list)))))

(defun docker-image-run-command-selection ()
  "Run docker-run-default on selection."
  (interactive)
  (docker-utils-ensure-items)
  (let
      ((list
        (docker-utils-get-marked-items-ids))
       (it-index 0))
    (while list
      (let
          ((it
            (car list)))
        (sps
         (concat "docker-run-command " it)))
      (setq it-index
            (1+ it-index))
      (setq list
            (cdr list)))))

(defun docker-container-eranger (container &optional read-shell)
  "Open `sh' in CONTAINER.  When READ-SHELL is not nil, ask the user for it."
  (interactive
   (list
    (docker-container-read-name)
    current-prefix-arg))
  (let*
      ((sh-file-name
        (docker-container--read-shell read-shell))
       (container-address
        (format "docker:%s:/" container))
       (file-prefix
        (let
            ((prefix
              (file-remote-p default-directory)))
          (if prefix
              (format "%s|"
                      (s-chop-suffix ":" prefix))
            "/")))
       (default-directory
         (format "%s%s" file-prefix container-address)))
    (ranger default-directory)))

(defun docker-container-eranger-selection (prefix)
  "Run `docker-container-eranger' on the containers selection."
  (interactive "P")
  (docker-utils-ensure-items)
  (--each
      (docker-utils-get-marked-items-ids)
    (docker-container-eranger it prefix)))

;; This works
(defset docker-container-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "?" 'docker-container-help)
    (define-key map "C" 'docker-container-cp)
    (define-key map "D" 'docker-container-rm)
    (define-key map "I" 'docker-container-inspect)
    (define-key map "K" 'docker-container-kill)
    (define-key map "L" 'docker-container-logs)
    (define-key map "O" 'docker-container-stop)
    (define-key map ";" 'docker-container-sh-selection)
    (define-key map "i" 'docker-container-copy-ip)
    (define-key map "M" 'docker-container-commit)
    (define-key map "z" 'docker-container-eranger-selection)
    (define-key map "P" 'docker-container-pause)
    (define-key map "R" 'docker-container-restart)
    (define-key map "S" 'docker-container-start)
    (define-key map "a" 'docker-container-attach)
    (define-key map "b" 'docker-container-shells)
    (define-key map "d" 'docker-container-diff)
    (define-key map "f" 'docker-container-open)
    (define-key map "l" 'docker-container-ls)
    (define-key map "r" 'docker-container-rename-selection)
    map)
  "Keymap for `docker-container-mode'.")

(define-transient-command docker-container-help ()
  "Help transient for docker containers."
  ["Docker containers help"
   ("C" "Copy"       docker-container-cp)
   ("D" "Remove"     docker-container-rm)
   ("I" "Inspect"    docker-container-inspect)
   ("K" "Kill"       docker-container-kill)
   ("L" "Logs"       docker-container-logs)
   ("O" "Stop"       docker-container-stop)
   ("P" "Pause"      docker-container-pause)
   ("R" "Restart"    docker-container-restart)
   ("S" "Start"      docker-container-start)
   (";" "sh"         docker-container-sh-selection)
   ("z" "eranger"    docker-container-eranger-selection)
   ("i" "copy IP"    docker-container-copy-ip)
   ("M" "commit"     docker-container-commit)
   ("a" "Attach"     docker-container-attach)
   ("b" "Shell"      docker-container-shells)
   ("d" "Diff"       docker-container-diff)
   ("f" "Find file"  docker-container-open)
   ("l" "List"       docker-container-ls)
   ("r" "Rename"     docker-container-rename-selection)])

(docker-utils-define-transient-command docker-container-shells ()
  "Transient for doing M-x `shell'/`eshell' to containers."
  [:description docker-utils-generic-actions-heading
   ("b" "Shell" docker-container-shell-selection)
   ("e" "Eshell" docker-container-eshell-selection)
   ("z" "eranger" docker-container-eranger-selection)
   (";" "sh" docker-container-sh-selection)
   ("y" "py" docker-container-py-selection)
   ("f" "sh-fmg" docker-container-sh-fmg-selection)])

(define-transient-command docker-image-help ()
  "Help transient for docker images."
  ["Docker images help"
   ("D" "Remove"  docker-image-rm)
   ("F" "Pull"    docker-image-pull)
   ("I" "Inspect" docker-image-inspect)
   ("P" "Push"    docker-image-push)
   ("v" "edive"    docker-image-dive-selection)
   ("r" "zrepl run"    docker-image-run-command-selection)
   ("d" "zrepl run default"    docker-image-run-default-selection)
   ("c" "copy cmd"    docker-image-copy-cmd)
   ("e" "copy entrypoint"    docker-image-copy-entrypoint)
   ("a" "copy entrypoint and command"    docker-image-copy-entrypoint-and-cmd)
   ("b" "zrepl run sh"    docker-image-run-sh-selection)
   ("L" "show tags"    docker-image-tags)
   (";" "zrepl run sh"    docker-image-run-sh-selection)
   ("R" "Run"     docker-image-run)
   ("T" "Tag"     docker-image-tag-selection)
   ("l" "List"    docker-image-ls)])

(defset docker-image-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "?" 'docker-image-help)
    (define-key map "D" 'docker-image-rm)
    (define-key map "F" 'docker-image-pull)
    (define-key map "I" 'docker-image-inspect)
    (define-key map "P" 'docker-image-push)
    (define-key map "v" 'docker-image-dive-selection)
    (define-key map "r" 'docker-image-run-command-selection)
    (define-key map "d" 'docker-image-run-default-selection)
    (define-key map "c" 'docker-image-copy-cmd)
    (define-key map "e" 'docker-image-copy-entrypoint)
    (define-key map "a" 'docker-image-copy-entrypoint-and-cmd)
    (define-key map "L" 'docker-image-tags)
    (define-key map "b" 'docker-image-run-sh-selection)
    (define-key map ";" 'docker-image-run-sh-selection)
    (define-key map "R" 'docker-image-run)
    (define-key map "T" 'docker-image-tag-selection)
    (define-key map "l" 'docker-image-ls)
    map)
  "Keymap for `docker-image-mode'.")

(defun docker-machine-ssh-one (name)
  "Start an ssh shell on machine."
  (interactive (list (docker-machine-read-name)))
  (pen-sps (concat "docker-machine ssh " name)))

(defun docker-machine-ssh-selection ()
  "Run \"docker-machine ssh\" on selected machine."
  (interactive)
  (let ((marked (docker-utils-get-marked-items-ids)))
    (when (/= (length marked) 1)
      (error "Can only set environment vars for one machine at a time"))
    (docker-machine-ssh-one (car marked))
    (tablist-revert)))

(docker-utils-define-transient-command docker-machine-ssh ()
  "Transient for running ssh commands."
  :man-page "docker-machine-ssh"
  [:description docker-utils-generic-actions-heading
                (";" "SSH" docker-machine-ssh-selection)])

(defun docker-machine-env-unset ()
  (interactive)
  (setenv "DOCKER_TLS_VERIFY" nil)
  (setenv "DOCKER_HOST" nil)
  (setenv "DOCKER_CERT_PATH" nil)
  (setenv "DOCKER_MACHINE_NAME" nil)
  (message "Unset docker machine environment. Default machine is now localhost."))

(defun docker-select-one ()
  "Get a single selected item, or the one under the cursor"
  (docker-utils-ensure-items)
  (let ((marked (docker-utils-get-marked-items-ids)))
    (when (/= (length marked) 1)
      (error "This function requires one selection at a time"))
    (car marked)))

(defun docker-machine-env-selection-edit ()
  "Run \"docker-machine env\" on selected machine."
  (interactive)
  (docker-utils-ensure-items)
  (let ((marked (docker-utils-get-marked-items-ids)))
    (when (/= (length marked) 1)
      (error "Can only set environment vars for one machine at a time"))
    (new-buffer-from-string (pen-sn (concat "docker-machine env " (car marked))))))

(defun docker-machine-regenerate-certs ()
  "Run \"docker-machine env\" on selected machine."
  (interactive)
  (docker-utils-ensure-items)
  (let ((marked (docker-utils-get-marked-items-ids)))
    (when (/= (length marked) 1)
      (error "Can only set environment vars for one machine at a time"))
    ;; (pen-term-nsfa (concat "set -xv; nvc -pak docker-machine regenerate-certs " (car marked)))
    (pen-term-nsfa (concat "set -xv; docker-machine regenerate-certs " (car marked) " ; pen-pak"))))

(define-transient-command docker-machine-help ()
  "Help transient for docker machine."
  ["Docker machines help"
   ("C" "Create"     docker-machine-create)
   ("D" "Remove"     docker-machine-rm)
   ("E" "Env"        docker-machine-env-selection)
   ("e" "Env"        docker-machine-env-selection-edit)
   ("H" "Unset Env"  docker-machine-env-unset)
   ("r" "Regen Certs"  docker-machine-regenerate-certs)
   (";" "SSH"        docker-machine-ssh-selection)
   ("O" "Stop"       docker-machine-stop)
   ("R" "Restart"    docker-machine-restart)
   ("S" "Start"      docker-machine-start)
   ("l" "List"       docker-machine-ls)])

(defset docker-machine-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "?" 'docker-machine-help)
    (define-key map "C" 'docker-machine-create)
    (define-key map "D" 'docker-machine-rm)
    (define-key map "E" 'docker-machine-env-selection)
    (define-key map "e" 'docker-machine-env-selection-edit)
    (define-key map "H" 'docker-machine-env-unset)
    (define-key map "r" 'docker-machine-regenerate-certs)
    (define-key map ";" 'docker-machine-ssh-selection)
    (define-key map "O" 'docker-machine-stop)
    (define-key map "R" 'docker-machine-restart)
    (define-key map "S" 'docker-machine-start)
    (define-key map "l" 'docker-machine-ls)
    map)
  "Keymap for `docker-machine-mode'.")

(defun docker-image-copy-entrypoint-and-cmd (&optional image)
  (interactive)
  (if (not image)
      (setq image (docker-select-one)))
  (xc (chomp (pen-sn (concat "docker-get-entrypoint-and-cmd " image)))))

;; TODO Make a keybinding for this -- w
(defun docker-image-copy-name-and-tag ()
  (interactive)
  (let ((l (vector2list (tabulated-list-get-entry))))
    (xc (concat (nth (tabulated-list-current-column) l)
                     ":"
                     (nth (+ 1 (tabulated-list-current-column)) l)))))

(defun docker-image-copy-cmd (&optional image)
  (interactive)
  (if (not image)
      (setq image (docker-select-one)))
  (xc (chomp (pen-sn (concat "docker-get-cmd " image)))))

(defun docker-image-copy-entrypoint (&optional image)
  (interactive)
  (if (not image)
      (setq image (docker-select-one)))
  (xc (chomp (pen-sn (concat "docker-get-entrypoint " image)))))

(defun ff-dockerhub (&optional image)
  (interactive)
  (if (not image)
      (setq image (docker-select-one)))
  (pen-sps (concat "ff-dockerhub " image)))

(defun ff-dockerfile (&optional image)
  (interactive)
  (if (not image)
      (setq image (docker-select-one)))
  (pen-sps (concat "ff-dockerhub -d " image)))


(defun pen-docker-pull-specific-tag ()
  ""
  (interactive)
  (--each (docker-utils-get-marked-items-ids)
    (pen-sps (concat "pen-docker pull -s " it)))
  (tablist-revert))


(define-transient-command docker-image-pull ()
  "Transient for pulling images."
  :man-page "docker-image-pull"
  ["Arguments"
   ("-a" "All" "-a")]
  [:description docker-utils-generic-actions-heading
   ("F" "Pull selection" docker-utils-generic-action)
   ("T" "Pull specific tag (sps)" pen-docker-pull-specific-tag)
   ("N" "Pull a new image" docker-image-pull-one)])


;; The below is non-'docker.el' related

(require 'json-mode)

(defun docker-utils-inspect ()
  "Docker Inspect the tablist entry under point."
  (interactive)
  (let ((entry-id (tabulated-list-get-id)))
    (docker-utils-with-buffer (format "inspect %s" entry-id)
      (insert (docker-run-docker "inspect" () entry-id))
      (json-mode)
      (view-mode))))

(provide 'pen-docker)
