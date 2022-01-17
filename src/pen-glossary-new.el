(require 'my-regex)
(require 'my-lists)

(require 'my-glossary-error)

(require 'my-computed-context)

(defvar pen-glossary-keep-tuples-up-to-date t)

(defset pen-glossary-max-lines-for-entire-buffer-gen 1000)
(defset pen-glossary-overflow-chars 10000)
(defset pen-glossary-idle-time 0.2)

(defvar pen-glossary-files nil)

(defun pen-glossary-window-start ()
  (max 1 (- (window-start) pen-glossary-overflow-chars)))

(defun pen-glossary-window-end ()
  (min (point-max) (+ (window-end) pen-glossary-overflow-chars)))

(defun pen-go-glossary-predicate-tuples ()
  (interactive)
  (j 'pen-glossary-predicate-tuples))
(define-key global-map (kbd "H-Y P") 'pen-go-glossary-predicate-tuples)

(defset glossary-predicate-tuples
  (mu `(((or (pen-re-p "\\bVault\\b")
             (pen-re-p "\\bConsul\\b")
             (and (not (derived-mode-p 'text-mode))
                  (pen-istr-p "terraform"))
             (and (not (derived-mode-p 'text-mode))
                  (pen-ire-p "\\bvagrant\\b")))
         "$HOME/glossaries/hashicorp.txt"
         "$HOME/glossaries/terraform.txt")
        ((or (pen-istr-p "French")
             (pen-istr-p "france")
             (istr-match-p "French" (get-path nil t)))
         "$HOME/glossaries/french.txt"
         "$NOTES/ws/french/phrases.txt"
         "$NOTES/ws/french/glossary.txt")
        ((pen-istr-p "fasttext")
         "$HOME/glossaries/fasttext.txt")
        ((pen-istr-p "tensorflow")
         "$HOME/glossaries/tensorflow.txt")
        ((or (pen-istr-p "pytorch")
             (pen-istr-p "huggingface"))
         "$HOME/glossaries/pytorch.txt")
        ((or (pen-istr-p "kafka"))
         "$HOME/glossaries/kafka.txt")
        ((or (pen-istr-p "ocean"))
         "$HOME/glossaries/ocean.txt")
        ((or (pen-istr-p "semiotic")
             (pen-istr-p "semiosis"))
         "$HOME/glossaries/semiotics.txt")
        ((or (pen-str-p "consciousness")
             (pen-str-p "Schrodinger"))
         "$HOME/glossaries/consciousness.txt"
         "$HOME/glossaries/general-ai-agi.txt")
        ((or (pen-str-p "cryptocurrenc")
             (pen-str-p "blockchain")
             (pen-str-p "crypto")
             (pen-str-p "bitcoin")
             (pen-str-p "ethereum"))
         "$HOME/glossaries/cryptocurrencies.txt"
         "$HOME/glossaries/cryptography.txt")
        ((or (pen-istr-p "optic")
             (ieat-in-region-or-buffer-p "lens")
             (pen-istr-p "prism")
             (pen-istr-p "focal")
             (ieat-in-region-or-buffer-p "light"))
         "$HOME/glossaries/optics.txt"
         "$HOME/glossaries/physics.txt")
        ((or (pen-str-p "hashing")
             (ieat-in-region-or-buffer-or-path-p "hash"))
         "$HOME/glossaries/hashing.txt")
        ((or (pen-istr-p "graphql"))
         "$HOME/glossaries/graphql.txt")
        ((or (pen-str-p "Schrodinger"))
         "$HOME/glossaries/quantum-mechanics.txt")
        ((or (pen-istr-p "datomic"))
         "$HOME/glossaries/datomic.txt")
        ((or (pen-str-p "localhost"))
         "$HOME/glossaries/ip-networking.txt")
        ((or (pen-str-p "keras"))
         "$HOME/glossaries/keras.txt")
        ((or (pen-str-p "terraform")
             (pen-str-p "docker")
             (pen-ire-p "\\bIaC\\b"))
         "$HOME/glossaries/iac-infrastructure-as-code.txt")
        ((or (pen-ire-p "prolog"))
         "$HOME/glossaries/prolog.txt")
        ((or (pen-ire-p "\\bnix"))
         "$HOME/glossaries/nix.txt")
        ((or (derived-mode-p 'solidity-mode)
             (ieat-in-region-or-buffer-or-path-p "solidity")
             (ieat-in-region-or-buffer-or-path-p "ethereum"))
         "$HOME/glossaries/ethereum.txt"
         "$HOME/glossaries/solidity.txt")
        ((or
          (derived-mode-p 'emacs-lisp-mode)
          (derived-mode-p 'Info-mode))
         "$HOME/glossaries/emacs-lisp-elisp.txt")
        ((bound-and-true-p my/lisp-mode)
         "$HOME/glossaries/lisp-based-languages.txt")
        ((or (pen-ire-p "kubernetes")
             (pen-ire-p "k8s"))
         "$HOME/glossaries/kubernetes.txt")
        ((or (pen-istr-p "lotr")
             (pen-istr-p "lord of the rings"))
         "$HOME/glossaries/lotr-lord-of-the-rings.txt")
        ((pen-ire-p "docker")
         "$HOME/glossaries/docker.txt")
        ((pen-ire-p "/elisp/")
         "$HOME/glossaries/emacs-lisp-elisp.txt")
        ((pen-istr-p "clojure")
         "$HOME/glossaries/clojure.txt"
         "$HOME/glossaries/programming-language-theory.txt")
        ((and (pen-ire-p "haskell")
              (not (derived-mode-p 'emacs-lisp-mode)))
         "$HOME/glossaries/haskell.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "AWS")
             (ieat-in-region-or-buffer-or-path-p "awscloud")
             (ieat-in-region-or-buffer-or-path-p "amazon"))
         "$HOME/glossaries/aws.txt"
         "$HOME/glossaries/awscloud.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "RL")
             (ieat-in-region-or-buffer-or-path-p "reinforcement"))
         "$HOME/glossaries/reinforcement-learning.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "ethereum")
             (ieat-in-region-or-buffer-or-path-p "eth"))
         "$HOME/glossaries/ethereum.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "transformer"))
         "$HOME/glossaries/transformer.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "gpt")
             (ieat-in-region-or-buffer-or-path-p "openai")
             (ieat-in-region-or-buffer-or-path-p "huggingface"))
         "$HOME/glossaries/openai.txt"
         "$HOME/glossaries/huggingface.txt"
         "$HOME/glossaries/transformer.txt"
         "$HOME/glossaries/gpt.txt")
        ((pen-ire-p "\\bANSIBLE\\b")
         "$HOME/glossaries/ansible.txt")
        ((pen-istr-p "Maigret")
         "$NOTES/ws/maigret/glossary.txt"
         "$NOTES/ws/french/words.txt")
        ((or (pen-istr-p "mark forsyth")
             (pen-istr-p "simulacra")
             (derived-mode-p 'wordnut-mode))
         ,(glob "/home/shane/notes/ws/*/words.txt")
         ,(glob "/home/shane/notes/ws/*/phrases.txt")
         "$HOME/glossaries/english.txt")
        ((ieat-in-region-or-buffer-or-path-p "Myst")
         "$HOME/glossaries/myst.txt")
        ((or (pen-istr-p "mitmproxy")
             (pen-istr-p "Filter expressions"))
         "$HOME/glossaries/mitm.txt")
        ((or (pen-istr-p "network")
             (pen-istr-p "ifconfig"))
         "$HOME/glossaries/ip-networking.txt")
        ((or (pen-istr-p "spacy"))
         "$HOME/glossaries/spacy.txt")
        ((or (pen-istr-p "loom")
             (pen-istr-p "laria"))
         "$HOME/glossaries/multiverse.txt")
        ((or (pen-istr-p "learning")
             (pen-istr-p "intelligence"))
         "$HOME/glossaries/artificial-intelligence-ai.txt")
        ((pen-ire-p "\\bROS\\b") "$HOME/glossaries/ros.txt")
        ((or (pen-istr-p "database")
             (pen-istr-p "solr")
             (pen-istr-p "elasticsearch")
             (ieat-in-region-or-buffer-or-path-p "kibana")
             (ieat-in-region-or-buffer-or-path-p "information retrieval")
             (ieat-in-region-or-buffer-or-path-p "SEO"))
         "$HOME/glossaries/nlp-natural-language-processing.txt"
         "$HOME/glossaries/transformer.txt"
         "$HOME/glossaries/information-retrieval.txt"
         "$HOME/glossaries/spacy.txt"
         "$HOME/glossaries/elk-elastic-search.txt"
         "$HOME/glossaries/seo-search-engine-optimisation.txt"
         "$HOME/glossaries/databases.txt")
        ((or (pen-istr-p "natural language processing")
             (ieat-in-region-or-buffer-or-path-p "nlp")
             (pen-istr-p "liguistic")
             (pen-istr-p "embedding")
             (ieat-in-region-or-buffer-or-path-p "transformer")
             (ieat-in-region-or-buffer-or-path-p "GPT")
             (ieat-in-region-or-buffer-or-path-p "openai")
             (ieat-in-region-or-buffer-or-path-p "huggingface")
             (ieat-in-region-or-buffer-or-path-p "information retrieval"))
         "$HOME/glossaries/nlp-natural-language-processing.txt"
         "$HOME/glossaries/nlp-python.txt"
         "$HOME/glossaries/openai.txt"
         "$HOME/glossaries/huggingface.txt"
         "$HOME/glossaries/information-retrieval.txt"
         "$HOME/glossaries/seo-search-engine-optimisation.txt"
         "$HOME/glossaries/linguistics.txt"
         "$HOME/glossaries/prompt-engineering.txt"
         "$HOME/glossaries/language-acquisition.txt"
         "$HOME/glossaries/spoken-languages.txt"
         "$HOME/glossaries/databases.txt")
        ((or (pen-istr-p "ENGLISH BIBLE")
             (pen-istr-p "psalm")
             (pen-istr-p "hebrew")
             (pen-istr-p "King James"))
         "$HOME/glossaries/bible.txt"
         "$HOME/glossaries/bible-english.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "ADV")
             (ieat-in-region-or-buffer-or-path-p "DET")
             (ieat-in-region-or-buffer-or-path-p "NOUN"))
         "$HOME/glossaries/nlp-natural-language-processing.txt")
        ((or (pen-istr-p "relevance")
             (pen-istr-p "retrieval")
             (pen-istr-p "ranking")
             (ieat-in-region-or-buffer-or-path-p "IR"))
         "$HOME/glossaries/information-retrieval.txt"
         "$HOME/glossaries/information-ranking.txt")
        ((or (pen-istr-p "inflect"))
         "$HOME/glossaries/linguistics.txt")
        ((or (pen-istr-p "magic"))
         "$HOME/glossaries/magic.txt"
         "$HOME/glossaries/magick.txt")
        ((or (pen-istr-p "concurrency")
             (pen-istr-p "agent")
             (pen-istr-p "lock")
             (pen-istr-p "mutex"))
         "$HOME/glossaries/concurrent-programming.txt")
        ((or (pen-istr-p "Solr"))
         "$HOME/glossaries/solr.txt")
        ((or (pen-istr-p "Random")
             (pen-istr-p "probability")
             (pen-istr-p "outcome")
             (pen-istr-p "information")
             (pen-istr-p "distribution"))
         "$HOME/glossaries/probability.txt"
         "$HOME/glossaries/data-science.txt"
         "$HOME/glossaries/statistics.txt")
        ((or (pen-istr-p "classification")
             (pen-istr-p "regression")
             (pen-istr-p "model")
             (pen-istr-p "computer vision"))
         "$HOME/glossaries/machine-learning.txt"
         "$HOME/glossaries/deep-learning.txt")
        ((or (pen-istr-p "empirical"))
         "$HOME/glossaries/research.txt")
        ((or (pen-istr-p "conditioning"))
         "$HOME/glossaries/reinforcement-learning.txt")
        ((or (pen-istr-p "fixture"))
         "$HOME/glossaries/testing.txt")
        ((or (pen-istr-p "Aragorn"))
         "$HOME/glossaries/lotr-lord-of-the-rings.txt")
        ((or (eat-in-buffer-or-path-p "ZooKeeper")
             (ieat-in-region-or-buffer-or-path-p "Apache")
             (ieat-in-region-or-buffer-or-path-p "tika"))
         "$HOME/glossaries/apache.txt")
        ((or (pen-istr-p "Python")) "$HOME/glossaries/python.txt")
        ((or (pen-istr-p "tcl")) "$HOME/glossaries/tcl.txt")
        ((or (pen-istr-p "TypeScript")) "$HOME/glossaries/typescript.txt")
        ((or (pen-istr-p "Dwarf Fortress"))
         "$HOME/glossaries/dwarf-fortress.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "racket"))
         "$HOME/glossaries/racket.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "unison"))
         "$HOME/glossaries/unison.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "Kotlin")) "$HOME/glossaries/kotlin.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "git"))
         "$HOME/glossaries/git.txt")
        ((or (pen-istr-p "Neural Network"))
         "$HOME/glossaries/deep-learning.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "food")
             (ieat-in-region-or-buffer-or-path-p "cuisine")) "$HOME/glossaries/cooking.txt")
        ((or (pen-istr-p "SQL"))
         "$HOME/glossaries/sql.txt")
        ((or (pen-istr-p "sourcegraph"))
         "$HOME/glossaries/sourcegraph.txt"))))

(defun pen-glossary-list-relevant-glossaries ()
  (append
   (cl-loop for fn in (list-all-pen-glossary-files)
            when
            (pen-istr-p (string-replace ".txt$" "" (basename fn)))
            collect fn)
   (-distinct
    (-flatten
     (cl-loop for tup in
              glossary-predicate-tuples
              collect
              (if (eval (car tup)) (cdr tup)))))))

(defun pen-glossary-add-relevant-glossaries (&optional no-draw)
  (interactive)
  (pen-add-glossaries-to-buffer (pen-glossary-list-relevant-glossaries) no-draw))

(defsetface glossary-button-face
  '((t :foreground "#3fa75f"
       :background nil
       :weight bold
       :underline t))
  "Face for glossary buttons.")

(defsetface glossary-candidate-button-face
  '((t
     :foreground "#3f5fc7"
     :weight bold
     :underline t))
  "Face for glossary candidate buttons.")

(define-button-type 'glossary-button 'follow-link t 'help-echo "Click to go to definition" 'face 'pen-glossary-button-face)
(define-button-type 'glossary-candidate-button 'follow-link t 'help-echo "Click to add to glossary" 'face 'pen-glossary-candidate-button-face)

(defun pen-my-show-overlays-here ()
  (interactive)
  (new-buffer-from-string (pp (cl-loop for o in (overlays-at (point)) collect (sp--get-overlay-text o)))))

(defun pen-my-show-button-paths-here ()
  (interactive)
  (new-buffer-from-string (pp (pen-glossary-get-button-3-tuples-at (point)))))

(defun pen-glossary-get-button-3-tuples-at (p)
  (interactive (list (point)))
  (-filter
   (lambda (tp)
     (apply 'gnus-and tp))
   (cl-loop
    for
    o
    in
    (overlays-at p)
    collect
    (list
     (button-get o 'glossarypath)
     (button-get o 'byteoffset)
     (button-get o 'term)))))

(defset glossary-blacklist
  (s-split " " "The the and in or OR IN to TO"))

(defun pen-glossary-list-tuples (&optional fp)
  (-filter (lambda (e) (not (member (third e) pen-glossary-blacklist)))
           (glossary-sort-tuples
            (if fp
                (pen-eval-string (sn (concat "list-glossary-terms-for-elisp " (q fp))))
              (pen-eval-string (sn "list-glossary-terms-for-elisp"))))))

(defun pen-glossary-sort-tuples (tuples)
  (sort
   tuples
   (lambda (e1 e2) (< (length (third e1))
                      (length (third e2))))))

(defset pen-glossary-term-3tuples (pen-glossary-list-tuples))
(defset pen-glossary-term-3tuples-global pen-glossary-term-3tuples)
(defset pen-glossary-candidate-3tuples nil)

(defun pen-recalculate-glossary-3tuples ()
  (interactive)
  (defset-local pen-glossary-term-3tuples (-distinct (flatten-once (cl-loop for fp in pen-glossary-files collect (pen-glossary-list-tuples fp))))))

(defun pen-glossary-reload-term-3tuples ()
  (interactive)
  (defset pen-glossary-term-3tuples (pen-glossary-list-tuples))
  (defset pen-glossary-term-3tuples-global pen-glossary-term-3tuples))

(defset glossary-button-map
  (let ((map (make-sparse-keymap)))
    (define-key map [(control ?m)] 'push-button)
    (define-key map [double-mouse-1] 'push-button)
    (define-key map [mode-line mouse-2] 'push-button)
    (define-key map [header-line mouse-2] 'push-button)
    map)
  "Keymap used by buttons.")

(defun pen-create-buttons-for-term (term beg end &optional glossarypath byteoffset buttontype)
  "Adds glossary buttons for Term in in beg/end region.
Go through a buffer in search of a term and create buttons for all instances
Use my position list code. Make it use rosie lang and external software."
  (interactive "sTerm: \nr")
  (if (not buttontype)
      (setq buttontype 'glossary-button))

  (goto-char beg)
  (let ((pat
         (concat
          "\\(\\b\\|[. ']\\|^\\)"
          ;; Here, replace the ' ' spaces in term with \\s+
          (regexp-quote term)
          ;; The apostrophe is when I have a possessive (Gehn's)
          "s?\\(\\b\\|[. ']\\|$\\)")
         ))
    (while (re-search-forward pat end t)
      (progn
        (let ((contents (match-string 0))
              (beg (match-beginning 0))
              (end (match-end 0)))
          (if (or (get-text-property (+ 1 beg) 'shr-url)
                  (get-text-property (+ 1 end) 'shr-url))
              (setq end (+ 1 beg)))
          (make-button
           (if (string-match "^[ '.].*" contents)
               (+ beg 1)
             beg)
           (if (string-match ".*[' .]$" contents)
               (- end 1)
             end)
           'term term
           'keymap glossary-button-map
           'glossarypath glossarypath
           'byteoffset byteoffset
           'action (if (eq buttontype 'glossary-candidate-button)
                       'glossary-candidate-button-pressed
                     'pen-glossary-button-pressed)
           'type buttontype))))))

(defun pen-make-buttons-for-glossary-terms (beg end &optional 3tuples buttontype)
  "Makes buttons for glossary terms found in this buffer."
  (interactive "r")
  (if (not buttontype)
      (setq buttontype 'glossary-button))

  (if (not 3tuples)
      (setq 3tuples
            (cond
             ((eq buttontype 'glossary-button) pen-glossary-term-3tuples)
             ((eq buttontype 'glossary-candidate-button) pen-glossary-candidate-3tuples))))

  (if (not beg)
      (let ((nlines (count-lines (point-min) (point-max))))
        (if (> nlines pen-glossary-max-lines-for-entire-buffer-gen)
            (setq beg
                  (pen-glossary-window-start)
                  end
                  (pen-glossary-window-end))
          (setq beg
                (point-min)
                end
                (point-max)))))
  (cl-loop for termtuple in 3tuples do
           (pen-create-buttons-for-term (third termtuple) beg end
                                    (first termtuple)
                                    (cadr termtuple)
                                    buttontype)))

(defun pen-goto-byte (byteoffset)
  (interactive "nByte position: ")
  (goto-char (byte-to-position (+ byteoffset 1))))

(defun pen-glossary-candidate-button-pressed (button)
  "When I press a glossary button, it should take me to the definition"
  (let* ((term (pen-button-get-text button))
         (byteoffset (button-get button 'byteoffset))
         (start (button-start button))
         (glossarypath (button-get button 'glossarypath))
         (buttons-here (pen-glossary-get-button-3-tuples-at start)))

    (if (< 1 (length buttons-here))
        (let* ((button-line (umn (fz (mnm (pp-map-line buttons-here))
                                     nil nil "pen-glossary-candidate-button-pressed: ")))
               (button-tuple (if button-line
                                 (pen-eval-string (concat "'" button-line))))
               (selected-button (if button-tuple
                                    (car (-filter (lambda (li) (and (equal (first button-tuple) (button-get li 'glossarypath))
                                                               (equal (cadr button-tuple) (button-get li 'byteoffset))
                                                               (equal (third button-tuple) (button-get li 'term))))
                                                  (overlays-at start))))))
          (if selected-button
              (progn
                (setq button selected-button)
                (setq term (pen-button-get-text button))
                (setq byteoffset (button-get button 'byteoffset))
                (setq start (button-start button))
                (setq glossarypath (button-get button 'glossarypath))
                (setq buttons-here (pen-glossary-get-button-3-tuples-at byteoffset)))
            (backward-char))))
    (cond
         ((equal current-prefix-arg (list 4)) (setq current-prefix-arg nil))
         ((not current-prefix-arg) (setq current-prefix-arg (list 4))))
    (with-current-buffer
        (pen-add-to-glossary-file-for-buffer term nil (sn "oc" glossarypath)))))

(defun pen-glossary-button-pressed (button)
  "When I press a glossary button, it should take me to the definition"
  (let* ((term (button-get button 'term))
         (byteoffset (button-get button 'byteoffset))
         (start (button-start button))
         (glossarypath (button-get button 'glossarypath))
         (buttons-here (pen-glossary-get-button-3-tuples-at start)))

    (if (< 1 (length buttons-here))
        (let* ((button-line (umn (fz (mnm (pp-map-line buttons-here))
                                     nil nil "pen-glossary-button-pressed: ")))
               (button-tuple (if button-line
                                 (pen-eval-string (concat "'" button-line))))
               (selected-button (if button-tuple
                                    (car (-filter (lambda (li) (and (equal (first button-tuple) (button-get li 'glossarypath))
                                                               (equal (cadr button-tuple) (button-get li 'byteoffset))
                                                               (equal (third button-tuple) (button-get li 'term))))
                                                  (overlays-at start))))))
          (if selected-button
              (progn
                (setq button selected-button)
                (setq term (button-get button 'term))
                (setq byteoffset (button-get button 'byteoffset))
                (setq start (button-start button))
                (setq glossarypath (button-get button 'glossarypath))
                (setq buttons-here (pen-glossary-get-button-3-tuples-at byteoffset)))
            (backward-char))))
    (with-current-buffer
        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (find-file-other-window glossarypath)
          (find-file glossarypath))
      (pen-goto-byte byteoffset)
      )))

(defun pen-reload-glossary-and-generate-buttons (beg end)
  (interactive "r")
  (pen-glossary-reload-term-3tuples)
  (pen-generate-glossary-buttons-over-buffer beg end t))

(defun pen-reload-glossary-reopen-and-generate-buttons (beg end)
  "DEPRECATED"
  (interactive "r")
  (pen-glossary-reload-term-3tuples)
  (pen-kill-buffer-and-reopen)
  (pen-generate-glossary-buttons-over-buffer beg end))

(defun pen-button-get-text (b)
  (if b
      (buffer-substring (button-start b) (button-end b))))

(defalias 'pen-list-all-pen-glossary-files 'pen-list-pen-glossary-files)

(defun pen-other-glossaries-not-added-yet ()
  (let ((all-glossary-files (pen-list-pen-glossary-files)))
    (if (and (local-variable-p 'pen-glossary-files) pen-glossary-files)
        (-difference
         all-glossary-files
         pen-glossary-files)
      all-glossary-files)))

(defun pen-get-keyphrases-for-buffer (beg end)
  (interactive "r")

  (-filter-not-empty-string
   (let ((s (buffer-substring (pen-glossary-window-start)
                              (pen-glossary-window-end))))
     (s-lines (cl-sn "extract-keyphrases" :stdin s :chomp t)))))

(defun pen-recalculate-glossary-candidate-3tuples (beg end)
  (interactive "r")
  (let* ((p (mnm (get-path-nocreate)))
         (tls (mapcar
               (lambda (s) (list p nil s))
               (-distinct
                (if glossary-term-3tuples
                    (let ((tl (mapcar 'downcase (mapcar 'third pen-glossary-term-3tuples))))
                      (-filter
                       (lambda (s) (not (-contains? tl (downcase s))))
                       (pen-get-keyphrases-for-buffer beg end)))
                  (pen-get-keyphrases-for-buffer beg end))))))
    (if (not (use-region-p))
        (defset-local pen-glossary-candidate-3tuples tls))
    tls))

(defun pen-draw-glossary-buttons-and-maybe-recalculate (beg end &optional recalculate-tuples)
  (interactive "r")

  (if (not (or (derived-mode-p 'dired-mode)
               (derived-mode-p 'compilation-mode)
               (string-equal (buffer-name) "*button cloud*")
               (string-match (buffer-name) "^\\*untitled")))
      (progn
        (if (or
             recalculate-tuples
             (not (local-variable-p 'pen-glossary-term-3tuples))
             (derived-mode-p 'eww-mode))
            (progn
              (pen-recalculate-glossary-3tuples)
              (recalculate-glossary-error-3tuples)))

        (if (and
             (myrc-test "glossary_suggest_keyphrases")
             (or
              (derived-mode-p 'eww-mode)
              (derived-mode-p 'text-mode)
              (derived-mode-p 'org-brain-visualize-mode)
              (derived-mode-p 'sx-question-mode))
             (not (derived-mode-p 'yaml-mode)))
            (pen-recalculate-glossary-candidate-3tuples beg end))

        (gl-beg-end
         (progn
           (make-buttons-for-glossary-terms
            gl-draw-start
            gl-draw-end)
           (make-buttons-for-glossary-terms
            gl-draw-start
            gl-draw-end
            glossary-candidate-3tuples
            'glossary-candidate-button)
           (make-buttons-for-glossary-terms
            gl-draw-start
            gl-draw-end
            glossary-error-term-3tuples
            'glossary-error-button))))))

(defun pen-append-pen-glossary-files-locally (fps)
  (if (local-variable-p 'pen-glossary-files)
      (defset-local pen-glossary-files (-union pen-glossary-files fps))
    (defset-local pen-glossary-files fps)))

(defun pen-add-glossaries-to-buffer (fps &optional no-draw)
  (interactive (list (-filter-not-empty-string (s-lines (umn (fz (mnm (list2str (pen-other-glossaries-not-added-yet)))))))))
  (if fps
      (save-excursion
        (progn
          (append-glossary-files-locally fps)

          (if (not no-draw)
              (pen-draw-glossary-buttons-and-maybe-recalculate nil nil))))))

(defun pen-test-f (fp)
  (eq (progn (sn (concat "test -f " (q fp)))
             (string-to-number b_exit_code))
      0))

(defun pen-test-d (fp)
  (eq (progn (sn (concat "test -d " (q fp)))
             (string-to-number b_exit_code))
      0))

(defun pen-glossary-path-p (&optional fp)
  (if (not fp)
      (setq fp (get-path-nocreate)))
  (if fp
      (or (string-match "/glossary.txt$" fp)
          (string-match "glossaries/.*\\.txt$" fp)
          (string-match "/home/shane/notes/ws/.*/words.txt$" fp)
          (string-match "/home/shane/notes/ws/.*/phrases.txt$" fp))))

(defset glossary-imenu-generic-expression
  '(("" "^\\([^\n ].+\\)$" 1)))
(defun pen-glossary-imenu-configure ()
  (interactive)
  (if (pen-glossary-path-p)
      (setq imenu-generic-expression pen-glossary-imenu-generic-expression)))
(add-hook 'text-mode-hook 'pen-glossary-imenu-configure)

(defun pen-button-imenu ()
  (interactive)
  (let ((imenu-create-index-function #'button-cloud-create-imenu-index))
    (helm-imenu)))
(defalias 'pen-glossary-button-imenu 'pen-button-imenu)

(defun pen-byte-to-marker (byte)
  (set-marker (make-marker) byte))

(defun pen-generate-glossary-buttons-over-region (beg end &optional clear-first force)
  (interactive "r")
  (if glossary-keep-tuples-up-to-date
      (pen-glossary-reload-term-3tuples))

  (if (not (use-region-p))
      (pen-generate-glossary-buttons-over-buffer beg end clear-first force)
    (progn
      (if clear-first (pen-remove-glossary-buttons-over-region beg end))

      (let ((pen-glossary-files)
            (glossary-error-files))
        (pen-glossary-add-relevant-glossaries t)
        (glossary-error-add-relevant-glossaries t)
        (save-excursion
          (let ((glossary-files
                 (mu '("$NOTES/ws/english/words.txt")))
                (glossary-error-files nil))
            (mylog (pen-draw-glossary-buttons-and-maybe-recalculate beg end))))))))

(defun pen-generate-glossary-buttons-over-buffer-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    res))
(advice-add 'pen-generate-glossary-buttons-over-buffer :around #'pen-generate-glossary-buttons-over-buffer-around-advice)
(advice-remove 'pen-generate-glossary-buttons-over-buffer #'pen-generate-glossary-buttons-over-buffer-around-advice)

(defun pen-generate-glossary-buttons-over-buffer (beg end &optional clear-first force)
  (interactive "r")

  (if force (defset-local glossary-force-on t))

  (if (use-region-p)
      (pen-generate-glossary-buttons-over-region beg end clear-first force)
    (unless (or
             (string-equal (get-path-nocreate) "/home/shane/var/smulliga/source/git/config/emacs/config/my-glossary.el")
             (and (not (myrc-test "auto_glossary_enabled"))
                  (not (and (variable-p 'glossary-force-on) glossary-force-on))))

      (if clear-first (pen-remove-all-glossary-buttons))

      (pen-glossary-add-relevant-glossaries t)
      (glossary-error-add-relevant-glossaries t)
      (save-excursion
        (if (or (and (variable-p 'glossary-force-on) glossary-force-on)
                (not (or (derived-mode-p 'org-modmfse)
                         (derived-mode-p 'outline-mode)
                         (string-equal (buffer-name) "*glossary cloud*"))))

            (progn
              (mu (cond ((derived-mode-p 'python-mode)
                         (progn
                           (append-glossary-files-locally (list "$HOME/glossaries/python.txt"
                                                                "$HOME/glossaries/tensorflow.txt"
                                                                "$HOME/glossaries/nlp-python.txt"
                                                                "$HOME/glossaries/onnx.txt"
                                                                "$HOME/glossaries/deep-learning.txt"
                                                                "$HOME/glossaries/nlp-natural-language-processing.txt"))))
                        ((and (derived-mode-p 'text-mode)
                              (stringp (get-path-nocreate))
                              (let* ((fp (get-path-nocreate))
                                     (bn (basename fp))
                                     (dn (f-dirname fp))
                                     (ext (file-name-extension bn))
                                     (mant (file-name-sans-extension bn))
                                     (pdf-fp (concat dn "/" mant ".pdf"))
                                     (PDF-fp (concat dn "/" mant ".PDF")))
                                (or (pen-test-f pdf-fp)
                                    (pen-test-f PDF-fp))))
                         (progn
                           (let ((glossary-fp (concat (f-dirname (get-path-nocreate)) "/glossary.txt")))
                             (append-glossary-files-locally (list glossary-fp)))))
                        ((and (get-path-nocreate)
                              (let* ((fp (get-path-nocreate))
                                     (bn (basename fp))
                                     (dn (f-dirname fp))
                                     (dnbn (basename dn))
                                     (ext (file-name-extension bn))
                                     (mant (file-name-sans-extension bn)))
                                (or (and (string-equal dnbn "glossaries")
                                         (derived-mode-p 'text-mode))
                                    (string-equal bn "glossary.txt"))))
                         (append-glossary-files-locally (list (get-path-nocreate))))
                        ((derived-mode-p 'prog-mode)
                         (let* ((lang (detect-language))
                                (lang (cond ((string-equal "emacs-lisp" lang) "emacs-lisp-elisp")
                                            (t lang)))
                                (fp (concat "$HOME/glossaries/" lang ".txt")))
                           (if (pen-test-f fp)
                               (append-glossary-files-locally (list fp)))))
                        ((str-match-p "Lord of the Rings" (get-path-nocreate))
                         (progn
                           (append-glossary-files-locally (list "$HOME/glossaries/lotr-lord-of-the-rings.txt"))))
                        ((pen-glossary-path-p (get-path-nocreate))
                         (append-glossary-files-locally (list (get-path-nocreate))))))

              (pen-draw-glossary-buttons-and-maybe-recalculate beg end)))))))

(defmacro pen-gl-beg-end (&rest body)
  `(let* ((gl-beg (if mark-active
                      (min (point) (mark))
                    (point-min)))
          (gl-end (if mark-active
                      (max (point) (mark))
                    (point-max)))
          (nlines (count-lines gl-beg gl-end))
          (gl-use-sliding-window (> nlines pen-glossary-max-lines-for-entire-buffer-gen))
          (gl-draw-start (or
                          gl-beg
                          (if gl-use-sliding-window
                              (pen-glossary-window-start)
                            (point-min))))
          (gl-draw-end (or
                        gl-end
                        (if gl-use-sliding-window
                            (pen-glossary-window-end)
                          (point-max)))))
     (progn
       ,@body)))

(defun pen-generate-glossary-buttons-manually ()
  (interactive)

  (if (derived-mode-p 'term-mode)
      (with-current-buffer
          (new-buffer-from-tmux-pane-capture t)
        (pen-generate-glossary-buttons-manually))
    (gl-beg-end
     (if (use-region-p)
         (pen-generate-glossary-buttons-over-region gl-beg gl-end nil t)
       (pen-generate-glossary-buttons-over-buffer gl-end gl-end nil t)))))

(defun pen-wordnut--lookup-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (pen-run-buttonize-hooks)
    res))
(advice-add 'wordnut--lookup :around #'pen-wordnut--lookup-around-advice)

(defun pen-after-emacs-loaded-add-hooks-for-glossary ()
  (add-hook 'find-file-hooks 'pen-run-buttonize-hooks t)
  (remove-hook 'new-buffer-hooks 'pen-redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
  (pen-restart-glossary))

(add-hook 'emacs-startup-hook 'pen-after-emacs-loaded-add-hooks-for-glossary t)

(defun pen-glossary-next-button-fast (pos)
  (let* ((nextpos (next-single-char-property-change pos 'button))
         (nextbutton (button-at nextpos)))
    (if (not (and (not nextbutton) (= (button-start nextbutton) pos)))
        (progn
          (while (or (not nextbutton) (= (button-start nextbutton) pos))
            (progn
              (setq nextpos (next-single-char-property-change nextpos 'button))
              (setq nextbutton (button-at nextpos))))
          nextbutton))))

(defun pen-next-button-of-face (face)
  "Go to the next button which has the given face"
  (let ((b nil)
        (pos nil))
    (save-excursion
      (let ((cand (next-button (point)))
            (bface (button-get cand 'face)))
        (while (and cand (eq bface 'pen-glossary-button-face))
          (setq cand (next-button (point))))
        (setq pos (point))
        cand))
    (goto-char pos)))

(defun pen-buttons-collect (&optional face)
  "Collect the positions of visible links in the current `help-mode' buffer."

  (let* ((candidates)
         (p (pen-glossary-window-start))
         (b (button-at p))
         (e (or (and b (button-end b)) p))
         (le e))
    (if (and b (if face (eq (button-get b 'face) face)
                 t))
        (push (cons (button-label b) p) candidates))
    (while (and (setq b (next-button e))
                (setq p (button-start b))
                (setq e (button-end b))
                (< p (pen-glossary-window-end)))
      (if (and b (if face (eq (button-get b 'face) face)
                   t))
          (push (cons (button-label b) p) candidates)
        (progn
          (setq e (+ (button-start b) 1))
          (if (<= e le)
              (setq e (+ 1 le)))
          (setq le e))))
    (nreverse candidates)))

(defun pen-widgets-collect ()
  "Collect the positions of visible links in the current gnus buffer."
  (require 'wid-edit)
  (let (candidates pt)
    (save-excursion
      (goto-char (point-min))
      (setq pt (point))
      (if (widget-at (point))
          (push (cons (str (thing-at-point 'symbol)) (point)) candidates))
      (ignore-errors
        (while
            (progn (widget-forward 1)
                   (> (point) pt))
          (setq pt (point))
          (push (cons (str (thing-at-point 'symbol)) (point)) candidates)))
      (nreverse candidates))))

(defun pen-glossary-buttons-collect ()
  (append (pen-buttons-collect 'pen-glossary-button-face)
          (pen-buttons-collect 'pen-glossary-candidate-button-face)
          (pen-buttons-collect 'glossary-error-button-face)))

(defun pen-ace-link-glossary-button ()
  (interactive)
  (let ((pt (avy-with ace-link-help
              (avy-process
               (mapcar #'cdr (pen-glossary-buttons-collect))
               (avy--style-fn avy-style)))))
    (ace-link--help-action pt)))

(defun pen-goto-glossary-definition (term)
  (interactive (list
                (fz (sn "list-glossary-terms")
                    (if mark-active (downcase (my/thing-at-point)))
                    nil
                    "pen-goto-glossary-definition: ")))

  (if glossary-keep-tuples-up-to-date
      (pen-glossary-reload-term-3tuples))

  (let* ((tups (-filter (lambda (e) (string-equal (car (last e)) term)) pen-glossary-term-3tuples-global))
         (button-line (if tups
                          (umn (fz (mnm (pp-map-line tups)) nil nil nil nil t))))
         (button-tuple (if button-line
                           (pen-eval-string (concat "'" button-line)))))
    (if button-tuple
        (progn
          (deactivate-mark)
          (with-current-buffer
              (if (>= (prefix-numeric-value current-prefix-arg) 4)
                  (find-file-other-window (first button-tuple))
                (find-file (first button-tuple)))
            (pen-goto-byte (cadr button-tuple))))
      (message "word not found"))
    nil))

(defun pen-goto-glossary-definition-noterm (term)
  (interactive (list (fz (sn "list-glossary-terms")
                         ""
                         nil
                         "pen-goto-glossary-definition-noterm: ")))

  (pen-goto-glossary-definition term))

(defun pen-go-to-glossary-file-for-buffer (&optional take-first)
  (interactive)
  (mu (find-file (or (and (not (>= (prefix-numeric-value current-prefix-arg) 4))
                   (local-variable-p 'pen-glossary-files)
                   (if take-first
                       (car pen-glossary-files)
                     (umn (fz (mnm (list2str pen-glossary-files))
                              nil
                              nil
                              "pen-go-to-glossary-file-for-buffer: "))))
              (umn (fz (mnm (list2str (list-pen-glossary-files)))
                       nil
                       nil
                       "pen-go-to-glossary-file-for-buffer: "))))))



(define-key global-map (kbd "H-i") 'pen-add-glossaries-to-buffer)
(define-key global-map (kbd "H-Y I") 'pen-add-glossaries-to-buffer)

(define-key global-map (kbd "H-d") 'pen-generate-glossary-buttons-manually)
(define-key global-map (kbd "H-Y d") 'pen-generate-glossary-buttons-manually)
(define-key global-map (kbd "H-Y F") 'pen-go-to-glossary-file-for-buffer)
(define-key global-map (kbd "H-Y A") 'pen-add-to-glossary-file-for-buffer)
(define-key global-map (kbd "H-Y G") 'pen-glossary-reload-term-3tuples)
(define-key global-map (kbd "H-h") 'pen-goto-glossary-definition)
(define-key global-map (kbd "H-Y H") 'pen-goto-glossary-definition)
(define-key global-map (kbd "H-Y L") 'go-to-glossary)
(define-key global-map (kbd "<help> y") 'pen-goto-glossary-definition)
(define-key global-map (kbd "<help> C-y") 'go-to-glossary)
(define-key global-map (kbd "H-y") 'pen-go-to-glossary-file-for-buffer)

(define-key selected-keymap (kbd "A") 'pen-add-to-glossary-file-for-buffer)

(defun pen-remove-glossary-buttons-over-region (beg end)
  (interactive "r")
  (remove-overlays beg end 'face 'pen-glossary-button-face))

(defun pen-remove-all-glossary-buttons ()
  (interactive "r")
  (message "(pen-remove-all-glossary-buttons)")
  (pen-remove-glossary-buttons-over-region (point-min) (point-max)))
(defalias 'pen-clear-glossary-buttons 'pen-remove-all-glossary-buttons)

(defset pen-my-buttonize-hook '())

(add-hook 'pen-my-buttonize-hook 'pen-redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
(add-hook 'pen-my-buttonize-hook 'make-buttons-for-all-filter-cmds)

(defun pen-run-buttonize-hooks ()
  (interactive)
  (run-hooks 'pen-my-buttonize-hook))

(defun pen-Info-find-node-2-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (pen-run-buttonize-hooks)
    res))
(advice-add 'Info-find-node-2 :around #'pen-Info-find-node-2-around-advice)

(defun pen-redraw-glossary-buttons-when-window-scrolls-or-file-is-opened ()
  (interactive)
  (message-no-echo (concat "redraw-glossary scroll " (get-path nil t)))
  (unless (or
           (not (myrc-test "auto_glossary_enabled"))
           (derived-mode-p 'dired-mode)
           (derived-mode-p 'compilation-mode)
           (string-equal (buffer-name) "*button cloud*")
           (string-match (buffer-name) "^\\*untitled")
           (and (timerp pen-draw-glossary-buttons-timer)
                (= pen-glossary-timer-current-window-start (pen-glossary-window-start))
                (string= pen-glossary-timer-current-buffer-name (buffer-name))))
    (defset pen-glossary-timer-current-window-start (pen-glossary-window-start))
    (defset pen-glossary-timer-current-buffer-name (buffer-name))
    (if (or (derived-mode-p 'prog-mode)
            (derived-mode-p 'text-mode)
            (derived-mode-p 'conf-mode)
            (derived-mode-p 'org-brain-visualize-mode)
            (derived-mode-p 'Info-mode)
            (derived-mode-p 'eww-mode)
            (derived-mode-p 'fundamental-mode)
            (derived-mode-p 'Man-mode)
            (derived-mode-p 'special-mode))
        (pen-generate-glossary-buttons-over-buffer nil nil t))))

(defvar pen-draw-glossary-buttons-timer nil)

(defun pen-toggle-draw-glossary-buttons-timer (&optional newstate)
  (interactive)
  (defset pen-glossary-timer-current-window-start (pen-glossary-window-start))
  (defset pen-glossary-timer-current-buffer-name (buffer-name))

  (cond ((not (timerp pen-draw-glossary-buttons-timer))
         (if (interactive-p)
             (progn (pen-generate-glossary-buttons-over-buffer nil nil t)
                    (setq pen-draw-glossary-buttons-timer (run-with-idle-timer pen-glossary-idle-time 1 'pen-run-buttonize-hooks))
                    (message "glossary timer created")
                    t)
           nil))
        ((eq -1 newstate)
         (progn
           (cancel-timer pen-draw-glossary-buttons-timer)
           (message "glossary timer stopped")
           nil))
        ((eq 1 newstate)
         (progn
           (cancel-timer pen-draw-glossary-buttons-timer)
           (progn (pen-generate-glossary-buttons-over-buffer nil nil t)
                  (setq pen-draw-glossary-buttons-timer (run-with-idle-timer pen-glossary-idle-time 1 'pen-run-buttonize-hooks))
                  t)
           (message "glossary timer restarted")))
        (t
         (if (interactive-p)
             (if (-contains? timer-idle-list pen-draw-glossary-buttons-timer)
                 (pen-toggle-draw-glossary-buttons-timer -1)
               (pen-toggle-draw-glossary-buttons-timer 1))
           (-contains? timer-idle-list pen-draw-glossary-buttons-timer)))))

(defun pen-restart-glossary ()
  (interactive)
  (pen-toggle-draw-glossary-buttons-timer t))

(defun pen-glossary-add-link (term fp)
  (interactive (list (read-string-hist "glossary term: " (my/thing-at-point))
                     (umn (fz (mnm (list2str (glob "/home/shane/glossaries/*.txt")))
                              "$HOME/glossaries/"
                              nil "pen-glossary-add-link: "))))
  (let ((code
         `((or (pen-istr-p ,term))
           ,(mnm fp))))
    (j 'pen-glossary-predicate-tuples)
    (special-lispy-different)
    (-dotimes 3 'backward-char)
    (newline)
    (indent-for-tab-command)
    (insert (pp-oneline code))))

(define-key selected-keymap (kbd "L") 'pen-glossary-add-link)

(defun pen-glossary-draw-after-advice (proc &rest args)
  (let ((res (apply proc args)))
    (pen-generate-glossary-buttons-over-buffer nil nil t)
    (pen-redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
    res))

(advice-add 'Man-bgproc-sentinel :around #'pen-glossary-draw-after-advice)
(advice-remove 'Man-getpage-in-background #'Man-notify-when-ready-around-advice)

(define-key global-map (kbd "H-B") 'pen-goto-glossary-definition)

(defun pen-generate-glossary-term-and-definition (term)
  (interactive))

(define-key selected-keymap (kbd "Z g g") 'pen-generate-glossary-term-and-definition)

(defun pen-is-glossary-file (&optional fp)
  (setq fp (or fp (get-path)))
  (or
   (string-match "glossary\\.txt$" fp)
   (string-match "words\\.txt$" fp)
   (string-match "glossaries/.*\\.txt$" fp)))

(require 'link-hint)

(defun pen-glossary-button-at-point ()
  (let ((p (point))
        (b (button-at-point)))
    (if (and
         b
         (eq (button-get b 'face) 'pen-glossary-button-face))
        b
      nil))
  (button-at-point))
(defalias 'pen-glossary-button-at-point-p 'pen-glossary-button-at-point)

(defun pen-my-button-get-link (b)
  (cond
   ((eq (button-get b 'face) 'pen-glossary-button-face)
    (concat "[[y:" (pen-button-get-text b) "]]"))
   (t nil)))

(defun pen-my-button-copy-link-at-point ()
  (interactive)
  (let* ((url (get-text-property (point) 'shr-url)))
    (setq url
          (cond
           (url url)
           ((button-at-point) (pen-my-button-get-link (button-at-point)))))
    (xc (message url))))

(defun pen-ace-link-copy-button-link ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-buttons-collect))
     (avy--style-fn avy-style)))
  (let* ((b (button-at-point))
         (lambda (pen-my-button-get-link b)))
    (if l
        (xc l))))