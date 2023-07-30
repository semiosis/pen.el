;; This is so emacs can run in a terminal

(defun lo-display ()
  (interactive)
  (sps "tail -f /tmp/yo.txt"))

(defun lo (o)
  "log object"
  (append-string-to-file (concat
                          (pps o)
                          "\n")
                         "/tmp/yo.txt")
  o)

;; In default mode, each numeric parameter of XTerm's mouse report is
;; a single char, possibly encoded as utf-8.  The actual numeric
;; parameter then is obtained by subtracting 32 from the character
;; code.  In extended mode the parameters are returned as decimal
;; string delimited either by semicolons or for the last parameter by
;; one of the characters "m" or "M".  If the last character is a "m",
;; then the mouse event was a button release, else it was a button
;; press or a mouse motion.  Return value is a cons cell with
;; (NEXT-NUMERIC-PARAMETER . LAST-CHAR)
(defun xterm-mouse--read-number-from-terminal (extension)
  (let (c)
    (if extension
        (let ((n 0))
          (while (progn
                   (setq c (read-char))
                   ;; (lo (char-to-string c))
                   (<= ?0 c ?9))
            (setq n (+ (* 10 n) c (- ?0))))
          (cons n c))
      (cons (- (setq c (xterm-mouse--read-coordinate)) 32) c))))

;; XTerm reports mouse events as
;; <EVENT-CODE> <X> <Y> in default mode, and
;; <EVENT-CODE> ";" <X> ";" <Y> <"M" or "m"> in extended mode.
;; The macro read-number-from-terminal takes care of reading
;; the response parameters appropriately.  The EVENT-CODE differs
;; slightly between default and extended mode.
;; Return a list (EVENT-TYPE-SYMBOL X Y).
(defun xterm-mouse--read-event-sequence (&optional extension)
  (pcase-let*
      ((`(,code . ,_) (xterm-mouse--read-number-from-terminal extension))
       (`(,x . ,_) (xterm-mouse--read-number-from-terminal extension))
       (`(,y . ,c) (xterm-mouse--read-number-from-terminal extension))
       (wheel (/= (logand code 64) 0))
       (move (/= (logand code 32) 0))
       ;; (ctrl (/= (lo (logand (lo code) 16)) 0))
       (ctrl (/= (logand code 16) 0))
       (meta (/= (logand code 8) 0))
       (shift (/= (logand code 4) 0))
       (down (and (not wheel)
                  (not move)
                  (if extension
                      (eq c ?M)
                    (/= (logand code 3) 3))))
       (btn (cond
             ((or extension down wheel)
              (+ (logand code 3) (if wheel 4 1)))
             ;; The default mouse protocol does not report the button
             ;; number in release events: extract the button number
             ;; from last button-down event.
             ((terminal-parameter nil 'xterm-mouse-last-down)
              (string-to-number
               (substring
                (symbol-name
                 (car (terminal-parameter nil 'xterm-mouse-last-down)))
                -1)))
             ;; Spurious release event without previous button-down
             ;; event: assume, that the last button was button 1.
             (t 1)))
       (sym (if move 'mouse-movement
              (intern (concat (if ctrl "C-" "")
                              (if meta "M-" "")
                              (if shift "S-" "")
                              (if down "down-" "")
                              "mouse-"

                              ;; A left-click:
                              ;; (down-mouse-1 22 14)
                              ;; (mouse-1 16 12)

                              ;; A left-ctrl-click
                              ;; (C-down-mouse-1 37 13)
                              ;; (C-mouse-1 37 13)

                              ;; A right-click:
                              ;; (down-mouse-3 19 13)
                              ;; (mouse-3 19 13)

                              ;; A right-ctrl-click:
                              ;; (C-down-mouse-3 24 9)
                              ;; (C-mouse-3 24 9)

                              ;; if btn=4 it is mousewheel-up
                              ;; (mouse-4 17 16)

                              ;; if btn=5 it is mousewheel-down
                              ;; (mouse-5 13 13)
                              (number-to-string btn))))))

    ;; (lo (list sym (1- x) (1- y)))
    (list sym (1- x) (1- y))))

;; (defun xterm-mouse--read-coordinate ()
;;   "Read a mouse coordinate from the current terminal.
;; If `xterm-mouse-utf-8' was non-nil when
;; `turn-on-xterm-mouse-tracking-on-terminal' was called, reads the
;; coordinate as an UTF-8 code unit sequence; otherwise, reads a
;; single byte."
;;   (let ((previous-keyboard-coding-system (keyboard-coding-system))
;;         (r (unwind-protect
;;                (progn
;;                  (set-keyboard-coding-system
;;                   (if (terminal-parameter nil 'xterm-mouse-utf-8)
;;                       'utf-8-unix
;;                     'no-conversion))
;;                  ;; Wait only a little; we assume that the entire escape sequence
;;                  ;; has already been sent when this function is called.
;;                  (read-char nil nil 0.1))
;;              (set-keyboard-coding-system previous-keyboard-coding-system))))
;;     (append-string-to-file (concat "hi:" (str r)) "/tmp/yo.txt")
;;     r))

(provide 'pen-xt-mouse)
