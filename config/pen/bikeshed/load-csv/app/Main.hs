module Main where

-- This program reads a CSV from stdin and stores inside
-- a datastructure.
-- It then tabularises and prints the output

import qualified Data.ByteString.Lazy as L
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8)

read_ :: IO String
read_ = putStr "REPL> "
     >> hFlush stdout
     >> getLine

eval_ :: String -> String
eval_ input = input

print_ :: String -> IO ()
print_ = putStrLn

main :: IO ()
main = do
  input <- read_
  
  unless (input == ":quit")
       $ print_ (eval_ input) >> main

-- main = do

--   -- Read the CSV from stdin and decode it into a list of lines.
--   -- We use the Lazy version of ByteString to avoid reading the whole file into memory.
--   lines <- L.readFile "-"

--   -- Parse the CSV into a list of records, one for each line in the CSV file.
--   records <- decodeUtf8 <$> lines

--   -- The CSV file has a header, so we discard it.
--   records' <- records !! 1

--   -- Parse each record into a list of fields.
--   fields <- map (T.words . T.unpack) records'

--   -- Map the fields into a list of values, one for each field.
--   values <- map (map (read)) fields

--   -- Map the values into a list of tuples, one for each record.
--   tuples <- map (zip [1..]) values

--   -- Map the tuples into a list of rows, one for each record.
--   rows <- map (map (\t -> (t !! 0, t !! 1))) tuples

--   -- Tabularise the rows and print them to stdout
--   mapM_ print $ tabularise rows

-- tabularise :: [[String]] -> IO ()
-- tabularise rows = do
--   let cols = maximum (map length rows)
--   mapM_ (\row -> putStrLn $ intercalate "\t" (pad row cols)) rows
