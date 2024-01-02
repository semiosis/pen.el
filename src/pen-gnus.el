(add-to-list 'load-path (concat emacsdir "/manual-packages/gnus"))
(require 'gnus)
(load-library "gnus")



(pen-snc (pen-cmd "touch" "~/.gnus"))

;; TODO Ensure that the =gnus-summary= map, etc. are not butchered by gnus

;; (defset gnus-article-mode-map
;;   (let ((keymap (make-sparse-keymap)))
;;     keymap))
;; (defset gnus-summary-mode-map
;;   (let ((keymap (make-keymap)))
;;     keymap))
;; (defset gnus-group-mode-map
;;   (let ((keymap (make-keymap)))
;;     keymap))

;; Suppress gnus-suppress-keymap
;; (defun gnus-suppress-keymap-around-advice (proc &rest args)
;;   (never
;;    (let ((res (apply proc args)))
;;      res)))
;; (advice-add 'gnus-suppress-keymap :around #'gnus-suppress-keymap-around-advice)
(load-library "gnus")
;; (load "/home/shane/local/emacs28/share/emacs/28.0.50/lisp/gnus/gnus.el.gz")

(require 'gnus)

;; e:$HOME/.gnus
;; e:$HOME/local/emacs28/share/emacs/28.0.50/lisp/gnus/gnus.el.gz
;; e:$EMACSD/manual-packages/gnus/gnus.el

;; (defun gnus-suppress-keymap (keymap)
;;   ;; (suppress-keymap keymap)
;;   ;; (let ((keys '([delete] "\177" "\M-u"))) ;[mouse-2]
;;   ;;   (while keys
;;   ;;     (define-key keymap (pop keys) 'undefined)))
;;   )

(define-key gnus-group-mode-map (kbd "M-k") 'gnus-group-edit-local-kill)
(define-key gnus-group-mode-map (kbd "M-k") nil)

(define-key gnus-summary-mode-map (kbd "M-k") 'gnus-summary-edit-local-kill)
(define-key gnus-summary-mode-map (kbd "M-k") nil)


(setq gnus-always-read-dribble-file t)

;; [[egr:gnus config emacs]]



;; (defun gnus-articles-to-read-around-advice (proc group &optional read-all)
;;   (let ((res (apply proc (list group ;; read-all
;;                                t))))
;;     res))
;; (advice-add 'gnus-articles-to-read :around #'gnus-articles-to-read-around-advice)
;; (advice-remove 'gnus-articles-to-read #'gnus-articles-to-read-around-advice)


(defun gnus-articles-to-read (group &optional read-all)
  "Find out what articles the user wants to read."
  (let* ((only-read-p t)
         (articles
          (gnus-list-range-difference
           ;; Select all articles if `read-all' is non-nil, or if there
           ;; are no unread articles.
           (if (or read-all
                   (and (zerop (length gnus-newsgroup-marked))
                        (zerop (length gnus-newsgroup-unreads)))
                   ;; Fetch all if the predicate is non-nil.
                   gnus-newsgroup-display)
               ;; We want to select the headers for all the articles in
               ;; the group, so we select either all the active
               ;; articles in the group, or (if that's nil), the
               ;; articles in the cache.
               (or
                (if gnus-newsgroup-maximum-articles
                    (let ((active (gnus-active group)))
                      (gnus-uncompress-range
                       (cons (max (car active)
                                  (- (cdr active)
                                     gnus-newsgroup-maximum-articles
                                     -1))
                             (cdr active))))
                  (gnus-uncompress-range (gnus-active group)))
                (gnus-cache-articles-in-group group))
             ;; Select only the "normal" subset of articles.
             (setq only-read-p nil)
             (gnus-sorted-nunion
              (gnus-sorted-union gnus-newsgroup-dormant gnus-newsgroup-marked)
              gnus-newsgroup-unreads))
           (cdr (assq 'unexist (gnus-info-marks (gnus-get-info group))))))
         (scored-list (gnus-killed-articles gnus-newsgroup-killed articles))
         (scored (length scored-list))
         (number (length articles))
         (marked (+ (length gnus-newsgroup-marked)
                    (length gnus-newsgroup-dormant)))
         (select
          (cond
           ((numberp read-all)
            read-all)
           ((numberp gnus-newsgroup-display)
            gnus-newsgroup-display)
           (t
            (condition-case ()
                (cond
                 ((and (or (<= scored marked) (= scored number))
                       (numberp gnus-large-newsgroup)
                       (> number gnus-large-newsgroup))
                  (let* ((cursor-in-echo-area nil)
                         (initial (gnus-parameter-large-newsgroup-initial
                                   gnus-newsgroup-name))
                         (default (if only-read-p
                                      (if (eq initial 'all)
                                          nil
                                        (or initial gnus-large-newsgroup))
                                    number))
                         ;; it's about 1MB per 1000
                         (input (number-to-string ;; default
                                 number)
                                ;; (read-string
                                ;;  (if only-read-p
                                ;;      (format
                                ;;       "How many articles from %s (available %d, default %d): "
                                ;;       (gnus-group-real-name gnus-newsgroup-name)
                                ;;       number default)
                                ;;    (format
                                ;;     "How many articles from %s (%d default): "
                                ;;     (gnus-group-real-name gnus-newsgroup-name)
                                ;;     default))
                                ;;  nil
                                ;;  nil
                                ;;  (number-to-string default))
                                ))
                    (if (string-match "^[ \t]*$" input) number input)))
                 ((and (> scored marked) (< scored number)
                       (> (- scored number) 20))
                  (let ((input
                         (read-string
                          (format "%s %s (%d scored, %d total): "
                                  "How many articles from"
                                  (gnus-group-real-name gnus-newsgroup-name)
                                  scored number))))
                    (if (string-match "^[ \t]*$" input)
                        number input)))
                 (t number))
              (quit
               (message "Quit getting the articles to read")
               nil))))))
    (setq select (if (stringp select) (string-to-number select) select))
    (if (or (null select) (zerop select))
        select
      (if (and (not (zerop scored)) (<= (abs select) scored))
          (progn
            (setq articles (sort scored-list #'<))
            (setq number (length articles)))
        (setq articles (copy-sequence articles)))

      (when (< (abs select) number)
        (if (< select 0)
            ;; Select the N oldest articles.
            (setcdr (nthcdr (1- (abs select)) articles) nil)
          ;; Select the N most recent articles.
          (setq articles (nthcdr (- number select) articles))))
      (setq gnus-newsgroup-unselected
            (gnus-sorted-difference gnus-newsgroup-unreads articles))
      (when (functionp gnus-alter-articles-to-read-function)
        (setq articles
              (sort
               (funcall gnus-alter-articles-to-read-function
                        gnus-newsgroup-name articles)
               #'<)))
      articles)))


(setq gnus-summary-display-arrow nil)

;; ---

;; This is evil. It's not even part of gnus
;; vim +/"(defun ffap-ro-mode-hook ()" "$HOME/local/emacs28/share/emacs/28.0.50/lisp/ffap.el.gz"

(defun ffap-ro-mode-hook ()
  "Bind `ffap-next' and `ffap-menu' to M-l and M-m, resp."
  ;; (local-set-key "\M-l" 'ffap-next)
  ;; (local-set-key "\M-m" 'ffap-menu)
  )

(defun ffap-gnus-hook ()
  "Bind `ffap-gnus-next' and `ffap-gnus-menu' to M-l and M-m, resp."
  ;; message-id's
  (setq-local thing-at-point-default-mail-uri-scheme "news")
  ;; Note "l", "L", "m", "M" are taken:
  ;; (local-set-key "\M-l" 'ffap-gnus-next)
  ;; (local-set-key "\M-m" 'ffap-gnus-menu)
  )

;; ---



;; This doesn't work. I need to bind on the hooks
;; (define-key gnus-group-mode-map (kbd "RET") 'gnus-group-select-group)
;; (define-key gnus-summary-mode-map (kbd "RET") 'gnus-summary-select-article-buffer)


(add-hook
 'gnus-group-mode-hook
 (lambda ()
   (define-key gnus-group-mode-map (kbd "RET")
     'gnus-group-select-group)))

(add-hook
 'gnus-summary-mode-hook
 (lambda ()
   (define-key gnus-group-mode-map (kbd "RET")
     'gnus-summary-select-article-buffer)))

(set-face-foreground 'gnus-group-mail-3-empty nil)
(set-face-background 'gnus-group-mail-3-empty nil)

(define-key gnus-summary-mode-map (kbd "RET") 'gnus-summary-read-document)
(define-key gnus-group-mode-map (kbd "RET") 'gnus-summary-select-article-buffer)
;; (define-key gnus-group-mode-map (kbd "RET") 'gnus-group-select-group)

(defun gnus-summary-select-article-buffer ()
  "Reconfigure windows to show the article buffer.
If `gnus-widen-article-window' is set, show only the article
buffer."
  (interactive)
  ;; Killing this buffer solves more problems than it creates
  (ignore-errors (kill-buffer gnus-article-buffer))
  (if (not (gnus-buffer-live-p gnus-article-buffer))
      (progn
        ;; (error "There is no article buffer for this summary buffer")
        (call-interactively 'gnus-group-select-group))
    (or (get-buffer-window gnus-article-buffer)
	      (eq gnus-current-article (gnus-summary-article-number))
	      (gnus-summary-show-article))
    (let ((point (with-current-buffer gnus-article-buffer
		               (point))))
      (gnus-configure-windows
       (if gnus-widen-article-window
	         'only-article
	       'article)
       t)
      (select-window (get-buffer-window gnus-article-buffer))
      ;; If we've just selected the message, place point at the start of
      ;; the body because that's probably where we want to be.
      (if (not (= point (point-min)))
	        (goto-char point)
	      (article-goto-body)
	      (forward-char -1)))))

(provide 'pen-gnus)