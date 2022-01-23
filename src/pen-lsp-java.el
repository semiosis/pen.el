(require 'cc-mode)

(use-package lsp-java :ensure t :after lsp
  :config (add-hook 'java-mode-hook 'lsp))

(use-package dap-java :after (lsp-java))


;; For some reason, this globbed all of them and didn't bother selecting the one with highest version
;; It decided to instead just fail with pcase
(defun lsp-java--locate-server-jar ()
  "Return the jar file location of the language server.

The entry point of the language server is in `lsp-java-server-install-dir'/plugins/org.eclipse.equinox.launcher_`version'.jar."
  (pcase (list (-last-item (f-glob "org.eclipse.equinox.launcher_*.jar" (expand-file-name "plugins" lsp-java-server-install-dir))))
    (`(,single-entry) single-entry)
    (`nil nil)
    (server-jar-filenames
     (error "Unable to find single point of entry %s" server-jar-filenames))))

(provide 'pen-lsp-java)