(require 'eww)

(defun file-from-data (data)
  (let* ((hash (sha1 data))
         (fp (f-join "/tmp" hash)))
    (shut-up (write-to-file data fp))
    fp))

(defun shr-put-image (spec alt &optional flags)
  "Insert image SPEC with a string ALT.  Return image.
SPEC is either an image data blob, or a list where the first
element is the data blob and the second element is the content-type."

  ;; This runs at initial load and also after, when images later load
  (if (display-graphic-p)
      (let* ((size (cdr (assq 'size flags)))
             (data (if (consp spec)
                       (car spec)
                     spec))
             (content-type (and (consp spec) (cadr spec)))
             (start (point))
             (image (cond ((eq size 'original)
                           (create-image
                            data
                            nil
                            t
                            :ascent 100
                            :format content-type))
                          ((eq content-type
                               'image/svg+xml)
                           (create-image
                            data
                            'svg
                            t
                            :ascent 100))
                          ((eq size 'full)
                           (ignore-errors
                             (shr-rescale-image
                              data
                              content-type
                              (plist-get flags :width)
                              (plist-get flags :height))))
                          (t
                           (ignore-errors
                             (shr-rescale-image
                              data
                              content-type
                              (plist-get flags :width)
                              (plist-get flags :height)))))))
        (when image
          ;; When inserting big-ish pictures, put them at the
          ;; beginning of the line.
          (when (and (> (current-column) 0)
                     (> (car (image-size image t))
                        400))
            (insert "\n"))
          (if (eq size 'original)
              (insert-sliced-image
               image
               (or (lg-generate-alttext
                    (file-from-data data))
                   alt
                   "*")
               nil
               20
               1)
            (insert-image
             image
             (or (lg-generate-alttext
                  (file-from-data data))
                 alt
                 "*")))
          (put-text-property
           start
           (point)
           'image-size
           size)
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

    ;; This  gets called most often
    ;; And is also where it gets called after load
    (let ((data (if (consp spec)
                    (car spec)
                  spec)))
      (insert
       (or
        (lg-generate-alttext
         (file-from-data data))
        alt
        ;; ""
        )))))

;; Added "SVG Image"
(defun shr-tag-img (dom &optional url)
  ;; This runs on initial load
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
                (funcall shr-put-image-function image (sor alt)
                         (list :width width :height height))
              (insert alt))))
         ((and (not shr-inhibit-images)
               (string-match "\\`cid:" url))
          (let ((url (substring url (match-end 0)))
                image)
            (if (or (not shr-content-function)
                    (not (setq image (funcall shr-content-function url))))
                (insert alt)
              (funcall shr-put-image-function image (sor alt)
                       (list :width width :height height)))))
         ((or shr-inhibit-images
              (and shr-blocked-images
                   (string-match shr-blocked-images url)))
          (setq shr-start (point))
          (shr-insert alt))
         ((and (not shr-ignore-cache)
               (url-is-cached (shr-encode-url url)))
          (funcall shr-put-image-function (shr-get-image-data url) (sor alt)
                   (list :width width :height height)))
         (t
          (when (and shr-ignore-cache
                     (url-is-cached (shr-encode-url url)))
            (let ((file (url-cache-create-filename (shr-encode-url url))))
              (when (file-exists-p file)
                (delete-file file))))
          (let ((fullalttext
                 ;; (lg-generate-alttext (file-from-data (ecurl url)))

                 ;; This happens at load for the blog logo
                 (lg-generate-alttext url (sor alt))))
            (comment (insert fullalttext))
            (insert-image
             ;; A placeholder image gets reloaded
             ;; How to keep the alttext, if it's a placeholder image?
             (shr-make-placeholder-image dom)
             (or fullalttext "")))
          (insert " ")
          ;; This reloaded the image, but there is no need
          ;; Because alttext was used
          ;; Though, perhaps I should use something immediate first 
          (comment
           (url-queue-retrieve
            (shr-encode-url url) #'shr-image-fetched
            (list (current-buffer) start (set-marker (make-marker) (point))
                  (list :width width :height height))
            t
            (not (shr--use-cookies-p url shr-base))))))
        (when (zerop shr-table-depth) ;; We are not in a table.
          (put-text-property start (point) 'keymap shr-image-map)
          (put-text-property start (point) 'shr-alt alt)
          (put-text-property start (point) 'image-url url)
          (put-text-property start (point) 'image-displayer
                             (shr-image-displayer shr-content-function))
          (put-text-property start (point) 'help-echo
                             (shr-fill-text
                              (or (dom-attr dom 'title) alt))))))))

(defun shr-browse-image (&optional arg)
  "Browse the image under point.
If COPY-URL (the prefix if called interactively) is non-nil, copy
the URL of the image to the kill buffer instead."
  (interactive "P")
  (let ((url (get-text-property (point) 'image-url)))
    (cond
     ((not url)
      (message "No image under point"))
     ((>= (prefix-numeric-value current-prefix-arg) 8)
      (with-temp-buffer
        (insert url)
        (copy-region-as-kill (point-min) (point-max))
        (message "Copied %s" url)))
     ((>= (prefix-numeric-value current-prefix-arg) 4)
      (message "Browsing %s..." url)
      (my/eww-browse-url url))
     (t
      (message "Browsing %s..." url)
      (pen-snc (cmd "sps" "win" "ie" url))
      ;; (sps (cmd "unbuffer" "timg" url))
      ;; (sps (concat (cmd "timg" url) " | less -rS") "-s")
      ;; (pen-snc (cmd "sps" "-E" (concat (cmd "timg" url) " | less -rS")))
      ;; (pen-snc (cmd "sps" "-E" (concat (cmd "timg" url) " && pak")))
      ;; (pen-snc (cmd "sps" "-E" (concat (cmd "timg" url))))
      ;; (my/eww-browse-url url)
      ;; (my/eww-browse-url-chrome url)
      ))))

(defun eww-next-image ()
  (interactive)
  (goto-char (next-single-char-property-change (point) 'image-url))
  (if (not (get-text-property (point) 'image-url))
      (goto-char (next-single-char-property-change (point) 'image-url))))

(defun eww-previous-image ()
  (interactive)
  (goto-char (previous-single-char-property-change (point) 'image-url))
  (if (not (get-text-property (point) 'image-url))
      (goto-char (previous-single-char-property-change (point) 'image-url))))

(define-key eww-mode-map (kbd "]") 'eww-next-image)
(define-key eww-mode-map (kbd "[") 'eww-previous-image)

(provide 'pen-eww)