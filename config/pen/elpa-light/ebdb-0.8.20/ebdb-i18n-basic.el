;;; ebdb-i18n-basic.el --- Basic internationalization methods for EBDB  -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2023  Free Software Foundation, Inc.

;; Author: Eric Abrahamsen <eric@ericabrahamsen.net>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides internationalized methods for a few common
;; countries, "common" here meaning what used to be in
;; `ebdb-address-format-list'.

;;; Code:

(eval-when-compile
  ;; For `with-slots'.
  (require 'eieio))

(declare-function ebdb-i18n-countries "ebdb-i18n")
(declare-function ebdb-with-exit "ebdb")
(declare-function ebdb-address-region "ebdb")
(declare-function ebdb-read-string "ebdb")

;;; USA

(defvar ebdb-i18n-usa-states
  '(("Alabama" . "AL")
    ("Alaska" . "AK")
    ("American Samoa " . "AS")
    ("Arizona" . "AZ")
    ("Arkansas" . "AR")
    ("California" . "CA")
    ("Colorado" . "CO")
    ("Connecticut" . "CT")
    ("Delaware" . "DE")
    ("Dist. of Columbia" . "DC")
    ("Florida" . "FL")
    ("Georgia" . "GA")
    ("Guam" . "GU")
    ("Hawaii" . "HI")
    ("Idaho" . "ID")
    ("Illinois" . "IL")
    ("Indiana" . "IN")
    ("Iowa" . "IA")
    ("Kansas" . "KS")
    ("Kentucky" . "KY")
    ("Louisiana" . "LA")
    ("Maine" . "ME")
    ("Maryland" . "MD")
    ("Marshall Islands" . "MH")
    ("Massachusetts" . "MA")
    ("Michigan" . "MI")
    ("Micronesia" . "FM")
    ("Minnesota" . "MN")
    ("Mississippi" . "MS")
    ("Missouri" . "MO")
    ("Montana" . "MT")
    ("Nebraska" . "NE")
    ("Nevada" . "NV")
    ("New Hampshire" . "NH")
    ("New Jersey" . "NJ")
    ("New Mexico" . "NM")
    ("New York" . "NY")
    ("North Carolina" . "NC")
    ("North Dakota" . "ND")
    ("Northern Marianas" . "MP")
    ("Ohio" . "OH")
    ("Oklahoma" . "OK")
    ("Oregon" . "OR")
    ("Palau" . "PW")
    ("Pennsylvania" . "PA")
    ("Puerto Rico" . "PR")
    ("Rhode Island" . "RI")
    ("South Carolina" . "SC")
    ("South Dakota" . "SD")
    ("Tennessee" . "TN")
    ("Texas" . "TX")
    ("Utah" . "UT")
    ("Vermont" . "VT")
    ("Virginia" . "VA")
    ("Virgin Islands" . "VI")
    ("Washington" . "WA")
    ("West Virginia" . "WV")
    ("Wisconsin" . "WI")
    ("Wyoming" . "WY"))
  "All the states in the US, for use with completion.")

(cl-defmethod ebdb-parse-i18n ((_class (subclass ebdb-field-phone))
			       (str string)
			       (_cc (eql 1))
			       &optional slots)
  "Parse a US phone number.
Uses first three digits as the area code, next seven as the
number, and any remaining as an extension."
  (let ((numstr (replace-regexp-in-string "[^[:digit:]]+" "" str)))
    (unless (plist-get slots :area-code)
      (setq slots
	    (plist-put slots :area-code
		       (string-to-number (substring numstr 0 3)))
	    numstr (substring numstr 3)))
    (setq slots (plist-put slots :number (substring numstr 0 7))
	  numstr (substring numstr 7))
    (condition-case nil
	(setq slots (plist-put
		     slots
		     :extension
		     (when (and (null (string-empty-p numstr))
				(string-match-p "[[:digit:]]+" numstr))
		       (string-to-number numstr))))
      (args-out-of-range nil))
    slots))

