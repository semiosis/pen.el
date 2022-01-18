;; * TODO =continue-mode= should not be the default mode for prompts, but I should be able to enable it in emacs
;; ** TODO Add a set of modes to emacs buffers
;; Toggle them on, along with default variables.
;; -
;; Also, enable default variables to be evaluated.
;; Then create pen-minor-modes.
;; These minor modes should set defaults in prompt functions.


(defvar pen-mydefaults-minor-mode-map (make-sparse-keymap)
  "Keymap for `pen-mydefaults-minor-mode'.")

;;;###autoload
(define-minor-mode pen-mydefaults-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  ;; If init-value is not set to t, this mode does not get enabled in
  ;; `fundamental-mode' buffers even after doing \"(global-pen-mydefaults-minor-mode 1)\".
  ;; More info: http://emacs.stackexchange.com/q/16693/115
  :init-value t
  ;; :lighter " pen-mydefaults"
  :lighter " 🖊"
  :keymap pen-mydefaults-minor-mode-map)


(provide 'pen-minor-modes)