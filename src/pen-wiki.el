(require 'wiki-nav) 
(require 'wikinfo) 
(require 'wikinforg) 
(require 'tracwiki-mode) 
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

                               ;; This does it
                               (noop
                                (wiki-summary candidate)
                                ;; candidate
                                )))
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

(defun wikipedia-search (initial-input)
  (interactive (list (sor (pen-selected-text t))))
  (if (>= (prefix-numeric-value current-global-prefix-arg) 4)
      (if initial-input
          (wiki-summary initial-input)
        (call-interactively 'wiki-summary))
    (if initial-input
        (helm-wikipedia-suggest initial-input)
      (call-interactively 'helm-wikipedia-suggest))))

(defun helm-wikipedia-suggest (&optional initial-input)
  "Preconfigured `helm' for Wikipedia lookup with Wikipedia suggest."
  (interactive)
  (let ((helm-input-idle-delay helm-wikipedia-input-idle-delay)) 
    (helm :sources 'helm-source-wikipedia-suggest
          :buffer "*helm wikipedia*"
          :input initial-input
          :input-idle-delay (max 0.4 helm-input-idle-delay)
          :history 'helm-wikipedia-history)))

(provide 'pen-wiki)
