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

  ;; Does Clojure have a [[j:-->]] form?
  ;; Perhaps in another library?
  ;; I'd like to be able to have it.
  
  (->>
   ;; it
   (range 10)

   ;; (map inc (range 10))
   (map inc)
   (filter odd?)
   (reduce +))
  
  (-> inc
      ;; (map inc (range 10))
      (map (range 10))))

;; Transducers are used by the transduce function which is like reduce except it doesn’t
;; accept just a reducing function, it also accepts a transforming function.

;; Default behaviour in Clojure is lazy:
(->> (range 10) (map inc) (filter odd?) (reduce +))
