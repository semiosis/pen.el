(require 'mm-decode)
(require 'mailcap)

;; j:mm-display-part

;; [[ev:mailcap--computed-mime-data]]

;; j:mailcap-mime-info

(defun mailcap-mime-info-around-advice (proc string &optional request no-decode)
  (if request
      (let ((res (apply proc (list string request no-decode))))
        res)
    (cond
     ((string-equal "application/pdf" string)
      ;; "zathura %s"
      ;; "pl %s | store-file-by-hash | xa unbuffer sps o"
      "unbuffer sps o %s")
     (t (let ((res (apply proc (list string request no-decode))))
          res)))))
(advice-add 'mailcap-mime-info :around #'mailcap-mime-info-around-advice)
;; (advice-remove 'mailcap-mime-info #'mailcap-mime-info-around-advice)

;; (load-library "mm-decode")
;; Modify this so that the temporary directory name is idempotent.
;; j:mm-display-external

;; j:mm-mailcap-command

;; Move the file to an idempotent directory based on its hash
(defun mm-mailcap-command-around-advice (proc method file type-list)
  (let* ((o_fp file)
         (fn (f-basename file))
         (fp_sha (snc (cmd "sha" "-f" o_fp)))
         (store_dir (f-join (umn "$PEN/file-store-by-hash") fp_sha))
         (ret (mkdir-p store_dir))
         (n_fp (f-join store_dir fn)))

    (if (not (f-exists-p n_fp))
        (f-copy o_fp n_fp))

    (setq file n_fp)

    (let ((res (apply proc (list method file type-list))))
      file
      res)))
(advice-add 'mm-mailcap-command :around #'mm-mailcap-command-around-advice)
;; (advice-remove 'mm-mailcap-command #'mm-mailcap-command-around-advice)

(provide 'pen-mm-decode)
