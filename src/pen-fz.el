(require 'pen-helm)

(cl-defun pen-fz (candidates &key prompt &key full-frame &key initial-input &key must-match &key select-only-match &key hist-var &key add-props &key no-hist)
  ;; (cl-fz results :prompt prompt :key full-frame :key initial-input :key must-match :key select-only-match :key hist-var :key add-props :key no-hist)
  (fz-helm candidates (or (sor prompt)
                          "Select: ")))

(provide 'pen-fz)