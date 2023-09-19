(require 'openwith)
(setq openwith-associations '(
                              ("\\.mp4\\'" "pen-sps pen-win vp" (file))
                              ("\\.webm\\'" "pen-sps pen-win vp" (file))
                              ("\\.mkv\\'" "pen-sps pen-win vp" (file))
                              ("\\.npy\\'" "pen-sps o" (file))
                              ("\\.png\\'" "pen-sps pen-win ie" (file))
                              ("\\.gif\\'" "pen-sps open-gif" (file))
                              ("\\.jpe?g\\'" "pen-sps pen-win ie" (file))
                              ("\\.mp3\\'" "pen-win music" (file))
                              ("\\.m4a\\'" "pen-win music" (file))))

(openwith-mode t)

(defun openwith-open-unix (command arglist)
  "Run external command COMMAND, in such a way that it is
  disowned from the parent Emacs process.  If Emacs dies, the
  process spawned here lives on.  ARGLIST is a list of strings,
  each an argument to COMMAND."
  (setq command (concat
                 "sh -c \""
                 (concat
                  "export PEN_GUI=" (if (display-graphic-p)
                                        "y"
                                      "n")
                  "; "
                  command
                  " \\\"\\$@\\\"\"")
                 " --"))
  (let ((shell-file-name "/bin/sh"))
    (start-process-shell-command
     "openwith-process" nil
     (concat
      "exec nohup " command " "
      (mapconcat 'shell-quote-argument arglist " ")
      " >/dev/null"))))

;; nadvice - proc is the original function, passed in. do not modify
(defun openwith-mode-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    res))
(advice-add 'openwith-mode :around #'openwith-mode-around-advice)

(advice-add 'dired--find-file :around #'ignore-errors-around-advice)

;; (error) is used to abort higher functions, so I can't ignore errors for the subfunctions
;; (advice-add 'openwith-file-handler :around #'ignore-errors-around-advice)
;; (advice-remove 'openwith-file-handler #'ignore-errors-around-advice)
;; (advice-add 'find-file-noselect :around #'ignore-errors-around-advice)
;; (advice-remove 'find-file-noselect #'ignore-errors-around-advice)

(provide 'pen-openwith)
