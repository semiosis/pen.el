(ns utils.strings
  (:require [utils.misc :as ms])
  ;; (:require [babashka.deps :as deps])
  )

;; https://clojuredocs.org/clojure.string/replace

;; TODO Learn to 

(require '[clojure.string :as s]
         '[clojure.java.io :as io])

;; Sadly, this though it works to make a string/ namespace
;; available, it also makes the s namespace (s/) no longer
;; complete inside the cider repl
;; (alias 'string 'clojure.string)

(comment
  (letfn [(twice [x]
            (* x 2))
          (six-times [y]
            (* (twice y) 3))
          (uc [s]
            (s/upper-case s))]

    (let [s "MiXeD cAsE"
          separator "/"]
      

      (str
       (clojure.string/join separator (map uc s))
       (s/join separator (map uc s))
       ;; (string/join separator (map uc s))
       )
      
      (ms/println-and-return
       (s/join "\n"
                 [(clojure.string/join separator (map uc s))
                  (s/join separator (map uc s))
                  ;; (string/join separator (map uc s))
                  ])))))
