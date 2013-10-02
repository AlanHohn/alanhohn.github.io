---
layout: post
title: "Java Fork/Join Example"
description: "Monte Carlo NPV Walkthrough"
category: articles
tags: [java, fork, join, monte, carlo]
---

Introduction
------------

In a [previous post][part1] I discussed the fork/join framework introduced
with Java SE 7 and how it can be used to perform simple parallelism of
certain types of tasks; that is, those that operate within a single
JVM and involve a large piece of work that can be broken up into smaller
pieces through a divide and conquer strategy. To illustrate this, I
introduced an example of using fork/join to perform a Monte Carlo simulation
of the Net Present Value of an investment with uncertain profits and
discount rate. In this post, I will provide a walkthrough of the example
application. This walkthrough will provide the background for some
implementation changes we will discuss in a future post. The full code for the
example application is [available on GitHub][mcnpv] under an Apache 2.0
license. 

Application Overview
--------------------

Several of the application classes are related to the specifics of calculating
Net Present Value and generating random values for the Monte Carlo simulation:

* `NetPresentValue`: Utility class that, given a known set of annual profits
  or costs and a discount rate, returns the net present value using the well-
  known formula.
* `Distribution`: A Java interface representing a statistical distribution;
  implementers provide a method to return sample values that fit the
  distribution.
* `SingleValueDistribution`: A "distribution" that is actually not random
  but returns the same value every time.
* `TriangleDistribution`: A commonly used distribution that is suitable for
  cases where the full "shape" of a random variable is not known, but a
  minimum, maximum, and "most likely" value can be estimated.
* `StatsCollector`: A class to collect statistics from the simulation runs
  as they are performed. In parallel programming terms, this serves the role
  of a reducer (e.g. in [MapReduce][] or in [Cilk Plus][cilkplus]).
* `MonteCarloNpv`: The main class that sets up an example investment and
  print statistics.

The remaining class, `NpvTask`, is the class that bridges the Java fork/join
framework to the Monte Carlo and Net Present Value calculations. The `NpvTask`
class extends `RecursiveTask`, a generic, abstract class that requires its
children to implement `compute()`. The `compute()` method takes no parameters
and returns whatever type was used to parameterize the generic (in this case
`StatsCollector`).

By extending `RecursiveTask`, the `NpvTask` makes itself available to be submitted
to a `ForkJoinPool`, as is done in the main method. The task itself should be
lightweight and avoid other forms of thread synchronization (since there may be
many more tasks than there are threads in the pool, it would be very unwise to
seize a lock from inside a task). In exchange, the task has the ability to fork
other tasks, which will then be scheduled to run asynchronously in the pool.

The key part of `NpvTask` is as follows:
{% highlight java %}
protected StatsCollector compute() {
    StatsCollector collector = new StatsCollector(min, max, numBuckets);
    if (numIterations < minChunkSize) {
        for (int i = 0; i < numIterations; i++) {
            collector.addObs(NetPresentValue.npv(sampleFlows(),
                    rate.sample()));
        }
    } else {
        List<NpvTask> subTasks = new ArrayList<>(numChunks);
        for (int i = 0; i < numChunks; i++) {
            NpvTask subTask = new NpvTask(min, max, numBuckets,
                    numIterations / numChunks, rate, flows);
            subTasks.add(subTask);
        }
        invokeAll(subTasks);
        for (NpvTask subTask : subTasks) {
            collector.combine(subTask.join());
        }
    }
    return collector;
}
{% endhighlight %}

Each task invocation declares its own instance of `StatsCollector`. This allows the
tasks to operate in parallel without having to synchronize access to a single
instance. The stats are collected when the tasks are re-joined.

Next, the method compares the number of iterations it must perform to a
minimum chunk size. Because there is a cost associated with forking a new task, there is
a size below which it is no longer efficient to divide the work. By making this a tunable
parameter, it is possible to test different values to improve performance. The "best"
size will depend on the computation being performed and the processing hardware available.

