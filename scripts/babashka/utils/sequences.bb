(ns utils.sequences
  ;; (:require [babashka.deps :as deps])
  )

;; https://clojure.org/reference/sequences
;; https://clojuredocs.org/clojure.core/sequence

(sequence [1 2 3])


;; Make a transducer
(def xf (comp (filter odd?) (take 5)))
(sequence xf (range 1 10))


;; turns a string into a sequence of characters:
(sequence "abc")

;; combine a bunch of collections together
(sequence cat [[1 2 3] [5 6 7] [8 9 0]])
