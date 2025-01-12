;;; el-secretario-source.el --- The base class for sources -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Leo
;;
;; Author: Leo Okawa Ericson <http://github/Zetagon>
;; Maintainer: Leo <github@relevant-information.com>
;; Created: June 07, 2021
;; Modified: June 07, 2021
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
;;  This file contains the base source class.  The doc strings of each method
;;  describes what a source needs to implement.
;;
;;; Code:
(require 'eieio)
(require 'eieio-base)
(require 'hercules)

(defvar el-secretario-source-default-map (let ((km (make-sparse-keymap)))
                       (define-key km
                         "n" '("next" . el-secretario-next-item))
                       (define-key km
                         "p"  '("previous" . el-secretario-previous-item))
                       km)
  "The default hercules-style keymap for sources.")

(defclass el-secretario-source (eieio-named)
  ((keymap :initarg :keymap
           :initform 'el-secretario-source-default-map
           :protection :protected)
   (is-initialized :initform nil))
  :abstract t
  :documentation
  "Base class for sources. All sources should inherit from this
one.

It makes sure that the invariant \"A source is initialized (via
the `el-secretario-source-init') only once\" is kept.


")

;;; User methods
;; Each new source should implement these methods

(cl-defmethod el-secretario-source-init :after ((obj el-secretario-source) &optional _backwards)
  "Set the `is-initialized' flag after a source has been initialized."
  (with-slots (is-initialized) obj
    (setq is-initialized t)))

(cl-defmethod el-secretario-source-init :around ((obj el-secretario-source) &optional backwards)
  "Make sure that a source is only initialized once. If a source
is already initialized and this method is called, call `el-secretario-source-activate' instead."
  (if (el-secretario--source-initialized-p obj)
      (el-secretario-source-activate obj backwards)
    (cl-call-next-method)))

(cl-defmethod el-secretario-source-init ((obj el-secretario-source) &optional backwards)
  "Initialize source OBJ.

This method is called only once, the first time source OBJ is
activated.  Subsequent calls will redirect to
`el-secretario-source-activate'.

Implement this method if you need to setup state etc. for your
source that only needs to happen once.  The default
behavior (i.e. if your source doesn't implement this method) is
to call `el-secretario-source-activate'.

It should also do whatever is needed to bring up the relevant item to the user.

If BACKWARDS is t initialize the source in the reverse order.
This most likely means that the user has called
`el-secretario-previous-item' and is expecting the last item of
the source to be shown."
  (el-secretario-source-activate obj backwards))

(cl-defmethod el-secretario-source-cleanup ((obj el-secretario-source))
  "Do cleanup required by OBJ.

This method is called every time `el-secretario--next-source' is
called, i.e. when the source is changed away from OBJ.")

(cl-defmethod el-secretario-source-next-item ((_obj el-secretario-source))
  "Go to the next item of source OBJ.

It should call `el-secretario--next-source' if there are no more items.

Example:
 For the notmuch module, this method goes to the next email."
  (display-warning 'el-secretario "This source doesn't implement the next-item method!"))

(cl-defmethod el-secretario-source-previous-item ((_obj el-secretario-source))
  "Go to the previous item of source OBJ.

It should call `el-secretario--previous-source' if there are no more items."
  (display-warning 'el-secretario "This source doesn't implement the previous-item method!"))

(cl-defmethod el-secretario-source-activate ((_obj el-secretario-source) &optional _backwards)
  "Activate source OBJ.

This method is called when el-secretario switches to source
OBJ (for example when the user calls `el-secretario-next-item'
with no items left, so el-secretario switches to source OBJ).

For example, the org module implements this method to bring up
the correct org buffer, and go to the correct heading.

If BACKWARDS is t initialize the source in the reverse order.
This most likely means that the user has called
`el-secretario-previous-item' and is expecting the last item of
the source to be shown."
  (display-warning 'el-secretario "This source doesn't implement the activate method"))

;;; Utility methods
;; Subclasses don't need to implement these

(cl-defmethod el-secretario--source-keymap-activate ((obj el-secretario-source))
  "Activate keymap of OBJ."
  (hercules--show (oref obj keymap)
                  t t))
(cl-defmethod el-secretario--source-initialized-p ((obj el-secretario-source))
  "Return t if OBJ is initialized."
  (oref obj is-initialized))
(provide 'el-secretario-source)
;;; el-secretario-source.el ends here

;; Local Variables:
;; package-lint-main-file: "el-secretario.el"
;; End:
