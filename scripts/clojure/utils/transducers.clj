#!/usr/bin/env -S clojure-shebang

(ns utils.transducers)

;; https://andreyor.st/posts/2024-01-31-using-transducers/
;; https://andreyor.st/posts/2022-08-13-understanding-transducers/

(comment
  (reduce + (filter odd? (map inc (range 10)))))

(comment
  (def double-the-num
    (fn [i] (* 2 i)))
  ;; I find it interesting that a backtick is not required
  (map double-the-num (range 10)))

;; Thread macro
(comment
  ;; With regards to the previous expression in the
  ;; body of `->` or `-->`:
  ;; - thread-first (`->`) puts it as the first argument,
  ;; - thread-last (`->>`) puts it as the last
  
  (->> (range 10)

       (map inc)
       (filter odd?)
       (reduce +))

  (-> (range 10)

      ;; ((fn [f a b] (f)))
      (map inc)
      (filter odd?)
      (reduce +)))

