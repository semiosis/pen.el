(defun search-bible-verse (query)
  (interactive (list (read-string-hist "Bible sem-search: ")))

  (let* ((result (fz (pen-sn (cmd
                              ;; "upd"
                              "oci" "semantic-bible-search" query))
                     nil nil "Bible: search result: "))
         (text (pen-sn "jq -r .text" result))
         (text (pen-sn "pen-str join ' '" text))
         (book (pen-sn "jq -r .book" result))
         (chapter (pen-sn "jq -r .chapter" result))
         (url (pen-sn "jq -r .url" result)))

    (xc (concat "+ [[" (chomp url) "][" (concat (chomp book) " " (chomp chapter)) "]] :: " text))))

(provide 'pen-bible-search)
