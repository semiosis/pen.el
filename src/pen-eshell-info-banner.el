(require 'eshell-info-banner)

(setq eshell-info-banner-progress-bar-chars "܀")
(setq eshell-info-banner-progress-bar-char "܀")
;; (setq eshell-info-banner-progress-bar-char "⅏")
(setq eshell-info-banner-progress-bar-char "=")
;; Why could I not find this in mx:dff-call-interactively-symbol-select- ?
(setq eshell-info-banner-progress-bar-char "┅")
(setq eshell-info-banner-progress-bar-char "━")
(setq eshell-info-banner-progress-bar-char "█")
(setq eshell-info-banner-progress-bar-char "▆")
;; Sadly, this breaks the terminal when I move cursor across it. But it still looks nicest by far
(setq eshell-info-banner-progress-bar-char "🮅")

(defun eshell-info-banner--memory-to-string (type total used text-padding bar-length)
  "Display a memory’s usage with a progress bar.

The TYPE of memory will be the text on the far left, while USED
and TOTAL will be displayed on the right of the progress bar.
From them, a percentage will be computed which will be used to
display a colored percentage of the progress bar and it will be
displayed on the far right.

TEXT-PADDING will determine how many dots are necessary between
TYPE and the colon.

BAR-LENGTH determines the length of the progress bar to be
displayed."
  (concat (s-pad-right text-padding " " type)
          ": "
          (eshell-info-banner--progress-bar-without-prefix bar-length used total t)))

(defun eshell-info-banner--display-battery (text-padding bar-length)
  "If the computer has a battery, display its level.

Pad the left text with dots by TEXT-PADDING characters.

BAR-LENGTH indicates the length in characters of the progress
bar.

The usage of `eshell-info-banner-warning-percentage' and
`eshell-info-banner-critical-percentage' is reversed, and can be
thought of as the “percentage of discharge” of the computer.
Thus, setting the warning at 75% will be translated as showing
the warning face with a battery level of 25% or less."
  (let ((battery-level (unless (and (equal system-type 'gnu/linux)
                                    (not (file-readable-p "/sys/")))
                         (battery))))
    (if (or (null battery-level)
            (string= battery-level "Battery status not available")
            (string-match-p (regexp-quote "N/A") battery-level))
        ""
      (let ((percentage (save-match-data
                          (string-match "\\([0-9]+\\)\\(\\.[0-9]\\)?%" battery-level)
                          (string-to-number (substring battery-level
                                                       (match-beginning 1)
                                                       (match-end 1))))))
        (concat (s-pad-right text-padding " " "Battery")
                ": "
                (eshell-info-banner--progress-bar bar-length
                                                  percentage
                                                  t)
                (eshell-info-banner--string-repeat
                 " "
                 (if (equal eshell-info-banner-file-size-flavor 'iec) 21 17))
                (format "(%3s%%)\n"
                        (eshell-info-banner--with-face
                         (number-to-string percentage)
                         :inherit (eshell-info-banner--get-color-percentage (- 100.0 percentage)))))))))

(defun eshell-info-banner--partition-to-string (partition text-padding bar-length)
  "Display a progress bar showing how full a PARTITION is.

For TEXT-PADDING and BAR-LENGTH, see the documentation of
`eshell-info-banner--display-memory'."
  (concat (s-pad-right text-padding
                       " "
                       (eshell-info-banner--with-face
                        (eshell-info-banner--mounted-partitions-path partition)
                        :weight 'bold))
          ": "
          (eshell-info-banner--progress-bar-without-prefix
           bar-length
           (eshell-info-banner--mounted-partitions-used partition)
           (eshell-info-banner--mounted-partitions-size partition))))

(defun eshell-info-banner ()
  "Banner for Eshell displaying system information."
  (let* ((default-directory (if eshell-info-banner-tramp-aware default-directory "~"))
         (system-info       (eshell-info-banner--get-os-information))
         (os                (car system-info))
         (kernel            (cdr system-info))
         (hostname          (if  eshell-info-banner-tramp-aware
                                (or (file-remote-p default-directory 'host) (system-name))
                              (system-name)))
         (uptime             (eshell-info-banner--get-uptime))
         (partitions         (eshell-info-banner--get-mounted-partitions))
         (left-padding       (eshell-info-banner--get-longest-path partitions))
         (left-text          (max (length os)
                                  (length hostname)))
         (left-length        (+ left-padding 2 left-text)) ; + ": "
         (right-text         (+ (length "Kernel: ")
                                (max (length uptime)
                                     (length kernel))))
         (tot-width          (max (+ left-length right-text 3)
                                  eshell-info-banner-width))
         (middle-padding     (- tot-width right-text left-padding 4))

         (bar-length         (- tot-width left-padding 4 23))
         (bar-length         (if (equal eshell-info-banner-file-size-flavor 'iec)
                                 (- bar-length 4)
                               bar-length)))
    (concat ;; (format "%s\n" (eshell-info-banner--string-repeat eshell-info-banner-progress-bar-char
            ;;                                                   tot-width))
            (format "%s: %s Kernel.: %s\n"
                    (s-pad-right left-padding
                                 " "
                                 "OS")
                    (s-pad-right middle-padding " " (eshell-info-banner--with-face os :weight 'bold))
                    kernel)
            (format "%s: %s Uptime.: %s\n"
                    (s-pad-right left-padding " " "Hostname")
                    (s-pad-right middle-padding " " (eshell-info-banner--with-face hostname :weight 'bold))
                    uptime)
            (eshell-info-banner--display-battery left-padding bar-length)
            (eshell-info-banner--display-memory left-padding bar-length)
            (eshell-info-banner--display-partitions left-padding bar-length)
            ;; (format "\n%s\n" (eshell-info-banner--string-repeat eshell-info-banner-progress-bar-char
            ;;                                                     tot-width))
            )))

(defun eshell-info-banner--progress-bar (length percentage &optional invert)
  "Display a progress bar LENGTH long and PERCENTAGE full.
The full path will be displayed filled with the character
specified by `eshell-info-banner-progress-bar-char' up to
PERCENTAGE percents.  The rest will be empty.

If INVERT is t, then consider the percentage to approach
critical levels close to 0 rather than 100."
  (let* ((length-filled     (if (= 0 percentage)
                                0
                              (/ (* length percentage) 100)))
         (length-empty      (- length length-filled))
         (percentage-level (if invert
                               (- 100 percentage)
                             percentage)))
    (concat
     ;; (eshell-info-banner--with-face "[" :weight 'bold)
     (eshell-info-banner--with-face (eshell-info-banner--string-repeat eshell-info-banner-progress-bar-char
                                                                       length-filled)
                                    :weight 'bold
                                    :inherit (eshell-info-banner--get-color-percentage percentage-level))
     (eshell-info-banner--with-face (eshell-info-banner--string-repeat eshell-info-banner-progress-bar-char
                                                                       length-empty)
                                    :weight 'bold
                                    :inherit 'eshell-info-banner-background-face)
     ;; (eshell-info-banner--with-face "]" :weight 'bold)
     )))

(provide 'pen-eshell-info-banner)
