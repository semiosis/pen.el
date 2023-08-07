;; This is a new variable, nonexistent in the original package
(defcustom default-bible-mode-book-module
  "NASB"
  "Default book module for Diatheke to query."
  :type '(choice (const :tag "None" nil)
                 (string :tag "Module abbreviation (e.g. \"KJV\")"))
  :group 'bible-mode)

(defun bible-open (&optional global-chapter verse module ref)
  "Creates and opens a `bible-mode' buffer"
  (interactive)
  (let
      (
       (buf (get-buffer-create (generate-new-buffer-name "*bible*"))))
    (set-buffer buf)
    (if (not module)
        ;; (setq bible-mode-book-module module)
        (setq module default-bible-mode-book-module))

    (bible-mode)

    (setq bible-mode-book-module module)


    (bible-mode--set-global-chapter (or global-chapter 1) verse)
    (set-window-buffer (get-buffer-window (current-buffer)) buf)

    (if (and ref
             (sor ref))
        (bible-mode-lookup ref))))

(defun bible-open-version (version)
  (interactive (list (completing-read "Module: " (bible-mode--list-biblical-modules))))
  (if (not version)
      (setq version "NASB"))

  (let ((bible-mode-book-module version))
    (bible-open nil nil version)))

;; (defun bible-mode-fun-around-advice (proc &rest args)
;;   (let ((res (apply proc args)))
;;     res))
;; (advice-add 'bible-mode--exec-diatheke :around #'bible-mode-fun-around-advice)
;; (advice-remove 'bible-mode--exec-diatheke #'bible-mode-fun-around-advice)

(defun bible-mode--open-search(query searchmode &optional module)
  "Opens a search buffer of QUERY using SEARCHMODE."
  (let
      (
       (buf (get-buffer-create (concat "*bible-search-" (downcase (or module default-bible-mode-book-module)) "-" query "*"))))
    (set-buffer buf)
    (bible-search-mode)
    (setq bible-mode-book-module (or module default-bible-mode-book-module))
    ;; (lo module)
    (bible-mode--display-search query searchmode bible-mode-book-module)
    (pop-to-buffer buf nil t)))

