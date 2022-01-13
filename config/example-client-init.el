;; TODO Make two melpa packages? Or one?
;; Call it Pen Client, or ilambda?

(add-to-list 'load-path "/home/shane/source/git/semiosis/pen.el/src/")

(require 'pen-client)
(require 'ilambda)

(setq iλ-thin t)

(idefun thing-to-hex-color (thing))

(thing-to-hex-color "watermelon")

(pen-tv (pen-human (thing-to-hex-color "surreptitious strawberry")))
