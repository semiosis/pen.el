;;; mu4e-views.el --- View emails in mu4e using xwidget-webkit -*- lexical-binding: t -*-

;; Author: Boris Glavic <lordpretzel@gmail.com>
;; Maintainer: Boris Glavic <lordpretzel@gmail.com>
;; Version: 0.3
;; Package-Requires: ((emacs "26.1") (xwidgets-reuse "0.2") (ht "2.2") (esxml "20210323.1102"))
;; Homepage: https://github.com/lordpretzel/mu4e-views
;; Keywords: mail


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; `mu4e' is great, but viewing of html emails is suboptimal.  This packages
;; enables the user to choose how to view emails.  It's main use case is to view
;; emails using an xwidgets window, but the user provided viewing methods are
;; also supported.
;;
;; Also provides methods for user defined viewing methods to access content
;; extracted from an email, e.g., urls or attachments.  This makes it easier to
;; build new views.


;;; Code:

(require 'mu4e)

;; ********************************************************************************
;; helper functions for version testing
(defun mu4e-views-mu4e-ver-<= (v)
  "Check whether mu4e-version is less then or equal to V."
  (version-list-<= (version-to-list mu4e-mu-version) v))

(defun mu4e-views-mu4e-ver-< (v)
  "Check whether mu4e-version is less then or equal to V."
  (version-list-< (version-to-list mu4e-mu-version) v))

(defun mu4e-views-mu4e-ver-> (v)
  "Check whether mu4e-version is less then or equal to V."
  (not (version-list-<= (version-to-list mu4e-mu-version) v)))

(defun mu4e-views-mu4e-ver->= (v)
  "Check whether mu4e-version is less then or equal to V."
  (not (version-list-< (version-to-list mu4e-mu-version) v)))

(defun mu4e-views-mu4e-ver-between (low high)
  "Check whether mu4e-version is between LOW and HIGH."
  (and (mu4e-views-mu4e-ver->= low)
       (mu4e-views-mu4e-ver-<= high)))


;; INCLUDES
;;TODO also wrap mu4e text email viewing to get the customizable behaviour and reduction of window messing
(require 'seq)
(require 'dash)
;; for versions 1.5 to 1.6.x there are two view files, but from 1.7 on there is only one build-in view method
(when (mu4e-views-mu4e-ver-between '(1 5) '(1 6 100))
  (require 'mu4e-view-old)
  (require 'mu4e-view-gnus)
  (require 'mu4e-utils))
(when (mu4e-views-mu4e-ver->= '(1 7))
  (require 'mu4e-view)
  (require 'mu4e-message))
(when (mu4e-views-mu4e-ver-> '(1 8))
  (require 'url-file))
(require 'ht)
(require 'xwidgets-reuse)
;;(require 'cl-macs)
(require 'cl-lib)
(require 'thingatpt)
(require 'esxml)
(require 'dom)
(require 'gnus-art)



;; ********************************************************************************
;; Customize and defvars
(defcustom mu4e-views-view-commands
  `,(append ;; open with standard mu4e function
     (when (mu4e-views-mu4e-ver-< '(1 7))
       '(("text" . (:viewfunc mu4e-views-text-view-message
                              :create-view-window mu4e-views-text-create-view-window
                              :is-view-window-p mu4e-views-text-is-view-window-p
                              :view-function-only-msg t))))
     ;; open raw email in buffer
     `(("raw" . (:viewfunc mu4e-views-raw-view-message
                           :create-view-window ,(if (mu4e-views-mu4e-ver-< '(1 7))
                                                    #'mu4e-views-text-create-view-window
                                                  #'mu4e-views-gnus-create-view-window)
                           :is-view-window-p mu4e-views-raw-is-view-p))
       ;; open with xwidget
	   ("html" . (:viewfunc mu4e-views-xwidget-mu4e-view
                            :is-view-window-p mu4e-views-xwidget-is-view-window-p))
       ;; open with xwidget and force blocking of external content
       ("html-block" .
        (:viewfunc mu4e-views-xwidget-mu4e-view
                   :is-view-window-p mu4e-views-xwidget-is-view-window-p
                   :filter-html t))
       ;; open with xwidget and force loading of external content
       ("html-nonblock" .
        (:viewfunc mu4e-views-xwidget-mu4e-view
                   :is-view-window-p mu4e-views-xwidget-is-view-window-p
                   :filter-html nil))
       ;; open as pdf file
       ("pdf" . (:viewfunc mu4e-view-pdf-view-message
                           :is-view-window-p mu4e-views-pdf-is-view-window-p
                           :create-view-window
                           ,(if (mu4e-views-mu4e-ver-< '(1 7))
                                #'mu4e-views-text-create-view-window
                              #'mu4e-views-gnus-create-view-window)))
       ;; open as pdf file with remote content
       ("pdf-nonblock" . (:viewfunc mu4e-view-pdf-view-message
                                    :is-view-window-p mu4e-views-pdf-is-view-window-p
                                    :create-view-window
                                    ,(if (mu4e-views-mu4e-ver-< '(1 7))
                                         #'mu4e-views-text-create-view-window
                                       #'mu4e-views-gnus-create-view-window)
                                    :filter-html nil))
       ;; open as pdf file with remote content
       ("pdf-block" . (:viewfunc mu4e-view-pdf-view-message
                                 :is-view-window-p mu4e-views-pdf-is-view-window-p
                                 :create-view-window
                                 ,(if (mu4e-views-mu4e-ver-< '(1 7))
                                      #'mu4e-views-text-create-view-window
                                    #'mu4e-views-gnus-create-view-window)
                                 :filter-html t))
       ;; open with browser
	   ("browser" . (:viewfunc mu4e-views-view-in-browser
                               :no-view-window t))
       ;; open with browser do not block remote content
	   ("browser-nonblock" . (:viewfunc mu4e-views-view-in-browser
                                        :no-view-window t
                                        :filter-html nil))
       ;; open with gnus
       ("gnus" . (:viewfunc mu4e-views-gnus-view-message
                            :create-view-window mu4e-views-gnus-create-view-window
                            :is-view-window-p mu4e-views-gnus-is-view-window-p
                            :view-function-only-msg t))
       ;; show the messages html source code
       ("html-src" . (:viewfunc mu4e-views-html-src-view-message
                                :is-view-window-p mu4e-views-html-src-is-view-p))
       ;; dispatch to other view methods choosen based on predicates
       ("dispatcher" .
        (:viewfunc mu4e-views-dispatcher-view-message
                   :is-view-window-p mu4e-views-dispatcher-is-view-window-p
                   :view-function-only-msg t))))
  "A list of commands for viewing messages in mu4e.

Currently supported are:

- \"text\" - the standard `mu4e' text email view
- \"html\" - view email as HTML in xwidgets
- \"html-block\" - same as html but always block remote HTML content
- \"html-nonblock\" - same as html but never block remote HTML content
- \"pdf\" - view email as pdf with `mu4e-views-html-to-pdf-command'
- \"browser\" - view email as html in browser using `browse-url'
- \"gnus\" - use mu4e's build-in gnus article view
- \"html-src\" - show html source code of message
- \"dispatcher\" - dynamically chooses method per email

A viewing command ic a cons of a string (the methods name as
shown to the user), and a plist the defines the methods
behavior. The following keys are supported:

`:viewfunc' - this is function that does the actual work of
displaying a message. The signature is `(html msg
win)' (or `(msg)' if `:view-function-only-msg' is t) where `html'
is the name of a file storing the message as html, `msg' is a
mu4e message plist (see relevant `mu4e' code, and `win' is a
window in which the message should be displayed in.
`:view-function-only-msg' - if t, then the view function does
only take a single argument `msg' which is a mu4e message
plist. In this case `mu4e-views' will not write the message to an
html file.  `:create-view-window-function' - if called, this
function should create the mu4e message viewing window.
`:is-view-window-p' - if it is currently shown return the viewing
window, otherwise return nil.  `:no-view-window' - if t, then the
viewing method does not use a separate viewing window, e.g., it
may be using an external program like a browser to show the
method. In this case also `:is-view-window-p' does not have to be
provided.  Property `:filter-html' can be used to force
applying (non-nil) or force not-applying (nil) of filtering of
external content from emails.

The dispatcher method is special in that it dynamically chooes
the view method to apply per email, selecting the first view
method whose predicate in
`mu4e-views-dispatcher-predicate-view-map' evaluates to non-nil
if provided the `mu4e' email message as input."
  :group 'mu4e-views
  :type 'alist)

