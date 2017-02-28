# One weird trick for calculating Ramanujan numbers

or, Ramanujan numbers – an exercise in laziness

## Definition

Ramanujan numbers, also called Hardy-Ramanujan numbers or Taxicab
were born in an anecdote:

> When Ramanujan heard that Hardy had come in a taxi he asked him what
> the number of the taxi was. Hardy said that it was just a boring
> number: 1729. Ramanujan replied that 1729 was not a boring number at
> all: it was a very interesting one. He explained that it was the
> smallest number that could be expressed by the sum of two cubes in
> two different ways.

See also
[Wikipedia](https://en.wikipedia.org/wiki/Taxicab_number)
and
[The Online Encyclopedia of Integer Sequences](http://oeis.org/wiki/Hardy%E2%80%93Ramanujan_numbers).

## Implementation

Code in [ramanujan.hs](ramanujan.hs).

A friend wondered how to produce Ramanujan numbers functionally. He
had an imperative C implementation that iterated over `x` and `y` over
a range and updated a large table: `counts[x*x*x + y*y*y]++`. After
that he iterated through the table and collected the Ramanujan
numbers.

I knew that if I could produce numbers of the form `x^3 + y^3` in
order, it would be easy to produce the Ramanujan numbers:

```haskell
ramanujan :: [Integer]
ramanujan = map head . filter multiple . group $ sumsOfCubes
  where multiple [x] = False
        multiple _   = True
```

Producing all sums of cubes is relatively easy. By adding the
condition `y<=x` I both ensure that each sum is only produced once,
and that I eventually produce all sums:

```haskell
[ x^3 + y^3 | x <- [1..], y <- [1..x]]
```

This sequence consists of segments, one for each `x`. Within a
segment, `y` is increasing and so is the value `x^3 + y^3`. I can
express this explicitly as a list of lists:

```haskell
cubelists = [[ x^3 + y^3 | y <- [1..x]] | x <- [1..]]
```

Not only are the sequences themselves increasing, but they are ordered
by their first element. Thus if I want to know if `k` is a sum of two
cubes I can do it easily: look in every list in `cubelists` until I
find `k` or hit a list that starts with a value larger than `k`.

### Generator view

You can think of `cubelists` as a list of generators, each eager to
give you their next number. The generators are queued in the order of
the number they want to give you.

To get the smallest number, you take the number the first generator is
trying to give you. Then you put that generator back in the queue in
the right place (as determined by the next number it wants to give
you).

Putting a generator into the queue is done with `insert`:

```haskell
insert :: Ord a => a -> [a] -> [a]
insert x (y:ys)
  | x < y = x:y:ys
  | otherwise = y : insert x ys
insert x [] = [x]
```

It relies on the fact the `Ord` instance for lists does the right
thing: compares the first elements (and then the second elements, and
so forth, but that won't happen in our use case).

Finally, here's the function that just repeatedly takes the smallest
number available and calls insert:

```haskell
merge :: Ord a => [[a]] -> [a]
merge ((x:xs):xss) = x : merge (insert xs xss)
merge ([]:xss) = merge xss
merge [] = []
```

We can now define

```haskell
sumsOfCubes :: [Integer]
sumsOfCubes = merge cubelists
```

### Heap view

Another way to look at `cubelists` is to see it as a sort of
[heap](https://en.wikipedia.org/wiki/Heap_(data_structure)).
Visualize the list of lists as a two dimensional structure:

```
 +-+-+-+-...
 | | | |
 | | | |
 . . . .
```

The smallest number is in the top left corner, and when I further away
along the links I get larger and larger numbers.

The fundamental heap operation is `pop`: removing the smallest
element. I'll just do that:

```
   +-+-+-...
|  | | |
|  | | |
.  . . .
```

I'm left with a dangling ordered list (the list that was the first
list of the heap) and a heap (the rest of the lists still form a valid
heap). So I just need to figure out how to add the dangling list to
the remaining heap.

That's easy: the only invariant I need to respect is that the lists
are ordered by their first element. This is the `insert` function.

And here's how you pop using it:

```haskell
pop :: [[Int]] -> (Int,[[Int]])
pop ((x:dangle):heap) = (x, insert dangle heap)
```

Now you can see that `merge` is just an iterated `pop`.
