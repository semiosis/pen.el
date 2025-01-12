;;; csv-mode-tests.el --- Tests for CSV mode         -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2022 Free Software Foundation, Inc

;; Author: Simen Heggestøyl <simenheg@runbox.com>
;; Keywords:

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

;;

;;; Code:

(require 'ert)
(require 'csv-mode)
(eval-when-compile (require 'subr-x))

(ert-deftest csv-tests-end-of-field ()
  (with-temp-buffer
    (csv-mode)
    (insert "aaa,bbb")
    (goto-char (point-min))
    (csv-end-of-field)
    (should (equal (buffer-substring (point-min) (point)) "aaa"))
    (forward-char)
    (csv-end-of-field)
    (should (equal (buffer-substring (point-min) (point))
                   "aaa,bbb"))))

(ert-deftest csv-tests-end-of-field-with-quotes ()
  (with-temp-buffer
    (csv-mode)
    (insert "aaa,\"b,b\"")
    (goto-char (point-min))
    (csv-end-of-field)
    (should (equal (buffer-substring (point-min) (point)) "aaa"))
    (forward-char)
    (csv-end-of-field)
    (should (equal (buffer-substring (point-min) (point))
                   "aaa,\"b,b\""))))

(ert-deftest csv-tests-beginning-of-field ()
  (with-temp-buffer
    (csv-mode)
    (insert "aaa,bbb")
    (csv-beginning-of-field)
    (should (equal (buffer-substring (point) (point-max)) "bbb"))
    (backward-char)
    (csv-beginning-of-field)
    (should (equal (buffer-substring (point) (point-max))
                   "aaa,bbb"))))

(ert-deftest csv-tests-beginning-of-field-with-quotes ()
  (with-temp-buffer
    (csv-mode)
    (insert "aaa,\"b,b\"")
    (csv-beginning-of-field)
    (should (equal (buffer-substring (point) (point-max)) "\"b,b\""))
    (backward-char)
    (csv-beginning-of-field)
    (should (equal (buffer-substring (point) (point-max))
                   "aaa,\"b,b\""))))

(defun csv-tests--align-fields (before after)
  (with-temp-buffer
    (insert (string-join before "\n"))
    (csv-align-fields t (point-min) (point-max))
    (should (equal (buffer-string) (string-join after "\n")))))

(ert-deftest csv-tests-align-fields ()
  (csv-tests--align-fields
   '("aaa,bbb,ccc"
     "1,2,3")
   '("aaa, bbb, ccc"
     "1  , 2  , 3")))

(ert-deftest csv-tests-align-fields-with-quotes ()
  (csv-tests--align-fields
   '("aaa,\"b,b\",ccc"
     "1,2,3")
   '("aaa, \"b,b\", ccc"
     "1  , 2    , 3")))

;; Bug#14053
(ert-deftest csv-tests-align-fields-double-quote-comma ()
  (csv-tests--align-fields
   '("1,2,3"
     "a,\"b\"\"c,\",d")
   '("1, 2      , 3"
     "a, \"b\"\"c,\", d")))

(defvar csv-tests--data
  "1,4;Sun, 2022-04-10;4,12
8;Mon, 2022-04-11;3,19
3,2;Tue, 2022-04-12;1,00
2;Wed, 2022-04-13;0,37
9;Wed, 2022-04-13;0,37")

(ert-deftest csv-tests-guess-separator ()
  (should-not (csv-guess-separator ""))
  (should (= (csv-guess-separator csv-tests--data 3) ?,))
  (should (= (csv-guess-separator csv-tests--data) ?\;))
  (should (= (csv-guess-separator csv-tests--data)
             (csv-guess-separator csv-tests--data
                                  (length csv-tests--data)))))

(ert-deftest csv-tests-separator-candidates ()
  (should-not (csv--separator-candidates ""))
  (should-not (csv--separator-candidates csv-tests--data 0))
  (should
   (equal (sort (csv--separator-candidates csv-tests--data 4) #'<)
          '(?, ?\;)))
  (should
   (equal (sort (csv--separator-candidates csv-tests--data) #'<)
          '(?\s ?, ?- ?\;)))
  (should
   (equal
    (sort (csv--separator-candidates csv-tests--data) #'<)
    (sort (csv--separator-candidates csv-tests--data
                                     (length csv-tests--data))
          #'<))))

(ert-deftest csv-tests-separator-score ()
  (should (< (csv--separator-score ?, csv-tests--data)
             (csv--separator-score ?\s csv-tests--data)
             (csv--separator-score ?- csv-tests--data)))
  (should (= (csv--separator-score ?- csv-tests--data)
             (csv--separator-score ?\; csv-tests--data)))
  (should (= 0 (csv--separator-score ?\; csv-tests--data 0)))
  (should (= (csv--separator-score ?\; csv-tests--data)
             (csv--separator-score ?\; csv-tests--data
                                   (length csv-tests--data)))))

(provide 'csv-mode-tests)
;;; csv-mode-tests.el ends here
