(require 'avy)
(require 'ace-link)

(setq avy-all-windows nil)

;; For avy-goto-char-timer
(setq avy-timeout-seconds 0.2)

(defun avy-goto-char-all-windows (args)
  (interactive "P")
  (let ((avy-all-windows t))
    (call-interactively #'avy-goto-char)))

(defun avy-goto-char-enter ()
  "Go to a char with avy and then press 'Enter'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "C-m"))

(defun avy-goto-char-9 ()
  "Go to a char with avy and then press M-9"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-9"))

(defun avy-goto-link-or-button-w ()
  "Go to a char with avy and then press 'w' for copy"
  (interactive)
  (call-interactively 'ace-link-goto-link-or-button)
  (if (not (eq (key-binding "w") 'self-insert-command))
      (ekm "w")
    (message "No button/link address here to copy")))

(defun avy-goto-char-doc ()
  "Go to a char with avy and then press 'M-9'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-9"))

(defun avy-goto-char-goto-def ()
  "Go to a char with avy and then press 'M-.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-."))

(defun simulate-left-click ()
  (interactive)
  (pen-cl-sn "tmux run -b \"pen-tm mouseclick\"" :detach t))

(defun simulate-right-click ()
  (interactive)
  (pen-cl-sn "tmux run -b \"pen-tm mouseup -x -r\"" :detach t))

(defun avy-goto-char-left-click ()
  "Go to a char with avy and then left click with tmux.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (simulate-left-click))

(defun avy-goto-char-right-click ()
  "Go to a char with avy and then right click with tmux.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (simulate-right-click))

(defun avy-goto-char-c-o ()
  "Go to a char with avy and then type =C-c C-o=.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "C-c C-o"))

(defun avy-new-buffer-from-tmux-pane-capture ()
  (interactive)
  (with-current-buffer (pen-tmux-pane-capture t)
    (call-interactively 'avy-goto-char)))

(defun ace-link-goto-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (buttons-collect))
     (avy--style-fn avy-style))))

(defun ace-link-goto-widget ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-widgets-collect))
     (avy--style-fn avy-style))))

(defun ace-link-or-button-collect ()
  (-union
   (-union (-union
            (ace-link--help-collect)
            (ace-link--org-collect))
           (buttons-collect))
   (pen-widgets-collect)))

(defun ace-link-goto-link-or-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (ace-link-or-button-collect))
     (avy--style-fn avy-style))))

(defun ace-link-goto-glossary-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-glossary-buttons-collect))
     (avy--style-fn avy-style))))

(defun ace-link-click-glossary-button ()
  (interactive)
  (ignore-errors
    (avy-with ace-link-help
      (avy-process
       (mapcar #'cdr (pen-glossary-buttons-collect))
       (avy--style-fn avy-style)))
    (push-button)))

(defun ace-link-click-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (buttons-collect))
     (avy--style-fn avy-style)))
  (push-button))

(defun ace-link-click-widget ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-widgets-collect))
     (avy--style-fn avy-style)))
  (widget-button-press (point)))

(defun avy-jump-around-advice (proc &rest args)
  (lsp-ui-doc-hide)
  (let ((res (apply proc args)))
    res))
(advice-add 'avy-jump :around #'avy-jump-around-advice)

;; This fixes the glossary sometimes
(advice-add 'avy--overlay :around #'ignore-errors-around-advice)

(defun link-hint-copy-link ()
  "Copy a visible link of a supported type to the kill ring with avy.
`select-enable-clipboard' and `select-enable-primary' can be set to non-nil
values to copy the link to the clipboard and/or primary as well."
  (interactive)
  (avy-with link-hint-copy-link
    (link-hint--one :copy)))

(defun link-hint--button-at-point-p ()
  "Return the button at the point or nil."
  (let ((button (button-at (point))))
    (when button
      (cond
       ((derived-mode-p 'org-brain-visualize-mode)
        (try (org-brain-get-path-for-child-name (org-brain-entry-name (org-brain-entry-from-id (button-get button 'id))))
             (and (button-get button 'id)
                  (org-brain-get-path-for-entry (button-label button)))
             (button-label button)))
       (t
        (button-label button))))))

;; (buttons-collect)
;; (("Psalms 27:10" . 1)
;;  ("Psalms 103:13" . 87))

;; File looks like this: (i.e. 1 means the first char).
;; Psalms 27:10: When my father and my mother forsake me, then the Lord will take me up.
;; Psalms 103:13: Like as a father pitieth his children, so the Lord pitieth them that fear him.
;; psalms

(defun filter-cmd-collect (filter-cmd fp)
  (let ((winstart (window-start))
        (winend (window-end))
        (tuples (pen-eval-string (pen-sn (concat "cat " (pen-q fp) "|" filter-cmd "|" "words-to-avy-tuples " (pen-q fp))))))

    (mapcar (lambda (tp) (cons (car tp)
                               (+ 1 (cdr tp))))
            (-filter (lambda (tp) (and
                                   (>= (cdr tp) winstart)
                                   (<= (cdr tp) winend)))
                     tuples)))

  ;; (etv (pen-sn (concat (pen-q fp) "|" filter-cmd "|" "words-to-avy-tuples " (pen-q fp))))
  ;; (append (buttons-collect 'glossary-button-face)
  ;;         (buttons-collect 'glossary-candidate-button-face)
  ;;         (buttons-collect 'glossary-error-button-face))
  )

(defun ace-link-bible-ref ()
  (interactive)
  (ace-link-goto-filter-cmd-button "scrape-bible-references" 'bible-mode-lookup))

(defun ace-link-goto-filter-cmd-button (filter-script callback)
  (interactive (list (read-string "Filter script: ")))

  ;; OK, so without buttons I can go to something.
  ;; But how do I perform an action on it without without buttons?
  ;; I may need a separate function to see what ones exist at the point,
  ;; and choose an action based on that.

  ;; (filter-cmd-collect "scrape-bible-references" buffer-file-name)

  (let ((wordtuples (filter-cmd-collect filter-script buffer-file-name)))
    (avy-with ace-link-help
      (avy-process
       ;; There doesn't appear to be an easy way to get the avy string
       ;; Well, it's discarded here.
       ;; So I need to run the filter again
       (mapcar #'cdr wordtuples)
       (avy--style-fn avy-style)))

    (let ((result
           (cl-loop for tp in wordtuples
                    until (looking-at-p (car tp))
                    finally return (car tp))))
      (if (and result
               callback)
          (call-function callback result)))))

(define-key pen-map (kbd "M-j M-v") 'ace-link-bible-ref)

(provide 'pen-avy)
