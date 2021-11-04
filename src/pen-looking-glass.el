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
  ;; (etv (lg-generate-alttext "https://en.wikipedia.org/static/images/project-logos/enwiki.png"))
  (etv (lg-generate-alttext "https://mullikine.github.io/tagpics/Bodacious%20Blog.gif")))

(defun lg-get-alttext (fp-or-url)
  (let ((desc (sor (car (pen-one (pf-given-an-image-describe-it/1 fp-or-url)))
                   "?")))
    ;; (message desc)
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
          (eval `(pen-ci (lg-get-alttext ,fp-or-url))))
         (alephalpha (eval-string alephalpha))

         (alephalpha
          (if (string-equal "*" alephalpha)
              (setq alephalpha "?")
            alephalpha))

         (description
          (cond
           ((sor alt) (concat alt ":" alephalpha))
           ;; ((re-match-p "SVG" alt) (eval-string (eval `(pen-ci (lg-get-alttext ,fp-or-url)))))
           (t alephalpha))))

    ;; (setq description (concat "'" description "'"))

    (if (interactive-p)
        (etv description)
      (ink-propertise description))))

(defun file-from-data (data)
  (let* ((hash (sha1 data))
         (fp (f-join "/tmp" hash)))
    (shut-up (write-to-file data fp))
    fp))

(defun shr-put-image (spec alt &optional flags)
  "Insert image SPEC with a string ALT.  Return image.
SPEC is either an image data blob, or a list where the first
element is the data blob and the second element is the content-type."
  (if (display-graphic-p)
      (let* ((size (cdr (assq 'size flags)))
             (data (if (consp spec)
                       (car spec)
                     spec))
             (content-type (and (consp spec)
                                (cadr spec)))
             (start (point))
             (image (cond
                     ((eq size 'original)
                      (create-image data nil t :ascent 100
                                    :format content-type))
                     ((eq content-type 'image/svg+xml)
                      (create-image data 'svg t :ascent 100))
                     ((eq size 'full)
                      (ignore-errors
                        (shr-rescale-image data content-type
                                           (plist-get flags :width)
                                           (plist-get flags :height))))
                     (t
                      (ignore-errors
                        (shr-rescale-image data content-type
                                           (plist-get flags :width)
                                           (plist-get flags :height)))))))
        (when image
          ;; When inserting big-ish pictures, put them at the
          ;; beginning of the line.
          (when (and (> (current-column) 0)
                     (> (car (image-size image t)) 400))
            (insert "\n"))
          (if (eq size 'original)
              (insert-sliced-image image (lg-generate-alttext
                                          (file-from-data data)
                                          alt)
                                   nil 20 1)
            (insert-image image (lg-generate-alttext
                                 (file-from-data data)
                                 alt)))
          (put-text-property start (point) 'image-size size)
          (when (and shr-image-animate
                     (cond ((fboundp 'image-multi-frame-p)
                            ;; Only animate multi-frame things that specify a
                            ;; delay; eg animated gifs as opposed to
                            ;; multi-page tiffs.  FIXME?
                            (cdr (image-multi-frame-p image)))
                           ((fboundp 'image-animated-p)
                            (image-animated-p image))))
            (image-animate image nil 60)))
        image)
    (let ((data (if (consp spec)
                    (car spec)
                  spec)))
      (insert (lg-generate-alttext
               (file-from-data data)
               alt)))))

;; Added "SVG Image"
(defun shr-tag-img (dom &optional url)
  (when (or url
            (and dom
                 (or (> (length (dom-attr dom 'src)) 0)
                     (> (length (dom-attr dom 'srcset)) 0))))
    (when (> (current-column) 0)
      (insert "\n"))
    (let ((alt (dom-attr dom 'alt))
          (width (shr-string-number (dom-attr dom 'width)))
          (height (shr-string-number (dom-attr dom 'height)))
          (url (shr-expand-url (or url (shr--preferred-image dom)))))
      (let ((start (point-marker)))
        (when (zerop (length alt))
          (setq alt "*"))
        (cond
         ((null url)
          ;; After further expansion, there turned out to be no valid
          ;; src in the img after all.
          )
         ((or (member (dom-attr dom 'height) '("0" "1"))
              (member (dom-attr dom 'width) '("0" "1")))
          ;; Ignore zero-sized or single-pixel images.
          )
         ((and (not shr-inhibit-images)
               (string-match "\\`data:" url))
          (let ((image (shr-image-from-data (substring url (match-end 0)))))
            (if image
                (funcall shr-put-image-function image alt
                         (list :width width :height height))
              (insert alt))))
         ((and (not shr-inhibit-images)
               (string-match "\\`cid:" url))
          (let ((url (substring url (match-end 0)))
                image)
            (if (or (not shr-content-function)
                    (not (setq image (funcall shr-content-function url))))
                (insert alt)
              (funcall shr-put-image-function image alt
                       (list :width width :height height)))))
         ((or shr-inhibit-images
              (and shr-blocked-images
                   (string-match shr-blocked-images url)))
          (setq shr-start (point))
          (shr-insert alt))
         ((and (not shr-ignore-cache)
               (url-is-cached (shr-encode-url url)))
          (funcall shr-put-image-function (shr-get-image-data url) alt
                   (list :width width :height height)))
         (t
          (when (and shr-ignore-cache
                     (url-is-cached (shr-encode-url url)))
            (let ((file (url-cache-create-filename (shr-encode-url url))))
              (when (file-exists-p file)
                (delete-file file))))
          (when (image-type-available-p 'svg)
            (let ((fullalttext
                   ;; (lg-generate-alttext (file-from-data (ecurl url)))
                   (lg-generate-alttext url alt)))
              (insert-image
               (shr-make-placeholder-image dom)
               (or fullalttext ""))))
          (insert " ")
          (url-queue-retrieve
           (shr-encode-url url) #'shr-image-fetched
           (list (current-buffer) start (set-marker (make-marker) (point))
                 (list :width width :height height))
           t
           (not (shr--use-cookies-p url shr-base)))))
        (when (zerop shr-table-depth) ;; We are not in a table.
          (put-text-property start (point) 'keymap shr-image-map)
          (put-text-property start (point) 'shr-alt alt)
          (put-text-property start (point) 'image-url url)
          (put-text-property start (point) 'image-displayer
                             (shr-image-displayer shr-content-function))
          (put-text-property start (point) 'help-echo
                             (shr-fill-text
                              (or (dom-attr dom 'title) alt))))))))

(defun shr-browse-image (&optional copy-url)
  "Browse the image under point.
If COPY-URL (the prefix if called interactively) is non-nil, copy
the URL of the image to the kill buffer instead."
  (interactive "P")
  (let ((url (get-text-property (point) 'image-url)))
    (cond
     ((not url)
      (message "No image under point"))
     (copy-url
      (with-temp-buffer
        (insert url)
        (copy-region-as-kill (point-min) (point-max))
        (message "Copied %s" url)))
     (t
      (message "Browsing %s..." url)
      ;; (pen-snc (cmd "sps" "win" "ie" url))
      ;; (sps (cmd "unbuffer" "timg" url))
      ;; (sps (concat (cmd "timg" url) " | less -rS") "-s")
      ;; (pen-snc (cmd "sps" "-E" (concat (cmd "timg" url) " | less -rS")))
      ;; (pen-snc (cmd "sps" "-E" (concat (cmd "timg" url) " && pak")))
      (pen-snc (cmd "sps" "-E" (concat (cmd "timg" url))))
      ;; (my/eww-browse-url url)
      ;; (my/eww-browse-url-chrome url)
      ))))

(provide 'pen-looking-glass)