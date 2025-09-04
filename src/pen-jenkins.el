(require 'jenkins)
(require 'jenkinsfile-mode)
(require 'jenkins-watch)

;; https://www.jenkins.io/doc/book/installing/linux/

(setq jenkins-api-token "<api token can be found on user's configure page>")
(setq jenkins-url "<jenkins url>")
(setq jenkins-username "<your user name>")
(setq jenkins-viewname "<viewname>")

(provide 'pen-jenkins)
