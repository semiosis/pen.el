(require 'comint)

;; ** TODO Make a system for text-adventure games
;; - Set up for each game a set of default commands which are generally understood by the game at any point.
;;   - Display them in a hyper-convenient way.
;;     - Perhaps with universal-sidecaar.
;;     - Click them as buttons which should send the command to the terminal.
;;     - Consider also letting it prompt the user to complete parameters for the command, like in Apple's commando.


;; Perhaps also make rules for providing buttons.
;; For example, if asked a yes/no question provide buttons for yes and no
;; (defset pen-comint-common-commands '(("bsdgames-adventure" .
;;                                       ("score" "save" "quit" "help" "info"
;;                                        "nw" "ne" "se" "sw"))))
;; This works the same way
;; (defset pen-comint-common-commands '(("bsdgames-adventure" 
;;                                       "score" "save" "quit" "help" "info"
;;                                       "nw" "ne" "se" "sw")))
;; It's still an alist
(defset pen-comint-common-commands '(("bsdgames-adventure"
                                      "score" "save" "quit" "help" "info"
                                      "nw" "ne" "se" "sw")

                                     ;; 1979 game
                                     ;; ssh-host man battlestar
                                     ("battlestar"
                                      "score" "inven"
                                      "save"
                                      "take" "drop"
                                      ("wear" "wear an object you are holding")
                                      ("draw" "carry an object you are wearing")
                                      ("put on" "take an object and wear it")
                                      ("take off" "draw an object and drop it")
                                      ("eat" nil nil)
                                      ;; TODO Make it so I can prompt the user for arguments based on the description from the 3rd element
                                      ("throw" nil "<object> <direction>")
                                      "n" "s" "e" "w"
                                      ;; without compass:
                                      "r" "l" "a" "b"
                                      "up" "down")))

;; Unsure how this has broken
(comment
 (add-to-list 'universal-sidecar-sections '(comint-section :title "Comint!"))
 (remove-from-list 'universal-sidecar-sections '(comint-section :title "Comint!")))
(add-to-list 'universal-sidecar-sections '(comint-section :title "Comint!"))

(defset pen-sidecar-current-buffer nil)
(defun pen-sidecar-get-current-buffer (&optional b-noset)
  (if (not b-noset) (setq pen-sidecar-current-buffer (current-buffer)))
  pen-sidecar-current-buffer)

(defun pen-sidecar-current-buffer-name (&optional b-noset)
  (let ((b (pen-sidecar-get-current-buffer b-noset)))
    (if b
        (buffer-name b))))

(defun pen-sidecar-match-current-buffer-name (pattern &optional b-noset)
  (let ((bn (pen-sidecar-current-buffer-name b-noset)))
    (if bn
        (s-matches-p pattern bn))))

(defun pen-comint--battlestar--score ()
  (interactive)
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (end-of-buffer)
    (insert "score")
    (comint-send-input)))

(defun pen-comint--battlestar--inven ()
  (interactive)
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (end-of-buffer)
    (insert "inven")
    (comint-send-input)))

(defun pen-comint--battlestar--save ()
  (interactive)
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (end-of-buffer)
    (insert "save")
    (comint-send-input)
    (insert (read-string-hist "Battlestar savegame name: " "test.Bstar"))
    (comint-send-input)))

(defun pen-comint--battlestar--drop ()
  (interactive)
  (pen-comint--battlestar--inven)
  ;; Need this sleep to get the output.
  ;; But I should be using an "expect" system.
  (sleep 0.5)
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (let* ((bufstring (buffer-string))
           (items (-filter-not-empty-string (str2lines (snc "battlestar--scrape-inventory" bufstring))))
           (item (if items
                     (fz items nil nil "Drop item: "))))
      (if item
          (progn
            (end-of-buffer)
            (insert (format "drop %s" item))
            (comint-send-input))
        (message "You aren't carrying anything"))
      ;; (insert (read-string-hist "Battlestar savegame name: " "test.Bstar"))
      ;; (comint-send-input)
      )))

;; TODO Figure out how to wait for (expect) next comint prompt before inserting again into the repl.

(defun comint-smart-insert (game com)
  ;; (tv (format "game: %s, command: %s" game com))
  (with-current-buffer (pen-sidecar-current-buffer-name t)
    (end-of-buffer)
    (let* ((comname (format "pen-comint--%s--%s" (str game) (str com)))
           (comsym (str2sym comname)))
      (if (commandp comsym)
          (call-interactively comsym)
        (insert com)))))

(universal-sidecar-define-section comint-section (file title)
                                  (:major-modes comint-mode
                                                :predicate (or (pen-sidecar-match-current-buffer-name "bsdgames-adventure")
                                                               (pen-sidecar-match-current-buffer-name "battlestar")))
  (let* ((title "Comint!"))
    (universal-sidecar-insert-section comint-section title
      (insert
       (universal-sidecar-fontify-as org-mode ((org-fold-core-style 'overlays))
         ;; This is inserted
         (concat
          "Commands for "  (pen-sidecar-current-buffer-name t) ":\n"
          (s-join " " (-flatten
                       (mapcar
                        (lambda (bn)
                          (format "[[comint-smart-insert:%s %s][%s]]" (first bn) (second bn)
                                  (second bn)))
                        (-filter 'identity
                                 (flatten-once
                                  (loop for c in pen-comint-common-commands
                                        if (pen-sidecar-match-current-buffer-name (car c) t)
                                        collect (mapcar
                                                 (lambda (e) (list (car c)
                                                                   (cond
                                                                    ((listp e) (car e))
                                                                    ((stringp e) e))))
                                                 (cdr c))
                                        else collect nil))))))))))))


(provide 'pen-comint-sidecar)
