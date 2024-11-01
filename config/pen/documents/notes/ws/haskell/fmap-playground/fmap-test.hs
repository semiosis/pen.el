incList :: [Int] -> [Int] -- Note: [Int] is special syntax for [] Int
incList []     = []
incList (i:is) = i+1 : incList is

squareList :: [Int] -> [Int]
squareList []     = []
squareList (i:is) = i^2 : squareList is

-- main :: IO ()
-- main = print (incList [1,2,3,4])

-- main :: IO ()
-- main = putStrLn $ show (incList [1,2,3,4])

-- main :: IO ()
-- main = putStrLn "hello world"


-- Being good programmers, we realize there is a
-- common pattern in the two tasks `incList` and `squareList`. In particular,
-- we see that there is a function `f` (either inc or
-- square that we want to apply to each element in
-- the list. Therefore, we write the following function:
imap :: (Int -> Int) -> [Int] -> [Int]
imap f []     = []
imap f (i:is) = (f i) : imap f is

incList' :: [Int] -> [Int]
incList' = imap ((+) 1)

squareList' :: [Int] -> [Int]
squareList' = imap (\x -> x^2)
  -- Note: we could also do imap (^2) b/c of Haskell's
  -- handling of infix functions

-- Generalised Map - map for lists of any type, not just integers
gmap :: (a -> b) -> [a] -> [b]
gmap f []     = []
gmap f (i:is) = (f i) : map f is

data Tree a = Leaf | Bin a (Tree a) (Tree a)
   deriving (Eq, Show)

-- a function that increments each element in the tree
tinc :: Tree Int -> Tree Int
tinc Leaf         = Leaf
tinc (Bin i l r)  = Bin (i+1) (tinc l) (tinc r)

-- a function that squares each element in the tree
tsquare :: Tree Int -> Tree Int
tsquare Leaf         = Leaf
tsquare (Bin i l r)  = Bin (i^2) (tsquare l) (tsquare r)

main :: IO ()
main = print (incList' [1,2,3,4])
