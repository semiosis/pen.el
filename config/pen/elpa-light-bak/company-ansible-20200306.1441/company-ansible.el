;;; company-ansible.el --- A company back-end for ansible

;; Copyright (c) 2015-2020 Krzysztof Magosa

;; Author: Krzysztof Magosa <krzysztof@magosa.pl>
;; URL: https://github.com/krzysztof-magosa/company-ansible
;; Package-Requires: ((emacs "24.4") (company "0.8.12"))
;; Created: 31 August 2015
;; Version: 0.8.0
;; Keywords: ansible

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;

;;; Code:

(require 'company)
(require 'cl-lib)
(require 'company-ansible-keywords)

;;;###autoload
(defun company-ansible (command &optional arg &rest ignored)
  "Company backend for ansible yaml files."
  (interactive (list 'interactive))

  (cl-case command
    (interactive (company-begin-backend 'company-ansible))
    (prefix (and (bound-and-true-p ansible)
                 (company-grab-symbol)))

    (candidates
     (cl-remove-if-not
      (lambda (c) (string-prefix-p arg c))
      company-ansible-keywords))))

(provide 'company-ansible)
;;; company-ansible.el ends here
