(require 'pen-helm)

(defun pen-fz (list &key prompt &key full-frame &key initial-input &key must-match &key select-only-match &key hist-var &key add-props &key no-hist)
  ;; (cl-fz results :prompt prompt :key full-frame :key initial-input :key must-match :key select-only-match :key hist-var :key add-props :key no-hist)
  (fz-helm results prmopt))

(provide 'pen-fz)