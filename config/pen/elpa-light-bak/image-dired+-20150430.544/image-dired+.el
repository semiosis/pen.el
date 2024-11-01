;;; image-dired+.el --- Image-dired extensions

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: extensions, multimedia
;; Package-Version: 20150430.544
;; Package-Commit: b68094625d963056ad64e0e44af0e2266b2eadc7
;; URL: https://github.com/mhayashi1120/Emacs-image-diredx
;; Emacs: GNU Emacs 23 or later
;; Version: 0.7.2
;; Package-Requires: ((cl-lib "0.3"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Image-dired extensions

;; - Non-blocking thumbnail creating
;; - Adjust image to window

;; ## Install:

;; * Please install the ImageMagick before install this package.

;; * This package is registered at MELPA. (http://melpa.milkbox.net/)
;;   Please install from here.
;;
;; * If you need to install manually, put this file into load-path'ed
;;   directory, and byte compile it if desired. And put the following
;;   expression into your ~/.emacs.

;;     (eval-after-load 'image-dired '(require 'image-dired+))

;; ## Usage:

;; * Toggle the asynchronous image-dired feature

;;     M-x image-diredx-async-mode

;;  Or put following to your .emacs

;;     (eval-after-load 'image-dired+ '(image-diredx-async-mode 1))


;; * Toggle the adjusting image in image-dired feature

;;     M-x image-diredx-adjust-mode

;;  Or put following to your .emacs

;;     (eval-after-load 'image-dired+ '(image-diredx-adjust-mode 1))

;; ### Optional:

;; * Key bindings to replace `image-dired-next-line' and `image-dired-previous-line'

;;     (define-key image-dired-thumbnail-mode-map "\C-n" 'image-diredx-next-line)
;;     (define-key image-dired-thumbnail-mode-map "\C-p" 'image-diredx-previous-line)

;; * Although default key binding is set, but like a dired buffer,
;;   revert all thumbnails if `image-diredx-async-mode' is on:

;;     (define-key image-dired-thumbnail-mode-map "g" 'revert-buffer)

;; * Delete confirmation prompt with thumbnails.

;;     (define-key image-dired-thumbnail-mode-map "x" 'image-diredx-flagged-delete)

;; ### Recommend:

;; * Suppress unknown cursor movements:

;;     (setq image-dired-track-movement nil)

;;; Code:

;;
;; image-dired extensions
;;

(eval-when-compile
  (require 'easy-mmode))

(require 'cl-lib)

(defgroup image-dired+ ()
  "Image-dired extensions."
  :prefix "image-diredx-"
  :group 'image-dired)

(require 'advice)
(require 'image-dired)

;; to suppress byte-compile warning
(defvar image-diredx-async-mode)

;; NOTE: duplicated from `image-dired-display-thumbs'
(defun image-diredx--prepare-line-up ()
  (cond
   ((eq 'dynamic image-dired-line-up-method)
    (image-dired-line-up-dynamic))
   ((eq 'fixed image-dired-line-up-method)
    (image-dired-line-up))
   ((eq 'interactive image-dired-line-up-method)
    (image-dired-line-up-interactive))
   ((eq 'none image-dired-line-up-method)
    nil)
   (t
    (image-dired-line-up-dynamic))))

(defun image-diredx--redisplay-list-with-point ()
  (let ((file (image-dired-original-file-name)))
    (image-diredx--prepare-line-up)
    (image-diredx--goto-file file)))

(defun image-diredx--redisplay-window-function (frame)
  (when (eq major-mode 'image-dired-thumbnail-mode)
    (image-diredx--redisplay-list-with-point)))

(defvar image-diredx--suppress-invoking nil)

(defun image-diredx--invoke-process (items thumb-buf)
  (when (and items
             (not (buffer-local-value
                   'image-diredx--suppress-invoking thumb-buf)))
    (let* ((item (car items))
           (curr-file (car item))
           (dired-buf (cadr item))
           (thumb-name (image-dired-thumb-name curr-file)))
      (let ((proc
             (if (or
                  (not (file-exists-p curr-file))
                  (and (file-exists-p thumb-name)
                       (file-newer-than-file-p thumb-name curr-file)))
                 ;; !! async trick !!
                 ;; using cached thumbnail.
                 (start-process "image-dired+" nil shell-file-name
                                shell-command-switch "")
               (let ((entity (symbol-function 'call-process))
                     (caller-is-ad (ad-is-active 'call-process)))
                 ;; `fset' may replace `call-process' definition permanently
                 ;; when `call-process' is advised.
                 (when caller-is-ad
                   (ad-deactivate 'call-process))
                 (unwind-protect
                     (progn
                       ;; temporarily replace `call-process' entity.
                       ;; Very dangerous but old `flet' implement like this.
                       (fset 'call-process
                             (lambda (program &optional infile buffer display &rest args)
                               (apply 'start-process "image-dired+" nil program args)))
                       (unwind-protect
                           ;; this function call `call-process' that is replaced
                           ;; by `fset'
                           (image-dired-create-thumb curr-file thumb-name)
                         (fset 'call-process entity)))
                   (when caller-is-ad
                     (ad-activate 'call-process)))))))
        (set-process-sentinel proc 'image-diredx--thumb-process-sentinel)
        (process-put proc 'thumb-name thumb-name)
        (process-put proc 'curr-file curr-file)
        (process-put proc 'dired-buf dired-buf)
        (process-put proc 'thumb-buf thumb-buf)
        (process-put proc 'items (cdr items))
        proc))))

(defun image-diredx--cleanup-processes ()
  (set (make-local-variable 'image-diredx--suppress-invoking) t)
  (unwind-protect
      (let (proc)
        (while (setq proc (get-process "image-dired+"))
          (delete-process proc)))
    (kill-local-variable 'image-diredx--suppress-invoking)))

(defun image-diredx--thumb-process-sentinel (proc event)
  (when (memq (process-status proc) '(exit signal))
    (let ((thumb-name (process-get proc 'thumb-name))
          (curr-file (process-get proc 'curr-file))
          (dired-buf (process-get proc 'dired-buf))
          (thumb-buf (process-get proc 'thumb-buf))
          (items (process-get proc 'items)))
      (when (buffer-live-p thumb-buf)
        (unwind-protect
            (condition-case err
                (if (and (not (file-exists-p thumb-name))
                         (not (= 0 (process-exit-status proc))))
                    (message "Thumb could not be created for file %s" curr-file)
                  (image-diredx--thumb-insert
                   thumb-buf thumb-name curr-file dired-buf))
              (error (message "%s" err)))
          (image-diredx--invoke-process items thumb-buf))))))

(defun image-diredx--thumb-insert (buf thumb file dired)
  (with-current-buffer buf
    ;; save current point and filename.
    ;; restore point or filename.
    (let ((pf (image-dired-original-file-name))
          (pp (point)))
      (save-excursion
        (let ((inhibit-read-only t))
          (goto-char (point-max))
          ;; `image-dired-insert-thumbnail' destroy current window (ex: minibuffer)
          (save-window-excursion
            (image-dired-insert-thumbnail thumb file dired))
          (image-diredx--prepare-line-up)))
      (cond
       (pf
        (image-diredx--goto-file pf))
       (pp
        (goto-char pp))))))

(defun image-diredx--quiet-forward ()
  (let (message-log-max)
    (image-dired-forward-image)))

(defun image-diredx--goto-file (file)
  (let ((point (save-excursion
                 (goto-char (point-min))
                 (condition-case nil
                     (progn
                       (while (not (equal file (image-dired-original-file-name)))
                         (image-diredx--quiet-forward))
                       (point))
                   (error nil)))))
    (when point
      (goto-char point))))

(defun image-diredx-next-line ()
  "`image-dired-next-line' with preserve column"
  (interactive)
  (let ((left (image-diredx--thumb-current-left)))
    (image-dired-next-line)
    (image-diredx--thumb-goto-column left)))

(defun image-diredx-previous-line ()
  "`image-dired-previous-line' with preserve column"
  (interactive)
  (let ((left (image-diredx--thumb-current-left)))
    (image-dired-previous-line)
    (image-diredx--thumb-goto-column left)))

(defun image-diredx--thumb-current-left ()
  (save-excursion
    (let ((first (point))
          (acc 0))
      (beginning-of-line)
      (while (< (point) first)
        (let* ((img (get-text-property (point) 'display))
               (size (image-size img)))
          (setq acc (+ acc
                       ;; calculate both side margin
                       (* (plist-get (cdr img) :margin) 2)
                       (car size) )))
        (image-diredx--quiet-forward))
      acc)))

(defun image-diredx--thumb-goto-column (tleft)
  (let ((point
         (save-excursion
           (save-restriction
             (narrow-to-region (line-beginning-position) (line-end-position))
             (goto-char (point-min))
             (let ((left 0)
                   ;; diff between target and first column
                   (diff tleft)
                   hist)
               (condition-case nil
                   (while (or (null hist)
                              (progn
                                (setq left (image-diredx--thumb-current-left))
                                (setq diff (abs (- tleft left)))
                                ;; Break when incresing differences,
                                ;; this means obviously exceed target column
                                (<= diff (caar hist))))
                     (setq hist (cons (list diff (point)) hist))
                     (image-diredx--quiet-forward))
                 (error nil))
               (cond
                ((null hist)
                 (point))
                ((or (null (cdr hist))
                     (> (car (cadr hist)) (car (car hist))))
                 (cadr (car hist)))
                (t
                 (cadr (cadr hist)))))))))
        (goto-char point)))

(defun image-diredx--thumb-revert-buffer (&rest _ignore)
  (when image-diredx-async-mode
    (image-diredx--cleanup-processes)
    (let* ((bufs (image-diredx--associated-dired-buffers))
           (items (cl-loop for b in bufs
                           if (buffer-live-p b)
                           append (with-current-buffer b
                                    (cl-loop for f in (dired-get-marked-files)
                                             collect (list f b))))))
      (let ((inhibit-read-only t))
        (erase-buffer))
      (image-diredx--invoke-process items (current-buffer)))))

(defun image-diredx--associated-dired-buffers ()
  (save-excursion
    (goto-char (point-min))
    (let (res)
      (condition-case nil
          (while t
            (let ((buf (image-dired-associated-dired-buffer)))
              (unless (or (null buf) (memq buf res))
                (setq res (cons buf res))))
            (image-diredx--quiet-forward))
        (error nil))
      (nreverse res))))

(defun image-diredx-flagged-delete ()
  "Execute flagged deletion with thumbnails confirmation, like `dired' buffer."
  (interactive)
  (let ((flagged
         (cl-loop for buf in (image-diredx--associated-dired-buffers)
                  append (with-current-buffer buf
                           (let* ((dired-marker-char dired-del-marker)
                                  (files (dired-get-marked-files nil nil nil t)))
                             (cond
                              ;; selected NO file point of cursor filename
                              ((= (length files) 1)
                               nil)
                              ((eq (car files) t)
                               (cdr files))
                              (t files)))))))
    (cond
     ((null flagged)
      (message "(No deletions requested)"))
     ((not (image-diredx--confirm flagged))
      (message "(No deletions performed)"))
     (t
      (cl-loop with count = 0
               with failures = '()
               for f in flagged
               do (condition-case err
                      (progn
                        (dired-delete-file f)
                        (cl-incf count)
                        (image-diredx--delete-entry f)
                        (dired-fun-in-all-buffers
                         (file-name-directory f) (file-name-nondirectory f)
                         (function dired-delete-entry) f))
                    (error
                     (dired-log "%s\n" err)
                     (setq failures (cons f failures))))
               finally (if (not failures)
                           (message "%d deletion%s done"
                                    count (dired-plural-s count))
                         (dired-log-summary
                          (format "%d of %d deletion%s failed"
                                  (length failures) count
                                  (dired-plural-s count))
                          failures)))
      (image-diredx--redisplay-list-with-point)))))

(defun image-diredx--confirm (files)
  (let ((thumbs (cl-loop for f in files
                         collect
                         (let ((thumb (image-dired-thumb-name f)))
                           (unless (file-exists-p thumb)
                             ;;TODO or insert only string?
                             (error "Thumbnail has not been created for %s" f))
                           thumb))))
    ;; FIXME:
    ;; Show prompt buffer multiple times if exceed frame size.
    ;; This behavior same as dired.
    (with-current-buffer (get-buffer-create " *Deletions*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        ;; show all image as much as possible.
        (setq truncate-lines nil)
        (cl-loop for thumb in thumbs
                 do (insert-image (create-image
                                   thumb nil nil
                                   :relief image-dired-thumb-relief
                                   :margin image-dired-thumb-margin))))
      (save-window-excursion
        (image-diredx--pop-buffer (current-buffer))
        (funcall dired-deletion-confirmer "Delete image? ")))))

;; Copy from dired.el which obsoleted `dired-pop-to-buffer'
(defun image-diredx--pop-buffer (buf)
  (let ((split-window-preferred-function
	 (lambda (window)
	   (or (and (fboundp 'split-window-below)
                    (let ((split-height-threshold 0))
		      (window-splittable-p (selected-window)))
		    ;; Try to split the selected window vertically if
		    ;; that's possible.
		    (split-window-below))
	       ;; Otherwise, try to split WINDOW sensibly.
	       (split-window-sensibly window))))
	pop-up-frames)
    (pop-to-buffer (get-buffer-create buf)))
  (set-window-start nil (point-min))
  ;; Try to not delete window when we want to display less than
  ;; `window-min-height' lines.
  (fit-window-to-buffer (get-buffer-window buf) nil 1))

(defun image-diredx--delete-entry (file)
  (save-excursion
    (and (image-diredx--goto-file file)
         (let* ((cursor (point))
                (start (previous-single-property-change cursor 'display))
                (end (next-single-property-change cursor 'display))
                (inhibit-read-only t))
           (delete-region start end)))))

(defun image-diredx--adjust-window-size ()
  ;; prepare full-sized image window
  (image-dired-create-display-image-buffer)
  (unless (get-buffer-window image-dired-display-image-buffer)
    (let* ((thumb-h (+ (/ image-dired-thumb-height (frame-char-height)) 2))
           (t-win (split-window nil (- (window-text-height) thumb-h)))
           (i-win (selected-window)))
      (set-window-buffer i-win image-dired-display-image-buffer)
      (select-window t-win))))

(defun image-diredx--display-thumbs (&optional append do-not-pop)
  "Like `image-dired-display-thumbs' but asynchronously display thumbnails
of marked files.
"
  (let* ((buf (image-dired-create-thumbnail-buffer))
         (dir (dired-current-directory))
         (dired-buf (current-buffer))
         (items (cl-loop for f in (dired-get-marked-files)
                         collect (list f dired-buf))))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (unless append
          (erase-buffer)))
      (cd dir)
      (image-diredx--invoke-process items buf))
    (if do-not-pop
        (display-buffer image-dired-thumbnail-buffer)
      (pop-to-buffer image-dired-thumbnail-buffer))))

(defadvice image-dired-display-thumbs
  (around image-diredx-display-thumbs
          (&optional arg append do-not-pop) disable)
  ;; arg non-nil means retrieving single file.
  (if arg
      (setq ad-return-value ad-do-it)
    (setq ad-return-value
          (image-diredx--display-thumbs append do-not-pop))))

(defadvice image-dired-display-thumbnail-original-image
  (before image-diredx-adjusted-window (&optional arg) disable)
  (image-diredx--adjust-window-size))

;;;###autoload
(defun imagex-dired-show-image-thumbnails (buffer files &optional append)
  "Utility to insert thumbnail of FILES to BUFFER.
That thumbnails are not associated to any dired buffer although."
  (let ((items (mapcar
                ;; 'cadr must be a dired buffer that contains `x'
                (lambda (x) (list x nil))
                files)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (unless append
          (erase-buffer)))
      (image-diredx--invoke-process items buffer))))

;;;###autoload
(defun image-diredx-setup ()
  "Setup image-dired extensions."
  ;; original synchronous implementation is not considered
  ;; revert the thumbnails buffer.
  (set (make-local-variable 'revert-buffer-function)
       'image-diredx--thumb-revert-buffer)
  ;; for old version image-dired (bug?)
  ;; keep cursor at point
  (add-hook 'window-size-change-functions
            'image-diredx--redisplay-window-function nil t))

;; for compatibility
(defalias 'image-diredx--setup 'image-diredx-setup)

;;;###autoload
(define-minor-mode image-diredx-adjust-mode
  "Extension for `image-dired' show image as long as adjusting to frame."
  :global t
  :group 'image-dired+
  (funcall (if image-diredx-adjust-mode
               'ad-enable-advice
             'ad-disable-advice)
           'image-dired-display-thumbnail-original-image 'before
           'image-diredx-adjusted-window)
  (ad-activate 'image-dired-display-thumbnail-original-image))

;;;###autoload
(define-minor-mode image-diredx-async-mode
  "Extension for `image-dired' asynchrounous image thumbnail."
  :global t
  :group 'image-dired+
  (funcall (if image-diredx-async-mode
               'ad-enable-advice
             'ad-disable-advice)
           'image-dired-display-thumbs 'around
           'image-diredx-display-thumbs)
  (ad-activate 'image-dired-display-thumbs))

;;;
;;; activate/deactivate marmalade install or github install.
;;;

;; For `unload-feature'
(defun image-dired+-unload-function ()
  (image-diredx-async-mode -1)
  (image-diredx-adjust-mode -1)
  (remove-hook 'image-dired-thumbnail-mode-hook 'image-diredx-setup)
  ;; explicitly return nil to continue `unload-feature'
  nil)



;; activate main feature when elpa is activated.
;; Do not activate it when loading to follow the
;; `D.1 Emacs Lisp Coding Conventions`

;; setup key or any feature for buffer locally.
;;;###autoload(add-hook 'image-dired-thumbnail-mode-hook 'image-diredx-setup)

;; asynchronous display of images. This is main feature of this package.
;;;###autoload(image-diredx-async-mode 1)

(provide 'image-dired+)

;;; image-dired+.el ends here
