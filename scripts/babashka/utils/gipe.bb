#!/usr/bin/env bb

(ns utils.gipe
  (:require [babashka.deps :as deps]
            [utils.gum :as gum]
            [utils.myshell :as myshell]))

;; e:gum.bb

(require '[babashka.process :refer [shell process exec]])
(require '[clojure.data.csv :as csv])

(defn test
  ""
  []
  (myshell/snc "echo hi | tpop -E \"PEN_PROMPT=PEN_PROMPT PEN_HELP=PEN_HELP gipe.bb\""))

;; (deps/add-deps '{:deps {io.github.justone/bb-scripts {:sha "ecbd71747dd0527243286d98c5a209f6890763ff"}}})

(require '[clojure.string :as str]
         '[clojure.java.io :as io])

;; (b/gum {:cmd :confirm :as :bool :args ["Are you ready?"]})

;; (gum/input )

;; (gum/header "dsufoi")

(println (System/getenv "PEN_PROMPT"))

(gum/header (System/getenv "PEN_HELP"))

;; export PEN_PROMPT
;; export PEN_HELP
;; export PEN_OVERLAY
;; export PEN_PREOVERLAY
;; export PEN_EIPE_DATA
;; [[sps:v +/"pen -notm -nw --pool" "$EMACSD/pen.el/scripts/pen-eipe"]]

;; Collect stdin and put it into value:

;; (input :value "T" :placeholder "Type...")

;; This works
;; echo hi | tpop -E "PEN_PROMPT=PEN_PROMPT PEN_HELP=PEN_HELP gipe.bb"

(gum/input :value user/*input* :placeholder "Type stdin...")

;; (write "value" "Type...")
(gum/write "" "Type...")

;; export PEN_OVERLAY
;; export PEN_PREOVERLAY
;; export PEN_EIPE_DATA

;; (table (slurp "/root/.emacs.d/host/pen.el/config/pen/cross_references.csv"))
;; (table (slurp "/root/.emacs.d/host/pen.el/config/pen/tablist-test.csv"))

;; This CSV works
(gum/table (slurp "/root/.emacs.d/host/pen.el/config/pen/mygit-30.08.22.csv"))

(gum/choose ["a" "b" "c"] :limit 1)

(System/exit
 (if
     (confirm "yo")
     0
     1))

