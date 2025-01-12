;;; .ptemplate.el --- C/C++ Meson project .ptemplate -*- lexical-binding: t -*-

;;; Commentary:

;; C/C++ (prompted) meson project template.

;;; Code:

(require 'ptemplate)
(require 'ptemplate-templates)          ; utils needed by snippets

(ptemplate!
  :ignore "\\.gitkeep" "/README.md"
  :snippet-let
  (ptemplate-var-language
   (completing-read "Select a language: " '("c" "cpp") nil t))
  (ptemplate-var-main-file (format "src/main.%s" ptemplate-var-language))
  (ptemplate-var-pname (ptemplate-templates--project-name))
  :remap ("/src/main.c.yas" ptemplate-var-main-file)
  :nokill ptemplate-var-main-file)

;;; .ptemplate.el ends here
