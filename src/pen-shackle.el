(require 'shackle)

;; shackle gives you the means to put an end to popped up buffers not
;; behaving they way you'd like them to. By setting up simple rules you
;; can for instance make Emacs always select help buffers for you or
;; make everything reuse your currently selected window.

;; Shackle
;; https://github.com/wasamasa/shackle

;; I think shackle must use display-buffer-alist
;; It hooks into it.
;; [[https://www.youtube.com/watch?v=rjOhJMbA-q0][Emacs: window rules and parameters (`display-buffer-alist' and extras) - YouTube]]

;; split-window-sensibly
(defun pen--shackle-sensible-alignment (&optional window)
  (interactive)
  (let ((window (or window (selected-window))))
    ;; Prioritise splitting right
    (or (and (window-splittable-p window t)
             'right)
        (and (window-splittable-p window)
             'below)
        (and
         ;; If WINDOW is the only usable window on its frame (it is
         ;; the only one or, not being the only one, all the other
         ;; ones are dedicated) and is not the minibuffer window, try
         ;; to split it vertically disregarding the value of
         ;; `split-height-threshold'.
         (let ((frame (window-frame window)))
           (or
            (eq window (frame-root-window frame))
            (catch 'done
              (walk-window-tree (lambda (w)
                                  (unless (or (eq w window)
                                              (window-dedicated-p w))
                                    (throw 'done nil)))
                                frame)
              t)))
         (not (window-minibuffer-p window))
         (let ((split-height-threshold 0))
           (when (window-splittable-p window)
             'below))))))

(use-package shackle
  :if (not (bound-and-true-p disable-pkg-shackle))
  :config
  (progn
    (setq shackle-lighter "")
    (setq shackle-select-reused-windows nil) ; default nil
    (setq shackle-default-alignment 'below)  ; default below
    ;; (setq shackle-default-alignment 'same) ; default below
    (setq shackle-default-size 0.4)     ; default 0.5


    ;; CONDITION(:regexp ) :select :inhibit-window-quit :size+ :align| :other :same| :popup

    ;; Do not escape values which do not have ":regexp t"

    ;; Sometimes it's necessary to edit the function
    ;; vim +/";; Don't call pop-to-buffer. Use display-buffer instead because it doesn't select" "$MYGIT/config/emacs/config/my-anaconda.el"

    ;; Create new emacs buffers to test shackle
    ;; (display-buffer (generate-new-buffer "*Help*") '(display-buffer-pop-up-frame . nil))

    (setq shackle-rules
          '(
            ;; These don't work. I don't know why
            (magit-process-mode :select nil :inhibit-window-quit t :same nil :align pen--shackle-sensible-alignment :size 0.5)
            ("\\*magit-process:" :regexp t :select nil :inhibit-window-quit t :same nil :align pen--shackle-sensible-alignment :size 0.5)
            ("*pen-help*" :size 0.25 :align right)
            ;; You can also do it this way
            ;; (compilation-mode :select nil)
            ("*fs-mode*" :ignore nil :select t :same t)
            ("*flycheck-error-list-mode*" :ignore nil :select t :same t)
            ("*Bluetooth device info*" :ignore nil :select t :same t)
            ("*kubernetes logs*" :ignore nil :select t :same t)
            ("*slime-description*" :ignore nil :select t :same nil)
            ;; ("*Free keys*" :ignore nil :select nil :same nil :align pen--shackle-sensible-alignment)
            (hackernews-mode :ignore nil :select t :same t)
            (chess-display-mode :ignore nil :select t :same t)
            (cider-repl-mode :ignore nil :select t :same t)
            (sql-interactive-mode :ignore nil :select t :same t)
            ;; (cider-stacktrace-mode :ignore nil :select nil :same t)
            (python-pytest-mode :ignore nil :select t :same t)
            (evil-list-view-mode :ignore nil :select t :same t)
            ;; ("\\*Puppet Lint:.*" :regexp t :ignore nil :select t :same t)
            ("*Occur*" :ignore nil :select t :same t)
            ("*Phases of Moon*" :ignore nil :select t :same t)
            (inf-ruby-mode :ignore nil :select t :same t)
            (apu-mode :ignore nil :select t :same t)
            (geiser-repl-mode :ignore nil :select t :same t)
            (mastodon-mode :ignore nil :select t :same t)
            (sly-editing-mode :ignore t :select nil :same t)
            (inf-messer-mode :ignore nil :select t :same t)
            (sx-question-mode :ignore nil :select t :same t)
            (emoji-github-mode :ignore nil :select t :same t)
            (dogears-list-mode :ignore nil :select t :same t)
            ("*GitHub Emoji*" nil :select t :same t)
            ("*magit-prettier-graph*" :ignore nil :select t :same t)
            ("*xbm life*" :ignore nil :select t :same t)
            ("\\*docker.*\\*" :regexp t :ignore nil :select t :same t)
            ;; v +/";; I had to modify this function because shackled didn't work" "$HOME/local/bin/my-daemons.el"
            ("\\*daemons .*\\*" :regexp t :ignore nil :select t :same t)
            ("\\*define-it: .*\\*" :regexp t :ignore nil :select t :same t)
            ("\\*kubel .*\\*" :regexp t :ignore nil :select t :same t)
            ("\\*dante:.*\\*" :regexp t :ignore nil :select t :same t)
            ("\\*.*\\*\\.csv" :regexp t :ignore nil :select t :same t)
            ("magit.*\\.csv" :regexp t :ignore nil :select t :same t)
            ("*Flycheck checkers*" :ignore nil :select t :same t)
            ("\\*aws .*\\*" :regexp t :ignore nil :select t :same t)
            ("*HTTP Response*" :ignore nil :select t :same t)
            ("\\*Guix REPL.*" :regexp t :ignore nil :select t :same t)
            ("\\* Guile REPL .*" :regexp t :ignore nil :select t :same t)
            ("*aws-instances*" :ignore nil :select t :same t)
            ("*annotations*" :ignore nil :select t :same t)
            ("*inferior-lisp*" :ignore nil :select t :same t)
            ("\\*sly-mrepl.*" :regexp t :ignore nil :select t :same t)
            ("\\* docker image inspect.*" :regexp t :ignore nil :select t :same t)
            ("\\* docker container inspect.*" :regexp t :ignore nil :select t :same t)
            ("*undo-tree*" :size 0.25 :align pen--shackle-sensible-alignment)
            ("\\*sldb.*" :regexp t :size 0.40 :align pen--shackle-sensible-alignment)
            ("\\*slime.*" :regexp t :size 0.40 :align pen--shackle-sensible-alignment)
            ("*haskell-test*" :size 0.40 :align pen--shackle-sensible-alignment)
            ("\\*doc-override.*" :regexp t :size 0.25 :align pen--shackle-sensible-alignment)
            ("*Google Translate*" :size 0.25 :align pen--shackle-sensible-alignment :select t)
            ("*Flycheck error messages*" :size 0.25 :align pen--shackle-sensible-alignment :select nil)
            ;; ("*Racket REPL*" :size 0.15 :align below)
            ;; I want the default action to be to select the window
            ;; Let's say I ran racket-repl
            ;; Therefore, I use =save-window-excursion= for lispy's =e= binding
            ("*Racket REPL*" :select t :same t)
            ;; ("*Racket REPL*" :ignore t :select nil :same t)
            ("\\*YASnippet Tables.*" :regexp t :select t :same t)
            ("\\*Slack - .*" :regexp t :select t :same t)
            ("\\*magit-diff: .*" :regexp t :select t :same t)
            ("*Apropos*" :ignore nil :select t :same t)
            ("*prodigy*" :select t :same t)
            ("*lsp-diagnostics*" :select t :same t)
            ;; ("*Shell Command Output*" :select nil)
            ("*Shell Command Output*" :ignore t :select nil :same nil)
            ("\\*Async Shell.*" :regexp t :ignore t)
            ("*Async Shell Command*" :ignore t :select nil :same nil)
            ("*Process List*" :select t :same t)
            ("*pydoc*" :select nil :same t)
            ;; ("*Async Shell Command*" :select nil :same t)
            ("*url cookies*" :select nil :same t)
            ("\\*edit-indirect .*\\*" :regexp t :select t :same t)
            ("\\*How Do You.*\\*" :regexp t :select t :same t)
            ("\\*Perl-REPL.*\\*" :regexp t :select t :same t)
            ("\\*GHCi-REPL.*\\*" :regexp t :select t :same t)
            ("*eshell*" :select t :other t)
            ;; ("*Python*" :ignore t :select nil :same nil)
            ("*Python*" :ignore nil :select t :same t)
            ("*eww bookmarks*" :select nil :same t)
            (eww-bookmark-mode :select nil :same t)
            (python-pytest-mode :select nil :same t)
            ("*haskell*" :ignore t :select nil :same nil)
            ("*Compile-Log*" :ignore t :select nil :same nil)
            ("*Flycheck errors*" :select t :same t)
            ("*Warnings*" :ignore t :select nil :same t)
            ("*warnings*" :ignore t :select nil :same t)
            ("*Ibuffer*" :select t :same nil)
            ("*slime-description*" :select nil :same nil)
            ("*Proced*" :select t :same t)
            ("\\*edbi.*" :regexp t :select t :same t)
            ("\\*jenkins.*" :regexp t :select t :same t)
            ;; ("*Help*"  :select nil :align pen--shackle-sensible-alignment)
            ;; ("*Help*" :other t :select nil :align pen--shackle-sensible-alignment)
            ;; Only in spacemacs is :select not honored here
            ("*Anaconda*" :other t :select nil :same nil :align pen--shackle-sensible-alignment :size 0.5)
            ;; This prevents the help window from being selected
            ;; (setq help-window-select nil)
            ("*Help*" :select t :same t :align pen--shackle-sensible-alignment)
            ;; ("*Help*" :other t :select nil :same nil :align pen--shackle-sensible-alignment :size 0.5)
            ("\\*helpful .*" :regexp t :other t :select nil :same nil :align pen--shackle-sensible-alignment :size 0.5)
            ;; ("*Help*" :other t :select nil :same nil :align pen--shackle-sensible-alignment :size 0.25)
            ;; ("*Help*" :other t :select t)
            (circe-channel-mode :select t :same t)
            (circe-server-mode :select t :same t)
            ("*org-brain*" :select t :same t)
            ("*Bufler*" :select t :same t)
            ("*edbi-dialog-ds*" :select t :same t)
            ;; ("*Help*" :select t :same t)
            ;; If there are multiple wiki-summary's then shackle won't work
            ;;("*wiki-summary*"       :select t   :same t)
            ("\\*wiki-summary\\*.*" :regexp t :select t :same t)
            ("\\*Dictionary\\*.*" :regexp t :select t :same t)
            ("\\*gist-.*" :regexp t :select t :same t)
            ("\\*Org Src.*" :regexp t :select t :same t)
            ("*WordNut*" :select t :same t)
            ("*arXiv search*" :select t :same t)
            (occur-mode :select t :align t)
            ;; ("*Help*"              :select t   :inhibit-window-quit t  :other t)
            ;; ("*Help*" :select t :other t) ;; I want this to quit
            ("*Completions*" :size 0.3 :align t)
            ("*Messages*" :select nil :inhibit-window-quit t :other t)
            ("\\*[Wo]*Man.*\\*" :regexp t :select t :inhibit-window-quit t :same t)
            ("\\*poporg.*\\*" :regexp t :select t :other t)
            ;; ("*command-log*" :select nil :size 0.3 :align below)
            ;; I think command-log ignores everything. Either that, or I need to restart
            ("*command-log*" :select nil :ignore t)
            ("*Calendar*" :select t :size 0.3 :align below)
            ("*info*" :select t :inhibit-window-quit t :same t)
            (magit-status-mode :select t :inhibit-window-quit t :same t)
            (magit-log-mode :select t :inhibit-window-quit t :same t)))

    (shackle-mode 1)))



;; Elements of the `shackle-rules' alist:
;;
;; |-----------+------------------------+--------------------------------------------------|
;; | CONDITION | symbol                 | Major mode of the buffer to match                |
;; |           | string                 | Name of the buffer                               |
;; |           |                        | - which can be turned into regexp matching       |
;; |           |                        | by using the :regexp key with a value of t       |
;; |           |                        | in the key-value part                            |
;; |           | list of either         | a list groups either symbols or strings          |
;; |           | symbol or string       | (as described earlier) while requiring at        |
;; |           |                        | least one element to match                       |
;; |           | t                      | t as the fallback rule to follow when no         |
;; |           |                        | other match succeeds.                            |
;; |           |                        | If you set up a fallback rule, make sure         |
;; |           |                        | it's the last rule in shackle-rules,             |
;; |           |                        | otherwise it will always be used.                |
;; |-----------+------------------------+--------------------------------------------------|
;; | KEY-VALUE | :select t              | Select the popped up window. The                 |
;; |           |                        | `shackle-select-reused-windows' option makes     |
;; |           |                        | this the default for windows already             |
;; |           |                        | displaying the buffer.                           |
;; |-----------+------------------------+--------------------------------------------------|
;; |           | :inhibit-window-quit t | Special buffers usually have `q' bound to        |
;; |           |                        | `quit-window' which commonly buries the buffer   |
;; |           |                        | and deletes the window. This option inhibits the |
;; |           |                        | latter which is especially useful in combination |
;; |           |                        | with :same, but can also be used with other keys |
;; |           |                        | like :other as well.                             |
;; |-----------+------------------------+--------------------------------------------------|
;; |           | :ignore t              | Skip handling the display of the buffer in       |
;; |           |                        | question. Keep in mind that while this avoids    |
;; |           |                        | switching buffers, popping up windows and        |
;; |           |                        | displaying frames, it does not inhibit what may  |
;; |           |                        | have preceded this command, such as the          |
;; |           |                        | creation/update of the buffer to be displayed.   |
;; |-----------+------------------------+--------------------------------------------------|
;; |           | :same t                | Display buffer in the current window.            |
;; |           | :popup t               | Pop up a new window instead of displaying        |
;; |           | *mutually exclusive*   | the buffer in the current one.                   |
;; |-----------+------------------------+--------------------------------------------------|
;; |           | :other t               | Reuse the window `other-window' would select if  |
;; |           | *must not be used      | there's more than one window open, otherwise pop |
;; |           | with :align, :size*    | up a new window. When used in combination with   |
;; |           |                        | the :frame key, do the equivalent to             |
;; |           |                        | other-frame or a new frame                       |
;; |-----------+------------------------+--------------------------------------------------|
;; |           | :align                 | Align a new window at the respective side of     |
;; |           | 'above, 'below,        | the current frame or with the default alignment  |
;; |           | 'left, 'right,         | (customizable with `shackle-default-alignment')  |
;; |           | or t (default)         | by deleting every other window than the          |
;; |           |                        | currently selected one, then wait for the window |
;; |           |                        | to be "dealt" with. This can either happen by    |
;; |           |                        | burying its buffer with q or by deleting its     |
;; |           |                        | window with C-x 0.                               |
;; |           | :size                  | Aligned window use a default ratio of 0.5 to     |
;; |           | a floating point       | split up the original window in half             |
;; |           | value between 0 and 1  | (customizable with `shackle-default-size'), the  |
;; |           | is interpreted as a    | size can be changed on a per-case basis by       |
;; |           | ratio. An integer >=1  | providing a different floating point value like  |
;; |           | is interpreted as a    | 0.33 to make it occupy a third of the original   |
;; |           | number of lines.       | window's size.                                   |
;; |-----------+------------------------+--------------------------------------------------|
;; |           | :frame t               | Pop buffer to a frame instead of a window.       |
;; |-----------+------------------------+--------------------------------------------------|
;;
;; http://emacs.stackexchange.com/a/13687/115
;; Don't show Async Shell Command buffers

(provide 'pen-shackle)
