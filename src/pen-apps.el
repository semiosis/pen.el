;; These must come after the above block because the prefix is not yet defined
(require 'helm-sys)

(defun e/broot ()
  (interactive)
  (term-sps (concat (pen-cmd "cd" default-directory) "; br")))

(defun gambit ()
  (interactive)
  (term-sps (concat (pen-cmd "cd" default-directory) "; gambit")))

(defun slides (&optional path)
  (interactive)
  (let ((bpath (get-path nil t)))
    (cond
     (path
      (term-sps (cmd "slides" path)))
     ((string-match "\\.md$" bpath)
      (term-sps (cmd "slides" bpath)))
     (t
      (term-sps "slides")))))

(defun noted ()
  (interactive)
  (term-sps (concat (pen-cmd "cd" default-directory) "; noted")))

(defun broot ()
  (interactive)
  (pen-sps "br" nil nil default-directory))

(defun open-colors ()
  (interactive)
  (pen-sps "open-colors" nil nil default-directory)
  ;; (pen-use-vterm
  ;;  (pen-term "open-colors" nil nil default-directory))
  )

;; I guess if I need to quickly create tab-indented lists, hmm is the tool
(defun hmm ()
  (interactive)
  ;; Sadly, doesn't work well with eterm

  ;; hmm is certainly not perfect
  ;; - C-l while editing creates newlines in the node
  
  ;; tmux works best
  (pen-nw "hmm" nil nil default-directory)

  ;; vterm works ok
  ;; But I have not yet sorted all key bindings
  ;; Currently not working:
  ;; - arrow keys
  ;; - C-h
  ;; - Delete
  ;; - C-l messes up the screen
  ;; (pen-use-vterm
  ;;  (pen-term "h-m-m" nil nil default-directory))
  )


(provide 'pen-apps)
