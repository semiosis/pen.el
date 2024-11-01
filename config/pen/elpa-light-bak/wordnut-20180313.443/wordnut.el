;; wordnut.el -- Major mode interface to WordNet -*- lexical-binding: t -*-

(require 'cl-lib)
(require 'subr-x)
(require 'outline)
(require 'imenu)

(require 'wordnut-history)

(defconst wordnut-meta-name "wordnut")
(defconst wordnut-meta-version "0.0.2")

(defconst wordnut-bufname "*WordNut*")
(defvar wordnut-cmd "wn")
(defconst wordnut-cmd-options
  '("-over"
    "-synsn" "-synsv" "-synsa" "-synsr"
    "-simsv"
    "-antsn" "-antsv" "-antsa" "-antsr"
    "-famln" "-famlv" "-famla" "-famlr"
    "-hypen" "-hypev"
    "-hypon" "-hypov"
    "-treen" "-treev"
    "-coorn" "-coorv"
    "-derin" "-deriv"
    "-domnn" "-domnv" "-domna" "-domnr"
    "-domtn" "-domtv" "-domta" "-domtr"
    "-subsn"
    "-partn"
    "-membn"
    "-meron"
    "-hmern"
    "-sprtn"
    "-smemn"
    "-ssubn"
    "-holon"
    "-hholn"
    "-entav"
    "-framv"
    "-causv"
    "-perta" "-pertr"
    "-attrn" "-attra"))

(defconst wordnut-section-headings
  '("Antonyms" "Synonyms" "Hyponyms" "Troponyms"
    "Meronyms" "Holonyms" "Pertainyms"
    "Member" "Substance" "Part"
    "Attributes" "Derived" "Domain" "Familiarity"
    "Coordinate" "Grep" "Similarity"
    "Entailment" "'Cause To'" "Sample" "Overview of"))

(defvar wordnut-completion-hist '())
(defvar wordnut-hs (make-wordnut--h))

(defconst wordnut-fl-link-cat-re "->\\((.+?)\\)?")
(defconst wordnut-fl-link-word-sense-re "\\([^,;)>]+#[0-9]+\\)")
(defconst wordnut-fl-link-re (concat wordnut-fl-link-cat-re " "
				     wordnut-fl-link-word-sense-re))
(defconst wordnut-font-lock-keywords
  `(
    ("^\\* .+$" . 'outline-1)
    ("^\\*\\* .+$" . 'outline-2)

    (,wordnut-fl-link-cat-re ;; anchor
     ,(concat " " wordnut-fl-link-word-sense-re) nil nil (1 'link))
    ))



(define-derived-mode wordnut-mode special-mode "WordNut"
  "Major mode interface to WordNet lexical database.
Turning on wordnut mode runs the normal hook `wordnut-mode-hook'.

\\{wordnut-mode-map}"

  (setq-local visual-line-fringe-indicators '(nil top-right-angle))
  (visual-line-mode 1)

  ;; we make a custom imenu index
  (setq imenu-generic-expression nil)
  (setq-local imenu-create-index-function 'wordnut--imenu-make-index)
  (imenu-add-menubar-index)

  (setq font-lock-defaults '(wordnut-font-lock-keywords))

  ;; if user has adaptive-wrap mode installed, use it
  (if (and (fboundp 'adaptive-wrap-prefix-mode)
	   (boundp 'adaptive-wrap-extra-indent))
      (progn
	(setq adaptive-wrap-extra-indent 3)
	(adaptive-wrap-prefix-mode 1))))

(define-key wordnut-mode-map (kbd "q") 'quit-window)
(define-key wordnut-mode-map (kbd "RET") 'wordnut-lookup-current-word)
(define-key wordnut-mode-map (kbd "l") 'wordnut-history-backward)
(define-key wordnut-mode-map (kbd "r") 'wordnut-history-forward)
(define-key wordnut-mode-map (kbd "h") 'wordnut-history-lookup)
(define-key wordnut-mode-map (kbd "/") 'wordnut-search)
(define-key wordnut-mode-map (kbd "o") 'wordnut-show-overview)

(define-key wordnut-mode-map [(meta down)] 'outline-next-visible-heading)
(define-key wordnut-mode-map [(meta up)] 'outline-previous-visible-heading)

(define-key wordnut-mode-map (kbd "b") 'scroll-down-command)

(defun wordnut--get-buffer ()
  "Return a major mode buffer or cry."
  (let ((buf (get-buffer wordnut-bufname)))
    (unless buf (user-error "Has %s buffer been killed?" wordnut-bufname))
    buf))

(defun wordnut--completing (input)
  (let ((completion-ignore-case t))
    (completing-read "WordNut: "
		     (completion-table-dynamic 'wordnut--suggestions)
		     nil nil input 'wordnut-completion-hist)))

(defun wordnut--suggestions (input)
  (if (not (string-match "^\s*$" input))
      (progn
	(setq input (string-trim input))
	(let ((result (wordnut--exec input "-grepn" "-grepv" "-grepa" "-grepr")))
	  (if (equal "" result)
	      nil				; no match
	    (setq result (split-string result "\n"))
	    (wordnut-u-filter (lambda (idx)
			       (and
				(not (string-prefix-p "Grep of " idx))
				(not (equal idx ""))))
			     result))
	  ))))

(defun wordnut--exec (word &rest args)
  "Like `system(3)' but only for wn(1)."
  (with-output-to-string
    (with-current-buffer
	standard-output
      (apply 'call-process wordnut-cmd nil t nil word args)
      )))

;;;###autoload
(defun wordnut-search (word)
  "Prompt for a word to search for, then do the lookup."
  (interactive (list (wordnut--completing (current-word t t))))
  (ignore-errors
    (wordnut--history-update-cur wordnut-hs))
  (wordnut--lookup word))

;;;###autoload
(defun wordnut-lookup-current-word ()
  (interactive)
  (let (inline)
    (ignore-errors
      (wordnut--history-update-cur wordnut-hs))

    (setq inline (wordnut--lexi-link))
    (if inline
	(wordnut--lookup (car inline) (nth 1 inline) (nth 2 inline))
      (wordnut--lookup (current-word)))
    ))

(defun wordnut--lookup (word &optional category sense)
  "If wn prints something to stdout it means the word is
found. Otherwise we run wn again but with its -grepX options. If
that returns nothing or a list of words, prompt for a word, then
rerun `wordnut--lookup' with the selected word."
  (if (or (null word) (string-match "^\s*$" word)) (user-error "Invalid query"))

  (setq word (string-trim word))
  (let ((progress-reporter
	 (make-progress-reporter
	  (format "WordNet lookup for `%s'... " (wordnut-u-fix-name word)) 0 2))
	result buf item ipoint)

    (setq result (apply 'wordnut--exec word wordnut-cmd-options))
    (progress-reporter-update progress-reporter 1)

    (if (equal "" result)
	(let (sugg)
	  (setq sugg (wordnut--suggestions word))
	  (setq word (if (listp sugg) (wordnut--completing word) sugg))
	  ;; recursion!
	  (wordnut--lookup word category sense))
      ;; else
      (if (setq item (wordnut--h-find wordnut-hs word))
	  (setq ipoint (cdr (assoc 'point item))))
      (setq item (wordnut--h-item-new word ipoint category sense))
      (wordnut--h-add wordnut-hs item)

      (setq buf (get-buffer-create wordnut-bufname))
      (with-current-buffer buf
	(let ((inhibit-read-only t))
	  (erase-buffer)
	  (insert result))
	(wordnut--format-buffer)
	(setq imenu--index-alist nil)	; flush imenu cache
	(set-buffer-modified-p nil)
	(unless (eq major-mode 'wordnut-mode) (wordnut-mode))
	(wordnut--headerline)
	(wordnut--moveto item))

      (progress-reporter-update progress-reporter 2)
      (progress-reporter-done progress-reporter)
      (pop-to-buffer buf))
    ))

(defun wordnut--moveto (item)
  (let ((name (cdr (assoc 'name item)))
	(point (cdr (assoc 'point item)))
	(category (cdr (assoc 'category item)))
	(sense (cdr (assoc 'sense item))))
    (if (or category sense)
	(progn
	  (unless category (setq category "[^ ]+"))
	  (unless sense (setq sense "1"))
	  (goto-char (point-min))
	  (re-search-forward (format "^\\* Overview of %s" category))
	  (forward-line)
	  (re-search-forward (format "%s\\. " sense))
	  (goto-char (line-beginning-position))
	  (message "wordnut--moveto: %s -> (lexi) '%s' '%s' (cur point: %d)"
		   name category sense (point)))
      (if point
	  (progn
	    (goto-char point)
	    (message "wordnut--moveto: (point) %s -> %d" name point))
	(message "wordnut--moveto: (point) %s -> no" name))
      )))

(defun wordnut--headerline ()
  (setq header-line-format
	(format "C: %s, ← %s (%d), → %s (%d)"
		(propertize (wordnut-u-fix-name
			     (wordnut--h-name-by-pos
			      wordnut-hs (wordnut--h-pos wordnut-hs)))
			    'face 'bold)

		(or (wordnut-u-fix-name
		     (wordnut--h-name-by-pos
		      wordnut-hs (1+ (wordnut--h-pos wordnut-hs)))) "∅")
		(wordnut--h-back-size wordnut-hs)

		(or (wordnut-u-fix-name
		     (wordnut--h-name-by-pos
		      wordnut-hs (1- (wordnut--h-pos wordnut-hs)))) "∅")
		(wordnut--h-forw-size wordnut-hs)
		)
	))

(defun wordnut-history-clean ()
  (interactive)
  (wordnut--h-clean wordnut-hs))

(defun wordnut-history-lookup ()
  (interactive)
  (let ((list (wordnut--h-names wordnut-hs)))
    (unless list (user-error "History is ∅"))
    (wordnut--lookup (ido-completing-read "wordnut history: " list))))

(defun wordnut--history-update-cur (hs)
  (let ((cur (nth (wordnut--h-pos hs) (wordnut--h-list hs)))
	(buf (wordnut--get-buffer)))
    (if cur
	(with-current-buffer buf
	  (setf (cdr (assoc 'point cur)) (point))))))

;; a rare case when elisp is cool
(defmacro wordnut--history-move (desc direction)
  `(let (item)
     (setq item (,direction wordnut-hs 'wordnut--history-update-cur))
     (if item
	 (wordnut--lookup (cdr (assoc 'name item)))
       (user-error "The %s history is ∅" ,desc)) ))

(defun wordnut-history-backward ()
  (interactive)
  (wordnut--history-move "backward" wordnut--h-back))

(defun wordnut-history-forward ()
  (interactive)
  (wordnut--history-move "forward" wordnut--h-forw))

(defun wordnut--imenu-make-index ()
  (let ((index '()) marker)
    (save-excursion
      (while (re-search-forward "^\\* \\(.+\\)$" nil t)
	(setq marker (make-marker))
	(set-marker marker (line-beginning-position))
	(push `(,(match-string 1) . ,marker) index))

      (reverse index))))

(defun wordnut--format-buffer ()
  (let ((inhibit-read-only t)
	(case-fold-search nil))
    ;; delete the 1st empty line
    (goto-char (point-min))
    (delete-blank-lines)

    ;; make headings
    (delete-matching-lines "^ +$" (point-min) (point-max))
    (while (re-search-forward
	    (concat "^" (regexp-opt wordnut-section-headings t)) nil t)
      (replace-match "* \\1"))

    ;; remove empty entries
    (goto-char (point-min))
    (while (re-search-forward "^\\* .+\n\n\\*" nil t)
      (replace-match "*" t t)
      ;; back over the '*' to remove next matching lines
      (backward-char))

    ;; make sections
    (goto-char (point-min))
    (while (re-search-forward "^Sense [0-9]+" nil t)
      (replace-match "** \\&"))

    ;; remove the last empty entry
    (goto-char (point-max))
    (if (re-search-backward "^\\* .+\n\\'" nil t)
	(replace-match "" t t))

    (goto-char (point-min))
    ))



(defun wordnut--lexi-cat ()
  "Return a category name for the current lexical category."
  (let (line)
    (save-excursion
      (ignore-errors
	(outline-up-heading 1))
      (setq line (wordnut-u-line-cur))
      (unless (string-match " of \\(noun\\|verb\\|adj\\|adv\\)" line)
	(user-error "Cannot extract a lexical category"))

      (match-string 1 line)
      )))

(defun wordnut--lexi-sense ()
  "Return a sense number for the current lexical category."
  (let (line)
    (save-excursion
      (ignore-errors
	(outline-up-heading -1))
      (setq line (wordnut-u-line-cur))
      (unless (string-match "Sense \\([0-9]+\\)" line)
	(user-error "Cannot extract a sense number; move the cursor to the proper place first"))

      (match-string 1 line)
      )))

(defun wordnut--lexi-link ()
  "Return a list '(word cat sense) from the current line or nil."
  (let ((line (wordnut-u-line-cur))
	cat raw)
    (if (string-match wordnut-fl-link-re line)
	(progn
	  (setq cat
	       (if (match-string 1 line)
		   (replace-regexp-in-string "[()]" "" (match-string 1 line))))

	  (unless (setq raw (wordnut--lexi-link-word-sense))
	    (error "failed to extract an inline link"))
	  (setq raw (split-string raw "#"))

	  (list (nth 0 raw) cat (nth 1 raw)) )
      nil)))

(defun wordnut--lexi-link-word-sense ()
  "Return a string 'foo bar#123' or nil."
  (let ((word-re-back "[,;)>]")
	(line (wordnut-u-line-cur)) )

    (if (string-match wordnut-fl-link-re line)
	(save-restriction
	  (narrow-to-region (line-beginning-position) (line-end-position))
	  (re-search-backward word-re-back nil t)
	  (forward-char)
	  (if (re-search-forward wordnut-fl-link-word-sense-re nil t)
	      (string-trim (substring-no-properties (match-string 0)))
	    nil))
      nil
      ) ))

(cl-defun wordnut--lexi-overview ()
  "Try to locale an 'Overview' heading to extract a 'sense'
of a current lexical category.

Return a list '(cat sense desc)."
  (let (desc cat sense inline)
    (setq inline (wordnut--lexi-link))
    (if inline
	(if (equal (car inline) (wordnut--lexi-word))
	    (progn
	      (setq cat (nth 1 inline))
	      (setq sense (nth 2 inline)))
	  ;; go to the linked word
	  (wordnut--history-update-cur wordnut-hs)
	  (wordnut--lookup (car inline) (nth 1 inline) (nth 2 inline))
	  (cl-return-from wordnut--lexi-overview nil)
	  ))

    (setq cat (or cat (wordnut--lexi-cat)))
    (setq sense (or sense (wordnut--lexi-sense)))

    (save-excursion
      (goto-char (point-min))
      (re-search-forward (format "^\\* Overview of %s" cat) nil t)
      (forward-line)
      (re-search-forward (format "%s\\. " sense) nil t)
      (setq desc (string-trim (wordnut-u-line-cur)))

      (unless desc (user-error "Failed to extract an overview"))
      (list cat sense desc)
      )))

(defun wordnut--lexi-word ()
  "Return an actual displayed word, not what a user has typed
for a query. For example, return 'do' instead of 'did'."
  (save-excursion
    (goto-char (point-min))
    (unless (re-search-forward "^\\* Overview of [^ ]+ \\(.+\\)$" nil t)
      (user-error "Cannot extract the actual current word"))
    (substring-no-properties
     (replace-regexp-in-string wordnut--h-word-delim-re " " (match-string 1)))))

(defun wordnut-show-overview ()
  "Show a tooltip of a 'sense' for the current lexical category."
  (interactive)
  (let ((buf (wordnut--get-buffer)) desc)
    (with-current-buffer buf
      (setq desc (wordnut--lexi-overview))
      (if desc
	  (tooltip-show (wordnut-u-word-wrap
			 (+ (/ (window-body-width) 2) (/ (window-body-width) 4))
			 (format "OVERVIEW `%s', %s\n\n%s"
				 (wordnut-u-fix-name (wordnut--lexi-word))
				 (car desc) (nth 2 desc)
				 ))))
      )))



(provide 'wordnut)
