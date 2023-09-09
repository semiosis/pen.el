(require 'popup)

(let ((popup (popup-create (point) 10 10)))
  (popup-set-list popup '("Foo" "Bar" "Baz"))
  (popup-draw popup)
  ;; do something here
  (popup-delete popup))


(defun popup-menu-item-of-mouse-event (event)
  (lo (when (and (consp event)
                 (memq (cl-first event) '(mouse-1 mouse-2 mouse-3 mouse-4 mouse-5)))
        (let* ((position (cl-second event))
               (object (elt position 4)))
          (when (consp object)
            (get-text-property (cdr object) 'popup-item (car object)))))))


;; This is cool
(popup-cascade-menu '(("Top1" "Sub1" "Sub2") "Top2"))

(provide 'pen-popup)


