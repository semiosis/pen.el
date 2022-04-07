(require 'selected)
(require 'guess-language)

(guess-language-mode 1)

(defun monotonically-increasing-tuple-permutations (input)
  (s-lines (pen-snc "monotonically-increasing-tuple-permutations.py" input)))

(defun dictionaryapi-define (word)
  (interactive (list (rshi "dictionaryapi-define: " (pen-thing-at-point))))
  (let ((d (sor (chomp (pen-snc (pen-cmd "dictionaryapi-define" word))))))
    (if (interactive-p)
        (etv d)
      d)))

(defun google-define (word)
  (interactive (list (rshi "google-define: " (pen-thing-at-point))))
  (let ((d (sor (chomp (pen-snc (pen-cmd "google-define" word))))))
    (if (interactive-p)
        (etv d)
      d)))

(defun pen-wiki-summary (term)
  (interactive (list (rshi "wiki-summary: " (pen-thing-at-point))))
  (let ((s (snc (concat "wiki-summary " term))))
    (if (interactive-p)
        (etv s)
      s)))

(defun ngram-suggest (query)
  (interactive (list (read-string-hist "ngram-suggest query: ")))

  (if (string-match "^[^*]+$" query)
      (setq query (concat query " *")))

  (let ((res (s-lines (pen-snc "ngram-complete" query))))
    (if (interactive-p)
        (xc (fz res
                nil nil "ngram-suggest copy: "))
      res)))

(defun gen-google-ngram-queries (s i)
  (-filter-not-empty-string
   (str2list
    (snc (concat "echo " (pen-q s) " | google-ngram-query-combinations " (str i))))))

(defun ngram-query-replace-this ()
  (interactive)
  (if (not (selectedp))
      (let* ((get-current-line-string-str (chomp (get-current-line-string)))
             (col (+ 1 (current-column)))
             (suggestions (ngram-suggest (fz (gen-google-ngram-queries line-str col)
                                             nil nil "ngram-query-replace-this query: "))))
        (if (-filter-not-empty-string suggestions)
            (let ((replacement (fz suggestions
                                   nil nil "ngram-query-replace-this replacement: ")))
              (if (sor replacement)
                  (nbfs replacement)))))))

(defun ngram-query-replace ()
  (interactive)
  (if (selectedp)
      (let* ((query (if (selectedp)
                        (pen-selected-text)))
             (reformulated-query (if (string-match-p "\\*" query)
                                     query
                                   (let ((wildcard-word (fz (split-string query " " t)
                                                            nil nil "ngram-query-replace wildcard-word: ")))
                                     (if wildcard-word
                                         (s-replace-regexp (eatify wildcard-word) "*" query)
                                       query))))
             (suggestions (ngram-suggest reformulated-query)))
        (if (-filter-not-empty-string suggestions)
            (let ((replacement (fz suggestions
                                   nil nil "ngram-query-replace suggestions: ")))
              (if replacement
                  (progn
                    (cua-delete-region)
                    (insert replacement))))))
    (ngram-query-replace-this)))

(defun tuple-swap (tp)
  (list (car (cdr tp)) (car tp)))

(defmacro etv-filter (cmd)
  (let* ((slug (slugify cmd))
         (sym (intern (concat "etv-" slug))))
    `(defun ,sym (&optional input)
       (interactive (list (pen-selected-text)))
       (if (not input)
           (setq input (pen-selected-text)))
       (let ((tf (pen-snc "pen-tf txt" input)))
         (pen-sps (concat "cat " (pen-q tf) " | " ,cmd " | vs"))))))

(cl-loop for s in
         '("partsofspeech"
           "entities"
           "deplacy"
           "displacy"
           "summarize"
           "spacyparsetree"
           "token-pos-dep"
           "sentiment"
           "segment-sentences"
           "noun-chunks")
         do
         (eval
          (macroexpand
           `(etv-filter ,s))))

(defun sps-play-spacy (&optional input)
  (interactive)
  (if (not input)
      (setq input (pen-selected-text)))
  (pen-sn "play-spacy" input))

(defun get-topic (&optional semantic)
  (interactive)
  (let ((topic))
    (if (interactive-p)
        (etv topic))))

(defun find-anagrams (word)
  (interactive (list
                (if (selectedp)
                    (pen-selected-text)
                    (read-string-hist "find-anagrams: "
                                      (pen-thing-at-point)))))
  (xc (fz (pen-snc (pen-cmd "find-anagrams" word))
          nil
          nil
          "find-anagrams copy: "
          nil
          t)))

(defun openai-correct-word (&optional word)
  (interactive (list
                (car (flyspell-get-word))))

  (flyspell-auto-correct-word (chomp (pen-single-batch (pf-correct-word/1 word)))))

(defun pen-auto-correct-word ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'openai-correct-word)
    (call-interactively 'flyspell-auto-correct-word)))

(define-key selected-keymap (kbd "Z n") 'ngram-query-replace)
(define-key selected-keymap (kbd "Z S") 'sps-play-spacy)
(define-key selected-keymap (kbd "Z M") 'etv-summarize)
(define-key selected-keymap (kbd "Z P") 'etv-partsofspeech)
(define-key selected-keymap (kbd "Z R") 'etv-spacyparsetree)
(define-key selected-keymap (kbd "Z E") 'etv-entities)
(define-key selected-keymap (kbd "Z L") 'etv-deplacy)
(define-key selected-keymap (kbd "Z D") 'etv-displacy)
(define-key selected-keymap (kbd "Z T") 'etv-token-pos-dep)
(define-key selected-keymap (kbd "Z N") 'etv-sentiment)
(define-key selected-keymap (kbd "Z G") 'etv-segment-sentences)
(define-key selected-keymap (kbd "Z O") 'etv-noun-chunks)
(define-key selected-keymap (kbd "Z d g") 'google-define)
(define-key global-map (kbd "H-S") 'sps-play-spacy)

(provide 'pen-nlp)