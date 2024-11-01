(ns khala.core
  (:require [org.httpkit.server :refer [run-server] :as server]
            [clj-time.core :as t]
            [cheshire.core :as c]
            [clj-http.client :as http]
            [compojure.core :refer :all]
            [clojure.core.async :as a]
            ;; For test-make-request
            [clojure.data.json :as json]
            [compojure.handler :as handler]
            [ring.middleware.json :as middleware]
            ;; [clojure.java.jdbc :as sql]
            [compojure.route :as route]

            [ring.util.io :refer [string-input-stream]])
  (:gen-class))

(use '[clojure.java.shell :only [sh]])
(use '[clojure.string :only (join split upper-case) :as str])

(defn cmd
  ""
  [& args]
  (clojure.string/join
   " "
   ;; I have to use the jq version so unicode works
   ;; But it's much slower. So I have to rewrite this with clojure
   (map (fn [s] (->
                 (sh "pen-q-jq" :in (str s))
                 :out)) args)))

;; (defn app [req]
;;   {:status  200
;;    :headers {"Content-Type" "text/html"}
;;    :body    (str (t/time-now))})

(defn tv [s]
  (sh "tv" :in (str s))
  s)

(defn debug [request]
  ;; (print (slurp (:body request)))
  ;; (print (slurp (:body (:body request))))
  (let* [b (:body request)
         u (:username b)
         p (:username b)]
    ;; {:status 200
    ;;  :headers {"Content-Type" "text/html"}
    ;;  :body request}
    (tv u)))

;; Post would contain payloads
;; (defroutes routes
;;   (POST "/login" request (printPostBody request))
;;   (route/not-found {:status 404 :body "<h1>Page not found</h1"}))

(defn penf [& args]
  ;; This is how to run a macro at runtime
  (eval
   `(-> (sh "unbuffer" "penf" "-u" "-nto" "--pool" "-j"
            ~@args)
        :out)))

(defn pena [& args]
  ;; This is how to run a macro at runtime
  (eval
   `(-> (sh "unbuffer" "pena" "-u" "-nto" "--pool" "-j"
            ~@args)
        :out)))

(comment
 (let [args '("pf-tweet-sentiment/1" "I love pizza")]
   (eval
    `(penf fun ~@(c/parse-string args true))))

 (let [fun "pf-tweet-sentiment/1"
       args "[\"I love pizza\"]"]
   (c/parse-string
    (apply
     penf (conj (c/parse-string args true) fun))
    true)))

(defn login
  [request]
  (let [username (get-in request [:body :username])
        password (get-in request [:body :password])]
    (sh "tv" :stdin (str request))))

;; https://www.baeldung.com/clojure-ring
;; (app {:uri "/prompt" :request-method :post :headers {"Content-Type" "application/json"} :body "{\"fun\": \"pf-tweet-sentiment/1\", \"args\": \"I love chocolate\"}"})
;; (app {:uri "/prompt" :request-method :post :headers {"content-type" "application/json" "content-length" "59"} :body "{\"fun\": \"pf-tweet-sentiment/1\", \"args\": \"I love chocolate\"}"})
;; https://github.com/http-kit/http-kit/blob/master/test/org/httpkit/client_test.clj

;; curl --header "Content-Type: application/json" --request POST --data "{\"fun\": \"pf-tweet-sentiment/1\", \"args\": \"[\\\"I love chocolate\\\"]\"}" http://127.0.0.1:9837/prompt

(defn prompt [request]
  (let* [b (:body request)
         fun (:fun b)
         args (:args b)]
    (c/parse-string
     (apply
      penf (conj (c/parse-string args true) fun))
     true)))

;; (args-to-envs {:hello-yo-yo "there" :my "friend of mine"})
(defn args-to-envs [args]
  (join "\n"
        (map (fn [[key value]]
               (str
                (str/replace
                 (upper-case
                  (name key))
                 "-" "_")
                "=" (cmd value)))
             (seq args))))

(defn debug-lm-complete []
  (->
   (sh "pen-test-proxy-lm-complete")
   :out))

;; The proxy system must be able to send back all results,
;; Not in the format of a list of directories.
;; Rather a singular json containing all results, which are reconstructed as directories
(defn lm-complete [request]
  (let* [envs-map (:body request)]
    (->
     (sh "lm-complete" :in (str
                            (args-to-envs
                             (assoc
                              envs-map
                              :PEN_PROXY_RESPONSE "y"))))
     :out)))

(defroutes app-routes
  (GET "/" [] "<h1>Khala</h1>")
  ;; (GET "/" [] (fn [req] "Do something with req"))

  ;; curl -d "fun=pf-tweet-sentiment%2F1&args=%5B%22I%20love%20chocolate%22%5D" -X POST http://127.0.0.1:9837/prompt -H "Content-Type: application/x-www-form-urlencoded"
  ;; curl -d "{\"fun\": \"pf-tweet-sentiment/1\", \"args\": \"I love chocolate\"}" -X POST http://127.0.0.1:9837/prompt -H "Content-Type: application/json"
  ;; /usr/bin/curl --header "Content-Type: application/json" --request POST --data-binary '{"fun":"xyz","args":"xyz"}' http://127.0.0.1:800/prompt

  (POST "/prompt" []
        ;; [:as {headers :headers body :body}]
        ;; (sh "tv" :stdin (str headers))
        prompt
        )

  (POST "/lm-complete" []
        ;; [:as {headers :headers body :body}]
        ;; (sh "tv" :stdin (str headers))
        lm-complete)

  ;; curl --header "Content-Type: application/json" --request POST --data '{"username":"xyz","password":"xyz"}' http://127.0.0.1:9837/login
  (POST "/login" [] login)
  (POST "/debug" [] debug)

  ;; The maximum length of a URL in the address bar is 2048 characters.

  ;; Use urlencode
  ;; curl "http://127.0.0.1:9837/post/prompt/pf-tweet-sentiment%2F1/%5B%22I%20love%20chocolate%22%5D"
  (GET "/prompt/:fun/:args" [fun,args]
       (c/parse-string
        (apply
         penf (conj (c/parse-string args true) fun))
        true))
  ;; (GET "/gettime" [] (get-time))
  ;; (GET "/get/prompt" req (prompt req))
  (GET "/hello/:name" [name] (str "Hello " name))
  ;; You can adjust what each parameter matches by supplying a regex:
  (GET ["/file/:name.:ext" :name #".*", :ext #".*"] [name ext]
       (str "File: " name ext))
  (route/not-found "<h1>Khala service not found</h1>"))

;; (app {:uri "/" :request-method :post})

;; (defroutes app
;;   (GET "/" [] "Show something")
;;   (POST "/" [] "Create something")
;;   (PUT "/" [] "Replace something")
;;   (PATCH "/" [] "Modify Something")
;;   (DELETE "/" [] "Annihilate something")
;;   (OPTIONS "/" [] "Appease something")
;;   (HEAD "/" [] "Preview something"))

(defn test-make-request []
  (->
   (http/post
    "http://127.0.0.1:9837/prompt"
    ;; "http://127.0.0.1:800/prompt"
    {:body
     ;; (string-input-stream (json/write-str {:fun "xyz" :args "xyz"}))
     ;; (string-input-stream (json/write-str {:username "xyz" :password "xyz"}))
     (json/write-str {:username "xyz" :password "xyz"})
     ;; :accept :json
     :headers
     ;; {"Content-Type" "application/json; charset=utf-8"}
     {"Content-Type" "application/json"}
     ;; :form-params {"q" "foo, bar"}
     ;; :throw-entire-message? true
     })
   ;; :body
   ;; (json/read-str :key-fn keyword)
   ))

(def app
  ;; (-> (handler/api app-routes)
  ;;     ;; (middleware/wrap-json-body)
  ;;     (middleware/wrap-json-response)
  ;;     (middleware/wrap-json-body)
  ;;     (middleware/wrap-json-response))
  (as-> app-routes $
      ;; (middleware/wrap-json-body)
      (middleware/wrap-json-body $ {:keywords? true :bigdecimals? true})
      ;; (middleware/wrap-json-response $ {:pretty false})
    ))

(defn -main [& args]
  (let [port (Integer/parseInt (or (System/getenv "PORT") "9837"))] ;(5)
    (server/run-server app {:port port
                            :thread 8
                            :max-body 8388608})
    (println (str "Running Khala at http:/127.0.0.1:" port "/"))))