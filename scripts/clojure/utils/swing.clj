#!/usr/bin/env -S clojure-shebang

;; NOTE : Java apps should be set to float in xmonad
;; But I can't currently recompile xmonad.
;; , resource  =? "sun-awt-X11-XFramePeer"     --> doFloat
;; So instead, consider using a xephyr.

;; To get the main function to run, run like this:
;; #!/usr/bin/env -S clojure-shebang -m utils.swing

(ns utils.swing
  (:import [javax.swing JFrame JLabel JButton]
           [java.awt.event WindowListener]))

(defn swing []
  (let [frame (JFrame. "Fund manager")
        label (JLabel. "Exit on close")]
    (doto frame
      (.add label)
      (.setDefaultCloseOperation JFrame/EXIT_ON_CLOSE)
      (.addWindowListener
       (proxy [WindowListener] []
         (windowClosing [evt]
           (println "Whoop"))))
      (.setVisible true))))

(defn -main [& args]
  (swing))
