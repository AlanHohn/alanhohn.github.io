---
layout: post
title: "Tuning Java Fork/Join"
description: "Testing different forms of divide and conquer"
category: articles
tags: [java, fork, join]
---

This post continues a series discussing the new fork/join features added to
Java SE 7. [Part 1][part1] and [part 2][part2] introduced an example
application that performs a Monte Carlo simulation of the Net Present Value
of an investment with uncertain profits and discount rate. The example
application is [available on GitHub][mcnpv].

The previous post glossed over an important question: what is the "right" way
to divide up the work? Of course, the answer is dependent on the type of work
being performed and the machine on which it is run. But there are some alternatives
that we can consider.

First, recall that we start with a large amount of work (in this case, many
runs of a simulation that are independent). Below a certain size, we perform
the "base case", where we run like an ordinary sequential program. The size
of the "base case" is itself a tunable parameter.

Above that minimum size, we operate by dividing the work, creating tasks to
perform each piece of work, and collecting the results when the tasks are complete.
Each sub-task may itself spawn tasks to divide the work further until the base
case size is reached. It therefore makes sense to talk about how many levels there
will be, what is known as the "depth" of the implementation. 

The depth is specified using "Big O" notation since we are mostly interested in
how the depth will grow as the size of the problem changes. Of course, the
approach we choose for dividing up the work will affect this depth. In general,
the flatter the depth, the higher the theoretical value we can gain from adding
more processors, since the theoretical maximum speedup is the total work
performed divided by the depth.  (This is intuitive; if we had total work of
`O(n)` and we could perform all those steps in parallel, so that depth is `O(1)`,
we could in theory perform the whole calculation in one step if we had `n`
processors.)

Actually getting linear speedup is generally not possible, but typical approaches
do reasonably well for most problem sizes and machines.

The first approach divides up the work by a constant factor. A special case of
this is dividing the work up based on the number of available processors.

Another approach is to choose the number of children based on the size of the input.
This calculation is performed at each level of recursion. The common choice is to use
`sqrt(n)` as the number of children, as this reduces the growth in 

A third approach immediately divides the work into enough chunks that no further
subdivision is necessary. In languages like [Cilk Plus][cilkplus], there is a parallel
`for` statement to specify this. Of course, the number of tasks that can actually
be performed in parallel is much less, so in implementation this is similar to
dividing up the work based on the number of processors.

The example application provides the means to test the above approaches. Here is
example output from a run on a quad-core i7 using 10 million iterations.

{% highlight text %}
StopWatch 'Monte Carlo NPV': running time (millis) = 40192
-----------------------------------------
ms     %     Task name
-----------------------------------------
10149  025%  Sequential
02413  006%  DivideByTwo (children=2, min fork size=100)
02350  006%  DivideByTwo (children=2, min fork size=500)
02418  006%  DivideByTwo (children=2, min fork size=1000)
02448  006%  DivideByTwo (children=2, min fork size=2000)
02271  006%  DivideByP (children=8, min fork size=100)
02260  006%  DivideByP (children=8, min fork size=500)
02263  006%  DivideByP (children=8, min fork size=1000)
02281  006%  DivideByP (children=8, min fork size=2000)
02271  006%  Sqrt(n) (children=-1, min fork size=100)
02270  006%  Sqrt(n) (children=-1, min fork size=500)
02271  006%  Sqrt(n) (children=-1, min fork size=1000)
02268  006%  Sqrt(n) (children=-1, min fork size=2000)
02259  006%  Parfor (children=20000, min fork size=500)
{% endhighlight %}

The differences are mostly not significant; another run shows different outcomes,
with not just the numbers changing but the order of fastest to slowest also
different:

{% highlight text %}
StopWatch 'Monte Carlo NPV': running time (millis) = 44836
-----------------------------------------
ms     %     Task name
-----------------------------------------
10162  023%  Sequential
02841  006%  DivideByTwo (children=2, min fork size=100)
02712  006%  DivideByTwo (children=2, min fork size=500)
02734  006%  DivideByTwo (children=2, min fork size=1000)
02839  006%  DivideByTwo (children=2, min fork size=2000)
02621  006%  DivideByP (children=8, min fork size=100)
02586  006%  DivideByP (children=8, min fork size=500)
02617  006%  DivideByP (children=8, min fork size=1000)
02620  006%  DivideByP (children=8, min fork size=2000)
02612  006%  Sqrt(n) (children=-1, min fork size=100)
02619  006%  Sqrt(n) (children=-1, min fork size=500)
02620  006%  Sqrt(n) (children=-1, min fork size=1000)
02639  006%  Sqrt(n) (children=-1, min fork size=2000)
02614  006%  Parfor (children=20000, min fork size=500)
{% endhighlight %}

The results allow us to develop some reasonable conclusions about using Java
fork/join:

1. Parallel is better than sequential. All of our parallel methods did
   significantly better. Note that the speedup was pretty close to 4x
   on a quad-core processor.
1. Simple is better than complicated. At least for this kind of example,
   there isn't a lot of real-world value to be gained from more complex
   calculations for how the work should be divided. There's lots of
   good work in the high-performance computing literature, whether it's 
   dividing up problems, representing sparse matrices, or using custom-made 
   parallel algorithms. Much of that work applies to really big problem sets 
   or really big clusters. If you're not working with trillions of rows or 
   run times measured in days, readability is probably more important.
1. Performance isn't always intuitive. The "Parfor" implementation creates
   20,000 tasks, which seems like a lot. But the "DivideByTwo" implementation with
   "base case" size of 100 creates 262,142 tasks, and runs in about the same
   amount of time.
1. The Javadocs are telling the truth when they say that fork/join tasks are
   much lighter weight than a normal thread. It's doubtful that a Java application
   that spawned 262,142 threads would be peformant (or still alive) on normal hardware.
1. Off-by-one errors are the bane of parallel programming, and you *will* run into
   them. My initial implementation of `NpvTask` had a bug that would spawn children
   if the number of requested iterations was equal to the "base case" size. This means
   each of the 20,000 tasks in my "Parfor" spawned 20,000 children, taking 15 seconds
   to run. I noticed it when I had the `StatsCollector` also keep track of how many
   total instances were spawned and wound up with 4 billion.

Hopefully this has been a beneficial introduction to fork/join in Java. The key is
that for computations involving a large body of work that can be subdivided, fork/join
can provide parallel speedup with compact code.


[mcnpv]:https://github.com/AlanHohn/monte-carlo-npv
[cilkplus]:http://software.intel.com/en-us/intel-cilk-plus
[part1]:{% post_url 2013-09-22-monte-carlo-npv-1 %}
[part2]:{% post_url 2013-10-01-monte-carlo-npv-2 %}

