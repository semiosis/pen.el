;; This should be for debugging and profiling

(define-key pen-map (kbd "s-P P") 'profiler-start)
(define-key pen-map (kbd "s-P S") 'profiler-stop)
(define-key pen-map (kbd "s-P R") 'profiler-report)

(define-key pen-map (kbd "s-D D") 'debug-on-entry)

(provide 'pen-profiler)
