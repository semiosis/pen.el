;; 🔍 Looking-glass
;; “Where should I go?" -Alice. "That depends on where you want to end up." - The Cheshire Cat.” 🐈

;; Looking-glass web-browser (based on eww)

;; If a url is 404, then use the imaginary web-browser.
;; If a url is real then go to that.

;; When running an imaginary web search, optionally say which ones are real

(require 'eww)

(require 'eww)
(require 'cl-lib)
;; (require 'eww-lnum)
(require 'pen-asciinema)

(defun pen-uniqify-buffer (b)
  "Give the buffer a unique name"
  (with-current-buffer b
    (ignore-errors (let* ((hash (short-hash (str (time-to-seconds))))
                          (new-buffer-name (pcre-replace-string "(\\*?)$" (concat "-" hash "\\1") (current-buffer-name))))
                     (rename-buffer new-buffer-name)))
    b))

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

  (let* ((alephalpha
          (if pen-describe-images
              (eval `(pen-ci (lg-get-alttext ,fp-or-url) ,(or (>= (prefix-numeric-value current-prefix-arg) 4)
                                                              (= (prefix-numeric-value current-prefix-arg) 0))))
            ;; (lg-get-alttext fp-or-url)
            nil))

         (alephalpha
          (or (eval-string alephalpha)
              ""))

         (alephalpha
          (if (string-equal "*" alephalpha)
              (setq alephalpha "?")
            alephalpha))

         (description
          (cond
           ((sor alt) (concat alt ":" alephalpha))
           ;; ((re-match-p "SVG" alt) (eval-string (eval `(pen-ci (lg-get-alttext ,fp-or-url)))))
           (t alephalpha)))

         ;; (description (concat fp-or-url (q description) alt))
         )

    ;; (setq description (concat "'" description "'"))

    (if (interactive-p)
        (pen-etv description)
      (ink-propertise description))))

(provide 'pen-looking-glass)