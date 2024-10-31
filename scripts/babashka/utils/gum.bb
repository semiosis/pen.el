#!/usr/bin/env bb

(ns utils.gum
  (:require [babashka.deps :as deps]))

(deps/add-deps '{:deps {io.github.justone/bb-scripts {:sha "ecbd71747dd0527243286d98c5a209f6890763ff"}}})

(require '[clojure.string :as str]
         '[clojure.java.io :as io])

(defn header [msg]
  (shell (format "gum style --padding 1 --foreground 212 '%s'" msg)))

(defn input [& {:keys [value placeholder] :or {value "" placeholder ""}}]
  (-> (shell {:out :string}
             (format "gum input --placeholder '%s' --value '%s'" placeholder value))
      :out
      str/trim))

(defn write [value placeholder]
  (-> (shell {:out :string}
             (format "gum write --show-line-numbers --placeholder '%s' --value '%s'" placeholder value))
      :out
      str/trim))

(defn table [csv]
  (let [data (csv/read-csv csv)
        headers (->> data
                     first
                     (map str/upper-case))
        num-headers (count headers)
        width (int (/ 100.0 num-headers))
        cmd (format "gum table --widths %s" (str/join "," (repeat num-headers width)))]
    (shell {:in csv :out :string} cmd)))

(defn confirm [msg]
  (-> (shell {:continue true}
             (format "gum confirm '%s'" msg))
      :exit
      zero?))

(defn choose
  [opts & {:keys [no-limit limit]}]
  (let [opts (str/join " " opts)
        limit (str "--limit " (or limit 1))
        no-limit (if no-limit (str "--no-limit") "")
        cmd (format "gum choose %s %s %s" limit no-limit opts)]
    (-> (shell {:out :string} cmd)
        :out
        str/trim
        str/split-lines)))

(b/gum {:cmd :confirm :as :bool :args ["Are you ready?"]})
