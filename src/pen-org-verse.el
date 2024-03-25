;; https://github.com/DarkBuffalo/org-verse

(define-button-type 'org-verse-button
  'action #'org-verse-button-verse
  'follow-link t
  'face 'org-verse-number-face
  'help-echo "Clic le boutton pour lire le verset."
  'help-args "test")

(defconst org-verse-pattern
  (rx  (group  (or (or "Genèse" "Gen" "Gn")
                   (or "Exode" "Ex")
                   (or "Lévitique" "Lev" "Lv")
                   (or "Nombres" "Nb")
                   (or "Deutéronome" "Deut" "Dt")
                   (or "Josué" "Jos")
                   (or "Juges" "Jg")
                   (or "Ruth" "Ru")
                   (or "1 Samuel" "1S" "1Sam" "1 Sam")
                   (or "2 Samuel" "2S" "2Sam" "2 Sam")
                   (or "1 Rois" "1R" "1 R")
                   (or "2 Rois" "2R" "2 R")
                   (or "1 Chroniques" "1Ch" "2 Ch")
                   (or "2 Chroniques" "2Ch" "2 Ch")
                   (or "Esdras" "Esd")
                   (or "Néhémie" "Né" "Ne")
                   (or "Esther" "Est")
                   (or "Job" "Jb")
                   (or "Psaumes" "Ps")
                   (or "Proverbes" "Prov" "Pro" "Pr")
                   (or "Ecclésiaste" "Ecc" "Ec" "Ecl")
                   (or "Chant de Salomon" "Ct")
                   (or "Isaïe" "Is")
                   (or "Jérémie" "Jer" "Jr")
                   (or "Lamentations" "Lam" "Lm")
                   (or "Ézéchiel" "Ez")
                   (or "Daniel" "Dan" "Dn")
                   (or "Osée" "Os")
                   (or "Joël" "Jl")
                   (or "Amos" "Am")
                   (or "Abdias" "Ab")
                   (or "Jonas" "Jon")
                   (or "Michée" "Mi")
                   (or "Nahum" "Na")
                   (or "Habacuc" "Hab")
                   (or "Sophonie" "Soph" "Sph")
                   (or "Aggée" "Ag")
                   (or "Zacharie" "Za")
                   (or "Malachie" "Ml")
                   (or "Matthieu" "Matt" "Mt")
                   (or "Marc" "Mc")
                   (or "Luc" "Lc")
                   (or "Jean" "Je")
                   (or "Actes" "Ac")
                   (or "Romains" "Rom" "Rm")
                   (or "1 Corinthiens" "1Co" "1Cor" )
                   (or "2 Corinthiens" "2Co" "2Cor")
                   (or "Galates" "Ga")
                   (or "Éphésiens" "Eph")
                   (or "Philippiens" "Php")
                   (or "Colossiens" "Col")
                   (or "1 Thessaloniciens" "1Th")
                   (or "2 Thessaloniciens" "2Th")
                   (or "1 Timothée" "1Tm" "1Tim")
                   (or "2 Timothée" "2Tm" "2Tim")
                   (or "Tite" "Tt")
                   (or "Philémon" "Phm")
                   (or "Hébreux" "Hé" "He")
                   (or "Jacques" "Jc")
                   (or "1 Pierre" "1Pierre" "1P")
                   (or "2 Pierre" "2Pierre" "2P")
                   (or "1 Jean" "1J")
                   (or "2 Jean" "2J")
                   (or "3 Jean" "3J")
                   (or "Jude")
                   (or "Révélation" "Rév" "Ré" "Re" "Rv")))
       space
       (group (1+ digit))
       ":"
       (group (or
               (group (group(any digit))"-"(group (1+ digit)":"(1+ digit)))
               (group (1+ (1+ digit )(0+ ","))))))
  "Generic regexp for number highlighting.
It is used when no mode-specific one is available.")

(defun org-verse-buttonize-buffer ()
  "Turn all verse into button."
  ;; For some reason, overlays accumulate if a buffer
  ;; is visited another time, making emacs slower and slower.
  ;; Hack is to remove them all first.
  ;; remove-overlays does not seem to exist for older emacsen (<23.x.x?)
  (interactive)
  (if (fboundp 'remove-overlays)
      (remove-overlays))

  (save-excursion
    (goto-char (point-min))
    (while (search-forward-regexp org-verse-pattern nil t)
      ;;recuperer le contenu de la recherche pour le mettre en titre
      ;;https://github.com/Kinneyzhang/gkroam/blob/b40555f45a844b8fefc419cd43dc9bf63205a0b4/gkroam.el#L708
      (let ((title (match-string-no-properties 0))
            (book (match-string-no-properties 1))
            (chapter (match-string-no-properties 2))
            (verses (match-string-no-properties 3)))
        ;;créer les bouttons
        (make-text-button (match-beginning 0)
                          (match-end 0)
                          :type 'org-verse-button
                          ;;inserer le titre recuperer plus haut
                          'title title
                          'book book
                          'chapter chapter
                          'verses verses)))))

(define-minor-mode org-verse-mode "Highlight bible verses."
  :init-value nil
  :lighter " verse"
  :keymap org-verse-mode-keymap
  :group 'verse
  (org-verse--turn-off)
  (if org-verse-mode
      (progn
        (org-verse--turn-on)
        (add-hook 'after-save-hook #'org-verse-buttonize-buffer)))

  (when font-lock-mode
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (with-no-warnings (font-lock-fontify-buffer)))))

;; (add-hook 'org-verse-mode-hook
;;           (function
;;            (lambda ()
;;              (setq case-fold-search t))))

(add-hook 'org-mode-hook 'org-verse-mode)

(provide 'pen-org-verse)