;; Defined in `ebdb.el'
(defvar ebdb-default-phone-country)

(cl-defmethod ebdb-string-i18n ((phone ebdb-field-phone)
				(_cc (eql 1)))
  (with-slots (area-code number extension) phone
    (format "%s(%d) %s-%s%s"
	    (if (eql ebdb-default-phone-country 1)
		"" "+1 ")
	    area-code
	    (substring number 0 3)
	    (substring number 3)
	    (if extension (format "X%d" extension) ""))))

(cl-defmethod ebdb-read-i18n ((_class (subclass ebdb-field-address))
			      (_cc (eql usa))
			      &optional slots obj)
  (unless (plist-member slots :region)
    (setq slots
	  (plist-put
	   slots :region
	   (cdr (assoc-string
		 (ebdb-read-string
		  "Address state"
		  (when obj (rassoc (ebdb-address-region obj)
				    ebdb-i18n-usa-states))
		  ebdb-i18n-usa-states t)
		 ebdb-i18n-usa-states)))))
  slots)

(cl-defmethod ebdb-parse-i18n ((_class (subclass ebdb-field-address))
			       (str string)
			       (_cc (eql usa))
			       &optional slots)
  (let ((states (mapcar #'cdr ebdb-i18n-usa-states)))
    (unless (plist-member slots :country)
      (setq slots (plist-put slots :country 'usa)))
    (with-temp-buffer
      (insert str)
      (when (re-search-backward "[[:digit:]]\\{5\\}\\(?:-[[:digit:]]\\{4\\}\\)?"
				nil t)
	(setq slots (plist-put slots :postcode (match-string 0))))
      (when (re-search-backward (concat "\\(" (regexp-opt states) "\\)[ ,]+")
				(line-beginning-position) t)
	(setq slots (plist-put slots :region (match-string 1))))
      (when (re-search-backward "\\(?:^\\|, \\)\\([[:alpha:].-]+ ?[[:alpha:].-]+\\)[ ,]+"
				(line-beginning-position) t)
	(setq slots (plist-put slots :locality (match-string 1))))
      (setq slots (plist-put slots :streets
			     (split-string (buffer-substring (point-min) (point))
					   "[,\n]" t "[[:blank:]]"))))
    slots))

;;; France

(cl-defmethod ebdb-string-i18n ((phone ebdb-field-phone)
                                (_cc (eql 33)))
  (with-slots (area-code number extension) phone
    (concat
     (unless (eql ebdb-default-phone-country 33)
      "+33 ")
     (when area-code
       (format "%02d" area-code))
     (apply #'format "%s%s %s%s %s%s %s%s"
            (split-string number "" t))
     (when extension
       (format "X%d" extension)))))

;;; Germany

(cl-defmethod ebdb-string-i18n ((phone ebdb-field-phone)
                                (_cc (eql 49)))
  "Display a German phone number."
  (let ((is-default (eql ebdb-default-phone-country 49))
	num-len)
    (with-slots (area-code number extension) phone
      (setq num-len (length number))
      (concat
       (unless is-default
	 "+49 ")
       (when area-code
	 (format (if is-default "(%03d) " "%d ") area-code))
       (if (>= 4 num-len)
	   number
	 (mapconcat #'identity
		    (seq-partition number
				   (if (= 0 (mod num-len 3))
				       3 4))
	  " "))
       (when extension
	 (format "-%d" extension))))))

(cl-defmethod ebdb-parse-i18n ((_class (subclass ebdb-field-phone))
			       (str string)
			       (_cc (eql 49))
			       &optional slots)
  "Parse a German phone number.
Uses first block of digits as the area code, anything following a
hyphen as the extension, and everything in between as the number
itself."
  (let ((area-code-regexp "^(?\\([[:digit:]]+\\))? +")
	(extension-regexp "-\\([[:digit:]]+\\)\\'"))
    (setq slots
	  (plist-put slots :area-code
		     (when (string-match area-code-regexp str)
		       (prog1
			   (string-to-number (match-string 1 str))
			 (setq str (replace-regexp-in-string
				    area-code-regexp "" str)))))
	  slots
	  (plist-put slots :extension
		     (when (string-match extension-regexp str)
		       (prog1
			   (string-to-number (match-string 1 str))
			 (setq str (replace-regexp-in-string
				    extension-regexp "" str))))))

    (setq slots (plist-put
		 slots
		 :number
		 (replace-regexp-in-string
		  "[^[:digit:]]" "" str)))
    slots))

(defvar ebdb-i18n-german-states
 '(("Baden-Württemberg" . "BW")
   ("Bayern" . "BY")
   ("Berlin" . "BE")
   ("Brandenburg" . "BB")
   ("Bremen" . "HB")
   ("Hamburg" . "HH")
   ("Hessen" . "HE")
   ("Mecklenburg-Vorpommern" . "MV")
   ("Niedersachsen" . "NI")
   ("Nordrhein-Westfalen" . "NW")
   ("Rheinland-Pfalz" . "RP")
   ("Saarland" . "SL")
   ("Sachsen" . "SN")
   ("Sachsen-Anhalt" . "ST")
   ("Schleswig-Holstein" . "SH")
   ("Thüringen" . "TH"))
 "All the states in Germany, for use with completion.")

(cl-defmethod ebdb-read-i18n ((_class (subclass ebdb-field-address))
			      (_cc (eql deu))
			      &optional slots obj)
  (unless (plist-member slots :region)
    (let ((state (ebdb-with-exit
		  (ebdb-read-string
		   "State"
		   (when obj (ebdb-address-region obj))
		   ebdb-i18n-german-states t))))
      (setq slots
	    (plist-put
	     slots :region
	     (if state
		 (cdr (assoc-string state ebdb-i18n-german-states))
	       "")))))
  slots)

(cl-defmethod ebdb-string-i18n ((address ebdb-field-address)
                                (_cc (eql deu)))
  (with-slots (streets neighborhood locality region postcode) address
    (concat
     (when streets
       (concat (mapconcat #'identity streets "\n") "\n"))
     (when postcode
       (format "%s " postcode))
     locality
     "\n"
     (car-safe (rassq 'deu (ebdb-i18n-countries))))))

;;; India

(defvar ebdb-i18n-india-states
  '("Andhra Pradesh"
   "Arunachal Pradesh"
   "Assam"
   "Bihar"
   "Chhattisgarh"
   "Goa"
   "Gujarat"
   "Haryana"
   "Himachal Pradesh"
   "Jammu and Kashmir"
   "Jharkhand"
   "Karnataka"
   "Kerala"
   "Madhya Pradesh"
   "Maharashtra"
   "Manipur"
   "Meghalaya"
   "Mizoram"
   "Nagaland"
   "Odisha"
   "Punjab"
   "Rajasthan"
   "Sikkim"
   "Tamil Nadu"
   "Telangana"
   "Tripura"
   "Uttar Pradesh"
   "Uttarakhand"
   "West Bengal")
  "A list of states in India, for completion.")

(cl-defmethod ebdb-read-i18n ((_class (subclass ebdb-field-address))
			      (_cc (eql ind))
			      &optional slots obj)
  (unless (plist-member slots :region)
    (setq slots
	  (plist-put
	   slots :region
	   (cdr (assoc-string
		 (ebdb-read-string
		  "State"
		  (when obj (ebdb-address-region obj))
		  ebdb-i18n-india-states t)
		 ebdb-i18n-india-states)))))
  slots)

;;; Russia

(cl-defmethod ebdb-string-i18n ((phone ebdb-field-phone)
				(_cc (eql 8)))
  (with-slots (area-code number extension) phone
    (concat
     (unless (eql ebdb-default-phone-country 8)
      "+8 ")
     (when area-code (format "%d " area-code))
     (apply #'format
	    (cl-case (length number)
	      (5 "%s-%s%s-%s%s")
	      (6 "%s%s-%s%s-%s%s")
	      (7 "%s%s%s-%s%s-%s%s"))
	    (split-string number "" t))
     (when extension (format " X%s" extension)))))

;;; Singapore

(cl-defmethod ebdb-read-i18n ((_cls (subclass ebdb-field-address))
			      (_cc (eql sgp))
			      &optional slots _obj)
  "Singapore doesn't have localities, cities, or neighborhoods."
  (setq slots (plist-put slots :locality "")
	slots (plist-put slots :neighborhood "")
	slots (plist-put slots :region ""))
  slots)

(provide 'ebdb-i18n-basic)
;;; ebdb-i18n-basic.el ends here
