(require 'wiki-nav) 
(require 'wikinfo) 
(require 'wikinforg)

(require 'tracwiki-mode)
(advice-remove 'url-retrieve-synchronously #'ad-Advice-url-retrieve-synchronously)

(require 'plain-org-wiki) 
(require 'org-multi-wiki) 
(require 'ox-mediawiki) 
(require 'mediawiki) 
(require 'helm-wikipedia) 
;; (require 'helm-org-multi-wiki) 

;; DONE Make this open up the wikipedia summary instead of open the eww browser
(defset helm-source-wikipedia-suggest
  (helm-build-sync-source "Wikipedia Suggest"
    :candidates #'helm-wikipedia-suggest-fetch
    :action '(("Wikipedia" . (lambda (candidate)
                               (comment
                                (helm-search-suggest-perform-additional-action
                                 helm-search-suggest-action-wikipedia-url
                                 candidate))

                               candidate
                               ;; This does it
                               ;; (noop
                               ;;  (wiki-summary candidate)
                               ;;  ;; candidate
                               ;;  )
                               ))
              ("Show summary in new buffer (C-RET)" . helm-wikipedia-show-summary))
    :persistent-action #'helm-wikipedia-persistent-action
    :persistent-help "show summary"
    :match-dynamic t
    :keymap helm-wikipedia-map
    :requires-pattern 3))

(defun wiki-summary-after-advice (&rest args)
  (toggle-read-only)
  (pen-region-pipe "ttp")
  (toggle-read-only)
  (beginning-of-buffer))

(advice-add 'wiki-summary/format-summary-in-buffer :after 'wiki-summary-after-advice)

(defun wiki-summary-synchronous (s)
  (interactive
   (list
    (read-string (concat
                  "Wikipedia Article"
                  (if (thing-at-point 'word)
                      (concat " (" (thing-at-point 'word) ")")
                    "")
                  ": ")
                 nil
                 nil
                 (thing-at-point 'word))))

  ;; synchronous version of j:wiki-summary
  (save-excursion
    (with-current-buffer
        (with-current-buffer
            (url-retrieve-synchronously (wiki-summary/make-api-query s) t t 5)

          (message "")                  ; Clear the annoying minibuffer display
          (goto-char url-http-end-of-headers)
          (let ((json-object-type 'plist)
                (json-key-type 'symbol)
                (json-array-type 'vector))
            (let* ((result (json-read))
                   (summary (wiki-summary/extract-summary result)))
              (if (not summary)
                  (message "No article found")
                (wiki-summary/format-summary-in-buffer summary)))))
      
      ;; (tv (buffer-string))
      (with-writable-buffer
       (beginning-of-buffer)
       (org-link-minor-mode 1)
       ;; (insert-button (format "[[pen-wiki-summary:%s][%s]]\n\n" s s))
       (insert (format "Wikipedia summary for [[pen-wiki-summary:%s][%s]]:\n\n" s s))))))

(defalias 'pen-wiki-summary 'wiki-summary-synchronous)

(defun wikipedia-search (initial-input)
  (interactive (list (sor (pen-selected-text t))))
  (if (>= (prefix-numeric-value current-global-prefix-arg) 4)
      (if initial-input
          (wiki-summary initial-input)
        (call-interactively 'pen-wiki-summary))
    (if initial-input
        (helm-wikipedia-suggest initial-input)
      (call-interactively 'helm-wikipedia-suggest))))

(defun helm-wikipedia-suggest (&optional initial-input)
  "Preconfigured `helm' for Wikipedia lookup with Wikipedia suggest."
  (interactive)
  (let ((use-full-browser (>= (prefix-numeric-value current-prefix-arg) 4))
        (result
         (let ((helm-input-idle-delay helm-wikipedia-input-idle-delay)) 
           (helm :sources 'helm-source-wikipedia-suggest
                 :buffer "*helm wikipedia*"
                 :input initial-input
                 :input-idle-delay (max 0.4 helm-input-idle-delay)
                 :history 'helm-wikipedia-history))))
    (if result
        (if use-full-browser
            (engine/search-wikipedia result)
          (pen-wiki-summary result)))))

(provide 'pen-wiki)
