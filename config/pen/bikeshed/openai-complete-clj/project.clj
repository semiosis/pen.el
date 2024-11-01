(defproject openai-complete-clj "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"
            :url "https://www.eclipse.org/legal/epl-2.0/"}
  :dependencies [[org.clojure/clojure "1.10.1"]
                 [clj-python/libpython-clj "2.018"]
                 [clj-http "3.10.3"]
                 [com.cemerick/url "0.1.1"]
                 [org.clojure/data.csv "1.0.0"]
                 [org.clojure/data.json "1.0.0"]]
  :main ^:skip-aot openai-complete-clj.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all
                       :jvm-opts ["-Dclojure.compiler.direct-linking=true"]}})
