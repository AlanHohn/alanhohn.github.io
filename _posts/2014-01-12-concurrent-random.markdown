---
layout: post
title: "Concurrent Random in Java SE 7"
description: "Using ThreadLocalRandom"
category: articles
tags: [java, fork, join, random]
---

Introduction
------------

Last year I wrote a series of posts ([Part 1][part1], [Part 2][part2],
[Part 3][part3]) on the use of the new Java fork/join framework for
a Monte Carlo simulation.

First, an update. Going back through the code I discovered a bug in
the way the triangle distribution was implemented. Fortunately this is
a toy example, as it made the results inaccurate. My fault for not unit
testing. I would still not suggest using [this code][mcnpv] for anything
other than learning about fork/join.

Thread Local Random Numbers
---------------------------

To move on to more interesting things: I was reading through [Oracle's release
notes on Java SE 7][oracle] and noticed that they include a new facility for
concurrent random numbers.  Since a Monte Carlo simulation generates millions
of random numbers, I was very interested to see how its performance would be
impacted.

The [Javadoc for ThreadLocalRandom][threadlocalrandom] mentions contention
when multiple threads use regular `Math.random()`. Regular `Math.random()`
uses atomic variables to hold the current seed so that two threads calling
simultaneously get pseudo-random numbers in sequence rather than the same
number twice. In my case, I am using a separate instance of `Random` for each
random variable in the simulation, but these instances are being shared across
all runs on the simulation. As a result, there is a strong possibility of
contention, so we should expect an improvement.

`ThreadLocalRandom` is not instantiated directly; instead, there is a static
method `current()` that makes a new instance the first time it is called from
a given thread. So by changing from `Math.random()` to `ThreadLocalRandom` we
are changing two things about the program:

1. We no longer have the contention of accessing a single random number
   generator instance from multiple threads.
1. Instead of instantiating a random number generator instance per random variable,
   we instantiate one per thread. 

`Random` versus `ThreadLocalRandom`
-----------------------------------

To set a baseline, here's a fresh run using regular `Math.random()`:

{% highlight text %}
StopWatch 'Monte Carlo NPV': running time (millis) = 44637
-----------------------------------------
ms     %     Task name
-----------------------------------------
12202  027%  Sequential
02576  006%  DivideByTwo (children=2, min fork size=100)
02465  006%  DivideByTwo (children=2, min fork size=500)
02615  006%  DivideByTwo (children=2, min fork size=1000)
02515  006%  DivideByTwo (children=2, min fork size=2000)
02502  006%  DivideByP (children=8, min fork size=100)
02490  006%  DivideByP (children=8, min fork size=500)
02445  005%  DivideByP (children=8, min fork size=1000)
02450  005%  DivideByP (children=8, min fork size=2000)
02477  006%  Sqrt(n) (children=-1, min fork size=100)
02458  006%  Sqrt(n) (children=-1, min fork size=500)
02466  006%  Sqrt(n) (children=-1, min fork size=1000)
02468  006%  Sqrt(n) (children=-1, min fork size=2000)
02508  006%  Parfor (children=20000, min fork size=500)
{% endhighlight %}

As discussed in the previous posts, the move from sequential to parallel is
much more important than the way that the task is divided up.

The change is very minor:
{% highlight java %}
// double u = r.nextDouble();
double u = ThreadLocalRandom.current().nextDouble();
{% endhighlight %}

The resulting change is substantial:

{% highlight text %}
StopWatch 'Monte Carlo NPV': running time (millis) = 34942
-----------------------------------------
ms     %     Task name
-----------------------------------------
11347  032%  Sequential
02004  006%  DivideByTwo (children=2, min fork size=100)
01831  005%  DivideByTwo (children=2, min fork size=500)
01838  005%  DivideByTwo (children=2, min fork size=1000)
01784  005%  DivideByTwo (children=2, min fork size=2000)
01781  005%  DivideByP (children=8, min fork size=100)
01782  005%  DivideByP (children=8, min fork size=500)
01772  005%  DivideByP (children=8, min fork size=1000)
01776  005%  DivideByP (children=8, min fork size=2000)
01781  005%  Sqrt(n) (children=-1, min fork size=100)
01788  005%  Sqrt(n) (children=-1, min fork size=500)
01805  005%  Sqrt(n) (children=-1, min fork size=1000)
01799  005%  Sqrt(n) (children=-1, min fork size=2000)
01854  005%  Parfor (children=20000, min fork size=500)
{% endhighlight %}

The improvement is around 25%, which is well worth having.

Observations
------------

It is interesting that the sequential case shows less of an improvement
than the parallel case. This tends to show that there was genuine contention
between different threads accessing the same random number generator, and not
just overhead from the use of atomic variables.

It is also interesting that there is improvement in the sequential case. This
shows that not all the performance gain was created by eliminating contention.
This tends to suggest that even in regular Java code, there is an advantage to
using `ThreadLocalRandom` if many random numbers will be needed. This is
similar to the difference between `StringBuffer` and `StringBuilder`; by
shifting thread safety to instantiation rather than during use, it is possible
to improve performance. It is possible that there are other cases in Java
programming where `synchronized` code blocks are used that would be more
performant with separate `ThreadLocal` instances.

In the numbers above, the "divide by two" case with 2 children and the smallest 
chunk size appears to be significantly worse than other options. Note that this
method spawns the most tasks, but because of the way the fork/join framework operates,
it does not mean that it spawns more threads than the others. Subsequent runs still
showed some difference, but not as marked, so this may not be significant.

Conclusion
----------

The Java fork/join framework is, in my opinion, a valuable contribution to Java SE 7.
The `ThreadLocalRandom` class may be a considerably smaller and less complex addition,
but it appears to have a strong case for its usage, possibly even in "regular" Java code.

[mcnpv]:https://github.com/AlanHohn/monte-carlo-npv
[oracle]:http://www.oracle.com/technetwork/java/javase/jdk7-relnotes-418459.html
[threadlocalrandom]:http://docs.oracle.com/javase/7/docs/api/java/util/concurrent/ThreadLocalRandom.html
[part1]:{% post_url 2013-09-22-monte-carlo-npv-1 %}
[part2]:{% post_url 2013-10-01-monte-carlo-npv-2 %}
[part3]:{% post_url 2013-10-01-monte-carlo-npv-3 %}

