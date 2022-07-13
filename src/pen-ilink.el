;; Imaginary org-link

;; What is its purpose?

;; - If the link type doesn't exist, then add it
;; - If there is no handler for the link type then ask to create an imaginary function for it
;;   - Use an ifunc instead of prompting directly

;; org-add-link-type

;; As the fallback, instead of searching and org file, it should
;; create a new handler.

(defun org-link-open-around-advice (proc link &optional arg)
  (let* ((type (org-element-property :type link))
         (path (org-element-property :path link))
         (query (cut path :d ":" :f 2))
         (fun (org-link-get-parameter type :follow)))

    (if (equal type "fuzzy")
        (progn
          (setq type (cut path :d ":" :f 1))
          (setq path (org-element-property :path link))
          (setq query (cut path :d ":" :f 2))
          (setq fun (org-link-get-parameter type :follow))))

    (if (and
         (not fun)
         (yn "Add imaginary handler?"))
        (progn
          ;; (tv (org-add-link-type type (eval `(idefun ,(str2sym (concat (slugify type) "-link-hander")) path))))
          (tv `(idefun ,(str2sym (concat (slugify type) "-link-hander")) ,query))
          ;; (defun follow-yt-link (cmd)
          ;;   "Run pen-sps `CMD'."
          ;;   (pen-nw (concat "yt-search " cmd " | pen-xa o")))
          )))

  (let ((res (apply proc link arg)))
    res))
(advice-add 'org-link-open :around #'org-link-open-around-advice)
(advice-remove 'org-link-open #'org-link-open-around-advice)

(defun org-link-open (link &optional arg)
  "Open a link object LINK.

ARG is an optional prefix argument.  Some link types may handle
it.  For example, it determines what application to run when
opening a \"file\" link.

Functions responsible for opening the link are either hard-coded
for internal and \"file\" links, or stored as a parameter in
`org-link-parameters', which see."
  (let ((type (org-element-property :type link))
        (path (org-element-property :path link)))
    (pcase type
      ;; Opening a "file" link requires special treatment since we
      ;; first need to integrate search option, if any.
      ("file"
       (let* ((option (org-element-property :search-option link))
              (path (if option (concat path "::" option) path)))
         (org-link-open-as-file path
                                (pcase (org-element-property :application link)
                                  ((guard arg) arg)
                                  ("emacs" 'emacs)
                                  ("sys" 'system)))))
      ;; Internal links.
      ((or "coderef" "custom-id" "fuzzy" "radio")
       (unless (run-hook-with-args-until-success 'org-open-link-functions path)
         (if (not arg) (org-mark-ring-push)
           (switch-to-buffer-other-window (org-link--buffer-for-internals)))
         (let ((destination
                (org-with-wide-buffer
                 (if (equal type "radio")
                     (org-link--search-radio-target path)
                   (org-link-search
                    (pcase type
                      ("custom-id" (concat "#" path))
                      ("coderef" (format "(%s)" path))
                      (_ path))
                    ;; Prevent fuzzy links from matching themselves.
                    (and (equal type "fuzzy")
                         (+ 2 (org-element-property :begin link)))))
                 (point))))
           (unless (and (<= (point-min) destination)
                        (>= (point-max) destination))
             (widen))
           (goto-char destination))))
      (_
       ;; Look for a dedicated "follow" function in custom links.
       (let ((f (org-link-get-parameter type :follow)))
         (when (functionp f)
           ;; Function defined in `:follow' parameter may use a single
           ;; argument, as it was mandatory before Org 9.4.  This is
           ;; deprecated, but support it for now.
           (condition-case nil
               (funcall (org-link-get-parameter type :follow) path arg)
             (wrong-number-of-arguments
              (funcall (org-link-get-parameter type :follow) path)))))))))

(provide 'pen-ilink)