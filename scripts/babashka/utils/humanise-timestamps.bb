#!/usr/bin/env bb

;; DONE Get this working

;; cat sample.edn| humanise-timestamps.bb

;; (ns humanise-timestamps)
(ns utils.humanise-timestamps
  (:require [babashka.deps :as deps]
            [clojure.walk :as walk]
            [utils.myshell :as myshell])
  (:import (java.time Instant
                      ZoneId
                      OffsetDateTime)
           (java.time.format DateTimeFormatter)))

(comment
  (require '[clojure.walk :as walk])
  (require '[utils.myshell :as myshell]))

(def timestamp-format (DateTimeFormatter/ofPattern "yyyy-MM-dd h:mm:ss.SS a"))

;; TODO It reads the date-ts -mili timestamp
(comment
  (format-ts (read-string (myshell/she "date-ts -mili"))))

(comment
  (format-ts (read-string "1697642960678")))

(defn format-ts
  [ts]
  (.format (OffsetDateTime/ofInstant (Instant/ofEpochMilli ts) (ZoneId/systemDefault)) timestamp-format))

#_(java.time.Instant/ofEpochMilli 1655238854479)

(defn humanise-timestamps
  [m]
  (walk/postwalk
   (fn [current]
     (let [[k v] (when (map-entry? current) current)]
       (if (and (keyword? k)
                (= "timestamp" (name k))
                (number? v))
         [k (format-ts v)]
         current)))
   m))

(when (= *file* (System/getProperty "babashka.file"))
  (binding [*print-namespace-maps* false]
    (->> (map humanise-timestamps user/*input*)
         (run! prn))))