(defun bible-mode--display-search(query searchmode &optional module)
  "Renders results of search QUERY from SEARHCMODE"
  (setq buffer-read-only nil)
  (erase-buffer)

  (if (catch 'no-results (let* (
                                (term query)
                                (result (string-trim (replace-regexp-in-string "Entries .+?--" "" (bible-mode--exec-diatheke query nil "plain" searchmode module))))
                                (match 0)
                                (matchstr "")
                                (verses "")
                                fullverses)
                           (if (equal result (concat "none (" bible-mode-book-module ")"))
                               (throw 'no-results t))
                           (while match
                             (setq match (string-match ".+?:[0-9]?[0-9]?"
                                                       result (+ match (length matchstr)))
                                   matchstr (match-string 0 result))
                             (if match
                                 (setq verses (concat verses (replace-regexp-in-string ".+; " "" matchstr) ";"))))

                           (setq match 0)
                           (setq fullverses (bible-mode--exec-diatheke verses nil nil nil module))

                           (insert fullverses)
                           (let* (
                                  (html-dom-tree (libxml-parse-html-region (point-min) (point-max))))
                             (erase-buffer)
                             (bible-mode--insert-domnode-recursive
                              (dom-by-tag html-dom-tree 'body) html-dom-tree nil t
                              term)

                             (goto-char (point-min))
                             (while (search-forward (concat "(" bible-mode-book-module ")") nil t)
                               (replace-match "")))))
      (insert (concat "No results found." (if (equal searchmode "lucene") " Verify index has been build with mkfastmod."))))

  (setq mode-name (concat "Bible Search (" bible-mode-book-module ")"))
  (setq buffer-read-only t)
  (setq-local bible-mode-search-query query)
  (setq-local bible-mode-search-mode searchmode)
  (goto-char (point-min)))

(defun nasb ()
  (interactive)
  (bible-open-version "NASB"))

(defun kjv ()
  (interactive)
  (bible-open-version "KJV"))

(defun bsb ()
  (interactive)
  (bible-open-version "engbsb2020eb"))

;; TODO But I also need to grep for all of these, when looking for verse references
;; https://www.logos.com/bible-book-abbreviations

;; I need to make this efficient
;; All this is for currently is to put into the book/verse format
;; to the name of the book which xiphos knows.
;; (xc (lines2str (-flatten bible-book-map-names)))

(defset bible-book-map-names
  ;; Used to translate any of the latter elements into the first element of each tuple.
  ;; I should also make I, 1, First, 2, 3, etc part of the generic regex.
  ;; I still need to be able to translate them. So I still need this.
  '(("Genesis" "Gen" "Ge" "Gn")
    ("Exodus" "Ex" "Exod" "Exo")
    ("Leviticus" "Lev" "Le" "Lv")
    ("Numbers" "Num" "Nu" "Nm" "Nb")
    ("Deuteronomy" "Deut" "De" "Dt")
    ("Joshua" "Josh" "Jos" "Jsh")
    ("Judges" "Judg" "Jdg" "Jg" "Jdgs")
    ("Ruth" "Rth" "Ru")
    ("I Samuel" "1 Samuel" "1 Sam" "1 Sm" "1 Sa" "I Sam" "I Sa" "1Sam" "1Sa" "1S" "1st Samuel" "1st Sam" "First Samuel" "First Sam")
    ("II Samuel" "2 Samuel" "2 Sam" "2 Sm" "2 Sa" "II Sam" "II Sa" "2Sam" "2Sa" "2S" "2nd Samuel" "2nd Sam" "First Samuel" "First Sam")
    ("I Kings" "1 Kings" "1 Kgs" "1 Ki" "1Kgs" "1Kin" "1Ki" "1K" "1st Kings" "1st Kgs" "First Kings" "First Kgs")
    ("II Kings" "2 Kings" "2 Kgs" "2 Ki" "2Kgs" "2Kin" "2Ki" "2K" "2nd Kings" "2nd Kgs" "Second Kings" "Second Kgs")
    ("I Chronicles" "1 Chronicles" "1 Chron" "1 Chr" "1 Ch" "1Chron" "1Chr" "I Chron" "I Chr" "I Ch" "1st Chronicles" "1st Chron" "First Chronicles" "First Chron")
    ("II Chronicles" "2 Chronicles" "2 Chron" "2 Chr" "2 Ch" "2Chron" "2Chr" "II Chron" "II Chr" "II Ch" "2nd Chronicles" "2nd Chron" "Second Chronicles" "Second Chron")
    ("Ezra" "Ezr" "Ez")
    ("Nehemiah" "Neh" "Ne")
    ("Esther" "Est" "Esth" "Es")
    ("Job" "Jb")
    ("Psalms" "Ps" "psalm" "Psalm" "Pslm" "Psa" "Psm" "Pss")
    ("Proverbs" "Prov" "Pro" "Prv" "Pr")
    ("Ecclesiastes" "Eccles" "Eccle" "Ecc" "Ec" "Qoh")
    ("Song of Solomon" "Song" "Song of Songs" "SOS" "So" "Canticle of Canticles" "Canticles" "Cant")
    ("Isaiah" "Isa" "Is")
    ("Jeremiah" "Je" "Jr")
    ("Lamentations" "Lam" "La")
    ("Ezekiel" "Ezek" "Eze" "Ezk")
    ("Daniel" "Dan" "Da" "Dn")
    ("Hosea" "Hos" "Ho")
    ("Joel" "Jl")
    ("Amos" "Am")
    ("Obadiah" "Obad" "Ob")
    ("Jonah" "Jnh" "Jon")
    ("Micah" "Mic" "Mc")
    ("Nahum" "Nah" "Na")
    ("Habakkuk" "Hab" "Hb")
    ("Zephaniah" "Zeph" "Zep" "Zp")
    ("Haggai" "Hag" "Hg")
    ("Zechariah" "Zech" "Zec" "Zc")
    ("Malachi" "Mal" "Ml")
    ("Matthew" "Matt" "Mt")
    ("Mark" "Mrk" "Mar" "Mk" "Mr")
    ("Luke" "Luk" "Lk")
    ("John" "Joh" "Jhn" "Jn")
    ("Acts" "Act" "Ac")
    ("Romans" "Rom" "Ro" "Rm")
    ("I Corinthians" "1 Corinthians" "1 Cor" "1 Co" "I Cor" "I Co" "1Cor" "1Co" "1Corinthians" "1st Corinthians" "First Corinthians")
    ("II Corinthians" "2 Corinthians" "2 Cor" "2 Co" "II Cor" "II Co" "2Cor" "2Co" "2Corinthians" "2nd Corinthians" "Second Corinthians")
    ("Galatians" "Gal" "Ga")
    ("Ephesians" "Eph" "Ephes")
    ("Philippians" "Phil" "Php" "Pp")
    ("Colossians" "Col" "Co")
    ("I Thessalonians" "1 Thess" "1 Thes" "1 Th" "1 Thessalonians" "I Thess" "I Thes" "I Th" "1Thessalonians" "1Thess" "1Thes" "1Th" "1st Thessalonians" "1st Thess" "First Thessalonians" "First Thess")
    ("II Thessalonians" "2 Thess" "2 Thes" "2 Th" "2 Thessalonians" "II Thess" "II Thes" "II Th" "2Thessalonians" "2Thess" "2Thes" "2Th" "2nd Thessalonians" "2nd Thess" "Second Thessalonians" "Second Thess")
    ("I Timothy" "1 Timothy" "1 Tim" "1 Ti" "I Timothy" "I Tim" "I Ti" "1Timothy" "1Tim" "1Ti" "1st Timothy" "1st Tim" "First Timothy" "First Time")
    ("II Timothy" "2 Timothy" "2 Tim" "2 Ti" "II Timothy" "II Tim" "II Ti" "2Timothy" "2Tim" "2Ti" "2nd Timothy" "2nd Tim" "Second Timothy" "Second Time")
    ("Titus" "Tit"
     ;; "ti"
     )
    ("Philemon" "Philem" "Phm" "Pm")
    ("Hebrews" "Heb")
    ("James" "Jas" "Jm")
    ("I Peter" "1 Peter" "1 Pet" "1 Pe" "1 Pt" "1 P" "I Pet" "I Pt" "I Pe" "1Peter" "1Pet" "1Pe" "1Pt" "1P" "I Peter" "1st Peter" "First Peter")
    ("II Peter" "2 Peter" "2 Pet" "2 Pe" "2 Pt" "2 P" "II Pet" "II Pt" "II Pe" "2Peter" "2Pet" "2Pe" "2Pt" "2P" "II Peter" "2nd Peter" "Second Peter")
    ("I John" "1 John" "1 Jhn" "1 Jn" "1 J" "1John" "1Jhn" "1Joh" "1Jn" "1Jo" "1st John" "First John")
    ("II John" "2 John" "2 Jhn" "2 Jn" "2 J" "2John" "2Jhn" "2Joh" "2Jn" "2Jo" "2nd John" "Second John")
    ("III John" "3 John" "3 Jhn" "3 Jn" "3 J" "3John" "3Jhn" "3Joh" "3Jn" "3Jo" "3rd John" "Third John")
    ("Jude" "Jud" "Jd")
    ("Revelation of John" "Revelation" "Rev" "Re")))

