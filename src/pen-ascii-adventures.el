;; The 'place' has an animated, clickable

;; e:$EMACSD/pen.el/src/pen-hypertext.el

(defun aa/map ()
  "This should display the map.

A map should mainly simply connect places together.
"
  (interactive)
  (message "%s" "Go to the map"))

;; Yeah, call it a 'place'.
(defclass place ()                      ; No superclasses
  ((name :initarg :name
         :initform ""
         :type string
         :custom string
         :documentation "An area.")
   (animation-speed :initarg :birthday
                    :initform 1
                    :custom integer
                    :type integer
                    :documentation "The animation speed.")
   (frames :initarg :phone
           :initform ""
           :documentation "Phone number.")
   (cash :initarg :phone
         :initform ""
         :documentation "Phone number."))
  "A class for tracking people I know.")

(provide 'pen-ascii-adventures)
