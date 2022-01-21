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

;; nadvice - proc is the original function, passed in. do not modify
(defun openwith-mode-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    res))
(advice-add 'openwith-mode :around #'openwith-mode-around-advice)

(provide 'pen-openwith)