(defun bible-canonicalise-ref (ref &optional nilfailure)
  (setq ref (esed "\\.$" "" ref))
  (cl-loop for tp in bible-book-map-names
           until ;; (member ref (cdr tp))
           (member ref tp)
           finally return
           (if ;; (member ref (cdr tp))
               (member ref tp)
               (car tp)
             (if nilfailure
                 nil
               ref))))

;; TODO Generate this list
;; TODO Also have a map which translates into these
(defvar bible-mode-book-chapters
  '(("Genesis" 50)
    ("Exodus" 40)
    ("Leviticus" 27)
    ("Numbers" 36)
    ("Deuteronomy" 34)
    ("Joshua" 24)
    ("Judges" 21)
    ("Ruth" 4)
    ("I Samuel" 31)
    ("II Samuel" 24)
    ("I Kings" 22)
    ("II Kings" 25)
    ("I Chronicles" 29)
    ("II Chronicles" 36)
    ("Ezra" 10)
    ("Nehemiah" 13)
    ("Esther" 10)
    ("Job" 42)
    ("Psalms" 150)
    ("Proverbs" 31)
    ("Ecclesiastes" 12)
    ("Song of Solomon" 8)
    ("Isaiah" 66)
    ("Jeremiah" 52)
    ("Lamentations" 5)
    ("Ezekiel" 48)
    ("Daniel" 12)
    ("Hosea" 14)
    ("Joel" 3)
    ("Amos" 9)
    ("Obadiah" 1)
    ("Jonah" 4)
    ("Micah" 7)
    ("Nahum" 3)
    ("Habakkuk" 3)
    ("Zephaniah" 3)
    ("Haggai" 2)
    ("Zechariah" 14)
    ("Malachi" 4)
    ("Matthew" 28)
    ("Mark" 16)
    ("Luke" 24)
    ("John" 21)
    ("Acts" 28)
    ("Romans" 16)
    ("I Corinthians" 16)
    ("II Corinthians" 13)
    ("Galatians" 6)
    ("Ephesians" 6)
    ("Philippians" 4)
    ("Colossians" 4)
    ("I Thessalonians" 5)
    ("II Thessalonians" 3)
    ("I Timothy" 6)
    ("II Timothy" 4)
    ("Titus" 3)
    ("Philemon" 1)
    ("Hebrews" 13)
    ("James" 5)
    ("I Peter" 5)
    ("II Peter" 3)
    ("I John" 5)
    ("II John" 1)
    ("III John" 1)
    ("Jude" 1)
    ("Revelation of John" 22))
  "List of books in the Bible paired with their number of chapters.")

