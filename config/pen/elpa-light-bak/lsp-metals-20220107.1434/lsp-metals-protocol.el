;;; lsp-metals-protocol.el --- LSP Metals custom protocol definitions -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Evgeny Kurnevsky <kurnevsky@gmail.com>

;; Version: 1.0.0
;; Package-Requires: ((emacs "26.1") (lsp-mode "7.0"))
;; Author: Evgeny Kurnevsky <kurnevsky@gmail.com>
;; Keywords: languages, extensions
;; URL: https://github.com/emacs-lsp/lsp-metals

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; lsp-metals custom protocol definitions

;;; Code:

(require 'lsp-protocol)

(lsp-interface
  (PublishDecorationsParams (:uri :options) nil)
  (MetalsStatusParams (:text) (:show :hide :tooltip :command))
  (DecorationOptions (:range :renderOptions) (:hoverMessage))
  (ThemableDecorationInstanceRenderOption nil (:after))
  (ThemableDecorationAttachmentRenderOptions nil (:contentText :color :fontStyle))
  (DebugSession (:name :uri) nil)
  (TreeViewNode (:viewId :label) (:nodeUri :command :icon :tooltip :collapseState))
  (TreeViewCommand (:title :command) (:tooltip :arguments))
  (TreeViewChildrenResult (:nodes) nil)
  (TreeViewDidChangeParams (:nodes) nil)
  (TreeViewRevealResult (:viewId :uriChain) nil))

(provide 'lsp-metals-protocol)
;;; lsp-metals-protocol.el ends here
