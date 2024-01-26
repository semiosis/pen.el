(require 'bible-mode)

(defsetface bible-verse-ref
            '((t
               :foreground "#5555ff"))
            "Bible verse ref"
            :group 'bible-mode)

(defsetface bible-verse-ref-notes
            '((t
               :foreground "green"))
            "Bible verse ref with notes"
            :group 'bible-mode)

(defsetface bible-codes
            '((t
               ;; bright cyan - codes
               :foreground "#77ffff"
               :weight bold
               ;; :underline t
               ))
            "Strong's Code"
            :group 'bible-mode)

(defsetface bible-greek
            '((t
               ;; pink - greek words
               :foreground "#d2268b"
               :weight bold
               ;; :underline t
               ))
            "Strong's Greek"
            :group 'bible-mode)

(defsetface bible-greek-always
            '((t
               ;; light blue - always show greek words
               :foreground "#7777ff"
               :weight bold
               ;; :underline t
               ))
            "Strong's Greek (always show)"
            :group 'bible-mode)

(defsetface bible-hebrew
            '((t
               :foreground "cyan"
               :weight bold
               ;; :underline t
               ))
            "Strong's Hebrew"
            :group 'bible-mode)

(defsetface bible-lemma
            '((t
               :foreground "cyan"
               :weight bold
               ;; :underline t
               ))
            "Strong's Lemma"
            :group 'bible-mode)

(defsetface bible-jesus-words
            '((t
               :foreground "#ff3333"
               :weight bold
               ;; :underline t
               ))
            "Jesus' Words"
            :group 'bible-mode)

(defsetface bible-divine-name
            '((t
               :foreground "orange"
               :background "#552200"

               :weight bold
               ;; :underline t
               ))
            "Divine Name"
            :group 'bible-mode)

