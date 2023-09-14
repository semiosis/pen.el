;; This is a new variable, nonexistent in the original package
(defcustom default-bible-mode-book-module
  "NASB"
  "Default book module for Diatheke to query."
  :type '(choice (const :tag "None" nil)
                 (string :tag "Module abbreviation (e.g. \"KJV\")"))
  :group 'bible-mode)

;; (define-key pen-map (kbd "M-m r w") 'edit-var-elisp)
(defun bible-strongs-codes-sort (codeslist)
  (let ((lines (list2str codeslist)))
    (mapcar 'str2sym (str2lines (snc "bible-strongs-codes-sort" lines)))))

;; sort
;;
(defset bible-strongs-always-show-codelist
  (bible-strongs-codes-sort
   '(G25
     G1679 G5287
     G299 G26 G38 G40 G53 G76 G129 G165 G166 G169 G225
     G227 G228 G266 G281 G286 G386 G458 G487 G517
     G571 G721 G746 G757 G758 G907 G908 G932 G935
     G948 G1035 G1080 G1100 G1103 G1107 G1108 G1110
     G1140 G1169 G1169 G1208 G1242 G1258 G1336 G1390
     G1391 G1401 G1410 G1411 G1438 G1438 G1479 G1496
     G1497 G1504 G1515 G1680 G1781 G1785 G1799 G1849
     G1922 G2032 G2032 G2041 G2096 G2098 G2150 G2198
     G2222 G2226 G2246 G2250 G2288 G2303 G2307 G2316
     G2374 G2378 G2379 G2409 G2413 G2424 G2545 G2588
     G2730 G2809 G2839 G2842 G2889 G2919 G2937 G2962
     G3041 G3056 G3140 G3313 G3321 G3340 G3404 G3417
     G3439 G3466 G3485 G3528 G3609 G3739 G3741 G3772
     G3841 G3870 G3900 G3939 G3956 G3962 G4073 G4102
     G4103 G4138 G4151 G4178 G4190 G4202 G4203 G4205
     G4276 G4375 G4416 G4442 G4487 G4561 G4561 G4592
     G4633 G4637 G4678 G4716 G4891 G4982 G4990 G4991
     G5046 G5048 G5055 G5087 G5204 G5206 G5206 G5331
     G5333 G5360 G5368 G5399 G5406 G5426 G5457 G5479
     G5485 G5547 G5571 G5578 G5583 G5590 G3614 G4160
     G2570 G4550 G3551 G727 G154 G1097 G5429 G4160 G1857 G4655
     G1342
     H1 H410 H430 H1121 H4687 H5921 H6440 H6942 H8034 H8130 H8544)))

(comment
 (defset bible-strongs-always-show-code-tuples
   (mapcar (λ (e) (list e (bible-term-get-word e)))
           bible-strongs-always-show-codelist)))

(defset bible-strongs-always-show-xmllist
  (mapcar
   (λ (e)
     (concat "strong:" (str e)))
   bible-strongs-always-show-codelist))

;; For some words, I should actually use the strongs instead, for example with 'truly' in John 5:24

;; This will turn out to be a great way of learning greek

(defun bible-open (&optional global-chapter verse module ref)
  "Creates and opens a `bible-mode' buffer"
  (interactive)
  (let
      (
       (buf (get-buffer-create (generate-new-buffer-name "*bible*"))))
    (set-buffer buf)
    (setq module (or module
                     default-bible-mode-book-module
                     "NASB"))

    (bible-mode)

    (setq bible-mode-book-module module)

    (if (and ref
             (sor ref))
        (bible-mode-lookup (bible-canonicalise-ref ref))
      (progn
        (bible-mode--set-global-chapter (or global-chapter 1) verse)
        (set-window-buffer (get-buffer-window (current-buffer)) buf)))))

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

(defun bible-mode--open-search(query searchmode &optional module range)
  "Opens a search buffer of QUERY using SEARCHMODE."
  (let
      (
       (buf (get-buffer-create (concat "*bible-search-" (downcase (or module default-bible-mode-book-module)) "-" query "*"))))
    (set-buffer buf)
    (bible-search-mode)
    (setq bible-mode-book-module (or module default-bible-mode-book-module))
    ;; (lo module)
    (bible-mode--display-search query searchmode bible-mode-book-module range)
    (pop-to-buffer buf nil t)))

(defun bible-mode--exec-diatheke(query &optional filter format searchtype module range)
  "Executes `diatheke' with specified query options, returning the output."
  (with-temp-buffer
    (let (
          (args (list "diatheke"
                      nil
                      (current-buffer)
                      t
                      "-b" (or module bible-mode-book-module))))
      (if filter (setq args (append args (list
                                          "-o" (pcase filter
                                                 ("jesus" "w"))
                                          ))))
      (if searchtype (setq args (append args (list
                                              "-s" (pcase searchtype
                                                     ("lucene" "lucene")
                                                     ("phrase" "phrase")
                                                     )
                                              ))))
      (setq args (append args
                         (if range
                             (list
                              "-r" range)
                           nil)
                         (list
                          "-o" (pcase filter
                                 (_ "w"))
                          "-f" (pcase format
                                 ("plain" "plain")
                                 (_ "internal"))
                          "-k" query
                          )))
      (apply 'call-process args))
    (buffer-string)))

(defun bible-mode-display-final-tidy (&optional query)
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
    (while (sp--with-case-sensitive (re-search-forward "[a-z][A-Z]" nil t))
      (backward-char 1)
      (insert " ")))

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
    (beginning-of-buffer)
    (while (re-search-forward ":[0-9]+: " nil t)
      (let* ((end (point))
             (start
              (progn
                (beginning-of-line)
                (point)))
             (ref (s-replace-regexp ": " "" (buffer-substring start end)))
             (fp (bible-mode-get-notes-fp-for-verse ref)))
        (if (f-exists-p fp)
            (put-text-property start end 'font-lock-face '(:foreground "green"))
          (put-text-property start end 'font-lock-face '(:foreground "purple"))))
      ;; (message "%s" (current-line-string))
      (end-of-line)))

  (save-excursion
    (end-of-buffer)
    (while (looking-at-p "^$")
      (delete-backward-char 1)
      (end-of-buffer))))

(defun string-match-capture (regexp string &optional start)
  (string-match regexp string start)
  (match-string ))

(defun bible-mode--display-search(query searchmode &optional module range)
  "Renders results of search QUERY from SEARHCMODE"
  (setq buffer-read-only nil)
  (erase-buffer)

  (if (catch 'no-results (let* (
                                (term query)
                                (result (string-trim (replace-regexp-in-string "Entries .+?--" "" (bible-mode--exec-diatheke query nil "plain" searchmode module range))))
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

                             (bible-mode-display-final-tidy term)

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
  (if (pen-selected-p)
      (call-interactively-with-prefix-and-parameters 'bible-search-phrase (prefix-numeric-value current-prefix-arg) (pen-selection))
    ;; (bible-search-phrase (pen-selection))
    (bible-open-version "NASB")))

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
    ("Ecclesiastes" "Eccl" "Eccles" "Eccle" "Ecc" "Ec" "Qoh")
    ("Song of Solomon" "Song" "Song of Songs" "SOS" "So" "Canticle of Canticles" "Canticles" "Cant")
    ("Isaiah" "Isa" "Is")
    ("Jeremiah" "Jer" "Je" "Jr")
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
    ("Philemon" "Philem" "Phlm" "Phm" "Pm")
    ("Hebrews" "Heb")
    ("James" "Jas" "Jm")
    ("I Peter" "1 Peter" "1 Pet" "1 Pe" "1 Pt" "1 P" "I Pet" "I Pt" "I Pe" "1Peter" "1Pet" "1Pe" "1Pt" "1P" "I Peter" "1st Peter" "First Peter")
    ("II Peter" "2 Peter" "2 Pet" "2 Pe" "2 Pt" "2 P" "II Pet" "II Pt" "II Pe" "2Peter" "2Pet" "2Pe" "2Pt" "2P" "II Peter" "2nd Peter" "Second Peter")
    ("I John" "1 John" "1 Jhn" "1 Jn" "1 J" "1John" "1Jhn" "1Joh" "1Jn" "1Jo" "1st John" "First John")
    ("II John" "2 John" "2 Jhn" "2 Jn" "2 J" "2John" "2Jhn" "2Joh" "2Jn" "2Jo" "2nd John" "Second John")
    ("III John" "3 John" "3 Jhn" "3 Jn" "3 J" "3John" "3Jhn" "3Joh" "3Jn" "3Jo" "3rd John" "Third John")
    ("Jude" "Jud" "Jd")
    ("Revelation of John" "Revelation" "Rev" "Re")))

;; (member-similar "jas" '(Hi "Jas"))
(defun member-similar (elt lst &optional comparator)
  "works between floats and ints. and compares strings insensitively"

  (setq comparator (or comparator 'cl-equalp))

  (catch 'foo
    (dolist (x lst)
      (when (funcall comparator x elt)
        (throw 'foo x))))

  ;; (cl-member elt lst)
  ;; (member elt lst)
  )

(defalias 'member-caseinsensitive 'member-similar)

(defun sh-canonicalise-bible-ref (ref)
  (pen-snc "canonicalise-bible-book-title" ref))

(defun bible-canonicalise-book-title (ref &optional nilfailure)
  (setq ref (s-replace-regexp "\\(\\. \\?\\|\\.\\)" " " ref))
  (setq ref (esed "\\.$" "" ref))
  (cl-loop for tp in bible-book-map-names
           until ;; (member ref (cdr tp))
           (member-similar ref tp)
           ;; (member ref tp)
           finally return
           (if ;; (member ref (cdr tp))
               (member-similar ref tp)
               ;; (member ref tp)
               (car tp)
             (if nilfailure
                 nil
               ref))))

(defun bible-canonicalise-ref (ref &optional nilfailure)
  (let* ((booktitle (s-replace-regexp "[. ][0-9].*" "" ref))
         (chapverse (pen-snc "sed -n 's/.*[. ]\\([0-9].*\\)/\\1/p'" ref))
         (booktitle (bible-canonicalise-book-title booktitle nilfailure)))
    (if (test-n chapverse)
        (concat booktitle " " chapverse)
      booktitle)))

(defun bible-book-only-p (s)
  (member-similar
   (bible-canonicalise-ref s)
   (mapcar 'car bible-mode-book-chapters)))

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

(defun bible-mode-lookup (&optional text module)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (bible-get-text-here)))

  (setq text (or text (bible-get-text-here)))

  ;; (mapcar 'car bible-mode-book-chapters)

  (let* ((module
          (or module default-bible-mode-book-module))
         (ot text)

         (maybebook
          (bible-book-only-p (bible-canonicalise-ref ot t)))

         (text
          (if maybebook
              (concat maybebook " 1")
            text)))

    (if (and (re-match-p "[-,]" text)
             ;; (yn (concat "Also show " text " in vim?"))
             ;; (yn (concat "Show " text " in vim?"))
             )
        (sps (cmd "ebible" "-m" module "-nem"
                  text)))

    (let* (
           ;; To make refs like this work:
           ;; Lev 18-20
           (text (s-replace-regexp "-[0-9].*" "" text))
           ;; Make this one work too
           ;; Lev.19:18
           (text (s-replace-regexp "\\(\\. \\?\\|\\.\\)" " " text))
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
          (setq bible-mode-book-module module))

      (bible-open (+ (bible-mode--get-book-global-chapter book) (string-to-number chapter))
                   (string-to-number verse)
                   module)
      ;; (tryelse
      ;;  (bible-open (+ (bible-mode--get-book-global-chapter book) (string-to-number chapter))
      ;;              (string-to-number verse)
      ;;              module)
      ;;  (error "Error. Incorrect Bible reference?"))
      )))

(defun scrape-bible-references (text)
  (pen-str2lines (pen-snc "scrape-bible-references" text)))
(defalias 'scrape-bible-verses 'scrape-bible-references)

(defun bible-mode-lookup-ref (text)
  (interactive (list (read-string "Bible reference: " (car (scrape-bible-references (bible-get-text-here))))))
  (bible-mode-lookup text))

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
      (if (not (string-match ":$" text))
          (setq text (concat text ":")))
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

(defun bible-mode-copy-link (&optional text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (thing-at-point 'line t)))

  (setq text (or text (thing-at-point 'line t)))

  (if (major-mode-p 'bible-mode)
      (if (interactive-p)
          (xc (bible-mode-get-link text))
        (bible-mode-get-link text))
    nil))

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
    (bible-mode-display-final-tidy)
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
        (beginning-of-line)))
  (run-hooks 'bible-mode-hook))

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
                 (is-love (string-match "love" subnode))
                 ;; (verse-start (string-match ".+?:[0-9]?[0-9]?[0-9]?:" subnode))
                 ;; verse-start-text
                 ;; verse-match
                 )
            ;; (if verse-start
            ;;     (setq verse-match (string-trim (match-string 0 subnode))
            ;;           verse-start-text (string-trim-left (substring subnode verse-start (length subnode)))
            ;;           subnode (concat (substring subnode 0 verse-start) verse-start-text)))
            ;; (insert (string-trim-right subnode))
            ;; (if (plist-get iproperties 'jesus)
            ;;     (insert (str (length (string-trim-right subnode)))))
            (insert subnode)
            ;; (lo iproperties)
            (cond
             ((plist-get iproperties 'jesus)
              (put-text-property (- (point) (length (string-trim-right (s-replace-regexp "\n.*" "" subnode)))) (point) 'font-lock-face '(:foreground "red" :background "black")))
             ((plist-get iproperties 'divinename)
              (put-text-property (- (point) (length (string-trim-right (s-replace-regexp "\n.*" "" subnode)))) (point) 'font-lock-face '(:foreground "orange")))
             ;; (verse-start
             ;;  t
             ;;  ;; (let* (
             ;;  ;;        ;; (start (- (point) (length (string-trim-right verse-start-text))))
             ;;  ;;        (start (- (point) (length verse-start-text))))
             ;;  ;;   ;; (lo verse-start-text)
             ;;  ;;   (let* ((ref (s-replace-regexp ":$" "" verse-match))
             ;;  ;;          (fp (bible-mode-get-notes-fp-for-verse ref)))
             ;;  ;;     ;; (lo ref)
             ;;  ;;     (if (f-exists-p fp)
             ;;  ;;         (put-text-property start (+ start (length (string-trim-right verse-match))) 'font-lock-face '(:foreground "green"))
             ;;  ;;       (put-text-property start (+ start (length (string-trim-right verse-match))) 'font-lock-face '(:foreground "purple")))))
             ;;  )
             )))
      (progn
        ;; This does more than just the starting space
        (if (and (not (eq (dom-tag subnode) 'p)) (not (eq (dom-tag subnode) 'q)) (not (eq "" (dom-text subnode))))
            (insert " "))

        (bible-mode--insert-domnode-recursive subnode dom iproperties notitle)

        (if (and
             (not (stringp subnode))
             (or bible-mode-word-study-enabled
                 (member (dom-attr subnode 'savlm)
                         bible-strongs-always-show-xmllist))) ;;word study. Must be done after subnode is inserted recursively.
            (let* (
                   (savlm (dom-attr subnode 'savlm))
                   (match 0)
                   (matchstrlen 0)
                   (iter 0)
                   floating
                   refstart
                   refend)
              (if savlm
                  (progn
                    ;; (lo savlm)
                    ;; 0 is still truthy, so the thing will run
                    (while match ;;Greek
                      (if (> match 0)
                          (let* ((strongs_code (match-string 0 savlm))
                                 (strongs_word (bible-term-get-word strongs_code))
                                 (strongs_anno
                                  (if strongs_word
                                      (concat strongs_code "-" strongs_word)
                                    strongs_code))
                                 (strongs_len (length strongs_anno))
                                 (strongs_code_len (length strongs_code))
                                 (strongs_word_len (length strongs_word)))
                              (progn
                                (setq floating (or (> matchstrlen 0) (string-empty-p (dom-text subnode)))
                                      matchstrlen strongs_code_len)
                                (insert (if floating " " "")
                                        (concat strongs_code " " strongs_word))

                                (let ((refstart (- (point)
                                                    strongs_len))
                                      (refend (+ (- (point)
                                                    strongs_len)
                                                 strongs_code_len)))
                                  (put-text-property refstart refend 'font-lock-face `(
                                                                                       :foreground "cyan"
                                                                                       :height ,(if (not floating) 0.7)))
                                  (put-text-property refstart refend 'keymap bible-mode-greek-keymap)
                                  (if (not floating)
                                      (put-text-property refstart refend 'display '(raise 0.6))))
                                (let ((refstart (- (point)
                                                   strongs_word_len
                                                   ;; matchstrlen
                                                   ))
                                      (refend (point)))
                                  (if (member (str2sym strongs_code)
                                              bible-strongs-always-show-codelist)
                                      (put-text-property refstart refend 'font-lock-face `(
                                                                                           :foreground "blue"
                                                                                           :height ,(if (not floating) 0.7)))
                                    (put-text-property refstart refend 'font-lock-face `(
                                                                                         :foreground "#d2268b"
                                                                                                     :height ,(if (not floating) 0.7))))
                                  (if (not floating)
                                      (put-text-property refstart refend 'display '(raise 0.6)))))))
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
  t)

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
  (interactive  (list (pen-ask (pen-selection) "Bible Search (lucene): ")))
  ;; lucene or phrase

  (bible-mode--open-search query "lucene" (or module default-bible-mode-book-module)))

(defun bible-search-phrase (query &optional module range)
  (interactive
   (if (>= (prefix-numeric-value current-prefix-arg) 4)
       (let ((book (fz-bible-book "Bible Search (book): "))
             (query (pen-ask (pen-selection) "Bible Search: ")))
         (list query nil book))
     (list (pen-ask (pen-selection) "Bible Search: ") nil nil)))
  ;; lucene or phrase

  (bible-mode--open-search query "phrase" (or module default-bible-mode-book-module) range))

(defun bible-search-mode-select-book ()
  (interactive)
  (nasb)
  (bible-mode-select-book))

(defun fz-bible-book (prompt)
  (setq prompt (or prompt "Book: "))
  (completing-read prompt bible-mode-book-chapters nil t))

(defun fz-bible-version ()
  (completing-read "Module: " (bible-mode--list-biblical-modules)))

(defun bible-mode-verse-other-version (version)
  (interactive (list (fz-bible-version)))
  (cond
   ((>= (prefix-numeric-value current-prefix-arg) 16) (let ((prefix-numeric-value nil)
                                                           (current-prefix-arg nil))
                                                       (let ((ver (sor version))
                                                             (ref (sor (bible-mode-get-link))))
                                                         (if (and version
                                                                  ref)
                                                             (sps (concat "ebible -m " version " " ref " | cvs"))))))
   ((>= (prefix-numeric-value current-prefix-arg) 4) (let ((prefix-numeric-value nil)
                                                           (current-prefix-arg nil))
                                                       (let ((ver (sor version))
                                                             (ref (sor (bible-mode-get-link))))
                                                         (if (and version
                                                                  ref)
                                                             (pen-e-sps (lm (etv (snc (concat "ebible -m " version " " ref " | cat")))))))))
   (t (let ((ver (sor version))
            (ref (sor (bible-mode-get-link))))
        (if (and version
                 ref)
            (pen-e-sps (lm (bible-mode-lookup ref version))))))))

(defun bible-mode-open-notes-for-verse (text)
  (interactive (list (thing-at-point 'line t)))
  (setq text (or text (thing-at-point 'line t)))
  (let* ((ref (bible-mode-get-link text))
         (refslug (slugify (s-replace-regexp "," " " (s-replace-regexp "-" " to " (s-replace-regexp ":" " v" ref)))))
         (dp (f-join penconfdir "documents" "bible-notes" "verse"))
         (fn (concat refslug ".org"))
         (fp (f-join dp fn)))
    (f-mkdir dp)
    (find-file fp)))

(defun bible-mode-get-notes-fp-for-verse (&optional ref)
  (interactive (list (bible-mode-get-link (thing-at-point 'line t))))
  (setq ref (or ref (bible-mode-get-link (thing-at-point 'line t))))
  (let* ((refslug (slugify (s-replace-regexp "," " " (s-replace-regexp "-" " to " (s-replace-regexp ":" " v" ref)))))
         (dp (f-join penconfdir "documents" "bible-notes" "verse"))
         (fn (concat refslug ".org"))
         (fp (f-join dp fn)))
    (f-mkdir dp)
    fp))

(defun bible-mode-search-for-verse (text)
  (interactive (list (thing-at-point 'line t)))
  (setq text (or text (thing-at-point 'line t)))
  (let* ((ref (bible-mode-get-link text))
         (refslug (slugify (s-replace-regexp "," " " (s-replace-regexp "-" " to " (s-replace-regexp ":" " v" ref)))))
         (dp (f-join penconfdir "documents" "bible-notes" "verse"))
         (fn (concat refslug ".org"))
         (fp (f-join dp fn)))

    ;; (glimpse-thing-at-point "txt" "Galatians 3")
    ;; gli -F .txt -i "Galatians 3" | v
    (f-mkdir dp)
    (find-file fp)))

(defun view-notes-fp-verse (&optional ref editor)
  (interactive (list (bible-mode-get-link (thing-at-point 'line t))))
  (setq ref (or ref (bible-mode-get-link (thing-at-point 'line t))))
  ;; (tpop (cmd "less" "-rS") (cat (bible-mode-get-notes-fp-for-verse ref)))

  (let ((fp (bible-mode-get-notes-fp-for-verse ref)))
    (if (sor editor)
        (tpop (cmd editor (bible-mode-get-notes-fp-for-verse ref)))
      (find-file-other-window (bible-mode-get-notes-fp-for-verse ref)))))

(defun view-notes-fp-verse-v (&optional ref editor)
  (interactive (list (bible-mode-get-link (thing-at-point 'line t))))
  (setq ref (or ref (bible-mode-get-link (thing-at-point 'line t))))
  (view-notes-fp-verse ref "v"))

;; https://www.openbible.info/labs/cross-references/search?q=1+Samuel+7%3A3

;; https://www.openbible.info/labs/cross-references/search?q=Revelation+7%3A3

(defun openbible-canonicalise-ref (ref)
  (let ((ref (bible-canonicalise-ref ref)))

    (setq ref (s-replace-regexp "^III" "3" ref))
    (setq ref (s-replace-regexp "^II" "2" ref))
    (setq ref (s-replace-regexp "^I" "1" ref))
    (setq ref (s-replace-regexp "^Revelation of John" "Revelation" ref))
    ref))

(defun bible-mode-cross-references (ref)
  (interactive (list (bible-mode-get-link (thing-at-point 'line t))))
  (let ((link (concat "https://www.openbible.info/labs/cross-references/search?q=" (urlencode (openbible-canonicalise-ref ref)))))
    (message "%s" (concat "Visiting: " link))
    (eww link)))

(defun bible-term-greek-get (term_g_num)
  "Queries user for a Strong Greek Lexicon term."
  (interactive "sTerm: ")
  (replace-regexp-in-string (regexp-opt '("(StrongsGreek)")) "" (bible-mode--exec-diatheke term_g_num nil nil nil "StrongsGreek")))

(defun bible-term-hebrew-get (term_h_num)
  "Queries user for a Strong Hebrew Lexicon term."
  (interactive "sTerm: ")
  (replace-regexp-in-string (regexp-opt '("(StrongsHebrew)")) "" (bible-mode--exec-diatheke term_h_num nil nil nil "StrongsHebrew")))

(defun bible-term-get-word (term_code)
  (interactive "sTerm: ")
  (let* ((term_code (str term_code))
         (split_code (s-replace-regexp "." "" term_code))
         (is_greek (re-match-p "^G" term_code))
         (is_hebrew (re-match-p "^H" term_code))
         (term_code (s-replace-regexp "^[GH]" "" term_code))
         (info
          (cond
           (is_greek (bible-term-greek-get term_code))
           (is_hebrew (bible-term-hebrew-get term_code))
           (t nil)))
         (word (if info
                   (snc "sed 's/ \\+/ /g' | cut -d ' ' -f 3" (car (str2lines info))))))
    word))

(memoize 'bible-term-get-word)

;; TODO Make it so it resumes the same place
(defun bible-mode-toggle-word-study()
  "Toggles the inclusion of word study for the active `bible-mode' buffer."
  (interactive)
  (setq bible-mode-word-study-enabled (not bible-mode-word-study-enabled))
  (if (equal major-mode 'bible-search-mode)
      (bible-mode--display-search bible-mode-search-query bible-mode-search-mode)
    (bible-mode--display)))

(defun bible-random-verse-ref ()

  )

(defun bible-verse-get-quote-cmd (concordance_arg)
  (cmd "nem" "fast" "ebible"
       concordance_arg
       "-m" bible-mode-book-module (bible-mode-copy-link)))

(defun bible-get-quote (&optional backticks)
  (interactive)

  ;; major-mode

  (let* ((concordance_arg
          (cond
           ((>= (prefix-numeric-value current-prefix-arg) 64) "-cac")
           ((>= (prefix-numeric-value current-prefix-arg) 16) "-ca")
           ((>= (prefix-numeric-value current-prefix-arg) 4) "-c")
           (t nil)))
         (current-prefix-arg nil))
  
    (tpop (bible-verse-get-quote-cmd concordance_arg)
          nil
          :x_pos "M+1"
          :y_pos "M+1"
          :width_pc 50
          :height_pc 20)))

(defun bible-mode-tpop ()
  (interactive)
  (let* ((concordance_arg
          (cond
           ((>= (prefix-numeric-value current-prefix-arg) 64) "-cac")
           ((>= (prefix-numeric-value current-prefix-arg) 16) "-ca")
           ((>= (prefix-numeric-value current-prefix-arg) 4) "-c")
           (t nil)))
         (current-prefix-arg nil))
  
    (tpop (cmd "nem" "fast" "ebible"
               concordance_arg
               "-m" bible-mode-book-module (bible-mode-copy-link))
          nil
          :x_pos "M+1"
          :y_pos "M+1"
          :width_pc 50
          :height_pc 20
          :style "heavy")))

(define-key bible-mode-map (kbd "M-t") 'bible-mode-tpop)
(define-key bible-mode-map (kbd "M-e") 'view-notes-fp-verse)
(define-key bible-mode-map (kbd "M-v") 'view-notes-fp-verse-v)
(define-key bible-mode-map (kbd "e") 'bible-mode-open-notes-for-verse)
(define-key bible-mode-map (kbd "o") 'bible-mode-verse-other-version)
(define-key bible-mode-map (kbd "d") 'bible-mode-toggle-word-study)
(define-key bible-mode-map (kbd "w") 'bible-mode-copy-link)

(define-key bible-mode-map "n" 'bible-mode-next-chapter)
(define-key bible-mode-map "p" 'bible-mode-previous-chapter)
(define-key bible-mode-map "b" 'bible-mode-select-book)
(define-key bible-mode-map "g" 'bible-mode--display)
(define-key bible-mode-map "c" 'bible-mode-select-chapter)
(define-key bible-mode-map "s" 'bible-search-phrase)
(define-key bible-mode-map "S" 'bible-search-lucene)
(define-key bible-mode-map "m" 'bible-mode-select-module)
;; (define-key bible-mode-map "x" 'bible-mode-split-display)
(define-key bible-mode-map "x" 'bible-mode-cross-references)
(define-key bible-mode-map "l" 'bible-mode-lookup-ref)

(define-key bible-search-mode-map "s" 'bible-search-phrase)
(define-key bible-search-mode-map "S" 'bible-search-lucene)
(define-key bible-search-mode-map "b" 'bible-search-mode-select-book)
(define-key bible-search-mode-map "x" 'bible-mode-cross-references)
(define-key bible-search-mode-map "g" nil)

(define-key bible-search-mode-map (kbd "M-e") 'view-notes-fp-verse)
(define-key bible-search-mode-map (kbd "M-v") 'view-notes-fp-verse-v)
(define-key bible-search-mode-map (kbd "e") 'bible-mode-open-notes-for-verse)
(define-key bible-search-mode-map (kbd "o") 'bible-mode-verse-other-version)
(define-key bible-search-mode-map (kbd "d") 'bible-mode-toggle-word-study)
(define-key bible-search-mode-map (kbd "w") 'bible-mode-copy-link)

(define-key bible-search-mode-map (kbd "RET") 'bible-search-mode-follow-verse)

(define-key bible-mode-greek-keymap (kbd "RET") (λ ()
                                                  (interactive)
                                                  (bible-term-greek (replace-regexp-in-string "[^0-9]*" "" (thing-at-point 'word t)))))

(define-key bible-mode-lemma-keymap (kbd "RET") (λ ()(interactive)))

(define-key bible-mode-hebrew-keymap (kbd "RET") (λ ()
                                                   (interactive)
                                                   (bible-term-hebrew (replace-regexp-in-string "[a-z]+" "" (thing-at-point 'word t)))))

(define-key global-map (kbd "H-v") 'nasb)
(define-key bible-mode-map (kbd "v") 'bible-mode-select-module)

(provide 'pen-bible-mode)
