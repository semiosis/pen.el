(require 'which-key)

(setq which-key-sort-order 'which-key-key-order)
;; same as default, except single characters are sorted alphabetically
;; (setq which-key-sort-order 'which-key-key-order-alpha)
;; same as default, except all prefix keys are grouped together at the end
;; (setq which-key-sort-order 'which-key-prefix-then-key-order)
;; same as default, except all keys from local maps shown first
;; (setq which-key-sort-order 'which-key-local-then-key-order)
;; sort based on the key description ignoring case
;; (setq which-key-sort-order 'which-key-description-order)

;; Set the time delay (in seconds) for the which-key popup to appear. A value of
;; zero might cause issues so a non-zero value is recommended.
;;(setq which-key-idle-delay 0.5)
;; (setq which-key-idle-delay 0.2)
(setq which-key-idle-delay 1)

;; Set the maximum length (in characters) for key descriptions (commands or
;; prefixes). Descriptions that are longer are truncated and have ".." added.
(setq which-key-max-description-length 27)

;; Use additonal padding between columns of keys. This variable specifies the
;; number of spaces to add to the left of each column.
(setq which-key-add-column-padding 0)

;; The maximum number of columns to display in the which-key buffer. nil means
;; don't impose a maximum.
(setq which-key-max-display-columns nil)

;; Set the separator used between keys and descriptions. Change this setting to
;; an ASCII character if your font does not show the default arrow. The second
;; setting here allows for extra padding for Unicode characters. which-key uses
;; characters as a means of width measurement, so wide Unicode characters can
;; throw off the calculation.
(setq which-key-separator " → " )
(setq which-key-unicode-correction 3)

;; Set the prefix string that will be inserted in front of prefix commands
;; (i.e., commands that represent a sub-map).
(setq which-key-prefix-prefix "+" )

;; Set the special keys. These are automatically truncated to one character and
;; have which-key-special-key-face applied. Disabled by default. An example
;; setting is
;; (setq which-key-special-keys '("SPC" "TAB" "RET" "ESC" "DEL"))
(setq which-key-special-keys nil)

;; Show the key prefix on the left, top, or bottom (nil means hide the prefix).
;; The prefix consists of the keys you have typed so far. which-key also shows
;; the page information along with the prefix.
(setq which-key-show-prefix 'left)

;; Set to t to show the count of keys shown vs. total keys in the mode line.
;; (setq which-key-show-remaining-keys nil)
(setq which-key-show-remaining-keys t)


(ignore-errors (which-key-mode t))


(setq which-key-use-C-h-commands t)
;; (setq which-key-use-C-h-commands nil) ; disable
(setq which-key-paging-prefixes '("C-h"))

(defun which-key-describe-prefix-bindings (args)
  "docstring"
  (interactive "P")
  (let ((bindings (which-key--current-prefix)))
    (let ((which-key-inhibit t))
      (which-key--hide-popup-ignore-command))
    (describe-bindings bindings)))

(define-key which-key-C-h-map (kbd "k") 'which-key-describe-prefix-bindings)

(provide 'pen-which-key)