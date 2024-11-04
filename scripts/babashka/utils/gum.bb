#!/usr/bin/env bb

(ns utils.gum
  (:require [babashka.deps :as deps]
            [utils.myshell :as myshell]))

;; (deps/add-deps '{:deps {io.github.justone/bb-scripts {:sha "ecbd71747dd0527243286d98c5a209f6890763ff"}}})

(require '[babashka.process :refer [shell process exec]])
(require '[clojure.data.csv :as csv])

;; (deps/add-deps '{:deps {io.github.justone/bb-scripts {:sha "ecbd71747dd0527243286d98c5a209f6890763ff"}}})

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

(defn get-tty-width
  ""
  []
  ;; (myshell/snc "tm-resize")
  (read-string (str/trim (myshell/snc "tm-resize | sed -n '1s/^[A-Z]\\+=\\([0-9]\\+\\).*/\\1/p'"))))

(defn table [csv]
  (let [data (csv/read-csv csv)
        headers (->> data
                     first
                     (map str/upper-case))
        num-headers (count headers)
        width (- (int (/ (or (get-tty-width)
                             100) num-headers))
                 1)
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

;; (b/gum {:cmd :confirm :as :bool :args ["Are you ready?"]})

;; (input )

(comment
  (header "Header!")

  ;; (input :value "T" :placeholder "Type...")
  (input :placeholder "Type...")

  ;; (write "value" "Type...")
  (write "" "Type...")

  ;; (table (slurp "$EMACSD/pen.el/config/pen/cross_references.csv"))
  ;; (table (slurp "$EMACSD/pen.el/config/pen/tablist-test.csv"))

  ;; This CSV works
  (table (slurp "/root/.emacs.d/host/pen.el/config/pen/mygit-30.08.22.csv"))

  (choose ["a" "b" "c"] :limit 1)

  (System/exit
   (if
       (confirm "yo")
       0
       1)))
