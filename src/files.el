(defun buffers--ask-user-about-large-buffer (size op-type buffername offer-raw)
  "Query the user about what to do with large buffers.
Buffers are \"large\" if buffer SIZE is larger than `large-buffer-warning-threshold'.

OP-TYPE specifies the buffer operation being performed on BUFFERNAME.

If OFFER-RAW is true, give user the additional option to open the
buffer literally."
  (let ((prompt (format "Buffer %s is large (%s), really %s?"
		        (buffer-name-nondirectory buffername)
		        (funcall byte-count-to-string-function size) op-type)))
    (if (not offer-raw)
        (if (y-or-n-p prompt) nil 'abort)
      (let ((choice
             (car
              (read-multiple-choice
               prompt '((?y "yes")
                        (?n "no")
                        (?l "literally"))
               (buffers--ask-user-about-large-fileOB-help-text
                op-type (funcall byte-count-to-string-function size))))))
        (cond ((eq choice ?y) nil)
              ((eq choice ?l) 'raw)
              (t 'abort))))))

(defun around-advice-large-file-ask (proc &rest args)
  (let ((procname (first (str2lines (scrape "\".*\"" (pps proc)))))
        (size (buffer-size)))
    (if (not (files--ask-user-about-large-file 500 procname buffer-file-name nil))
        (let ((res (apply proc args)))
          res))))
(advice-add 'isearch-forward-region :around #'around-advice-large-file-ask)
(advice-remove 'isearch-forward-region #'around-advice-large-file-ask)

(files--ask-user-about-large-file 500 "search" buffer-file-name nil)
(buffers--ask-user-about-large-buffer 500 "search" buffer-file-name nil)
