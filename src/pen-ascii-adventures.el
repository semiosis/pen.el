(require 'pen-hypertext)

;; Remember
;; Every slot that appears in each parent class is replicated in the new class.

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
(defclass aa/place ()                      ; No superclasses
  ((name :initarg :name
         ;; This gives the default name. It is empty.
         :initform ""
         :type string
         :custom string
         :documentation "An area.")
   (animation-speed :initarg :timer
                    :initform 1
                    :custom integer
                    :type integer
                    :documentation "The animation speed.")

   ;; Items you can take
   (inventory :initarg :timer
              :initform 1
              :custom integer
              :type integer
              :documentation "The animation speed.")
   ;; (frames :initarg :phone
   ;;         :initform ""
   ;;         :documentation "Phone number.")
   )
  "A class for describing an area.")

;; TODO Open the house.org file in j:hypertext-mode
;; Hypertext mode will be renamed as ascii-adventures-mode
;; because it will be the major mode for playing the game.
;; j:open-hypertext
;; j:load-place-from-file

;; OK, so how do I store game state?
;; I should probably use an emacs buffer for the game state
;; That way, I can open the buffer to tweak variable as the game is running'

;; I guess that I will use objects to store game state.
;; However, it may be better to use org files to store the state.

;; Here, area is a variable
;; Make methods as I need them
(comment
 (cl-defmethod aa/goto-place ((area place) &optional scriptname)
   ""
   (message "Going to %s"  (slot-value area 'name))

   (slot-value pers 'animation-speed)))

;; I won't typically need to have many areas remain open in memory,
;; because I will be only at a single place at a time.
;; But, actually, I *do* want persistent world state.
;; How will I do that?

(defset entrance
        (aa/place :name "House" :timer 1))

;; Do I really want to maintain a separate state?
;; It *would* be useful for automating the game, of course:
;; - searching for things.
;; If it was filesystem-based-state then it would work nicely across hyperdrive, for example.
(comment
 (defset entrance
         (make-instance 'aa/place :name "House" :timer 1))
 ;; Rename the area
 (set-slot-value entrance 'name "Big house")

 (aa/place-p entrance)
 
 (slot-value entrance 'name)
 (oref entrance name)
 (oref-default entrance name)

 ;; Rename the house yet again
 (oset entrance name "Giant house")

 ;; Change the default name for new objects of type  aa/place
 (oset-default aa/place name "Unnamed place")

 (object-add-to-list entrance 'objects item &optional append))

;; OK, so I need to think about how I load this
(defun load-place-from-file (path)
  (setq path (umn path))

  ;; I guess this is parsing it twice
  (let ((parse (org-parser-parse-file filename))
        (b (open-hypertext-in-buffer path)))))

(comment
 (load-place-from-file "$HOME/notes/ws/ascii-adventures/house.org")

 (open-hypertext))

(provide 'pen-ascii-adventures)
