(require 'dash)
(require 'nav-flash)

;; TODO Select a current filter command (scrapes for things)

;; This might be better called 'filter navigator'

;; TODO C-u to update the position-list function. That will just let you select it

(defvar position-list-current-function nil)
(defvar position-list-functions '())

;; This generates from a shell script but does not use byte positions
;; I need one that is also given the byte positions, and possibly also the string match itself
;; pos:len
;; pos:len
(defun make-position-list-function (pen-cmd-filter)
  (interactive (list (sed "s/ *#.*//" (fz (cat "/root/.emacs.d/host/pen.el/config/filters/filters.sh")))))
  (let ((f (func-for-expression
            "position-list-function"
            `(save-excursion
               (beginning-of-buffer)
               (cl-loop
                for
                s
                in
                (pen-str2list (pen-cl-sn ,cmd-filter :stdin (buffer-string) :chomp t))
                collect
                (list
                 (progn
                   (search-forward s)
                   (if (match-string 0)
                       (backward-char (length (match-string 0))))
                   (point))
                 s)))
            t
            cmd-filter)))
    (add-to-list 'position-list-functions f)
    (setq position-list-current-function f)))

(defun show-current-position-list-function-definition ()
  (interactive)
  ;; (nbfs (helpful-function position-list-current-function))
  (helpful-function position-list-current-function))

;; ;; This generates based on a positions lists file
;; ;; pos:len
;; ;; pos:len
;; (defun make-position-list-function-from-position-list-command (pen-cmd-filter)
;;   (interactive (list (sed "s/ *#.*//" (fz (cat "$HOME/filters/filters.sh")))))
;;   (let ((f (func-for-expression
;;             "position-list-function"
;;             `(save-excursion
;;                (beginning-of-buffer)
;;                (cl-loop for pen-str in (-drop-last 1 (pen-str2list (pen-sn ,cmd-filter (buffer-string)))) collect (progn (search-forward s) (point))))
;;             t
;;             cmd-filter)))
;;     (add-to-list 'position-list-functions f)
;;     (setq position-list-current-function f)))

;; (make-position-list-function (sed "s/ *#.*//" (fz (cat "$HOME/filters/filters.sh"))))

;; TODO Collect both positions and the match -- so I can use it if needed
;; This may not be as accurate
(defun positions-of-rpl-1 (rpl)
  (-drop-last
   1
   (mapcar 'byte-to-position (mapcar 'string-to-number (pen-str2list
                                                        (pen-sn
                                                         (concat "rosie grep -w -o jsonpp " (pen-q rpl) " | jq -e \".subs[].s\"")
                                                         (buffer-string)))))))


;; (positions-of-rpl-1 "net.ipv4")

;; (1- 5)
(defun -- (x)
  (- x 1))

(defun positions-of-rosie-net-email ()
  (-drop-last
   1
   (mapcar 'list
           (mapcar 'byte-to-position (mapcar 'string-to-number (pen-str2list
                                                                (pen-sn
                                                                 "rosie grep -w -o jsonpp net.email | jq -e \"( .subs[]  | select(.type==\\\"email\\\") ).s\""
                                                                 (buffer-string))))))))

(defun positions-of-rosie-net-ipv4 ()
  (-drop-last
   1
   (mapcar 'list
           (mapcar 'byte-to-position
                   (mapcar 'string-to-number (pen-str2list
                                              (pen-sn
                                               "rosie grep -w -o jsonpp net.ipv4 | jq -e \"( .subs[]  | select(.type==\\\"ipv4\\\") ).s\""
                                               (buffer-string))))))))
(memoize-by-buffer-contents 'positions-of-rosie-net-email)
(memoize-by-buffer-contents 'positions-of-rosie-net-ipv4)

(add-to-list 'position-list-functions 'positions-of-rosie-net-email)
(add-to-list 'position-list-functions 'positions-of-rosie-net-ipv4)

;; TODO Make an fz which returns a symbol?

;; TODO Find the next monotonically increasing value after (point) from func
;; Return the first one that is greater.
(defun position-list-next (&optional func current)
  ;; (interactive (list (str2sym (fz position-list-functions)) (point)))
  (interactive (list position-list-current-function (point)))

  (if (or current-prefix-arg (not func))
      (progn (setq position-list-current-function (str2sym (fz position-list-functions)))
             (setq func position-list-current-function)))
  (if (not func)
      (error "No position list function selected"))

  (if (not current)
      (setq current (point)))
  (let ((next current)
        (positions (call-function func))
        (s))
    (catch 'bbb
      (mapc
       (lambda (x)
         (when (> (car x) current)
           (setq next (car x))
           (setq pen-str (cadr x))
           (throw 'bbb (car x))))
       positions)
      nil)
    (if (equalp current next)
        (progn (mode-line-bell-flash)
               (message "None further down"))
      (goto-char next))
    (deactivate-mark)
    (nav-flash-show)
    (if s
        (progn
          (call-interactively 'cua-set-mark)
          (forward-char (length s))
          (call-interactively 'cua-exchange-point-and-mark)))))

(defun position-list-prev (&optional func current)
  ;; (interactive (list (str2sym (fz position-list-functions)) (point)))
  (interactive (list position-list-current-function (point)))

  (if (or current-prefix-arg (not func))
      (progn (setq position-list-current-function (str2sym (fz position-list-functions)))
             (setq func position-list-current-function)))
  (if (not func)
      (error "No position list function selected"))

  (if (not current)
      (setq current (point)))
  (let ((next current)
        (positions (reverse (call-function func)))
        (s))
    (catch 'bbb
      (mapc
       (lambda (x)
         (when (< (car x) current)
           (setq next (car x))
           (setq pen-str (cadr x))
           (throw 'bbb (car x))))
       positions)
      nil)
    (if (equalp current next)
        (progn (mode-line-bell-flash)
               (message "None further up"))
      (goto-char next))
    (deactivate-mark)
    (nav-flash-show)
    (if s
        (progn
          (call-interactively 'cua-set-mark)
          (forward-char (length s))
          (call-interactively 'cua-exchange-point-and-mark)))))

(defun position-list-function-select (&optional func)
  (interactive)
  (if (not func)
      (setq func (str2sym (fz position-list-functions nil nil "Position list function select: "))))
  (setq position-list-current-function func))

(defun position-list-show ()
  "The function sometimes doesn't produce the matching strings. It sometimes produces positions only"
  (interactive)
  ;; (with-output-to-temp-buffer
  ;;     "position list show"
  ;;   (pen-list2str
  ;;    (call-function
  ;;     position-list-current-function)))
  (if (not position-list-current-function)
      (error "No position list function selected"))

  (nbfs
   (pen-list2str
    (mapcar 'second
            (call-function
             position-list-current-function)))))

(defun position-list-show-instances ()
  (interactive)
  ;; (nbfs (pp-map-line (mapcar (l (p) (list p (string-at-point p))) (call-function position-list-current-function))))
  ;; (with-output-to-temp-buffer
  ;;     "position list instances"
  ;;   (pp-map-line
  ;;    (mapcar
  ;;     (l (p) (list p (string-at-point p)))
  ;;     (call-function
  ;;      position-list-current-function))))

  (if (not position-list-current-function)
      (error "No position list function selected"))

  (nbfs
   (pp-map-line
    ;; (mapcar
    ;;  (l (p) (list p (string-at-point p)))
    ;;  (call-function
    ;;   position-list-current-function))
    (call-function
     position-list-current-function))
   nil
   'emacs-lisp-mode))

;; DISCORD Memoise the current function until the hydra exits

;; TODO Memoise the current function until a buffer change

(defhydra position-list-nav (:exit nil :color green :hint nil :columns 1)
  "position list navigation"
  ("." (j 'position-list-show) "edit")
  ("," #'position-list-function-select "change function")
  ("n" #'position-list-next "next")
  ("p" #'position-list-prev "prev")
  ("l" #'position-list-show "show list")
  ("i" #'position-list-show-instances "show instances")
  ("f" #'make-position-list-function "use filter")
  ("q" nil "quit"))


(define-key global-map (kbd "H-,") 'position-list-nav/body)
(define-key global-map (kbd "H-=") 'position-list-nav/body)

(provide 'pen-position-list-navigator)
