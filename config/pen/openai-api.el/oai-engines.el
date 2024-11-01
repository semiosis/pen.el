(require 'memoize)

;; This is actually defined in pen
(defun pen-openai-list-engines ()
  (let ((engines
         (pen-str2list
          (pen-snc "pen-openai-official api engines.list | jq -r '.data[].id'"))))
    (if (interactive-p)
        (etv (pen-list2str engines))
      engines)))

;; Can't memoize twice
;; (memoize 'pen-openai-list-engines)

(provide 'oai-engines)