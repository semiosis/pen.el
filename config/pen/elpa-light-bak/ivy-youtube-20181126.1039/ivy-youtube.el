;;; ivy-youtube.el --- Query YouTube and play videos in your browser

;; Copyright (C) 2017 Brunno dos Santos

;; Author: Brunno dos Santos
;; Version: 0.3.1
;; Package-Version: 20181126.1039
;; Package-Commit: 849b6db7ef02b080a86c1b887488e2935c31059a
;; Package-Requires: ((request "0.2.0") (ivy "0.8.0") (cl-lib "0.5"))
;; URL: https://github.com/squiter/ivy-youtube
;; Created: 2017-Jan-02
;; Keywords: youtube, multimedia, mpv, vlc

;;; Commentary:

;; This package provides an interactive prompt to search
;; youtube as you code :)

;; This package was based on Maximilian Roquemore's package called
;; helm-youtube.  You can find the original code in:
;; https://github.com/maximus12793/helm-youtube

;; Thank you Maximilian to create this awesome package.

;;; MIT License
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Code:

(require 'cl-lib)
(require 'ivy)
(require 'request)
(require 'json)

(defgroup ivy-youtube nil
  "Ivy-youtube settings."
  :group 'tools)

(defcustom ivy-youtube-key nil
  "Your Google API key.";; INSERT YOUR KEY FROM GOOGLE ACCOUNT!!!
  :type '(string)
  :group 'ivy-youtube)

(defcustom ivy-youtube-play-at "browser"
  "Where do you want to play the video.  You can set browser or process."
  :type '(string)
  :group 'ivy-youtube-play-at)

(defcustom ivy-youtube-history-file (format "%sivy-youtube-history" user-emacs-directory)
  "History file for your searches.

If nil then don't keep a search history"
  :type '(string)
  :group 'ivy-youtube)

(defcustom ivy-youtube-max-results 50
  "The max amount of results displayed after search

Increasing this value too much might result in getting connection errors"
  :type '(integer)
  :group 'ivy-youtube)

(defun ivy-youtube-read-lines (filePath)
  "Return a list of lines of a file at FILEPATH."
  (with-temp-buffer
    (insert-file-contents filePath)
    (split-string (buffer-string) "\n" t)))

(defun ivy-youtube-history-list ()
  "Return a list with content of file or an empty list."
  (if (and ivy-youtube-history-file (file-readable-p ivy-youtube-history-file))
      (ivy-youtube-read-lines ivy-youtube-history-file)
    '()))

;;;###autoload
(defun ivy-youtube ()
  (interactive)
  (unless ivy-youtube-key
    (error "You must set `ivy-youtube-key' to use this command"))
  (request
   "https://www.googleapis.com/youtube/v3/search"
   :params `(("part" . "snippet")
	     ("q" . ,(ivy-youtube-search))
	     ("type" . "video")
	     ("maxResults" . ,(int-to-string ivy-youtube-max-results))
	     ("key" .  ,ivy-youtube-key));; <--- GOOGLE API KEY
   :parser 'json-read
   :success (cl-function
	     (lambda (&key data &allow-other-keys)
	       (ivy-youtube-wrapper data)));;function
   :status-code '((400 . (lambda (&rest _) (message "Got 400.")))
		  ;; (200 . (lambda (&rest _) (message "Got 200.")))
		  (418 . (lambda (&rest _) (message "Got 418.")))
                  (403 . (lambda (&rest _)
                           (message "403: Unauthorized. Maybe you need to enable your youtube api key"))))
   :complete (message "searching...")))

(defun ivy-youtube-tree-assoc (key tree)
  "Build the tree-assoc from KEY TREE for youtube query."
  (when (consp tree)
    (cl-destructuring-bind (x . y)  tree
      (if (eql x key) tree
	(or (ivy-youtube-tree-assoc key x) (ivy-youtube-tree-assoc key y))))))

(defun ivy-youtube-playvideo (video-url)
  "Play the video based on users choice."
  (cond ((equal ivy-youtube-play-at "browser")
         (ivy-youtube-play-on-browser video-url))
        ((equal ivy-youtube-play-at nil)
         (ivy-youtube-play-on-browser video-url))
        ((equal ivy-youtube-play-at "")
         (ivy-youtube-play-on-browser video-url))
        (t (ivy-youtube-play-on-process video-url))))

(defun ivy-youtube-play-on-browser (video-url)
  "Open your browser with VIDEO-URL."
  (message "Opening your video on browser...")
  (browse-url video-url))

(defun ivy-youtube-play-on-process (video-url)
  "Start a process based on ivy-youtube-play-at variable passing VIDEO-URL."
  (message (format "Starting a process with: [%s %s]" ivy-youtube-play-at video-url))
  (make-process :name "Ivy Youtube"
                :buffer "*Ivy Youtube Output*"
                :sentinel (lambda (process event)
                            (message
                             (format "Ivy Youtube: Process %s (Check buffer *Ivy Youtube Output*)" event)))
                :command `(,ivy-youtube-play-at ,video-url)))

(defun ivy-youtube-build-url (video-id)
  "Create a usable youtube URL with VIDEO-ID."
  (concat "http://www.youtube.com/watch?v=" video-id))

(defun ivy-youtube-wrapper (*qqJson*)
  "Parse the json provided by *QQJSON* and provide search result targets."
  (let (results '())
    (let ((search-results (cdr (ivy-youtube-tree-assoc 'items *qqJson*))))
      (dotimes (i (length search-results))
	(push  (cons (cdr (ivy-youtube-tree-assoc 'title (aref search-results i)))
		     (cdr (ivy-youtube-tree-assoc 'videoId (aref search-results i))))
	       results)))
    (ivy-read "Youtube Search Results"
              (reverse results)
              :action (lambda (cand)
                        (ivy-youtube-playvideo (ivy-youtube-build-url (cdr cand)))))))

(defun ivy-youtube-search ()
  "Use ivy-read to select your search history."
  (ivy-read "Search YouTube: "
            (ivy-youtube-history-list)
            :action (lambda (cand)
                      (ivy-youtube-append-history cand))))

(defun ivy-youtube-append-history (candidate)
  "Save the new CANDIDATE to the history file."
  (if ivy-youtube-history-file
      (let* ((history-words (ivy-youtube-history-list))
	     (history-words-with-candidate (add-to-list 'history-words candidate))
	     (unique-words (delq nil (delete-dups history-words-with-candidate))))
	(write-region (mapconcat 'identity unique-words "\n") nil ivy-youtube-history-file nil))))

(provide 'ivy-youtube)

;; Local Variables:
;; End:

;;; ivy-youtube.el ends here
