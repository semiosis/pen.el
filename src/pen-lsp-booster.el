;; https://www.reddit.com/r/emacs/comments/18ybxsa/emacs_lspmode_performance_booster/?%24deep_link=true&correlation_id=866ffc1d-a52d-4ad9-8551-1c03ff8b282a&post_fullname=t3_18ybxsa&post_index=1&ref=email_digest&ref_campaign=email_digest&ref_source=email&%243p=e_as&_branch_match_id=1080262788655345442&_branch_referrer=H4sIAAAAAAAAA22QXWrDMBCET%2BO%2B2a4l27iFEAql11hkaZWI6g9pjdPbd900fSpIaPiGnR10Jcr1te8LGuOoUzl33sXPXuZzI0aZTwiqPrFMxV1cVB624k%2FXY6qRb4344LPve%2Fc7r1NgUPhiULryyyRgpEMOy9d6q%2Bphgq85JIOQsdhUgooaYU2pEh4BjeTs0SBmOBo18p3Kho2YdSoFvSKXIjjDfJlna%2FVgWjUJ047KvLTLNA3toJ%2BltcsqFsFL58zJYDfvowp4xEn4a3Q3XTR4Y2dgUNCy4qLOg3EXrHSHoFXIyl3i%2F25NW9H48BhuFECnSPwHTH%2FWkCOP382XFY15AQAA
;; https://github.com/blahgeek/emacs-lsp-booster

(define-advice json-parse-buffer (:around (old-fn &rest args) lsp-booster-parse-bytecode)
  "Try to parse bytecode instead of json."
  (or
   (when (equal (following-char) ?#)
     (let ((bytecode (read (current-buffer))))
       (when (byte-code-function-p bytecode)
         (funcall bytecode))))
   (apply old-fn args)))

(define-advice lsp-resolve-final-command (:around (old-fn cmd &optional test?) add-lsp-server-booster)
  "Prepend emacs-lsp-booster command to lsp CMD."
  (let ((orig-result (funcall old-fn cmd test?)))
    (if (and (not test?)                             ;; for check lsp-server-present?
             (not (file-remote-p default-directory)) ;; see lsp-resolve-final-command, it would add extra shell wrapper
             lsp-use-plists
             (not (functionp 'json-rpc-connection))  ;; native json-rpc
             (executable-find "emacs-lsp-booster"))
        (progn
          (message "Using emacs-lsp-booster for %s!" orig-result)
          (cons "emacs-lsp-booster" orig-result))
      orig-result)))

(provide 'pen-lsp-booster)
