(require 'elfeed)
(require 'elfeed-score)
;; (require 'universal-sidecar-elfeed-score)

;; Load elfeed-org
(require 'elfeed-org)

;; Initialize elfeed-org
;; This hooks up elfeed-org to read the configuration when elfeed
;; is started with =M-x elfeed=
(elfeed-org)

;; Optionally specify a number of files containing elfeed
;; configuration. If not set then the location below is used.
;; Note: The customize interface is also supported.
(setq rmh-elfeed-org-files (list "/root/.pen/conf/elfeed.org"))

(define-key elfeed-search-mode-map (kbd "a") 'elfeed-add-feed)

(comment
 ;; This is immutable, thankfully, but where are these saved?
 (elfeed-add-feed "https://lexi-lambda.github.io/feeds/all.rss.xml" :save t)
 ;; (elfeed-add-feed "https://mullikine.github.io/index.xml" :save t)
 (elfeed-add-feed "https://news.ycombinator.com/rss" :save t)
 (elfeed-add-feed "https://ahungry.com/blog/rss.xml" :save t)
 (elfeed-add-feed "https://nullprogram.com/feed/" :save t)
 (elfeed-add-feed "https://planet.emacslife.com/atom.xml" :save t)
 (elfeed-add-feed "https://www.reddit.com/r/emacs/.rss" :save t))

(setq elfeed-feeds
      '("https://reddit.com/r/emacs/.rss"
        "https://planet.emacslife.com/atom.xml" "https://nullprogram.com/feed/" "https://news.ycombinator.com/rss" "https://ahungry.com/blog/rss.xml"))

;; show the feeds
;; (mapcar 'list elfeed-feeds)

(define-key elfeed-search-mode-map (kbd "U") 'elfeed-update)

(provide 'pen-elfeed)
