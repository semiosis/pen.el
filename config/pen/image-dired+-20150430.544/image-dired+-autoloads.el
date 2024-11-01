;;; image-dired+-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "image-dired+" "image-dired+.el" (0 0 0 0))
;;; Generated autoloads from image-dired+.el

(autoload 'imagex-dired-show-image-thumbnails "image-dired+" "\
Utility to insert thumbnail of FILES to BUFFER.
That thumbnails are not associated to any dired buffer although.

\(fn BUFFER FILES &optional APPEND)" nil nil)

(autoload 'image-diredx-setup "image-dired+" "\
Setup image-dired extensions." nil nil)

(defvar image-diredx-adjust-mode nil "\
Non-nil if Image-Diredx-Adjust mode is enabled.
See the `image-diredx-adjust-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `image-diredx-adjust-mode'.")

(custom-autoload 'image-diredx-adjust-mode "image-dired+" nil)

(autoload 'image-diredx-adjust-mode "image-dired+" "\
Extension for `image-dired' show image as long as adjusting to frame.

If called interactively, enable Image-Diredx-Adjust mode if ARG
is positive, and disable it if ARG is zero or negative.  If
called from Lisp,  also enable the mode if ARG is omitted or nil,
and toggle it if ARG is `toggle'; disable the mode otherwise.

\(fn &optional ARG)" t nil)

(defvar image-diredx-async-mode nil "\
Non-nil if Image-Diredx-Async mode is enabled.
See the `image-diredx-async-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `image-diredx-async-mode'.")

(custom-autoload 'image-diredx-async-mode "image-dired+" nil)

(autoload 'image-diredx-async-mode "image-dired+" "\
Extension for `image-dired' asynchrounous image thumbnail.

If called interactively, enable Image-Diredx-Async mode if ARG is
positive, and disable it if ARG is zero or negative.  If called
from Lisp,  also enable the mode if ARG is omitted or nil, and
toggle it if ARG is `toggle'; disable the mode otherwise.

\(fn &optional ARG)" t nil)
(add-hook 'image-dired-thumbnail-mode-hook 'image-diredx-setup)
(image-diredx-async-mode 1)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "image-dired+" '("image-dired")))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; image-dired+-autoloads.el ends here
