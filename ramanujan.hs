import Data.List (group)

insert :: Ord a => a -> [a] -> [a]
insert x (y:ys)
  | x < y = x:y:ys
  | otherwise = y : insert x ys
insert x [] = [x]

merge :: Ord a => [[a]] -> [a]
merge ((x:xs):xss) = x : merge (insert xs xss)
merge ([]:xss) = merge xss
merge [] = []

sumsOfCubes :: [Integer]
sumsOfCubes = merge [[ x^3 + y^3 | y <- [1..x]] | x <- [1..]]

ramanujan :: [Integer]
ramanujan = map head . filter multiple . group $ sumsOfCubes
  where multiple [x] = False
        multiple _   = True
