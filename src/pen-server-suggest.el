;; TODO
;; https://github.com/dbcli/mycli

;; docker run --rm -p 5432:5432 -e POSTGRES_PASSWORD=admin -e POSTGRES_USER=admin -e POSTGRES_DB=main -v "$(pwd):/$(pwd | slugify)" -w "/$(pwd | slugify)" -ti --entrypoint= postgres:alpine docker-entrypoint.sh postgres
;; psql -U admin -h localhost -p 5432 main
;; docker run --network=host --rm -v "$(pwd):/$(pwd | slugify)" -w "/$(pwd | slugify)" -ti --entrypoint= pygpen-pgcli:stable /sbin/tini -- /usr/bin/pgcli -h localhost -p 5432 -d main -U admin -W

;; docker-run-postgres
;; pgcli -h localhost -p 5432 -d main -U admin -W

;; TODO Extend this to also show what the ports probably mean 
;; pen-start-tablist

;; barrier
;; 24800

;; Anything in this range is a lein repl
;; (n-get-free-port "40500" "40800")
;; lein repl :connect localhost:40500

;; I should prototype this here so I have at least something to work with
;; Then I should rebuild it in clojure

(require 'pen-net)

(defun connect-to-mysql (&optional hn port user dbname pass)
  (interactive (list (read-string-hist "mysql hn: ")
                     (read-string-hist "mysql port: ")
                     (read-string-hist "mysql user: ")
                     (read-string-hist "mysql db: ")
                     (read-string-hist "mysql pw: ")))

  (if (not (sor hn)) (setq hn "localhost"))
  (if (not (sor port)) (setq port "3306"))
  (if (not (sor user)) (setq user "admin"))
  (if (not (sor dbname)) (setq dbname "main"))
  (if (not (sor pass)) (setq pass "admin"))

  (pen-sps (concat (cmd
                "mycli"
                "-initcmd" "\\d"
                "-h" hn
                "-p" port
                "-D" dbname
                "-y" user
                "-p" pass)
               "; pen-pak")))

(defun connect-to-postgres (&optional hn port user dbname pass)
  (interactive (list (read-string-hist "pg hn: ")
                     (read-string-hist "pg port: ")
                     (read-string-hist "pg user: ")
                     (read-string-hist "pg db: ")
                     (read-string-hist "pg pw: ")))

  (if (not (sor hn)) (setq hn "localhost"))
  (if (not (sor port)) (setq port "5432"))
  (if (not (sor user)) (setq user "admin"))
  (if (not (sor dbname)) (setq dbname "main"))
  (if (not (sor pass)) (setq pass "admin"))

  (pen-sps (concat (cmd
                "pgcli"
                "-pw" pass
                "-initcmd" "\\d"
                "-h" hn
                "-p" port
                "-d" dbname
                "-U" user
                "-W")
                   "; pen-pak")))

;; cdr is a list of suggested commands I can fuzzy search through
;; They are lists which will be evalled as a function call
;; Therefore, they may make use of
;; The first argument to each function must be the hostname
;; The second argument must be the port
;; I also need a port range -- how to best check for matching within a port range?

;; The lein repl is also recorded here
;; $MYGIT/gigasquid/libpython-clj-examples/.nrepl-port
;; TODO This is a use-case for searching ranges
;; I really shouldn't be using algorithms for something like this.
;; However, I want to get good at algorithms, so maybe I should.
(defset pen-server-command-tuples
  `((22 . ((pen-sps (pen-cmd "zrepl" "-cm" "ssh" "-vvv" "-o" "BatchMode=no"
                             hn "-p" port))))
    (80 . ((chrome (concat "http://" hn ":" port))
           (eww (concat "http://" hn ":" port))))
    (8680 . ((pen-clomacs-connect)))
    (,(pen-get-khala-port) . ((khala-stop)))
    ;; Unsure how to check this atm.
    ((40500 40800) . ((chrome (concat "http://" hn ":" port))
                      (eww (concat "http://" hn ":" port))))
    (443 . ((chrome (concat "https://" hn ":" port))
            (eww (concat "https://" hn ":" port))))
    (4334 . ((zrepl "datomic-connect-db hello")))
    (3306 . ((call-interactively 'connect-to-mysql)
             (call-interactively 'sql-mysql)))
    (5432 . ((connect-to-postgres hn port "admin" "main" "admin")
             (connect-to-postgres hn port "ahungry" "ahungry" "ahungry")
             (call-interactively 'connect-to-postgres)
             (call-interactively 'sql-postgres)))))

;; I want to do some kind of 'join' on two maps

;; Dear Lord, I really need first-class maps
;; I need Clojure.
;; (defun pen-n-list-open-ports-tree (&optional hn)
;;   (let ((ps (list-open-ports hn))
;;         (al))
;;     (cl-loop for tp in ps do
;;              (let ((tphn (car tp))
;;                    (port (string-to-number (cadr tp))))))))

(defun pen-server-suggestions (hostname &optional fast)
  (interactive (list (read-string-hist "hostname: ")))
  (let* ((hnopen
          (mapcar
           (λ (tp) (-drop 1 tp))
           (-filter (λ (tp) (string-equal hostname (car tp)))
                    (pen-n-list-open-ports hostname t))))
         (openmap
          (mapcar
           (λ (tp)
             (cons (string-to-number (car tp))
                   (cdr tp)))
           hnopen))
         (suggestions
          (flatten-once
           (-filter
            'identity
            (cl-loop
             for tp in
             openmap
             collect
             ;; https://en.wikipedia.org/wiki/Relational_algebra
             ;; outer join is what i'm thinking of
             ;; how do pen-i fill the missing values using an outer join a list of tuples?
             ;; I think I should flatten once
             (let* ((cand (assoc (car tp) pen-server-command-tuples))
                    (hnport (list hostname (car cand)))
                    (cs (cdr cand)))
               (if cand
                   (cl-loop for subtp in cs collect
                            (append hnport subtp)))))))))
    suggestions))

(defun pen-server-suggest (hostname)
  (interactive (list (read-string-hist "hostname: ")))
  (message "Suggesting clients for %s. Please wait." hostname)
  (let* ((ss (pen-server-suggestions
              hostname
              ;; Make it fast if it's not localhost
              (not (string-equal "localhost" hostname))))
         (c (fz (mapcar 'pp-oneline ss)
                nil nil
                "server-suggest: ")))
    (if c
        (let* ((sel (pen-eval-string (concat "'" c)))
               (hn (car sel))
               (port (str (cadr sel)))
               (c2 (-drop 2 sel)))
          (eval c2)))))

(provide 'pen-server-suggest)