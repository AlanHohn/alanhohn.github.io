---
layout: post
title: "Fork/Join in Java"
description: "Using Fork/Join for a Monte Carlo simulation"
category: articles
tags: [java, fork, join, monte, carlo]
---

Introduction
------------

This is the first of a series of posts that will discuss an [example
application][mcnpv] that uses the Java Fork/Join framework to do a Monte Carlo
simulation of the Net Present Value of a prospective investment. This first
post discusses the purpose of the example application as well as the purpose of
the fork/join framework and the kinds of problems it can best solve.

Fork/Join and Divide and Conquer
--------------------------------

The fork/join framework introduced with Java SE 7 is based on a specific model
of parallel programming, similar to what is implemented in languages such as
Intel's [Cilk Plus][cilk].  The intent is to allow parallel programming without
requiring direct management of threads. This is done through a thread pool and
a set of tasks. Of course, Java has had thread pools for several years, and the
concept of a `Runnable` task has been around since the beginning. The fork/join
framework leverages these features; the key difference is that it simplifies
the way that tasks can divide up work and submit new tasks to parallelize the
performance of that work.

There are lots of ways to take advantage of parallel computing, whether the
available parallelism comes in the form of multiple cores, multiple processors, 
or multiple physical or virtual machines. The fork/join framework is designed to
use multiple threads within a single process. It is made for speeding up large
tasks by breaking them up into smaller tasks that can be executed
simultaneously. This is very different from typical uses of Java EE, where lots
of small, independent tasks show up at different times.

The fork/join framework is built around a `RecursiveTask`. As the name implies, the
task is expected to spawn additional tasks within its own processing, and combine
the results of those tasks with its own work before returning to its caller.

As a result, we wind up with three primary ways to think about multithreading within
a single process:

* Defined threading model. This works well when an application has several long-running
tasks, potentially cooperating with each other. For example, a GUI application that
accepts user input, makes server requests, and receives system updates, has a natural
division into separate threads. This structure can also mix in a thread pool; for
example, a GUI application may have a thread pool for server requests so the system
can start processing a new operator action before the previous one finishes.
* Thread pool. This works well when short-term work comes in at various times. A new
task can pick up an available thread, saving the cost of creating a new one. This can also
be used to limit the amount of available parallelism, since if the thread pool is full
the new task will be queued. This is important for maximizing performance as too many
threads can lead to excessive context switching.
* Divide and conquer. This is the fork/join model, where a big task is divided up
into progressively smaller tasks and the results are combined. Of course, this just
defines how we generate the tasks; to execute them we still need a thread pool to
avoid creating a potentially too-large number of threads. This works best where the
smaller tasks are independent. There are lots of creative ways to work with problems
where the tasks are not independent, but this is too complex to cover here.

Monte Carlo
-----------

A Monte Carlo simulation is a way of modeling a complex system that contains uncertainty.
It is especially useful for modeling a system where the overall statistical distribution
is not known, for example in cases where a number of random variables interact in complex
ways. In a Monte Carlo simulation, a large number of trials are made, where each trial
picks one set of possible values for all the random variables. If the simulation is run
enough times, the average and probable range of outputs can be determined.

Net Present Value
-----------------

Many calculations in finance take into account the "time value of money"; that is, the
principle that $1 today is worth more than $1 a year from now, because the $1 today could
be invested. One way of thinking about the time value of money is to use a "discount rate",
which is like an interest rate in reverse. The discount rate is used to calculate the
equivalent value today of an amount of money in the future. For example, if we use a discount
rate of 5% per year, then $100 promised to us in one year would be worth ($100 / 1.05) = $95.24.
This value of $95.24 is called the "present value" of the future $100 we are promised.

This way of thinking can be applied to whole investments. In a typical example, a business might
choose to build a new factory. There is an upfront cost associated with building the factory,
and the business expects a certain amount of profit in future years. Most businesses will
use calculate the "present value" of all those expected future profits, and compare them to the
cost of building the factory. If the "*net* present value" (present value of profits minus
the cost) is positive, the investment is worthwhile. Also, a business can compare the net
present value of different investments to see which is better.

Monte Carlo Net Present Value
-----------------------------

One problem with calculating net present value is that the business is making guesses about
what the future profits will be. A regular net present value calculation does not consider
risk, because it only uses one value (usually the most likely) for the future
profits. For a single investment, this could mean that an investment with
positive net present value could have a high chance (almost 50%) of losing money, perhaps
a large amount of money. For multiple investments, a less risky investment with a slightly
lower net present value may be a better choice.

Taking risk into account means looking at a range of possible scenarios for each investment.
This is hard because there may be a possible range of values for each year in the future.
Also, the correct choice of a discount rate is uncertain because it is based on things like
interest rates in the future.

A Monte Carlo simulation helps to solve this problem. For each scenario, one possible value
can be selected for each of the future profits as well as the discount rate. It
is possible to decide on a statistical distribution for each of these
individual items, but it would be very challenging to come up with a
statistical distribution that took all the future profits and discount rates
into account. 

This particular problem also presents a useful example application for Java
fork/join, since the simulation is a big task that can be easily broken down
into separate independent tasks (each scenario is independent).

The next post will go over the example application as a whole.

[mcnpv]:https://github.com/AlanHohn/monte-carlo-npv
[cilk]:http://software.intel.com/en-us/intel-cilk-plus

