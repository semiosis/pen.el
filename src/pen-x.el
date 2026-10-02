(require 'pen-utils)

;; 
;; (defvar '())

;; This is for my automation stuff
;; It's not just =x= (my expect script generator). It's xdotool as well
;; This is for macros

;; See
;; $EMACSD/config/pen-git.el

(defun x/git-add-all-below ()
  "Show git commit in tmux."
  (interactive)
  ;; Create a new tmux split and use 'x'
  ;; cd "$(vc get-top-level)" && pwd
  ;; git add -A .
  ;; (tm-sph (concat "pen-git-show-commit " sha1) "-nopakf -noerror")
  ;; (tm-sph "pwd | less" "-nopakf -noerror")
  (tm-sph "xs g A" "-nopakf -noerror"))

(defun x/git-amend-all-below ()
  "Show git amend in tmux."
  (interactive)
  (tm-sph "xs g -zsh-amend" "-nopakf -noerror"))

(defun x/eack-thing ()
  "xs eack"
  (interactive)
  (tm-sph (concat "xs eack " (pen-q (pen-thing-at-point))) "-nopakf -noerror"))

(defun x/eack-thing-top ()
  "xs eack (vc top)"
  (interactive)
  (tm-sph (concat "xs eack-top " (pen-q (pen-thing-at-point))) "-nopakf -noerror"))

;; Automation using my x and xs scripts

;; $HOME/scripts/x
;; $HOME/scripts/xs   

(provide 'pen-x)
