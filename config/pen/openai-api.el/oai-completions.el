;; https://beta.openai.com/docs/api-reference/completions/
;; https://beta.openai.com/docs/api-reference/parameter-details

(require 'oai-engines)

;; TODO Implement streaming completions
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Input-Streams.html

;; Open a process buffer and then do a similar thing to comint
;; Or perhaps I should simply use one comint per language model

;; I would then read everything through comint

(provide 'oai-completions)