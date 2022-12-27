(require 'pen-helm)

(cl-defun pen-fz (candidates
                  &key prompt
                  &key full-frame
                  &key initial-input
                  &key must-match
                  &key select-only-match
                  &key hist-var
                  &key add-props
                  &key no-hist)
  ;; (cl-fz results :prompt prompt :key full-frame :key initial-input :key must-match :key select-only-match :key hist-var :key add-props :key no-hist)
  (if (stringp candidates)
      (setq candidates (pen-str2list candidates)))
  (fz-helm
   ;; Remove ink
   ;; (mapcar 'str candidates)
   candidates (or (sor prompt)
                  "Select: ")))

(provide 'pen-fz)
