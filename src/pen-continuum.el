;; A list of strings, each a snapshot of the terminal
(defset pen-terminal-states '())

;; It's possible that I need a language model which is trained on editing text at scale.
;; It may need to be trained on watching people program, or over git history rather than to mimic coherence in final source code.
;; But that will definitely happen.
;; I could possibly find a prompt closer to this effect by using git markup.

;; Usage:
;; Run the `continuum-push` command a couple of times before running the prompt

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

;;; Continuum Game of Life

(defvar continuum-life-ready t)
(defset continuum-life-stop nil)

(defun continuum-life-start ()
  (interactive)

  (defset continuum-life-stop nil)
  (call-interactively 'continuum-life-update))

(defun continuum-life-update (buf)
  (interactive (list (current-buffer)))
  (setq buf (or buf (current-buffer)))
  (with-current-buffer buf
    (let ((bs (buffer-string)))
      (async-pf "pf-evaluate-entire-terminal-to-get-a-new-terminal/1"
                (eval
                 `(lambda (result)
                    (with-current-buffer ,buf
                      (if (and (string-equal (buffer-string) ,bs)
                               (not (string-equal (buffer-string) result))
                               (not (pen-selected)))
                          (save-excursion-reliably
                           (save-excursion-and-region-reliably
                            (pen-replace-region result)))))
                    (if (not continuum-life-stop)
                        (continuum-life-update ,buf))))
                bs))))

(defun continuum-life-stop ()
  (interactive)
  (setq continuum-life-stop t))

(defun continuum-life-demo ()
  (interactive)

  (let ((cb (nbfs
             ":top
i = i + 1
show i
=> 3
i = i mod 5
show i
=> 3
Correct!
loop from top with i == 3")))
    (if (yn "Start Life?")
        (progn (switch-to-buffer cb)
               (continuum-life-start)))))

(provide 'pen-continuum)
