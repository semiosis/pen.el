;; (require 'pen-browser)
(require 'engine-mode)
;; (require 'pen-search)

(defun pen-eww-js-for-browse-url (url discard)
  (lg-eww-js url nil))

(defun pen-eww-for-browse-url (url discard)
  (lg-eww url nil))

(setq engine/browser-function 'pen-eww-for-browse-url)

(engine/set-keymap-prefix (kbd "H-/"))

(engine-mode 1)

(defun defengine-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (add-to-list 'search-functions (intern (concat "engine/search-" (str (car args)))))
    res))
(advice-add 'defengine :around #'defengine-around-advice)

;; Also Use =C-x /= to invoke engine-mode
(define-key engine-mode-map (kbd "C-x /") engine-mode-prefixed-map)

(defengine gs
  "https://github.com/search?ref=simplesearch&q=%s"
  :keybinding "e"
  :browser 'pen-eww-browse-url)

(defengine amazon
  "http://www.amazon.com/s/ref=nb_sb_noss?url=search-alias%3Daps&field-keywords=%s")

(defengine clojars-clojure-templates
  "https://clojars.org/search?q=%s"
  :keybinding "C")

(defengine duckduckgo
  "https://duckduckgo.com/?q=%s"
  :keybinding "k")

(defengine libraries
  "https://libraries.io/search?q=%s"
  :keybinding "/")

(defengine wordincontext
  ;; Ludwig has a very low limit
  ;; "https://ludwig.guru/s/%s"
  "https://wordincontext.com/en/%s"
  :keybinding "c")

(defengine libgen
  "http://gen.lib.rus.ec/search.php?req=%s&lg_topic=libgen&open=0&view=simple&res=25&phrase=1&column=def"
  :keybinding "I")

(defengine project-gutenberg
  "http://www.gutenberg.org/ebooks/search/?query=%s"
  :keybinding "U")

(defengine codesearch-debian
  "https://codesearch.debian.net/search?q=%s"
  :keybinding "d")

(defengine searchcode
  "https://searchcode.com/?q=%s"
  :keybinding "s")

(defengine talktobooks
  "https://books.google.com/talktobooks/query?q=%s"
  :keybinding "t")

(defengine hoogle
  "https://www.haskell.org/hoogle/?hoogle=%s"
  :keybinding "7")

(defengine rosindex
  "https://index.ros.org/search/?term=%s"
  :keybinding "R")

(defengine racket
  "http://docs.racket-lang.org/search/index.html?q=%s"
  :keybinding "r")

(defengine racket-languages
  "http://docs.racket-lang.org/search/index.html?q=H:%s"
  :keybinding "l")

(defengine google
  "http://www.google.com/search?ie=utf-8&oe=utf-8&q=%s"
  :keybinding "g"
  :browser 'lg-eww)

(defun chrome (url &optional discard)
  (interactive (read-string-hist "chrome: "))
  (pen-ns (concat "Chrome: " url))
  (pen-sn (concat "chrome " (pen-q url))))

;; Unfortunately, search requires that I am logged in
(defengine github-advanced
  "https://github.com/search?q=%s&type=Code&ref=advsearch&l=GraphQL&l="
  :keybinding "H"
  :browser 'chrome)

(defengine github
  "https://github.com/search?ref=simplesearch&q=%s"
  :keybinding "h")

(defengine google-lucky
  "http://www.google.com/search?ie=utf-8&oe=utf-8&btnI&q=%s"
  :keybinding "L"
  :browser 'pen-eww-for-browse-url)

(defun browsh (&rest body)
  (interactive (list (read-string "url:")))

  (if (not body)
      (setq body '("http://google.com")))

  (pen-sps (concat "browsh " (pen-q (car body)))))

(defun ebrowsh (url)
  "This is very slow, actually"
  (interactive (list (read-string "url:")))

  (if (not url)
      (setq url '("http://google.com")))

  (pen-term-nsfa (concat "browsh -s " (pen-q url))))

(defengine grep-app
  "https://grep.app/search?q=%s"
  :keybinding "G"
  :browser 'browsh)

(defengine google-images
  "http://www.google.com/images?hl=en&source=hp&biw=1440&bih=795&gbv=2&aq=f&aqi=&aql=&oq=&q=%s"
  :keybinding "i")

(defengine google-maps
  "http://maps.google.com/maps?q=%s"
  :docstring "Mappin' it up."
  :keybinding "m")

(defengine programming-idioms
  "https://programming-idioms.org/search/%s"
  :keybinding "5")

(defengine rfcs
  "http://pretty-rfc.herokuapp.com/search?q=%s")

(defengine artifacthub
  "https://artifacthub.io/packages/search?ts_query_web=%s&sort=relevance&page=1")

(defengine stack-overflow
  "https://stackoverflow.com/search?q=%s"
  :keybinding "o")

(defengine wikipedia
  "http://www.wikipedia.org/search-redirect.php?language=en&go=Go&search=%s"
  :keybinding "w"
  :docstring "Searchin' the wikis.")

(defengine wiktionary
  "https://www.wikipedia.org/search-redirect.php?family=wiktionary&language=en&go=Go&search=%s"
  :keybinding "k")

(defengine wolfram-alpha
  "http://www.wolframalpha.com/input/?i=%s"
  :keybinding "a")

(defengine youtube
  "http://www.youtube.com/results?aq=f&oq=&search_query=%s")

;; I may need to use a proxy address
(defengine thepiratebay
  "http://uj3wazyk5u4hnvtk.onion/search/%s/0/99/0"
  :keybinding "p")

(defengine huggingface-modelhub
  "https://huggingface.co/models?search=%s"
  :keybinding "u")

(defun engine/prompted-search-term (engine-name)
  (let ((current-word (or (thing-at-point 'symbol) "")))
    (read-string-hist (engine/search-prompt engine-name current-word)
                      nil nil current-word)))

(defalias 'find-book-online 'engine/search-libgen)

(provide 'pen-engine-mode)
