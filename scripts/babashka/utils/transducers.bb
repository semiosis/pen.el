(ns utils.transducers
  ;; (:require [babashka.deps :as deps])
  )

;; https://andreyor.st/posts/2024-01-31-using-transducers/
;; https://andreyor.st/posts/2022-08-13-understanding-transducers/

(comment
  (reduce + (filter odd? (map inc (range 10)))))

;; Thread macro
(comment
  ;; With regards to the previous expression in the
  ;; body of `->` or `-->`:
  ;; - thread-first (`->`) puts the  as the first argument,
  ;; - thread-last (`->>`) as the last

  ;; thread-last
  (->> (range 10)

       (map inc)
       (filter odd?)
       (reduce +))
  
  (->> (range 10)

       (mapv inc)
       (filterv odd?)
       (reduce +))

  ;; thread-first
  (-> (range 10)
      
      ;; Because with -> the `it` gets put into the first slot
      ;; I just wrap with a lambda which only has one slot
      ((fn [col] (map inc col)))
      ((fn [col] (filter odd? col)))
      ((fn [col] (reduce + col)))))

(->> (range 10)
     ;; You’ll see this character beside another e.g. #( or #".
     ;; # is a special character that tells the Clojure reader
     ;; (the component that takes Clojure source and "reads" it as Clojure data)
     ;; how to interpret the next character using a read table.
     ;; Although some Lisps allow the read table to be extended by users, Clojure does not.
     ;; The # is also used at the end of a symbol when creating generated symbols inside a syntax quote.
     ;; https://clojure.org/guides/weird_characters
     (keep #(let [x (inc %)]
              (when (odd? x)
                x)))
     (reduce +))
