;; A list of strings, each a snapshot of the terminal
(defset pen-terminal-states '())

;; It's possible that I need a language model which runs in reverse somehow, or is trained on editing text at scale.
;; It may need to be trained on watching people program rather than source code.
;; But that will definitely happen.

;; Run the command a couple of times before running the prompt

(defun continuum-add-state (state)
  (interactive (list (buffer-string-visible)))
  (setq pen-terminal-states(cons state pen-terminal-states)))

(defun continuum-get-older ()
  (let ((r (reverse pen-terminal-states)))
    (if (> (length pen-terminal-states) 1)
        (second r))))

(defun continuum-get-old ()
  (let ((r (reverse pen-terminal-states)))
    (if (> (length pen-terminal-states) 1)
        (first r))))

(defun continuum-get-current ()
  (buffer-string-visible))

;; These saves should happen automatically on a timer?
;; Or after a certain number of key presses
(defun continuum-push ()
  (interactive)
  (setq pen-terminal-states (cons (continuum-get-current) pen-terminal-states)))

(defun continuum (older-state old-state)
  (interactive (list (continuum-get-older) (continuum-get-old)))

  (pf-guess-your-terminal-s-future/3
   (continuum-get-older)
   (continuum-get-old)
   (continuum-get-current)))

(provide 'pen-continuum)