If the remaining size is large enough that it makes sense to divide, the method creates
multiple instances of `NpvTask` and hands off a section of the remaining work. The tasks
are kept in a list so that their statistics can be combined. The tasks are then invoked,
then the parent waits until all tasks are done and collects the results.

This is one possible implementation of a divide and conquer. It is a cross between
splitting the work into two pieces and performing a true "parallel-for" where the work
would be divided immediately into enough pieces that no further division would be
required. In a future post I will show some alternate ways of dividing the work and
the performance.

Performance
-----------

There are many different options for dividing the work, which affects the performance
seen. However, we can compare the simple case where all the runs are done sequentially
to a variety of cases with different parameters:

{% highlight text %}
StopWatch 'Monte Carlo NPV': running time (millis) = 4902
-----------------------------------------
ms     %     Task name
-----------------------------------------
00861  018%  Sequential
00282  006%  Parallel (children=2, min fork size=100)
00234  005%  Parallel (children=2, min fork size=500)
00200  004%  Parallel (children=2, min fork size=1000)
00186  004%  Parallel (children=2, min fork size=2000)
00181  004%  Parallel (children=3, min fork size=100)
00182  004%  Parallel (children=3, min fork size=500)
00188  004%  Parallel (children=3, min fork size=1000)
00192  004%  Parallel (children=3, min fork size=2000)
00197  004%  Parallel (children=4, min fork size=100)
00203  004%  Parallel (children=4, min fork size=500)
00211  004%  Parallel (children=4, min fork size=1000)
00182  004%  Parallel (children=4, min fork size=2000)
00194  004%  Parallel (children=5, min fork size=100)
00203  004%  Parallel (children=5, min fork size=500)
00189  004%  Parallel (children=5, min fork size=1000)
00207  004%  Parallel (children=5, min fork size=2000)
00194  004%  Parallel (children=6, min fork size=100)
00208  004%  Parallel (children=6, min fork size=500)
00206  004%  Parallel (children=6, min fork size=1000)
00202  004%  Parallel (children=6, min fork size=2000)
{% endhighlight %}

There are some minor differences in performance with the different tunable parameters,
though they may not be statistically significant and are certainly
machine-dependent. All parallel cases have a significant advantage over the
sequential case (around 4x).

This printout comes from the excellent `StopWatch` class that is part of the Spring
framework utility library. `StopWatch` is good at regular benchmarks like this one
where the task takes long enough that the resolution of the system clock is not a
concern. For microbenchmarks using the [Caliper][] library, see my post on Java
[collection performance][colper].

Notes
-----

One of the more irritating aspects of divide and conquer is that we typically need to
divide the work into integral chunks (it doesn't make sense to perform one-half of a
simulation run), but the work does not always divide neatly by the number of tasks.
In this example, this is OK as we can perform a few runs more or fewer without much
affecting the statistics we create. But a real-world example would likely need to
address this by dividing the work into slightly unequal chunks.

Another key issue with divide and conquer is the way we recombine the collected data. In
this example, we are collecting basic statistics and our `combine()` method in
`StatsCollector` is simple. This works because the operations we are performing
are associative and commutative; if we collect stats in three separate buckets,
it doesn't matter what order we combine them in. If the operations were
associative but *not* commutative, we would have to be more careful how we
combined the data and where we generated new (empty) `StatsCollector` instances.


[mcnpv]:https://github.com/AlanHohn/monte-carlo-npv
[MapReduce]:http://en.wikipedia.org/wiki/MapReduce
[cilkplus]:http://software.intel.com/en-us/blogs/2013/02/26/an-introduction-to-cilk-plus-reducers
[Caliper]: https://code.google.com/p/caliper/ 
[part1]:{% post_url 2013-09-22-monte-carlo-npv-1 %}
[colper]:{% post_url 2013-09-15-collection-performance %}

