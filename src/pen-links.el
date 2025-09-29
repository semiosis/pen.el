(require 'org-link-minor-mode)

;; This is to fix org-links for emacs29
(advice-add 'org-fold-core-set-folding-spec-property :around #'ignore-errors-around-advice)

;; TODO make it so the links remain expanded if it's a prog-mode
;; because languages such as closure often use things which look like
;; org links but are actually not.
;; Alternatively, see if I can get them to only display if it's in a comment
;; org-link-minor-mode
;; (defun in-comment-p ()
;;   (eq 'font-lock-comment-face
;;       (pen-face-at-point)))

;; I modified it in e:pen-org.el
;; j:org-activate-links--text-properties
;; (defun org-activate-links--overlays (limit)
;;   nil)
;; (defun org-activate-links--text-properties (limit)
;;   nil)

(defun pen-go-to-prompt-function-definition (prompt-function-name-or-sym)
  (interactive (list (fz pen-prompt-functions nil nil "prompt function: ")))

  ;; I could, rather, consult the prompt function database
  (if (sor prompt-function-name-or-sym)
      (let* ((prompt-fn
              (->> (str prompt-function-name-or-sym)
                   (s-replace-regexp "\\.prompt$" "")
                   (s-replace-regexp "^\\(pf\\|pen-fn\\)-" "")
                   (s-replace-regexp "/" "-")
                   (string-replace "--" "-")
                   (s-replace-regexp "$" ".prompt"))))
        (find-file (f-join pen-prompts-directory "prompts" prompt-fn)))))

(org-add-link-type "prompt" 'pen-go-to-prompt-function-definition)

(define-key org-link-minor-mode-map (kbd "C-c C-o") 'org-open-at-point)

(provide 'pen-links)
