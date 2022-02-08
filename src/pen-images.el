(defun feh (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-sn (pen-cmd "feh" path) nil nil nil t))

(defun pen-win-ie (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-sps (pen-cmd "pen-win" "ie" path)))

(defun pen-show-image (path)
  (interactive (list (read-file-name "Image file path: ")))
  (feh path))

(provide 'pen-images)