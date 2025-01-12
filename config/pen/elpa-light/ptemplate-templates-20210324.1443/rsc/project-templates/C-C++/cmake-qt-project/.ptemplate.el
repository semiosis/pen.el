;;; .ptemplate.el --- Qt CMake project .ptemplate -*- lexical-binding: t :+.

;;; Commentary:

;; C/C++ Qt CMake project template.

;;; Code:

(require 'ptemplate)
(require 'ptemplate-templates)

(ptemplate!
  :snippet-let (ptemplate-var-pname (ptemplate-templates--project-name))
  :open "src/main.cpp" "src/gui/Application.hpp")

;;; .ptemplate.el ends here
