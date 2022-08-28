(require 'json-mode)

(defun docker-utils-inspect ()
  "Docker Inspect the tablist entry under point."
  (interactive)
  (let ((entry-id (tabulated-list-get-id)))
    (docker-utils-with-buffer (format "inspect %s" entry-id)
      (insert (docker-run-docker "inspect" () entry-id))
      (json-mode)
      (view-mode))))

(provide 'pen-docker)
