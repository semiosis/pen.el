;; Discover prompts from gptprompts.org
;; https://gptprompts.org/prompts?format=json

(require 'json)

(defun pen-gptprompts-list-prompts ()
  (ecurl "https://gptprompts.org/prompts?format=json"))

(provide 'pen-gptprompts)