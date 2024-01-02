(require 'elfeed)

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


;; This is immutable, thankfully, but where are these saved?
(elfeed-add-feed "https://lexi-lambda.github.io/feeds/all.rss.xml" :save t)
(elfeed-add-feed "https://mullikine.github.io/index.xml" :save t)
(elfeed-add-feed "https://news.ycombinator.com/rss" :save t)
(elfeed-add-feed "https://ahungry.com/blog/rss.xml" :save t)

;; show the feeds
;; (mapcar 'list elfeed-feeds)

(provide 'my-elfeed)
