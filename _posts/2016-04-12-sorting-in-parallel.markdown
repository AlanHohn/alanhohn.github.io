---
layout: post
title: "Working in Parallel"
description: ""
category: articles
tags: []
---

Moving from a sequential to a parallel implementation of an algorithm
usually means that something has to change, and it may mean that
the whole algorithm has to be rethought. There are some important
concepts that help us predict what kinds of changes will make an
algorithm perform well when run in parallel. This article is a brief
introduction.

## Simple Performance

In the sequential case, we typically talk about algorithms in terms
of the order of the algorithm (typically called Big O). This lets us
talk about how an algorithm behaves as the number of items changes,
without worrying too much about specifics of how long it takes to
actually do the work. 

For example, if we have data stored in an unsorted list structure,
and we need to find out if a particular value is in the list, our
only option is to check each item in the list until we find the item
or reach the end of the list. In Big O notation we call this `O(n)`,
indicating that as the length `n` of the list grows, we should expect
the time it takes to search it to increase in a linear way. 

The key here is that we don't care how long it takes to step through the list
and look at each element, and we don't care that sometimes we'll find it on the
first try and exit very quickly. We only care about the general relationship
between the size of the list and the time it takes to run. In this case,
if the list gets twice as long, the average run time will get about twice
as long.

Similarly, if we had an unsorted list, and we had to see if it contains any
duplicated elements, we would call this `O(n^2)`, because we are 
going to have to do `n` searches through the list, each of which we
already said is `O(n)`. Regular math works here, and `O(n)` times `O(n)`
equals `O(n^2)`. Again, the time to do the comparison or the fact that we
might find a duplicate very quickly doesn't matter; we just care about the
fact that if the list gets three times as long, the average run time will be
about nine times as long.

## Work and Depth

When we move from working sequentially to working in parallel, we
start to worry not just about how many steps an algorithm takes, but also
how easy it is to do more than one thing at the same time. For example,
in our case of searching an unordered list, while we have to step through
the whole list, every single comparison that we do is independent of every
other, so we could hand out each comparison to a separate processor (if we
had that many) and get them all done at once.

To talk about how easy it is to break an algorithm up, we need to talk about
more than just a single Big O value for the algorithm. Instead, the convention
is to talk about it in terms of "work" and "depth". Work is the same as we
saw earlier; it is how the run time grows as the input size grows. Depth also
uses Big O notation, but it uses it to express how easy it is to split the
problem up so it can be run in parallel.

We use the term "depth" because we are thinking in terms of "divide and
conquer": we expect to have a recursive function that hands off smaller and
smaller pieces of the problem to new versions of itself. In that kind of setup,
the flatter (shallower) the recursion, the better, because it means we can
spread out across multiple processes more easily. In the case of our search in
an unordered list, we would say that depth is `O(1)`, also known as "constant
time". No matter how many extra items there are in the list, we can in theory
break it up into that number of pieces.

We can analyze our unsorted list duplicate search in the same way. We need
to compare each item in the list with every other item. No problem, we just
create `n^2` separate tasks, each with a different "left" and "right" index
for the comparison, and we can do all the comparisons in one step. So the
depth is still `O(1)`.

At this point, hopefully alarm bells will be ringing about how feasible this
is, but I'm not quite ready to let the real world intrude yet. So bear with me.

## Available Parallelism

So we have some figures for work and depth, in Big O notation. While these
figures are useful on their own, there is also value in putting them together.
We can define the "available parallelism" as the work divided by the depth;
in this case, bigger is better.

With our search through an unsorted list, the work was `O(n)` and the depth
was `O(1)`, giving an available parallelism of `O(n)`. What this says is that
while the amount of work we need to do increases in a linear way as the size
of the input increases, our ability to do the work in parallel also increases
in a linear way, so as long as we have more processors to throw at the problem
we can get the work done in about the same amount of time (ignoring for a moment
the overhead of splitting up the work). 

To give a marginally more realistic example, let's say that instead of just
identifying duplicates, we wanted a count of the number of duplicates for each
duplicate we find. Now, instead of just comparing each item in the list to
every other item, we also need to keep track of how many matches we've found.
That means we can't split up the comparisons completely; the best we can do is
split up the "left" side of the comparison so we count the number of matches in
parallel for each item in the list. Of course, this is a very poor approach,
because we are finding the number of duplicates for every duplicate, which is a
lot of wasted work; bear with me.

So for this example, while the work is still `O(n^2)`, the depth is now `O(n)`.
This means our available parallelism is `O(n)`, which is still quite good because
it tells us that if we have more processors, we can put them to use, but it also
means that we would expect the running time of the algorithm to increase in a
linear way as the size of the input increases.

It would be nice to avoid that wasted work. Those of you who are experienced in
map / reduce have probably noticed that rather than comparing each item to
every other item, we can have a map emit a count for each item, then add up the
count of each item in a reducer.  In fact this is the default WordCount example
from Hadoop.  The mapper in this case has work `O(n)`, and if the reducer is
written correctly this can make the depth `O(log n)`. Hopefully in a future
article I can expand on this, since right associativity is cool.

One final note: it is interesting to see that while the work is much worse in
the first example, because of all the wasted comparisons, it has slightly better
available parallelism than the map / reduce example, because it fully preserves
independence of all the comparisons. In this case, that is not enough reason to
prefer it, but it does illustrate an important rule in parallel programming, which
is that sometimes it is necessary to waste work in order to improve parallelism.

## The Real World Will Not Stop Hassling Me

So far, with everything we considered, to have a good parallel algorithm we want
to increase our available parallelism, because then we can just throw more hardware
at the problem to get it to run faster. Unfortunately, while that can be true, it
isn't the full story.

First of all, in the real world servers cost money, and so does electricity. There
is bound to be a limit on our ability to buy more hardware or spawn more cloud
instances. At that point, no matter what the theoretical speedup of our algorithm
is, we won't see any actual advantages, because we'll just be queueing up more tasks
than we have cores to run them on.

Second, Big O notation hides a lot of important differences between algorithms.
There's a definite cost in a real implementation in creating a task or kicking off
a [Goroutine](https://tour.golang.org/concurrency/1). In most real-world implementations
of parallel algorithms, there is a tuning step that happens where the number of
parallel tasks we actually spawn is far less than the theoretical maximum for the 
algorithm. There's a reason Hadoop lets you carefully configure [split
size][split] and [block size][block]. This illustrates what was absurd about breaking
up our duplicate search into `n^2` pieces; the overhead of doing that is going to be
many times greater than the time it takes to do the single comparison of two items.

[split]:https://hadoop.apache.org/docs/r2.7.1/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml
[block]:https://hadoop.apache.org/docs/r2.7.1/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml

Third, as we saw above, to get higher available parallelism we sometimes have to
do extra work, not just extra overhead. Sometimes that extra work is justified by
the speedup we get; sometimes it is not.

## Conclusion

This is a pretty basic discussion of how parallel algorithms are analyzed and compared
to each other. If you'd like to see how parallel code might be written in practice, I
have a [GitHub repository][repo] that runs a Net Present Value simulator using Java
fork / join `RecursiveTask` that might be of interest. 

[repo]:https://github.com/AlanHohn/monte-carlo-npv

