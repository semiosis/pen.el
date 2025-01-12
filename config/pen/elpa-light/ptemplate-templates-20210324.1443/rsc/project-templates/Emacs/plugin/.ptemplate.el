;;; .ptemplate.el --- Emacs plugin leveraging Cask -*- lexical-binding: t -+-

;;; Commentary:

;; This template generates an Emacs plugin project leveraging Cask.

;;; Code:

(require 'ptemplate)
(require 'ptemplate-templates)

(ptemplate!
  :ignore "/README.md"
  :snippet-let
  (ptemplate-var-pname (ptemplate-templates--project-name))
  (ptemplate-var-module (concat ptemplate-var-pname ".el"))
  :remap ("/src.el.yas" ptemplate-var-module)
  :nokill ptemplate-var-module)

;;; .ptemplate.el ends here
