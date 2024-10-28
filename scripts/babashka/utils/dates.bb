(ns utils.dates
  (:import java.util.Date
           java.util.Calendar))

(comment
  ;; Make a new instance
  (Date.))

(comment
                                        ; Use . to call methods. Or, use the ".method" shortcut
  (. (Date.) getTime)                   ; <a timestamp>
  (.getTime (Date.))                    ; exactly the same thing.

                                        ; Use / to call static methods
  (System/currentTimeMillis)          ; <a timestamp> (system is always present)

                                        ; Use doto to make dealing with (mutable) classes more tolerable
  ;; How come I can't import the Caldendar class?
  (import java.util.Calendar)
  (doto (Calendar/getInstance)
    (.set 2000 1 1 0 0 0)
    .getTime)) ; => A Date. set to 2000-01-01 00:00:00
