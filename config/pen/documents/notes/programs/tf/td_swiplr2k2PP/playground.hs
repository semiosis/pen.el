mytest :: Maybe Int
mytest = Just 5 >>= (\ x -> if (x == 0) then fail "zero" else Just (x + 1) )

main :: IO ()
main = do print mytest
-- main = print mytest
