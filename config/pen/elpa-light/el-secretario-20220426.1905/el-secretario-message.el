;;; el-secretario-message.el --- A source that displays one message -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Leo
;;
;; Author: Leo Okawa Ericson <http://github/Zetagon>
;; Maintainer: Leo <github@relevant-information.com>
;; Created: January 21, 2021
;; Modified: January 21, 2021
;; Version: 0.0.1
;; Keywords: convenience
;; Homepage: https://git.sr.ht/~zetagon/el-secretario
;;
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file LICENSE.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;
;;; Commentary:
;;
;;  A source that displays one message
;;
;;; Code:
(require 'el-secretario-source)


(defvar el-secretario-message-pre-message-marker nil
  "The marker to return to before a message has been displayed.")

(defvar el-secretario-message-keymap (let ((km (make-sparse-keymap)))
                  (define-key km
                    "q" '("quit" . el-secretario-message--back-to-pre-message))
                  km)
  "The keymap to be used for current message.")

(defvar el-secretario-message-buffer-name "*el-secretario message*")

;;;###autoload
(defun el-secretario-message-display-message-prompt (message &optional keymap)
  "Display MESSAGE in a dedicated buffer.
If KEYMAP is nil, use `el-secretario-message-message-keymap'.

If KEYMAP is non-nil, use that as prompt.  Keep in mind that it
should probably have one keybinding that calls
`el-secretario-message--back-to-pre-message'"
  (setq el-secretario-message-pre-message-marker (point-marker))
  (switch-to-buffer (get-buffer-create el-secretario-message-buffer-name))
  (delete-region (point-min) (point-max))
  (insert message)
  (setq el-secretario-message-keymap (or keymap 'el-secretario-message-message-keymap))
  (hercules--show el-secretario-message-keymap t t))

(defun el-secretario-message--back-to-pre-message ()
  "Quit from the message and reset state."
  (interactive)
  (switch-to-buffer (marker-buffer el-secretario-message-pre-message-marker))
  (goto-char (marker-position el-secretario-message-pre-message-marker))
  (setq el-secretario-message-keymap nil))

(defvar el-secretario-message-message-keymap (make-sparse-keymap)
  "Default keymap for exiting a message.
Only one head which is for removing the message buffer.")

(defmacro el-secretario-message--with-pre-buffer (&rest body)
  "Run BODY in the buffer before the current message was displayed."
  `(if (string-equal (buffer-name)
                     el-secretario-message-buffer-name)
       (with-current-buffer (marker-buffer el-secretario-message-pre-message-marker)
         (save-excursion
           (goto-char (marker-position el-secretario-message-pre-message-marker))

           ,@body))
     ,@body))

(provide 'el-secretario-message)
;;; el-secretario-message.el ends here

;; Local Variables:
;; package-lint-main-file: "el-secretario.el"
;; End:
