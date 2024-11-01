(ns utils.strings
  ;; (:require [babashka.deps :as deps])
  )

(require '[clojure.string :as str]
         '[clojure.java.io :as io])

(alias 'string 'clojure.string)

(comment
  (letfn [(twice [x]
            (* x 2))
          (six-times [y]
            (* (twice y) 3))
          (uc [s]
            (str/upper-case s))]

    (let [s "MiXeD cAsE"
          separator "/"]
      

      (str
       (clojure.string/join separator (map uc s))
       (str/join separator (map uc s))
       (string/join separator (map uc s)))
      
      (println
       (str/join "\n"
                 [(clojure.string/join separator (map uc s))
                  (str/join separator (map uc s))
                  (string/join separator (map uc s))])))))
