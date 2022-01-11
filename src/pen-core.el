;; These are helper functions
;; examplary.el uses them.

;; So might org-brain

(defun pen-preceding-text (&optional max-chars)
  (setq max-chars (or max-chars 1000))
  (let* ((text (str (buffer-substring (point) (max 1 (- (point) max-chars))))))
    (if (major-mode-p 'term-mode)
        (setq text (s-preserve-trailing-whitespace (pen-sn "clean-term-capture -rmtm" text) text)))
    text))

(defun pen-preceding-sentences (&optional text n exclude-current)
  (interactive)

  (setq n (or n 1))
  (setq text (or text (pen-preceding-text)))

  (chomp
   (with-temp-buffer
     (insert text)
     (goto-char (point-max))

     (save-excursion
       (if exclude-current
           (progn
             (backward-sentence)
             (setq n (1- n))))

       (let ((end (point))
             (start))

         (cl-loop for i in (number-sequence 0 n) do
               (backward-sentence))
         (setq start (point))

         (str (buffer-substring start end)))))))

(defun pen-beginning-of-line-point ()
  (save-excursion
    (beginning-of-line)
    (point)))

(defun pen-preceding-text-line ()
  ;; (cond
  ;;  (derived-mode-p 'term-mode))
  (str (buffer-substring (point) (max 1 (pen-beginning-of-line-point)))))

(defun get-point-start-of-nth-previous-line (n)
  (save-excursion
    (eval `(macroexpand (ntimes ,n (ignore-errors (previous-line)))))
    (beginning-of-line)
    (point)))

(defun get-point-start-of-nth-next-line (n)
  (save-excursion
    (eval `(macroexpand (ntimes ,n (ignore-errors (next-line)))))
    (beginning-of-line)
    (point)))

(defun pen-surrounding-text (&optional window-line-size select)
  (if (not window-line-size)
      (setq window-line-size 20))
  (let* ((window-line-radius (/ (+ 1 window-line-size) 2))
         (start (get-point-start-of-nth-previous-line window-line-radius))
         (end (get-point-start-of-nth-next-line (+ 1 window-line-radius))))
    (if select
        (progn
          (set-mark start)
          (goto-char end)
          (activate-mark)))
    (str (buffer-substring
          start
          end))))

(defun pen-surrounding-proceeding-text (&optional preceding-lines proceeding-lines select)
  (if (not preceding-lines)
      (setq preceding-lines 3))
  (if (not proceeding-lines)
      (setq proceeding-lines 10))
  (let* ((start (get-point-start-of-nth-previous-line preceding-lines))
         (end (get-point-start-of-nth-next-line (+ 1 proceeding-lines))))
    (if select
        (progn
          (set-mark start)
          (goto-char end)
          (activate-mark)))
    (str (buffer-substring
          start
          end))))

(defun pen-proceeding-text (&optional proceeding-lines select)
  (if (not proceeding-lines)
      (setq proceeding-lines 10))
  (let* ((start (point))
         (end (get-point-start-of-nth-next-line (+ 1 proceeding-lines))))
    (if select
        (progn
          (set-mark start)
          (goto-char end)
          (activate-mark)))
    (str (buffer-substring
          start
          end))))

(defun pen-words (&optional n input)
  (setq n (or n 5))
  (s-join " " (-take n (s-split-words input))))

;; Great for NLP tasks such as keyword extraction
(defun pen-selection-or-surrounding-context (&optional window-line-size)
  (let ((context
         (if (pen-selected-p)
             (pen-selected-text)
           (pen-surrounding-context window-line-size))))
    ;; Correcting the spelling and grammer helps massively
    ;; But it's slow
    (pen-snc "sed -z -e 's/\\s\\+/ /g' -e 's/^\\s*//' -e 's/\\s*$//'"
             (pen-snc "pen-c context-chars" context))
    ;; (car
    ;;  (pf-correct-english-spelling-and-grammar/1
    ;;   (pen-snc "sed -z 's/\\s\\+/ /g'" (pen-snc "pen-c context-chars" context))
    ;;   :no-select-result t))
    ))

(defun pen-surrounding-context (&optional window-line-size)
  (pen-snc "sed -z 's/\\s\\+/ /g'" (pen-surrounding-text window-line-size)))

(defun pen-thing-at-point (&optional only-if-selected)
  (interactive)

  (if (and only-if-selected
           (not mark-active))
      nil
    (if (or mark-active
            iedit-mode)
        (pen-selected-text)
      (str
       (or (thing-at-point 'symbol)
           (thing-at-point 'sexp)
           (let ((s (str (thing-at-point 'char))))
             (if (string-equal s "\n")
                 ""
               s))
           "")))))

(defun pen-thing-at-point-ask (&optional prompt prefer-not-to-ask)
  "thing at point or ask"
  (interactive)
  ;; If selected, definitely use
  ;; If not selected, verify
  (let ((sel (pen-selection))
        (thing (sor (pen-thing-at-point))))
    (cond
     (sel sel)
     ((not sel)
      (read-string-hist
       (concat
        (or (sor prompt "pen-thing-at-point-ask")
            "")
        ": ")
       thing))
     ((and prefer-not-to-ask
           thing) thing)
     (t (read-string-hist
         (concat
          (or (sor prompt "pen-thing-at-point-ask")
              "")
          ": ")
         thing)))))

(defun pen-choose (options prompt)
  (interactive)
  (if (not prompt)
      (setq prompt "pen-choose: "))

  (let ((fnn (pen-var-value-maybe 'func-name)))
    (if (sor fnn)
        (setq prompt (concat fnn " ~ " prompt))))

  (if (pen-var-value-maybe 'pen-single-generation-b)
      (car options)
    (fz
     options
     nil
     nil
     prompt
     nil nil nil nil t)))

(defun pen-detect-language-ask (&optional prompt world)
  (interactive)
  (if (not prompt)
      (setq prompt "Pen detected language"))
  (pen-choose
   (if pen-cost-efficient
       (if (sor (s-chompall (buffer-string)))
           (pen-detect-language t nil world)
         (pen-detect-language nil nil world))
     (pen-detect-language-lm))
   "pen-detect-language-ask: "))

(defun pen-detect-language-lm (&optional world)
  (interactive)
  (let ((langs
         (-uniq-u
          (append
           ;; TODO Make it so I can feed values into prompt functions
           ;; So, for example, I can use them inside the prompt fuzzy-finder
           (let ((context (sor
                           (pen-selected-text t)
                           (pen-preceding-text))))
             (if context
                 (pf-get-language/1
                  context
                  :no-select-result t)))
           ;; inexpensive
           (list (pen-detect-language t nil world)
                 (pen-detect-language t t world))))))
    langs))

(defun pen-detect-language-lm-ask (&optional prompt world)
  (interactive)
  (pen-choose  (pen-detect-language-lm world) prompt))

(provide 'pen-core)