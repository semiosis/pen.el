#!/usr/bin/env bb

;; TODO Get this working

;; (ns humanise-timestamps)
(ns humanise-timestamps
  (:require [babashka.deps :as deps]
            [clojure.walk :as walk])
  (:import (java.time Instant
                      ZoneId
                      OffsetDateTime)
           (java.time.format DateTimeFormatter)))

(comment
  (require '[clojure.walk :as walk]))

(def timestamp-format (DateTimeFormatter/ofPattern "yyyy-MM-dd h:mm:ss.SS a"))

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
