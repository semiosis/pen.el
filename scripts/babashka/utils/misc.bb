#!/usr/bin/env bbb

(ns utils.misc)

(use '[clojure.java.shell :only [sh]])

(eval '(+ 1 2))

;; Query a namespace -- list functions, etc.
(dir clojure.string)
;; In Rebel, the FQ name is required
(clojure.repl/dir clojure.string)

(let [f (new File ".")] (clojure.repl/dir f))
;; No namespace: f found


(defn escape-string [x]
  (clojure.string/replace x #"^[':\\]" "\\\\$0"))

(defn q [s]
  (:out (sh "q" "-f" :in s)))

(defn cmd2list [cmd]
  (clojure.string/split-lines (:out (sh "sh" "-c" (str "args2lines " cmd)))))


;; Drop to REPL
;; https://stackoverflow.com/questions/67454150/how-to-drop-into-a-repl-inside-a-clojure-function-and-print-the-stack-traces
;; Can I make this work in a tmux split?
;; Still can't eval locals. So this is useless.
(defmacro break! []
  (let [locals (into {} (map (juxt keyword identity)) (keys &env))]
    (prn locals)
    (clojure.main/repl :prompt #(print "nested> "))))

(require '[clojure.pprint :as pp])
(defn pprint-to-string
  ""
  [o]
  (with-out-str (clojure.pprint/pprint o)))
(def pps pprint-to-string)


;; This appears to hang
(defn tv
  ""
  [s]
  (sh "tv" :in s)
  s)

(defn mnm [s]
  (:out (sh "mnm" :in s)))
(defn umn [s]
  (:out  (sh "umn" :in s)))

;; TODO Make my filesystem functions unminimise stuff
;; and use my own library of functions.

(defn myslurp
  ""
  [s]
  (slurp (umn s)))

;; Is there an advice/decorator syntax in clojure?
;; There probably isn't.

(comment
  ;; Read entire file
  (myslurp "$EMACSD/pen.el/scripts/babashka/utils/misc.bb")
  (slurp "my-utf8-file.txt" "UTF-8"))

(def with-output-to-string 'with-out-str)

(defmacro mu
  ""
  [& exprs]
  (let [s (pps exprs)
        ucode (umn s)
        newcode (read-string ucode)]

    ;; (tv (pps newstr))
    `(do $HOME@newcode)))


(require 'cljfmt.core)
;; (cljfmt.core/reformat-string "")
