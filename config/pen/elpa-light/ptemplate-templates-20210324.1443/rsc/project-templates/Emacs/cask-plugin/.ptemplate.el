;;; .ptemplate.el --- Emacs plugin leveraging Cask -*- lexical-binding: t -+-

;;; Commentary:

;; This template generates an Emacs plugin project leveraging Cask.

;;; Code:

(require 'ptemplate)

(ptemplate!
  :ignore "/README.md"
  :inherit-rel "../plugin/")

;;; .ptemplate.el ends here
