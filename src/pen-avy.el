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

;; cat $HOME/.emacs.d/host/pen.el/src/pen-avy.el | scrape-bible-references | parallel --pipe -L 10 -N1 words-to-avy-tuples -nbe $HOME/.emacs.d/host/pen.el/src/pen-avy.el | v
;; cat $HOME/.emacs.d/host/pen.el/src/pen-avy.el | scrape-bible-references | parallel --group --pipe -l 10 --halt never -j 1 -N1 words-to-avy-tuples -nbe $HOME/.emacs.d/host/pen.el/src/pen-avy.el | uniqnosort

;; j:filter-cmd-buttonize-2-tuples
(defset filter-cmd-2-tuples
  ;; They have to be different

  ;; I number them to differentiate them
  (let ((tps '(("scrape-bible-references" bible-mode-lookup)
               ("scrape-bible-references" "sps ebible")
               ("scrape \"[^\\\"<>]+\" | xurls | uniqnosort" "tm-nohup chrome"))))
    (cl-loop for index from 0
             for e in tps
             collect (cons (concat (car e) " # " (str index)) (cdr e)))))

;; | =M-j M-v= | =ace-link-bible-ref= | =pen-map=
(defun ace-link-bible-ref ()
  (interactive)
  (ace-link-goto-filter-cmd-button "scrape-bible-references" 'bible-mode-lookup)
  ;; (ace-link-goto-filter-cmd-button "scrape-bible-references" "sps ebible")
  )

(defun ace-link-filter-cmd ()
  (interactive)
  (let ((scraper
         (s-replace-regexp
          " #.*" ""
          (fz filter-cmd-2-tuples nil nil "filter-cmd: ")))
        (tup (cadr pen-ivy-result-tuple)))
    (ace-link-goto-filter-cmd-button scraper tup)))

(define-key pen-map (kbd "H-l") 'ace-link-filter-cmd)

;; TODO Make a binding for this
(defun ace-link-filter-ref ()
  (interactive)

  ;; I should also have actions associated with each filter

  ;; (ace-link-goto-filter-cmd-button (select-filter) 'bible-mode-lookup)
  (ace-link-goto-filter-cmd-button (select-filter) nil))


;; TODO Make it only use the visible window contents instead of (buffer-string)
;; Use (window-start) to get the starting byte.
;; It's already not using buffer-file-name, so it should be easy
(defun filter-cmd-collect (filter-cmd &optional fp-or-buf)
  (let* ((tempf
          (cond
           ((not fp-or-buf)
            (with-current-buffer
                (current-buffer)
              (pen-tf "avy-bible" (window-string))))
           ((bufferp fp-or-buf)
            (with-current-buffer
                fp-or-buf
              (pen-tf "avy-bible" (window-string))))
           ((and
             (stringp fp-or-buf)
             (f-file-p fp-or-buf))
            (pen-tf "avy-bible" (e/cat fp-or-buf)))
           ((f-file-p buffer-file-name)
            (pen-tf "avy-bible" (e/cat buffer-file-name)))))
         (winstart (window-start))
         (winend (window-end))

         (input (cond
                 ((and
                   (stringp tempf)
                   (f-file-p tempf))
                  (e/cat tempf))
                 (t
                  (buffer-string))))

         ;; Because this always needs a file, I should just simplify all this by creating a temp file
         (tuples (pen-eval-string
                  (concat
                   "'("
                   (pen-sn (concat filter-cmd "| pen-sort line-length-desc |" "serialsplit -l 10 words-to-avy-tuples -nbe " (pen-q tempf) " | uniqnosort")
                           input
                           nil)
                   ")"))))

    ;; Only delete it if it is a temp file
    (if (and (stringp tempf)
             (f-file-p tempf))
        (f-delete tempf))

    (-filter (λ (tp) (and
                           (>= (cdr tp) winstart)
                           (<= (cdr tp) winend)))
             (mapcar (λ (tp)
                       (cons (car tp)
                             (- (byte-to-position
                                 (+ (position-bytes winstart)
                                    (+ 1 (cdr tp))))
                                1)))
                     tuples)))

  ;; (etv (pen-sn (concat (pen-q fp-or-buf) "|" filter-cmd "|" "words-to-avy-tuples " (pen-q fp-or-buf))))
  ;; (append (buttons-collect 'glossary-button-face)
  ;;         (buttons-collect 'glossary-candidate-button-face)
  ;;         (buttons-collect 'glossary-error-button-face))
  )

(defun ace-link-goto-filter-cmd-button (filter-script callback)
  (interactive (list (read-string "Filter script: ")))

  ;; OK, so without buttons I can go to something.
  ;; But how do I perform an action on it without without buttons?
  ;; I may need a separate function to see what ones exist at the point,
  ;; and choose an action based on that.

  ;; (filter-cmd-collect "scrape-bible-references" buffer-file-name)

  (let ((wordtuples
         ;; filter-cmd-collect handles nil buffer path
         (filter-cmd-collect
          filter-script

          ;; This could be nil, ie. for *scratch*
          ;; In-fact, it should always be nil, because I want to only use the visible contents of the buffer.
          ;; buffer-file-name

          nil)))
      (avy-with ace-link-help
      (let ((avy-action
             (eval
              `(λ (pt)
                 (avy-action-goto pt)
                 (let ((result
                        (cl-loop for tp in ',wordtuples
                                 until (looking-at-p (pen-unregexify (car tp)))
                                 finally return (car tp))))
                   (let ((cb ',callback))
                     (if (and result
                              cb)
                         (if (stringp cb)
                             (pen-snc (concat cb " " (pen-q result)))
                           (call-function cb result)))))))))
        (avy-process
         ;; There doesn't appear to be an easy way to get the avy string
         ;; Well, it's discarded here.
         ;; So I need to run the filter again
         (mapcar #'cdr wordtuples)
         (avy--style-fn avy-style))))))

(define-key pen-map (kbd "M-j M-v") 'ace-link-bible-ref)

(provide 'pen-avy)
