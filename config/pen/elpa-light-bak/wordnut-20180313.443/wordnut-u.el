;; -*- lexical-binding: t -*-

;; s.el
(defun wordnut-u-word-wrap (len s)
  "If S is longer than LEN, wrap the words with newlines."
  (with-temp-buffer
    (insert s)
    (let ((fill-column len))
      (fill-region (point-min) (point-max)))
    (buffer-substring-no-properties (point-min) (point-max))))

;; emacswiki.org
(defun wordnut-u-filter (condp lst)
  (delq nil
	(mapcar (lambda (x) (and (funcall condp x) x)) lst)))

(defun wordnut-u-fix-name (str)
  (let ((max 10))
    (if (> (length str) max)
	(concat (substring str 0 max) "...")
      str)
    ))

(defun wordnut-u-line-cur()
  (substring-no-properties (or (thing-at-point 'line) "")) )



(provide 'wordnut-u)
