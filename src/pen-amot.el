;; Make something like Ray's Maze (AMOT) Inside of emacs


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
          :documentation "Phone number."))
  "A class for tracking people I know.")


(provide 'pen-amot)
