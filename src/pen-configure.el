(require 'f)

(defvar penconfdir (f-join user-home-directory ".pen"))
(defvar genhistdir (f-join penconfdir "gen-history"))

(if (not (f-dir-p penconfdir))
    (f-mkdir penconfdir))

(if (not (f-dir-p genhistdir))
    (f-mkdir genhistdir))

(defun pen-edit-conf ()
  (interactive)
  (find-file (f-join penconfdir "pen.yaml")))

(defun pen-edit-efm-conf ()
  (interactive)
  (cond
   ((f-exists? (f-join pen-penel-directory "config" "efm-langserver-config.yaml")) (find-file (f-join pen-penel-directory "config" "efm-langserver-config.yaml")))
   ((f-exists? (f-join penconfdir "efm-langserver-config.yaml")) (find-file (f-join penconfdir "efm-langserver-config.yaml")))
   (t (error "No editable `efm-langserver-config.yaml` found."))))

(defun pen-edit-timeouts-log ()
  (interactive)
  (find-file (f-join penconfdir "timeouts.txt")))

(defun pen-read-service-key (service-name)
  (interactive (list (read-string "service: ")))
  (let* ((key-path (f-join user-home-directory ".pen" (format "%s_api_key" service-name)))
         (maybe-key (if (f-file-p key-path)
                        (chomp (str (f-read key-path))))))
    (if maybe-key
        (read-string (format "update %s key: " service-name) maybe-key)
      (read-string (format "%s key (enter to leave empty): " service-name)))))

(defun pen-add-key (service-name key)
  (interactive (let* ((service-name (read-string "service: "))
                      (key (or (ignore-errors (pen-read-service-key service-name)) "")))
                 (list service-name key)))
  (let ((key-path (f-join user-home-directory ".pen" (format "%s_api_key" service-name))))
    (f-touch key-path)
    (f-write-text key 'utf-8 key-path)))

(require 'pen-keys)

(provide 'pen-configure)
