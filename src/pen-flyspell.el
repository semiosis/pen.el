;; this is not currently used

(require 'flyspell)

(setq flyspell-issue-message-flag nil)

(require 'helm-flyspell)

(defun pen-flyspell-buffer ()
  (interactive)
  nil
  ;; Was the error breaking startup?
  ;; (user-error "flyspell-flycheck disabled")
  ;;;; In honesty, this may be too slow
  ;;(if (pen-rc-test "auto_flyspell_flycheck")
  ;;    (flyspell-buffer)
  ;;  ;; (user-error "flyspell-flycheck disabled")
  ;;  )
  )

;; Combine flyspell and flycheck
(defun fly-next-error ()
  (interactive)
  (let* ((pos (point))
         (fspos
          (save-excursion
            (ignore-errors
              (try
               (progn
                 (if (flyspell-overlay-here-p)
                     (setq flyspell-old-pos-error (point))
                   (setq flyspell-old-pos-error nil))
                 (call-interactively 'flyspell-goto-next-error)
                 (point))))))
         (fcpos
          (save-excursion
            (ignore-errors
              (try
               (progn
                 (call-interactively 'flycheck-next-error)
                 (point)))))))

    (if (and fspos
             (= pos fspos))
        (setq fspos nil))

    (if (and fcpos
             (= pos fcpos))
        (setq fcpos nil))

    (cond
     ((and fspos
           (or
            (not fcpos)
            (< fspos fcpos))
           (< (point) fspos))
      (progn
        ;; (message (concat "going from " (str (point)) " to " (str fspos) " oldpos: " (str flyspell-old-pos-error) " flyspell-old-pos-error: " (str flyspell-old-pos-error)))

        (goto-char fspos)

        ;; This isn't very reliable. Just go to the point
        ;; (call-interactively 'flyspell-goto-next-error)
        ;; (flyspell-goto-next-error)
        ;; (message (concat "gone from " (str (point)) " to " (str fspos) " oldpos: " (str flyspell-old-pos-error)))
        ))
     ((and fcpos
           (or
            (not fspos)
            (< fcpos fspos))
           (< (point) fcpos))
      (call-interactively 'flycheck-next-error)))))

(defun fly-prev-error ()
  (interactive)
  (let* ((pos (point))
         (fspos
          (save-excursion
            (ignore-errors
              (try
               (progn
                 (if (flyspell-overlay-here-p)
                     (setq flyspell-old-pos-error (point))
                   (setq flyspell-old-pos-error nil))
                 (call-interactively 'flyspell-goto-previous-error)
                 (point))))))
         (fcpos
          (save-excursion
            (ignore-errors
              (try
               (progn
                 (call-interactively 'flycheck-previous-error)
                 (point)))))))

    (if (and fspos
             (= pos fspos))
        (setq fspos nil))

    (if (and fcpos
             (= pos fcpos))
        (setq fcpos nil))

    (cond
     ((and fspos
           (or
            (not fcpos)
            (> fspos fcpos))
           (> (point) fspos))
      (progn
        (goto-char fspos)
        ;; (call-interactively 'flyspell-goto-previous-error)
        ))
     ((and fcpos
           (or
            (not fspos)
            (> fcpos fspos))
           (> (point) fcpos))
      (call-interactively 'flycheck-previous-error)))))

(add-hook 'org-mode-hook 'flyspell-mode)
(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

(defun flyspell-goto-next-error ()
  "Go to the next previously detected error.
In general FLYSPELL-GOTO-NEXT-ERROR must be used after
FLYSPELL-BUFFER."
  (interactive)
  (let ((pos (point))
	    (max (point-max)))
    (if (and (eq (current-buffer) flyspell-old-buffer-error)
	         (eq pos flyspell-old-pos-error))
	    (progn
	      (if (= flyspell-old-pos-error max)
	          ;; goto beginning of buffer
	          (progn
		        (message "Restarting from beginning of buffer")
		        (goto-char (point-min)))
	        (forward-word 1))
	      (setq pos (point))))
    ;; seek the next error
    (while (and (< pos max)
		        (let ((ovs (overlays-at pos))
		              (r '()))
		          (while (and (not r) (consp ovs))
		            (if (flyspell-overlay-p (car ovs))
			            (setq r t)
		              (setq ovs (cdr ovs))))
		          (not r)))
      (setq pos (1+ pos)))
    ;; save the current location for next invocation
    (setq flyspell-old-pos-error pos)
    (setq flyspell-old-buffer-error (current-buffer))
    (goto-char pos)
    (if (= pos max)
        ;; Here is the change
	    (error "No more miss-spelled word!"))))

;; move point to previous error
;; based on code by hatschipuh at
;; http://emacs.stackexchange.com/a/14912/2017
(defun flyspell-goto-previous-error (arg)
  "Go to arg previous spelling error."
  (interactive "p")
  (while (not (= 0 arg))
    (let ((pos (point))
          (min (point-min)))
      (if (and (eq (current-buffer) flyspell-old-buffer-error)
               (eq pos flyspell-old-pos-error))
          (progn
            (if (= flyspell-old-pos-error min)
                ;; goto beginning of buffer
                (progn
                  (message "Restarting from end of buffer")
                  (goto-char (point-max)))
              (backward-word 1))
            (setq pos (point))))
      ;; seek the next error
      (while (and (> pos min)
                  (let ((ovs (overlays-at pos))
                        (r '()))
                    (while (and (not r) (consp ovs))
                      (if (flyspell-overlay-p (car ovs))
                          (setq r t)
                        (setq ovs (cdr ovs))))
                    (not r)))
        (backward-word 1)
        (setq pos (point)))
      ;; save the current location for next invocation
      (setq arg (1- arg))
      (setq flyspell-old-pos-error pos)
      (setq flyspell-old-buffer-error (current-buffer))
      (goto-char pos)
      (if (= pos min)
          (progn
            (message "No more miss-spelled word!")
            (setq arg 0))
        ;; (forward-word)
        ))))

(define-key org-mode-map (kbd "C-.") #'flyspell-auto-correct-word)

(defun pen-flyspell-next ()
  (interactive)
  (flyspell-mode t)
  (pen-flyspell-buffer)
  (flyspell-goto-next-error))

(defun pen-flyspell-prev ()
  (interactive)
  (flyspell-mode t)
  (pen-flyspell-buffer)
  (call-interactively 'flyspell-goto-previous-error))

(defun pen-flyspell-correct ()
  (interactive)
  (flyspell-mode t)
  (pen-flyspell-buffer)
  (helm-flyspell-correct))

(defun flyspell-word-here ()
  (car (flyspell-get-word)))

;; $HOME/.aspell.en.pws
(defun pen-flyspell-add-word ()
  (interactive)
  (let ((current-location (point))
        (word (flyspell-get-word)))
    (when (consp word)
      (flyspell-do-correct 'save nil (car word) current-location (cadr word) (caddr word) current-location))))


;; This helps the glossary system
(define-key flyspell-mouse-map (kbd "<mouse-2>") nil)

(defun startofword-return-around-advice (proc &rest args)
  (let ((endofword (looking-at "\\b ")))
    (if endofword
        (backward-word))
    (let ((res (apply proc args)))
      res)
    (if endofword
        (forward-word))))

(advice-add 'flyspell-auto-correct-word :around #'startofword-return-around-advice)

(defvar flyspell-mouse-map
  (let ((map (make-sparse-keymap)))
    ;; (define-key map [mouse-2] 'flyspell-correct-word)
    map)
  "Keymap for Flyspell to put on erroneous words.")

(defun make-flyspell-overlay (beg end face mouse-face)
  "Allocate an overlay to highlight an incorrect word.
BEG and END specify the range in the buffer of that word.
FACE and MOUSE-FACE specify the `face' and `mouse-face' properties
for the overlay."
  (let ((overlay (make-overlay beg end nil t nil)))
    (overlay-put overlay 'face face)
    ;; (overlay-put overlay 'mouse-face mouse-face)
    (overlay-put overlay 'flyspell-overlay t)
    (overlay-put overlay 'evaporate t)
    ;; (overlay-put overlay 'help-echo
    ;;              (concat (if flyspell-use-mouse-3-for-menu
    ;;                          "mouse-3"
    ;;                        "mouse-2") ": correct word at point"))
    ;; If misspelled text has a 'keymap' property, let that remain in
    ;; effect for the bindings that flyspell-mouse-map doesn't override.
    (set-keymap-parent flyspell-mouse-map (get-char-property beg 'keymap))
    (overlay-put overlay 'keymap flyspell-mouse-map)
    (when (eq face 'flyspell-incorrect)
      (and (stringp flyspell-before-incorrect-word-string)
           (overlay-put overlay 'before-string
                        flyspell-before-incorrect-word-string))
      (and (stringp flyspell-after-incorrect-word-string)
           (overlay-put overlay 'after-string
                        flyspell-after-incorrect-word-string)))
    overlay))

(require 'flyspell)

(defun flyspell-overlay-here-p (&optional pos)
  (setq pos (or pos (point)))

  (if flyspell-persistent-highlight
      (let* ((overlay-here nil)
             (overlays (overlays-at pos)))
        (cl-loop for o in overlays do
                 (if (flyspell-overlay-p o)
                     (setq overlay-here t)))
        overlay-here)))

;; I want to add an optional replacement so I can override it with GPT-3
(defun flyspell-auto-correct-word (&optional rep)
  "Correct the current word.
This command proposes various successive corrections for the
current word.  If invoked repeatedly on the same position, it
cycles through the possible corrections of the current word.

See `flyspell-get-word' for details of how this finds the word to
spell-check."
  (interactive (list ""))
  ;; If we are not in the construct where flyspell should be active,
  ;; invoke the original binding of M-TAB, if that was recorded.
  (if (and (local-variable-p 'flyspell--prev-meta-tab-binding)
           (commandp flyspell--prev-meta-tab-binding t)
           (functionp flyspell-generic-check-word-predicate)
           (not (funcall flyspell-generic-check-word-predicate))
           (equal (where-is-internal 'flyspell-auto-correct-word nil t)
                  [?\M-\t]))
      (call-interactively flyspell--prev-meta-tab-binding)
    (let ((pos     (point))
          (old-max (point-max)))
      ;; Flush a possibly stale cache from previous invocations of
      ;; flyspell-auto-correct-word/flyspell-auto-correct-previous-word.
      (if (not (memq last-command '(flyspell-auto-correct-word
                                    flyspell-auto-correct-previous-word)))
          (setq flyspell-auto-correct-region nil))
      ;; Use the correct dictionary.
      (flyspell-accept-buffer-local-defs)
      (if (and (eq flyspell-auto-correct-pos pos)
               (consp flyspell-auto-correct-region))
          ;; We have already been using the function at the same location.
          (let* ((start (car flyspell-auto-correct-region))
                 (len   (cdr flyspell-auto-correct-region)))
            (flyspell-unhighlight-at start)
            (delete-region start (+ start len))
            (setq flyspell-auto-correct-ring (cdr flyspell-auto-correct-ring))
            (let* ((word (car flyspell-auto-correct-ring))
                   (len  (length word)))
              (rplacd flyspell-auto-correct-region len)
              (goto-char start)
              (if flyspell-abbrev-p
                  (if (flyspell-already-abbrevp (flyspell-abbrev-table)
                                                flyspell-auto-correct-word)
                      (flyspell-change-abbrev (flyspell-abbrev-table)
                                              flyspell-auto-correct-word
                                              word)
                    (flyspell-define-abbrev flyspell-auto-correct-word word)))
              (funcall flyspell-insert-function word)
              (flyspell-word)
              (flyspell-display-next-corrections flyspell-auto-correct-ring))
            (flyspell-adjust-cursor-point pos (point) old-max)
            (setq flyspell-auto-correct-pos (point)))
        ;; Fetch the word to be checked.
        (let ((word (flyspell-get-word)))
          (if (consp word)
              (let ((start (car (cdr word)))
                    (end (car (cdr (cdr word))))
                    (word (car word))
                    poss ispell-filter)
                (setq flyspell-auto-correct-word word)
                ;; Now check spelling of word..
                (ispell-send-string "%\n") ;Put in verbose mode.
                (ispell-send-string (concat "^" word "\n"))
                ;; Wait until ispell has processed word.
                (while (progn
                         (accept-process-output ispell-process)
                         (not (string= "" (car ispell-filter)))))
                ;; Remove leading empty element.
                (setq ispell-filter (cdr ispell-filter))
                ;; Ispell process should return something after word is sent.
                ;; Tag word as valid (i.e., skip) otherwise.
                (or ispell-filter
                    (setq ispell-filter '(*)))
                (if (consp ispell-filter)
                    (setq poss (ispell-parse-output (car ispell-filter))))
                (cond
                 ((or (eq poss t) (stringp poss))
                  ;; Don't correct word.
                  t)
                 ((null poss)
                  ;; Ispell error.
                  (error "Ispell: error in Ispell process"))
                 (t
                  ;; The word is incorrect, we have to propose a replacement.
                  (let ((replacements
                         (or (if (sor rep)
                                 (list rep))
                             (flyspell-sort (car (cdr (cdr poss)))
                                            word))))
                    (setq flyspell-auto-correct-region nil)
                    (if (consp replacements)
                        (progn
                          (let ((replace (car replacements)))
                            (let ((new-word replace))
                              (if (not (equal new-word (car poss)))
                                  (progn
                                    ;; then save the current replacements
                                    (setq flyspell-auto-correct-region
                                          (cons start (length new-word)))
                                    (let ((l replacements))
                                      (while (consp (cdr l))
                                        (setq l (cdr l)))
                                      (rplacd l (cons (car poss) replacements)))
                                    (setq flyspell-auto-correct-ring
                                          replacements)
                                    (flyspell-unhighlight-at start)
                                    (delete-region start end)
                                    (funcall flyspell-insert-function new-word)
                                    (if flyspell-abbrev-p
                                        (if (flyspell-already-abbrevp
                                             (flyspell-abbrev-table) word)
                                            (flyspell-change-abbrev
                                             (flyspell-abbrev-table)
                                             word
                                             new-word)
                                          (flyspell-define-abbrev word
                                                                  new-word)))
                                    (flyspell-word)
                                    (flyspell-display-next-corrections
                                     (cons new-word flyspell-auto-correct-ring))
                                    (flyspell-adjust-cursor-point pos
                                                                  (point)
                                                                  old-max))))))))))
                (setq flyspell-auto-correct-pos (point))
                (ispell-pdict-save t))))))))

(provide 'pen-flyspell)
