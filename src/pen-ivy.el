(defvar default-ivy-height 30)
(setq ivy-height default-ivy-height)

(defun pen-ivy-filtered-candidates ()
  "Returns the list of candidates filtered by the currently entered pattern"
  (ivy--filter ivy-text ivy--all-candidates))

(defun pen-ivy-current-string ()
  "Returns the candidate currently under the cursor (not all marked candidates)"
  (nth ivy--index (pen-ivy-filtered-candidates)))

(defun pen-ivy-get-selection ()
  "Copy the selected candidate as a string."
  (interactive)
  (let ((ret nil))
    (if (ivy--prompt-selected-p)
        (ivy-immediate-done)
      ;; (delete-minibuffer-contents)
      (setq ivy-current-prefix-arg current-prefix-arg)
      (cond ((or (> ivy--length 0)
                 ;; the action from `ivy-dispatching-done' may not need a
                 ;; candidate at all
                 (eq this-command 'ivy-dispatching-done))
             (let ((s (pen-ivy-current-string)))
               (xc s t)
               (setq ret s)
               s))
            ((memq (ivy-state-collection ivy-last)
                   '(read-file-name-internal internal-complete-buffer))
             (if (or (not (eq confirm-nonexistent-file-or-buffer t))
                     (equal " (confirm)" ivy--prompt-extra))
                 ;; (ivy--done ivy-text)
                 (ivy--done (pen-ivy-current-string))
               (setq ivy--prompt-extra " (confirm)")
               ;; (xc ivy-text t)
               (xc (ivy--done (pen-ivy-current-string)) t)
               (ivy--exhibit)))
            ((memq (ivy-state-require-match ivy-last)
                   '(nil confirm confirm-after-completion))
             ;; (ivy--done ivy-text)
             (ivy--done (pen-ivy-current-string)))
            (t
             (setq ivy--prompt-extra " (match required)")
             ;; (xc ivy-text t)
             (setq ret (pen-ivy-current-string))
             (ivy--exhibit))))

    (setq ret (--> ret
                   ;; remove grep numbers
                   (s-replace-regexp "^[^:]+:[0-9]+:[0-9]+: *" "" it)))
    
    ret))

(defun pen-ivy-copy-selection ()
  "Copy the selected candidate as a string."
  (interactive)
  (if (ivy--prompt-selected-p)
      (ivy-immediate-done)
    ;; It's really strange how it doesn't show, but it does copy
    (xc (pen-ivy-get-selection))))

;; TODO Explore an asynchronous edit while Pen.el is running
;; Maybe I have to use vim for the moment.

(defun ivy-alt-done (&optional arg)
  "Modified to = ivy-immediate-done.

Exit the minibuffer with the selected candidate.
When ARG is t, exit with current text, ignoring the candidates.
When the current candidate during file name completion is a
directory, continue completion from within that directory instead
of exiting.  This function is otherwise like `ivy-done'."
  (interactive "P")
  (ivy-immediate-done))

(defun ivy-edit-and-use-selection (text &optional edit-fn)
  "Copy the selected candidate as a string."
  (interactive (list (if (selected-p)
                         (selection))))
  (if (ivy--prompt-selected-p)
      (ivy-alt-done (pen-ivy-get-selection))
    ;; It's really strange how it doesn't show, but it does copy
    ))

(defun pen-ivy-edit-and-use-selected-continuation (text)
  "Copy the selected candidate as a string."
  (interactive (list (if (selected-p)
                         (selection))))
  (if (ivy--prompt-selected-p)
      (ivy-alt-done (pen-ivy-get-selection))
    ;; It's really strange how it doesn't show, but it does copy
    ))

(defun pen-ivy-open-selection-in-vim ()
  "Copy the selected candidate as a string."
  (interactive)
  (if (ivy--prompt-selected-p)
      (ivy-immediate-done)
    (let ((c (concat "v " (pen-q (s-replace-regexp " .*" "" (pen-ivy-get-selection))))))
      (eval
       `(ivy-quit-and-run
          (pen-term-sps ,c))))))

(defun ivy-scroll-up ()
  (interactive)
  (dotimes (_n 8)
    ;; (call-interactively 'ivy-previous-line-or-history)
    (call-interactively 'ivy-previous-line)))

(defun ivy-scroll-down ()
  (interactive)
  (dotimes (_n 8)
    ;; (call-interactively 'ivy-next-line-or-history)
    (call-interactively 'ivy-next-line)))

(defun ivy-tvipe-filtered-candidates ()
  (interactive)
  (tvd (list2str (pen-ivy-filtered-candidates))))

(define-key ivy-minibuffer-map (kbd "<next>") 'ivy-scroll-down)
(define-key ivy-minibuffer-map (kbd "<prior>") 'ivy-scroll-up)

(define-key ivy-minibuffer-map (kbd "M-c") 'pen-ivy-copy-selection)
(define-key ivy-minibuffer-map (kbd "M-v") 'pen-ivy-open-selection-in-vim)
(define-key ivy-minibuffer-map (kbd "M-D") 'send-m-del)
(define-key ivy-minibuffer-map (kbd "C-c o") 'ivy-tvipe-filtered-candidates)

;; I havent got this going yet - C-' in the GUI does work
;; (define-key ivy-minibuffer-map (kbd "M-k") 'ivy-avy)
;; (define-key ivy-mode-map (kbd "M-k") 'ivy-avy)

(define-key ivy-mode-map (kbd "M-c") nil)
(define-key ivy-mode-map (kbd "M-D") nil)
(define-key ivy-mode-map (kbd "C-c o") nil)

(use-package ivy
  :defer 0.1
  :diminish
  :bind (
         :map ivy-minibuffer-map
         ("M-D" . send-m-del)
         ("M-c" . pen-ivy-copy-selection)
         ("M-v" . pen-ivy-open-selection-in-vim)
         ("M-p" . pen-previous-defun)
         ("M-n" . pen-next-defun)
         ("M-h" . sph)
         ("M-s" . spv)
         ("M-o" . ivy-sps-open)
         ("M-y" . ivy-sps-ff)
         ("M-e" . ivy-sps-eww)
         ;; Why is this globally bound? because  i have to prefix with :map
         ("C-c o" . ivy-tvipe-filtered-candidates)
         ;; ("<PageDown>" . nil)
         ;; ("<PageUp>" . nil)
         )
  ;; :bind (("C-c C-r" . ivy-resume)
  ;;        ("C-x b" . ivy-switch-buffer)
  ;;        ("C-x B" . ivy-switch-buffer-other-window))
  :custom
  (ivy-count-format "(%d/%d) ")
  (ivy-display-style 'fancy)
  (ivy-use-virtual-buffers t)
  :config (ivy-mode))

(defun pen-counsel--format-command (cmd extra-args needle)
  "Construct a complete `counsel-ag-command' as a string.
EXTRA-ARGS is a string of the additional arguments.
NEEDLE is the search string."
  (counsel--format
   cmd
   (if (listp cmd)
       (if (string-match " \\(--\\) " extra-args)
           (counsel--format
            (split-string (replace-match "%s" t t extra-args 1))
            needle)
         (nconc (split-string extra-args) needle))
     (if (string-match " \\(--\\) " extra-args)
         (replace-match needle t t extra-args 1)
       (concat extra-args " " needle)))))

;; The cmd takes a single string which is the search
;; In this case, it may be the first argument to a gpt3 prompt function
(defmacro pen-gen-counsel-generator-function (cmd)
  ""
  (let ((funsym (intern (concat "counsel-generator-function-" (slugify cmd))))
        (cmdstr (concat cmd " %s")))
    `(defun ,funsym (string)
       ,(concat "Run " cmd " in the current directory with STRING argument. Do this to generate candidates for ivy.")
       (let* ((command-args (counsel--split-command-args string))
              (search-term (cdr command-args)))
         (or
          (let ((ivy-text search-term))
            (ivy-more-chars))
          (let* ((default-directory (ivy-state-directory ivy-last))
                 (switches (concat (car command-args))))
            (counsel--async-command
             (concat
              (pen-counsel--format-command
               ,cmdstr
               switches
               (funcall (if (listp ,cmdstr) #'identity
                          #'shell-quote-argument)
                        string))
              " | cat"))
            nil))))))

(defmacro gen-counsel-function (cmd action)
  ""
  (let ((funsym (intern (concat "counsel-generated-" (slugify cmd))))
        (histvarsym (intern (concat "counsel-generated-" (slugify cmd) "-histvar")))
        (cmdstr (concat cmd " %s")))
    (eval `(defvar ,histvarsym nil))
    `(cl-defun ,funsym (&optional initial-input initial-directory extra-ag-args ag-prompt
                                  &key caller &key histvar)
       "Run an arbitrary external shell command in the current directory. Select from the results.

INITIAL-INPUT can be given as the initial minibuffer input.
INITIAL-DIRECTORY, if non-nil, is used as the root directory for search.
EXTRA-AG-ARGS, if non-nil, is appended to `counsel-ag-base-command'.
AG-PROMPT, if non-nil, is passed as `ivy-read' prompt argument.
CALLER is passed to `ivy-read'.

With a `\\[universal-argument]' prefix argument, prompt for INITIAL-DIRECTORY.
With a `\\[universal-argument] \\[universal-argument]' prefix argument, \
prompt additionally for EXTRA-AG-ARGS."
       (interactive)

       (if (not histvar)
           (defset histvar ',histvarsym))

       (setq counsel--regex-look-around nil)

       (let ((default-directory (or initial-directory
                                    (counsel--git-root)
                                    default-directory)))

         (ivy-read
          (concat ,cmd ": ")
          (pen-gen-counsel-generator-function ,cmd)
          :initial-input initial-input
          :dynamic-collection t
          :keymap counsel-ag-map
          :history histvar
          :action ,action
          :require-match t
          :caller
          (or caller ',funsym)
          )))))

(defun fz-pen-counsel ()
  (interactive)
  (let* ((pfp
          (fz
           (pen-snc
            (concat
             "cd "
             (pen-q (concat pen-prompts-directory "/prompts"))
             "; find . -maxdepth 1 -mindepth 1 -type f | sed -e 's/..//' -e 's/\\.prompt$//'"))
           nil
           nil
           "pen list: "))
         (cf (eval `(gen-counsel-function ,(concat "loop lm-complete -s " (pen-q pfp)) 'pen-etv))))
    (call-interactively cf)))

(defvar pen-ivy-result-tuple)

(defun ivy-call ()
  "Call the current action without exiting completion."
  (interactive)
  ;; Testing with `ivy-with' seems to call `ivy-call' again,
  ;; in which case `this-command' is nil; so check for this.
  (unless (memq this-command '(nil
                               ivy-done
                               ivy-alt-done
                               ivy-dispatching-done))
    (setq ivy-current-prefix-arg current-prefix-arg))
  (let* ((action
          (if (functionp ivy-inhibit-action)
              ivy-inhibit-action
            (and (not ivy-inhibit-action)
                 (ivy--get-action ivy-last))))
         (current (ivy-state-current ivy-last))
         (x (ivy--call-cand current))
         (res
          (cond
           ((null action)
            current)
           (t
            (select-window (ivy--get-window ivy-last))
            (set-buffer (ivy-state-buffer ivy-last))
            (prog1 (unwind-protect
                       (if ivy-marked-candidates
                           (ivy--call-marked action)
                         (funcall action x))
                     (ivy-recursive-restore))
              (unless (or (eq ivy-exit 'done)
                          (minibuffer-window-active-p (selected-window))
                          (null (active-minibuffer-window)))
                (select-window (active-minibuffer-window))))))))

    ;; This is needed, and the best way to get the tuple,
    ;; because when res is the tuple, ivy-inhibit-action is nil.
    ;; And when ivy-inhibit-action is t, res is not the tuple.
    ;; I can't be bothered digging further and changing behaviour.
    (setq pen-ivy-result-tuple res)

    (if ivy-inhibit-action
        res
      current)))

(define-key ivy-minibuffer-map (kbd "C-m") 'ivy-done)
(define-key ivy-minibuffer-map (kbd "C-M-d") 'ivy-immediate-done)
(define-key ivy-minibuffer-map (kbd "C-M-j") nil)

(comment
 (defset ivy-minibuffer-map
         (let ((map (make-sparse-keymap)))
           (ivy-define-key map (kbd "C-m") 'ivy-done)
           (define-key map [down-mouse-1] 'ignore)
           (ivy-define-key map [mouse-1] 'ivy-mouse-done)
           (ivy-define-key map [mouse-3] 'ivy-mouse-dispatching-done)
           (ivy-define-key map (kbd "C-M-m") 'ivy-call)
           (ivy-define-key map (kbd "C-j") 'ivy-alt-done)
           (ivy-define-key map (kbd "C-M-j") 'ivy-immediate-done)
           (ivy-define-key map (kbd "TAB") 'ivy-partial-or-done)
           (ivy-define-key map [remap next-line] 'ivy-next-line)
           (ivy-define-key map [remap previous-line] 'ivy-previous-line)
           (ivy-define-key map (kbd "C-r") 'ivy-reverse-i-search)
           (define-key map (kbd "SPC") 'self-insert-command)
           (ivy-define-key map [remap delete-backward-char] 'ivy-backward-delete-char)
           (ivy-define-key map [remap backward-delete-char-untabify] 'ivy-backward-delete-char)
           (ivy-define-key map [remap backward-kill-word] 'ivy-backward-kill-word)
           (ivy-define-key map [remap delete-char] 'ivy-delete-char)
           (ivy-define-key map [remap forward-char] 'ivy-forward-char)
           (ivy-define-key map (kbd "<right>") 'ivy-forward-char)
           (ivy-define-key map [remap kill-word] 'ivy-kill-word)
           (ivy-define-key map [remap beginning-of-buffer] 'ivy-beginning-of-buffer)
           (ivy-define-key map [remap end-of-buffer] 'ivy-end-of-buffer)
           (ivy-define-key map (kbd "M-n") 'ivy-next-history-element)
           (ivy-define-key map (kbd "M-p") 'ivy-previous-history-element)
           (define-key map (kbd "C-g") 'minibuffer-keyboard-quit)
           (ivy-define-key map [remap scroll-up-command] 'ivy-scroll-up-command)
           (ivy-define-key map [remap scroll-down-command] 'ivy-scroll-down-command)
           (ivy-define-key map (kbd "<next>") 'ivy-scroll-up-command)
           (ivy-define-key map (kbd "<prior>") 'ivy-scroll-down-command)
           (ivy-define-key map (kbd "C-v") 'ivy-scroll-up-command)
           (ivy-define-key map (kbd "M-v") 'ivy-scroll-down-command)
           (ivy-define-key map (kbd "C-M-n") 'ivy-next-line-and-call)
           (ivy-define-key map (kbd "C-M-p") 'ivy-previous-line-and-call)
           (ivy-define-key map (kbd "M-a") 'ivy-toggle-marks)
           (ivy-define-key map (kbd "M-r") 'ivy-toggle-regexp-quote)
           (ivy-define-key map (kbd "M-j") 'ivy-yank-word)
           (ivy-define-key map (kbd "M-i") 'ivy-insert-current)
           (ivy-define-key map (kbd "C-M-y") 'ivy-insert-current-full)
           (ivy-define-key map (kbd "C-o") 'hydra-ivy/body)
           (ivy-define-key map (kbd "M-o") 'ivy-dispatching-done)
           (ivy-define-key map (kbd "C-M-o") 'ivy-dispatching-call)
           (ivy-define-key map [remap kill-line] 'ivy-kill-line)
           (ivy-define-key map [remap kill-whole-line] 'ivy-kill-whole-line)
           (ivy-define-key map (kbd "S-SPC") 'ivy-restrict-to-matches)
           (ivy-define-key map [remap kill-ring-save] 'ivy-kill-ring-save)
           (ivy-define-key map (kbd "C-M-a") 'ivy-read-action)
           (ivy-define-key map (kbd "C-c C-o") 'ivy-occur)
           (ivy-define-key map (kbd "C-c C-a") 'ivy-toggle-ignore)
           (ivy-define-key map (kbd "C-c C-s") 'ivy-rotate-sort)
           (ivy-define-key map [remap describe-mode] 'ivy-help)
           (ivy-define-key map "$" 'ivy-magic-read-file-env)
           map)
         "Keymap used in the minibuffer."))

;; Remove trailing whitespace after annotations
(defun ivy--format-minibuffer-line-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (s-replace-regexp "\s\+$" "" res)))
(advice-add 'ivy--format-minibuffer-line :around #'ivy--format-minibuffer-line-around-advice)
;; (advice-remove 'ivy--format-minibuffer-line #'ivy--format-minibuffer-line-around-advice)

;; Make it so I can click on results in ivy, as I can with helm
(defun ivy-mouse-done (event)
  (interactive "@e")
  (let ((offset (ivy-mouse-offset event)))
    (when offset
      (ivy-next-line offset)
      (ivy--exhibit)
      ;; (ivy-alt-done)
      (ivy-done))))

;; This ensures that the ivy-height is never too tall for the screen
(defun ivy--minibuffer-setup-around-advice (proc &rest args)
  (setq ivy-height
        (min
         default-ivy-height
         (- (frame-height)
            5)))
  (let ((res (apply proc args)))
    res))
(advice-add 'ivy--minibuffer-setup :around #'ivy--minibuffer-setup-around-advice)
;; (advice-remove 'ivy--minibuffer-setup #'ivy--minibuffer-setup-around-advice)

(provide 'pen-ivy)
