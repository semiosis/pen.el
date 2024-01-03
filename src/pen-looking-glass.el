;; 🔍 Looking-glass
;; “Where should I go?" -Alice. "That depends on where you want to end up." - The Cheshire Cat.” 🐈

;; Looking-glass web-browser (based on eww)

;; If a url is 404, then use the imaginary web-browser.
;; If a url is real then go to that.

;; When running an imaginary web search, optionally say which ones are real

(require 'eww)
(require 'pen-eww)
(require 'cl-lib)
;; (require 'eww-lnum)
(require 'pen-asciinema)

(defcustom pen-lg-always ""
  "Always use LG instead of real websites"
  :type 'boolean
  :group 'pen)

;; TODO Also make one that re-renders an eww website, imaginarily
(defun lg-render (ascii &optional url)
  (interactive (list (buffer-string)))

  (let* ((firstline (pen-snc "sed -n 1p | xurls" ascii))
         (rest (pen-snc "sed 1d" ascii))
         (url (or (sor url)
                  (sor firstline)))
         (ascii (if (sor url)
                    ascii
                  rest)))

    (new-buffer-from-string
     (car (pen-one (pf-generate-html-from-ascii-browser/2 url ascii)))
     nil 'text-mode)))

(defun test-lg-generate-alttext ()
  (interactive)
  ;; (pen-etv (lg-generate-alttext "https://en.wikipedia.org/static/images/project-logos/enwiki.png"))
  (pen-etv (lg-generate-alttext "https://mullikine.github.io/tagpics/Bodacious%20Blog.gif")))

(defun lg-get-alttext (fp-or-url)
  (let ((desc (sor (car (pen-one (pf-given-an-image-describe-it/1 fp-or-url)))
                   "?")))
    ;; (message desc)

    ;; If fp then convert the image into a standard format
    desc))

(defun lg-generate-alttext (fp-or-url &optional alt)
  (interactive
   (list (read-string-hist "lg-generate-alttext (fp or url): ")))
  ;; (pen-snc "tee -a ~/alttext.txt" fp-or-url)

  (if (sor alt)
      (setq alt
            (s-remove-trailing-newline
             (s-remove-leading-whitespace
              (s-remove-trailing-whitespace alt)))))

  (if (or (string-equal "*" alt)
          (not alt))
      (setq alt "Image"))

  (let* ((image-description
          (if pen-describe-images
              ;; alephalpha?
              (eval `(pen-ci (lg-get-alttext ,fp-or-url) ,(or (>= (prefix-numeric-value current-prefix-arg) 4)
                                                              (= (prefix-numeric-value current-prefix-arg) 0))))
            ;; (lg-get-alttext fp-or-url)
            nil))

         (image-description
          (or (eval-string image-description)
              ""))

         (image-description
          (if (string-equal "*" image-description)
              (setq image-description "?")
            image-description))

         (alttext-and-description
          (cond
           ((sor alt) (concat alt ":" image-description))
           ;; ((re-match-p "SVG" alt) (eval-string (eval `(pen-ci (lg-get-alttext ,fp-or-url)))))
           (t image-description)))

         ;; (alttext-and-description (concat fp-or-url (pen-q alttext-and-description) alt))
         )

    ;; (setq alttext-and-description (concat "'" alttext-and-description "'"))

    (if (interactive-p)
        (pen-etv alttext-and-description)
      (ink-propertise alttext-and-description))))

(defun pen-lg-select-rendering (results)
  (let* ((result (fz results nil nil "select rendering: ")))
    (new-buffer-from-string (ink-propertise result))))

(defun pen-lg-display-page (url)
  (interactive (list (read-string-hist "🔍 Enter URL: "
                                       (if (major-mode-p 'eww-mode)
                                           (get-path)))))
  (pen-lg-select-rendering (pf-imagine-a-website-from-a-url/1 url :no-select-result t))

  (comment
   (let ((content (s-join "\n\nNext result:\n\n" (pf-imagine-a-website-from-a-url/1 url :no-select-result t))))
     (new-buffer-from-string content nil 'text-mode))))

(defun pen-browse-url-for-passage (url)
  "Search the web, given a selection"
  (interactive (list (pf-get-urls-for-a-passage/1)))
  (pen-lg-display-page url)

  (comment
   (let* ((sites
           (s-join "\n\nNext result:\n\n" (pf-imagine-a-website-from-a-url/1 url :no-select-result t))))
     (new-buffer-from-string (ink-propertise sites) nil 'text-mode)
     (comment (cl-loop for pg in sites do (new-buffer-from-string pg nil 'text-mode)))
     (comment
      (if (url-is-404 url)
          (cl-loop for pg in
                   (pf-imagine-a-website-from-a-url/1 url :no-select-result t)
                   do (pen-etv (ink-propertise pg)))
        (eww url))))))
(defalias 'lg-search 'pen-browse-url-for-passage)

(provide 'pen-looking-glass)
