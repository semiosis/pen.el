(require 'emacsql)
(require 'emacsql-mysql)
(require 'emacsql-psql)
(require 'emacsql-sqlite)
(require 'emacsql-sqlite3)

;; emacsql is actually atrocious
;; But emacs29 has too many problems to upgrade right now in order to get emacs-sqlite

;; TODO Figure out how to generate sql
;; TODO Make some wrapper functions for caching things
;; Then make some shell scripts for the same

(defset db (emacsql-sqlite (f-join penconfdir "pen.db")))


;; TODO Firstly, make a generic cache
;; query by function name, and perhaps a string match on the arguments list


(comment
 ;; Create a table. Table and column identifiers are symbols.
 (emacsql db [:create-table people ([name id salary])])

 ;; Or optionally provide column constraints.
 (emacsql db [:create-table people
                            ([name (id integer :primary-key) (salary float)])])

 ;; Insert some data:
 (emacsql db [:insert :into people
                      :values (["Jeff" 1000 60000.0] ["Susan" 1001 64000.0])])

 ;; Query the database for results:
 (emacsql db [:select [name id]
                      :from people
                      :where (> salary 62000)])
 ;; => (("Susan" 1001))

 ;; Queries can be templates, using $1, $2, etc.:
 (emacsql db [:select [name id]
                      :from people
                      :where (> salary $s1)]
          50000)
 )

(provide 'pen-emacsql)
