;; Make something like Ray's Maze (AMOT) Inside of emacs
;; Hmm. I have no idea how I'm going to design this.


(defclass person ()                     ; No superclasses
  ((name :initarg :name
         :initform ""
         :type string
         :custom string
         :documentation "The name of a person.")
   (birthday :initarg :birthday
             :initform "Jan 1, 1970"
             :custom string
             :type string
             :documentation "The person's birthday.")
   (phone :initarg :phone
          :initform ""
          :documentation "Phone number.")
   (cash :initarg :phone
         :initform ""
         :documentation "Phone number."))
  "A class for tracking people I know.")


(defclass game-state ()                 ; No superclasses
  ((name :initarg :name
         :initform ""
         :type string
         :custom string
         :documentation "The name of a person.")
   (birthday :initarg :birthday
             :initform "Jan 1, 1970"
             :custom string
             :type string
             :documentation "The person's birthday.")
   (phone :initarg :phone
          :initform ""
          :documentation "Phone number.")
   (cash :initarg :phone
         :initform ""
         :documentation "Phone number."))
  "A class for tracking people I know.")


(cl-defmethod call-person ((pers person) &optional scriptname)
  "Dial the phone for the person PERS.
     Execute the program SCRIPTNAME to dial the phone."
  (message "Dialing the phone for %s"  (slot-value pers 'name))
  (shell-command (concat (or scriptname "dialphone.sh")
                         " "
                         (slot-value pers 'phone))))


(provide 'pen-amot)
