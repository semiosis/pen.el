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
        (fmt

         ebdb-full-formatter
         ;; (ebdb-formatter-prefix)
         ))
    (ebdb style regexp fmt)))

;; j:ebdb-display-all-records

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

(define-key ebdb-mode-map (kbd "w f") nil)
(define-key ebdb-mode-map (kbd "w m") nil)
(define-key ebdb-mode-map (kbd "w r") nil)
(define-key ebdb-mode-map (kbd "w") nil)

(define-key ebdb-mode-map (kbd "w") 'get-path)

(define-key ebdb-mode-map (kbd "M-W f") 'ebdb-copy-fields-as-kill)
(define-key ebdb-mode-map (kbd "M-W m") 'ebdb-copy-mail-as-kill)
(define-key ebdb-mode-map (kbd "M-W r") 'ebdb-copy-records-as-kill)

(defun pen-ebdb-return-fields-for-get-path (records field &optional num)
  "For RECORDS copy values of FIELD at point to kill ring.
If FIELD is an address or phone with a label, copy only field values
with the same label.  With numeric prefix NUM, if the value of FIELD
is a list, copy only the NUMth list element."
  (interactive
   (list (ebdb-do-records t) (ebdb-current-field)
         (and current-prefix-arg
              (prefix-numeric-value current-prefix-arg))))
  (unless field (error "Not a field"))
  (let ((field-class (eieio-object-class field))
        val-list fields)
    ;; Store the first field string, then pop the record list.  If
    ;; there's only one record, this keeps things simpler.
    (push (ebdb-string field) val-list)
    (setq records (cdr (ebdb-record-list records)))
    (dolist (record records)
      (setq fields
            (seq-filter
             (lambda (f)
               (same-class-p f field-class))
             (mapcar #'cdr (ebdb-record-current-fields (car record)))))
      (when (object-of-class-p field 'ebdb-field-labeled)
        (setq fields
              (seq-filter
               (lambda (f)
                 (string= (ebdb-field-label f)
                          (ebdb-field-label field)))
               fields)))
      (when (and num (> 1 (length fields)))
        (setq fields (list (nth num fields))))
      (dolist (f fields)
        (push (ebdb-string f) val-list)))
    (let ((str (ebdb-concat 'record (nreverse val-list))))
      str)))

(defun ebdb-get-path-org-link ()
  (interactive)
  (format "[[ebdb:%s]]" (call-interactively 'pen-ebdb-return-fields-for-get-path)))

(defun ebdb-copy-fields-as-kill-org-link ()
  (interactive)
  (shut-up-c (call-interactively 'ebdb-copy-fields-as-kill))
  (xc (format "[[ebdb:%s]]" (car kill-ring))))

;; This combined with shackle, seems to do the trick
(defun ebdb-pop-up-window (buf &optional select pop)
  (display-buffer buf))

(comment
 (defun ebdb-pop-up-window (buf &optional select pop)
   "Display *EBDB* buffer BUF by popping up a new window.
If SELECT is non-nil, select the new window after creation.

POP is a list of (window split direction), where \"window\" is
the window to be split, \"split\" says to split it by how much,
and \"direction\" is one of the symbols left, right, above or
below.

Any of the three elements can be nil.  If \"window\" is nil, use
the current window.  If \"direction\" is nil, split either below
or right, depending on which dimension is longest.  If \"split\"
is nil, split 0.5.

If the whole POP argument is nil, re-use the current window.

If the option `ebdb-join-atomic-windows' is non-nil, a popped-up
buffer window will become part of whichever atomic window it was
popped up from."
   (let* ((buf (get-buffer buf))
          (split-window (car-safe pop))
          (buffer-window (get-buffer-window buf t))
          direction size)
     ;; It's already visible, re-use it and we're done.
     (unless buffer-window
       (setq direction (or (nth 2 pop)
                           (if (> (window-total-width split-window)
                                  (window-total-height split-window))
                               'right
                             'below))
             size (cond ((null pop)
                         nil)
                        ((integerp (cadr pop))
                         (cadr pop))
                        ((or (floatp (cadr pop)) (floatp ebdb-default-window-size))
                         (let ((flt (or (cadr pop) ebdb-default-window-size)))
                           (round (* (if (memq direction '(left right))
                                         (window-total-width split-window)
                                       (window-total-height split-window))
                                     (- 1 flt)))))
                        ((integerp ebdb-default-window-size)
                         ebdb-default-window-size)))
       (if (not (or split-window size))
           ;; Not splitting, but buffer isn't visible, just take up
           ;; the whole window.
           (progn
             (pop-to-buffer-same-window buf)
             (setq buffer-window (get-buffer-window buf t)))
         ;; Otherwise split.
         (setq
          buffer-window
          ;; If the window we're splitting is an atomic window,
          ;; maybe make our buffer part of the atom.
          (if (and ebdb-join-atomic-windows
                   (window-atom-root split-window))
              (display-buffer-in-atom-window
               buf `((window . ,split-window)
                     (side . ,direction)
                     ,(if (eq direction 'below)
                          `(window-height . ,size)
                        `(window-width . ,size))))
            (split-window
             split-window size direction))))
       (set-window-buffer buffer-window buf)
       (display-buffer-record-window 'window buffer-window buf)
       (set-window-prev-buffers buffer-window nil))
     (when select
       (select-window buffer-window)))))


(defun ebdb-around-advice (proc style regexp &optional fmt)
  (interactive (list (ebdb-search-style)
                     (ebdb-search-read 'all)
                     (ebdb-formatter-prefix)))
  (setq fmt (or fmt
                ebdb-full-formatter))
  (let ((res (apply proc (list style regexp fmt))))
    res))
(advice-add 'ebdb :around #'ebdb-around-advice)
;; (advice-remove 'ebdb #'ebdb-around-advice)

(provide 'pen-addressbook)
