(defun feh (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-sn (pen-cmd "feh" path) nil nil nil t))

(defun pen-win-ie (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-sps (pen-cmd "pen-win" "ie" path)))

(defun pen-show-image (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-win-ie path))

(defun pen-visualise-text (text)
  (interactive (list (pen-selected-text)))
  (let ((path (pf-given-a-textual-description-visualise-it-with-an-image/1 text)))
    (pen-show-image path)))

(provide 'pen-images)