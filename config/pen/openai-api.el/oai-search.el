(require 'oai-files)

;; https://beta.openai.com/docs/api-reference/searches/

(defun oai-search (job-id documents max-rerank query)
  (pen-snc (cmd "pen-openai-official"
                "api"
                "engines.search"
                "-d" documents
                "--max_rerank" max-rerank
                "-q" query)))

(provide 'oai-search)