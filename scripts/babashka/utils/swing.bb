(ns swing
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
