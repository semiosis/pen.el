#!/usr/bin/env bb

(ns utils.gipe
  (:require [babashka.deps :as deps]
            [utils.gum :as gum]
            [utils.myshell :as myshell]
            [utils.fzf :as fzf]))

;; e:gum.bb

(require '[babashka.process :refer [shell process exec]])
(require '[clojure.data.csv :as csv])

;; TODO Also construct the buttons, etc.:
;; e:$EMACSD/pen.el/scripts/pen-eipe

;; This comes from the emacs environment. I should really disable this environment variable in emacs.
;; (show-environment)
;; (setenv "TMUX_PANE" "")
;; That was a sufficient solution to the problem.

;; TODO make a way of getting the exact pane, or disabling this environment variable form the repl
;; v +/"unset TMUX_PANE" "$PENELD/scripts/clojure-lsp"
;; TODO See if I can get the pane from the repl
;; (System/getenv "TMUX_PANE")
(defn test
  ""
  []
  (myshell/snc "echo hi | tpop -E \"PEN_PROMPT=PEN_PROMPT PEN_HELP=PEN_HELP gipe.bb\""))

(defn test2
  ""
  []
  (myshell/snc "echo hi | tpop vipe v"))

;; (deps/add-deps '{:deps {io.github.justone/bb-scripts {:sha "ecbd71747dd0527243286d98c5a209f6890763ff"}}})

(require '[clojure.string :as s]
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
(println (System/getenv "PEN_EIPE_DATA"))
;; [[sps:v +/"pen -notm -nw --pool" "$EMACSD/pen.el/scripts/pen-eipe"]]

;; Collect stdin and put it into value:

;; (input :value "T" :placeholder "Type...")

;; This works
;; echo hi | tpop -E "PEN_PROMPT=PEN_PROMPT PEN_HELP=PEN_HELP gipe.bb"

(comment
  ;; TODO work out how to do this:
  (if (clojure.core/bound? user/*input*)
    user/*input*
    "hi")

  ;; I want to be able to check to see if user/*input* is bound etc.
  ;; from PEN_EIPE_DATA
  ;; And decide if I'm going to use it or not.
  )

(gum/input :value user/*input* :placeholder "Type stdin...")

;; (write "value" "Type...")

(let [writings (gum/write "" "Type...")]
  (print (fzf/fzf writings)))

;; export PEN_OVERLAY
;; export PEN_PREOVERLAY
;; export PEN_EIPE_DATA

;; (table (slurp "/root/.emacs.d/host/pen.el/config/pen/cross_references.csv"))
;; (table (slurp "/root/.emacs.d/host/pen.el/config/pen/tablist-test.csv"))

(comment
  ;; This CSV works
  (gum/table (slurp "/root/.emacs.d/host/pen.el/config/pen/mygit-30.08.22.csv"))

  (gum/choose ["a" "b" "c"] :limit 1)

  (System/exit
   (if
       (confirm "yo")
       0
       1)))

