(require 'addressbook-bookmark)

(add-to-list 'load-path "/root/repos/ebdb")

(require 'ebdb)
(require 'ebdb-com)
(require 'ebdb-complete)
(require 'ebdb-counsel)
(require 'ebdb-format)
;; (require 'ebdb-gnus)
(require 'ebdb-html)

;; Internationalization - I found it a bit buggy
(comment
 (require 'ebdb-i18n)
 (require 'ebdb-i18n-basic)
 (require 'ebdb-i18n-test))

(require 'ebdb-ispell)
(require 'ebdb-latex)
(require 'ebdb-message)
;; (require 'ebdb-mhe)
(require 'ebdb-migrate)
;; (require 'ebdb-mu4e)
(require 'ebdb-mua)
(require 'ebdb-notmuch)
(require 'ebdb-org)
(require 'ebdb-pgp)
(require 'ebdb-rmail)
(require 'ebdb-snarf)
(require 'ebdb-test)
(require 'ebdb-vcard)
(require 'ebdb-vm)
(require 'ebdb-wl)
;; (require 'helm-ebdb)

;; ebdb-i18n-countries

;; [[info:(ebdb) Top]]

(add-to-list 'load-path "/root/repos/company-ebdb")
(require 'company-ebdb)

;; mx:ebdb-open

;; [[cg:ebdb]]
;; cg:ebdb

;; [[ev:ebdb-sources]]
;; ev:ebdb-sources

(setq ebdb-sources '"/root/.pen/ebdb")

(defun disable-read-only ()
  ;; (sleep 1)
  ;; (switch-to-buffer "*EBDB*")
  ;; (setq buffer-read-only nil)
  (redraw-frame))

(defun refresh-frame ()
  (interactive)

  (pen-sn (concat "sleep 1 && " (cmd "tm" "nw" "-d" "-fargs" "pen-emacsclient" "-a" "" "-t" "-s" (daemonp) "-e" "(delete-frame)"))))

;; nadvice - proc is the original function, passed in. do not modify
(defun ebdb-open-around-advice (proc &rest args)
  (if (buffer-exists "*EBDB*")
      (switch-to-buffer "*EBDB*")
    (let ((res (apply proc args)))
      ;; (refresh-frame)
      ;; (ebdb-toggle-all-records-format)
      ;; (ebdb-toggle-all-records-format)      
      res)))
(advice-add 'ebdb-open :around #'ebdb-open-around-advice)
;; (advice-remove 'ebdb-open #'ebdb-open-around-advice)

(add-hook 'ebdb-display-hook 'disable-read-only)

(comment (setq ebdb-sources '("/root/.pen/ebdb"
                              "/root/.pen/ebdb2")))

(defun pen-ebdb-search (&optional regexp)
  (interactive (list (ebdb-search-read 'all)))
  (if (not regexp)
      (setq regexp (ebdb-search-read 'all)))

  (let ((style (ebdb-search-style))
        (fmt (ebdb-formatter-prefix)))
    (ebdb style regexp fmt)))

;; j:ebdb-display-all-records

;; nadvice - proc is the original function, passed in. do not modify
(defun ebdb-display-all-records-around-advice (proc &optional fmt)
  (interactive)
  (setq fmt (or fmt
                ebdb-full-formatter))
  (let ((res (apply proc (list fmt))))
    res))
(advice-add 'ebdb-display-all-records :around #'ebdb-display-all-records-around-advice)
;; (advice-remove 'ebdb-display-all-records #'ebdb-display-all-records-around-advice)

;; These must be added to a hook as the map doesn't until ebdb is run
;; ;; These bindings act more like org-mode
(defun ebdb-set-bindings ()
  (define-key ebdb-mode-map (kbd "<backtab>") 'ebdb-toggle-all-records-format)
  (define-key ebdb-mode-map (kbd "TAB") 'ebdb-toggle-records-format)
  (define-key ebdb-mode-map (kbd "n") 'ebdb-next-field)
  (define-key ebdb-mode-map (kbd "p") 'ebdb-prev-field))

(add-hook 'ebdb-display-hook 'ebdb-set-bindings)

(defun pen-ebdb-mouse-click (event)
  (interactive (list
                (get-pos-for-x-popup-menu)))

  (ebdb-mouse-menu event))

(provide 'pen-addressbook)
