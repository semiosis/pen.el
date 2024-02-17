;; The 'place' has an animated, clickable

;; e:$EMACSD/pen.el/src/pen-hypertext.el

(defun aa/map ()
  "This should display the map.

A map should mainly simply connect places together.
"
  (interactive)
  (message "%s" "Go to the map"))

;; Yeah, call it a 'place'.
;; [[info:(eieio) Slot Options]]
(defclass place ()                      ; No superclasses
  ((name :initarg :name
         :initform ""
         :type string
         :custom string
         :documentation "An area.")
   (animation-speed :initarg :timer
                    :initform 1
                    :custom integer
                    :type integer
                    :documentation "The animation speed.")
   ;; (frames :initarg :phone
   ;;         :initform ""
   ;;         :documentation "Phone number.")
   )
  "A class for describing an area.")

;; Here, area is a variable
(cl-defmethod aa/goto-place ((area place) &optional scriptname)
  "Dial the phone for the person PERS.
     Execute the program SCRIPTNAME to dial the phone."
  (message "Going to %s"  (slot-value area 'name))

  (slot-value pers 'animation-speed))

(defvar entrance
  (person :name "Eric" :birthday "June" :phone "555-5555"))

(defun load-place-from-file (path)
  (setq path (umn path)))

(load-place-from-file "$HOME/notes/ws/ascii-adventures/house.org")

(provide 'pen-ascii-adventures)
