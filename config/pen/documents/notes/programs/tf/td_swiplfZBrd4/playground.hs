 greet() = 
    do planet <- getLine
       home <- getLine
       putStrLn ("greetings " ++ planet ++ "ling.")
       putStrLn ("I am from " ++ home ++ ".")
       putStrLn "Take me to your leader."