;; Can't require sqlite here or it will break bible-mode on the host
;; (require 'sqlite-mode)

;; This is a new variable, nonexistent in the original package
(defcustom default-bible-mode-book-module
  ;; "NASB"
  "RLT"
  "Default book module for Diatheke to query."
  :type '(choice (const :tag "None" nil)
                 (string :tag "Module abbreviation (e.g. \"KJV\")"))
  :group 'bible-mode)

(setq default-bible-mode-book-module "RLT")
(setq default-bible-mode-book-module "NASB")
(setq default-bible-mode-book-module "ESV")

;; (define-key pen-map (kbd "M-m r w") 'edit-var-elisp)
(defun bible-strongs-codes-sort (codeslist)
  (let ((lines (list2str codeslist)))
    (mapcar 'str2sym (str2lines (snc "bible-strongs-codes-sort" lines)))))

(define-derived-mode bible-mode special-mode "Bible"
  "Mode for reading the Bible.
\\{bible-mode-map}"
  (buffer-disable-undo)
  (font-lock-mode t)
  ;; (auto-fill-mode t)
  (use-local-map bible-mode-map)
  (setq buffer-read-only t)
  (setq word-wrap t)

  (make-local-variable 'magit-buffer-margin)
  (setq magit-buffer-margin '(t age 30 t 18)))

(define-derived-mode bible-search-mode special-mode "Bible Search"
  "Mode for performing Bible searches.
\\{bible-search-mode-map}"
  (buffer-disable-undo)
  (font-lock-mode t)
  ;; (auto-fill-mode t)
  (use-local-map bible-search-mode-map)
  (setq buffer-read-only t)
  (setq word-wrap t))

;; sort
;;
(defset bible-strongs-always-show-codelist
        (bible-strongs-codes-sort
         '(G25 G859 G2983 G1431
               G1679 G5287
               G299 G26 G38 G40 G53 G76 G129 G165 G166 G169 G225
               G227 G228 G266 G281 G286 G386

               ;; https://www.sermonindex.net/modules/articles/index.php?view=article&aid=34351
               G458

               G487 G517
               G571

               ;; II Corinthians 8:2
               ;; TODO Make G572 show as = generosity
               ;; https://youtu.be/aUPSZBm1OjY?t=2797
               G572

               G721 G746 G757 G758 G907 G908 G932 G935
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
               G1342 G2631 G1343 G4828
               H1 H410 H3068 H430 H1004 H1121 H3801 H3548 H4687 H5411 H5921 H6440 H6942
               H8034 H8130 H8544)))

(comment
 (defset bible-strongs-always-show-code-tuples
   (mapcar (lambda (e) (list e (bible-term-get-word e)))
           bible-strongs-always-show-codelist)))

(defset bible-strongs-always-show-xmllist
  (mapcar
   (lambda (e)
     (concat "strong:" (str e)))
   bible-strongs-always-show-codelist))

;; For some words, I should actually use the strongs instead, for example with 'truly' in John 5:24

;; This will turn out to be a great way of learning greek

(defun bible-open (&optional global-chapter verse module ref buffer)
  "Creates and opens a `bible-mode' buffer"
  (interactive)
  (let*
      ((buffername_ref (or ref "Genesis"))
       (slug (slugify buffername_ref))
       (buf (or buffer
                (get-buffer-create "*bible*"))))

    (bible-rename-buffer buffername_ref buf)
    (set-buffer buf)
    (setq module (or module
                     default-bible-mode-book-module
                     "NASB"))

    (bible-mode)

    (setq bible-mode-book-module module)
    (switch-to-buffer buf)

    ;; (redraw-frame)

    (if (and ref
             (sor ref))
        (bible-mode-lookup (bible-canonicalise-ref ref) module buf)
      (progn
        (bible-mode--set-global-chapter (or global-chapter 1) verse)
        (set-window-buffer (get-buffer-window (current-buffer)) buf)))
    buf))

(defun bible-mode-select-module()
  "Queries user to select a new reading module for the current `bible-mode' buffer."
  (interactive)
  (let* (
         (module
          (fz (bible-mode--list-biblical-modules) nil nil "Module: ")
          ;; (completing-read "Module: " (bible-mode--list-biblical-modules))
          ))
    (setq bible-mode-book-module module)
    (bible-mode--display)))

(defun bible-open-version (version)
  (interactive (list
                (fz (bible-mode--list-biblical-modules) nil nil "Module: ")
                ;; (completing-read "Module: " (bible-mode--list-biblical-modules))
                ))
  (if (not version)
      (setq version (or default-bible-mode-book-module "NASB")))

  (let ((bible-mode-book-module version))
    (bible-open nil nil version)))

;; (defun bible-mode-fun-around-advice (proc &rest args)
;;   (let ((res (apply proc args)))
;;     res))
;; (advice-add 'bible-mode--exec-diatheke :around #'bible-mode-fun-around-advice)
;; (advice-remove 'bible-mode--exec-diatheke #'bible-mode-fun-around-advice)

(defun bible-mode--open-search (query searchmode &optional module range search-on-search)
  "Opens a search buffer of QUERY using SEARCHMODE."
  (let
      (
       (buf (get-buffer-create (concat "*bible-search-" (downcase (or module default-bible-mode-book-module)) "-" query "*"))))
    (set-buffer buf)
    (bible-search-mode)
    (setq bible-mode-book-module (or module default-bible-mode-book-module))
    ;; (lo module)
    (bible-mode--display-search query searchmode bible-mode-book-module range)
    (if search-on-search
        (progn
          (goto-char (point-min))
          (search-forward-regexp search-on-search nil t)))
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
                                                 ("jesus" "w"))))))
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

  ;; For Psalm 3 - NASB
  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward "^ " nil t)
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
      (let* ((end (- (point) 1))
             (start
              (progn
                (beginning-of-line)
                (point)))
             (ref (s-replace-regexp ": " "" (buffer-substring start (+ 1 end))))
             (fp (bible-mode-get-notes-fp-for-verse ref)))
        (if (f-exists-p fp)
            (put-text-property start end 'font-lock-face
                               'bible-verse-ref-notes
                               ;; '(:foreground "green")
                               )

          ;; #rrggbb works with truecolor, and to get nice blues, truecolor is required
          ;; (put-text-property start end 'font-lock-face '(:foreground
          ;;                                                ;; "#443344"
          ;;                                                "#222255"))

          ;; This is a good colour on both xterm and alacritty
          (put-text-property start end 'font-lock-face
                             'bible-verse-ref
                             ;; '(:foreground
                             ;;   ;; "#443344"
                             ;;   "#5555ff")
                             )

          (pen-magit-make-margin-overlay
           (concat "  "
                   (magit--propertize-face
                    (bible-verse-margin-status)
                    'pen-magit-right-margin-face)))))
      ;; (message "%s" (current-line-string))
      (end-of-line)))

  (save-excursion
    (end-of-buffer)
    (while (looking-at-p "^$")
      (delete-backward-char 1)
      (end-of-buffer)))

  (if (universal-sidecar-visible-p)
      (toggle-chrome-extras nil t)))

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

(defmacro defun-bible-open-version (module-name module-sym)
  `(defun ,module-sym ()
     (interactive)
     (if (selected-p)
         (call-interactively-with-prefix-and-parameters 'bible-search-phrase (prefix-numeric-value current-prefix-arg) (pen-selection))
       ;; (bible-search-phrase (pen-selection))
       (bible-open-version ,module-name))))

(defun-bible-open-version "NASB" nasb)
(defun-bible-open-version "KJV" kjv)
(defun-bible-open-version "engbsb2020eb" bsb)
(defun-bible-open-version "RLT" rlt)
(defun-bible-open-version "ESV" esv)

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

(defun bible-rename-buffer (ref &optional buffer)
  "if create-if-buf-is-nil is true then when buf is nil, a buffer is created rather than renaming the current buffer"
  (let* ((buf (or
               buffer
               (current-buffer)))
         (slug (slugify ref))
         (current_name (buffer-name buf))
         (optimal_name (concat "*bible-" slug "*"))
         (next_name (generate-new-buffer-name
                     optimal_name)))

    (if (not (string-equal current_name optimal_name))
        (with-current-buffer buf
          (rename-buffer next_name)))
    buf))

(defun bible-mode-lookup (&optional text module buf)
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
                  module
                  nil
                  buf)
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

        (setq-local bible-mode-ref-tuple (list book chapter verse))
        (setq-local bible-mode-chapter (concat book " " chapter))

        (if (>= (prefix-numeric-value current-prefix-arg) 4)
            (concat "[[bible:" (concat bible-mode-chapter ":" verse) "]]")
          (concat bible-mode-chapter ":" verse))))))

(defun bible-mode-get-ref-tuple (&optional text)
  (interactive (list (thing-at-point 'line t)))

  (setq text (or text (thing-at-point 'line t)))

  (let* ((refstring
          (ignore-errors
            (bible-mode-get-link text)))
         (verse
          (ignore-errors
            (string-to-int (s-replace-regexp ".*:" "" refstring))))
         (refstring
          (ignore-errors
            (s-replace-regexp ":[^:]*" "" refstring)))
         (book
          (ignore-errors
            (s-replace-regexp " [^ ]*$" "" refstring)))
         (chapter
          (ignore-errors
            (string-to-int
             (s-replace-regexp ".* \\([^ ]*\\)$" "\\1" refstring))))

         ;; (title
         ;;  (ignore-errors
         ;;    (bible-get-chapter-title book chapter)))
         )
    (if refstring
        (list
         book
         chapter
         verse
         ;; TODO Get VERSE title
         ;; title
         ))))

(defun bible-mode-get-book-and-chapter (&optional text)
  (interactive (list (thing-at-point 'line t)))

  (setq text (or text (thing-at-point 'line t)))

  (let ((ref (bible-mode-get-link text)))
    (setq ref (s-replace-regexp ":[^:]*" "" ref))
    ref))

(defalias 'bible-mode-get-ref 'bible-mode-get-link)
(defalias 'bible-mode-get-verse 'bible-mode-get-link)

(defun bible-mode-copy-link (&optional text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (thing-at-point 'line t)))

  (setq text (or text (thing-at-point 'line t)))

  (if (or (major-mode-p 'bible-mode)
          (major-mode-p 'bible-search-mode))
      (if (interactive-p)
          (xc (bible-mode-get-link text))
        (bible-mode-get-link text))
    nil))

(defun tmux-rename-current-window (name &optional win_id)
  (interactive (list (read-string "new tmux window name: ")))

  (if win_id
      (pen-snc (cmd "tmux" "renamew" "-t" (str win_id) name))
    (pen-snc (cmd "tmux" "renamew" name))))

(comment
 (defun bible-mode--display (&optional verse)
   "Renders text for `bible-mode'"
   (interactive)
   (setq buffer-read-only nil)
   (erase-buffer)

   (let ((tmux_win (tm-get-window)))

     (insert (bible-mode--exec-diatheke (concat "Genesis " (number-to-string bible-mode-global-chapter)) nil nil nil bible-mode-book-module))

     (let* (
            (html-dom-tree (libxml-parse-html-region (point-min) (point-max)))
            )
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

     (let* ((slug (slugify
                   (concat bible-mode-book-module
                           "-"
                           (or verse
                               (bible-mode-get-book-and-chapter)))))
            (bufname (generate-new-buffer-name (if (and (sor slug)
                                                        nil)
                                                   (concat "*bible-" slug "*")
                                                 (concat "*bible*"))))
            (tmuxname (concat
                       "("
                       bible-mode-book-module
                       " "
                       (s-replace-regexp
                        " "
                        ""
                        (bible-mode-get-book-and-chapter))
                       ")")))
       (rename-buffer bufname t)
       (tmux-rename-current-window tmuxname tmux_win)))

   (run-hooks 'bible-mode-hook)
   (pen-clear-message)))

(defun pen-highlight-line ()
  (interactive)
  ;; twice so the cursor moves past the initial whitespace
  (pen-comint-bol)
  (pen-comint-bol)
  (cua-set-mark)
  (end-of-line))

(defun spinner-start-around-advice (proc &rest args)
  (if (not (display-graphic-p))
      (pen-snc "spinner-start -b"))
  (let ((res (apply proc args)))
    res))
(advice-add 'spinner-start :around #'spinner-start-around-advice)
;; (advice-remove 'spinner-start #'spinner-start-around-advice)

(defun spinner-stop-around-advice (proc &rest args)
  (if (not (display-graphic-p))
      (pen-snc "spinner-stop"))
  (let ((res (apply proc args)))
    res))
(advice-add 'spinner-stop :around #'spinner-stop-around-advice)
;; (advice-remove 'spinner-stop #'spinner-stop-around-advice)

(defun bible-mode--display (&optional verse)
  "Renders text for `bible-mode'"
  (interactive)
  (setq buffer-read-only nil)
  (erase-buffer)
  (deselect)

  (message "Rendering page...")
  (spinner-start)

  (insert (bible-mode--exec-diatheke (concat "Genesis " (number-to-string bible-mode-global-chapter)) nil nil nil bible-mode-book-module))
  (let* (
         (html-dom-tree (libxml-parse-html-region (point-min) (point-max))))
    (erase-buffer)
    (bible-mode--insert-domnode-recursive (dom-by-tag html-dom-tree 'body) html-dom-tree)
    (message "Final tidying...")
    (bible-mode-display-final-tidy)
    (goto-char (point-min))
    (while (search-forward (concat "(" bible-mode-book-module ")") nil t)
      (replace-match ""))
    (goto-char (point-min))
    (redisplay))

  (message "Final tidying...")
  (setq mode-name (concat "Bible (" bible-mode-book-module ")"))
  (setq buffer-read-only t)
  (goto-char (point-min))
  ;; (message (concat ":" (number-to-string verse) ": "))

  (if (and verse (numberp verse))
      (progn
        ;; Can't use ": " because sometimes like with Psalms 40:1
        ;; there is no space
        ;; (goto-char (string-match (regexp-opt `(,(concat ":" (number-to-string verse) ":"))) (buffer-string)))
        (goto-char (string-match (concat ":" (str verse) ":") (buffer-string))))
    (goto-char (point-min)))

  (run-hooks 'bible-mode-hook)
  (spinner-stop)

  (pen-clear-message)

  ;; Sometimes 'verse' is just a number
  (if (or (and
           verse
           (and verse (numberp verse)))
          (and
           verse
           (re-match-p ":" (str verse))))
      (progn
        (pen-highlight-line)

        ;; Don't actually narrow it right now
        ;; because it's half-baked.
        ;; Instead, highlight the line.
        ;; (pen-copy-line)

        (comment
         (progn
           (beginning-of-line)
           (cua-set-mark)
           (end-of-line)
           (recursive-narrow-or-widen-dwim)
           (deselect))))))

;; Use hooks instead
;; nadvice - proc is the original function, passed in. do not modify
;; (defun bible-mode--display-around-advice (proc &rest args)
;;   (let ((res (apply proc args)))
;;     ;; (pen-generate-glossary-buttons-manually)
;;     ;; (message "%s" "Done.")

;;     res))
;; (advice-add 'bible-mode--display :around #'bible-mode--display-around-advice)
;; (advice-remove 'bible-mode--display #'bible-mode--display-around-advice)

(defset bible-mode-fast-enabled t)

(defun bible-mode-fast-toggle ()
   (interactive)
   (if bible-mode-fast-enabled
       (add-hook 'bible-mode-hook 'pen-generate-glossary-buttons-manually t)
     (remove-hook 'bible-mode-hook 'pen-generate-glossary-buttons-manually))
   (defset bible-mode-fast-enabled (not bible-mode-fast-enabled))
   (if bible-mode-fast-enabled
       (message "%s" "bible-mode-fast enabled")
     (message "%s" "bible-mode-fast disabled")))

(add-hook 'bible-mode-hook 'ov-highlight-load)


;; (defun pen-after-emacs-loaded-setup-biblemode ()
;;   (interactive)
;;   (bible-mode-fast-toggle)
;;   (bible-mode-fast-toggle))

;; (add-hook 'emacs-startup-hook 'pen-after-emacs-loaded-setup-biblemode t)


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
              ;; :background "#110000"
              ;; (put-text-property (- (point) (length (string-trim-right (s-replace-regexp "\n.*" "" subnode)))) (point) 'font-lock-face '(:foreground "#ff3333"))
              (put-text-property (- (point) (length (string-trim-right (s-replace-regexp "\n.*" "" subnode)))) (point) 'font-lock-face 'bible-jesus-words))
             ((plist-get iproperties 'divinename)
              ;; (put-text-property (- (point) (length (string-trim-right (s-replace-regexp "\n.*" "" subnode)))) (point) 'font-lock-face '(:foreground "orange" :background "#552200"))
              (put-text-property (- (point) (length (string-trim-right (s-replace-regexp "\n.*" "" subnode)))) (point) 'font-lock-face 'bible-divine-name)
              )

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
             (not bible-mode-fast-enabled)
             (or bible-mode-word-study-enabled
                 (member (dom-attr subnode 'savlm)
                         bible-strongs-always-show-xmllist)))
            ;; (plist-get iproperties 'jesus)
            ;; (plist-get iproperties 'divinename)

            ;;word study. Must be done after subnode is inserted recursively.

            (let* (
                   (savlm (dom-attr subnode 'savlm))

                   (iter 0)
                   floating
                   refstart
                   refend)
              (if (and (not bible-mode-fast-enabled) savlm)
                  ;; code
                  (progn
                    ;; Greek, hebrew and lemma are independant of each other

                    (let (
                          ;; used by greek only
                          (match 0)
                          (matchstrlen 0))
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
                                (setq matchstrlen strongs_code_len)
                                (insert (concat strongs_code " " strongs_word))

                                (let ((refstart (- (point)
                                                   strongs_len))
                                      (refend (+ (- (point)
                                                    strongs_len)
                                                 strongs_code_len)))
                                  (put-text-property refstart refend 'face 'bible-codes)
                                  (cond ((re-match-p "^G" strongs_code)
                                         (put-text-property refstart refend 'keymap bible-mode-greek-keymap))
                                        ((re-match-p "^H" strongs_code)
                                         (put-text-property refstart refend 'keymap bible-mode-hebrew-keymap))
                                        (t
                                         nil)))
                                (let ((refstart (- (point)
                                                   strongs_word_len
                                                   ;; matchstrlen
                                                   ))
                                      (refend (point)))
                                  (if (member (str2sym strongs_code)
                                              bible-strongs-always-show-codelist)
                                      (put-text-property refstart refend 'face 'bible-greek-always)
                                    (put-text-property refstart refend
                                                       'face 'bible-greek))))))
                        (setq match (string-match "[GH][0-9]+" savlm (+ match matchstrlen)))))

                    (if (string-match "lemma.TR:.*" savlm) ;;Lemma
                        (let* ((strongs_code (match-string 0 savlm))
                               (strongs_word (bible-term-get-word strongs_code)))
                          (dolist (word (split-string strongs_code " "))
                            (setq word (replace-regexp-in-string "[.:a-zA-Z0-9]+" "" word))
                            (insert " " word)
                            (setq refstart (- (point) (length word))
                                  refend (point))
                            (put-text-property refstart refend 'face 'bible-lemma)
                            (put-text-property refstart refend 'keymap bible-mode-lemma-keymap))))

                    (comment
                     (if (string-match "strong:H.*" savlm) ;;Hebrew
                         (let* ((strongs_code (match-string 0 savlm))
                                (strongs_word (bible-term-get-word strongs_code)))
                           (dolist (word (split-string strongs_code " "))
                             (setq iter (+ iter 1))
                             (setq word (replace-regexp-in-string "strong:" "" word))
                             (insert (if (eq iter 1) "" " ") word)
                             (setq refstart (- (point) (length word))
                                   refend (point))
                             (put-text-property refstart refend 'face 'bible-hebrew)
                             (put-text-property refstart refend 'keymap bible-mode-hebrew-keymap))))))))
          (insert)))))

  (if (equal (dom-tag node) 'title) ;;newline at end of title (i.e. those in Psalms)
      (insert "\n"))
  (if (not bible-mode-fast-enabled)
      (redisplay))
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

(defun bible-search-phrase (query &optional module range search-on-search)
  (interactive
   (let ((current-book-and-chap
          (let* ((tup (bible-mode-get-ref-tuple))
                 (book (car tup))
                 (chap (str (cadr tup)))
                 (re (concat "\\(" book " " chap ":\\|" book "\\)")))
            re)))
     (if (>= (prefix-numeric-value current-prefix-arg) 4)
         (let ((book (fz-bible-book "Bible Search (book): "))
               (query (pen-ask (pen-selection) "Bible Search: ")))
           (list query nil book current-book-and-chap))
       (list (pen-ask (pen-selection) "Bible Search: ") nil nil current-book-and-chap))))
  (bible-mode--open-search query "phrase" (or module default-bible-mode-book-module) range
                           search-on-search))

(defun bible-search-mode-select-book ()
  (interactive)
  (nasb)
  (bible-mode-select-book))

(defun fz-bible-book (&optional prompt)
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

(defun bible-mode-cross-references-ext (ref)
  (interactive (list (bible-mode-get-link (thing-at-point 'line t))))
  (let ((link (concat "https://www.openbible.info/labs/cross-references/search?q=" (urlencode (openbible-canonicalise-ref ref)))))
    (message "%s" (concat "Visiting: " link))
    (eww link)))

(defun bible-mode-cross-references (ref)
  (interactive (list
                (let ((current-prefix-arg nil))
                  (bible-mode-get-link (thing-at-point 'line t)))))
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (let ((current-prefix-arg nil))
        (bible-mode-cross-references-ext ref))
    (etv (snc "in-pen bible-get-cross-references | wrlp cif bible-canonicalise-cross-reference" ref))))

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
         (word
          ;; This isn't the main bottleneck
          (if info
              (snc "sed 's/ \\+/ /g' | cut -d ' ' -f 3" (car (str2lines info))))))
    word))

;; This speeds it up a lot
;; I should ensure that the memoization databases are saved on the host
(memoize 'bible-term-get-word)
;; (memoize-restore 'bible-term-get-word)

;; TODO Make it so it resumes the same place
(defun bible-mode-toggle-word-study()
  "Toggles the inclusion of word study for the active `bible-mode' buffer."
  (interactive)
  (setq bible-mode-word-study-enabled (not bible-mode-word-study-enabled))
  (if (equal major-mode 'bible-search-mode)
      (bible-mode--display-search bible-mode-search-query bible-mode-search-mode)
    (bible-mode--display)))

(defun bible-random-verse-ref ()
  (interactive)
  (let* ((book (pen-snc "db-bible-book-list| sort -R | head -n 1"))
         (chapter (+ 1 (random (string-to-int (pen-snc (cmd "db-bible-book-max-chapter" book))))))
         (verse (+ 1 (random (string-to-int (pen-snc (cmd "db-bible-book-chapter-max-verse" book chapter)))))))

    (bible-mode-lookup-ref (concat book " " (str chapter) ":" (str verse)))))

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

(defun count-chars (char str)
  (let ((s (char-to-string char))
        (count 0)
        (start-pos -1))
    (while (setq start-pos (string-search s str (+ 1 start-pos)))
      (setq count (+ 1 count)))
    count))

(defun tpop-fit-vim-string (s)
  (let* ((nlines
          ;; (snc "wc -l" s)
          (count-chars ?\n s))
         (lines (string2list s))
         (first_line (car lines))
         (slug (slugify first_line t)))
    (tpop
     ;; (concat "pa -E \"tf -sha -X " slug " txt | xa colvs -nls -num\"")
     (concat "pa -E \"tf -sha -X " slug " txt | xa v -nls -num\"")
     s
     :x_pos "M+1"
     :y_pos "M+1"
     :bg 233
     :width_pc 55
     :height_pc (+ 4 ;; (string-to-int nlines)
                   nlines)
     ;; 20
     :style "heavy")))

(defun bible-mode-tpop (ref)
  (interactive (list (or (bible-mode-copy-link)
                         (read-string-hist "Bible ref: "))))
  (let* ((concordance_arg
          (cond
           ((>= (prefix-numeric-value current-prefix-arg) 64) "-cac")
           ((>= (prefix-numeric-value current-prefix-arg) 16) "-ca")
           ((>= (prefix-numeric-value current-prefix-arg) 4) "-c")
           (t (if (and
                   (major-mode-p 'bible-mode)
                   bible-mode-word-study-enabled)
                  "-ca"
                "-c"))))
         (current-prefix-arg nil)
         (s (snc (cmd "bible-tpop-lookup"
                      concordance_arg
                      "-m" bible-mode-book-module ref))))

    (tpop-fit-vim-string s)

    ;; (tpop (cmd "nem" "fast" "ebible"
    ;;            concordance_arg
    ;;            "-m" bible-mode-book-module (bible-mode-copy-link))
    ;;       nil
    ;;       :x_pos "M+1"
    ;;       :y_pos "M+1"
    ;;       :bg 233
    ;;       :width_pc 55
    ;;       :height_pc 20
    ;;       :style "heavy")
    ))

(defun bible-mode-show-definition ()
  (interactive)
  (cond
   ;; TODO Translate Maori into English, then look up word in theological dictionary
   ;; TODO Translate theological dictionary definition into Maori
   ((string-equal "Maori" bible-mode-book-module) (call-interactively 'maori-dictionary))
   ;; TODO Use theological dictionaries
   ;; https://www.swordsearcher.com/resources.html
   (t (call-interactively 'wordnut-lookup-current-word))
   ;; (t nil)
   ))

(comment
 (defmacro closure (vars &rest body)
   ""
   (let ((assignments (-zip-lists vars (mapcar 'eval vars))))
     (tv
      `(lambda ()
         (interactive)
         (let ,assignments
           ,@body)))))

 ;; This will capture a closure lambda, which I can rerun independently
 (defmacro capture (vars &rest body)
   ""
   (let* ((assignments (-zip-lists vars (mapcar 'eval vars)))
          (f `(lambda ()
                (interactive)
                (let ,assignments
                  ,@body))))
     (tv f)
     (f)))

 (defmacro memo (vars &rest body)
   ""
   (let* ((assignments (-zip-lists vars (mapcar 'eval vars)))
          (bodyform `(let ,assignments
                       ,@body))
          (form `(dff
                  (eval
                   ',bodyform)))
          (f_sym (dff-sym bodyform))
          ;; (show_form (tv form))
          ;; idempotent (I think it is)
          (f_sym
           (if (commandp f_sym)
               f_sym
             (progn
               (tv "redefining")
               (eval form)))))

     ;; (tv f_sym)
     ;; (tv f_sym)
     ;; Hopefully, this is idempotent (I think it is)
     ;; (memoize-restore f_sym)
     (if (not (memoize-exists-p f_sym))
         (memoize f_sym))
     (tv f_sym)
     ;; does this execute the memoized version? It *SHOULD*
     `(,f_sym)))

 (defmacro unmemo (vars &rest body)
   ""
   (let* ((assignments (-zip-lists vars (mapcar 'eval vars)))
          (bodyform `(let ,assignments
                       ,@body))
          (form `(dff
                  (eval
                   ',bodyform)))
          (f_sym (dff-sym bodyform))
          ;; (show_form (tv form))
          ;; idempotent (I think it is)
          (f_sym
           (if (commandp f_sym)
               f_sym
             ;; (eval form)
             )))

     ;; (tv f_sym)
     ;; Hopefully, this is idempotent (I think it is)
     (if f_sym
         (if (memoize-exists-p f_sym)
             (memoize-restore f_sym)))
     nil
     ;; (ignore-errors (memoize f_sym))
     ;; `(,f_sym)
     ))

 ;; TODO Make the memo macro
 (defun test-memo ()
   (interactive)
   (let ((info_a "about a\nstory book")
         (info_b "about a\nmystery"))
     (unmemo (info_a info_b)
             (tv "firstrun")
             (snc "tr -s a A" (car (str2lines (concat info_a info_b))))))
   (let ((info_a "about a\nstory book")
         (info_b "about a\nmystery"))
     (memo (info_a info_b)
           (tv "firstrun")
           (snc "tr -s a A" (car (str2lines (concat info_a info_b))))))))

(defun bible-e-chapter-titles ()
  (interactive)
  (if (interactive-p)
      (find-file (umn "$PEN/documents/notes/ws/peniel/Bible-chapter-titles.txt"))
    (cat "$PEN/documents/notes/ws/peniel/Bible-chapter-titles.txt")))

(defun bible-e-outlines ()
  (interactive)
  (if (interactive-p)
      (find-file (umn "$PEN/documents/notes/ws/peniel/Bible-outlines.txt"))
    (cat "$PEN/documents/notes/ws/peniel/Bible-outlines.txt")))

;; (memoize-restore 'dff-let-nil-let-info-a-about-a-nstory-book-info-b-about-a-nmystery-tv-firstrun-snc-tr-s-a-a-car-str2lines-concat-info-a-info-b-)
;; (memoize 'dff-let-nil-let-info-a-about-a-nstory-book-info-b-about-a-nmystery-tv-firstrun-snc-tr-s-a-a-car-str2lines-concat-info-a-info-b-)

(defun bible-mode-next-book ()
  "Pages to the next book for the active `bible-mode' buffer."
  (interactive)

  ;; bible-mode-book-chapters

  (bible-mode--set-global-chapter (+ bible-mode-global-chapter 1)))

;; Where object-orientation is useful is with getters and setters
;; to make abstractions such as 'iterable'/arraylike
(defun current-book-number ()
  (let (;; (global-chapter bible-mode-global-chapter)
        (book (car bible-mode-ref-tuple))
        (chapter (cadr bible-mode-ref-tuple))
        (verse (caddr bible-mode-ref-tuple)))

    ;; (assoc "Leviticus" bible-mode-book-chapters)
    ;; (-find (lambda (e) (string-equal "Leviticus" (car e))) bible-mode-book-chapters)
    ;; (-find-index (lambda (e) (string-equal "Leviticus" (car e))) bible-mode-book-chapters)

    ;; Interestingly, this lambda has access to book
    (+ 1 (-find-index (lambda (e) (string-equal book (car e))) bible-mode-book-chapters))
    ;; Get the index
    ;; verse
    ))

(define-key bible-mode-map (kbd "M-t") 'bible-mode-tpop)
(define-key bible-mode-map (kbd "M-e") 'view-notes-fp-verse)
(define-key bible-mode-map (kbd "M-v") nil)
(define-key bible-mode-map (kbd "M-V") 'view-notes-fp-verse-v)
(define-key bible-mode-map (kbd "e") 'bible-mode-open-notes-for-verse)
(define-key bible-mode-map (kbd "o") 'bible-mode-verse-other-version)
(define-key bible-mode-map (kbd "d") 'bible-mode-toggle-word-study)
(define-key bible-mode-map (kbd "w") 'bible-mode-copy-link)
(define-key bible-mode-map (kbd "M-w") 'bible-mode-copy-link)

(define-key bible-mode-map "n" 'bible-mode-next-chapter)
;; next title / outline would also be cool
(define-key bible-mode-map "N" 'bible-mode-next-book)
(define-key bible-mode-map "p" 'bible-mode-previous-chapter)
(define-key bible-mode-map "b" 'bible-mode-select-book)
(define-key bible-mode-map "g" 'bible-mode--display)
(define-key bible-mode-map "c" 'bible-mode-select-chapter)
(define-key bible-mode-map "s" 'bible-search-phrase)
(define-key bible-mode-map "z" 'bible-mode-fuzzy-search)
(define-key bible-mode-map "S" 'bible-search-lucene)
(define-key bible-mode-map "m" 'bible-mode-select-module)
;; (define-key bible-mode-map "x" 'bible-mode-split-display)
(define-key bible-mode-map "x" 'bible-mode-cross-references)
(define-key bible-mode-map "l" 'bible-mode-lookup-ref)

(define-key bible-search-mode-map "s" 'bible-search-phrase)
(define-key bible-search-mode-map "z" 'bible-mode-fuzzy-search)
(define-key bible-search-mode-map "S" 'bible-search-lucene)
(define-key bible-search-mode-map "b" 'bible-search-mode-select-book)
(define-key bible-search-mode-map "x" 'bible-mode-cross-references)
(define-key bible-search-mode-map "g" nil)

(define-key bible-search-mode-map (kbd "M-t") 'bible-mode-tpop)
(define-key bible-search-mode-map (kbd "M-e") 'view-notes-fp-verse)
(define-key bible-search-mode-map (kbd "M-v") nil)
(define-key bible-search-mode-map (kbd "M-V") 'view-notes-fp-verse-v)
(define-key bible-search-mode-map (kbd "e") 'bible-mode-open-notes-for-verse)
(define-key bible-search-mode-map (kbd "o") 'bible-mode-verse-other-version)
(define-key bible-search-mode-map (kbd "d") 'bible-mode-toggle-word-study)
(define-key bible-search-mode-map (kbd "w") 'bible-mode-copy-link)
(define-key bible-search-mode-map (kbd "M-w") 'bible-mode-copy-link)

(define-key bible-search-mode-map (kbd "RET") 'bible-search-mode-follow-verse)

(defun bible-term-greek-at-point ()
  (interactive)
  (bible-term-greek (replace-regexp-in-string "[^0-9]*" "" (thing-at-point 'word t))))

(defun bible-term-hebrew-at-point ()
  (interactive)
  (bible-term-hebrew (replace-regexp-in-string "[a-z]+" "" (thing-at-point 'word t))))

(define-key bible-mode-greek-keymap (kbd "RET") 'bible-term-greek-at-point)
(define-key bible-mode-lemma-keymap (kbd "RET") (lambda ()(interactive)))
(define-key bible-mode-hebrew-keymap (kbd "RET") 'bible-term-hebrew-at-point)

(define-key bible-mode-greek-keymap (kbd "<mouse-1>") 'bible-term-greek-at-point)
(define-key bible-mode-lemma-keymap (kbd "<mouse-1>") (lambda ()(interactive)))
(define-key bible-mode-hebrew-keymap (kbd "<mouse-1>") 'bible-term-hebrew-at-point)

(defun bible-open-default ()
  (interactive)
  (if (selected-p)
      (call-interactively-with-prefix-and-parameters 'bible-search-phrase
                                                     (prefix-numeric-value current-prefix-arg)
                                                     (pen-selection))
    (bible-open-version default-bible-mode-book-module)))

;; (define-key global-map (kbd "H-v") 'nasb)
(define-key global-map (kbd "H-v") 'bible-open-default)
;; (define-key global-map (kbd "H-v") 'rlt)
(define-key bible-mode-map (kbd "v") 'bible-mode-select-module)

(defun pen-bible-set-margins ()
  ;; perfect-margin-mode doesn't work for Bible-mode.
  ;; (perfect-margin-mode 1)

  ;; I have to do it manually.
  ;; (set-window-margins (selected-window) 20 20)
  ;; But there are still issues with it.
  )
;; (add-hook 'bible-mode-hook 'pen-bible-set-margins)
(remove-hook 'bible-mode-hook 'pen-bible-set-margins)

;; (bible-mode-fuzzy-search "out of my hand")
(defun bible-mode-fuzzy-search (query)
  (interactive (list (read-string-hist "Bible fuzzy phrase search:")))
  (let* ((results
          (sor
           (if (>= (prefix-numeric-value current-prefix-arg) 4)
               (pen-snc (concat "ocif diatheke-regex-search-multi " query))
             (pen-snc (concat "ocif diatheke-regex-search-multi -fv " default-bible-mode-book-module " " query)))))
         (sel
          (if results
              (fz results nil nil "Bible fuzzy phrase search results:"))))

    (if (sor sel)
        (let ((ref
               (s-replace-regexp ": $" "" (s-replace-regexp "\\(.*[0-9]: \\).*" "\\1" sel))))
          (bible-mode-lookup-ref ref)))))

(define-key bible-mode-map (kbd "F") 'bible-mode-fast-toggle)


(defset bible-chapter-titles-fp (umn "$PEN/documents/notes/ws/peniel/Bible-chapter-titles.txt"))
(defset bible-passage-outlines-fp (umn "$PEN/documents/notes/ws/peniel/Bible-outlines.txt"))

;; (bible-get-chapter-title "Genesis" "30")
;; (bible-get-chapter-title "Leviticus" "6")
;; e:bible-get-chapter-title.els
(defun bible-get-chapter-title (book chapter)
  (interactive (list (read-string "Book: ")
                     (read-string "Chapter: ")))
  (with-temp-buffer
    (ignore-errors (insert-file-contents bible-chapter-titles-fp))
    (search-forward-regexp (concat "^" book))
    (search-forward-regexp (concat "\\b" (str chapter) "[,.]"))
    (beginning-of-line)
    (search-forward-regexp "\\. ")
    (let ((start (point))
          (end (progn
                 (end-of-line)
                 (point))))
      (buffer-substring start end))))

(defun bible-mode-read-chapter-aloud-kjv ()
  (interactive)
  (let ((reftuple (bible-mode-get-ref-tuple)))
    (if reftuple
        (let* ((dir "/volumes/home/shane/dump/torrents/The Holy Bible - Audio Bible - King James Version - Alexander Scourby - Voice of The Bible/")
               (booknumber (str (current-book-number)))
               (book-chapter (str (cadr bible-mode-ref-tuple)))
               (regex (concat "^0*" booknumber " .* 0*" book-chapter ".mp3"))
               (fileslisting (list2str (mapcar 'f-basename (f-files dir))))
               (filename (e/grep regex fileslisting 'pcre)))
          (nw (cmd "mplayer" (f-join dir filename))
              "-d"))
      (message "Open the Bible first"))))

(define-key bible-mode-map (kbd "K") 'bible-mode-read-chapter-aloud-kjv)
(define-key bible-mode-map (kbd "M") 'magit-toggle-margin)

(defun bible-verse-margin-status ()
  (chomp (pps (bible-mode-get-ref-tuple))))

(defun bible-mode-show-hover-docs ()
  (interactive)
  (pen-custom-lsp-ui-doc-display
   (pen-snc (concat (cmd "nbd" "ebible" "-m" bible-mode-book-module (bible-mode-copy-link)) " | cat"))
   (bible-verse-margin-status)))

(defun bible-open-interlinear ()
  (interactive)
  (let* ((tup (bible-mode-get-ref-tuple))
         (book-lc (downcase (car tup)))
         (chap (str (cadr tup)))
         (verse (str (caddr tup))))
    (w3m (format "https://biblehub.com/interlinear/%s/%s-%s.htm" book-lc chap verse))))

(define-key bible-mode-map (kbd "D") 'bible-mode-show-hover-docs)
(define-key bible-mode-map (kbd "I") 'bible-open-interlinear)

(defun bible-fz-chapter-titles ()
  (interactive)
  (fz (str2lines (e/cat bible-chapter-titles-fp))))

(defun bible-fz-passage-outlines ()
  (interactive)
  (fz (str2lines (e/cat bible-passage-outlines-fp))))

(provide 'pen-bible-mode)