(defcustom mu4e-views-dispatcher-predicate-view-map
  `((,(lambda (msg) (mu4e-message-field msg :body-html)) . "html")
    (,(lambda (msg) (ignore msg) t) . ,(if (mu4e-views-mu4e-ver-< '(1 7))
                                           "text"
                                         "gnus")))
  "Alist of (predicate . view-method) pairs.
PREDICATE should be a predicate and view-method is a string which should be a
valid `mu4e-views' view method.  This is used by the dispatcher view method to
determine which view method to use for an email.  The predicates can refer to a
variable msg to access information about the email to be shown.  This is a
`mu4e' message plist."
  :group 'mu4e-views
  :type '(alist :key-type function :value-type string))

(defcustom mu4e-views-html-to-pdf-command
  "html-pdf %h %p"
  "Command to run to translate html files into pdf files.

Inside the string %h and %p will be replaced with the input html
file name and output PDF file name."
  :group 'mu4e-views
  :type 'string)

(defcustom mu4e-views-respect-mu4e-view-use-gnus
  nil
  "If t, then repect `mu4e-view-use-gnus' over the mu4e-views viewing method.
That is, if `mu4e-view-use-gnus' is t, then always use viewing method \"gnus\"."
  :group 'mu4e-views
  :type 'boolean)

(defcustom mu4e-views-default-view-method
  (cdr (assoc (if (mu4e-views-mu4e-ver-< '(1 7)) "text" "gnus") mu4e-views-view-commands))
  "Default method to use for viewing emails in mu4e."
  :group 'mu4e-views
  :type 'plist)

(defcustom mu4e-views-inject-email-information-into-html
  t
  "Show email headers (e.g., subject) in the html view.

If t then `mu4e-views' will inject email message headers information into the
email's html file for the email.  This is useful for viewing emails in
browsers and xwidgets."
  :group 'mu4e-views
  :type 'boolean)

(defcustom mu4e-views-auto-view-selected-message
  t
  "If t, then view follows header movements.

That is, if this it non-nil then selecting a message in the headers
view (moving) automatically shows that message in the view window
if it is open."
  :group 'mu4e-views
  :type 'boolean)

(defcustom mu4e-views-next-previous-message-behaviour
  'always-switch-to-headers
  "Behavior when moving to the next / previous message in the mu4e-headers view.

Default (`always-switch-to-headers') is to stay in the headers views.  Other
options are staying in the current view (`stick-to-current-window') or always
moving to the `mu4e-views' window (`always-switch-to-view')."
  :group 'mu4e-views
  :type '(radio (const :tag
                       "Always switch to mu4e-headers window which shows the list of emails"
                       always-switch-to-headers)
                (const :tag
                       "Always switch to mu4e-views view window which shows the current email"
                       always-switch-to-view)
                (const :tag
                       "Always stay in the current window"
                       stick-to-current-window)))

(defcustom mu4e-views-mu4e-html-email-header-style
  "<style type=\"text/css\">
.mu4e-mu4e-views-mail-headers { font-family: Courier New; font-size:10pt; border: solid 2px;  padding: 2px; background-color: #EEEEEE; }
.mu4e-mu4e-views-header-row { display:block; padding: 1px; }
.mu4e-mu4e-views-mail-header { font-family: Courier New; font-size:10pt; display: inline-block; font-weight: normal; color: #155327; background-color: #ECFFEC; border: 1px solid; border-color: #155327; padding: 1px;}
.mu4e-mu4e-views-header-content { font-family: Courier New; font-size:10pt; display: inline-block; font-weight: normal; color: black; padding-right: 6px; }
.mu4e-mu4e-views-email { font-family: Courier New; font-size:10pt; display: inline-block; padding-right: 8px; }
.mu4e-mu4e-views-attachment { font-family: Courier New; font-size:10pt; display: inline-block; padding-right: 8px; }
.mu4e-mu4e-views-mail-title { font-family: Courier New; font-size:14pt; font-weight: bold; display: inline-block; padding-right: 8px; width: 100%; text-align: center; }
</style>"
  "CSS style for displaying email header information in a mu4e-views email view."
  :group 'mu4e-views
  :type 'string)

(defcustom mu4e-views-completion-method
  'default
  "The completion framework to use when letting choosing an option from a list.

The default (`default') is to just use completing read.  Other
supported options are `ivy', `helm', and `ido'."
  :group 'mu4e-views
  :type '(radio (const :tag "Use completing read." default)
                (const :tag "Use ivy." ivy)
                (const :tag "Use helm." helm)
                (const :tag "Use ido." ido)
                (function :tag "Custom function")))

(defcustom mu4e-views-mu4e-email-headers-as-html-function
  #'mu4e-views-mu4e-email-headers-as-html
  "This function is used to create html code from an mu4e message.

The function should take a single argument MSG.  If you want to
provide your custom implementation, then have a look at the
implementation of `mu4e-views-mu4e-email-headers-as-html'."
  :group 'mu4e-views
  :type 'function)

(defcustom mu4e-views-html-filter-external-content
  t
  "If not-nil, then external elements are filtered from emails.

To filter external content, the functions from
`mu4e-views-html-dom-filter-chain' are applied to the html DOM of
the email.  This is meant to deal with tracking code."
  :group 'mu4e-views
  :type 'boolean)

(defcustom mu4e-views-html-dom-filter-chain
  '(mu4e-views-default-dom-filter)
  "Chain of filter functions for filtering html email doms.

The filters are applied to the DOM of an HTML email to filter out
annoying or malicious elements.  The filters are chained together,
i.e., the result of the first filter is fed into the second
filter, and so on.  Filters should take as input an `esxml' dom
node and return a transformed node.  If your filter is only
modifying some content of a node, then it should probably recurse
by applying itself to the children of the current node using
`esxml-tree-map'."
  :group 'mu4e-views
  :type '(list function))

(defcustom mu4e-views-file-open-function
  'open
  "Function to use to open attachments.

If `mu4e-views-mu4e-view-open-attachment' is called with a prefix
argument, then this function is used."
  :group 'mu4e-views
  :type 'function)

(defcustom mu4e-views-export-alist
  '((pdf . mu4e-views-export-to-pdf)
    (html . mu4e-views-export-to-html))
  "An alist of cons cells mapping export file formats to functions.

These functions are used to export email messages into a
particular format. The functions should take a single parameters,
the `mu4e' message plist."
  :group 'mu4e-views
  :type '(alist :key-type symbol :value-type function))

(defvar mu4e-views--mu4e-select-view-msg-method-history
  nil
  "Store completion history for `mu4e-views-mu4e-select-view-msg-method'.")

(defvar mu4e-views--current-viewing-method
  mu4e-views-default-view-method
  "Records which method for viewing email in mu4e is currently active.")

(defvar mu4e-views--one-time-viewing-method
  nil
  "Cache a one-time-use viewing method.")

(defvar mu4e-views--view-window
  nil
  "Caches the view window.")

(defvar mu4e-views--current-mu4e-message
  nil
  "Store the `mu4e' message object for the message shown in `mu4e-views' window.

This enables us to provide `mu4e' functionality in a `mu4e-views'
view such as opening or storing attachments which need this
object.")

(defvar mu4e-views--header-selected
  t
  "On moving to another email, store whether we are in the headers window.")

(defvar mu4e-views--called-from-view
  nil
  "Set if we are called from the view window.")

(defvar mu4e-views--debug
  nil
  "If true than show a lot of log output for debugging.")

(defvar mu4e-views--advice-installed
  nil
  "If true then we have already advised mu4e functions.")

(defconst mu4e-views-html-src-view-buffer-name
  "*mu4e-views-html-src*"
  "Name for the view buffer showing the html source of an email.")

(defconst mu4e-views-raw-view-buffer-name
  "*mu4e-views-raw-view*"
  "Name for the view buffer showing the raw source of an email.

This also prints other internal data structures for debugging.")

(defconst mu4e-views--default-coding-system
  "utf-8"
  "Default coding system for emails.")

(defconst mu4e-views--charset-translation
  '(("utf8" . "utf-8"))
  "Translate from email charsets to valid Emacs charset names.")

;; for 1.7 create a variable storing attachments
(when (mu4e-views-mu4e-ver->= '(1 7))
  (defvar mu4e~view-attach-map nil)
  (put 'mu4e~view-attach-map 'permanent-local t))

;; ********************************************************************************
;; FUNCTIONS

;; ********************************************************************************
;; define function for removing dom attributes on emacsen 27 or less that do not have that
(when (not (fboundp 'dom-remove-attribute))
  (defun dom-remove-attribute (node attribute)
    "Remove ATTRIBUTE from NODE."
    (setq node (dom-ensure-node node))
    (when-let ((old (assoc attribute (cadr node))))
      (setcar (cdr node) (delq old (cadr node))))))

;; ********************************************************************************
;; helper function for debug logging
(defmacro mu4e-views-debug-log (format-string &rest args)
  "Call message with FORMAT-STRING and ARGS.

Only writes messages when `mu4e-views--debug' is true."
  `(when mu4e-views--debug
     (message ,format-string ,@args)))

;; ********************************************************************************
;; helper functions for advising
(defun mu4e-views-advice-unadvice (sym)
  "Remove all advices from symbol SYM."
  (interactive "aFunction symbol: ")
  (advice-mapc (lambda (advice _props) (advice-remove sym advice)) sym))

(defun mu4e-views-advice-add-if-def (f type theadvice)
  "Add advice THEADVICE as type TYPE to function F.

Only do this if the function to be advised (F) and the advising
function (THEADVICE) both exists."
  (when (and (fboundp f)  (fboundp theadvice))
    (advice-add f type theadvice)))

(defun mu4e-views-advice-remove-if-def (f theadvice)
  "Remove advice THEADVICE from function F.

Only do this if the function to be advised (F) and the advising
function (THEADVICE) both exists."
  (when (and (fboundp f)  (fboundp theadvice))
    (advice-remove f theadvice)))

;; ********************************************************************************
;; wrapper for completing read frameworks (adapted from projectile:
;; https://github.com/bbatsov/projectile/)
(cl-defun mu4e-views-completing-read (prompt
                                      choices
                                      &key initial-input
                                      action
                                      history
                                      sort
                                      caller
                                      require-match)
  "Present a PROMPT with CHOICES.

Optionally, provide INITIAL-INPUT and an ACTION to execute with
the chosen option.  If the completion framework supports it and
HISTORY is not nil, then store completion history in HISTORY.  If
the framework supports it and SORT is t, then sort CHOICES.  If
CALLER is provided and the framework supports it, provide CALLER
as a caller.  Otherwise, provide `mu4e-views-completing-read' as
a caller.  If REQUIRE-MATCH is provided, then only matching
inputs can be selected."
  (let (res)
    (setq res
          (cond
           ((eq mu4e-views-completion-method 'ido)
            (ido-completing-read prompt
                                 choices
                                 nil
                                 require-match
                                 initial-input
                                 history))
           ((eq mu4e-views-completion-method 'default)
            (completing-read prompt
                             choices
                             nil
                             require-match
                             initial-input
                             history))
           ((eq mu4e-views-completion-method 'helm)
            (if (and (fboundp 'helm)
                     (fboundp 'helm-make-source))
                (helm :sources
                      (helm-make-source "mu4e-views" 'helm-source-sync
                        :candidates choices
                        :must-match require-match
                        :action (if action
                                    (prog1 action
                                      (setq action nil))
                                  #'identity))
                      :prompt prompt
                      :input initial-input
                      :history history
                      :buffer "*helm-mu4e-views*")
              (user-error "Please install helm from \
https://github.com/emacs-helm/helm")))
           ((eq mu4e-views-completion-method 'ivy)
            (if (fboundp 'ivy-read)
                (ivy-read prompt choices
                          :initial-input initial-input
                          :action (prog1 action
                                    (setq action nil))
                          :caller (or caller 'mu4e-views-completing-read)
                          :history history
                          :require-match require-match
                          :sort sort)
              (user-error "Please install ivy from \
https://github.com/abo-abo/swiper")))
           (t (funcall mu4e-views-completion-method prompt choices))))
    (if action
        (funcall action res)
      res)))

;; ********************************************************************************
;; Functions to create and manage view windows

;;;###autoload
(defun mu4e-views-mu4e-use-view-msg-method (method)
  "Apply METHOD for viewing emails in mu4e-headers view."
  (let
	  ((cmd (cdr (assoc
                                        ; when user asked to respect mu4e-view-use-gnus and this setting
                                        ; is on then use gnus irrespective of selection
                  (if (and mu4e-views-respect-mu4e-view-use-gnus
                           (boundp 'mu4e-view-use-gnus) ;; does no longer exists in 1.5
                           mu4e-view-use-gnus)
                      "gnus"
                    method)
                  mu4e-views-view-commands)))
	   (oldmethod mu4e-views--current-viewing-method))
                                        ; do not update anything if the method is the same
	(unless (eq cmd oldmethod)
	  (setq mu4e-views--current-viewing-method cmd)
      (mu4e-views-advice-mu4e))))

(defun mu4e-views-get-current-viewing-method ()
  "Return either currently active viewing method.

This is either the current one-time viewing method or the
currently selected viewing method."
  (or mu4e-views--one-time-viewing-method mu4e-views--current-viewing-method))

(defun mu4e-views--get-current-viewing-method-name ()
  "Get the name of the currently selected viewing method."
  (car (rassoc (mu4e-views-get-current-viewing-method) mu4e-views-view-commands)))

;; ********************************************************************************
;; preserve functions for attachment handling from older mu versions
(when (mu4e-views-mu4e-ver-> '(1 7))
  (defun mu4e~view-get-attach (msg attnum)
    "Return the attachment plist in MSG corresponding to attachment
number ATTNUM."
    (let* ((partid (gethash attnum mu4e~view-attach-map))
           (attach
            (cl-find-if
             (lambda (part)
               (eq (mu4e-message-part-field part :index) partid))
             (mu4e-message-field msg :parts))))
      (or attach (mu4e-error "Not a valid attachment"))))

  ;; construct mu4e attachments header
  (defun mu4e~view-construct-attachments-header (msg)
    "Display attachment information; the field looks like something like:
        :parts ((:index 1 :name \"1.part\" :mime-type \"text/plain\"
                 :type (leaf) :attachment nil :size 228)
                (:index 2 :name \"analysis.doc\"
                 :mime-type \"application/msword\"
                 :type (leaf attachment) :attachment nil :size 605196))"
    ;; create hash table
    (setq mu4e~view-attach-map ;; buffer local
          (make-hash-table :size 64 :weakness nil))

    (if (mu4e-views-mu4e-ver-< '(1 8))
        (mu4e~view-construct-attachments-header-v17 msg)
      (mu4e~view-construct-attachments-header-v18 msg)))

  (defun mu4e~view-construct-attachments-header-v18 (msg)
    "Construct hashmap for attachment information for MSG.

For 1.8 we need to use gnus data structures since mu4e no longer
stores parts in a message plist."
    (mu4e-views-create-gnus-att-handles-need-be msg)
    (let* ((id 0)
           (atts (plist-get msg :gnus-attachments))
           attplists)
      (dolist (att atts)
        (let ((name (car att))
              (part (cdr att)))
          (when name
            (let* ((mimetype (car (mm-handle-type part)))
                   (filename (mm-handle-filename part)))
              (push
               `(:index ,(cl-incf id)
                        :mime-type ,mimetype
                        :size 0
                        :type (leaf attachment)
                        :name ,name
                        :filename ,filename
                        :attachment t
                        :attindex ,id)
               attplists)))))
      ;; (setq attplists (nreverse attplists))
      (plist-put msg :parts attplists)
      (setq id 0)
      (dolist (att attplists)
        (let ((index (mu4e-message-part-field att :index)))
          (cl-incf id)
          (puthash id index mu4e~view-attach-map)))
      (mu4e-views-debug-log "================================================================================\nMESSAGE PLIST WITH ASSIGNMENTS: %s\n================================================================================" msg)
      attplists))

  ;; construct mu4e view attachments data structure in 1.7.x
  (defun mu4e~view-construct-attachments-header-v17 (msg)
    "Construct hashmap for attachment information for MSG.

The field looks like something like:
        :parts ((:index 1 :name \"1.part\" :mime-type \"text/plain\"
                 :type (leaf) :attachment nil :size 228)
                (:index 2 :name \"analysis.doc\"
                 :mime-type \"application/msword\"
                 :type (leaf attachment) :attachment nil :size 605196))"

    ;; identify message parts that are attachments and store them in the hash table
    (let* ((id 0)
           (partcount (length (mu4e-message-field msg :parts)))
           (attachments
            ;; we only list parts that look like attachments, ie. that have a
            ;; non-nil :attachment property; we record a mapping between
            ;; user-visible numbers and the part indices
            (cl-remove-if-not
             (lambda (part)
               (let* ((mtype (or (mu4e-message-part-field part :mime-type)
                                 "application/octet-stream"))
                      (partsize (or (mu4e-message-part-field part :size) 0))
                      (attachtype (mu4e-message-part-field part :type))
                      (isattach
                       (or ;; we consider parts marked either
                        ;; "attachment" or "inline" as attachment.
                        (member 'attachment attachtype)
                        ;; list inline parts as attachment (so they can be
                        ;; saved), unless they are text/plain, which are
                        ;; usually just message footers in mailing lists
                        ;;
                        ;; however, slow bigger text parts as attachments,
                        ;; except when they're the only part... it's
                        ;; complicated.
                        (and (member 'inline attachtype)
                             (or
                              (and (> partcount 1) (> partsize 256))
                              (not (string-match "^text/plain" mtype)))))))
                 (or ;; remove if it's not an attach *or* if it's an
                  ;; image/audio/application type (but not a signature)
                  isattach
                  (string-match "^\\(image\\|audio\\)" mtype)
                  (string= "message/rfc822" mtype)
                  (string= "text/calendar" mtype)
                  (and (string-match "^application" mtype)
                       (not (string-match "signature" mtype))))))
             (mu4e-message-field msg :parts))))

      (mapc
       (lambda (part)
         (let ((index (mu4e-message-part-field part :index)))
           (cl-incf id)
           (puthash id index mu4e~view-attach-map)))
       attachments)))
  )

;; ********************************************************************************
;; VIEWING METHOD: html
;; functions for viewing a mu4e message in xwidgets
(defun mu4e-views-xwidget-mu4e-view (html msg win)
  "View message MSG with HTML content in xwidget using window WIN."
  (interactive)
  (ignore msg)
  (unless (fboundp 'xwidget-webkit-browse-url)
	(mu4e-error "No xwidget support available"))
  (setq mu4e~view-message msg)
  ;; select window
  (select-window win)
  ;; show message
  (xwidgets-reuse-xwidget-reuse-browse-url
   (concat "file://" html)
   'mu4e-views-view-actions-mode))

(defun mu4e-views-xwidget-is-view-window-p (win)
  "Return t if WIN is the xwidget view window."
  (let ((buf (window-buffer win)))
    (with-current-buffer buf
      (eq major-mode 'xwidget-webkit-mode))))

;; ********************************************************************************
;; VIEWING METHOD: html-src
;; functions for viewing a mu4e message html source code
(defun mu4e-views-html-src-view-message (html msg win)
  "View html source code HTML of message MSG in window WIN."
  (ignore msg)
  (setq mu4e~view-message msg)
  (when (get-buffer mu4e-views-html-src-view-buffer-name)
    (kill-buffer mu4e-views-html-src-view-buffer-name))
  (let ((buf (find-file-noselect html)))
    (with-current-buffer buf
      (read-only-mode)
      (select-window win)
      (switch-to-buffer buf t t)
      (rename-buffer mu4e-views-html-src-view-buffer-name)
      (mu4e-views-view-actions-mode 1))))

(defun mu4e-views-html-src-is-view-p (win)
  "Return non-nil if window WIN is showing the html source of an email."
  (let ((winbuf (window-buffer win)))
    (with-current-buffer winbuf
      (string= mu4e-views-html-src-view-buffer-name (buffer-name winbuf)))))

;; ********************************************************************************
;; VIEWING METHOD: dispatcher
(defun mu4e-views-dispatcher-view-message (msg win) ;;CHECK have removed html
  "Dispatches to another viewing method.
This is based the map from predicate to view method in
`mu4e-views-dispatcher-predicate-view-map'.  Parameters HTML, MSG and WIN are
passed on to the selected view method."
  (let* ((viewmethod
          (cdr (assoc
                (cdr (seq-find (lambda (it) (funcall (car it) msg))
                               mu4e-views-dispatcher-predicate-view-map
                               '(t  "text")))
                mu4e-views-view-commands)))
         (viewfun (plist-get viewmethod :viewfunc))
         (createwinfun (plist-get viewmethod :create-view-window))
         (only-msg (plist-get viewmethod :view-function-only-msg))
         (filter-pretermined (plist-member viewmethod :filter-html))
         (filter-html (when filter-pretermined (if (plist-get viewmethod :filter-html) t 0)))
         (filters (plist-get viewmethod :filters))
         html)
    (mu4e-views-debug-log "viewmethod <%s> for mssage %s"
                          viewmethod
                          (mu4e-message-field msg  :docid))
    ;; store view method as one time method for reference of other functions
    (setq mu4e-views--one-time-viewing-method viewmethod)
    (unless only-msg
	  (setq html (mu4e-views-mu4e~write-body-and-headers-to-html msg filter-html filters)))
    (when createwinfun
      (funcall createwinfun win))
    (if only-msg
        (funcall viewfun msg win)
      (funcall viewfun html msg win))))

(defun mu4e-views-dispatcher-is-view-window-p (win)
  "Check whether any dispatched to viewing methods recognizes WIN as its own."
  (let ((viewmethods (mapcar (lambda (it) (thread-first it
                                                        (cdr)
                                                        (assoc mu4e-views-view-commands)
                                                        (cdr)
                                                        (plist-get :is-view-window-p)))
                             mu4e-views-dispatcher-predicate-view-map)))
    (seq-find (lambda (v) (funcall v win)) viewmethods)))

;; ********************************************************************************
;; VIEWING METHOD: text (only supported < mu 1.7)

;; keep byte compiler quiet. This is function is dynamically defined by mu4e based on the selected viewing method.
(declare-function mu4e-view-mode "mu4e-view" nil t)
(declare-function mu4e~view-activate-urls nil nil t)

(when (mu4e-views-mu4e-ver-< '(1 7))

  (defun mu4e-views-text-view-message (msg win)
    "Copy of most of `mu4e~view-internal' for using this method from `mu4e-views'.

Takes MSG plist and window WIN as input."
    (let* ((embedded ;; is it as an embedded msg (ie. message/rfc822 att)?
            (when (mu4e-views-mu4e-ver-< '(1 5))
              (when (gethash (mu4e-message-field msg :path)
                             mu4e~path-parent-docid-map) t)))
           (buf (if embedded
                    (mu4e~view-embedded-winbuf)
                  (get-buffer-create mu4e~view-buffer-name)))
           (previouswin (selected-window)))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (if (mu4e-views-mu4e-ver-< '(1 5))
              ;; for versions before 1.5.x
              (progn
                (mu4e-views-debug-log "IN TEXT VIEW < 1.5 selected message is %s" (mu4e-message-field msg :docid))
                (when (or embedded (not (mu4e~view-mark-as-read-maybe msg)))
                  (erase-buffer)
                  (mu4e~delete-all-overlays)
                  (insert (mu4e-view-message-text msg))
                  (goto-char (point-min))
                  (mu4e~fontify-cited)
                  (mu4e~fontify-signature)
                  (mu4e~view-make-urls-clickable)
                  (mu4e~view-show-images-maybe msg)
                  (when (not embedded) (setq mu4e~view-message msg))
                  (mu4e-view-mode)
                  (when embedded (local-set-key "q" 'kill-buffer-and-window))))
            (mu4e-views-debug-log "IN TEXT VIEW >= 1.5 selected message is %s" (mu4e-message-field msg :docid))
            (erase-buffer)
            (mu4e~delete-all-overlays)
            (insert (mu4e-view-message-text msg))
            (goto-char (point-min))
            (mu4e~fontify-cited)
            (mu4e~fontify-signature)
            (mu4e~view-activate-urls)
            (mu4e~view-show-images-maybe msg)
            (when (not embedded) (setq mu4e~view-message msg))
            (mu4e-view-mode)
            (when embedded (local-set-key "q" 'kill-buffer-and-window)))
          (select-window win)
          (switch-to-buffer buf t t)
          (select-window previouswin)))))

  (defun mu4e-views-text-create-view-window (window)
    "Create the mu4e-view window for the `text' method in WINDOW."
    (select-window window)
    (unless (buffer-live-p mu4e~headers-loading-buf)
      (setq mu4e~headers-loading-buf (get-buffer-create " *mu4e-loading*"))
      (with-current-buffer mu4e~headers-loading-buf
        (mu4e-loading-mode))))

  (defun mu4e-views-text-is-view-window-p (window)
    "Check whether WINDOW is the mu4e-view window.

This window is used by the `text' or `gnus' (standard mu4e methods)."
    (let ((buf (window-buffer window)))
      (or (eq buf mu4e~headers-loading-buf)
          (eq buf (get-buffer mu4e~view-buffer-name)))))

  )

;; ********************************************************************************
;; VIEWING METHOD: pdf
;; viewing email as a pdf (available as action and as a view method. This uses html-pdf
(defun mu4e-view-pdf-view-message (html msg win)
  "Transform HTML MSG file into pdf.

This is done by running `mu4e-views-html-to-pdf-command' and show
in WIN."
  (ignore msg)
  (let* ((pdf (concat (file-name-sans-extension html) ".pdf"))
         (cmd (format-spec mu4e-views-html-to-pdf-command
                           (format-spec-make ?h html ?p pdf))))
    (setq mu4e~view-message msg)
    ;; select window
    (select-window win)
    ;; kill previous pdf buffer if there (don't want them to accumulate)
    (when (or (eq major-mode 'pdf-view-mode)
              (eq major-mode 'doc-view-mode))
      (kill-buffer (window-buffer win)))
    ;; run html-to-pdf command
    (shell-command cmd nil nil) ;;TODO set buffer
    ;; show message
    (switch-to-buffer
     (find-file-noselect pdf) t t)))

(defun mu4e-views--html-to-pdf (html-file pdf-file)
  "Export HTML-FILE as pdf PDF-FILE."
  (let ((cmd (format-spec mu4e-views-html-to-pdf-command
                          (format-spec-make ?h html-file ?p pdf-file))))
    (message "Execute: %s" cmd)
    (shell-command cmd nil nil)))

(defun mu4e-views-pdf-is-view-window-p (window)
  "Check whether WINDOW is the mu4e-view window for the `pdf' view method."
  (let ((buf (window-buffer window)))
    (with-current-buffer buf
      (or (eq major-mode 'pdf-view-mode)
          (eq major-mode 'doc-view-mode)
          (eq buf mu4e~headers-loading-buf)))))

;; ********************************************************************************
;; VIEWING METHOD: raw
;; viewing email as raw text plus show summary of some gnus datastructures for debugging
(defun mu4e-views-raw-view-message (html msg win)
  "View raw content of email MSG in WIN.

Also show mu4e message plist and gnus parts for easier debugging.
Ignores HTML."
  (setq mu4e~view-message msg)
  (when (get-buffer mu4e-views-raw-view-buffer-name)
    (kill-buffer mu4e-views-raw-view-buffer-name))
  (cl-flet ((hmessage (mes)
              (insert (format "================================================================================\n%s\n================================================================================\n" (upcase mes)))))
    (let ((buf (get-buffer-create mu4e-views-raw-view-buffer-name)))
      (with-current-buffer buf
        (hmessage "gnus parts")
        (mu4e-views-create-gnus-all-parts-if-need-be msg)
        (insert (pp-to-string (plist-get msg :gnus-all-parts)))
        (hmessage "message plist")
        (insert (pp-to-string msg))
        (hmessage "raw message")
        (insert-file-contents-literally (plist-get msg :path))
        (read-only-mode)
        (select-window win)
        (switch-to-buffer buf t t)
        ;; (rename-buffer mu4e-views-raw-view-buffer-name)
        (mu4e-views-view-actions-mode 1)))))

(defun mu4e-views-raw-is-view-p (win)
  "Return non-nil if window WIN is showing the raw source of an email."
  (let ((winbuf (window-buffer win)))
    (with-current-buffer winbuf
      (string= mu4e-views-raw-view-buffer-name (buffer-name winbuf)))))


;; ********************************************************************************
;; VIEWING METHOD: gnus
;; viewing email using the mu4e build-in view based on gnus article view


(defun mu4e-views-gnus-view-message (msg win)
  "View message MSG on window WIN using Gnus article mode."
  (if (mu4e-views-mu4e-ver-< '(1 5))
      (mu4e-views-gnus-view-message-before-1.5 msg win)
    (mu4e-views-gnus-view-message-1.5-or-later msg win)))

(declare-function mu4e~view-render-buffer nil t)
(defvar gnus-article-buffer)

(defun mu4e-views-gnus-view-message-1.5-or-later (msg win)
  "View message MSG on window WIN using Gnus article.

This function is for mu4e versions 1.5.x or later."
  (when (bufferp gnus-article-buffer)
    (kill-buffer gnus-article-buffer))
  (with-current-buffer (get-buffer-create gnus-article-buffer)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert-file-contents-literally
       (mu4e-message-field msg :path) nil nil nil t)))
  (select-window win)
  (switch-to-buffer gnus-article-buffer t t)
  (mu4e~view-render-buffer msg))

(defun mu4e-views-gnus-view-message-before-1.5 (msg win)
  "View message MSG on window WIN using Gnus article mode.

This function is for mu4e versions before 1.5.x."
  (require 'gnus-art)
  (let* ((marked-read (if (mu4e-views-mu4e-ver-< '(1 5))
                          nil
                        (mu4e~view-mark-as-read-maybe msg)))
         (path (mu4e-message-field msg :path))
         (inhibit-read-only t)
         ;; support signature verification
         (mm-verify-option 'known)
         (mm-decrypt-option 'known)
         (gnus-article-emulate-mime t)
         (previouswin (selected-window))
         (buf (get-buffer-create mu4e~view-buffer-name))
         (gnus-buttonized-mime-types (append (list "multipart/signed"
                                                   "multipart/encrypted")
                                             gnus-buttonized-mime-types)))
    (select-window win)
    (switch-to-buffer buf t t)
    (erase-buffer)
    (unless marked-read
      ;; when we're being marked as read, no need to start rendering
      ;; the messages; just the minimal so (update... ) can find us.
      (insert-file-contents-literally path)
      (unless (message-fetch-field "Content-Type" t)
        ;; For example, for messages in `mu4e-drafts-folder'
        (let ((coding (or (default-value 'buffer-file-coding-system)
                          'prefer-utf-8)))
          (recode-region (point-min) (point-max) coding 'no-conversion)))
      (setq
       gnus-summary-buffer (get-buffer-create " *appease-gnus*")
       gnus-original-article-buffer (current-buffer))
      (run-hooks 'gnus-article-decode-hook)
      (mu4e-views-gnus-prepare-display
       mu4e-view-max-specpdl-size
       (mu4e~view-gnus-display-mime msg)
       (mu4e-personal-addresses))
      ;; (setq lexical-binding nil)
      ;;   (let ((mu4e~view-rendering t) ; customize gnus in mu4e
      ;;         (max-specpdl-size mu4e-view-max-specpdl-size)
      ;;         (gnus-blocked-images ".") ;; don't load external images.
      ;;         ;; Possibly add headers (before "Attachments")
      ;;         (gnus-display-mime-function (mu4e~view-gnus-display-mime msg))
      ;;         (gnus-icalendar-additional-identities (mu4e-personal-addresses)))
      ;;     (gnus-article-prepare-display)))
      ;; (setq lexical-binding t)
      (setq mu4e~gnus-article-mime-handles gnus-article-mime-handles)
      (setq mu4e~view-message msg)
      (mu4e-view-mode)
      (setq gnus-article-decoded-p gnus-article-decode-hook)
      (set-buffer-modified-p nil)
      (add-hook 'kill-buffer-hook
                (lambda() ;; cleanup the mm-* buffers that the view spawns
                  (when mu4e~gnus-article-mime-handles
                    (mm-destroy-parts mu4e~gnus-article-mime-handles)
                    (setq mu4e~gnus-article-mime-handles nil))))
      (read-only-mode))
    (select-window previouswin)))

(defvar gnus-icalendar-additional-identities)

(defun mu4e-views-gnus-prepare-display (mymax-specpdl-size mime-functions idents)
  "Use dynamic scope to override gnus settings.

The settings that we override are MYMAX-SPECPDL-SIZE
MIME-FUNCTIONS IDENTS."
  (let ((mu4e~view-rendering t) ; customize gnus in mu4e
        (max-specpdl-size mymax-specpdl-size)
        (gnus-blocked-images ".") ;; don't load external images.
        ;; Possibly add headers (before "Attachments")
        (gnus-display-mime-function mime-functions)
        (gnus-icalendar-additional-identities idents))
    (gnus-article-prepare-display)))

(defun mu4e-views-gnus-create-view-window (window)
  "Create the mu4e-view window for the `gnus' method in WINDOW."
  (select-window window)
  (if (mu4e-views-mu4e-ver-< '(1 5))
      (unless (buffer-live-p mu4e~headers-loading-buf)
        (setq mu4e~headers-loading-buf (get-buffer-create " *mu4e-loading*"))
        (with-current-buffer mu4e~headers-loading-buf
          (mu4e-loading-mode)))
    (unless (buffer-live-p gnus-article-buffer)
      (with-current-buffer (get-buffer-create gnus-article-buffer)))))

(defun mu4e-views-gnus-is-view-window-p (window)
  "Check whether WINDOW is the mu4e-view window.

This is for the `gnus' method (new standard mu4e viewing
method)."
  (let ((buf (window-buffer window)))
    (if (mu4e-views-mu4e-ver-< '(1 5))
        (or (eq buf mu4e~headers-loading-buf)
            (eq buf (get-buffer mu4e~view-buffer-name)))
      (or (eq buf gnus-article-buffer)
          (eq buf (get-buffer gnus-article-buffer))))))

;; ********************************************************************************
;; VIEWING METHOD: browser
;; viewing email in a webbrowser (available as action and as a view method)
(defun mu4e-views-mu4e-view-in-browser-action (msg)
  "Open email MSG in browser using `browse-url'."
  (interactive)
  (browse-url (concat "file://"
                      (mu4e-views-mu4e~write-body-and-headers-to-html msg))))

(defun mu4e-views-view-in-browser (html msg)
  "Open email `MSG` with content HTML using `browse-url'."
  (ignore msg)
  (browse-url (concat "file://" html)))

;; access with `aV' from headers view
(add-to-list 'mu4e-headers-actions
             '("ViewInBrowser" . mu4e-views-mu4e-view-in-browser-action) t)

;; ********************************************************************************
;; functions for writing a message to HTML and making it accessible to custom views
(defun mu4e-views--person-name (muperson)
  "Get a name from a mu4e person MUPERSON."
  (if (mu4e-views-mu4e-ver-> '(1 8 0))
      (plist-get muperson :name)
    (car muperson)))

(defun mu4e-views--person-email (muperson)
  "Get a name from a mu4e person MUPERSON."
  (if (mu4e-views-mu4e-ver-> '(1 8 0))
      (plist-get muperson :email)
    (cdr muperson)))

(defun mu4e-views-mu4e-email-headers-as-html (msg)
  "Create formatted html for headers like subject and from/to of email MSG."
  (interactive)
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by msg)
  (cl-flet ((wrap-row (header content id)
              (concat "<div class=\"mu4e-mu4e-views-header-row\">"
                      "<div class=\"mu4e-mu4e-views-mail-header\">"
                      header "</div>: <div class=\"mu4e-mu4e-views-header-content\" id=\""
                      id "\">"
                      content "</div></div>"))
			(wrap-row-multi (headers)
              (concat "<div class=\"mu4e-mu4e-views-header-row\">"
					  (mapconcat
                       (lambda (l) (let ((header (nth 0 l))
										 (content (nth 1 l))
										 (id (nth 2 l)))
									 (concat "<div class=\"mu4e-mu4e-views-mail-header\">"
											 header "</div>: <div class=\"mu4e-mu4e-views-header-content\" id=\""
                                             id "\">"
											 content "</div>")))
					   headers "")
					  "</div>")))
	(with-temp-buffer
	  (insert (concat "<div class=\"mu4e-mu4e-views-mail-headers\">"))
	  (insert (wrap-row "from"
                        (mapconcat
                         (lambda (mail)
                           (concat "<div class=\"mu4e-mu4e-views-email\">"
                                   (mu4e-views--person-name mail) " ("
                                   (mu4e-views--person-email mail) ")</div>"))
                         (mu4e-message-field msg :from) "")
                        "mu4e-from"))
	  (insert (wrap-row "to" (mapconcat
                              (lambda (mail)
                                (concat "<div class=\"mu4e-mu4e-views-email\">"
                                        (mu4e-views--person-name mail) " ("
                                        (mu4e-views--person-email mail) ")</div>"))
                              (mu4e-message-field msg :to) "")
                        "mu4e-to"))
	  (when (mu4e-message-field msg :cc)
		(insert (wrap-row "cc" (mapconcat
                                (lambda (mail)
                                  (concat "<div class=\"mu4e-mu4e-views-email\">"
                                          (mu4e-views--person-name mail) " ("
                                          (mu4e-views--person-email mail) ")</div>"))
                                (mu4e-message-field msg :cc) "")
                          "mu4e-cc")))
	  (when (mu4e-message-field msg :bcc)
		(insert (wrap-row "bcc" (mapconcat
                                 (lambda (mail)
                                   (concat "<div class=\"mu4e-mu4e-views-email\">"
                                           (mu4e-views--person-name mail) " ("
                                           (mu4e-views--person-email mail) ")</div>"))
                                 (mu4e-message-field msg :bcc) "")
                          "mu4e-bcc")))
	  (insert (wrap-row "subject" (mu4e-message-field msg :subject) "mu4e-subject"))
	  (insert (wrap-row-multi (list
							   (list "date"
                                     (format-time-string (if (boundp 'mu4e-view-date-format)
                                                             mu4e-view-date-format
                                                           "%Y-%m-%d")
											             (mu4e-message-field msg :date))
                                     "mu4e-date")
							   (list "size"
                                     (mu4e-display-size (mu4e-message-field msg :size))
                                     "mu4e-size")
							   (list "maildir"
                                     (mu4e-message-field msg :maildir)
                                     "mu4e-maildir"))))
	  (let ((attachments (mu4e-views-get-attachment-plists msg)))
		(when attachments
		  (insert (wrap-row "attachments" (mapconcat
                                           (lambda (att)
                                             (concat "<div class=\"mu4e-mu4e-views-attachment\">"
                                                     (lax-plist-get att :name) " ("
                                                     (mu4e-display-size (lax-plist-get att :size)) ")</div>"))
                                           attachments "")
                            "mu4e-attachments"))))
      ;;TODO process attachments for 1.7
      ;; )
	  (insert "</div>")
	  (buffer-string))))

(defun mu4e-views-set-auto-mode-dummy (&optional keep-mode-if-same)
  "Do nothing function to replace `set-auto-mode' when just writing to a file.
Ignore `KEEP-MODE-IF-SAME'."
  (ignore keep-mode-if-same))

(defun mu4e-views-vc-refresh-state-dummy ()
  "Do nothing function to replace `vc-refresh-state' when just writing to a file.")

(defun mu4e-views-vc-before-save-dummy ()
  "Do nothing function to replace `vc-before-save' when just writing to a file.")

(defun mu4e-views-vc-after-save-dummy ()
  "Do nothing function to replace `vc-before-after' when just writing to a file.")

(defun mu4e-views-mu4e~write-body-and-headers-to-html (msg &optional filter-html filters)
  "Write the body (either html or text) and headers of MSG to a temporary file.

Return the file's name.  Text messages are converted into html.
If FILTER-HTML is non-nil, then it determines whether the html
text is filtered by applying all filters from
`mu4e-views-html-dom-filter-chain' or argument FILTERS if it is
provided (if FILTERS-HTML is t).  Otherwise,
`mu4e-views-html-filter-external-content' is consulted to
determine whether to filter or not."

  ;; create attachments map if it doex not yet exist
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by msg)

  (let* ((html (mu4e-message-field msg :body-html))
		 (txt (mu4e-message-field msg :body-txt))
         (charcoding (or (plist-get msg :body-html-coding)
                                   (plist-get msg :body-txt-coding)
                                   mu4e-views--default-coding-system))
         (transfercoding (plist-get msg :body-transfer-coding))
         (icalinvites (plist-get msg :icals))
         (codingsymb (intern charcoding))
		 (tmpfile (mu4e-make-temp-file "html"))
         (dofilter (if filter-html
                       (if (eq filter-html t) t nil)
                     mu4e-views-html-filter-external-content))
         (filter-chain (or filters mu4e-views-html-dom-filter-chain))
         (attachments (mu4e-views-get-attachment-plists msg)))
    (unless (or html txt)
      (setq txt "")
	  (mu4e-views-debug-log "No body part for this message"))
    ;; (when (and txt (string= transfercoding "base64"))
    ;;   (setq txt (base64-decode-string txt nil t)))
	;; remove hooks and advices that are not needed for writing constructed content to a file, but slow us down
	(mu4e-views-advice-remove-if-def #'set-visited-file-name 'doom-modeline-update-buffer-file-name)
	(mu4e-views-advice-remove-if-def #'set-visited-file-name 'lsp--on-set-visited-file-name)
	(mu4e-views-advice-remove-if-def #'basic-save-buffer 'polymode-with-current-base-buffer)
	(mu4e-views-advice-remove-if-def #'vc-refresh-state 'doom-modeline-update-vcs-text)
	(mu4e-views-advice-remove-if-def #'vc-refresh-state 'doom-modeline-update-vcs-icon)
	(mu4e-views-advice-remove-if-def #'rename-buffer 'doom-modeline-update-buffer-file-name)
	(mu4e-views-advice-add-if-def #'set-auto-mode :override #'mu4e-views-set-auto-mode-dummy)
	(mu4e-views-advice-add-if-def #'vc-refresh-state :override #'mu4e-views-vc-refresh-state-dummy)
	(mu4e-views-advice-add-if-def #'vc-before-save :override #'mu4e-views-vc-before-save-dummy)
	(mu4e-views-advice-add-if-def #'vc-after-save :override #'mu4e-views-vc-after-save-dummy)
    ;; write HTML and set coding system
    (mu4e-views-debug-log "Coding system %s (%s) - with transfer coding" charcoding (symbol-name codingsymb) transfercoding)
    (cl-assert (coding-system-p codingsymb)
               "Unkown coding system: %s (%s)"
               (symbol-name codingsymb)
               charcoding)
	(let ((cache-before-save-hook before-save-hook)
		  (cache-after-save-hook after-save-hook)
          (coding-system-for-write codingsymb))
      ;; write HTML to buffer
	  (with-temp-buffer
        (setq-local buffer-file-coding-system codingsymb)
		(setq before-save-hook nil)
		(setq after-save-hook nil)
		(insert (concat (format "<html><head><meta charset=\"%s\">" charcoding)
                        mu4e-views-mu4e-html-email-header-style
                        "</head>\n"))
        ;; insert mu4e-views info header
        (when mu4e-views-inject-email-information-into-html
          (mu4e-views-debug-log "Insert html mail header")
          (insert (funcall mu4e-views-mu4e-email-headers-as-html-function msg)))
        ;; insert ical invites from message
        (dolist (ical icalinvites)
          (mu4e-views-debug-log "Insert calendar invite")
          (insert (mu4e-views-ical-to-html ical)))
        ;; if message is html, then optionally apply provided or default filter-chain
        (if html
            (let ((decoded-html (decode-coding-string html codingsymb)))
              (if dofilter
                  (insert (mu4e-views-filter-html msg decoded-html filter-chain codingsymb))
                (insert decoded-html)))
		  (insert (concat "<div style=\"white-space: pre-wrap;\">" txt "</div>")))
		(write-file tmpfile)
		;; rewrite inline attachment urls (show images that are attachments)
		(mapc (lambda (attachment)
                (let* ((fname (plist-get attachment :name))
                       (cid (plist-get attachment :cid))
                       (temp (plist-get attachment :temp))
                       (tmp-attachment-name (save-match-data (mu4e-make-temp-file (file-name-extension fname))))
                       (cid-search-str (format "src=\"cid:%s\"" cid))
                       have-matched)
				  (goto-char (point-min))
				  (while (re-search-forward cid-search-str nil t)
				    (if temp
					    (replace-match (format "src=\"%s\"" temp))
                      ;; replace with file link and write att to that file
					  (replace-match (format "src=\"%s\"" tmp-attachment-name))
                      ;; do not write more than once
                      (unless have-matched
                        (setq have-matched t)
                        (mu4e-views-save-cid-content-to-html msg cid tmp-attachment-name))))))
			  attachments)
		(save-buffer)
		;; restore normal behaviour
		(mu4e-views-advice-add-if-def #'set-visited-file-name :after 'doom-modeline-update-buffer-file-name)
		(mu4e-views-advice-add-if-def #'set-visited-file-name :around 'lsp--on-set-visited-file-name)
		(mu4e-views-advice-add-if-def #'basic-save-buffer :around 'polymode-with-current-base-buffer)
		(mu4e-views-advice-add-if-def #'vc-refresh-state :after 'doom-modeline-update-vcs-text)
		(mu4e-views-advice-add-if-def #'vc-refresh-state :after 'doom-modeline-update-vcs-icon)
		(mu4e-views-advice-add-if-def #'rename-buffer :after 'doom-modeline-update-buffer-file-name)
		(mu4e-views-advice-remove-if-def #'set-auto-mode #'mu4e-views-set-auto-mode-dummy)
		(mu4e-views-advice-remove-if-def #'vc-refresh-state #'mu4e-views-vc-refresh-state-dummy)
		(mu4e-views-advice-remove-if-def #'vc-before-save #'mu4e-views-vc-before-save-dummy)
		(mu4e-views-advice-remove-if-def #'vc-after-save #'mu4e-views-vc-after-save-dummy)
		(setq before-save-hook cache-before-save-hook)
		(setq after-save-hook cache-after-save-hook)
		(lax-plist-put msg :html-file tmpfile)
		tmpfile))))

;; convert calendar invite into html
(defun mu4e-views-ical-to-html (ical)
  "Convert an calendar invite gnus handle into html."
  (cl-flet* ((wrap-row (header content id)
              (concat "<div class=\"mu4e-mu4e-views-header-row\">"
                      "<div class=\"mu4e-mu4e-views-mail-header\">"
                      header "</div>: <div class=\"mu4e-mu4e-views-header-content\" id=\""
                      id "\">"
                      content "</div></div>"))
			(wrap-row-multi (headers)
              (concat "<div class=\"mu4e-mu4e-views-header-row\">"
					  (mapconcat
                       (lambda (l) (let ((header (nth 0 l))
										 (content (nth 1 l))
										 (id (nth 2 l)))
									 (concat "<div class=\"mu4e-mu4e-views-mail-header\">"
											 header "</div>: <div class=\"mu4e-mu4e-views-header-content\" id=\""
                                             id "\">"
											 content "</div>")))
					   headers "")
					  "</div>"))
            (key-field-row (key field)
              (when (and field (not (string-equal field  "")))
              (let ((id (concat "mu4e-" key)))
              	  (insert (wrap-row key
                        (concat "<div class=\"mu4e-mu4e-views-email\">"
                                (substring-no-properties field)
                                "</div>")
                        id))))))
	(with-temp-buffer
	  (insert (concat "<div class=\"mu4e-mu4e-views-mail-headers\">"))
      (insert "<div class=\"mu4e-mu4e-views-mail-title\">Calendar Invite</div>")
      (key-field-row "organizer" (gnus-icalendar-event:organizer ical))
      (key-field-row "summary" (gnus-icalendar-event:summary ical))
      (key-field-row "location" (gnus-icalendar-event:location ical))
      (key-field-row "time" (concat (gnus-icalendar-event:start ical)
                                    " - "
                                    (format-time-string "%H:%m" (gnus-icalendar-event:end-time ical))))
      (key-field-row "participants"
                     (->> (gnus-icalendar-event:req-participants ical)
                          (--reduce-from (concat acc (when (not (string-equal acc "")) ", ") it) "")))
      (key-field-row "optional-participants"
                     (->> (gnus-icalendar-event:opt-participants ical)
                          (--reduce-from (concat acc (when (not (string-equal acc "")) ", ") it) "")))
      (when (gnus-icalendar-event:description ical)
          (key-field-row "description" "  ")
          (insert (concat "<div style=\"white-space: pre-wrap;\">"
                                 (gnus-icalendar-event:description ical)
                                 "</div>")))
	  (insert "</div>")
	  (buffer-string))))

;; ********************************************************************************
;; functions for filtering HTML DOMs
(defun mu4e-views-filter-html (msg html &optional filters codingsymb)
  "Filter HTML of message MSG to remove external elements.

All filters from `mu4e-views-html-dom-filter-chain' are applied
in sequence.  If FILTERS is non-nil, then it should be a list of
filters to apply instead."
  (let ((filter-chain (or filters mu4e-views-html-dom-filter-chain)))
    (mu4e-views-debug-log
     "FILTER HTML:\n\tfilters: %s\n\thave LIBXML: %s"
     filters
     (libxml-available-p))
    (when (libxml-available-p)
      (with-temp-buffer
        (setq-local buffer-file-coding-system codingsymb)
        (insert html)
        (let ((dom (libxml-parse-html-region (point-min) (point-max))))
          (esxml-to-xml
           (mu4e-views-apply-dom-filter-chain
            msg
            dom
            filter-chain)))))))

(defun mu4e-views-apply-dom-filter-chain (msg dom filters)
  "Apply all filters from list FILTERS to MSG and DOM in sequence."
  (let ((transdom dom))
    (dolist (f filters transdom)
      (setq transdom (mu4e-views-apply-dom-filter msg transdom f)))))

(defun mu4e-views-apply-dom-filter (msg dom f)
  "Apply filter function F to MSG and html DOM and return filtered DOM."
  (funcall f msg dom))

;; define dom-remove-node for emacs 25
(when (<= emacs-major-version 25)
  (defun dom-remove-node (dom node)
	"Remove NODE from DOM."
	;; If we're removing the top level node, just return nil.
	(dolist (child (dom-children dom))
	  (cond
	   ((eq node child)
	 	(delq node dom))
	   ((not (stringp child))
	 	(dom-remove-node child node))))))

(defun mu4e-views-dom-remove-attr-and-map-children (msg node att f)
  "Remove attribute ATT from NODE apply F to it's children.

MSG is passed on to F."
  (dom-remove-attribute node att)
  (mu4e-views-apply-dom-filter-to-children msg node f))

(defun mu4e-views-apply-dom-filter-to-children (msg dom f)
  "Return the result of applying F to the children of DOM.

That is, the result is constructed by replacing the children of
DOM with the result of applying F to them.  MSG is an mu4e email
plist that is passed on to F."
  (cond
   ((stringp dom) dom)
   ((not (dom-children dom)) dom)
   (t (let ((new-children (-map
                           (lambda (n)
                             (mu4e-views-apply-dom-filter msg n f))
                           (dom-children dom))))
        (apply 'dom-node
               (dom-tag dom)
               (dom-attributes dom)
               (--filter it new-children))))))

(defun mu4e-views-dom-fix-img (msg n f)
  "Remove the src tag of img tag N unless it is pointing to an attachment.

MSG is just passed on when recursing into the children using F."
  (if (dom-attr n 'src)
      (let ((src (dom-attr n 'src)))
        (if (string-prefix-p  "cid:" src)
            (mu4e-views-apply-dom-filter-to-children msg n f)
          (mu4e-views-dom-remove-attr-and-map-children msg n 'src f)))
    (mu4e-views-apply-dom-filter-to-children msg n f)))

(defun mu4e-views-default-dom-filter (msg n)
  "Default filter function for html emails.

Takes as input a message mu4e message plist MSG and a dom node
N."
  (cl-flet ((is-a (node tag) (eq (dom-tag node) tag))
            (has-att (node a) (dom-attr node a))
            (recurse-children (node) (mu4e-views-apply-dom-filter-to-children msg node #'mu4e-views-default-dom-filter)))
    (cond
     (;; text is fine
      (stringp n) n)
     ;; images
     ((is-a n 'img) (mu4e-views-dom-fix-img msg n #'mu4e-views-default-dom-filter))
     ;; remove src attributes unless they point to email attachments
     ((has-att n 'src) (mu4e-views-dom-remove-attr-and-map-children msg n 'src #'mu4e-views-default-dom-filter))
     ;; ((has-att n 'href) (mu4e-views-dom-remove-attr-and-map-children n 'href  #'mu4e-views-default-dom-filter))
     ;; remove all script tags
     ((is-a n 'script) nil)
     ;; otherwise search in children
     (t (recurse-children n)))))


;; ********************************************************************************
;; functions that replace mu4e functions and additional helper functions for
;; handling the mu4e header view windows
;;TODO check that the window size ratios are ok?
(defun mu4e-views-mu4e-header-and-view-windows-p ()
  "Check whether we are already showing the `mu4e-headers' and our view windows."
  (let ((have-header nil)
        (have-view nil)
        (other-buf nil)
        (is-view-p (plist-get (mu4e-views-get-current-viewing-method) :is-view-window-p))
        (header-buffer (mu4e-get-headers-buffer)))
    (mu4e-views-debug-log "CHECKING WHETHER WE HAVE THE CORRECT WINDOW LAYOUT\nVIEW WINDOW TEST FUNCTION <%s> ..." is-view-p)
    (if (eq (length (window-list)) 2)
        ;; we have two window check whether they are the correct ones
        (progn
          (cl-loop for w in (window-list) do
                   (let* ((buf (window-buffer w)))
                     (when (eq buf header-buffer)
                       (setq have-header t))
                     (when (funcall is-view-p w)
                       (setq have-view t))
                     (unless (or (eq buf header-buffer) (funcall is-view-p w))
                       (setq other-buf t))))
          (mu4e-views-debug-log "\t%s, because\n\t\theaders-window?: %s, view-window?: %s other windows present?: %s\n\t\twindows are %s" (if (and have-header have-view (not other-buf)) "YES" "NO") have-header have-view other-buf (window-list))
          (and have-header have-view (not other-buf)))
      ;; return nil if window list has not exactly 2 windows
      (mu4e-views-debug-log "\tdo not have 2 windows, but %s" (length (window-list)))
      nil)))

(defun mu4e-views-mu4e-view-window-p (&optional window)
  "Return t if WINDOW is the mu4e-views message window.

If WINDOW is omitted, then check for the current window. Use
`:is-view-window-p' of the current viewing method."
  (let ((is-view-p (plist-get (mu4e-views-get-current-viewing-method) :is-view-window-p))
        (thewindow (or window (selected-window))))
    (mu4e-views-debug-log "VIEW-WINDOW-P: the selected win %s ..." thewindow)
    (if (mu4e-views-mu4e-header-and-view-windows-p)
        (let ((isview (funcall is-view-p thewindow)))
          (mu4e-views-debug-log"\t%s %s the view window." thewindow (if isview "is" "isnot"))
	      isview)
      (mu4e-views-debug-log "\twe are not even in correct layout!")
      nil)))

(defun mu4e-views-get-view-win (&optional noerror)
  "Return window to use for `mu4e-views' viewing of emails.

If optional argument NOERROR is t then do not throw an error if
the window does not exist."
  (let (win
        (view-window-p (plist-get (mu4e-views-get-current-viewing-method) :is-view-window-p)))
    (cl-loop for w in (window-list) do
             (when (and (funcall view-window-p w) (window-valid-p w))
               (setq win w)))
    (if win
        win
      (unless noerror (error "View window not found in %s" (window-list))))))

(defun mu4e-views-get-view-window-maybe ()
  "Return view window if it exists."
  (mu4e-views-get-view-win t))

(defun mu4e-views-get-view-buffer ()
  "If view window exists return its buffer."
  (let ((win (mu4e-views-get-view-win t)))
    (when win (window-buffer win))))

(defun mu4e-views-headers-redraw-get-view-window ()
  "Unless we already have the correct window layout, rebuild it.

For that we close all windows, redraw the headers buffer based on
the value of `mu4e-split-view', and return a window for the
message view (if the current viewing method needs a window)."
  ;; if single is used then the headers buffer needs to be replaced
  (mu4e-views-debug-log "REDRAW WINDOWS IF NECESSARY")
  (let ((create-view-fun (plist-get (mu4e-views-get-current-viewing-method) :create-view-window)))
    ;; single window
    (when (eq mu4e-split-view 'single-window)
      (mu4e-views-debug-log "\twe are using SINGLE PANE")
      (let* ((win (selected-window))
             (viewwin (mu4e-views-get-view-win t))
             (usewin (if (and viewwin (window-live-p viewwin)) viewwin win)))
        (setq mu4e-views--view-window usewin)
        (setq mu4e~headers-view-win usewin)
        (when create-view-fun
          (mu4e-views-debug-log "\tCALL CREATE VIEW FUNCTION: %s" create-view-fun)
          (funcall create-view-fun viewwin))
        usewin))
    ;; if we have already the right setup, then just return the mu4e-views window
    (mu4e-views-debug-log "\twe are using MULTIPLE PANES")
    (if (mu4e-views-mu4e-header-and-view-windows-p)
        (progn
          (mu4e-views-debug-log "\tREUSE EXISTING WINDOW %s" (mu4e-views-get-view-win))
          (mu4e-views-get-view-win))
      ;; create the window
      (unless (buffer-live-p (mu4e-get-headers-buffer))
        (mu4e-error "\tNo headers buffer available"))
      (switch-to-buffer (mu4e-get-headers-buffer))
      (delete-other-windows)
      ;; get a new view window
      (let ((theviewwin (cond ((eq mu4e-split-view 'horizontal) ;; split horizontally
                               (split-window-vertically mu4e-headers-visible-lines))
                              ((eq mu4e-split-view 'vertical) ;; split vertically
                               (split-window-horizontally mu4e-headers-visible-columns)))))
        (mu4e-views-debug-log "\tWINDOW TO USE FOR VIEWING: %s\n\t\tall windows: %s" theviewwin (window-list))
        (setq mu4e-views--view-window theviewwin)
        (setq mu4e~headers-view-win theviewwin)
        ;; if viewing method provdes a setup method for the viewing window then call it
        (when create-view-fun
          (mu4e-views-debug-log "\tCALL CREATE VIEW FUNCTION: %s" create-view-fun)
          (funcall create-view-fun theviewwin))
        theviewwin))))

(defun mu4e-views-headers-redraw-get-view-buffer ()
  "Return the view buffer.

We redraw the view window if we do not have the correct layout."
  (window-buffer (mu4e-views-headers-redraw-get-view-window)))

(defun mu4e-views-select-other-view ()
  "Switch between headers and view window.

That is, if the headers view is selected, then select the message
view (if that has a live window), and vice versa."
  (interactive)
  (let* ((other-buf
          (cond
           ((eq major-mode 'mu4e-headers-mode)
            (window-buffer (mu4e-views-get-view-win t)))
           ((mu4e-views-mu4e-view-window-p)
            (mu4e-get-headers-buffer))))
         (other-win (and other-buf (get-buffer-window other-buf))))
    (if (window-live-p other-win)
        (select-window other-win)
      (mu4e-message "No window to switch to"))))

(defun mu4e-views-mu4e-headers-view-message ()
  "View message at point.

If there's an existing window for the view, re-use that one.  If
not, create a new one, depending on the value of
`mu4e-split-view': if it's a symbol `horizontal' or `vertical',
split the window accordingly; if it is nil, replace the current
window."
  (interactive)
  (unless (eq major-mode 'mu4e-headers-mode)
    (mu4e-error "Must be in mu4e-headers-mode (%S)" major-mode))
  (let* ((msg (mu4e-message-at-point))
         (docid (or (mu4e-message-field msg :docid)
                    (mu4e-warn "No message at point")))
         (decrypt (when (mu4e-views-mu4e-ver-< '(1 7))
                    (mu4e~decrypt-p msg)))
         (mark-as-read (when (mu4e-views-mu4e-ver->= '(1 5 3))
                         (if (functionp mu4e-view-auto-mark-as-read)
                             (funcall mu4e-view-auto-mark-as-read msg)
                           mu4e-view-auto-mark-as-read)))
         (verify  (not (and (boundp 'mu4e-view-use-gnus) mu4e-view-use-gnus))))
    (mu4e-views-debug-log "IN HEADERS VIEW selected message is %s" docid)
    (cond
     ((mu4e-views-mu4e-ver-< '(0 9 9)) (mu4e~proc-view docid mu4e-view-show-images))
     ((mu4e-views-mu4e-ver-<= '(1 3 9)) (mu4e~proc-view docid mu4e-view-show-images decrypt))
     ((mu4e-views-mu4e-ver-<= '(1 5 2)) (mu4e~proc-view docid mu4e-view-show-images decrypt verify))
     ((mu4e-views-mu4e-ver-< '(1 7)) (mu4e~proc-view docid mark-as-read decrypt verify))
     (t (mu4e--server-view docid mark-as-read)))))

(defun mu4e-views-view-current-msg-with-method (&optional method)
  "Takes `mu4e' message MSG as input and opens it with method METHOD."
  (interactive)
  (let ((m (or method (mu4e-views-completing-read
                       "Select view method: "
                       (mapcar (lambda (x) (car x)) mu4e-views-view-commands)
			           :sort t
			           :require-match t
			           :caller 'mu4e-views-view-current-msg-with-method))))
    (when mu4e-views--current-mu4e-message
      (mu4e-views-debug-log
       "VIEW CURRENT EMAIL WITH %s:\n\t%s"
       m
       (cdr (assoc m mu4e-views-view-commands)))
      (mu4e-views-view-msg-internal
       mu4e-views--current-mu4e-message
       (cdr (assoc m mu4e-views-view-commands))))))

(defun mu4e-views-mu4e-view-as-nonblocked-html ()
  "View current email using html-nonblocked method."
  (interactive)
  (mu4e-views-view-current-msg-with-method "html-nonblock"))

(defun mu4e-views-view-msg-internal (msg &optional viewmethod)
  "Replacement for `mu4e-view-msg-internal'.

Takes `mu4e' message MSG as input.  If VIEWMETHOD is provided,
then use this instead of the currently selected view method."
  (mu4e-views-debug-log "IN VIEW-MSG-INTERNAL!")
  (setq mu4e-views--one-time-viewing-method viewmethod)
  (when (mu4e-views-mu4e-ver-> '(1 8 0))
    (mu4e-views--extract-html-for-v18 msg))
  (let* ((method (mu4e-views-get-current-viewing-method))
         (viewfunc (plist-get method  :viewfunc))
         (only-msg (plist-get method :view-function-only-msg))
         (no-window (plist-get method :no-view-window))
         (html (mu4e-message-field msg :body-html))
	     (txt (mu4e-message-field msg :body-txt))
         (filter-pretermined (plist-member method :filter-html))
         (filter-html (when filter-pretermined (if (plist-get method :filter-html) t 0)))
         (filters (plist-get method :filters))
         htmlfile)
    (mu4e-views-debug-log "VIEW MESSAGE INTERNAL (%i [%s] FROM: %s SUBJECT: %s)\n\tuse view function: %s\n\tonly-msg: %s\n\tno-window: %s\n\tfilter-predetermined: %s, force-filtering/nofiltering: %s\n\tcustom-filters: %s"
                          (mu4e-message-field msg :docid)
                          (mu4e-message-field msg :message-id)
                          (mu4e-message-field msg :from)
                          (mu4e-message-field msg :subject)
                          viewfunc
                          only-msg
                          no-window
                          filter-pretermined
                          filter-html
                          filters)
    (mu4e-views-debug-log "================================================================================\nMESSAGE PLIST: %s\n================================================================================" msg)
    (unless only-msg
      ;; if there is a no content still show message for its metadata (e.g., only attachments)
	  (unless (or html txt)
	    (mu4e-views-debug-log "\tNo body part for this message")
        (setq txt "")));;FIXME what is the purpose of this, this does not do anything, need to deal in writing to HTML!
    ;; cleanup old message if it exists
    (when (and mu4e-views--current-mu4e-message
               (not (equal (mu4e-message-field mu4e-views--current-mu4e-message :docid) (mu4e-message-field msg :docid))))
      (mu4e-views--cleanup-message-datastructure mu4e-views--current-mu4e-message))
    ;; store message
	(setq mu4e-views--current-mu4e-message msg)
    (setq mu4e~view-message msg)
    (unless only-msg
	  (setq htmlfile (mu4e-views-mu4e~write-body-and-headers-to-html msg filter-html filters)))
    (if only-msg
        ;; only pass msg
        (funcall viewfunc msg (mu4e-views-headers-redraw-get-view-window))
      (if no-window
          ;; method does not use a window, do nothing
          (funcall viewfunc htmlfile msg)
        ;; method needs a window, reuse or create a new one, then switch to the
        ;; headers or view window based on
        ;; `mu4e-views-next-previous-message-behaviour'.
        (funcall viewfunc htmlfile msg (mu4e-views-headers-redraw-get-view-window))
        ;;(mu4e-views-headers-redraw-get-view-window)
        ))
    (mu4e-views-switch-to-right-window)))

(defun mu4e-views--cleanup-message-datastructure (msg)
  "Cleanup gnus datastructures we created for MSG."
  (when (plist-member msg :gnus-all-parts)
    (mm-destroy-parts (plist-get msg :gnus-all-parts))
    (cl-remf msg :gnus-all-parts)
    (cl-remf msg :gnus-attachments)
    (when (bufferp (plist-get msg :gnus-buffer))
      (kill-buffer (plist-get msg :gnus-buffer))
      (cl-remf msg :gnus-buffer))))

(when (mu4e-views-mu4e-ver-> '(1 7))
  (defun mu4e-views-compose (compose-type)
    "Start composing a message of COMPOSE-TYPE.
COMPOSE-TYPE is a symbol, one of `reply', `forward', `edit',
`resend' `new'. All but `new' take the message at point as input.
Symbol `edit' is only allowed for draft messages."
    (let ((msg (mu4e-views--message-at-point 'noerror)))
      ;; some sanity checks
      (unless (or msg (eq compose-type 'new))
        (mu4e-warn "No message at point"))
      (unless (member compose-type '(reply forward edit resend new))
        (mu4e-error "Invalid compose type '%S'" compose-type))
      (when (and (eq compose-type 'edit)
                 (not (member 'draft (mu4e-message-field msg :flags))))
        (mu4e-warn "Editing is only allowed for draft messages"))

      ;; 'new is special, since it takes no existing message as arg; therefore, we
      ;; don't need to involve the backend, and call the handler *directly*
      (if (eq compose-type 'new)
          (mu4e~compose-handler 'new)
        ;; otherwise, we need the doc-id
        (let* ((docid (mu4e-message-field msg :docid))
               ;; decrypt (or not), based on `mu4e-decryption-policy'.
               (decrypt
                (and (member 'encrypted (mu4e-message-field msg :flags))
                     (if (eq mu4e-decryption-policy 'ask)
                         (yes-or-no-p (mu4e-format "Decrypt message?"))
                       mu4e-decryption-policy))))
          ;; if there's a visible view window, select that before starting
          ;; composing a new message, so that one will be replaced by the compose
          ;; window. The 10-or-so line headers buffer is not a good place to write
          ;; it...
          (unless (eq mu4e-split-view 'single-window)
            (let ((viewwin (get-buffer-window (mu4e-get-view-buffer))))
              (when (window-live-p viewwin)
                (select-window viewwin))))
          ;; talk to the backend
          (mu4e--server-compose compose-type decrypt docid)))))

  (defun mu4e-views--message-at-point (&optional noerror)
    "Return the currently shown message.

Replaces `mu4e-message-at-point' to allow this to work in custom
view buffers."
    (or (cond
         ((eq major-mode 'mu4e-headers-mode) (get-text-property (point) 'msg))
         ((eq major-mode 'mu4e-view-mode) mu4e~view-message)
         ((mu4e-views-mu4e-view-window-p) mu4e~view-message))
        (unless noerror (mu4e-warn "No message at point")))))

(when (mu4e-views-mu4e-ver-> '(1 8))
  (defun mu4e-views--extract-html-for-v18 (msg)
    "Fetch the message as html and store in :body-html."
    (mu4e-views-debug-log "Use gnus to get message html body for: %s" msg)
    (let ((browse-url-browser-function (lambda (url &optional _rest)
                                         ;; (browse-url-default-browser (url-file-build-filename url) _rest))
                                         (with-temp-buffer
                                           (insert-file-contents-literally
                                            (url-file-build-filename url))
                                           (plist-put msg :body-html (buffer-substring-no-properties (point-min) (point-max)))))))
      (mu4e-views-create-gnus-all-parts-if-need-be msg)
      (let ((parts (plist-get msg :gnus-all-parts))
            header)
        (with-current-buffer (plist-get msg :gnus-buffer)
          (mu4e-views--extract-text-and-html-coding-from-gnus parts msg nil)
          (gnus-article-browse-html-parts parts header)))))

(defun mu4e-views--extract-text-and-html-coding-from-gnus (parts msg inmp)
  "Extract text parts from PARTS of message MSG."
  (plist-put msg :icals nil)
  (dolist (part parts)
    (cond
     ;; a text part
     ((and (listp part) (equal (car (mm-handle-type part)) "text/plain"))
      (let* ((type (mm-handle-type part))
             (charset (mu4e-views--convert-charset (mail-content-type-get type 'charset)))
             (encoding (mm-handle-encoding part))
             (txt (mm-get-part part)))
        (when encoding
          (if inmp
              (let ((buf))
                (with-current-buffer (mm-handle-buffer part)
                  (setq buf (buffer-string)))
                (with-temp-buffer
                  (insert buf)
                  (mm-decode-body charset encoding "text/plain")
                  (setq txt (buffer-string))))
            (save-restriction
              (save-restriction
	            (article-narrow-to-head)
	            (goto-char (point-max)))
              (forward-line 1)
              (save-restriction
	            (narrow-to-region (point) (point-max))
                (setq txt (buffer-string))))))
        (plist-put msg :body-txt (if (plist-member msg :body-txt)
                                     (concat (plist-get msg :body-txt)
                                             txt)
                                   txt))
        (plist-put msg :body-txt-coding charset)))
     ;; a calendar part
     ((and (listp part) (or (equal (car (mm-handle-type part)) "text/calendar")
                            (equal (car (mm-handle-type part)) "html/calendar")))
      (let ((ical (gnus-icalendar-event-from-handle part (gnus-icalendar-identities))))
        (mu4e-views-debug-log "Ical event: %s" (gnus-icalendar-event:summary ical))
        (plist-put msg :icals
                   (append `(,ical) (plist-get msg :icals)))))
     ;; an html part
     ((and (listp part) (equal (car (mm-handle-type part)) "text/html"))
      (let* ((type (mm-handle-type part))
             (charset (mu4e-views--convert-charset (mail-content-type-get type 'charset)))
             (encoding (mm-handle-encoding part)))
        ;; if there are multiple html parts with different codings use more specific encoding (currently only checks for ascii)
        (unless (and (plist-member msg :body-html-coding) (string-match-p ".*ascii.*" charset))
          (plist-put msg :body-html-coding charset))
        (when encoding (plist-put msg :body-transfer-coding encoding))))
     ;; recurse into multipart
     ((and (listp part) (equal (mm-handle-media-supertype part) "multipart"))
      (mu4e-views--extract-text-and-html-coding-from-gnus part msg t))
     ;; marker for multipart mixed
     ((and (stringp part) (string= part "multipart/mixed"))
      (setq inmp t)))))
  )

(defun mu4e-views--convert-charset (charset)
  "Translate email coding system CHARSET into Emacs coding system."
  (let* ((cs (or charset mu4e-views--default-coding-system))
         (downc (downcase cs))
         (fixed (or (alist-get downc mu4e-views--charset-translation)
                    downc)))
    (unless (coding-system-p (intern fixed))
      (warn "Unkown coding system %s in email" fixed)
      (setq fixed mu4e-views--default-coding-system))
    (mu4e-views-debug-log "translate coding system %s into %s" charset fixed)
    fixed))


(declare-function mu4e~view-gnus nil t nil)

(defun mu4e-views-mu4e-view (msg)
  "Used as a replacement for `mu4e-view' to view MSG in mu4e 1.5.x and above."
  (mu4e-views-debug-log "In advice for 1.5.x mu4e-view function")
  (mu4e~headers-update-handler msg nil nil)
  (if (mu4e-views-mu4e-ver-< '(1 7))
      (mu4e~view-gnus msg)
    (mu4e-views-view-msg-internal msg)))

(defun mu4e-views-switch-to-right-window ()
  "Switch to a different window.

The window to switch to is determined based on
`mu4e-views-next-previous-message-behaviour'."
  (if (plist-get mu4e-views--current-viewing-method :no-view-window)
      (mu4e-views-debug-log "SWITCH-TO-WINDOW: method without view window, do not attempt to switch.")
    (mu4e-views-debug-log "SWITCH-TO-WINDOW: behavior is %s currently on header? %s"
                          mu4e-views-next-previous-message-behaviour
                          mu4e-views--header-selected)
    ;; set view message in buffer shown in view window for mu4e methods
    (with-current-buffer (window-buffer (mu4e-views-get-view-win t))
      (setq mu4e~view-message mu4e-views--current-mu4e-message))
    ;; switch to header or view window based on what users wants
    (cl-case mu4e-views-next-previous-message-behaviour
      (stick-to-current-window (if mu4e-views--header-selected
                                   (select-window
                                    (get-buffer-window (mu4e-get-headers-buffer)))
                                 (let ((viewwin (mu4e-views-get-view-win t)))
                                   (when viewwin
                                     (select-window viewwin)))))
      (always-switch-to-view (select-window
                              (mu4e-views-get-view-win)))
      (always-switch-to-headers (mu4e~headers-select-window)))))

;; ********************************************************************************
;; functions for exporting email
(defun mu4e-views-export-email-dispatch (format msg file)
  "Dispatcher that exports MSG to FILE as FORMAT."
  (let ((exporter (alist-get format mu4e-views-export-alist)))
    (funcall exporter msg file)))

(defun mu4e-views-export-to-pdf (msg file)
  "Exports MSG to FILE as a pdf document."
  (let* ((html (mu4e-views-mu4e~write-body-and-headers-to-html msg -1 nil)))
    (mu4e-views--html-to-pdf html file)))

(defun mu4e-views-export-to-html (msg file)
  "Exports MSG to FILE as an html document."
  (let* ((html (mu4e-views-mu4e~write-body-and-headers-to-html msg -1 nil)))
    (copy-file html file)))

(defun mu4e-views-export-msg-action (msg &optional tofile export-format)
  "Export MSG to a file.

If TOFILE if non-nil, then export to this file instead of asking
for the file. If EXPORT-FORMAT is non-nil, then use this file
format."
  (let* ((format (or export-format
                     (mu4e-views-completing-read
                      "Select export file format: "
                      (--map (symbol-name (car it)) mu4e-views-export-alist)
                      :require-match t)))
         (formatsym (intern format))
         (default-file-name (concat
                             (replace-regexp-in-string "[^[:alnum:]_-]" "_"
                                                       (concat
                                                        (format-time-string (if (boundp 'mu4e-view-date-format)
                                                                                mu4e-view-date-format
                                                                              "%Y-%m-%d")
											                                (mu4e-message-field msg :date))
                                                        "_"
                                                        (if (mu4e-views-mu4e-ver-> '(1 8))
                                                            (plist-get (car (mu4e-message-field msg :from)) :name)
                                                          (caar (mu4e-message-field msg :from)))
                                                        "_"
                                                        (mu4e-message-field msg :subject)))
                             "."
                             format))
         (file-name (or tofile
                        (read-file-name
                         "Export to file: "
                         "~/Downloads/"
                         default-file-name
                         nil
                         default-file-name
                         (lambda (fname)
                           (and
                            (not (directory-name-p fname))
                            (string-suffix-p (concat "." format) fname)))))))
    (mu4e-views-export-email-dispatch formatsym msg file-name)))

(defun mu4e-views-forward-as-exported-attachment (msg)
  "Export this email MSG and forward the exported file as an attachment."
  (let ((file (make-temp-file "mu4e-views-export")))
    (mu4e-views-export-msg-action msg file)
    (mu4e-compose 'forward)
    ;;TODO add attachment
    ))

;; ********************************************************************************
;; helpers for mu4e-headers view.

;;;###autoload
(defun mu4e-views-mu4e-headers-windows-only ()
  "Show only the headers window of mu4e."
  (interactive)
  ;; delete other windows because otherwise mu4e will mess up and select the
  ;; header window for replacement.
  (switch-to-buffer (mu4e-get-headers-buffer))
  (delete-other-windows))

;;;###autoload
(defun mu4e-views-cursor-msg-view-window-down ()
  "Scroll message view down if we are viewing the message using xwidget-webkit."
  (interactive)
  (let* ((wind (other-window-for-scrolling))
		 (mode (with-selected-window wind major-mode)))
	(if (eq mode 'xwidget-webkit-mode)
		(with-selected-window wind
          (if (>= emacs-major-version 27)
		      (xwidget-webkit-scroll-up 100)
            (xwidget-webkit-scroll-up)))
	  (scroll-other-window 2))))

;;;###autoload
(defun mu4e-views-cursor-msg-view-window-up ()
  "Scroll message view up if we are viewing the message using xwidget-webkit."
  (interactive)
  (let* ((wind (other-window-for-scrolling))
		 (mode (with-selected-window wind major-mode)))
	(if (eq mode 'xwidget-webkit-mode)
		(with-selected-window wind
          (if (>= emacs-major-version 27)
		      (xwidget-webkit-scroll-down 100)
            (xwidget-webkit-scroll-down)))
	  (scroll-other-window -2))))

;;;###autoload
(defun mu4e-views-mu4e-headers-next (&optional n)
  "Move to next message in headers view.

If a xwidget message view is open then use that to show the
message.  With prefix argument move N steps instead."
  (interactive "P")
  (let ((step (or n 1)))
	(mu4e-views-mu4e-headers-move-wrapper step)))

;;;###autoload
(defun mu4e-views-mu4e-headers-prev (&optional n)
  "Move to previous message in headers view.

If a xwidget message view is open then use that to show the
message.  With prefix argument move N steps backwards instead."
  (interactive "P")
  (let ((step (* -1 (or n 1))))
	(mu4e-views-mu4e-headers-move-wrapper step)))

;;;###autoload
(defun mu4e-views-mu4e-headers-move (lines)
  "Move point LINES lines.
Forward (if LINES is positive) or backward (if LINES is negative).
If this succeeds, return the new docid.  Otherwise, return nil."
  (unless (eq major-mode 'mu4e-headers-mode)
    (mu4e-error "Must be in mu4e-headers-mode (%S)" major-mode))
  (let* ((_succeeded (zerop (forward-line lines)))
         (docid (mu4e~headers-docid-at-point)))
    (mu4e-views-debug-log "MOVE TO DOCID: %s" docid)
    ;; move point, even if this function is called when this window is not
    ;; visible
    (when docid
      ;; update all windows showing the headers buffer
      (walk-windows
       (lambda (win)
         (when (eq (window-buffer win) (mu4e-get-headers-buffer))
           (set-window-point win (point))))
       nil t)
      (if (eq mu4e-split-view 'single-window)
          (when (eq (window-buffer) (mu4e-get-view-buffer))
            (mu4e-headers-view-message))
        ;; update message view if it was already showing
        (when (and mu4e-split-view (mu4e-views-mu4e-header-and-view-windows-p) mu4e-views-auto-view-selected-message)
          (mu4e-headers-view-message)))
      ;; attempt to highlight the new line, display the message
      (mu4e~headers-highlight docid)
      docid)))

;;;###autoload
(defun mu4e-views-mu4e-headers-move-wrapper (n)
  "Move by N messages in the headers view.

Negative numbers move backwards. Record the window that we
started from to be able to respect
`mu4e-views-next-previous-message-behaviour'."
  (interactive)
  (mu4e-views-debug-log "MOVE-WARPPER\n\tinitiated from: %s\theader was selected? %s" (selected-window) (not (mu4e-views-mu4e-view-window-p (selected-window))))
  (setq mu4e-views--header-selected (not (mu4e-views-mu4e-view-window-p (selected-window))))
  (mu4e-views-debug-log "\t after call window was: %s is header %s" (selected-window) mu4e-views--header-selected)
  (with-current-buffer (mu4e-get-headers-buffer)
    (mu4e-views-mu4e-headers-move n)))

;; ********************************************************************************
;; helper function for accessing parts of an email. These can be bound by custom
;; mu4e-view modes.  These functions wrap `mu4e' functions and pass on our
;; saved message.

;;;###autoload
(defun mu4e-views-mu4e-extract-urls-from-msg (msg)
  "Prepare mu4e message data structure for MSG.
This data structure is used to support commands like browsing
urls in `mu4e-views' xwidget message view."
  (interactive)
  (unless (plist-member msg :body-urls)
    (let ((num 0)
          (urls nil))
      (with-temp-buffer
        (setq mu4e~view-link-map ;; buffer local
              (make-hash-table :size 32 :weakness nil))
        (insert-file-contents (lax-plist-get msg :html-file))
        (goto-char (point-min))
        (while (re-search-forward mu4e~view-beginning-of-url-regexp nil t)
          (let ((bounds (thing-at-point-bounds-of-url-at-point)))
            (when bounds
              (let* ((url (thing-at-point-url-at-point)))
                (puthash (cl-incf num) url mu4e~view-link-map)
                (push url urls))))))
      (lax-plist-put msg :body-urls urls))))

;;;###autoload
(defun mu4e-views-mu4e-select-url-from-message ()
  "Select a url from a mu4e message."
  (interactive)
  (mu4e-views-mu4e-extract-urls-from-msg mu4e-views--current-mu4e-message)
  (mu4e-views-completing-read "Select url: " ;; prompt
			                  (lax-plist-get
                               mu4e-views--current-mu4e-message
                               :body-urls)
			                  :action (lambda (x)
					                    (browse-url x))
			                  :sort t
			                  :require-match t
			                  :caller 'mu4e-views-mu4e-select-url-from-message))

;;;###autoload
(defun mu4e-views-mu4e-open-attachment (arg)
  "Select an attached from a mu4e message and open it.

If called with prefix ARG, then call method selected by the
user."
  (interactive "P")
  (let* ((attachments (mu4e-views-get-attachment-plists mu4e-views--current-mu4e-message))
		 (names (--map (mu4e-message-part-field it :name)
                       attachments)))
	(mu4e-views-completing-read "Select url: " ;; prompt
			                    names ;; collection to complete over
			                    :action (lambda (x)
                                          (mu4e-views--write-att-to-file-and-open x arg))
                                :sort t
			                    :require-match t
			                    :caller 'mu4e-views-mu4e-open-attachment)))

(defun mu4e-views--write-att-to-file-and-open (fname user-open-func)
  "Write attachment FNAME for current message to file and open it.

If USER-OPEN-FUNC is non-nil, then call function
`mu4e-views-file-open-function' to open it."
  (let* ((msg mu4e-views--current-mu4e-message)
         (index (mu4e-views--att-index-for-name fname)))
    (if (mu4e-views-mu4e-ver-< '(1 7))
		(mu4e-view-open-attachment
         mu4e-views--current-mu4e-message
         index)
      (mu4e-views-create-gnus-att-handles-need-be msg)
      (let ((fpath (mu4e-view-save-attachment-single msg index)))
        (if user-open-func
            (funcall mu4e-views-file-open-function fpath)
          (mu4e~view-open-file fpath nil))))))

(defun mu4e-views--att-index-for-name (fname &optional msg)
  "Return index of attachment FNAME for MSG.

If MSG is not provided then use `mu4e-views--current-mu4e-message'."
  (let* ((themsg (or msg mu4e-views--current-mu4e-message))
         (attachments (mu4e-views-get-attachment-plists themsg)))
    (->> attachments
         (--filter (string= (plist-get it :name) fname))
         (--map (plist-get it :attindex))
         (-first-item))))

(defun mu4e-views--att-name-for-index (index &optional msg)
  "Return file name of attachment at INDEX for MSG.

If MSG is not provided then use `mu4e-views--current-mu4e-message'."
  (let* ((themsg (or msg mu4e-views--current-mu4e-message))
         (attachments (mu4e-views-get-attachment-plists themsg)))
    (->> attachments
         (--filter (equal (plist-get it :attindex) index))
         (--map (plist-get it :name))
         (-first-item))))

;;;###autoload
(defun mu4e-views-mu4e-save-attachment ()
  "Select an attached from a mu4e message and save it."
  (interactive)
  (let* ((attachments (mu4e-views-get-attachment-plists))
         (names (--map (plist-get it :name) attachments))
         (name-to-index (--map (cons (plist-get it :name) (plist-get it :attindex)) attachments)))
	(mu4e-views-completing-read "Select attachment(s): " ;; prompt
			                    names ;; collection to complete over
			                    :action (lambda (x)
						                  ;; (let ((index (cdr (assoc x name-to-index))))
                                          (let ((index (cdr (assoc x name-to-index))))
						                    (mu4e-view-save-attachment-single
                                             mu4e-views--current-mu4e-message index)))
			                    :sort t
			                    :require-match t
			                    :caller 'mu4e-views-mu4e-save-attachment)))

;;;###autoload
(defun mu4e-views-mu4e-save-all-attachments ()
  "Save all attachments to a single directory chosen by the user."
  (interactive)
  (let* ((msg mu4e-views--current-mu4e-message)
		 (attachnums (sort (ht-keys mu4e~view-attach-map) '<))
		 (path (concat (mu4e~get-attachment-dir) "/"))
		 (attachdir (mu4e~view-request-attachments-dir path)))
	(dolist (num attachnums)
	  (let* ((att (mu4e~view-get-attach msg num))
			 (fname (plist-get att :name))
			 ;; (index (plist-get att :attindex))
			 (retry t)
			 fpath)
		(while retry
		  (setq fpath (expand-file-name (concat attachdir fname) path))
		  (setq retry
				(and (file-exists-p fpath)
					 (not (y-or-n-p
						   (mu4e-format "Overwrite '%s'?" fpath))))))
        (mu4e-views-mu4e-save-one-attachment-index msg num fpath)))))

;; get plists storing information for all attachments
(defun mu4e-views-get-attachment-plists (&optional msg)
  "Return plists storing information about each attachment of MSG."
  (let ((msg (or msg mu4e-views--current-mu4e-message)))
    (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by msg)
    (let* ((attachnames (mu4e-views-get-attachment-names msg))
           (attachments
            (--filter (member (plist-get it :name) attachnames)
                      (--map
                       (plist-put
                        (mu4e~view-get-attach mu4e-views--current-mu4e-message it)
                        :attindex it)
                       (ht-keys mu4e~view-attach-map)))))
      attachments)))

(defun mu4e-views-mu4e-save-one-attachment (msg file to-path)
  "Save attachment FILE from MSG to TO-PATH."
  ;; create attachment datastructures if need be
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by msg)
  (mu4e-views-mu4e-save-one-attachment-index
   msg
   (mu4e-views--att-index-for-name file)
   to-path))

(when (mu4e-views-mu4e-ver->= '(1 7))
  (defun mu4e-views-save-cid-content-to-html (msg cid filename)
    "Write CID content of MSG to temporary file FILENAME."
    (mu4e-views-create-gnus-att-handles-need-be msg)
    (mu4e-views-create-gnus-all-parts-if-need-be msg)
    (let ((parts (plist-get msg :gnus-all-parts))
          cid-file)
      (setq cid (mu4e-views--get-gnus-created-cid parts cid))
      (setq cid-file (concat temporary-file-directory "../"
	                         (gnus-article-browse-html-save-cid-content
	                          cid
	                          parts
	                          temporary-file-directory)))
      (copy-file cid-file filename t)))

  (defun mu4e-views--get-gnus-created-cid (handles cid)
    (save-match-data
      (let ((cidresult))
        (catch 'found
          (dolist (handle handles)
            (cond
             ((not (listp handle)))
	         ;; Exclude broken handles that `gnus-summary-enter-digest-group'
	         ;; may create.
	         ((not (or (bufferp (car handle)) (stringp (car handle)))))
             ;; multipart part
	         ((equal (mm-handle-media-supertype handle) "multipart")
	          (when (setq cidresult (mu4e-views--get-gnus-created-cid handle cid))
	            (throw 'found cidresult)))
             ;; found a cid part, check that it is the one
             ((string-prefix-p (concat "<" cid) (mm-handle-id handle))
              (setq cidresult (mm-handle-id handle))
              (setq cidresult  (substring cidresult 1 (1- (length cidresult))))
              (throw 'found cidresult))))))))

  )

(when (mu4e-views-mu4e-ver-< '(1 7))
  (defun mu4e-views-save-cid-content-to-html (msg cid filename)
    "Write CID content of MSG to temporary file FILENAME."
    (mu4e-views-mu4e-save-one-attachment msg cid filename)))

;; for 1.7 we need to defin some  function that got removed
(when (mu4e-views-mu4e-ver-< '(1 7))
  (defun mu4e-views-get-attachment-names (msg)
    "Return the names of all attachments for MSG."
    (let ((attnums (sort (ht-keys mu4e~view-attach-map) '<)))
      (--map (plist-get (mu4e~view-get-attach msg it) :name)
             attnums))))


(defun mu4e-views-mu4e-save-one-attachment-index (msg index to-path)
  "Save attachment with index INDEX from MSG to TO-PATH."
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by msg)
  (if (mu4e-views-mu4e-ver-< '(1 7))
      ;; pre 1.7
	  (mu4e~proc-extract
	   'save (mu4e-message-field msg :docid)
	   index mu4e-decryption-policy to-path)
    ;; post 1.7
    ;; create the handles if we have done so already
    (mu4e-views-create-gnus-att-handles-need-be msg)
    (let ((handles (plist-get msg :gnus-attachments))
          (file (mu4e-views--att-name-for-index index)))
      (unless (member file (mapcar (lambda (x) (car x)) handles))
        (error "Email has no attachment %s" file))
      (cl-loop for (f . h) in handles
    	       when (member f `(,file))
    	       do (mm-save-part-to-file
    	           h
    		       (if (file-exists-p to-path)
    		           (let (newname (count 1))
    			         (while (and
    				             (setq newname
    				                   (concat
    					                (file-name-sans-extension to-path)
    					                (format "(%s)" count)
    					                (file-name-extension to-path t)))
    				             (file-exists-p newname))
    			           (cl-incf count))
    			         newname)
    		         to-path))))))

(defun mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by (msg)
  "Call the `mu4e' function to setup the attachments hash-map for MSG.

The function we are using is
`mu4e~view-construct-attachments-header' or `gnus' for mu4e
version 1.7+. Only do this if we have not already done this for
this message. We record this in a message property:
`:attachment-setup'."
  (unless (plist-member msg :attachment-setup)
	(mu4e~view-construct-attachments-header msg)
	(lax-plist-put msg :attachment-setup t)))

;; ********************************************************************************
;; 1.7 workaround hacks for attachments
(when (mu4e-views-mu4e-ver->= '(1 7))
  (defun mu4e-views-create-gnus-att-handles-need-be (msg)
    "Create data structures that gnus needs to store attachments.

Cache these datastructures so we do not recreate them everytime
we do something with an attachment."
    (unless (lax-plist-get msg :gnus-attachments)
      (mu4e-views-create-gnus-all-parts-if-need-be msg)
      (let* ((parts (plist-get msg :gnus-all-parts)) ;;(mu4e~view-gather-mime-parts))
	         (handles '()))
        (setq handles (mu4e-views--extract-attachment-parts parts))
        (lax-plist-put msg :attachment-setup t)
        (lax-plist-put msg :gnus-msg-parts parts)
        (lax-plist-put msg :gnus-attachments handles)
        (mu4e-views-debug-log "Gnu message parts: %s\nAttachment handles: %s" parts handles))))

  (defun mu4e-views--extract-attachment-parts (parts)
    "Determine which message PARTS are "
    (let ((attachments))
      (dolist (part parts)
        (mu4e-views-debug-log "Process part: %s" part)
        (when (listp part)
          (cond ((equal (mm-handle-media-supertype part) "multipart")
                 (mu4e-views-debug-log "Part %s is multipart, recurse" part)
                 (setq attachments (append attachments (mu4e-views--extract-attachment-parts part))))
                (t (let ((fname (or (cdr (assoc 'filename (assoc "attachment" part)))
                                    (cdr (assoc 'filename (assoc "inline" part)))
                                    (cl-loop for item in part
                                             for name = (and (listp item)
	  				                                         (assoc-default 'name item))
                                             thereis (and (stringp name) name)))))
	                 (when fname
                       (mu4e-views-debug-log "Part %s is an attachment" part)
	                   (push `(,fname . ,part) attachments)))))))
      attachments))

  (defun mu4e-views-create-gnus-all-parts-if-need-be (msg)
    "Extract all message parts including inline images from MSG using gnus.

Used to insert inline content into html message and for
extracting attachments."
    (unless (plist-member msg :gnus-all-parts)
      (let* ((gnusbufname (make-temp-name "gnus-part-extraction-"))
             (gnusbuf (get-buffer-create gnusbufname)))
        (with-current-buffer gnusbuf
          (insert-file-contents-literally
           (mu4e-message-readable-path msg) nil nil nil t)
          (run-hooks 'gnus-article-decode-hook)
          (let ((parts (mm-dissect-buffer t t)))
            ;; If singlepart, enforce a list.
            (when (and (bufferp (car parts))
		               (stringp (car (mm-handle-type parts))))
	          (setq parts (list parts)))
            (lax-plist-put msg :gnus-all-parts parts)
            (plist-put msg :gnus-buffer gnusbuf))))))

  (defun mu4e-views-get-attachment-names (msg)
    "Return names of attachments for MSG.

We use the previous mu4e method for this, but if we have already
created the data structures for it (which is expensive), use the
gnus method instead."
    ;; initialize attachment data structure if need be
    (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by msg)
    ;; use gnus attachments if we have created them already, but since this is
    ;; expensive fallback to old mu4e method if not
    (if (plist-get msg :gnus-attachments)
        (--map (car it) (lax-plist-get msg :gnus-attachments))
      (let ((attnums (sort (ht-keys mu4e~view-attach-map) '<)))
        (--map (plist-get (mu4e~view-get-attach msg it) :name)
               attnums))))

  (defun mu4e~get-attachment-dir (&optional fname mimetype)
    "Get the directory for saving attachments from
`mu4e-attachment-dir' (which can be either a string or a function,
see its docstring)."
    (let
        ((dir
          (cond
           ((stringp mu4e-attachment-dir)
            mu4e-attachment-dir)
           ((functionp mu4e-attachment-dir)
            (funcall mu4e-attachment-dir fname mimetype))
           (t
            (mu4e-error "Unsupported type for mu4e-attachment-dir")))))
      (if dir
          (expand-file-name dir)
        (mu4e-error "Mu4e-attachment-dir evaluates to nil"))))

  (unless (fboundp 'mu4e-message-readable-path)
    (defun mu4e-message-readable-path (&optional msg)
      "Get a readable path to MSG or raise an error.
If MSG is nil, use `mu4e-message-at-point'."
      (let ((path (plist-get (or msg (mu4e-message-at-point)) :path)))
        (unless (file-readable-p path)
          (mu4e-error "No readable message at %s; database outdated?" path))
        path)))

  (defun mu4e~view-request-attachments-dir (path)
    "Ask the user where to save multiple attachments (default is PATH)."
    (let ((fpath (expand-file-name
                  (read-directory-name
                   (mu4e-format "Save in directory ")
                   path nil nil nil) path)))
      (if (file-directory-p fpath)
          fpath)))

  (defun mu4e~view-request-attachment-path (fname path)
    "Ask the user where to save FNAME (default is PATH/FNAME)."
    (let ((fpath (expand-file-name
                  (read-file-name
                   (mu4e-format "Save as ")
                   path nil nil fname) path)))
      (if (file-directory-p fpath)
          (expand-file-name fname fpath)
        fpath)))

  (defun mu4e-view-save-attachment-single (msg attnum)
    (let* ((msg (or msg (mu4e-message-at-point)))
           (att (mu4e~view-get-attach msg attnum))
           (fname  (plist-get att :name))
           (mtype  (plist-get att :mime-type))
           (path (concat
                  (mu4e~get-attachment-dir fname mtype) "/"))
           (retry t) (fpath))
      (while retry
        (setq fpath (mu4e~view-request-attachment-path fname path))
        (setq retry
              (and (file-exists-p fpath)
                   (not (y-or-n-p (mu4e-format "Overwrite '%s'?" fpath))))))
      (mu4e-views-mu4e-save-one-attachment msg fname fpath)
      fpath)))

;;;###autoload
(defun mu4e-views-mu4e-view-open-attachment (arg)
  "Wraps the `mu4e-view-open-attachment' function.

Passes on the message stored in
`mu4e-views--current-mu4e-message'. If called with prefix ARG,
then apply user-define function to open the attachment."
  (interactive "P")
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by
   mu4e-views--current-mu4e-message)
  (mu4e-views-mu4e-open-attachment arg))

;;;###autoload
(defun mu4e-views-mu4e-view-go-to-url ()
  "Wraps the `mu4e-view-go-to-url' function.

Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-views-mu4e-select-url-from-message))

;;;###autoload
(defun mu4e-views-mu4e-view-save-url ()
  "Wraps the `mu4e-view-save-url' function.

 Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-view-save-url mu4e-views--current-mu4e-message))

;;;###autoload
(defun mu4e-views-mu4e-view-save-attachment ()
  "Wraps the `mu4e-save-attachment' function.

 Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by
   mu4e-views--current-mu4e-message)
  (mu4e-views-mu4e-save-attachment))

;;;###autoload
(defun mu4e-views-mu4e-view-save-all-attachments ()
  "Wraps function to save all attachments using `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-views-mu4e-create-mu4e-attachment-table-if-need-by
   mu4e-views--current-mu4e-message)
  (mu4e-views-mu4e-save-all-attachments))

;;;###autoload
(defun mu4e-views-mu4e-view-action ()
  "Wraps the `mu4e-view-action' function.

Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-view-action mu4e-views--current-mu4e-message))

;;;###autoload
(defun mu4e-views-mu4e-view-fetch-url ()
  "Wraps the `mu4e-view-fetch-url' function.

Passes on the message stored in `mu4e-views--current-mu4e-message'."
  (interactive)
  (mu4e-view-fetch-url mu4e-views--current-mu4e-message))

(defun mu4e-views-view-prev-or-next-unread (backwards)
  "Move point to the next or previous unread message.

The direction is determined by BACKWARDS.  This is done in the
headers buffer connected with this message view.  If this
succeeds, return the new docid.  Otherwise, return nil."
  (setq mu4e-views--header-selected (not (mu4e-views-mu4e-view-window-p (selected-window))))
  (when (not mu4e-views--header-selected)
    (mu4e~view-in-headers-context
     (mu4e~headers-prev-or-next-unread backwards))
    (with-current-buffer (mu4e-get-headers-buffer)
      (mu4e-headers-view-message))))

(defun mu4e-views--xwidget-callback-if-is-at-bottom (callback)
  "Check whether the xwidget buffer is at the end of a message.

For that run javascript code in xwidgets webkit buffer to
determine whether we are currently at the end of the currently
shown email (html document). The result of this test if passed to
function CALLBACK."
  (xwidget-webkit-execute-script
   (xwidget-webkit-current-session)
   "(function() {
        if((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
          return \"TRUE\"
        }
        else {
          return \"FALSE\"
        }
      })()"
   callback))

(defun mu4e-views-scroll-up-or-next ()
  "Wrapper around mu4e method for scrolling down and jumping to next mail.

 This method scrolls down or if we reached the end of the email
 moves to the next email. For xwidgets we have to use javascript
 to detect when we reached the end."
  (interactive)
  (let ((is-xwidget (pcase (mu4e-views--get-current-viewing-method-name)
                      ("html" t)
                      ("html-block" t)
                      ("html-nonblock" t)
                      (_ nil)))
        (is-mu4e-view (pcase (mu4e-views--get-current-viewing-method-name)
                        ("text" t)
                        ("gnus" t)
                        (_ nil))))
    ;; in xwidgets window using xwidgets scroll method and jump to next message if we reached end
    (cond
     (is-xwidget
      (mu4e-views--xwidget-callback-if-is-at-bottom
       (lambda (res) (if (string-equal res "TRUE")
                         (when mu4e-view-scroll-to-next
                           (mu4e-view-headers-next))
                       (xwidget-webkit-scroll-up)))))
     (is-mu4e-view
      (mu4e-view-scroll-up-or-next))
     (t
      (scroll-up)))))

;; ********************************************************************************
;; Minor mode that bounds keys to access mu4e email actions like saving attachments.
;; create a custom keymap for mu4e-views-view-actions-mode-map
(defvar mu4e-views-view-actions-mode-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "$") #'mu4e-show-log)
    (define-key km (kbd ";") #'mu4e-context-switch)
    (define-key km (kbd "<") #'beginning-of-buffer)
    (define-key km (kbd ">") #'end-of-buffer)
    (define-key km (kbd "B") #'mu4e-headers-search-bookmark-edit)
    (define-key km (kbd "E") #'mu4e-views-mu4e-view-save-all-attachments)
    (define-key km (kbd "F") #'mu4e-compose-forward)
    (define-key km (kbd "H") #'mu4e-display-manual)
    (define-key km (kbd "R") #'mu4e-compose-reply)
    (define-key km (kbd "[") #'mu4e-view-headers-prev-unread)
    (define-key km (kbd "]") #'mu4e-view-headers-next-unread)
    (define-key km (kbd "a") #'mu4e-views-mu4e-view-action)
    (define-key km (kbd "e") #'mu4e-views-mu4e-view-save-attachment)
    (define-key km (kbd "f") #'mu4e-views-mu4e-view-fetch-url)
    (define-key km (kbd "g") #'mu4e-views-mu4e-view-go-to-url)
    (define-key km (kbd "k") #'mu4e-views-mu4e-view-save-url)
    (define-key km (kbd "i") #'mu4e-views-mu4e-view-as-nonblocked-html)
    (define-key km (kbd "n") #'mu4e-views-mu4e-headers-next)
    (define-key km (kbd "o") #'mu4e-views-mu4e-view-open-attachment)
    (define-key km (kbd "p") #'mu4e-views-mu4e-headers-prev)
    (define-key km (kbd "q") #'mu4e-views-mu4e-headers-windows-only)
    (define-key km (kbd "y") #'mu4e-views-select-other-view)
    (define-key km (kbd "!") #'mu4e-view-mark-for-read)
    (define-key km (kbd "%") #'mu4e-view-mark-pattern)
    (define-key km (kbd "&") #'mu4e-view-mark-custom)
    (define-key km (kbd "*") #'mu4e-view-mark-for-something)
    (define-key km (kbd "+") #'mu4e-view-mark-for-flag)
    (define-key km (kbd "-") #'mu4e-view-mark-for-unflag)
    (define-key km (kbd "/") #'mu4e-view-search-narrow)
    (define-key km (kbd "?") #'mu4e-view-mark-for-unread)
    (define-key km (kbd "B") #'mu4e-headers-search-bookmark-edit)
    (define-key km (kbd "O") #'mu4e-headers-change-sorting)
    (define-key km (kbd "P") #'mu4e-headers-toggle-threading)
    (define-key km (kbd "Q") #'mu4e-headers-toggle-full-search)
    (define-key km (kbd "S") #'mu4e-view-search-edit)
    (define-key km (kbd "T") #'mu4e-view-mark-thread)
    (define-key km (kbd "W") #'mu4e-headers-toggle-include-related)
    (define-key km (kbd "b") #'mu4e-headers-search-bookmark)
    (define-key km (kbd "d") #'mu4e-view-mark-for-trash)
    (define-key km (kbd "j") #'mu4e~headers-jump-to-maildir)
    (define-key km (kbd "m") #'mu4e-view-mark-for-move)
    (define-key km (kbd "r") #'mu4e-view-mark-for-refile)
    (define-key km (kbd "s") #'mu4e-headers-search)
    (define-key km (kbd "t") #'mu4e-view-mark-subthread)
    (define-key km (kbd "v") #'mu4e-view-verify-msg-popup)
    (define-key km (kbd "x") #'mu4e-view-marked-execute)
    (define-key km (kbd "SPC") #'mu4e-views-scroll-up-or-next)
    km)
  "The keymap for `Mu4e-views-view-actions-mode'.")

;; create a minor mode mainly for custom keys
(define-minor-mode mu4e-views-view-actions-mode
  "Minor mode for setting up keys when viewing a mu4e email in a mu4e-views window."
  ;; The initial value - Set to 1 to enable by default
  :init-value nil
  ;; The indicator for the mode line.
  :lighter " M4"
  ;; The minor mode keymap
  :keymap mu4e-views-view-actions-mode-map
  ;; Make mode global rather than buffer local
  :global nil)

;; Register the minor mode with `xwidgets-reuse' so that it is automatically
;; turned of if the xwidget session is reused for a different purpose.
(xwidgets-reuse-register-minor-mode 'mu4e-views-view-actions-mode)

;; function to select how to view emails
;;;###autoload
(defun mu4e-views-mu4e-select-view-msg-method ()
  "Select the method for viewing emails in `mu4e'."
  (interactive)
  (mu4e-views-completing-read "Select method for viewing mail: " ;; prompt
                              ;; collection to complete over
			                  (mapcar (lambda (x) (car x)) mu4e-views-view-commands)
			                  :action (lambda (x)
					                    (mu4e-views-mu4e-use-view-msg-method x))
			                  :sort t
			                  :require-match t
                              :history 'mu4e-views--mu4e-select-view-msg-method-history
			                  :caller 'mu4e-views-mu4e-select-view-msg-method))

;;;###autoload
(defun mu4e-views-toggle-auto-view-selected-message ()
  "Toggle automatic viewing of message when moving around in the mu4e-headers view."
  (interactive)
  (setq mu4e-views-auto-view-selected-message
        (not mu4e-views-auto-view-selected-message)))

;; replacement for mu4e's function in 1.6.0 that removes linebreaks
(unless (mu4e-views-mu4e-ver-< '(1 5))
  (defun mu4e-views-mu4e-message-outlook-cleanup (_msg body)
    "Clean-up MSG's BODY.
Esp. MS-Outlook-originating message may not advertise the correct
encoding (e.g. 'iso-8859-1' instead of 'windows-1252'), thus
giving us these funky chars. here, we either remove them, or
replace with."
    (with-temp-buffer
      (insert body)
      (goto-char (point-min))
      (while (re-search-forward "[\015 ]" nil t)
        (replace-match
         (cond
          ((string= (match-string 0) "") "'")
          ((string= (match-string 0) " ") " ")
          (t ""))))
      (buffer-string))))

;;;###autoload
(defun mu4e-views-unload-function ()
  "Uninstalls the advices on mu4e functions created by mu4e-views."
  (interactive)
  (mu4e-views-debug-log "Uninstall mu4e advice")
  (mu4e-views-advice-unadvice 'mu4e~view-internal)
  (unless (mu4e-views-mu4e-ver-<= '(1 4 99))
    (mu4e-views-advice-unadvice #'mu4e~view-old)
    (mu4e-views-advice-unadvice #'mu4e-view)
    (mu4e-views-advice-unadvice #'mu4e-message-outlook-cleanup))
  (mu4e-views-advice-unadvice #'mu4e-headers-view-message)
  (mu4e-views-advice-unadvice #'mu4e~headers-move)
  (mu4e-views-advice-unadvice #'mu4e-select-other-view)
  (mu4e-views-advice-unadvice #'mu4e-view-headers-next)
  (mu4e-views-advice-unadvice #'mu4e-view-headers-previous)
  (mu4e-views-advice-unadvice #'mu4e~view-gnus)
  (mu4e-views-advice-unadvice #'mu4e-get-view-buffer)
  (mu4e-views-advice-unadvice #'mu4e~view-prev-or-next-unread)
  (mu4e-views-advice-unadvice #'mu4e-message-at-point)
  (mu4e-views-advice-unadvice #'mu4e-views-compose)
  (setq mu4e-views--advice-installed nil))

(defun mu4e-views-advice-mu4e ()
  "Advice mu4e functions used by mu4e-views to overwrite its functionality."
  (mu4e-views-debug-log "Install mu4e advice for mu version %s" mu4e-mu-version)
  ;; in all cases
  (advice-add 'mu4e~view-internal
              :override #'mu4e-views-view-msg-internal)
  ;; only for 1.5 and above
  (unless (mu4e-views-mu4e-ver-<= '(1 4 99))
    (advice-add 'mu4e~view-old
                :override #'mu4e-views-view-msg-internal)
    ;; for 1.5 and above avoid complaint about old and gnus to being loaded
    (advice-add 'mu4e-view
                :override #'mu4e-views-mu4e-view)
    (advice-add 'mu4e-message-outlook-cleanup
                :override #'mu4e-views-mu4e-message-outlook-cleanup))
  (advice-add 'mu4e-headers-view-message
              :override #'mu4e-views-mu4e-headers-view-message)
  (advice-add 'mu4e~headers-move
              :override #'mu4e-views-mu4e-headers-move-wrapper)
  (advice-add 'mu4e-select-other-view
              :override #'mu4e-views-select-other-view)
  (advice-add 'mu4e-view-headers-next
              :override #'mu4e-views-mu4e-headers-next)
  (advice-add 'mu4e-view-headers-previous
              :override #'mu4e-views-mu4e-headers-prev)
  ;; only advice gnus function if it exists
  (when (mu4e-views-mu4e-ver-< '(1 7))
    (advice-add 'mu4e~view-gnus
                :override #'mu4e-views-view-msg-internal))
  (advice-add 'mu4e-get-view-buffer
              :override #'mu4e-views-get-view-buffer)
  (advice-add 'mu4e~view-prev-or-next-unread
              :override #'mu4e-views-view-prev-or-next-unread)
  (when (mu4e-views-mu4e-ver-> '(1 7))
    (advice-add 'mu4e-compose
                :override #'mu4e-views-compose))
  (setq mu4e-views--advice-installed t))

(unless mu4e-views--advice-installed
  (mu4e-views-advice-mu4e))

(provide 'mu4e-views)
;;; mu4e-views.el ends here
