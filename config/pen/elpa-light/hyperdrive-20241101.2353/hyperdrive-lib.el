;;; hyperdrive-lib.el --- Library functions and structures  -*- lexical-binding: t; -*-

;; Copyright (C) 2023, 2024  USHIN, Inc.

;; Author: Adam Porter <adam@alphapapa.net>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; Affero General Public License for more details.

;; You should have received a copy of the GNU Affero General Public
;; License along with this program. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'map)
(require 'pcase)
(require 'seq)
(require 'url-util)
(require 'gv)

(require 'compat)
(require 'persist)
(require 'plz)
(require 'transient)

(require 'hyperdrive-vars)

;;;; Declarations

(declare-function h/mode "hyperdrive")
(declare-function h/dir-mode "hyperdrive-dir")

;;;; Errors

(define-error 'h/error "hyperdrive error")

(defun h/error (&rest args)
  "Like `error', but signals `hyperdrive-error'.
Passes ARGS to `format-message'."
  (signal 'h/error (list (apply #'format-message args))))

;;;; Structs

(cl-defstruct (hyperdrive-entry (:constructor he//create)
                                (:copier nil))
  "Represents an entry in a hyperdrive."
  (hyperdrive nil :documentation "The entry's hyperdrive.")
  ;; Rather than storing just the path and making a function to return
  ;; the name, we store the name as-is because, for one thing, the name
  ;; could theoretically contain a slash, and `file-name-nondirectory'
  ;; would return the wrong value in that case.
  (name nil :documentation "URL-decoded filename of entry without leading slash.")
  (path nil :documentation "URL-decoded path with leading slash.")
  (headers nil :documentation "HTTP headers from request.")
  (mtime nil :documentation "Last modified time.")
  (size nil :documentation "Size of file.")
  (version nil :documentation "Hyperdrive version specified in entry's URL.")
  (type nil :documentation "MIME type of the entry.")
  ;; TODO: Consider adding gv-setters for etc slot keys
  (etc nil :documentation "Alist for extra data about the entry.
- display-name :: Displayed in directory view instead of name.
- target :: Link fragment to jump to.
- block-length :: Number of blocks file blob takes up.
- block-length-downloaded :: Number of blocks downloaded for file.
- existsp :: Whether entry exists at its version.
- next-version-exists-p :: Whether or not the next version exists.
  + t :: next version range exists
  + nil :: next version range does not exist
  + \\+`unknown' :: next version range existence is not known
- next-version-number :: Start of next range or nil if latest.
- previous-version-exists-p :: Whether or not the previous version exists.
  + t :: previous version range exists
  + nil :: previous version range does not exist
  + \\+`unknown' :: previous version range existence is not known
- previous-version-number :: Start of previous range."))

(cl-defstruct (hyperdrive (:constructor h/create)
                          (:copier nil))
  "Represents a hyperdrive."
  (public-key nil :documentation "Hyperdrive's public key.")
  (seed nil :documentation "Seed (always and only present for writable hyperdrives).")
  (writablep 'unknown :documentation "Whether the drive is writable.")
  (petname nil :documentation "Petname.")
  ;; TODO: Where to invalidate old domains?
  (domains nil :documentation "List of DNSLink domains which resolve to the drive's public-key.")
  (metadata nil :documentation "Public metadata alist.")
  (latest-version nil :documentation "Latest known version of hyperdrive.")
  ;; TODO: Consider adding gv-setters for etc slot keys
  (etc nil :documentation "Alist of extra data.
- disk-usage :: Number of bytes occupied locally by the drive.
- safep :: Whether or not to treat this hyperdrive as safe.
  + t :: safe
  + nil :: unsafe
  + \\+`unknown' (or unset) :: unknown"))

(defun h/url (hyperdrive)
  "Return a \"hyper://\"-prefixed URL from a HYPERDRIVE struct.
URL does not have a trailing slash, i.e., \"hyper://PUBLIC-KEY\".

If HYPERDRIVE's public-key slot is empty, use first domain in
domains slot."
  ;; TODO: Add option to prefer domain over public-key
  (pcase-let* (((cl-struct hyperdrive public-key domains) hyperdrive)
               ;; TODO: Fallback to secondary domains?
               (host (or public-key (car domains))))
    (concat "hyper://" host)))

(defun h//url-hexify-string (string)
  "Return STRING having been URL-encoded.
Calls `url-hexify-string' with the \"/\" character added to
`url-unreserved-chars'."
  (url-hexify-string string (cons ?/ url-unreserved-chars)))

(defun he/url (entry)
  "Return ENTRY's canonical URL.
Returns URL with hyperdrive's full public key."
  (h//format-entry-url entry :with-protocol t))

(cl-defun he/create (&key hyperdrive path version etc)
  "Return hyperdrive entry struct from args.
HYPERDRIVE, VERSION, and ETC are used as-is.  Entry NAME is
generated from PATH."
  (setf path (h//format-path path))
  (he//create
   :hyperdrive hyperdrive
   :path path
   ;; TODO: Is it necessary to store the name alongside the path?
   ;;       Instead, only store path and generate name on the fly.
   :name (pcase path
           ("/"
            ;; Root directory: use "/" for clarity.
            "/")
           ((pred (string-suffix-p "/"))
            ;; A subdirectory: keep the trailing slash for clarity
            (file-relative-name path (file-name-parent-directory path)))
           (_
            ;; A file: remove directory part.
            (file-name-nondirectory path)))
   :version version
   :etc etc))

(cl-defun h/sort-entries (entries &key (direction h/directory-sort))
  "Return ENTRIES sorted by DIRECTION.
See `hyperdrive-directory-sort' for the type of DIRECTION."
  (pcase-let* ((`(,column . ,direction) direction)
               ((map :accessor (direction sort-function))
                (alist-get column h/dir-sort-fields)))
    (cl-sort entries (lambda (a b)
                       (cond ((and a b) (funcall sort-function a b))
                             ;; When an entry lacks appropriate metadata
                             ;; for sorting by DIRECTION, put it at the end.
                             (a t)))
             :key accessor)))

;;;; API

(cl-defun h/api (method url &rest rest)
  "Make hyperdrive API request by METHOD to URL.
Calls `hyperdrive--httpify-url' to convert HYPER-URL starting
with `hyperdrive--hyper-prefix' to a URL starting with
\"http://localhost:4973/hyper/\" (assuming that
`hyperdrive-gateway-port' is \"4973\").

REST is passed to `plz', which see.

REST may include the argument `:queue', a `plz-queue' in which to
make the request.

This low-level function should only be used when sending requests
to the gateway which do not involve an entry.  Otherwise, use
`hyperdrive-entry-api', which automatically fills metadata."
  ;; TODO: Document that the request/queue is returned.
  (declare (indent defun))
  (pcase method
    ((and (or 'get 'head)
          (guard (string-suffix-p "/" url)))
     ;; By default, hypercore-fetch resolves directory URLs to the
     ;; index.html file inside that directory. See
     ;; <https://git.sr.ht/~ushin/hypercore-fetch-ushin/#codefetchhypernameexamplenoresolve-method-getcode>
     (setf url (concat url "?noResolve"))))
  (pcase-let* ((else (pcase (plist-get rest :then)
                       ((or 'nil 'sync)
                        ;; In keeping with `plz', ignore ELSE for sync requests.
                        nil)
                       (_ (plist-get rest :else))))
               ;; We wrap the provided ELSE in our own lambda that
               ;; checks for common errors.
               (else* (apply-partially #'h/api-default-else else)))
    (setf rest (plist-put rest :else else*))
    (condition-case err
        ;; The `condition-case' is only intended for synchronous
        ;; requests.  Async requests should never signal a `plz-error'
        ;; directly from `plz' or `plz-run'.
        (if-let ((queue (prog1 (plist-get rest :queue)
                          (setf rest (map-delete rest :queue)))))
            (plz-run
             (apply #'plz-queue
                    queue method (h//httpify-url url) rest))
          (apply #'plz method (h//httpify-url url) rest))
      (plz-error
       ;; We pass only the `plz-error' struct to the ELSE* function.
       (funcall else* (caddr err))))))

(defun he/api (method entry &rest rest)
  "Make hyperdrive API request by METHOD for ENTRY.
REST is passed to `hyperdrive-api', which see.  AS keyword should
be nil, because it is always set to `response'.  BODY-TYPE
keyword should be nil, because it is always set to `binary'.
Automatically calls `hyperdrive-entry--api-then' to update
metadata from the response."
  (declare (indent defun))
  ;; Always use :as 'response
  (cl-assert (null (plist-get rest :as)))
  (setf (plist-get rest :as) 'response)
  ;; Always use :body-type 'binary so curl leaves carriage returns and newlines.
  (cl-assert (null (plist-get rest :body-type)))
  (setf (plist-get rest :body-type) 'binary)
  (unless (map-elt rest :then) (setf (map-elt rest :then) 'sync))
  (when-let* ((version (he/version entry))
              (existent-versions (gethash (h//existent-versions-key entry)
                                          h/existent-versions))
              (next-existent-version
               (cl-find-if (apply-partially #'< version) existent-versions)))
    (push `("X-Next-Version-Hint" . ,next-existent-version)
          (map-elt rest :headers)))
  (pcase-let* (((map :then) rest))
    (unless (eq 'sync then)
      (setf (plist-get rest :then)
            (lambda (response)
              (he//api-then method entry response)
              (funcall then response))))
    (let ((response (apply #'h/api method (he/url entry) rest)))
      (when (eq 'sync then)
        (funcall 'he//api-then method entry response))
      response)))

(defun he//api-then (method entry response)
  "Update ENTRY and drive metadata according to METHOD and RESPONSE.
Sets ENTRY's hyperdrive to the persisted version of the drive if
it exists.  Persists ENTRY's hyperdrive.  Invalidates ENTRY display."
  (pcase-let*
      ((encoding
        ;; TODO: After the resolution of <https://todo.sr.ht/~ushin/ushin/211>,
        ;; use the encoding specified in the 'Content-Type' header.  For now, we
        ;; rely on the guesswork of `detect-coding-region'.
        (if-let ((filename-encoding (auto-coding-alist-lookup (he/path entry))))
            filename-encoding
          (pcase (detect-coding-string (plz-response-body response) t)
            ((or 'undecided 'undecided-dos 'undecided-mac 'undecided-unix)
             ;; Default to UTF-8
             'utf-8)
            (detected-encoding detected-encoding))))
       ((map link allow content-length content-type last-modified etag
             x-drive-size x-file-block-length x-file-block-length-downloaded
             x-drive-version x-next-version-exists x-next-version-number
             x-previous-version-exists x-previous-version-number)
        (plz-response-headers response))
       ;; RESPONSE is guaranteed to have a "Link" header with the public key,
       ;; while ENTRY may have a DNSLink domain but no public key yet.
       (public-key (progn (string-match h//public-key-re link)
                          (match-string 1 link)))
       ;; NOTE: Don't destructure `persisted-hyperdrive' with `pcase' here since it may be nil.
       (persisted-hyperdrive (gethash public-key h/hyperdrives)))
    ;; Decode response body.
    (unless (eq 'no-conversion encoding)
      (cl-callf decode-coding-string (plz-response-body response) encoding))
    ;; TODO: Once we can get hyperdrive file contents as a buffer
    ;; (<https://github.com/alphapapa/plz.el/issues/61>), we should use
    ;; `decode-coding-region' instead of `decode-coding-string'.
    ;; `decode-coding-region' will set the buffer-local value of
    ;; `buffer-file-coding-system' to the correct encoding.  Currently,
    ;; hyperdrive file buffers always have `buffer-file-coding-system' to the
    ;; global default, `utf-8' on my machine.

    (when persisted-hyperdrive
      ;; ENTRY's hyperdrive already persisted: merge domains into persisted
      ;; hyperdrive and set ENTRY's hyperdrive slot to the persisted copy.
      (setf (h/domains persisted-hyperdrive)
            (delete-dups (append (h/domains persisted-hyperdrive)
                                 (h/domains (he/hyperdrive entry)))))
      (setf (he/hyperdrive entry) persisted-hyperdrive))

    ;; Ensure that ENTRY's hyperdrive has a public key.
    (setf (h/public-key (he/hyperdrive entry)) public-key)

    ;; Fill hyperdrive.
    (when allow
      ;; NOTE: "Allow" header is only present on HEAD requests.  We can change
      ;; this, but it's fine as-is since we only need to check writability once.
      (setf (h/writablep (he/hyperdrive entry)) (string-match-p "PUT" allow)))
    (when x-drive-size
      (setf (map-elt (h/etc (he/hyperdrive entry)) 'disk-usage)
            (cl-parse-integer x-drive-size)))
    (when x-drive-version
      (setf (h/latest-version (he/hyperdrive entry))
            (string-to-number x-drive-version)))
    ;; TODO: Update buffers like h/describe-hyperdrive after updating drive.
    ;; TODO: Consider debouncing or something for hyperdrive-persist to minimize I/O.
    (h/persist (he/hyperdrive entry))

    ;; Fill entry.
    (setf (map-elt (he/etc entry) 'existsp) (not (eq method 'delete)))
    (when x-next-version-exists
      (setf (map-elt (he/etc entry) 'next-version-exists-p)
            ;; HACK: At least on Emacs 28 and 29, `json-parse-string' signals an
            ;; error when receiving the string "unknown" or the string
            ;; "undefined", so we parse ourselves.
            (pcase-exhaustive x-next-version-exists
              ("true" t) ("false" nil) ("unknown" 'unknown))))
    (when x-next-version-number
      (setf (map-elt (he/etc entry) 'next-version-number)
            (json-parse-string x-next-version-number :null-object nil)))
    (when x-previous-version-exists
      (setf (map-elt (he/etc entry) 'previous-version-exists-p)
            (pcase-exhaustive x-previous-version-exists
              ("true" t) ("false" nil) ("unknown" 'unknown))))
    (when x-previous-version-number
      (setf (map-elt (he/etc entry) 'previous-version-number)
            (json-parse-string x-previous-version-number)))
    (when content-length
      (setf (he/size entry)
            (ignore-errors (cl-parse-integer content-length))))
    (when content-type
      ;; FIXME: `content-type' for 'text/plain' always has 'charset=utf-8',
      ;; which may not be correct.  Since charset in `hyperdrive-entry-type' is
      ;; not used anywhere, this should not result in any bugs.  This FIXME can
      ;; be removed when <https://todo.sr.ht/~ushin/ushin/211> is resolved.
      (setf (he/type entry) content-type))
    (when last-modified
      (setf (he/mtime entry) (encode-time (parse-time-string last-modified))))
    (when x-file-block-length
      (setf (map-elt (he/etc entry) 'block-length)
            (ignore-errors
              (cl-parse-integer x-file-block-length))))
    (when x-file-block-length-downloaded
      (setf (map-elt (he/etc entry) 'block-length-downloaded)
            (ignore-errors
              (cl-parse-integer x-file-block-length-downloaded))))

    ;; Fill `hyperdrive-existent-versions'
    (unless (eq method 'delete)
      (when etag
        (h/update-existent-versions
         (he/hyperdrive entry) (he/path entry) (json-parse-string etag)))
      (when-let (((string-equal "true" x-next-version-exists))
                 (next-version-number
                  (json-parse-string x-next-version-number :null-object nil)))
        (h/update-existent-versions
         (he/hyperdrive entry) (he/path entry) next-version-number))
      (when-let (((string-equal "true" x-previous-version-exists))
                 (previous-version-number
                  (json-parse-string x-previous-version-number)))
        (h/update-existent-versions
         (he/hyperdrive entry) (he/path entry) previous-version-number)))

    ;; Redisplay entry.
    (unless (h//entry-directory-p entry)
      ;; There's currently never a reason to redisplay directory entries since
      ;; they don't have block-length{,-downloaded} metadata.

      ;; NOTE: When we send a HEAD and GET request in rapid succession,
      ;; `he//invalidate' gets called twice.  Consider debouncing.
      (he//invalidate entry))))

(defun h/purge-existent-versions (hyperdrive)
  "Purge all existent versions for HYPERDRIVE."
  (maphash (lambda (key _val)
             (when (h/equal-p (he/hyperdrive key) hyperdrive)
               (remhash key h/existent-versions)))
           h/existent-versions)
  (persist-save 'h/existent-versions))

(declare-function h/dir--invalidate-entry "hyperdrive-dir")
(declare-function h/history--invalidate-entry "hyperdrive-history")
(defun he//invalidate (entry)
  "Invalidate ENTRY's ewoc node in directory and history buffers.
Invalidated ewoc node entries will have these slots updated:

- ETC
  + BLOCK-LENGTH-DOWNLOADED

All other slots in each ewoc node entry data will be reused."
  ;; Check `fboundp' to only iterate over directory or history buffers when
  ;; their respective libraries have been loaded.
  (when (fboundp #'h/dir--invalidate-entry)
    (h/dir--invalidate-entry entry))
  (when (fboundp #'h/history--invalidate-entry)
    (h/history--invalidate-entry entry)))

(defun h/gateway-needs-upgrade-p ()
  "Return non-nil if the gateway is responsive and needs upgraded."
  (and (h//gateway-ready-p)
       (not (equal h/gateway-version-expected (h//gateway-version)))))

(defun h/check-gateway-version ()
  "Warn if gateway is responsive and not at the expected version.
Unconditionally sets `h/gateway-version-checked-p' to t."
  (when (h/gateway-needs-upgrade-p)
    (display-warning
     'hyperdrive
     (substitute-command-keys
      (format
       "Gateway version %S not expected %S; consider installing the latest version with \\[hyperdrive-install]"
       (h//gateway-version) h/gateway-version-expected))
     :warning))
  (setf h/gateway-version-checked-p t))

(defun h//gateway-version ()
  "Return the name and version number of gateway as a plist.
If it's not running, signal an error."
  (condition-case err
      (pcase-let* ((url (format "http://localhost:%d/" h/gateway-port))
                   ((map name version) (plz 'get url :as #'json-read)))
        (list :name name :version version))
    (plz-error (h/api-default-else nil (caddr err)))))

(defun h/api-default-else (else plz-err)
  "Handle common errors, overriding ELSE.
Checks for common errors; if none are found, calls ELSE with
PLZ-ERR, if ELSE is non-nil; otherwise re-signals PLZ-ERR.
PLZ-ERR should be a `plz-error' struct."
  (pcase plz-err
    ((app plz-error-curl-error `(7 . ,_message))
     ;; Curl error 7 is "Failed to connect to host."
     (h/user-error "Gateway not running.  Use \\[hyperdrive-start] to start it"))
    ((app plz-error-response (cl-struct plz-response (status (or 403 405)) body))
     ;; 403 Forbidden or 405 Method Not Allowed: Display message from gateway.
     (h/error "%s" body))
    ((guard else)
     (funcall else plz-err))
    (_
     (signal 'plz-error (list "plz error" plz-err)))))

(defun h//httpify-url (url)
  "Return localhost HTTP URL for HYPER-URL."
  (format "http://localhost:%d/hyper/%s"
          h/gateway-port
          (substring url (length h//hyper-prefix))))

(defun h/parent (entry)
  "Return parent entry for ENTRY.
If already at top-level directory, return nil."
  (pcase-let (((cl-struct hyperdrive-entry hyperdrive path version) entry))
    (and-let* ((parent-path (file-name-parent-directory path)))
      (he/create :hyperdrive hyperdrive :path parent-path :version version))))

;; For Emacsen <29.1.
(declare-function textsec-suspicious-p "ext:textsec-check")
(defun h/url-entry (url)
  "Return entry for URL.
Set entry's hyperdrive slot to persisted hyperdrive if it exists.

If URL host is a DNSLink domain, returned entry will have an
empty public-key slot.

If URL does not begin with \"hyper://\" prefix, it will be added
before making the entry struct."
  (unless (string-prefix-p "hyper://" url)
    (setf url (concat "hyper://" url)))
  (pcase-let*
      (((cl-struct url host (filename path) target)
        (url-generic-parse-url url))
       ;; TODO: For now, no other function besides `h/url-entry' calls
       ;; `h/create', but perhaps it would be good to add a function which wraps
       ;; `h/create' and returns either an existing hyperdrive or a new one?
       (hyperdrive (pcase host
                     ((rx ".") ; Assume host is a DNSLink domain.
                      ;; See code for <https://github.com/RangerMauve/hyper-sdk#sdkget>.
                      (when (and (>= emacs-major-version 29)
                                 (textsec-suspicious-p host 'domain))
                        ;; Check DNSLink domains for suspicious characters;
                        ;; don't bother checking public keys since they're
                        ;; not recognizable anyway.
                        (unless (y-or-n-p
                                 (format "Suspicious domain: %s; continue anyway?" host))
                          (h/user-error "Suspicious domain %s" host)))
                      (h/create :domains (list host)))
                     (_  ;; Assume host is a public-key
                      (or (gethash host h/hyperdrives)
                          (h/create :public-key host)))))
       (etc (and target
                 `((target . ,(if (h/org-filename-p path)
                                  (substring (url-unhex-string target)
                                             (length "::"))
                                (url-unhex-string target))))))
       (version (pcase path
                  ((rx "/$/version/" (let v (1+ num)) (let p (0+ anything)))
                   (setf path p)
                   (string-to-number v)))))
    ;; e.g. for hyper://PUBLIC-KEY/path/to/basename, we do:
    ;; :path "/path/to/basename" :name "basename"
    (he/create :hyperdrive hyperdrive :path (url-unhex-string path)
               :version version :etc etc)))

;;;; Entries

;; These functions take a hyperdrive-entry struct argument, not a URL.

(defun h//existent-versions-key (entry)
  "Return cons cell of ENTRY hyperdrive public-key and path.
Intended to be used as hash table key in `hyperdrive-existent-versions'."
  ;; This format is designed to have compact serialization.
  (cons (h/public-key (he/hyperdrive entry)) (he/path entry)))

(defun he/at (version entry)
  "Return ENTRY at its hyperdrive's VERSION, or nil if not found.
When VERSION is nil, return latest version of ENTRY."
  (let ((entry (compat-call copy-tree entry t)))
    (setf (he/version entry) version)
    (condition-case err
        ;; FIXME: Requests to out of range version currently hang.
        (progn (he/api 'head entry) entry)
      (plz-error
       (pcase (plz-response-status (plz-error-response (caddr err)))
         ;; FIXME: If plz-error is a curl-error, this block will fail.
         (404 nil)
         (_ (signal (car err) (cdr err))))))))

(declare-function h/history "hyperdrive-history")
(cl-defun h/open
    (entry &key recurse (createp t) (messagep t)
           (then (lambda ()
                   ;; HACK: `pop-to-buffer' moves point back to the beginning of
                   ;; the buffer in certain cases (see
                   ;; <https://todo.sr.ht/~ushin/ushin/213>), so
                   ;; `save-excursion' ensure that point is retained.
                   (save-excursion
                     (pop-to-buffer (current-buffer)
                                    '((display-buffer-reuse-window
                                       display-buffer-same-window)))))))
  "Open hyperdrive ENTRY.
If RECURSE, proceed up the directory hierarchy if given path is
not found.  THEN is a function to pass to the handler which will
be called with no arguments in the buffer opened by the handler.
When a writable ENTRY is not found and CREATEP is non-nil, create
a new buffer for ENTRY.  When MESSAGEP, show a message in the
echo area when the request for the file is made."
  (declare (indent defun))
  ;; TODO: Add `find-file'-like interface. See <https://todo.sr.ht/~ushin/ushin/16>
  ;; FIXME: Some of the synchronous filling functions we've added now cause this to be blocking,
  ;; which is very noticeable when a file can't be loaded from the gateway and eventually times out.
  (let ((hyperdrive (he/hyperdrive entry)))
    (he/api 'head entry
      :then (lambda (_response)
              (pcase-let* (((cl-struct hyperdrive-entry type) entry)
                           (handler (alist-get type h/type-handlers
                                               nil nil #'string-match-p)))
                (funcall (or handler #'h/handler-default) entry :then then)))
      :else (lambda (err)
              (cl-labels ((not-found-action ()
                            (if recurse
                                (h/open (h/parent entry) :recurse t)
                              (pcase (prompt)
                                ('history (h/history entry))
                                ('up (h/open (h/parent entry)))
                                ('recurse (h/open (h/parent entry) :recurse t))
                                ('explain (info "(hyperdrive) Unknown paths")))))
                          (prompt ()
                            (pcase-exhaustive
                                (read-answer (format "URL not found: \"%s\". " (he/url entry))
                                             '(("history" ?h "open version history")
                                               ("up" ?u "open parent directory")
                                               ("recurse" ?r "go up until a directory is found")
                                               ("explain" ?e "show Info manual section about unknown paths")
                                               ("quit" ?q "quit")))
                              ("history" 'history)
                              ("up" 'up)
                              ("recurse" 'recurse)
                              ("explain" 'explain)
                              ("quit" nil))))
                (pcase (plz-response-status (plz-error-response err))
                  ;; FIXME: If plz-error is a curl-error, this block will fail.
                  (404 ;; Path not found.
                   (cond
                    ((equal (he/path entry) "/")
                     ;; Root directory not found: Drive has not been
                     ;; loaded locally, and no peers are found seeding it.
                     (h/message "No peers found for %s" (he/url entry)))
                    ((and createp
                          (not (h//entry-directory-p entry))
                          (h/writablep hyperdrive)
                          (not (he/version entry)))
                     ;; `existsp' will be set to non-nil in `he//api-then'.
                     (setf (map-elt (he/etc entry) 'existsp) nil)
                     ;; Entry is a writable file: create a new buffer
                     ;; that will be saved to its path.
                     (if-let ((buffer (h//find-buffer-visiting entry)))
                         ;; Buffer already exists: likely the user deleted the
                         ;; entry without killing the buffer.  Switch to the
                         ;; buffer and alert the user that the entry no longer
                         ;; exists.
                         (progn
                           (switch-to-buffer buffer)
                           (h/message "Entry does not exist!  %s"
                                      (h//format-entry entry)))
                       ;; Make and switch to new buffer.
                       (switch-to-buffer (h//get-buffer-create entry))
                       (h//set-auto-mode)))
                    (t
                     ;; Hyperdrive entry is not writable: prompt for action.
                     (not-found-action))))
                  (500 ;; Generic error, likely a mistyped URL
                   (h/message
                    "Generic gateway status 500 error. %s %s"
                    "Is this URL correct?" (he/url entry)))
                  (_ (h/message "Unable to load URL \"%s\": %S"
                                (he/url entry) err))))))
    (when messagep
      (h/message "Opening <%s>..." (he/url entry)))))

(cl-defun h/fully-replicate (entry &key then)
  "Fully replicate hyperdrive for ENTRY.
Then update hyperdrive's size and latest version metadata, then
call THEN with ENTRY as its sole argument."
  ;; TODO: For now, this replicates the entire drive, but when
  ;; hyper-gateway-ushin support replicating only a folder range, this code will
  ;; change behavior to only replicating the folder range for ENTRY.
  ;; TODO: For now, the entire db is replicated regardless of version, but the
  ;; blob store is only replicated for the drive version.
  (h/api 'get (he/url entry) :as 'response
    :headers `(("X-Fully-Replicate" . "db"))
    :else (lambda (err)
            (h/error "Unable to replicate `%s': %S" (he/url entry) err))
    :then
    (pcase-lambda ((cl-struct plz-response (headers (map x-drive-size
                                                         x-drive-version))))
      (when x-drive-size
        (setf (map-elt (h/etc (he/hyperdrive entry)) 'disk-usage)
              (cl-parse-integer x-drive-size)))
      (when x-drive-version
        (setf (h/latest-version (he/hyperdrive entry))
              (string-to-number x-drive-version)))
      ;; TODO: Update buffers like h/describe-hyperdrive after updating drive.
      ;; TODO: Consider debouncing or something for hyperdrive-persist to minimize I/O.
      (h/persist (he/hyperdrive entry))
      (funcall then entry))))

(defun h//fill-listing-entries (listing hyperdrive version)
  "Return entries list with metadata from LISTING.
Accepts HYPERDRIVE and VERSION of parent entry as arguments.
LISTING should be an alist based on the JSON retrieved in, e.g.,
`hyperdrive-dir-handler'."
  (mapcar
   (pcase-lambda ((map key value seq blockLengthDownloaded))
     (let* ((mtime (map-elt (map-elt value 'metadata) 'mtime))
            (size (map-elt (map-elt value 'blob) 'byteLength))
            (block-length (map-elt (map-elt value 'blob) 'blockLength))
            (entry (he/create
                    :hyperdrive hyperdrive :path key :version version)))
       (when mtime ; mtime is milliseconds since epoch
         (setf (he/mtime entry) (seconds-to-time (/ mtime 1000.0))))
       (when size
         (setf (he/size entry) size))
       (when block-length
         (setf (map-elt (he/etc entry) 'block-length) block-length))
       (when blockLengthDownloaded
         (setf (map-elt (he/etc entry) 'block-length-downloaded)
               blockLengthDownloaded))
       (when seq
         (h/update-existent-versions
          ;; seq is the hyperdrive version *before* entry was added/modified
          (he/hyperdrive entry) (he/path entry) (1+ seq)))
       entry))
   listing))

(defun h/update-existent-versions (hyperdrive path version)
  "Update and persist `hyperdrive-existent-versions'.
Accepts HYPERDRIVE, PATH, and VERSION, an existent range start."
  (cl-callf (lambda (existent-versions)
              (cl-pushnew version existent-versions)
              (sort existent-versions #'<))
      (gethash (h//existent-versions-key
                (he//create :hyperdrive hyperdrive :path path))
               h/existent-versions))
  (persist-save 'h/existent-versions))

(defun h/fill (hyperdrive)
  "Synchronously fill latest version and drive size in HYPERDRIVE."
  (he/api 'head (he/create :hyperdrive hyperdrive :path "/")))

(defun he/fill-version (entry)
  "Synchronously fill next version metadata for ENTRY."
  ;; TODO: Send request with entry version set to (1- next-version-range-start) for perf
  (he/api 'head entry :headers '(("X-Wait-On-Version-Data" . t))))

(defun h/fill-metadata (hyperdrive)
  "Fill HYPERDRIVE's public metadata and return it.
Sends a synchronous request to get the latest contents of
HYPERDRIVE's public metadata file."
  (declare (indent defun))
  (pcase-let*
      ((entry (he/create
               :hyperdrive hyperdrive
               :path "/.well-known/host-meta.json"
               ;; NOTE: Don't attempt to fill hyperdrive struct with old metadata
               :version nil))
       (metadata (condition-case err
                     ;; TODO: Refactor to use :as 'response-with-buffer and call he/fill
                     (pcase-let
                         (((cl-struct plz-response body)
                           (he/api 'get entry :noquery t)))
                       (with-temp-buffer
                         (insert body)
                         (goto-char (point-min))
                         (json-read)))
                   (json-error
                    (h/message "Error parsing JSON metadata file: %s"
                               (he/url entry)))
                   (plz-error
                    (pcase (plz-response-status (plz-error-response (caddr err)))
                      ;; FIXME: If plz-error is a curl-error, this block will fail.
                      (404 nil)
                      (_ (signal (car err) (cdr err))))))))
    (setf (h/metadata hyperdrive) metadata)
    (h/persist hyperdrive)
    hyperdrive))

(cl-defun h/purge-no-prompt (hyperdrive &key then else)
  "Purge all data corresponding to HYPERDRIVE, then call THEN with response.

- HYPERDRIVE file content and metadata managed by the gateway
- hash table entry for HYPERDRIVE in `hyperdrive-hyperdrives'
- hash table entries for HYPERDRIVE in `hyperdrive-existent-versions'

Call ELSE if request fails."
  (declare (indent defun))
  (he/api 'delete (he/create :hyperdrive hyperdrive)
    :then (lambda (response)
            (h/persist hyperdrive :purge t)
            (h/purge-existent-versions hyperdrive)
            (funcall then response))
    :else else))

(cl-defun h/write (entry &key body then else queue)
  "Write BODY to hyperdrive ENTRY's URL.
BODY should be an encoded string or buffer.  THEN and ELSE are
passed to `hyperdrive-entry-api', which see."
  (declare (indent defun))
  (he/api 'put entry
    :body body :then then :else else :queue queue))

(cl-defun h//format-entry-url
    (entry &key (host-format '(public-key domain))
           (with-path t) (with-protocol t) (with-help-echo t) (with-target t))
  "Return ENTRY's URL.
Returns URL formatted like:

  hyper://HOST-FORMAT/PATH/TO/FILE

HOST-FORMAT is passed to `hyperdrive--preferred-format', which see.
If WITH-PROTOCOL, \"hyper://\" is prepended.  If WITH-HELP-ECHO,
propertize string with `help-echo' property showing the entry's
full URL.  If WITH-TARGET, append the ENTRY's target, stored in
its :etc slot.  If WITH-PATH, include the path portion.  When
ENTRY has non-nil `version' slot, include version number in URL.

Note that, if HOST-FORMAT includes values other than `public-key'
and `domain', the resulting URL may not be a valid hyperdrive
URL.

Path and target fragment are URI-encoded."
  ;; NOTE: Entries may have only a domain, not a public key yet, so we
  ;; include `domain' in HOST-FORMAT's default value.  The public key
  ;; will be filled in later.
  (pcase-let* (((cl-struct hyperdrive-entry path version etc)
                entry)
               (protocol (and with-protocol "hyper://"))
               (host (and host-format
                          ;; FIXME: Update docstring to say that host-format can be nil to omit it.
                          (h//preferred-format (he/hyperdrive entry)
                                               host-format h/raw-formats)))
               (version-part (and version (format "/$/version/%s" version)))
               ((map target) etc)
               (target-part (and with-target
                                 target
                                 (concat "#"
                                         (when (h/org-filename-p path)
                                           (url-hexify-string "::"))
                                         (url-hexify-string target))))
               (path (and with-path
                          ;; TODO: Consider removing this argument if it's not needed.
                          (h//url-hexify-string path)))
               (url (concat protocol host version-part path target-part)))
    (if with-help-echo
        (propertize url 'help-echo (h//format-entry-url
                                    entry
                                    :with-protocol t
                                    :host-format '(public-key domain)
                                    :with-path with-path
                                    :with-help-echo nil
                                    :with-target with-target))
      url)))

(defun h//format (hyperdrive &optional format formats)
  "Return HYPERDRIVE formatted according to FORMAT.
FORMAT is a `format-spec' specifier string which maps to specifications
according to FORMATS, by default `hyperdrive-formats', which see."
  (pcase-let* (((cl-struct hyperdrive domains public-key petname seed
                           (metadata (map ('name nickname))))
                hyperdrive)
               (format (or format "%H"))
               (formats (or formats h/formats)))
    (cl-labels ((fmt (format value face)
                  (if value
                      (format (alist-get format formats)
                              (propertize value 'face face))
                    "")))
      (format-spec
       format
       ;; TODO(deprecate-28): Use lambdas in each specifier.
       `((?H . ,(and (string-match-p (rx "%"
                                         ;; Flags
                                         (optional
                                          (1+ (or " " "0" "-" "<" ">" "^" "_")))
                                         (0+ digit) ;; Width
                                         (0+ digit) ;; Precision
                                         "H")
                                     format)
                     ;; HACK: Once using lambdas in this specifier,
                     ;; remove the `string-match-p' check.
                     (h//preferred-format hyperdrive)))
         (?P . ,(fmt 'petname petname 'h/petname))
         (?N . ,(fmt 'nickname nickname 'h/nickname))
         (?k . ,(fmt 'short-key public-key 'h/public-key))
         (?K . ,(fmt 'public-key public-key 'h/public-key))
         (?S . ,(fmt 'seed seed 'h/seed))
         (?D . ,(if (car domains)
                    (format (alist-get 'domains formats)
                            (string-join
                             (mapcar (lambda (domain)
                                       (propertize domain
                                                   'face 'h/domain))
                                     domains)
                             ","))
                  "")))))))

(defun h//preferred-format (hyperdrive &optional format formats)
  "Return HYPERDRIVE's formatted hostname, or nil.
FORMAT should be one or a list of symbols, by default
`hyperdrive-preferred-formats', which see for choices.  If the
specified FORMAT is not available, return nil.

Each item in FORMAT is formatted according to FORMATS, set by
default to `hyperdrive-formats', which see."
  (pcase-let* (((cl-struct hyperdrive petname public-key domains seed
                           (metadata (map ('name nickname))))
                hyperdrive))
    (cl-loop for f in (ensure-list (or format h/preferred-formats))
             when (pcase f
                    ((and 'petname (guard petname))
                     (h//format hyperdrive "%P" formats))
                    ((and 'nickname (guard nickname))
                     (h//format hyperdrive "%N" formats))
                    ((and 'domain (guard (car domains)))
                     (h//format hyperdrive "%D" formats))
                    ((and 'seed (guard seed))
                     (h//format hyperdrive "%S" formats))
                    ((and 'short-key (guard public-key))
                     (h//format hyperdrive "%k" formats))
                    ((and 'public-key (guard public-key))
                     (h//format hyperdrive "%K" formats)))
             return it)))

;;;; Reading from the user

(declare-function h/dir--entry-at-point "hyperdrive-dir")
(cl-defun h//context-entry (&key latest-version force-prompt)
  "Return the current entry in the current context.
LATEST-VERSION is passed to `hyperdrive-read-entry'.  With
FORCE-PROMPT, prompt for entry."
  (cl-labels ((read-entry ()
                (h/read-entry
                 (h//context-hyperdrive :force-prompt force-prompt)
                 :read-version t :latest-version latest-version)))
    (cond (force-prompt (read-entry))
          ((derived-mode-p 'h/dir-mode) (h/dir--entry-at-point 'no-error))
          (t (or h/current-entry (read-entry))))))

(cl-defun h//context-hyperdrive (&key predicate force-prompt)
  "Return hyperdrive for current entry when it matches PREDICATE.

With FORCE-PROMPT or when current hyperdrive does not match
PREDICATE, return a hyperdrive selected with completion.  In this
case, when PREDICATE, only offer hyperdrives matching it."
  (unless predicate
    ;; cl-defun default value doesn't work when nil predicate value is passed in.
    (setf predicate #'always))

  ;; Return current drive when appropriate.
  (unless force-prompt
    ;; If transient menu is open, use that as the current hyperdrive.
    (when-let* ((obj (transient-active-prefix 'h/menu-hyperdrive))
                (transient-hyperdrive (oref obj scope))
                ((funcall predicate transient-hyperdrive)))
      (cl-return-from h//context-hyperdrive transient-hyperdrive))
    (when-let* ((h/current-entry)
                (current-hyperdrive (he/hyperdrive h/current-entry))
                ((funcall predicate current-hyperdrive)))
      (cl-return-from h//context-hyperdrive current-hyperdrive)))

  ;; Otherwise, prompt for drive.
  (h/read-hyperdrive predicate))

(defun h/read-hyperdrive (&optional predicate)
  "Read hyperdrive from among those which match PREDICATE."
  (when (zerop (hash-table-count h/hyperdrives))
    (h/user-error "No known hyperdrives.  Use `hyperdrive-new' to create a new one"))
  (unless predicate
    ;; cl-defun default value doesn't work when nil predicate value is passed in.
    (setf predicate #'always))
  (let* ((current-hyperdrive (and h/current-entry
                                  (he/hyperdrive h/current-entry)))
         (hyperdrives (cl-remove-if-not predicate (hash-table-values h/hyperdrives)))
         (default (and h/current-entry
                       (funcall predicate current-hyperdrive)
                       (h//format-hyperdrive (he/hyperdrive h/current-entry))))
         (prompt (format-prompt "Hyperdrive" default))
         (candidates (mapcar (lambda (hyperdrive)
                               (cons (h//format-hyperdrive hyperdrive) hyperdrive))
                             hyperdrives))
         (completion-styles (cons 'substring completion-styles))
         (selected
          (completing-read
           prompt
           (lambda (string predicate action)
             (if (eq action 'metadata)
                 '(metadata (category . hyperdrive))
               (complete-with-action
                action candidates string predicate)))
           nil 'require-match nil nil default)))
    (or (alist-get selected candidates nil nil #'equal)
        (h/user-error "No such hyperdrive.  Use `hyperdrive-new' to create a new one"))))

(cl-defun h//format-hyperdrive
    (hyperdrive &key (formats '(petname nickname domain seed short-key)))
  "Return HYPERDRIVE formatted for completion.
For each of FORMATS, concatenates the value separated by two spaces."
  (string-trim
   (cl-loop for format in formats
            when (h//preferred-format hyperdrive format)
            concat (concat it "  "))))

(cl-defun h/read-entry (hyperdrive &key default-path latest-version read-version)
  "Return new hyperdrive entry in HYPERDRIVE with path read from user.

If DEFAULT-PATH, offer it as the default entry path.  Otherwise,
offer the path of `hyperdrive-current-entry' when it is in the
hyperdrive chosen with completion.

When LATEST-VERSION is non-nil, returned entry's version is nil.
When LATEST-VERSION is nil, READ-VERSION is non-nil, and
`hyperdrive-current-entry' is in the hyperdrive chosen with
completion, returned entry has the same version.
Otherwise, prompt for a version number."
  (let* ((default-version (and (not latest-version)
                               h/current-entry
                               (h/equal-p hyperdrive
                                          (he/hyperdrive h/current-entry))
                               (he/version h/current-entry)))
         (version (cond (latest-version nil)
                        (read-version
                         (h/read-version :hyperdrive hyperdrive
                                         :initial-input-number default-version))
                        (default-version)))
         (default-path (h//format-path
                        (or default-path
                            (and h/current-entry
                                 (h/equal-p
                                  hyperdrive (he/hyperdrive h/current-entry))
                                 (he/path h/current-entry)))))
         (path (h/read-path :hyperdrive hyperdrive
                            :version version
                            :default default-path)))
    (he/create :hyperdrive hyperdrive :path path :version version)))

(defvar h//version-history nil
  "Minibuffer history of `hyperdrive-read-version'.")

(cl-defun h/read-version (&key hyperdrive prompt initial-input-number)
  "Return version number.
Blank input returns nil.

HYPERDRIVE is used to fill in PROMPT format %s sequence.
INITIAL-INPUT-NUMBER is converted to a string and passed to
`read-string', which see."
  (let* ((prompt (or prompt "Version number in `%s' (leave blank for latest version)"))
         ;; Don't use read-number since it cannot return nil.
         (version (read-string
                   (format-prompt prompt nil (h//format-hyperdrive hyperdrive))
                   (and initial-input-number
                        (number-to-string initial-input-number))
                   'h//version-history)))
    (unless (string-blank-p version)
      (string-to-number version))))

(defvar h//path-history nil
  "Minibuffer history of `hyperdrive-read-path'.")

(cl-defun h/read-path (&key hyperdrive version prompt default)
  "Return path read from user.
HYPERDRIVE and VERSION are used to fill in the prompt's format %s
sequence.  PROMPT is passed to `format-prompt', which see.  DEFAULT
is passed to `read-string' as its DEFAULT-VALUE argument."
  (let ((prompt (or prompt
                    (if version
                        "Path in `%s' (version:%s)"
                      "Path in `%s'"))))
    ;; TODO: Provide a `find-file'-like auto-completing UI
    (read-string (format-prompt prompt default
                                (h//format-hyperdrive hyperdrive) version)
                 nil 'h//path-history default)))

(defvar h//url-history nil
  "Minibuffer history of `hyperdrive-read-url'.")

(cl-defun h/read-url (&key (prompt "Hyperdrive URL"))
  "Return URL trimmed of whitespace.
Prompts with PROMPT.  Defaults to current entry if it exists."
  (let* ((default-entry
          (cond ((derived-mode-p 'h/dir-mode) (h/dir--entry-at-point 'no-error))
                (h/current-entry h/current-entry)))
         (default-url (and default-entry (he/url default-entry))))
    (string-trim (read-string (format-prompt prompt default-url)
                              nil 'h//url-history default-url))))

(defvar h//name-history nil
  "Minibuffer history of `hyperdrive-read-name'.")

(cl-defun h/read-name (&key prompt initial-input default)
  "Wrapper for `read-string' with common history.
Prompts with PROMPT and DEFAULT, according to `format-prompt'.
DEFAULT and INITIAL-INPUT are passed to `read-string' as-is."
  (read-string (format-prompt prompt default)
               initial-input 'h//name-history default))

(cl-defun h/put-metadata (hyperdrive &key then)
  "Put HYPERDRIVE's metadata into the appropriate file, then call THEN."
  (declare (indent defun))
  (let ((entry (he/create :hyperdrive hyperdrive
                          :path "/.well-known/host-meta.json")))
    ;; TODO: Is it okay to always encode the JSON object as UTF-8?
    (h/write entry :body (encode-coding-string
                          (json-encode (h/metadata hyperdrive)) 'utf-8)
      :then then)
    hyperdrive))

(cl-defun h/persist (hyperdrive &key purge)
  "Persist HYPERDRIVE in `hyperdrive-hyperdrives'.
With PURGE, delete hash table entry for HYPERDRIVE."
  ;; TODO: Make separate function for purging persisted data.
  (if purge
      (remhash (h/public-key hyperdrive) h/hyperdrives)
    (puthash (h/public-key hyperdrive) hyperdrive h/hyperdrives))
  (persist-save 'h/hyperdrives))

(defun h/seed-url (seed)
  "Return URL to hyperdrive known as SEED, or nil if it doesn't exist.
That is, if the SEED has been used to create a local
hyperdrive."
  (condition-case err
      (pcase-let
          (((cl-struct plz-response (body url))
            (h/api 'get (format "hyper://localhost/?key=%s"
                                (url-hexify-string seed))
              :as 'response :noquery t)))
        (h/fill (h/url-entry url))
        url)
    (plz-error (if (= 400 (plz-response-status (plz-error-response (caddr err))))
                   ;; FIXME: If plz-error is a curl-error, this block will fail.
                   nil
                 (signal (car err) (cdr err))))))

;;;###autoload
(defun hyperdrive-by-slot (slot value)
  "Return persisted hyperdrive struct whose SLOT matches VALUE.
Otherwise, return nil.  SLOT may be one of

- seed
- petname
- public-key"
  (catch 'get-first-hash
    (maphash (lambda (_key val)
               (when (equal (cl-struct-slot-value 'hyperdrive slot val) value)
                 (throw 'get-first-hash val)))
             h/hyperdrives)
    nil))

;;;; Handlers

(declare-function h/org--link-goto "hyperdrive-org")
(declare-function h/blob-mode "hyperdrive")
(declare-function h/mark-as-safe "hyperdrive")
(cl-defun h/handler-default (entry &key then)
  "Load ENTRY's file into an Emacs buffer.
If then, then call THEN with no arguments.  Default handler."
  (pcase-let*
      (((cl-struct plz-response body)
        ;; TODO: Handle errors
        ;; TODO: When plz adds :as 'response-with-buffer, use that.
        (he/api 'get entry :noquery t))
       ((cl-struct hyperdrive-entry hyperdrive version etc) entry)
       ((map target) etc))
    (with-current-buffer (h//get-buffer-create entry)
      ;; TODO: Don't reload if we're jumping to a link on the
      ;; same page (but ensure that reverting still works).
      (if (buffer-modified-p)
          (h/message "Buffer modified: %S" (current-buffer))
        (save-excursion
          (with-silent-modifications
            (erase-buffer)
            (insert body))
          (setf buffer-undo-list nil)
          (setf buffer-read-only
                (or (not (h/writablep hyperdrive)) version))
          (set-buffer-modified-p nil)
          (set-visited-file-modtime (current-time))))
      (h//set-auto-mode)
      (when target
        (with-demoted-errors "Hyperdrive: %S"
          (pcase major-mode
            ('org-mode
             (require 'hyperdrive-org)
             (h/org--link-goto target))
            ('markdown-mode
             ;; TODO: Handle markdown link
             ))))
      (h/blob-mode (if version +1 -1))
      (when then
        (funcall then)))))

(cl-defun h/handler-streamable (entry &key _then)
  ;; TODO: Is there any reason to not pass THEN through?
  "Stream ENTRY."
  ;; NOTE: Since data is streamed to an external process, disk usage will not be
  ;; updated until a later request.
  (h/message "Streaming %s..."  (h//format-entry-url entry))
  (pcase-let ((`(,command .  ,args) (split-string h/stream-player-command)))
    (apply #'start-process "hyperdrive-stream-player"
           nil command (cl-substitute (h//httpify-url
                                       (he/url entry))
                                      "%s" args :test #'equal))))

(declare-function h/dir-handler "hyperdrive-dir")
(cl-defun h/handler-json (entry &key then)
  "Show ENTRY.
THEN is passed to other handlers, which see.  If ENTRY is a
directory (if its URL ends in \"/\"), pass to
`hyperdrive-dir-handler'.  Otherwise, open with
`hyperdrive-handler-default'."
  (if (h//entry-directory-p entry)
      (h/dir-handler entry :then then)
    (h/handler-default entry :then then)))

(cl-defun h/handler-html (entry &key then)
  "Show ENTRY, where ENTRY is an HTML file.
If `hyperdrive-render-html' is non-nil, render HTML with
`shr-insert-document', then calls THEN if given.  Otherwise, open
with `hyperdrive-handler-default'."
  (if h/render-html
      (let (buffer)
        (save-window-excursion
          ;; Override EWW's calling `pop-to-buffer-same-window'; we
          ;; want our callback to display the buffer.
          (eww (he/url entry))
          ;; Set `h/current-entry' and use `h/mode'
          ;; for remapped keybindings for, e.g., `h/up'.
          (setq-local h/current-entry entry)
          (h/mode)
          (setf buffer (current-buffer)))
        (set-buffer buffer)
        ;; Since the buffer is modified (by `eww') and
        ;; `write-contents-functions' is set (by `hyperdrive-mode'), Emacs
        ;; prompts to save before killing the EWW buffer.  To avoid this, set
        ;; `buffer-modified-p' flag to nil.
        (set-buffer-modified-p nil)
        (when then
          (funcall then)))
    (h/handler-default entry :then then)))

(cl-defun h/handler-image (entry &key then)
  "Show ENTRY, where ENTRY is an image file.
Then calls THEN if given."
  (h/handler-default
   entry :then (lambda ()
		 (image-mode)
		 (when then
		   (funcall then)))))

;;;; Gateway process

(defun h//gateway-path ()
  "Return path to gateway executable, or nil if not found.
See user options `hyperdrive-gateway-program' and
`hyperdrive-gateway-directory'."
  (cond ((file-exists-p
          (expand-file-name h/gateway-program h/gateway-directory))
         (expand-file-name h/gateway-program h/gateway-directory))
        ((executable-find h/gateway-program))))

(defun h//gateway-start-default ()
  "Start the gateway as an Emacs subprocess.
Default function; see variable `h/gateway-start-function'."
  (setf h/gateway-process
        (make-process
         :name "hyperdrive-gateway"
         :buffer " *hyperdrive-start*"
         :command (cons (h//gateway-path)
                        (append (split-string-and-unquote h/gateway-command-args)
                                (list "--port" (number-to-string h/gateway-port))))
         :connection-type 'pipe)))

(defun h/announce-gateway-ready ()
  "Announce that the gateway is ready."
  (h/message "Gateway ready."))

(defun h/announce-gateway-stopped ()
  "Announce that the gateway is stopped."
  (h/message "Gateway stopped."))

(defun h/menu-refresh ()
  "Refresh `hyperdrive-menu' if it's open."
  (when (transient-active-prefix 'h/menu)
    (transient--refresh-transient)))

(defun h//gateway-stop-default ()
  "Stop the gateway subprocess."
  (unless (h/gateway-live-p-default)
    ;; NOTE: We do not try to stop the process if we didn't start it ourselves.
    (h/user-error "Gateway not running as subprocess"))
  (interrupt-process h/gateway-process))

(defun h//gateway-wait-for-dead ()
  "Run `hyperdrive-gateway-dead-hook' after the gateway is dead.
Or if gateway isn't dead within timeout, show an error."
  (letrec
      ((start-time (current-time))
       (check
        (lambda ()
          (cond ((not (h/gateway-live-p))
                 (setf h//gateway-stopping-timer nil)
                 (run-hooks 'h/gateway-dead-hook))
                ((< 10 (float-time (time-subtract nil start-time)))
                 ;; Gateway process still running: show error.
                 (setf h//gateway-stopping-timer nil)
                 (if-let (((equal h/gateway-stop-function
                                  (eval (car (get 'h/gateway-stop-function
                                                  'standard-value)))))
                          (process-buffer (process-buffer h/gateway-process)))
                     ;; User has not customized the stop function: suggest
                     ;; opening the process buffer.
                     (h/error "Gateway failed to stop (see %S for errors)"
                              process-buffer)
                   ;; User appears to have customized the stop function.
                   (h/error "Gateway failed to stop")))
                (t
                 (setf h//gateway-stopping-timer (run-at-time 0.1 nil check)))))))
    (funcall check)))

(defun h//gateway-cleanup-default ()
  "Clean up gateway process buffers, etc.
To be called after gateway process dies."
  (when-let* ((process h/gateway-process)
              (buffer (process-buffer h/gateway-process))
              ((buffer-live-p buffer)))
    (kill-buffer (process-buffer h/gateway-process)))
  (setf h/gateway-process nil))

(defun h/gateway-live-p ()
  "Return non-nil if the gateway process is running.
Calls function set in option `hyperdrive-gateway-live-predicate'.
This does not mean that the gateway is responsive, only that the
process is running.  See also function
`hyperdrive--gateway-ready-p'."
  (funcall h/gateway-live-predicate))

(defun h/gateway-live-p-default ()
  "Return non-nil if the gateway is running as an Emacs subprocess.
This does not mean that the gateway is responsive, only that the
process is running."
  (process-live-p h/gateway-process))

(defun h/gateway-installing-p ()
  "Return non-nil if the gateway program is being installed."
  ;; If this variable is non-nil, it might be a dead process, but it is
  ;; interpreted to mean that we are still trying to download and install the
  ;; gateway, because we are still trying other sources; we will set the
  ;; variable nil when we succeed, give up, or are canceled.
  h/install-process)

(defun h/gateway-installed-p ()
  "Return non-nil if the gateway program is installed."
  (and-let* ((gateway-path (hyperdrive--gateway-path)))
    (file-executable-p gateway-path)))

(defun h//gateway-ready-p ()
  "Return non-nil if the gateway is running and accessible.
Times out after 2 seconds."
  (ignore-errors
    (plz 'get (format "http://localhost:%d/" h/gateway-port)
      :connect-timeout 2 :timeout 2)))

(defun h//gateway-wait-for-ready ()
  "Run `hyperdrive-gateway-ready-hook' after gateway is ready.
Or if gateway isn't ready within timeout, show an error."
  (letrec
      ((start-time (current-time))
       (check
        (lambda ()
          (cond ((h//gateway-ready-p)
                 (setf h//gateway-starting-timer nil)
                 (run-hooks 'h/gateway-ready-hook))
                ((< 10 (float-time (time-subtract nil start-time)))
                 ;; Gateway still not responsive: show error.
                 (setf h//gateway-starting-timer nil)
                 (if-let (((equal h/gateway-start-function
                                  (eval (car (get 'h/gateway-start-function
                                                  'standard-value)))))
                          (process-buffer (process-buffer h/gateway-process)))
                     ;; User has not customized the start function: suggest
                     ;; opening the process buffer.
                     (h/error "Gateway failed to start (see %S for errors)"
                              process-buffer)
                   ;; User appears to have customized the start function.
                   (h/error "Gateway failed to start")))
                (t
                 (setf h//gateway-starting-timer (run-at-time 0.1 nil check)))))))
    (funcall check)))

;;;; Misc.

(defun h//get-buffer-create (entry)
  "Return buffer for ENTRY.
In the buffer, `hyperdrive-mode' is activated and
`hyperdrive-current-entry' is set.

This function helps prevent duplicate `hyperdrive-mode' buffers
by ensuring that buffer names always use the namespace seed
corresponding to URL if possible.

In other words, this avoids the situation where a buffer called
\"foo:/\" and another called \"hyper://<public key for foo>/\"
both point to the same content."
  (let* ((existing-buffer (h//find-buffer-visiting entry))
         (buffer
          (if (not existing-buffer)
              ;; No existing buffer visiting entry: make new buffer.
              (get-buffer-create (h//generate-new-buffer-name entry))
            ;; Existing buffer visiting entry.
            (unless (eq (he/version entry)
                        (he/version
                         (buffer-local-value 'hyperdrive-current-entry
                                             existing-buffer)))
              ;; Entry versions differ: rename buffer.
              (with-current-buffer existing-buffer
                (rename-buffer (h//generate-new-buffer-name entry))))
            existing-buffer)))
    (with-current-buffer buffer
      ;; NOTE: We do not erase the buffer because, e.g. the directory
      ;; handler needs to record point before it erases the buffer.
      (h/mode)
      (setq-local h/current-entry entry)
      (current-buffer))))

(defun h//generate-new-buffer-name (entry)
  "Return a new, unique name for a buffer visiting ENTRY."
  ;; TODO: Use in calls to `h//get-buffer-create', et al.
  (let ((buffer-name (h//format-entry entry h/buffer-name-format)))
    (generate-new-buffer-name buffer-name)))

(defun h//find-buffer-visiting (entry &optional any-version-p)
  "Return a buffer visiting ENTRY, or nil if none exists.
If ANY-VERSION-P, return the first buffer showing ENTRY at any
version."
  ;; If `match-buffers' returns more than one buffer, we ignore the others.
  (car (match-buffers
        (lambda (buffer)
          (and-let* ((local-entry (buffer-local-value 'h/current-entry buffer)))
            (he/equal-p entry local-entry any-version-p))))))

(defun h//format-entry (entry &optional format formats)
  "Return ENTRY formatted according to FORMAT.
FORMAT is a `format-spec' specifier string which maps to specifications
according to FORMATS, by default `hyperdrive-formats', which see."
  (pcase-let* (((cl-struct hyperdrive-entry hyperdrive name path version) entry)
               (formats (or formats h/formats)))
    (cl-labels ((fmt (format value)
                  (if value
                      (format (alist-get format formats) value)
                    "")))
      (propertize
       ;; TODO(deprecate-28): Use lambdas in each specifier.
       (format-spec (or format h/default-entry-format)
                    `((?n . ,(fmt 'name name))
                      (?p . ,(fmt 'path path))
                      (?v . ,(fmt 'version version))
                      (?H . ,(h//preferred-format hyperdrive nil formats))
                      (?D . ,(h//format hyperdrive "%D" formats))
                      (?k . ,(h//format hyperdrive "%k" formats))
                      (?K . ,(h//format hyperdrive "%K" formats))
                      (?N . ,(h//format hyperdrive "%N" formats))
                      (?P . ,(h//format hyperdrive "%P" formats))
                      (?S . ,(h//format hyperdrive "%S" formats))))
       'help-echo (he/url entry)))))

(defun h//entry-directory-p (entry)
  "Return non-nil if ENTRY is a directory."
  (string-suffix-p "/" (he/path entry)))

(defun h/message (message &rest args)
  "Call `message' with MESSAGE and ARGS, prefixing MESSAGE with \"Hyperdrive:\"."
  (apply #'message
         (concat "Hyperdrive: " (substitute-command-keys message)) args))

(defun h/user-error (format &rest args)
  "Call `user-error' with FORMAT and ARGS, prefixing FORMAT with \"Hyperdrive:\"."
  (apply #'user-error
         (concat "Hyperdrive: " (substitute-command-keys format)) args))

(cl-defun h//format-path (path &key directoryp)
  "Return PATH with a leading slash if it lacks one.
When DIRECTORYP, also add a trailing slash to PATH if it lacks one.
When PATH is nil or blank, return \"/\"."
  (if (or (not path) (string-blank-p path))
      "/"
    (expand-file-name (if directoryp
                          (file-name-as-directory path)
                        path)
                      "/")))

;;;; Utilities

(defun h/time-greater-p (a b)
  "Return non-nil if time value A is greater than B."
  (not (or (time-less-p a b)
           (time-equal-p a b))))

(defun h//clean-buffer (&optional buffer)
  "Remove all local variables, overlays, and text properties in BUFFER.
When BUFFER is nil, act on current buffer."
  (with-current-buffer (or buffer (current-buffer))
    ;; TODO(deprecate-28): Call `kill-all-local-variables' with argument to also kill permanent-local variables.
    ;; We're not sure if this is absolutely necessary, but it seems like a good
    ;; idea.  But on Emacs 28 that function does not take an argument, and
    ;; trying to do so conditionally causes a native-compilation error, so we
    ;; omit it for now.
    (kill-all-local-variables)
    (let ((inhibit-read-only t))
      (delete-all-overlays)
      (set-text-properties (point-min) (point-max) nil))))

(defun h//set-auto-mode ()
  "Set major mode according to file extension, prompting for safety."
  (let ((entry (h//context-entry))
        (hyperdrive (h//context-hyperdrive)))
    (when (eq 'unknown (h/safe-p hyperdrive))
      (call-interactively #'h/mark-as-safe))
    ;; Check safe-p again after potential call to `h/mark-as-safe'.
    (when (eq t (h/safe-p hyperdrive))
      (let ((buffer-file-name (he/name entry)))
        (set-auto-mode t)))))

(defun he/equal-p (a b &optional any-version-p)
  "Return non-nil if hyperdrive entries A and B are equal.
Compares only public key, version, and path.  If ANY-VERSION-P,
treat A and B as the same entry regardless of version."
  (pcase-let (((cl-struct hyperdrive-entry (path a-path) (version a-version)
                          (hyperdrive (cl-struct hyperdrive (public-key a-key))))
               a)
              ((cl-struct hyperdrive-entry (path b-path) (version b-version)
                          (hyperdrive (cl-struct hyperdrive (public-key b-key))))
               b))
    (and (or any-version-p (eq a-version b-version))
         (equal a-path b-path)
         (equal a-key b-key))))

(defun h/equal-p (a b)
  "Return non-nil if hyperdrives A and B are equal.
Compares their public keys."
  (equal (h/public-key a) (h/public-key b)))

(defun he/hyperdrive-equal-p (a b)
  "Return non-nil if entries A and B have the same hyperdrive."
  (h/equal-p (he/hyperdrive a) (he/hyperdrive b)))

(defun he/within-version-range-p (entry entry-with-next-version-number)
  "Return non-nil if ENTRY is within range of ENTRY-WITH-NEXT-VERSION-NUMBER."
  (let* ((latest-version (h/latest-version (he/hyperdrive entry)))
         (range-start (he/version entry-with-next-version-number))
         (version (or (he/version entry) latest-version))
         (range-end
          (if-let ((next-version-number
                    (map-elt (he/etc entry-with-next-version-number)
                             'next-version-number)))
              (1- next-version-number)
            latest-version)))
    (<= range-start version range-end)))

(defun h/safe-p (hyperdrive)
  "Return whether HYPERDRIVE is safe or not.
Potential return values are t, nil, or \\+`unknown'.  If ETC slot
has no value for \\+`safep', return \\+`unknown'."
  (map-elt (h/etc hyperdrive) 'safep 'unknown))

(defun h/safe-string (hyperdrive)
  "Return string with face property describing HYPERDRIVE safety."
  (pcase-exhaustive (h/safe-p hyperdrive)
    ('t (propertize "safe" 'face 'h/safe))
    ('nil (propertize "unsafe" 'face 'h/unsafe))
    ('unknown (propertize "unknown" 'face 'h/safe-unknown))))

(defun h//ensure-dot-slash-prefix-path (path)
  "Return PATH, ensuring it begins with the correct prefix.
Unless PATH starts with \"/\" \"./\" or \"../\", add \"./\"."
  (if (string-match-p (rx bos (or "/" "./" "../")) path)
      path
    (concat "./" path)))

(defun h/org-filename-p (path)
  "Return non-nil when PATH is an Org file."
  (string-suffix-p ".org" path))

(provide 'hyperdrive-lib)

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("he//" . "hyperdrive-entry--")
;;   ("he/"  . "hyperdrive-entry-")
;;   ("h//"  . "hyperdrive--")
;;   ("h/"   . "hyperdrive-"))
;; End:
;;; hyperdrive-lib.el ends here
