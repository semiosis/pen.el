(require 'ssh-deploy)
(require 'pen-tablist)

(defun ssh/ssh-tablist (&rest args)
  "Like docker-mode but for ssh."
  (interactive)
  (cmd-out-to-tablist-quick "tablist-list-ssh-hosts"
                            t))

(provide 'pen-ssh)
