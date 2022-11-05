(defun feh (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-sn (pen-cmd "feh" path) nil nil nil t))

(defun pen-win-ie (path)
  (interactive (list (read-file-name "Image file path: ")))
  (pen-sps (pen-cmd "pen-win" "ie" path) nil nil default-directory))

(defun test-pen-win-ie ()
  (interactive)
  (let ((default-directory "/root/.pen/results/results_1667625716.9521382_05.11.22_91155942-917e-48d9-baad-bec94794036c")
        (current-prefix-arg '(4)))
    (pen-win-ie "results_05.11.22__1667625720_91155942-917e-48d9-baad-bec94794036c_TeaH2/images/result-a-phantasmagoria-of-semiotic-art-depicting-a-surreal-and-surreptitious-strawberry-.png")))

(defun pen-show-image (path)
  (interactive (list (read-file-name "Image file path: ")))

  (if (pen-var-value-maybe 'gen-dir)
      (let ((default-directory gen-dir))
        (pen-win-ie path))
    (pen-win-ie path)))

(defun pen-visualise-text (text)
  (interactive (list (pen-selected-text)))
  (let ((path (car (pen-one (pf-given-a-textual-description-visualise-it-with-an-image/1 text :no-select-result t)))))
    (pen-show-image path)))

(provide 'pen-images)
