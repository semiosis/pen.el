module Main where

type Parser a = String -> [(a,String)]

-- First parser
-- succeeds without consuming any of the input string, and returns the single result v
result :: a -> Parser a
result v = \inp -> [(v,inp)]
result v inp = [(v,inp)]

main :: IO ()
main = putStrLn "Hello, Haskell!"
