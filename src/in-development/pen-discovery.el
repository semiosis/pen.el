
;; (url-hexify-string "github.com/semiosis/prompts")

(defun find-prompt-repos (url &optional recursion-depth)
  "Go over each of the repositories in the prompts-library directory,
consolidate their prompt-repositories.txt files and optionally display"
  (interactive (list 5))
  (cl-loop for url in (pen-str2list (e/cat (concat pen-prompts-directory "/prompt-repositories.txt")))
           collect ))

(defun pull-prompt-repos ()
  )