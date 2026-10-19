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

;; pa:link-hint
(comment
 ;; This one is fine
 (link-hint--collect (point-min) (point-max) 'link-hint-text-url)
 (funcall (get 'link-hint-text-url :at-point-p))
 ;; This one is problematic
 (link-hint--collect (point-min) (point-max) 'link-hint-help-link)
 (funcall (get 'link-hint-help-link :at-point-p))
 (j (get 'link-hint-help-link :at-point-p))

 ;; Here, the list is converted into a string. That's the problem
 ;; j:link-hint--help-link-at-point-p

 ;; T his kind of code is problematic:
 (make-text-button (mark) (point)
                   'type 'help-function
                   'help-args (list 'make-text-button)))
(defun link-hint--collect-visible-links ()
  "Collect all visible links in the current buffer."
  (let (all-link-positions)
    (dolist (bounds (link-hint--find-visible-regions (window-start)
                                                     (window-end nil t)))
      (dolist (type link-hint-types)
        (when (link-hint--type-valid-p type)

          (let ((links (link-hint--collect (car bounds) (cdr bounds) type)))
            (setq all-link-positions
                  (append all-link-positions
                          links))
            (message (concat (str type) "=" (pps links)))))))

    (sort (cl-delete-duplicates all-link-positions
                                :test #'link-hint--equal
                                ;; types earlier in `link-hint-types' have
                                ;; higher priority
                                :from-end t)
          #'link-hint--<)))

;; The fix
(defun link-hint--help-link-at-point-p ()
  "Return the name of the help link at the point or nil."
  (let ((help-link (get-text-property (point) 'help-args)))
    (cond
     ((and (consp help-link)
           (eq 1 (length help-link)))
      (str (car help-link)))
     (help-link
      (pps help-link)))))

(provide 'pen-links)
