(defvar current-hscroll-number (window-hscroll))

(defvar changed-hscroll-hook nil)

(defun update-hscroll-number ()
  (let ((new-hscroll-number (window-hscroll)))
    (message "hs %d" (window-hscroll))
    (when (not (equal new-hscroll-number current-hscroll-number))
      (setq current-hscroll-number new-hscroll-number)
      (run-hooks 'changed-hscroll-hook))))

;; Example of hook usage

(defun my-hscroll-func ()
  (if (not (major-mode-p 'messages-buffer-mode))
      (pen-message-no-echo "This is the current hscroll: %s" current-hscroll-number)))

(add-hook 'changed-hscroll-hook #'my-hscroll-func)
;; (remove-hook 'changed-hscroll-hook #'my-hscroll-func)

;; (add-hook 'post-command-hook #'update-hscroll-number)
;; (remove-hook 'post-command-hook #'update-hscroll-number)

;; sp +/"\/\* I hope this works\*\/" "$MYGIT/emacs/src/window.c"

;; modified   src/window.c
;; @@ -1303,6 +1303,10 @@ set_window_hscroll (struct window *w, EMACS_INT hscroll)
;;    w->hscroll = new_hscroll;
;;    w->suspend_auto_hscroll = true;
 
;; +  /* I hope this works*/
;; +  /* safe_run_hooks (Qwindow_state_change_hook); */
;; +  /* Yes, it worked. But it's only triggered when I, say, change to the minibuffer and back */
;; +  /* I want it to trigger when I go to the end of the line, etc. */
;;    return make_fixnum (new_hscroll);
;;  }


;; I am trying this next:

;; modified   src/xdisp.c
;; @@ -16073,8 +16073,12 @@ hscroll_window_tree (Lisp_Object window)
;;  hscroll_windows (Lisp_Object window)
;;  {
;;    bool hscrolled_p = hscroll_window_tree (window);
;; -  if (hscrolled_p)
;; +  if (hscrolled_p) {
;;      clear_desired_matrices (XFRAME (WINDOW_FRAME (XWINDOW (window))));
;; +    
;; +    /* I hope this works*/
;; +    safe_run_hooks (Qwindow_state_change_hook);
;; +  }
;;    return hscrolled_p;
;;  }

;; This did it! - Now the header line updates when I scroll in tabulated-list-mode
;; v +/"safe_run_hooks (Qwindow_state_change_hook);" "$MYGIT/emacs/src/xdisp.c"

;; (add-hook 'window-state-change-hook #'update-hscroll-number)
;; (remove-hook 'window-state-change-hook #'update-hscroll-number)
(add-hook 'window-state-change-hook #'tabulated-list-init-header)
(add-hook 'window-state-change-hook #'lsp-ui-doc-hide)
;; (remove-hook 'window-state-change-hook #'tabulated-list-init-header)

;; (run-hooks 'window-state-change-hook)
;; (add-hook 'window-configuration-change-hook #'update-hscroll-number)

;; Sadly, this isn't the function that's called when the hscroll changes
;; (set-window-hscroll (selected-window) 0)


;; Sigh... that's rather frustrating that set-window-hscroll
;; is not what is called by emacs when the hscroll changes
;; when I move forward or backwards along the line.
;; It would be really annoying to need to hook into lots of things
;; to get the behaviour I want.
(comment
 (defun set-window-hscroll-around-advice (proc &rest args)
   (let ((res (apply proc args)))
     (run-hooks 'changed-hscroll-hook)
     res)))
;; (advice-add 'set-window-hscroll :around #'set-window-hscroll-around-advice)
;; (advice-remove 'set-window-hscroll #'set-window-hscroll-around-advice)


;; Hmmm... also this mode is a variable
;; (setq auto-hscroll-mode t)
;; I think this is where a hook should exist.


;; (advice-add 'window-hscroll :around #'set-window-hscroll-around-advice)
;; (advice-remove 'window-hscroll #'set-window-hscroll-around-advice)

(provide 'pen-hscroll-changed)
