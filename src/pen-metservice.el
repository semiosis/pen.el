(defun get-weather-report (place)
  (interactive (list (fz '("Dunedin") nil nil "Weather for location:")))
  ;; (pen-term-sps "get-weather-report Dunedin")
  ;; (w3m "https://wttr.in/wttr")
  (w3m (format "https://wttr.in/%s" place)))

(provide 'pen-metservice)
