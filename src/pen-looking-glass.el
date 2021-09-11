;; 🔍 Looking-glass
;; “Where should I go?" -Alice. "That depends on where you want to end up." - The Cheshire Cat.”

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
     (pen-one (pf-generate-html-from-ascii-browser/2 url ascii))
     nil 'text-mode)))

(provide 'pen-looking-glass)