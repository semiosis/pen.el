(require 'chemtable)
(require 'chembalance)

;; I made up these concepts:
;; s-series
;; d-series
;; p-series
;; d-series
;; For the purposes of learning to write electron configurations

;; s-series
(defsetface chemtable-hl-1-face
  '((t :foreground "#d2268b"
       :background "#2e2e2e"
       ;; :weight bold
       :underline t))
  "Face for highlighting specific `chemtable' elements."
  :group 'chemtable)

;; p-series
(defsetface chemtable-hl-2-face
  '((t :foreground "#8bd226"
       :background "#2e2e2e"
       ;; :weight normal
       :italic t
       :underline t))
  "Face for highlighting specific `chemtable' elements."
  :group 'chemtable)

;; d-series
(defsetface chemtable-hl-3-face
  '((t :foreground "#8b26d2"
       :background "#2e2e2e"
       ;; :weight normal
       ;; :italic t
       :underline t))
  "Face for highlighting specific `chemtable' elements."
  :group 'chemtable)

;; f-series
(defsetface chemtable-hl-4-face
  '((t :foreground "#660000"
       ;; :weight normal
       :strike-through t))
  "Face for highlighting specific `chemtable' elements."
  :group 'chemtable)

(defsetface chemtable-hl-other-face
            '((t :foreground "#999999"
                 ;; :background "#2e2e2e"
                 :weight bold
                 :underline nil))
            "Face for highlighting specific `chemtable' elements."
            :group 'chemtable)

;; TODO Make it so I can highlight sets of elements

;; For example:

(defset chem-s-series '(2 4 12 30))
(defset chem-p-series '(10 18 36))
(defset chem-d-series '(28 46))
(defset chem-f-series '(60))

(comment
 ;; see the atomic numbers
 (etv
  (number-a-list-last-element
   chem-atomic-data)))

;; https://en.wikipedia.org/wiki/Hassium
;; Ah, I see, this list is out of order
;; TODO Get the list of elements anew
(defset chem-atomic-data
        '(("H" s)
          ("He" s)
          ("Li" s)
          ("Be" s)
          ("B" p)
          ("C" p)
          ("N" p)
          ("O" p)
          ("F" p)
          ("Ne" p)
          ("Na" s)
          ("Mg" s)
          ("Al" p)
          ("Si" p)
          ("P" p)
          ("S" p)
          ("Cl" p)
          ("Ar" p)
          ("K" s)
          ("Ca" s)
          ("Sc" d)
          ("Ti" d)
          ("V" d)
          ("Cr" d)
          ("Mn" d)
          ("Fe" d)
          ("Co" d)
          ("Ni" d)
          ("Cu" d)
          ("Zn" d)
          ("Ga" p)
          ("Ge" p)
          ("As" p)
          ("Se" p)
          ("Br" p)
          ("Kr" p)
          ("Rb" s)
          ("Sr" s)
          ("Y" d)
          ("Zr" d)
          ("Nb" d)
          ("Mo" d)
          ("Tc" d)
          ("Ru" d)
          ("Rh" d)
          ("Pd" d)
          ("Ag" d)
          ("Cd" d)
          ("In" p)
          ("Sn" p)
          ("Sb" p)
          ("Te" p)
          ("I" p)
          ("Xe" p)
          ("Cs" s)
          ("Ba" s)
          ("Lu" d)
          ("Hf" d)
          ("Ta" d)
          ("W" d)
          ("Re" d)
          ("Os" d)
          ("Ir" d)
          ("Pt" d)
          ("Au" d)
          ("Hg" d)
          ("Tl" p)
          ("Pb" p)
          ("Bi" p)
          ("Po" p)
          ("At" p)
          ("Rn" p)
          ("Fr" s)
          ("Ra" s)
          ("Lr" d)
          ("Rf" d)
          ("Db" d)
          ("Sg" d)
          ("Bh" d)
          ("Hs" d)
          ("Mt" d)
          ("Ds" d)
          ("Rg" d)
          ("Cn" d)
          ("Nh" p)
          ("Fl" p)
          ("Mc" p)
          ("Lv" p)
          ("Ts" p)
          ("Og" p)
          ("La" f)
          ("Ce" f)
          ("Pr" f)
          ("Nd" f)
          ("Pm" f)
          ("Sm" f)
          ("Eu" f)
          ("Gd" f)
          ("Tb" f)
          ("Dy" f)
          ("Ho" f)
          ("Er" f)
          ("Tm" f)
          ("Yb" f)
          ("Ac" f)
          ("Th" f)
          ("Pa" f)
          ("U" f)
          ("Np" f)
          ("Pu" f)
          ("Am" f)
          ("Cm" f)
          ("Bk" f)
          ("Cf" f)
          ("Es" f)
          ("Fm" f)
          ("Md" f)
          ("No" f)))

;; (chem-face-from-atom "H")
(defun chem-face-from-atom (atom)
  (case (second (assoc (s-trim-right atom) chem-atomic-data))
    (s 'chemtable-hl-1-face)
    (p 'chemtable-hl-2-face)
    (d 'chemtable-hl-3-face)
    (f 'chemtable-hl-4-face)
    (t 'chemtable-hl-other-face)))

;; TODO Put which face to use inside a lookup table, instead of inside the logic
;; j:chemtable
;; cat $EMACSD_BUILTIN/elpa/chemtable-20230314.1825/chemtable.el | scrape "chemtable-.-block-face \"..\""

(defun hl-s-series ()

  )

(provide 'pen-chemistry)
