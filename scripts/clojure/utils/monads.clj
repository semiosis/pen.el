#!/usr/bin/env -S clojure-shebang
;; #!/usr/bin/env -S clojure-shebang -dep "org.clojure/algo.monads {:mvn/version \"0.2.0\"}"
;; When using as a script, the deps must be added this way.
;; But I must also add the deps to the project edn file.

;; DONE. Works. Figure out how to add monads to the deps of this script using a project edn.

;; https://github.com/clojure/algo.monads?tab=readme-ov-file
;; https://github.com/khinsen/monads-in-clojure/blob/master/PART1.md
;; https://github.com/khinsen/monads-in-clojure/blob/master/PART2.md
;; https://github.com/khinsen/monads-in-clojure/blob/master/PART3.md
;; https://github.com/khinsen/monads-in-clojure/blob/master/PART4.md
;; https://www.leonardoborges.com/writings/2012/11/30/monads-in-small-bites-part-i-functors/
;; https://www.leonardoborges.com/writings/2012/12/02/monads-in-small-bites-part-ii-applicative-functors/
;; https://www.leonardoborges.com/writings/2012/12/05/monads-in-small-bites-part-iii-monoids/
;; https://www.leonardoborges.com/writings/2012/12/08/monads-in-small-bites-part-iv-monads/

;; I'm determined to use the standard clojure interpreter for scripting alongside babashka.

(ns utils.monads
  ;; Is there something like babashka.deps for clojure?
  ;; (:require [babashka.deps :as deps])
  )

(comment
  (require '[clojure.repl.deps :refer :all]))

;; Sadly, add-lib is only available at the repl.
(comment
  (add-lib 'org.clojure/core.memoize {:mvn/version "0.7.1"})
  (add-lib 'org.clojure/algo.monads {:mvn/version "0.2.0"}))

(require '[clojure.algo.monads :as m])

(let [a  1
      b  (inc a)]
  (* a b))

;; The functional equivalent of the let form.
;; - The computational steps appear in reverse order
((fn [a]
   ((fn [b]
      (* a b))
    (inc a)))
 1)

;; We can put the steps in the right order with a small helper function, bind
(defn m-bind [value function]
  (function value))
(m-bind 1        (fn [a]
(m-bind (inc a)  (fn [b]
        (* a b)))))

;; TODO Run macroexpand on this
(println
 (m/domonad m/identity-m
            [a  1
             b  (inc a)]
            (* a b)))

(clojure.algo.monads/with-monad m/identity-m
  (m-bind 1 (fn [a] (m-bind (inc a) (fn [b] (m-result (* a b)))))))
