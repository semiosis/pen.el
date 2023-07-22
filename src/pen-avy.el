(require 'avy)
(require 'ace-link)

(setq avy-all-windows nil)

;; For avy-goto-char-timer
(setq avy-timeout-seconds 0.2)

(defun avy-goto-char-all-windows (args)
  (interactive "P")
  (let ((avy-all-windows t))
    (call-interactively #'avy-goto-char)))

(defun avy-goto-char-enter ()
  "Go to a char with avy and then press 'Enter'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "C-m"))

(defun avy-goto-char-9 ()
  "Go to a char with avy and then press M-9"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-9"))

(defun avy-goto-link-or-button-w ()
  "Go to a char with avy and then press 'w' for copy"
  (interactive)
  (call-interactively 'ace-link-goto-link-or-button)
  (if (not (eq (key-binding "w") 'self-insert-command))
      (ekm "w")
    (message "No button/link address here to copy")))

(defun avy-goto-char-doc ()
  "Go to a char with avy and then press 'M-9'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-9"))

(defun avy-goto-char-goto-def ()
  "Go to a char with avy and then press 'M-.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "M-."))

(defun simulate-left-click ()
  (interactive)
  (pen-cl-sn "tmux run -b \"pen-tm mouseclick\"" :detach t))

(defun simulate-right-click ()
  (interactive)
  (pen-cl-sn "tmux run -b \"pen-tm mouseup -x -r\"" :detach t))

(defun avy-goto-char-left-click ()
  "Go to a char with avy and then left click with tmux.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (simulate-left-click))

(defun avy-goto-char-right-click ()
  "Go to a char with avy and then right click with tmux.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (simulate-right-click))

(defun avy-goto-char-c-o ()
  "Go to a char with avy and then type =C-c C-o=.'"
  (interactive)
  (call-interactively #'avy-goto-char)
  (ekm "C-c C-o"))

(defun avy-new-buffer-from-tmux-pane-capture ()
  (interactive)
  (with-current-buffer (pen-tmux-pane-capture t)
    (call-interactively 'avy-goto-char)))

(defun ace-link-goto-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (buttons-collect))
     (avy--style-fn avy-style))))

(defun ace-link-goto-widget ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-widgets-collect))
     (avy--style-fn avy-style))))

(defun ace-link-or-button-collect ()
  (-union
   (-union (-union
            (ace-link--help-collect)
            (ace-link--org-collect))
           (buttons-collect))
   (pen-widgets-collect)))

(defun ace-link-goto-link-or-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (ace-link-or-button-collect))
     (avy--style-fn avy-style))))

(defun ace-link-goto-glossary-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-glossary-buttons-collect))
     (avy--style-fn avy-style))))

(defun ace-link-click-glossary-button ()
  (interactive)
  (ignore-errors
    (avy-with ace-link-help
      (avy-process
       (mapcar #'cdr (pen-glossary-buttons-collect))
       (avy--style-fn avy-style)))
    (push-button)))

(defun ace-link-click-button ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (buttons-collect))
     (avy--style-fn avy-style)))
  (push-button))

