(require 'my-regex)
(require 'my-lists)

(require 'my-glossary-error)

(require 'my-computed-context)

(defvar glossary-keep-tuples-up-to-date t)

(defset glossary-max-lines-for-entire-buffer-gen 1000)
(defset glossary-overflow-chars 10000)
(defset glossary-idle-time 0.2)

(defvar glossary-files nil)

(defun glossary-window-start ()
  (max 1 (- (window-start) glossary-overflow-chars)))

(defun glossary-window-end ()
  (min (point-max) (+ (window-end) glossary-overflow-chars)))



(defun go-glossary-predicate-tuples ()
  (interactive)
  (j 'glossary-predicate-tuples))
(define-key global-map (kbd "H-Y P") 'go-glossary-predicate-tuples)

(defset glossary-predicate-tuples
  (mu `(((or (re-in-region-or-buffer-or-path-p "\\bVault\\b")
             (re-in-region-or-buffer-or-path-p "\\bConsul\\b")
             (and (not (derived-mode-p 'text-mode))
                  (istr-in-region-or-buffer-or-path-p "terraform"))
             (and (not (derived-mode-p 'text-mode))
                  (ire-in-region-or-buffer-or-path-p "\\bvagrant\\b")))
         "$HOME/glossaries/hashicorp.txt"
         "$HOME/glossaries/terraform.txt")
        ((or (istr-in-region-or-buffer-p "French")
             (istr-in-region-or-buffer-p "france")
             (istr-match-p "French" (get-path nil t)))
         "$HOME/glossaries/french.txt"
         "$NOTES/ws/french/phrases.txt"
         "$NOTES/ws/french/glossary.txt")
        ((istr-in-region-or-buffer-p "fasttext")
         "$HOME/glossaries/fasttext.txt")
        ((istr-in-region-or-buffer-p "tensorflow")
         "$HOME/glossaries/tensorflow.txt")
        ((or (istr-in-region-or-buffer-p "pytorch")
             (istr-in-region-or-buffer-p "huggingface"))
         "$HOME/glossaries/pytorch.txt")
        ((or (istr-in-region-or-buffer-p "kafka"))
         "$HOME/glossaries/kafka.txt")
        ((or (istr-in-region-or-buffer-p "ocean"))
         "$HOME/glossaries/ocean.txt")
        ((or (istr-in-region-or-buffer-p "semiotic")
             (istr-in-region-or-buffer-p "semiosis"))
         "$HOME/glossaries/semiotics.txt")
        ((or (str-in-region-or-buffer-p "consciousness")
             (str-in-region-or-buffer-p "Schrodinger"))
         "$HOME/glossaries/consciousness.txt"
         "$HOME/glossaries/general-ai-agi.txt")
        ((or (str-in-region-or-buffer-p "cryptocurrenc")
             (str-in-region-or-buffer-p "blockchain")
             (str-in-region-or-buffer-p "crypto")
             (str-in-region-or-buffer-p "bitcoin")
             (str-in-region-or-buffer-p "ethereum"))
         "$HOME/glossaries/cryptocurrencies.txt"
         "$HOME/glossaries/cryptography.txt")
        ((or (istr-in-region-or-buffer-p "optic")
             (ieat-in-region-or-buffer-p "lens")
             (istr-in-region-or-buffer-p "prism")
             (istr-in-region-or-buffer-p "focal")
             (ieat-in-region-or-buffer-p "light"))
         "$HOME/glossaries/optics.txt"
         "$HOME/glossaries/physics.txt")
        ((or (str-in-region-or-buffer-p "hashing")
             (ieat-in-region-or-buffer-or-path-p "hash"))
         "$HOME/glossaries/hashing.txt")
        ((or (istr-in-region-or-buffer-p "graphql"))
         "$HOME/glossaries/graphql.txt")
        ((or (str-in-region-or-buffer-p "Schrodinger"))
         "$HOME/glossaries/quantum-mechanics.txt")
        ((or (istr-in-region-or-buffer-p "datomic"))
         "$HOME/glossaries/datomic.txt")
        ((or (str-in-region-or-buffer-p "localhost"))
         "$HOME/glossaries/ip-networking.txt")
        ((or (str-in-region-or-buffer-p "keras"))
         "$HOME/glossaries/keras.txt")
        ((or (str-in-region-or-buffer-p "terraform")
             (str-in-region-or-buffer-p "docker")
             (ire-in-region-or-buffer-p "\\bIaC\\b"))
         "$HOME/glossaries/iac-infrastructure-as-code.txt")
        ((or (ire-in-region-or-buffer-p "prolog"))
         "$HOME/glossaries/prolog.txt")
        ((or (ire-in-region-or-buffer-p "\\bnix"))
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
        ((or (ire-in-region-or-buffer-or-path-p "kubernetes")
             (ire-in-region-or-buffer-or-path-p "k8s"))
         "$HOME/glossaries/kubernetes.txt")
        ((or (istr-in-region-or-buffer-or-path-p "lotr")
             (istr-in-region-or-buffer-or-path-p "lord of the rings"))
         "$HOME/glossaries/lotr-lord-of-the-rings.txt")
        ((ire-in-region-or-buffer-or-path-p "docker")
         "$HOME/glossaries/docker.txt")
        ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Window-Hooks.html
        ((ire-in-region-or-buffer-or-path-p "/elisp/")
         "$HOME/glossaries/emacs-lisp-elisp.txt")
        ((istr-in-region-or-buffer-or-path-p "clojure")
         "$HOME/glossaries/clojure.txt"
         "$HOME/glossaries/programming-language-theory.txt")
        ((and (ire-in-region-or-buffer-or-path-p "haskell")
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
        ((ire-in-region-or-buffer-or-path-p "\\bANSIBLE\\b")
         "$HOME/glossaries/ansible.txt")
        ((istr-in-region-or-buffer-or-path-p "Maigret")
         "$NOTES/ws/maigret/glossary.txt"
         "$NOTES/ws/french/words.txt")
        ((or (istr-in-region-or-buffer-or-path-p "mark forsyth")
             (istr-in-region-or-buffer-or-path-p "simulacra")
             (derived-mode-p 'wordnut-mode))
         ,(glob "/home/shane/notes/ws/*/words.txt")
         ,(glob "/home/shane/notes/ws/*/phrases.txt")
         "$HOME/glossaries/english.txt")
        ((ieat-in-region-or-buffer-or-path-p "Myst")
         "$HOME/glossaries/myst.txt")
        ((or (istr-in-region-or-buffer-or-path-p "mitmproxy")
             (istr-in-region-or-buffer-or-path-p "Filter expressions"))
         "$HOME/glossaries/mitm.txt")
        ((or (istr-in-region-or-buffer-or-path-p "network")
             (istr-in-region-or-buffer-or-path-p "ifconfig"))
         "$HOME/glossaries/ip-networking.txt")
        ((or (istr-in-region-or-buffer-or-path-p "spacy"))
         "$HOME/glossaries/spacy.txt")
        ((or (istr-in-region-or-buffer-or-path-p "loom")
             (istr-in-region-or-buffer-or-path-p "laria"))
         "$HOME/glossaries/multiverse.txt")
        ((or (istr-in-region-or-buffer-or-path-p "learning")
             (istr-in-region-or-buffer-or-path-p "intelligence"))
         "$HOME/glossaries/artificial-intelligence-ai.txt")
        ((ire-in-region-or-buffer-or-path-p "\\bROS\\b") "$HOME/glossaries/ros.txt")
        ((or (istr-in-region-or-buffer-or-path-p "database")
             (istr-in-region-or-buffer-or-path-p "solr")
             (istr-in-region-or-buffer-or-path-p "elasticsearch")
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
        ((or (istr-in-region-or-buffer-or-path-p "natural language processing")
             (ieat-in-region-or-buffer-or-path-p "nlp")
             (istr-in-region-or-buffer-or-path-p "liguistic")
             (istr-in-region-or-buffer-or-path-p "embedding")
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
        ((or (istr-in-region-or-buffer-or-path-p "ENGLISH BIBLE")
             (istr-in-region-or-buffer-or-path-p "psalm")
             (istr-in-region-or-buffer-or-path-p "hebrew")
             (istr-in-region-or-buffer-or-path-p "King James"))
         "$HOME/glossaries/bible.txt"
         "$HOME/glossaries/bible-english.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "ADV")
             (ieat-in-region-or-buffer-or-path-p "DET")
             (ieat-in-region-or-buffer-or-path-p "NOUN"))
         "$HOME/glossaries/nlp-natural-language-processing.txt")
        ((or (istr-in-region-or-buffer-or-path-p "relevance")
             (istr-in-region-or-buffer-or-path-p "retrieval")
             (istr-in-region-or-buffer-or-path-p "ranking")
             (ieat-in-region-or-buffer-or-path-p "IR"))
         "$HOME/glossaries/information-retrieval.txt"
         "$HOME/glossaries/information-ranking.txt")
        ((or (istr-in-region-or-buffer-or-path-p "inflect"))
         "$HOME/glossaries/linguistics.txt")
        ((or (istr-in-region-or-buffer-or-path-p "magic"))
         "$HOME/glossaries/magic.txt"
         "$HOME/glossaries/magick.txt")
        ((or (istr-in-region-or-buffer-or-path-p "concurrency")
             (istr-in-region-or-buffer-or-path-p "agent")
             (istr-in-region-or-buffer-or-path-p "lock")
             (istr-in-region-or-buffer-or-path-p "mutex"))
         "$HOME/glossaries/concurrent-programming.txt")
        ((or (istr-in-region-or-buffer-or-path-p "Solr"))
         "$HOME/glossaries/solr.txt")
        ((or (istr-in-region-or-buffer-or-path-p "Random")
             (istr-in-region-or-buffer-or-path-p "probability")
             (istr-in-region-or-buffer-or-path-p "outcome")
             (istr-in-region-or-buffer-or-path-p "information")
             (istr-in-region-or-buffer-or-path-p "distribution"))
         "$HOME/glossaries/probability.txt"
         "$HOME/glossaries/data-science.txt"
         "$HOME/glossaries/statistics.txt")
        ((or (istr-in-region-or-buffer-or-path-p "classification")
             (istr-in-region-or-buffer-or-path-p "regression")
             (istr-in-region-or-buffer-or-path-p "model")
             (istr-in-region-or-buffer-or-path-p "computer vision"))
         "$HOME/glossaries/machine-learning.txt"
         "$HOME/glossaries/deep-learning.txt")
        ((or (istr-in-region-or-buffer-or-path-p "empirical"))
         "$HOME/glossaries/research.txt")
        ((or (istr-in-region-or-buffer-or-path-p "conditioning"))
         "$HOME/glossaries/reinforcement-learning.txt")
        ((or (istr-in-region-or-buffer-or-path-p "fixture"))
         "$HOME/glossaries/testing.txt")
        ((or (istr-in-region-or-buffer-or-path-p "Aragorn"))
         "$HOME/glossaries/lotr-lord-of-the-rings.txt")
        ((or (eat-in-buffer-or-path-p "ZooKeeper")
             (ieat-in-region-or-buffer-or-path-p "Apache")
             (ieat-in-region-or-buffer-or-path-p "tika"))
         "$HOME/glossaries/apache.txt")
        ((or (istr-in-region-or-buffer-or-path-p "Python")) "$HOME/glossaries/python.txt")
        ((or ;; (istr-in-region-or-buffer-or-path-p "expect")
          (istr-in-region-or-buffer-or-path-p "tcl")) "$HOME/glossaries/tcl.txt")
        ((or (istr-in-region-or-buffer-or-path-p "TypeScript")) "$HOME/glossaries/typescript.txt")
        ((or (istr-in-region-or-buffer-or-path-p "Dwarf Fortress")
             ;; Can't do this or LORT is full of symbols
             ;; (istr-in-region-or-buffer-or-path-p "Dwarf")
             )
         "$HOME/glossaries/dwarf-fortress.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "racket"))
         "$HOME/glossaries/racket.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "unison"))
         "$HOME/glossaries/unison.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "Kotlin")) "$HOME/glossaries/kotlin.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "git"))
         "$HOME/glossaries/git.txt")
        ((or (istr-in-region-or-buffer-or-path-p "Neural Network"))
         "$HOME/glossaries/deep-learning.txt")
        ((or (ieat-in-region-or-buffer-or-path-p "food")
             (ieat-in-region-or-buffer-or-path-p "cuisine")) "$HOME/glossaries/cooking.txt")
        ((or (istr-in-region-or-buffer-or-path-p "SQL"))
         "$HOME/glossaries/sql.txt")
        ((or (istr-in-region-or-buffer-or-path-p "sourcegraph"))
         "$HOME/glossaries/sourcegraph.txt"))))

(defun glossary-list-relevant-glossaries ()
  (append
   (cl-loop for fn in (list-all-glossary-files)
            when
            (istr-in-region-or-buffer-p (string-replace ".txt$" "" (basename fn)))
            collect fn)
   (-distinct
    (-flatten
     (cl-loop for tup in
              glossary-predicate-tuples
              collect
              (if (eval (car tup)) (cdr tup)))))))

(defun glossary-add-relevant-glossaries (&optional no-draw)
  (interactive)
  (add-glossaries-to-buffer (glossary-list-relevant-glossaries) no-draw))

(defsetface glossary-button-face
  '((t :foreground "#3fa75f"
       :background nil
       :weight bold
       :underline t))
  "Face for glossary buttons.")

(defsetface glossary-candidate-button-face
  '((t
     :foreground "#3f5fc7"
     ;; :foreground nil
     ;; :background "#000022"
     :weight bold
     :underline t))
  "Face for glossary candidate buttons.")

(define-button-type 'glossary-button 'follow-link t 'help-echo "Click to go to definition" 'face 'glossary-button-face)
(define-button-type 'glossary-candidate-button 'follow-link t 'help-echo "Click to add to glossary" 'face 'glossary-candidate-button-face)

(defun my-show-overlays-here ()
  (interactive)
  (new-buffer-from-string (pp (cl-loop for o in (overlays-at (point)) collect (sp--get-overlay-text o)))))

(defun my-show-button-paths-here ()
  (interactive)
  (new-buffer-from-string (pp (glossary-get-button-3-tuples-at (point)))))

(defun glossary-get-button-3-tuples-at (p)
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

(defun glossary-list-tuples (&optional fp)
  (-filter (lambda (e) (not (member (third e) glossary-blacklist)))
           (glossary-sort-tuples
            (if fp
                (my-eval-string (sn (concat "list-glossary-terms-for-elisp " (q fp))))
              (my-eval-string (sn "list-glossary-terms-for-elisp"))))))

(defun glossary-sort-tuples (tuples)
  (sort
   tuples
   (lambda (e1 e2) (< (length (third e1))
                      (length (third e2))))))

(defset glossary-term-3tuples (glossary-list-tuples))
(defset glossary-term-3tuples-global glossary-term-3tuples)
(defset glossary-candidate-3tuples nil)

(defun recalculate-glossary-3tuples ()
  (interactive)
  (defset-local glossary-term-3tuples (-distinct (flatten-once (cl-loop for fp in glossary-files collect (glossary-list-tuples fp))))))

(defun glossary-reload-term-3tuples ()
  (interactive)
  (defset glossary-term-3tuples (glossary-list-tuples))
  (defset glossary-term-3tuples-global glossary-term-3tuples))

(defset glossary-button-map
  (let ((map (make-sparse-keymap)))
    (define-key map [(control ?m)] 'push-button)
    (define-key map [double-mouse-1] 'push-button)
    (define-key map [mode-line mouse-2] 'push-button)
    (define-key map [header-line mouse-2] 'push-button)
    map)
  "Keymap used by buttons.")

(defun create-buttons-for-term (term beg end &optional glossarypath byteoffset buttontype)
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
                     'glossary-button-pressed)
           'type buttontype))))))

(defun make-buttons-for-glossary-terms (beg end &optional 3tuples buttontype)
  "Makes buttons for glossary terms found in this buffer."
  (interactive "r")
  (if (not buttontype)
      (setq buttontype 'glossary-button))

  (if (not 3tuples)
      (setq 3tuples
            (cond
             ((eq buttontype 'glossary-button) glossary-term-3tuples)
             ((eq buttontype 'glossary-candidate-button) glossary-candidate-3tuples))))

  (if (not beg)
      (let ((nlines (count-lines (point-min) (point-max))))
        (if (> nlines glossary-max-lines-for-entire-buffer-gen)
            (setq beg
                  (glossary-window-start)
                  end
                  (glossary-window-end))
          (setq beg
                (point-min)
                end
                (point-max)))))
  (cl-loop for termtuple in 3tuples do
           (create-buttons-for-term (third termtuple) beg end
                                    (first termtuple)
                                    (cadr termtuple)
                                    buttontype)))

(defun goto-byte (byteoffset)
  (interactive "nByte position: ")
  (goto-char (byte-to-position (+ byteoffset 1))))

(defun glossary-candidate-button-pressed (button)
  "When I press a glossary button, it should take me to the definition"
  (let* ((term (button-get-text button))
         (byteoffset (button-get button 'byteoffset))
         (start (button-start button))
         (glossarypath (button-get button 'glossarypath))
         (buttons-here (glossary-get-button-3-tuples-at start)))

    (if (< 1 (length buttons-here))
        (let* ((button-line (umn (fz (mnm (pp-map-line buttons-here))
                                     nil nil "glossary-candidate-button-pressed: ")))
               (button-tuple (if button-line
                                 (my-eval-string (concat "'" button-line))))
               (selected-button (if button-tuple
                                    (car (-filter (lambda (li) (and (equal (first button-tuple) (button-get li 'glossarypath))
                                                               (equal (cadr button-tuple) (button-get li 'byteoffset))
                                                               (equal (third button-tuple) (button-get li 'term))))
                                                  (overlays-at start))))))
          (if selected-button
              (progn
                (setq button selected-button)
                (setq term (button-get-text button))
                (setq byteoffset (button-get button 'byteoffset))
                (setq start (button-start button))
                (setq glossarypath (button-get button 'glossarypath))
                (setq buttons-here (glossary-get-button-3-tuples-at byteoffset)))
            (backward-char))))
    (cond
         ((equal current-prefix-arg (list 4)) (setq current-prefix-arg nil))
         ((not current-prefix-arg) (setq current-prefix-arg (list 4))))
    (with-current-buffer
        (add-to-glossary-file-for-buffer term nil (sn "oc" glossarypath)))))

(defun glossary-button-pressed (button)
  "When I press a glossary button, it should take me to the definition"
  ;; Get some properties of the button
  (let* ((term (button-get button 'term))
         (byteoffset (button-get button 'byteoffset))
         (start (button-start button))
         (glossarypath (button-get button 'glossarypath))
         (buttons-here (glossary-get-button-3-tuples-at start)))

    (if (< 1 (length buttons-here))
        (let* ((button-line (umn (fz (mnm (pp-map-line buttons-here))
                                     nil nil "glossary-button-pressed: ")))
               (button-tuple (if button-line
                                 (my-eval-string (concat "'" button-line))))
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
                (setq buttons-here (glossary-get-button-3-tuples-at byteoffset)))
            (backward-char))))
    (with-current-buffer
        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (find-file-other-window glossarypath)
          (find-file glossarypath))
      (goto-byte byteoffset)
      )))

(defun reload-glossary-and-generate-buttons (beg end)
  (interactive "r")
  (glossary-reload-term-3tuples)
  (generate-glossary-buttons-over-buffer beg end t))

(defun reload-glossary-reopen-and-generate-buttons (beg end)
  "DEPRECATED"
  (interactive "r")
  (glossary-reload-term-3tuples)
  (kill-buffer-and-reopen)
  (generate-glossary-buttons-over-buffer beg end))

(defun button-get-text (b)
  (if b
      (buffer-substring (button-start b) (button-end b))))

(defun list-glossary-files ()
  (s-lines (cl-sn "list-glossary-files" :chomp t)))
(defalias 'list-all-glossary-files 'list-glossary-files)

(defun other-glossaries-not-added-yet ()
  (let ((all-glossary-files (list-glossary-files)))
    (if (and (local-variable-p 'glossary-files) glossary-files)
        (-difference
         all-glossary-files
         glossary-files)
      all-glossary-files)))

(defun get-keyphrases-for-buffer (beg end)
  (interactive "r")

  (-filter-not-empty-string
   (let ((s (buffer-substring (glossary-window-start)
                              (glossary-window-end))))
     (s-lines (cl-sn "extract-keyphrases" :stdin s :chomp t)))))

(defun recalculate-glossary-candidate-3tuples (beg end)
  (interactive "r")
  (let* ((p (mnm (get-path-nocreate)))
         (tls (mapcar
               (lambda (s) (list p nil s))
               (-distinct
                (if glossary-term-3tuples
                    (let ((tl (mapcar 'downcase (mapcar 'third glossary-term-3tuples))))
                      (-filter
                       (lambda (s) (not (-contains? tl (downcase s))))
                       (get-keyphrases-for-buffer beg end)))
                  (get-keyphrases-for-buffer beg end))))))
    (if (not (use-region-p))
        (defset-local glossary-candidate-3tuples tls))
    tls))

(defun draw-glossary-buttons-and-maybe-recalculate (beg end &optional recalculate-tuples)
  (interactive "r")

  (if (not (or (derived-mode-p 'dired-mode)
               (derived-mode-p 'compilation-mode)
               (string-equal (buffer-name) "*button cloud*")
               (string-match (buffer-name) "^\\*untitled")))
      (progn
        (if (or
             recalculate-tuples
             (not (local-variable-p 'glossary-term-3tuples))
             (derived-mode-p 'eww-mode))
            (progn
              (recalculate-glossary-3tuples)
              (recalculate-glossary-error-3tuples)))

        (if (and
             (myrc-test "glossary_suggest_keyphrases")
             (or
              (derived-mode-p 'eww-mode)
              (derived-mode-p 'text-mode)
              (derived-mode-p 'org-brain-visualize-mode)
              (derived-mode-p 'sx-question-mode))
             (not (derived-mode-p 'yaml-mode)))
            (recalculate-glossary-candidate-3tuples beg end))

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

(defun append-glossary-files-locally (fps)
  ;; relevant-glossaries should override glossary-files when set
  ;; It's meant for the region, not the buffer
  (if (local-variable-p 'glossary-files)
      (defset-local glossary-files (-union glossary-files fps))
    (defset-local glossary-files fps)))

(defun add-glossaries-to-buffer (fps &optional no-draw)
  (interactive (list (-filter-not-empty-string (s-lines (umn (fz (mnm (list2str (other-glossaries-not-added-yet)))))))))
  (if fps
      (save-excursion
        (progn
          (append-glossary-files-locally fps)

          (if (not no-draw)
              (draw-glossary-buttons-and-maybe-recalculate nil nil))))))

(defun test-f (fp)
  (eq (progn (sn (concat "test -f " (q fp)))
             (string-to-int b_exit_code))
      0))

(defun test-d (fp)
  (eq (progn (sn (concat "test -d " (q fp)))
             (string-to-int b_exit_code))
      0))

(defun glossary-path-p (&optional fp)
  (if (not fp)
      (setq fp (get-path-nocreate)))
  (if fp
      (or (string-match "/glossary.txt$" fp)
          (string-match "glossaries/.*\\.txt$" fp)
          (string-match "/home/shane/notes/ws/.*/words.txt$" fp)
          (string-match "/home/shane/notes/ws/.*/phrases.txt$" fp))))

(defset glossary-imenu-generic-expression
  '(("" "^\\([a-zA-Z0-9].+\\)$" 1)))
(defun glossary-imenu-configure ()
  (interactive)
  (if (glossary-path-p)
      (setq imenu-generic-expression glossary-imenu-generic-expression)))
(add-hook 'text-mode-hook 'glossary-imenu-configure)

(defun button-imenu ()
  (interactive)
  (let ((imenu-create-index-function #'button-cloud-create-imenu-index))
    (helm-imenu)))
(defalias 'glossary-button-imenu 'button-imenu)

(defun byte-to-marker (byte)
  (set-marker (make-marker) byte))

(defun generate-glossary-buttons-over-region (beg end &optional clear-first force)
  (interactive "r")
  (if glossary-keep-tuples-up-to-date
      (glossary-reload-term-3tuples))

  (if (not (use-region-p))
      (generate-glossary-buttons-over-buffer beg end clear-first force)
    (progn
      (if clear-first (remove-glossary-buttons-over-region beg end))

      (let ((glossary-files)
            (glossary-error-files))
        (glossary-add-relevant-glossaries t)
        (glossary-error-add-relevant-glossaries t)
        (save-excursion
          (let ((glossary-files
                 (mu '("$NOTES/ws/english/words.txt")))
                (glossary-error-files nil))
            (mylog (draw-glossary-buttons-and-maybe-recalculate beg end))))))))

(defun generate-glossary-buttons-over-buffer-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    res))
(advice-add 'generate-glossary-buttons-over-buffer :around #'generate-glossary-buttons-over-buffer-around-advice)
(advice-remove 'generate-glossary-buttons-over-buffer #'generate-glossary-buttons-over-buffer-around-advice)

(defun generate-glossary-buttons-over-buffer (beg end &optional clear-first force)
  (interactive "r")

  (if force (defset-local glossary-force-on t))

  (if (use-region-p)
      (generate-glossary-buttons-over-region beg end clear-first force)
    (unless (or
             (string-equal (get-path-nocreate) "/home/shane/var/smulliga/source/git/config/emacs/config/my-glossary.el")
             (and (not (myrc-test "auto_glossary_enabled"))
                  (not (and (variable-p 'glossary-force-on) glossary-force-on))))

      (if clear-first (remove-all-glossary-buttons))

      (glossary-add-relevant-glossaries t)
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
                                (or (test-f pdf-fp)
                                    (test-f PDF-fp))))
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
                           (if (test-f fp)
                               (append-glossary-files-locally (list fp)))))
                        ((str-match-p "Lord of the Rings" (get-path-nocreate))
                         (progn
                           (append-glossary-files-locally (list "$HOME/glossaries/lotr-lord-of-the-rings.txt"))))
                        ((glossary-path-p (get-path-nocreate))
                         (append-glossary-files-locally (list (get-path-nocreate))))))

              (draw-glossary-buttons-and-maybe-recalculate beg end)))))))

(defmacro gl-beg-end (&rest body)
  `(let* ((gl-beg (if mark-active
                      (min (point) (mark))
                    (point-min)))
          (gl-end (if mark-active
                      (max (point) (mark))
                    (point-max)))
          (nlines (count-lines gl-beg gl-end))
          (gl-use-sliding-window (> nlines glossary-max-lines-for-entire-buffer-gen))
          (gl-draw-start (or
                          gl-beg
                          (if gl-use-sliding-window
                              (glossary-window-start)
                            (point-min))))
          (gl-draw-end (or
                        gl-end
                        (if gl-use-sliding-window
                            (glossary-window-end)
                          (point-max)))))
     (progn
       ,@body)))

(defun generate-glossary-buttons-manually ()
  (interactive)

  (if (derived-mode-p 'term-mode)
      (with-current-buffer
          (new-buffer-from-tmux-pane-capture t)
        (generate-glossary-buttons-manually))
    (gl-beg-end
     (if (use-region-p)
         (generate-glossary-buttons-over-region gl-beg gl-end nil t)
       (generate-glossary-buttons-over-buffer gl-end gl-end nil t)))))

(defun wordnut--lookup-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (run-buttonize-hooks)
    res))
(advice-add 'wordnut--lookup :around #'wordnut--lookup-around-advice)

(defun after-emacs-loaded-add-hooks-for-glossary ()
  (add-hook 'find-file-hooks 'run-buttonize-hooks t)
  (remove-hook 'new-buffer-hooks 'redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
  (restart-glossary))

(add-hook 'emacs-startup-hook 'after-emacs-loaded-add-hooks-for-glossary t)

(defun glossary-next-button-fast (pos)
  (let* ((nextpos (next-single-char-property-change pos 'button))
         (nextbutton (button-at nextpos)))
    (if (not (and (not nextbutton) (= (button-start nextbutton) pos)))
        (progn
          (while (or (not nextbutton) (= (button-start nextbutton) pos))
            (progn
              (setq nextpos (next-single-char-property-change nextpos 'button))
              (setq nextbutton (button-at nextpos))))
          nextbutton))))

(defun next-button-of-face (face)
  "Go to the next button which has the given face"
  (let ((b nil)
        (pos nil))
    (save-excursion
      (let ((cand (next-button (point)))
            (bface (button-get cand 'face)))
        (while (and cand (eq bface 'glossary-button-face))
          (setq cand (next-button (point))))
        (setq pos (point))
        cand))
    (goto-char pos)))

(defun buttons-collect (&optional face)
  "Collect the positions of visible links in the current `help-mode' buffer."

  (let* ((candidates)
         (p (glossary-window-start))
         ;; (lp p)
         (b (button-at p))
         (e (or (and b (button-end b)) p))
         (le e))
    (if (and b (if face (eq (button-get b 'face) face)
                 t))
        (push (cons (button-label b) p) candidates))
    (while (and (setq b (next-button e))
                (setq p (button-start b))
                (setq e (button-end b))
                (< p (glossary-window-end)))
      (if (and b (if face (eq (button-get b 'face) face)
                   t))
          (push (cons (button-label b) p) candidates)
        (progn
          (setq e (+ (button-start b) 1))
          (if (<= e le)
              (setq e (+ 1 le)))
          (setq le e))))
    (nreverse candidates)))

(defun widgets-collect ()
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

(defun glossary-buttons-collect ()
  (append (buttons-collect 'glossary-button-face)
          (buttons-collect 'glossary-candidate-button-face)
          (buttons-collect 'glossary-error-button-face)))

(defun ace-link-glossary-button ()
  (interactive)
  (let ((pt (avy-with ace-link-help
              (avy-process
               (mapcar #'cdr (glossary-buttons-collect))
               (avy--style-fn avy-style)))))
    (ace-link--help-action pt)))

(defun goto-glossary-definition (term)
  (interactive (list
                (fz (sn "list-glossary-terms")
                    (if mark-active (downcase (my/thing-at-point)))
                    nil
                    "goto-glossary-definition: ")))

  (if glossary-keep-tuples-up-to-date
      (glossary-reload-term-3tuples))

  (let* ((tups (-filter (lambda (e) (string-equal (car (last e)) term)) glossary-term-3tuples-global))
         (button-line (if tups
                          (umn (fz (mnm (pp-map-line tups)) nil nil nil nil t))))
         (button-tuple (if button-line
                           (my-eval-string (concat "'" button-line)))))
    (if button-tuple
        (progn
          (deactivate-mark)
          (with-current-buffer
              (if (>= (prefix-numeric-value current-prefix-arg) 4)
                  (find-file-other-window (first button-tuple))
                (find-file (first button-tuple)))
            (goto-byte (cadr button-tuple))))
      (message "word not found"))
    nil))

(defun goto-glossary-definition-noterm (term)
  (interactive (list (fz (sn "list-glossary-terms")
                         ""
                         nil
                         "goto-glossary-definition-noterm: ")))

  (goto-glossary-definition term))

(defun go-to-glossary-file-for-buffer (&optional take-first)
  (interactive)
  (mu (find-file (or (and (not (>= (prefix-numeric-value current-prefix-arg) 4))
                   (local-variable-p 'glossary-files)
                   (if take-first
                       (car glossary-files)
                     (umn (fz (mnm (list2str glossary-files))
                              nil
                              nil
                              "go-to-glossary-file-for-buffer: "))))
              (umn (fz (mnm (list2str (list-glossary-files)))
                       nil
                       nil
                       "go-to-glossary-file-for-buffer: "))))))

(defun lm-define (term &optional prepend-lm-warning topic)
  (interactive)
  (let* ((final-topic
          (if topic
              (concat " in the context of " topic)
            ""))
         (def
          (pf-define-word (concat term final-topic))))

    (if (sor def)
        (progn
          (if prepend-lm-warning
              (setq def (concat "NLG: " def)))
          (if (interactive-p)
              (etv def)
            def)))))

(define-key global-map (kbd "H-i") 'add-glossaries-to-buffer)
(define-key global-map (kbd "H-Y I") 'add-glossaries-to-buffer)

(define-key global-map (kbd "H-d") 'generate-glossary-buttons-manually)
(define-key global-map (kbd "H-Y d") 'generate-glossary-buttons-manually)
(define-key global-map (kbd "H-Y F") 'go-to-glossary-file-for-buffer)
(define-key global-map (kbd "H-Y A") 'add-to-glossary-file-for-buffer)
(define-key global-map (kbd "H-Y G") 'glossary-reload-term-3tuples)
(define-key global-map (kbd "H-h") 'goto-glossary-definition)
(define-key global-map (kbd "H-Y H") 'goto-glossary-definition)
(define-key global-map (kbd "H-Y L") 'go-to-glossary)
(define-key global-map (kbd "<help> y") 'goto-glossary-definition)
(define-key global-map (kbd "<help> C-y") 'go-to-glossary)
(define-key global-map (kbd "H-y") 'go-to-glossary-file-for-buffer)

(define-key selected-keymap (kbd "A") 'add-to-glossary-file-for-buffer)

(defun remove-glossary-buttons-over-region (beg end)
  (interactive "r")
  (remove-overlays beg end 'face 'glossary-button-face))

(defun remove-all-glossary-buttons ()
  (interactive "r")
  (message "(remove-all-glossary-buttons)")
  (remove-glossary-buttons-over-region (point-min) (point-max)))
(defalias 'clear-glossary-buttons 'remove-all-glossary-buttons)

(defset my-buttonize-hook '())

(add-hook 'my-buttonize-hook 'redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
(add-hook 'my-buttonize-hook 'make-buttons-for-all-filter-cmds)

(defun run-buttonize-hooks ()
  (interactive)
  (run-hooks 'my-buttonize-hook))

(defun Info-find-node-2-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (run-buttonize-hooks)
    res))
(advice-add 'Info-find-node-2 :around #'Info-find-node-2-around-advice)

(defun redraw-glossary-buttons-when-window-scrolls-or-file-is-opened ()
  (interactive)
  (message-no-echo (concat "redraw-glossary scroll " (get-path nil t)))
  (unless (or
           (not (myrc-test "auto_glossary_enabled"))
           (derived-mode-p 'dired-mode)
           (derived-mode-p 'compilation-mode)
           (string-equal (buffer-name) "*button cloud*")
           (string-match (buffer-name) "^\\*untitled")
           (and (timerp draw-glossary-buttons-timer)
                (= glossary-timer-current-window-start (glossary-window-start))
                (string= glossary-timer-current-buffer-name (buffer-name))))
    (defset glossary-timer-current-window-start (glossary-window-start))
    (defset glossary-timer-current-buffer-name (buffer-name))
    (if (or (derived-mode-p 'prog-mode)
            (derived-mode-p 'text-mode)
            (derived-mode-p 'conf-mode)
            (derived-mode-p 'org-brain-visualize-mode)
            (derived-mode-p 'Info-mode)
            (derived-mode-p 'eww-mode)
            (derived-mode-p 'fundamental-mode)
            (derived-mode-p 'Man-mode)
            (derived-mode-p 'special-mode))
        (generate-glossary-buttons-over-buffer nil nil t))))

(defvar draw-glossary-buttons-timer nil)

(defun toggle-draw-glossary-buttons-timer (&optional newstate)
  (interactive)
  (defset glossary-timer-current-window-start (glossary-window-start))
  (defset glossary-timer-current-buffer-name (buffer-name))

  (cond ((not (timerp draw-glossary-buttons-timer))
         (if (interactive-p)
             (progn (generate-glossary-buttons-over-buffer nil nil t)
                    (setq draw-glossary-buttons-timer (run-with-idle-timer glossary-idle-time 1 'run-buttonize-hooks))
                    (message "glossary timer created")
                    t)
           nil))
        ((eq -1 newstate)
         (progn
           (cancel-timer draw-glossary-buttons-timer)
           (message "glossary timer stopped")
           nil))
        ((eq 1 newstate)
         (progn
           (cancel-timer draw-glossary-buttons-timer)
           (progn (generate-glossary-buttons-over-buffer nil nil t)
                  (setq draw-glossary-buttons-timer (run-with-idle-timer glossary-idle-time 1 'run-buttonize-hooks))
                  t)
           (message "glossary timer restarted")))
        (t
         (if (interactive-p)
             (if (-contains? timer-idle-list draw-glossary-buttons-timer)
                 (toggle-draw-glossary-buttons-timer -1)
               (toggle-draw-glossary-buttons-timer 1))
           (-contains? timer-idle-list draw-glossary-buttons-timer)))))

(defun restart-glossary ()
  (interactive)
  (toggle-draw-glossary-buttons-timer t))

(defun glossary-add-link (term fp)
  (interactive (list (read-string-hist "glossary term: " (my/thing-at-point))
                     (umn (fz (mnm (list2str (glob "/home/shane/glossaries/*.txt")))
                              "$HOME/glossaries/"
                              nil "glossary-add-link: "))))
  (let ((code
         `((or (istr-in-region-or-buffer-or-path-p ,term))
           ,(mnm fp))))
    (j 'glossary-predicate-tuples)
    (special-lispy-different)
    (-dotimes 3 'backward-char)
    (newline)
    (indent-for-tab-command)
    (insert (pp-oneline code))))

(define-key selected-keymap (kbd "L") 'glossary-add-link)

(defun glossary-draw-after-advice (proc &rest args)
  (let ((res (apply proc args)))
    (generate-glossary-buttons-over-buffer nil nil t)
    (redraw-glossary-buttons-when-window-scrolls-or-file-is-opened)
    res))

(advice-add 'Man-bgproc-sentinel :around #'glossary-draw-after-advice)
(advice-remove 'Man-getpage-in-background #'Man-notify-when-ready-around-advice)

(define-key global-map (kbd "H-B") 'goto-glossary-definition)

(defun generate-glossary-term-and-definition (term)
  (interactive))

(define-key selected-keymap (kbd "Z g g") 'generate-glossary-term-and-definition)

(defun is-glossary-file (&optional fp)
  (setq fp (or fp (get-path)))
  (or
   (string-match "glossary\\.txt$" fp)
   (string-match "words\\.txt$" fp)
   (string-match "glossaries/.*\\.txt$" fp)))

(require 'link-hint)

(defun glossary-button-at-point ()
  (let ((p (point))
        (b (button-at-point)))
    (if (and
         b
         (eq (button-get b 'face) 'glossary-button-face))
        b
      nil))
  (button-at-point))
(defalias 'glossary-button-at-point-p 'glossary-button-at-point)

(defun my-button-get-link (b)
  (cond
   ((eq (button-get b 'face) 'glossary-button-face)
    (concat "[[y:" (button-get-text b) "]]"))
   (t nil)))

(defun my-button-copy-link-at-point ()
  (interactive)
  (let* ((url (get-text-property (point) 'shr-url)))
    (setq url
          (cond
           (url url)
           ((button-at-point) (my-button-get-link (button-at-point)))))
    (xc (message url))))

(defun ace-link-copy-button-link ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (buttons-collect))
     (avy--style-fn avy-style)))
  (let* ((b (button-at-point))
         (lambda (my-button-get-link b)))
    (if l
        (xc l))))