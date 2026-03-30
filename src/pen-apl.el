(require 'gnu-apl-mode)

(setq gnu-apl-show-apl-welcome nil)
(setq gnu-apl-show-keymap-on-startup nil)
(setq gnu-apl-show-tips-on-start nil)
;; (setq gnu-apl-show-keymap-on-startup t)

(define-key gnu-apl-interactive-mode-map (kbd "C-c C-k") nil)
;; (define-key gnu-apl-interactive-mode-map (kbd "C-c TAB") 'gnu-apl-finnapl-list)
(define-key gnu-apl-interactive-mode-map (kbd "C-c TAB") nil)

;; https://tryapl.org/
;; https://www.gnu.org/software/apl/apl-intro.html
;; https://www.gnu.org/software/apl/apl-intro.html#CH_3.3.3

;; +/⍳100000

(defun start-apl-server ()
  (interactive)
  (nw "apl" "-d"))

(defun runapl (s)
  (pen-snc
   (concat
    (cmd "apl" "-s" "-f"
         (tf "tempXXX" (concat
                        (awk1 s)
                        ")OFF") "apl"))
    "| sed '/^$/d'")))

;; It's not exactly fast
;; But start APL first in a tmux split, and it will run much faster
(defun testrunapl ()
  (interactive)
  (ifietv
   (runapl "+/⍳100000")))

(defun testrunapl-2 ()
  (interactive)
  (ifietv
   (runapl "+/[2] (3 3⍴1 2 3 4 5 6 7 8 9)")))

;; Add a time delay to showing the keyboard
;; 0.1 sec added some reliability
(defun gnu-apl (apl-executable)
  "Start the GNU APL interpreter in a buffer.
APL-EXECUTABLE is the path to the apl program (defaults
to ‘gnu-apl-executable’)."
  (interactive (list (when current-prefix-arg
                       (read-file-name "Location of GNU APL Executable: " nil nil t))))
  (let ((buffer (get-buffer-create "*gnu-apl*"))
        (resolved-binary (or apl-executable gnu-apl-executable)))
    (unless resolved-binary
      (user-error "GNU APL Executable was not set"))
    (pop-to-buffer-same-window buffer)
    (unless (comint-check-proc buffer)
      (gnu-apl--cleanup-trace-symbol buffer)
      (when gnu-apl-show-tips-on-start
        (gnu-apl--insert-tips))
      (apply #'make-comint-in-buffer
             "apl" buffer resolved-binary nil
             "--rawCIN" "--emacs" (append (if (and gnu-apl-native-communication gnu-apl-use-new-native-library)
                                              (list "--emacs_arg" (int-to-string gnu-apl-native-listener-port)))
                                          (if (not gnu-apl-show-apl-welcome)
                                              (list "--silent"))
                                          gnu-apl-program-extra-args))
      (setq gnu-apl-current-session buffer)

      (gnu-apl-interactive-mode)
      (set-process-coding-system (get-buffer-process (current-buffer)) 'utf-8 'utf-8)
      (when (and gnu-apl-native-communication (not gnu-apl-use-new-native-library))
        (gnu-apl--send buffer (concat "'" *gnu-apl-network-start* "'"))
        (gnu-apl--send buffer (concat "'" gnu-apl-libemacs-location "' ⎕FX "
                                      "'" *gnu-apl-native-lib* "'"))
        (gnu-apl--send buffer (format "%s[1] %d" *gnu-apl-native-lib* gnu-apl-native-listener-port))
        (gnu-apl--send buffer (concat "'" *gnu-apl-network-end* "'"))))
    (when gnu-apl-show-keymap-on-startup
      ;; (run-at-time "0 sec" nil #'(lambda () (gnu-apl-show-keyboard 1)))
      (run-at-time "0.1 sec" nil #'(lambda () (gnu-apl-show-keyboard 1))))))

;; (define-key gnu-apl-interactive-mode-map (kbd "C-c C-h") 'gnu-apl-show-help-for-symbol)
(define-key gnu-apl-interactive-mode-map (kbd "C-c C-h") nil)

;; e:pronounce-apl
(defun pen-pronounce-apl (s)
  (interactive (list (pen-buffer-string-or-selection)))
  (pen-etv (pen-snc "pronounce-apl" s) 'text-mode))

;; e:visor-apl-show-pronounciation
(defun pen-visor-apl-show-pronounciation (s)
  (interactive (list (pen-buffer-string-or-selection)))
  (pen-etv (pen-snc "visor-apl-show-pronounciation" s) 'text-mode))

;; e:visor-apl-show-functionality
(defun pen-visor-apl-show-functionality (s)
  (interactive (list (pen-buffer-string-or-selection)))
  (pen-etv (pen-snc "visor-apl-show-functionality" s) 'text-mode))

;; e:visor-apl-show-keys
(defun pen-visor-apl-show-keys (s)
  (interactive (list (pen-buffer-string-or-selection)))
  (pen-etv (pen-snc "visor-apl-show-keys" s) 'text-mode))

(provide 'pen-apl)
