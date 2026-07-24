(require 'artist)

;; There is a bug where if I start drawing a line, but only use one click,
;; then press any keyboard key, there is an error.
;; (advice-add 'artist-set-arrow-points-for-poly :around #'ignore-errors-around-advice)
;; (advice-remove 'artist-set-arrow-points-for-poly #'ignore-errors-around-advice)

(advice-add 'artist-mouse-draw-poly :around #'ignore-errors-around-advice)
;; (advice-remove 'artist-mouse-draw-poly #'ignore-errors-around-advice)

;; (advice-add 'artist-down-mouse-1 :around #'ignore-errors-around-advice)
;; (advice-remove 'artist-down-mouse-1 #'ignore-errors-around-advice)

;; I also needed to silence this function so lots of data wouldn't
;; appear in the minibuffer after artist-mouse-draw-poly causes an error.
(advice-add 'artist-down-mouse-1 :around #'shut-up-around-advice)

(setq artist-figlet-list-fonts-command
      '"for dir in `figlet -I2`; do cd $dir; ls *.[tf]lf; done")

(defun artist-figlet-get-font-list ()
  "Read fonts in with the shell command.
Returns a list of strings."
  (let* ((cmd-interpreter "/bin/sh")
	     (ls-cmd          artist-figlet-list-fonts-command)
	     (result          (artist-system cmd-interpreter ls-cmd nil))
	     (exit-code       (elt result 0))
	     (stdout          (elt result 1))
	     (stderr          (elt result 2)))
    (if (not (= exit-code 0))
	    (error "Failed to read available fonts: %s (%d)" stderr exit-code))
    (str2lines (e/chomp stdout))))

(provide 'pen-artist)