(defun bible-get-text-here ()
  ;; Here, use scrape-bible-references

  (let* ((found
          (pen-str2list (pen-snc "scrape-bible-references | pen-sort line-length-desc" (thing-at-point 'line t))))
         (matched
          (-filter 'looking-at-p found)))

    (cond
     (matched (car matched))
     (found (car found))
     (t (thing-at-point 'line t)))))

(defun bible-mode-lookup (&optional text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (bible-get-text-here)))

  (setq text (or text (bible-get-text-here)))

  ;; (mapcar 'car bible-mode-book-chapters)

  (let* ((ot text)

         (maybebook
          (bible-canonicalise-ref ot t))

         (text
          (if maybebook
              (concat maybebook " 1")
            text))

         (text (cond
                ((re-match-p ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:" text)
                 text)
                ((re-match-p ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?" text)
                 (concat (match-string 0 text) ":"))
                ((re-match-p ".+ [0-9]?[0-9]?[0-9]?:" text)
                 (concat text "1:"))
                ((re-match-p ".+ [0-9]?[0-9]?[0-9]?" text)
                 (concat text ":1:"))
                ((re-match-p ".+ " text)
                 (concat text "1:1:"))
                ((re-match-p ".+" text)
                 (concat text " 1:1:"))
                (t text)))

         book
         chapter
         verse)

    (string-match ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:" text)
    (setq text (match-string 0 text))

    (string-match " [0-9]?[0-9]?[0-9]?:" text)
    (setq chapter (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))

    (string-match ":[0-9]?[0-9]?[0-9]?" text)
    (setq verse (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))

    (setq book
          (bible-canonicalise-ref
           (replace-regexp-in-string "[ ][0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:$" "" text)))

    (if (not (major-mode-p 'bible-mode))
        (setq bible-mode-book-module default-bible-mode-book-module))

    (tryelse
     (bible-open (+ (bible-mode--get-book-global-chapter book) (string-to-number chapter))
                 (string-to-number verse)
                 bible-mode-book-module)
     (error "Error. Incorrect Bible reference?"))))

(defun bible-search-mode-get-search ()
  (interactive)
  (cmd-nice
   (downcase bible-mode-book-module)
   "-s"
   bible-mode-search-query))

(defun bible-search-mode-copy-search ()
  (interactive)
  (xc (bible-search-mode-get-search)))

(defun bible-mode-get-link (&optional text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (thing-at-point 'line t)))
  
  (setq text (or text (thing-at-point 'line t)))

  (if (and
       (>= (prefix-numeric-value current-prefix-arg) 4)
       (major-mode-p 'bible-search-mode))
      (bible-search-mode-copy-search)
    (progn
      (setq text (concat text ":"))
      (let* (
             book
             chapter
             verse)
        (string-match ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:" text)
        (setq text (match-string 0 text))

        (string-match " [0-9]?[0-9]?[0-9]?:" text)
        (setq chapter (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))

        (string-match ":[0-9]?[0-9]?[0-9]?" text)
        (setq verse (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))
        (setq book (replace-regexp-in-string "[ ][0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:$" "" text))

        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (concat "[[bible:" book " " chapter ":" verse "]]")
          (concat book " " chapter ":" verse))))))

(defun bible-mode-copy-link (text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (thing-at-point 'line t)))

  (xc (bible-mode-get-link text)))

(defun bible-mode--display(&optional verse)
  "Renders text for `bible-mode'"
  (interactive)
  (setq buffer-read-only nil)
  (erase-buffer)

  (insert (bible-mode--exec-diatheke (concat "Genesis " (number-to-string bible-mode-global-chapter)) nil nil nil bible-mode-book-module))

  (let* (
         (html-dom-tree (libxml-parse-html-region (point-min) (point-max))))
    (erase-buffer)
    (bible-mode--insert-domnode-recursive (dom-by-tag html-dom-tree 'body) html-dom-tree)
    (goto-char (point-min))
    (while (search-forward (concat "(" bible-mode-book-module ")") nil t)
      (replace-match "")))

  (setq mode-name (concat "Bible (" bible-mode-book-module ")"))
  (setq buffer-read-only t)
  (goto-char (point-min))
  ;; (tv (concat ":" (number-to-string verse) ": "))
  (if verse
      (progn
        ;; Can't use ": " because sometimes like with Psalms 40:1
        ;; there is no space
        (goto-char (string-match (regexp-opt `(,(concat ":" (number-to-string verse) ":"))) (buffer-string)))
        (beginning-of-line))))

;; nadvice - proc is the original function, passed in. do not modify
(defun bible-mode--display-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (pen-generate-glossary-buttons-manually)
    res))
(advice-add 'bible-mode--display :around #'bible-mode--display-around-advice)
;; (advice-remove 'bible-mode--display #'bible-mode--display-around-advice)


;; TODO Make it so God's names are all highlighted by passing each bit of text through a matcher?
(defun bible-mode--insert-domnode-recursive (node dom &optional iproperties notitle query)
  "Recursively parses a domnode from `libxml-parse-html-region''s usage on text
produced by `bible-mode-exec-diatheke'. Outputs text to active buffer with properties."
  ;; (lo node)
  ;; (lo (dom-tag node))
  ;; (lo (dom-text node))
  
  (if (equal (dom-tag node) 'divinename)
      (progn
        ;; (lo node)
        (setq iproperties (plist-put iproperties 'divinename t))))

  ;; (if (equal (dom-text node) query)
  ;;     (setq iproperties (plist-put iproperties 'jesus t)))
  
  (if (equal (dom-attr node 'who) "Jesus")
      (setq iproperties (plist-put iproperties 'jesus t)))

  (if (and (not notitle) (equal (dom-tag node) 'title)) ;;newline at start of title (i.e. those in Psalms)
      (insert "\n"))

  (dolist (subnode (dom-children node))
    (if (and notitle (equal (dom-tag node) 'title))
        (return))

    ;; (lo subnode)

    (if (stringp subnode)
        (progn
          (let* (
                 (verse-start (string-match ".+?:[0-9]?[0-9]?[0-9]?:" subnode))
                 verse-start-text
                 verse-match)
            (if verse-start
                (setq verse-match (string-trim (match-string 0 subnode))
                      verse-start-text (string-trim-left (substring subnode verse-start (length subnode)))
                      subnode (concat (substring subnode 0 verse-start) verse-start-text)))
            ;; (insert (string-trim-right subnode))
            (insert subnode)
            ;; (lo iproperties)
            (cond
             ((plist-get iproperties 'jesus)
              (put-text-property (- (point) (length (string-trim-right subnode))) (point) 'font-lock-face '(:foreground "red")))
             ((plist-get iproperties 'divinename)
              (put-text-property (- (point) (length (string-trim-right subnode))) (point) 'font-lock-face '(:foreground "orange")))
             (verse-start
              (let* (
                     ;; (start (- (point) (length (string-trim-right verse-start-text))))
                     (start (- (point) (length verse-start-text))))
                ;; (lo verse-start-text)
                (put-text-property start (+ start (length (string-trim-right verse-match))) 'font-lock-face '(:foreground "purple")))))))
      (progn
        ;; This does more than just the starting space
        (if (and (not (eq (dom-tag subnode) 'p)) (not (eq (dom-tag subnode) 'q)) (not (eq "" (dom-text subnode))))
            (insert " "))

        (bible-mode--insert-domnode-recursive subnode dom iproperties notitle)

        (if (and bible-mode-word-study-enabled (not (stringp subnode))) ;;word study. Must be done after subnode is inserted recursively.
            (let (
                  (savlm (dom-attr subnode 'savlm))
                  (match 0)
                  (matchstrlen 0)
                  (iter 0)
                  floating
                  refstart
                  refend)
              (if savlm
                  (progn
                    (while match ;;Greek
                      (if (> match 0)
                          (progn
                            (setq floating (or (> matchstrlen 0) (string-empty-p (dom-text subnode)))
                                  matchstrlen (length (match-string 0 savlm)))
                            (insert (if floating " " "") (match-string 0 savlm))
                            (setq refstart (- (point) matchstrlen)
                                  refend (point))
                            (put-text-property refstart refend 'font-lock-face `(
                                                                                 :foreground "cyan"
                                                                                 :height ,(if (not floating) 0.7)))
                            (put-text-property refstart refend 'keymap bible-mode-greek-keymap)
                            (if (not floating)
                                (put-text-property refstart refend 'display '(raise 0.6)))))
                      (setq match (string-match "G[0-9]+" savlm (+ match matchstrlen))))

                    (if (string-match "lemma.TR:.*" savlm) ;;Lemma
                        (dolist (word (split-string (match-string 0 savlm) " "))
                          (setq word (replace-regexp-in-string "[.:a-zA-Z0-9]+" "" word))
                          (insert " " word)
                          (setq refstart (- (point) (length word))
                                refend (point))
                          (put-text-property refstart refend 'font-lock-face `(:foreground "cyan"))
                          (put-text-property refstart refend 'keymap bible-mode-lemma-keymap)))

                    (if (string-match "strong:H.*" savlm) ;;Hebrew
                        (dolist (word (split-string (match-string 0 savlm) " "))
                          (setq iter (+ iter 1))
                          (setq word (replace-regexp-in-string "strong:" "" word))
                          (insert (if (eq iter 1) "" " ") word)
                          (setq refstart (- (point) (length word))
                                refend (point))
                          (put-text-property refstart refend 'font-lock-face `(
                                                                               :foreground "cyan"
                                                                               :height ,(if (eq iter 1) 0.7)))
                          (put-text-property refstart refend 'keymap bible-mode-hebrew-keymap))))))))))

  (if (equal (dom-tag node) 'title) ;;newline at end of title (i.e. those in Psalms)
      (insert "\n"))

  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward ":[^0-9 ]" nil t)
      (backward-char)
      (insert " ")
      ;; (replace-match ": ")
      ))

  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward "[;,.!?]" nil t)
      (insert " ")))

  ;; This must be a hack but it seems to work
  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward "  +" nil t)
      (replace-match " ")))


  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward " [’”]" nil t)
      (backward-char 1)
      (delete-backward-char 1)))

  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward "[‘“] " nil t)
      (delete-backward-char 1)))

  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward " , " nil t)
      (replace-match ", ")))

  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward " $" nil t)
      (delete-backward-char 1)))

  (if query
      (save-excursion
        (beginning-of-buffer)
        (while (re-search-forward query nil t)
          (put-text-property
           (- (point) (length query))
           (point) 'font-lock-face '(:foreground "green" :background "darkgreen")))))

  (save-excursion
    (end-of-buffer)
    (while (looking-at-p "^$")
      (delete-backward-char 1)
      (end-of-buffer))))

(defun bible-search (query &optional module searchtype)
  "Queries the user for a Bible search query. 
'lucene' mode requires an index to be built using the `mkfastmod' program."
  (interactive  (list (pen-ask (pen-selection) "Bible Search: ")))
  (if (> (length query) 0)
      (let* (
             (searchmode (or
                          searchtype
                          (completing-read "Search Mode: " '("lucene" "phrase")))))
        (bible-mode--open-search query searchmode (or module default-bible-mode-book-module)))))

(defun bible-search-lucene (query &optional module)
  (interactive  (list (pen-ask (pen-selection) "Bible Search: ")))
  ;; lucene or phrase

  (bible-mode--open-search query "lucene" (or module default-bible-mode-book-module)))

(defun bible-search-phrase (query &optional module)
  (interactive  (list (pen-ask (pen-selection) "Bible Search: ")))
  ;; lucene or phrase

  (bible-mode--open-search query "phrase" (or module default-bible-mode-book-module)))

(defun bible-search-mode-select-book ()
  (interactive)
  (nasb)
  (bible-mode-select-book))

(defun fz-bible-book ()
  (completing-read "Book: " bible-mode-book-chapters nil t))

(defun fz-bible-version ()
  (completing-read "Module: " (bible-mode--list-biblical-modules)))

(defun bible-mode-verse-other-version (version)
  (interactive (list (fz-bible-version)))

  (let ((ver (sor version))
        (ref (sor (bible-mode-get-link))))
    (if (and version
             ref)
        (sps (concat "ebible -m " version " " ref " | cvs")))))

(define-key bible-mode-map (kbd "o") 'bible-mode-verse-other-version)

(define-key bible-mode-map (kbd "d") 'bible-mode-toggle-word-study)
(define-key bible-mode-map (kbd "w") 'bible-mode-copy-link)

(define-key bible-mode-map "n" 'bible-mode-next-chapter)
(define-key bible-mode-map "p" 'bible-mode-previous-chapter)
(define-key bible-mode-map "b" 'bible-mode-select-book)
(define-key bible-mode-map "g" 'bible-mode--display)
(define-key bible-mode-map "c" 'bible-mode-select-chapter)
(define-key bible-mode-map "s" 'bible-search-phrase)
(define-key bible-mode-map "m" 'bible-mode-select-module)
(define-key bible-mode-map "x" 'bible-mode-split-display)

(define-key bible-search-mode-map "s" 'bible-search-phrase)
(define-key bible-search-mode-map "b" 'bible-search-mode-select-book)
(define-key bible-search-mode-map "g" nil)

(define-key bible-search-mode-map (kbd "d") 'bible-mode-toggle-word-study)
(define-key bible-search-mode-map (kbd "w") 'bible-mode-copy-link)

(define-key bible-search-mode-map (kbd "RET") 'bible-search-mode-follow-verse)

(define-key bible-mode-greek-keymap (kbd "RET") (lambda ()
                                                  (interactive)
                                                  (bible-term-greek (replace-regexp-in-string "[^0-9]*" "" (thing-at-point 'word t)))))

(define-key bible-mode-lemma-keymap (kbd "RET") (lambda ()(interactive)))

(define-key bible-mode-hebrew-keymap (kbd "RET") (lambda ()
                                                   (interactive)
                                                   (bible-term-hebrew (replace-regexp-in-string "[a-z]+" "" (thing-at-point 'word t)))))

(define-key global-map (kbd "H-v") 'nasb)
(define-key bible-mode-map (kbd "v") 'bible-mode-select-module)

(provide 'pen-bible-mode)
