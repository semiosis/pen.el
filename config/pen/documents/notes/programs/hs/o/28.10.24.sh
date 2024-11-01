cd /root/repos;  "o" "https://github.com/manateelazycat/cloel" "#" "<==" "zsh"
cd /root/.emacs.d/host/pen.el/scripts/babashka/utils;  "o" "#" "<==" "zsh"
cd /root/.emacs.d/host/pen.el/scripts/babashka/utils;  "o" " for this very small example. But we can clean it up and put the steps in the right order with a small helper function, bind. We will call it m-bind (for monadic bind) right away, because that’s the name it has in Clojure’s monad library. First, its definition:

(defn m-bind [value function]
  (function value))

As you can see, it does almost nothing, but it permits to write a value before the function that is applied to it. Using m-bind, we can write our example as

(m-bind 1        (fn [a]
(m-bind (inc a)  (fn [b]
        (* a b)))))

That’s still not as nice as the let form, but it comes a lot closer. In fact, all it takes to convert a let form into a chain of computations linked by m-bind is a little macro. This macro is called domonad, and it permits us to write our example as" "#" "<==" "o"
cd /root/.emacs.d/host/pen.el/scripts/babashka/utils;  "o" "#" "<==" "zsh"
cd /root/.emacs.d/host/pen.el/scripts/babashka/utils;  "o" "https://github.com/khinsen/monads-in-clojure/" "#" "<==" "o"
cd /root/.emacs.d/host/pen.el/scripts/babashka/utils;  "o" "#" "<==" "zsh"
cd /root/.emacs.d/host/pen.el/scripts/babashka/utils;  "o" "https://github.com/khinsen/monads-in-clojure/" "#" "<==" "o"
