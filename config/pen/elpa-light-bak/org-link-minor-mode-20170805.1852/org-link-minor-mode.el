;;; org-link-minor-mode.el --- Enable org-mode links in non-org modes
;;
;; Copyright (C) 2012-2017
;; Author: Sean O'Halpin <sean dot ohalpin at gmail dot com>
;; Changes for org v9: Stefan-W. Hahn <stefan dot hahn at s-hahn dot de>
;; Package-Requires: ((org "8"))
;; Package-Version: 20170805.1852
;; Url: https://github.com/seanohalpin/org-link-minor-mode
;;
;; Enables org-mode links of the form:
;;
;;   http://www.bbc.co.uk
;;   man:emacs
;;   info:emacs
;;   <http://www.bbc.co.uk>
;;   [[http://www.bbc.co.uk][BBC]]
;;   [[org-link-minor-mode]]
;;   [2012-08-18]
;;   <2012-08-18>
;;
;; Note that =org-toggle-link-display= will also work when this mode
;; is enabled.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(require 'org)

;; Following declarations are necessary to make the byte compiler happy.

;; For org v8 compatibility (if used with org v9)
(declare-function org-activate-plain-links "org" (limit))
(declare-function org-activate-angle-links "org" (limit))
(declare-function org-activate-bracket-links "org" (limit))
(declare-function org-decompose-region "org-compat" (beg end))

;; For org v9 compatibility (if used with org v8)
(declare-function org-activate-links "org" (limit))
(declare-function org-activate-dates "org" (limit))

(defun org-link-minor-mode-unfontify-region (beg end &optional maybe_loudly)
  "Remove fontification and activation overlays from links."
  (font-lock-default-unfontify-region beg end)
  (let* ((buffer-undo-list t)
         (inhibit-read-only t) (inhibit-point-motion-hooks t)
         (inhibit-modification-hooks t)
         deactivate-mark buffer-file-name buffer-file-truename)
    (if (fboundp 'org-decompose-region)
        (org-decompose-region beg end)
      (decompose-region beg end))
    (remove-text-properties beg end
                            '(mouse-face t keymap t org-linked-text t
                                         invisible t intangible t
                                         help-echo t rear-nonsticky t
                                         org-no-flyspell t org-emphasis t))
    (org-remove-font-lock-display-properties beg end)))

(defvar org-link-minor-mode-map (make-sparse-keymap)
  "Local keymap.")
(make-variable-buffer-local 'org-link-minor-mode-map)

;;;###autoload
(define-minor-mode org-link-minor-mode
  "Toggle display of org-mode style bracket links in non-org-mode buffers."
  :lighter " org-link"
  :keymap org-link-minor-mode-map
  (let ((lk org-highlight-links)
        org-link-minor-mode-keywords)
    (if (fboundp 'org-activate-links)
        ;; from Org v9.2
        (setq org-link-minor-mode-keywords
              (list
               '(org-activate-links)
               (when (memq 'tag lk) '(org-activate-tags (1 'org-tag prepend)))
               (when (memq 'radio lk) '(org-activate-target-links (1 'org-link t)))
               (when (memq 'date lk) '(org-activate-dates (0 'org-date t)))
               (when (memq 'footnote lk) '(org-activate-footnote-links))))
      (setq org-link-minor-mode-keywords
            (list
             (if (memq 'tag lk) '(org-activate-tags (1 'org-tag prepend)))
             (if (memq 'angle lk) '(org-activate-angle-links (0 'org-link t)))
             (if (memq 'plain lk) '(org-activate-plain-links (0 'org-link t)))
             (if (memq 'bracket lk) '(org-activate-bracket-links (0 'org-link t)))
             (if (memq 'radio lk) '(org-activate-target-links (0 'org-link t)))
             (if (memq 'date lk) '(org-activate-dates (0 'org-date t)))
             (if (memq 'footnote lk) '(org-activate-footnote-links)))))
    (if org-link-minor-mode
        (if (derived-mode-p 'org-mode)
            (progn
              (message "org-mode doesn't need org-link-minor-mode")
              (org-link-minor-mode -1))
          (font-lock-add-keywords nil org-link-minor-mode-keywords t)
          (kill-local-variable 'org-mouse-map)
          (setq-local org-mouse-map
                      (let ((map (make-sparse-keymap)))
                        (define-key map [return] 'org-open-at-point)
                        (define-key map [tab] 'org-next-link)
                        (define-key map [backtab] 'org-previous-link)
                        (define-key map [mouse-2] 'org-open-at-point)
                        (define-key map [follow-link] 'mouse-face)
                        map))
          (setq-local font-lock-unfontify-region-function
                      'org-link-minor-mode-unfontify-region)
          (setq-local org-descriptive-links org-descriptive-links)
          (condition-case nil (require 'org-man)
            (error (message "Problems while trying to load feature `org-man'")))
          ;; Set to non-descriptive and then switch to descriptive links
          (setq org-descriptive-links nil)
          (org-toggle-link-display))
      (unless (derived-mode-p 'org-mode)
        (font-lock-remove-keywords nil org-link-minor-mode-keywords)
        (org-restart-font-lock)
        (remove-from-invisibility-spec '(org-link))
        (kill-local-variable 'org-descriptive-links)
        (kill-local-variable 'org-mouse-map)
        (kill-local-variable 'font-lock-unfontify-region-function)
        ))))

(provide 'org-link-minor-mode)
;;; org-link-minor-mode.el ends here
