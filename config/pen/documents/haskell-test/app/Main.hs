module Main where

-- import Options.Applicative

travelToSchool :: String -> IO ()
travelToSchool weather = do
    if weather == "sunny"
    then putStrLn "I'm walking to school"
    else putStrLn "I'm driving to school"

travelToWork :: String -> IO ()
-- travelToWork weather =
-- the 'do' is not accomplishing anything here
travelToWork weather = do
    if weather == "sunny"
    then putStrLn "walking to work"
    else if weather == "cloudy"
         then putStrLn "biking to work"
         else putStrLn "driving to work"

main :: IO ()
main = do
  putStrLn "Please enter your age: "
  age <- getLine
  let ageAsNumber = read age :: Int
  -- print ageAsNumber
  putStrLn $ "Your age is: " ++ show ageAsNumber