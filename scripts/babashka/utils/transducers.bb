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
  
  (->> (range 10)

       (map inc)
       (filter odd?)
       (reduce +))

  (-> (range 10)

       (map inc)
       (filter odd?)
       (reduce +)))
