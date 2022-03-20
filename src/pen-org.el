(require 'wordnut)
(require 'my-thesaurus)

;; This is important to let org-mode highlight code blocks
(setq org-src-fontify-natively t)


;; This provides the nice M-j and M-k keybindings while in evil-org mode
(if (not (cl-search "SPACEMACS" my-daemon-name))
    (load "$HOME/var/smulliga/source/git/spacemacs/layers/+emacs/org/local/evil-org/evil-org.el"))


;; This is for the "j" menu
(defconst org-goto-help
  "Browse buffer copy, to find location or copy text.%s
Start typing to search.
\[C-m]           jump to location
\[C-g]           quit and return to previous location
\[PgUp]/[PgDown] up and down page
\[Up]/[Down]     next/prev headline
\[C-i]           cycle visibility
\[/]             org-occur")


;; (define-key org-mode-map (kbd "M-7") #'my-synonym-current-word)
;; (define-key org-mode-map (kbd "M-9") #'dict-word)
(define-key org-mode-map (kbd "M-9") 'handle-docs)
;; (define-key org-mode-map (kbd "M-8") #'engine/search-google)
(define-key org-mode-map (kbd "M-8") nil)


(defun my-org-publish-current-file ()
  (interactive)

  (ns "Don't forget to add these under the headings: :PROPERTIES: \n :CUSTOM_ID: my-headline-2 \n :END:")
  ;; (xc ":PROPERTIES: \n :CUSTOM_ID: my-headline-2 \n :END:")

  ;; :PROPERTIES:
  ;; :CUSTOM_ID: server-config-yaml
  ;; :END:

  ;; Dont use this. I need to set up projects for this
  ;; (org-publish-current-file)

  (let ((htmlfn
         (replace-regexp-in-string "\\(.*\\)\\.org$" "\\1.html" (buffer-file-name))))

    (call-interactively #'org-html-export-as-html)

    ;; Need a shell script to touch a new file, including making the directories with mkdir -p
    ;; (replace-regexp-in-string "\\(.*\\)\\.org$" "\\1.html" (buffer-file-name))
    (set-visited-file-name htmlfn)
    ;; (save-current-buffer)
    (save-buffer)
    (kill-current-buffer)

    (bl ff-view htmlfn)
    (kill-window))
  ;; Open chrome to this html file
  )

(defun put-on-codelingo-troubleshooting-blog ()
  (interactive)
  (sh (concat "put-on-codelingo-troubleshooting-blog " (q (buffer-file-name)))))

(define-key org-mode-map (kbd "C-c M-p") #'my-org-publish-current-file)
(define-key org-mode-map (kbd "C-c M-o") #'put-on-codelingo-troubleshooting-blog)


;; (setq org-capture-templates
;;       (quote (("j" "Journal Entry" entry (file+olp+datetree "$HOME/Documents/Journal/journal.org") "* %T %a\n%?" :tree-type week)
;;               ("i" "Incident" entry (file+headline "/tmp/work.org" "Incidents") "* %?\n :Details: \n :Tickets: \n :UNIs: \n :Devices:"))))


;; https://writequit.org/articles/emacs-org-mode-generate-ids.html#automating-id-creation
(require 'org-id)

;; This fixes a compatibility with older org
;; Could not run org-edit-special without this
(defun org-get-indentation (&optional line)
  "Get the indentation of the current line, interpreting tabs.
When LINE is given, assume it represents a line and compute its indentation."
  (if line
      (when (string-match "^ *" (org-remove-tabs line))
	(match-end 0))
    (save-excursion
      (beginning-of-line 1)
      (skip-chars-forward " \t")
      (current-column))))

;; How to make this permanent?
;; (define-key org-goto-map (kbd "<next>") nil)
;; I should put some advice around the (org-goto-map) function so it always calls the above after executing


;; org-goto-map is both a variable AND a function

;; ;;None of these worked
;; (advice-add 'org-goto-map :after '(lambda (&rest args) (define-key org-goto-map (kbd "<next>") nil)))
;; (advice-add 'org-goto :after '(lambda (&rest args) (define-key org-goto-map (kbd "<next>") nil)))
;; (advice-add 'org :after '(lambda (&rest args) (define-key org-goto-map (kbd "<next>") nil)))

;; This works! The function moved to org-compat
(advice-add 'org-goto--set-map :after '(lambda (&rest args) (define-key org-goto-map (kbd "<next>") nil)))

;; (with-eval-after-load "org" (define-key org-goto-map (kbd "<next>") nil))
;; (dk org-goto-map "q" 'org-goto-quit)
;; (with-eval-after-load "org-goto" (define-key org-goto-map (kbd "<next>") nil)) ;; This is a valid attempt, because org-goto is now a package. in earlier versions it was part of org

;; Not even redefining this function works
;; (defun org-goto-map ()
;;   "Set the keymap `org-goto'."
;;   (setq org-goto-map
;; 	(let ((map (make-sparse-keymap)))
;; 	  (let ((cmds '(isearch-forward isearch-backward kill-ring-save set-mark-command
;; 					mouse-drag-region universal-argument org-occur)))
;; 	    (dolist (cmd cmds)
;; 	      (substitute-key-definition cmd cmd map global-map)))
;; 	  (suppress-keymap map)
;; 	  (org-defkey map "\C-m"     'org-goto-ret)
;; 	  (org-defkey map [(return)] 'org-goto-ret)
;; 	  (org-defkey map [(left)]   'org-goto-left)
;; 	  (org-defkey map [(right)]  'org-goto-right)
;; 	  (org-defkey map [(control ?g)] 'org-goto-quit)

;; 	  (org-defkey map "\C-i" 'org-cycle)
;; 	  (org-defkey map [(tab)] 'org-cycle)
;; 	  (org-defkey map [(down)] 'outline-next-visible-heading)
;; 	  (org-defkey map [(up)] 'outline-previous-visible-heading)
;; 	  (if org-goto-auto-isearch
;; 	      (if (fboundp 'define-key-after)
;; 		  (define-key-after map [t] 'org-goto-local-auto-isearch)
;; 		nil)
;; 	    (org-defkey map "q" 'org-goto-quit)
;; 	    (org-defkey map "n" 'outline-next-visible-heading)
;; 	    (org-defkey map "p" 'outline-previous-visible-heading)
;; 	    (org-defkey map "f" 'outline-forward-same-level)
;; 	    (org-defkey map "b" 'outline-backward-same-level)
;; 	    (org-defkey map "u" 'outline-up-heading))
;; 	  (org-defkey map "/" 'org-occur)
;; 	  (org-defkey map "\C-c\C-n" 'outline-next-visible-heading)
;; 	  (org-defkey map "\C-c\C-p" 'outline-previous-visible-heading)
;; 	  (org-defkey map "\C-c\C-f" 'outline-forward-same-level)
;; 	  (org-defkey map "\C-c\C-b" 'outline-backward-same-level)
;; 	  (org-defkey map "\C-c\C-u" 'outline-up-heading)

;;           (org-defkey map "q" 'org-goto-quit)
;;           (org-defkey map "<next>" nil)

;; 	  map)))

(defun org-mode-hook-after ()
  (interactive)
  (if (s-match "/glossary\.org$" (get-path))
      (org-global-cycle 1))
  ;; This broke lsp company completion
  ;; (add-to-list 'company-backends 'company-ispell)
  )

;; (remove-from-list 'company-backends 'company-ispell)

(add-hook 'org-mode-hook 'org-mode-hook-after t)
(add-hook 'org-mode-hook #'company-mode)

(nconc org-modules
       '(
         org-capture
         org-habit
         org-id
         org-protocol
         org-brain
         ))



;; This should not care about ellipsis and go to the end anyway
(defun my-org-end-of-line (&optional n)
  "If this is a headline, and `org-special-ctrl-a/e' is not nil or
symbol `reversed', ignore tags on the first attempt, and only
move to after the tags when the cursor is already beyond the end
of the headline.

If `org-special-ctrl-a/e' is symbol `reversed' then ignore tags
on the second attempt.

With argument N not nil or 1, move forward N - 1 lines first."
  (interactive "^p")
  (let ((origin (point))
        (special (pcase org-special-ctrl-a/e
                   (`(,_ . ,C-e) C-e) (_ org-special-ctrl-a/e)))
        deactivate-mark)
    ;; First move to a visible line.
    (if (bound-and-true-p visual-line-mode)
        (beginning-of-visual-line n)
      (move-beginning-of-line n))
    (cond
     ;; At a headline, with tags.
     ((and special
           (save-excursion
             (beginning-of-line)
             (let ((case-fold-search nil))
               (looking-at org-complex-heading-regexp)))
           (match-end 5))
      (let ((tags (save-excursion
                    (goto-char (match-beginning 5))
                    (skip-chars-backward " \t")
                    (point))))
        (cond ((eq special 'reversed)
               (if (and (= origin (line-end-position))
                        (eq this-command last-command))
                   (goto-char tags)
                 (end-of-line)))
              (t
               (if (or (< origin tags) (= origin (line-end-position)))
                   (goto-char tags)
                 (end-of-line))))))
     (t (end-of-line)))))

;; How to unmape a modes keybinding
;; This isn't working for org, though
;; (add-hook 'org-mode-hook
;;           (lambda() (define-key org-mode-map (kbd "C-e") nil)))
;; (define-key org-mode-map (kbd "C-e") nil)
;; (local-unset-key (kbd "C-e"))
;; This doesn't work either
;; (define-key org-mode-map "\C-e" 'move-end-of-line)
(define-key org-mode-map "\C-e" 'my-org-end-of-line)

;; Original binding here:
;; vim +/"(define-key org-mode-map \"\C-e\" 'org-end-of-line" "$EMACSD/packages-spacemacs/org-plus-contrib-20180312/org.el"

(require 'org-habit)

(define-key org-mode-map (kbd "M-P") 'handle-preverr)
(define-key org-mode-map (kbd "M-N") 'handle-nexterr)
(define-key org-mode-map (kbd "M-l M-j M-w") 'handle-spellcorrect)


(define-key org-mode-map (kbd "M-RET") 'org-meta-return)

;; No need for this anymore because I rebound it to C-M-@
;; (if (is-spacemacs)
;;     (define-key spacemacs-org-mode-map-root-map (kbd "M-RET") nil))

(defun tvipe-org-table-export ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")
    (sps (concat "vs " (q newfile)))))
(defalias 'tvipe-org-table-export-tsv 'tvipe-org-table-export)

(defun etv-org-table-export ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")
    (esph (lm (pen-term-nsfa (concat "vs " (q newfile)))))))
(defalias 'etv-org-table-export-tsv 'etv-org-table-export)

(defun fpvd-org-table-export ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")
    (sps (concat "fpvd " (q newfile)))))

(defun efpvd-org-table-export ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")
    (esph (lm (pen-term-nsfa (concat "fpvd " (q newfile)))))))



(defun org-copy-src-block ()
  (interactive)
  (shut-up (my-copy (org-get-src-block-here))))


(defun org-get-src-block-here ()
  (interactive)
  (org-edit-src-code)
  (mark-whole-buffer)
  (let ((contents (sh/chomp (selection))))
    ;; (easy-kill 1)
    (org-edit-src-abort)
    contents))


(defun org-copy-thing-here ()
  (interactive)
  (if (or (org-in-src-block-p)
          (org-in-block-p '("src" "example" "verbatim" "clocktable" "example")))
      (org-copy-src-block)
    (self-insert-command 1)))

;; (defun org-babel-change-block-type ()
;;   (interactive)
;;   (cond ((or (org-in-src-block-p)
;;              (org-in-block-p '("src" "example" "verbatim" "clocktable" "quote")))
;;          (progn
;;            (call-interactively 'org-babel-raise)
;;            (call-interactively 'hydra-org-template/body)))
;;         (t
;;          (self-insert-command 1))))

(define-key org-mode-map (kbd "M-c") 'org-copy-thing-here)


;; This appears to not work
(require 'org-translate)

;; ((vm . vm-visit-folder-other-frame) (vm-imap . vm-visit-imap-folder-other-frame) (gnus . org-gnus-no-new-news) (file . find-file-other-window) (wl . wl-other-frame))
;; (alist-set 'org-link-frame-setup 'file 'find-file)
(alist-setcdr 'org-link-frame-setup 'file 'find-file)



;; DISCARD
;; To fix yasnippet in a babel src block with no contents, I need to ensure there is something
;; Sadly that doesnt work
;; (defun org-src--edit-element
;;     (datum name &optional initialize write-back contents remote)
;;   "Edit DATUM contents in a dedicated buffer NAME.

;; INITIALIZE is a function to call upon creating the buffer.

;; When WRITE-BACK is non-nil, assume contents will replace original
;; region.  Moreover, if it is a function, apply it in the edit
;; buffer, from point min, before returning the contents.

;; When CONTENTS is non-nil, display them in the edit buffer.
;; Otherwise, show DATUM contents as specified by
;; `org-src--contents-area'.

;; When REMOTE is non-nil, do not try to preserve point or mark when
;; moving from the edit area to the source.

;; Leave point in edit buffer."
;;   (setq org-src--saved-temp-window-config (current-window-configuration))
;;   (let* ((area (org-src--contents-area datum))
;; 	       (beg (copy-marker (nth 0 area)))
;; 	       (end (copy-marker (nth 1 area) t))
;; 	       (old-edit-buffer (org-src--edit-buffer beg end))
;; 	       (contents (or contents (nth 2 area))))
;;     (if (and old-edit-buffer
;; 	           (or (not org-src-ask-before-returning-to-edit-buffer)
;; 		             (y-or-n-p "Return to existing edit buffer ([n] will revert changes)? ")))
;; 	      ;; Move to existing buffer.
;; 	      (org-src-switch-to-buffer old-edit-buffer 'return)
;;       ;; Discard old edit buffer.
;;       (when old-edit-buffer
;; 	      (with-current-buffer old-edit-buffer (org-src--remove-overlay))
;; 	      (kill-buffer old-edit-buffer))
;;       (let* ((org-mode-p (derived-mode-p 'org-mode))
;; 	           (source-file-name (buffer-file-name (buffer-base-buffer)))
;; 	           (source-tab-width (if indent-tabs-mode tab-width 0))
;; 	           (type (org-element-type datum))
;; 	           (ind (org-with-wide-buffer
;; 		               (goto-char (org-element-property :begin datum))
;; 		               (current-indentation)))
;; 	           (preserve-ind
;; 	            (and (memq type '(example-block src-block))
;; 		               (or (org-element-property :preserve-indent datum)
;; 		                   org-src-preserve-indentation)))
;; 	           ;; Store relative positions of mark (if any) and point
;; 	           ;; within the edited area.
;; 	           (point-coordinates (and (not remote)
;; 				                             (org-src--coordinates (point) beg end)))
;; 	           (mark-coordinates (and (not remote)
;; 				                            (org-region-active-p)
;; 				                            (let ((m (mark)))
;; 				                              (and (>= m beg) (>= end m)
;; 					                                 (org-src--coordinates m beg end)))))
;; 	           ;; Generate a new edit buffer.
;; 	           (buffer (generate-new-buffer name))
;; 	           ;; Add an overlay on top of source.
;; 	           (overlay (org-src--make-source-overlay beg end buffer)))
;; 	      ;; Switch to edit buffer.
;; 	      (org-src-switch-to-buffer buffer 'edit)
;; 	      ;; Insert contents.
;; 	      ;; (insert (string-or
;;         ;;          contents
;;         ;;          "\n"))
;;         (insert contents)
;; 	      (remove-text-properties (point-min) (point-max)
;; 				                        '(display nil invisible nil intangible nil))
;; 	      (unless preserve-ind (org-do-remove-indentation))
;; 	      (set-buffer-modified-p nil)
;; 	      (setq buffer-file-name nil)
;; 	      ;; Initialize buffer.
;; 	      (when (functionp initialize)
;; 	        (let ((org-inhibit-startup t))
;; 	          (condition-case e
;; 		            (funcall initialize)
;; 	            (error (message "Initialization fails with: %S"
;; 			                        (error-message-string e))))))
;; 	      ;; Transmit buffer-local variables for exit function.  It must
;; 	      ;; be done after initializing major mode, as this operation
;; 	      ;; may reset them otherwise.
;; 	      (setq org-src--tab-width source-tab-width)
;; 	      (setq org-src--from-org-mode org-mode-p)
;; 	      (setq org-src--beg-marker beg)
;; 	      (setq org-src--end-marker end)
;; 	      (setq org-src--remote remote)
;; 	      (setq org-src--source-type type)
;; 	      (setq org-src--block-indentation ind)
;; 	      (setq org-src--preserve-indentation preserve-ind)
;; 	      (setq org-src--overlay overlay)
;; 	      (setq org-src--allow-write-back write-back)
;; 	      (setq org-src-source-file-name source-file-name)
;; 	      ;; Start minor mode.
;; 	      (org-src-mode)
;; 	      ;; Move mark and point in edit buffer to the corresponding
;; 	      ;; location.
;; 	      (if remote
;; 	          (progn
;; 	            ;; Put point at first non read-only character after
;; 	            ;; leading blank.
;; 	            (goto-char
;; 	             (or (text-property-any (point-min) (point-max) 'read-only nil)
;; 		               (point-max)))
;; 	            (skip-chars-forward " \r\t\n"))
;; 	        ;; Set mark and point.
;; 	        (when mark-coordinates
;; 	          (org-src--goto-coordinates mark-coordinates (point-min) (point-max))
;; 	          (push-mark (point) 'no-message t)
;; 	          (setq deactivate-mark nil))
;; 	        (org-src--goto-coordinates
;; 	         point-coordinates (point-min) (point-max)))))))


(require 'my-mode)
(define-key org-mode-map (kbd "M-*") 'my/evil-star-maybe)


(defun my-org-list-top-level-headings ()
  (ignore-errors (mapcar 'str (mapcar 'car (org-imenu-get-tree)))))

(defun my-org-select-heading (name)
  (interactive (list (fz (my-org-list-top-level-headings))))
  ;; (-filter (lambda (e) (string-equal name (get-text-property 0 'org-imenu-marker (car e)))) (org-imenu-get-tree))
  (let* ((l (-filter (lambda (e) (string-equal name (car e))) (org-imenu-get-tree)))
         (sel (if (> 0 (length l))
                  ;; I need an fz that lets me pick by a different thing
                  ;; (fz l)
                  (car l)
                (car l))))
    (setq sel (car sel))
    (if (sor sel)
        (goto-char (get-text-property 0 'org-imenu-marker sel)))))


;; org-clock
;; (advice-add 'org-clock-kill-emacs-query :around #'ignore-errors-around-advice)
(advice-remove 'org-clock-kill-emacs-query #'ignore-errors-around-advice)



(defun org-activate-links (limit)
  "Add link properties to links.
This includes angle, plain, and bracket links."
  (catch :exit
    (while (re-search-forward org-link-any-re limit t)
      (let* ((start (match-beginning 0))
	     (end (match-end 0))
	     (visible-start (or (match-beginning 3) (match-beginning 2)))
	     (visible-end (or (match-end 3) (match-end 2)))
	     (style (cond ((eq ?< (char-after start)) 'angle)
			  ((eq ?\[ (char-after (1+ start))) 'bracket)
			  (t 'plain))))
	(when (and (memq style org-highlight-links)
		   ;; Do not span over paragraph boundaries.
		   (not (string-match-p org-element-paragraph-separate
					(match-string 0)))
		   ;; Do not confuse plain links with tags.
		   (not (and (eq style 'plain)
			     (let ((face (get-text-property
					  (max (1- start) (point-min)) 'face)))
			       (if (consp face) (memq 'org-tag face)
				       (eq 'org-tag face))))))
	  (let* ((link-object (save-excursion
				(goto-char start)
				(save-match-data (org-element-link-parser))))
		 (link (org-element-property :raw-link link-object))
		 (type (org-element-property :type link-object))
		 (path (org-element-property :path link-object))
		 (properties		;for link's visible part
		  (list
		   'face (pcase (org-link-get-parameter type :face)
			   ((and (pred functionp) face) (funcall face path))
			   ((and (pred facep) face) face)
			   ((and (pred consp) face) face) ;anonymous
			   (_
          (if (my-url-cache-exists link)
              'eww-cached
            'org-link)))
		   'mouse-face (or (org-link-get-parameter type :mouse-face)
				   'highlight)
		   'keymap (or (org-link-get-parameter type :keymap)
			       org-mouse-map)
		   'help-echo (pcase (org-link-get-parameter type :help-echo)
				((and (pred stringp) echo) echo)
				((and (pred functionp) echo) echo)
				(_ (concat "LINK: " link)))
		   'htmlize-link (pcase (org-link-get-parameter type
								:htmlize-link)
				   ((and (pred functionp) f) (funcall f))
				   (_ `(:uri ,link)))
		   'font-lock-multiline t)))
	    (org-remove-flyspell-overlays-in start end)
	    (org-rear-nonsticky-at end)
	    (if (not (eq 'bracket style))
		(add-text-properties start end properties)
	      ;; Handle invisible parts in bracket links.
	      (remove-text-properties start end '(invisible nil))
	      (let ((hidden
		     (append `(invisible
			       ,(or (org-link-get-parameter type :display)
				    'org-link))
			     properties)))
		(add-text-properties start visible-start hidden)
		(add-text-properties visible-start visible-end properties)
		(add-text-properties visible-end end hidden)
		(org-rear-nonsticky-at visible-start)
		(org-rear-nonsticky-at visible-end)))
	    (let ((f (org-link-get-parameter type :activate-func)))
	      (when (functionp f)
		(funcall f start end path (eq style 'bracket))))
	    (throw :exit t)))))		;signal success
    nil))


(require 'org-clock)
(advice-add 'org-clocking-p :around #'ignore-errors-around-advice)

(provide 'my-org)