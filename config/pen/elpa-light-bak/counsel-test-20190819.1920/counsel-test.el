;;; counsel-test.el --- Browse and execute tests with ivy -*- lexical-binding: t -*-

;; Copyright (c) 2019 Konstantin Sorokin (GNU/GPL Licence)

;; Authors: Konstantin Sorokin <sorokin.kc@gmail.com>
;; URL: http://github.com/xmagpie/counsel-test
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.1") (ivy "0.11.0") (s "1.12.0"))
;; Keywords: tools, ivy, counsel, testing, ctest, pytest

;; This file is NOT part of GNU Emacs.

;; counsel-test is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; counsel-test is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with counsel-test.el.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;; This package is a small framework for integrating counsel with
;;; different testing frameworks.  By using it one can browse, select and
;;; execute tests from concrete framework with the power of counsel and ivy.

;;; Code:
(require 'counsel-test-ctest)
(require 'counsel-test-pytest)

(provide 'counsel-test)
;;; counsel-test.el ends here
