;;; hyperdrive-download-monitor.el ---    -*- lexical-binding: t; -*-

;; Copyright (C) 2024 USHIN, Inc.

;; Author: Joseph Turner <joseph@ushin.org>
;; Author: Adam Porter <adam@alphapapa.net>
;; Maintainer: Joseph Turner <~ushin/ushin@lists.sr.ht>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation; either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public
;; License along with this program. If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Monitor a file download's progress in a buffer.

;;; Code:

(require 'cl-lib)
(require 'map)
(require 'pcase)

;;;; Variables

(defvar-local h/download-monitor-etc nil)

;;;; Functions

(cl-defun h//download-monitor
    (&key buffer-name path total-size preamble postamble (update-interval 1))
  "Return buffer that monitors the download to PATH expecting it to be TOTAL-SIZE.
Buffer's name is based on BUFFER-NAME.  PREAMBLE and POSTAMBLE
are inserted at the top and bottom of the buffer, respectively.
Monitor buffer is updated every UPDATE-INTERVAL seconds."
  (let ((buffer (generate-new-buffer buffer-name)))
    (with-current-buffer buffer
      (special-mode)
      (setf (map-elt h/download-monitor-etc :path) path
            (map-elt h/download-monitor-etc :total-size) total-size
            (map-elt h/download-monitor-etc :preamble) preamble
            (map-elt h/download-monitor-etc :postamble) postamble
            (map-elt h/download-monitor-etc :started-at) (current-time)
            (map-elt h/download-monitor-etc :timer)
            (run-at-time nil update-interval #'h//download-monitor-update buffer))
      (setq-local kill-buffer-hook
                  (cons (lambda ()
                          (when (timerp (map-elt h/download-monitor-etc :timer))
                            (cancel-timer (map-elt h/download-monitor-etc :timer))))
                        kill-buffer-hook)
                  cursor-type nil))
    buffer))

(defun h//download-monitor-update (buffer)
  "Update download monitor in BUFFER."
  (with-current-buffer buffer
    (pcase-let* (((map :preamble :postamble :path :total-size :started-at)
                  h/download-monitor-etc)
                 (attributes (and (file-exists-p path)
                                  (file-attributes path)))
                 (current-size (or (and attributes
                                        (file-attribute-size attributes))
                                   0))
                 (elapsed (float-time (time-subtract (current-time) started-at)))
                 (speed (/ current-size elapsed)))
      ;; TODO: Consider using `format-spec'.
      (with-silent-modifications
        (erase-buffer)
        (insert preamble
                "Downloaded: " (file-size-human-readable current-size nil " ")
                " / " (file-size-human-readable total-size nil " ") "\n"
                "Elapsed: " (format-seconds "%hh%mm%ss%z" elapsed) "\n"
                "Speed: " (file-size-human-readable speed) "/s\n\n"
                postamble)))))

(defun h//download-monitor-close (buffer)
  "Close download monitor BUFFER."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (when (timerp (map-elt h/download-monitor-etc :timer))
        (cancel-timer (map-elt h/download-monitor-etc :timer))))
    (let ((buffer-window (get-buffer-window buffer)))
      (when buffer-window
        (quit-window nil buffer-window)))
    (kill-buffer buffer)))

(provide 'hyperdrive-download-monitor)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-download-monitor.el ends here