(defun ace-link-click-widget ()
  (interactive)
  (avy-with ace-link-help
    (avy-process
     (mapcar #'cdr (pen-widgets-collect))
     (avy--style-fn avy-style)))
  (widget-button-press (point)))

(defun avy-jump-around-advice (proc &rest args)
  (lsp-ui-doc-hide)
  (let ((res (apply proc args)))
    res))
(advice-add 'avy-jump :around #'avy-jump-around-advice)

;; This fixes the glossary sometimes
(advice-add 'avy--overlay :around #'ignore-errors-around-advice)

(defun link-hint-copy-link ()
  "Copy a visible link of a supported type to the kill ring with avy.
`select-enable-clipboard' and `select-enable-primary' can be set to non-nil
values to copy the link to the clipboard and/or primary as well."
  (interactive)
  (avy-with link-hint-copy-link
    (link-hint--one :copy)))

(defun link-hint--button-at-point-p ()
  "Return the button at the point or nil."
  (let ((button (button-at (point))))
    (when button
      (cond
       ((derived-mode-p 'org-brain-visualize-mode)
        (try (org-brain-get-path-for-child-name (org-brain-entry-name (org-brain-entry-from-id (button-get button 'id))))
             (and (button-get button 'id)
                  (org-brain-get-path-for-entry (button-label button)))
             (button-label button)))
       (t
        (button-label button))))))

;; (buttons-collect)
;; (("Psalms 27:10" . 1)
;;  ("Psalms 103:13" . 87))

;; File looks like this: (i.e. 1 means the first char).
;; Psalms 27:10: When my father and my mother forsake me, then the Lord will take me up.
;; Psalms 103:13: Like as a father pitieth his children, so the Lord pitieth them that fear him.
;; psalms

;; cat $HOME/.emacs.d/host/pen.el/src/pen-avy.el | scrape-bible-references | parallel --pipe -L 10 -N1 words-to-avy-tuples -nbe $HOME/.emacs.d/host/pen.el/src/pen-avy.el | v
;; cat $HOME/.emacs.d/host/pen.el/src/pen-avy.el | scrape-bible-references | parallel --group --pipe -l 10 --halt never -j 1 -N1 words-to-avy-tuples -nbe $HOME/.emacs.d/host/pen.el/src/pen-avy.el | uniqnosort

;; TODO Make it only use the visible window contents instead of (buffer-string)
;; Use (window-start) to get the starting byte.
;; It's already not using buffer-file-name, so it should be easy
(defun filter-cmd-collect (filter-cmd &optional fp-or-buf)
  (let* ((tempf
          (cond
           ((not fp-or-buf)
            (with-current-buffer
                (current-buffer)
              (pen-tf "avy-bible" (buffer-string))))
           ((bufferp fp-or-buf)
            (with-current-buffer
                fp-or-buf
              (pen-tf "avy-bible" (buffer-string))))
           ((and
             (stringp fp-or-buf)
             (f-file-p fp-or-buf))
            (pen-tf "avy-bible" (e/cat fp-or-buf)))
           ((f-file-p buffer-file-name)
            (pen-tf "avy-bible" (e/cat buffer-file-name)))))
         (winstart (window-start))
         (winend (window-end))

         (input (cond
                 ((and
                   (stringp tempf)
                   (f-file-p tempf))
                  (e/cat tempf))
                 (t
                  (buffer-string))))

         ;; Because this always needs a file, I should just simplify all this by creating a temp file
         (tuples (pen-eval-string
                  (concat
                   "'("
                   (pen-sn (concat filter-cmd "| pen-sort line-length-desc |" "serialsplit -l 10 words-to-avy-tuples -nbe " (pen-q tempf) " | uniqnosort")
                           input
                           nil)
                   ")"))))

    ;; Only delete it if it is a temp file
    (if (and (stringp tempf)
             (f-file-p tempf))
        (f-delete tempf))

    (-filter (lambda (tp) (and
                           (>= (cdr tp) winstart)
                           (<= (cdr tp) winend)))
             (mapcar (lambda (tp) (cons (car tp)
                                        (byte-to-position (+ 1 (cdr tp)))))
                     tuples)))

  ;; (etv (pen-sn (concat (pen-q fp-or-buf) "|" filter-cmd "|" "words-to-avy-tuples " (pen-q fp-or-buf))))
  ;; (append (buttons-collect 'glossary-button-face)
  ;;         (buttons-collect 'glossary-candidate-button-face)
  ;;         (buttons-collect 'glossary-error-button-face))
  )

(defvar bible-book-map-names
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
    ("Psalms" "Ps" "Psalm" "Pslm" "Psa" "Psm" "Pss")
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

;; | =M-j M-v= | =ace-link-bible-ref= | =pen-map=
(defun ace-link-bible-ref ()
  (interactive)
  (ace-link-goto-filter-cmd-button "scrape-bible-references" 'bible-mode-lookup))

;; TODO Make a binding for this
(defun ace-link-filter-ref ()
  (interactive)

  ;; I should also have actions associated with each filter

  ;; (ace-link-goto-filter-cmd-button (select-filter) 'bible-mode-lookup)
  (ace-link-goto-filter-cmd-button (select-filter) nil))

(defun ace-link-goto-filter-cmd-button (filter-script callback)
  (interactive (list (read-string "Filter script: ")))

  ;; OK, so without buttons I can go to something.
  ;; But how do I perform an action on it without without buttons?
  ;; I may need a separate function to see what ones exist at the point,
  ;; and choose an action based on that.

  ;; (filter-cmd-collect "scrape-bible-references" buffer-file-name)

  (let ((wordtuples
         ;; filter-cmd-collect handles nil buffer path
         (filter-cmd-collect filter-script
                             ;; This could be nil, ie. for *scratch*
                             buffer-file-name)))
      (avy-with ace-link-help
      (let ((avy-action
             (eval
              `(lambda (pt)
                 (avy-action-goto pt)
                 (let ((result
                        (cl-loop for tp in ',wordtuples
                                 until (looking-at-p (car tp))
                                 finally return (car tp))))
                   (let ((cb ',callback))
                     (if (and result
                              cb)
                         (if (stringp cb)
                             (pen-snc (concat cb (pen-q result)))
                           (call-function cb result)))))))))
        (avy-process
         ;; There doesn't appear to be an easy way to get the avy string
         ;; Well, it's discarded here.
         ;; So I need to run the filter again
         (mapcar #'cdr wordtuples)
         (avy--style-fn avy-style))))))

(define-key pen-map (kbd "M-j M-v") 'ace-link-bible-ref)

(provide 'pen-avy)
