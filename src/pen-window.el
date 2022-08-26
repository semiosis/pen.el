(require 'window)

(setq split-height-threshold 80)
(setq split-width-threshold 80)

;; This is no longer necessary. I have solved the problem with j:ranger-sub-window-setup
(comment
 (defun display-buffer-same-window (buffer alist)
   "Display BUFFER in the selected window.
ALIST is an association list of action symbols and values.  See
Info node `(elisp) Buffer Display Action Alists' for details of
such alists.

This function fails if ALIST has an `inhibit-same-window'
element whose value is non-nil, or if the selected window is a
minibuffer window or is dedicated to another buffer; in that case,
return nil.  Otherwise, return the selected window.

This is an action function for buffer display, see Info
node `(elisp) Buffer Display Action Functions'.  It should be
called only by `display-buffer' or a function directly or
indirectly called by the latter."
   (unless (or (cdr (assq 'inhibit-same-window alist))
	       (window-minibuffer-p)
	       (window-dedicated-p)
               ;; (major-mode-p 'ranger-mode)
               )
     (window--display-buffer buffer (selected-window) 'reuse alist))))

(provide 'pen-window)
