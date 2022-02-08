(defun feh (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-sn (cmd "pen-win" "ie" path) nil nil nil t))

(defun pen-win-ie (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-sps (cmd "pen-win" "ie" path)))

(defun pen-show-image (path)
  (interactive (list (read-file-name "Image file path: ")))
  (feh path))

(provide 'pen-images)