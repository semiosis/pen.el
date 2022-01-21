(require 'openwith)

(setq openwith-associations '(
                              ("\\.mp4\\'" "pen-sps win vp" (file))
                              ("\\.webm\\'" "pen-sps win vp" (file))
                              ("\\.npy\\'" "pen-sps o" (file))
                              ("\\.png\\'" "pen-sps win ie" (file))
                              ("\\.gif\\'" "pen-sps open-gif" (file))
                              ("\\.jpe?g\\'" "pen-sps win ie" (file))
                              ("\\.mp3\\'" "win music" (file))
                              ("\\.m4a\\'" "win music" (file))))

(openwith-mode t)

;; nadvice - proc is the original function, passed in. do not modify
(defun openwith-mode-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    res))
(advice-add 'openwith-mode :around #'openwith-mode-around-advice)

(provide 'pen-openwith)