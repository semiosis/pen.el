#!/usr/bin/env bbb

(ns utils.aliases)

(def sym2str name)

;; Contrib is deprecated though
;; A synonym for a macro must be defined using a macro
;; or with clojure.contrib.def/defalias
;; https://stackoverflow.com/questions/1317396/define-a-synonym-for-a-clojure-macro
;; (def 'foreach 'doseq)
(defmacro foreach [& args] `(doseq $HOME@args))
