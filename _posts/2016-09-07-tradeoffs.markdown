---
layout: post
title: "Architecture Is About Tradeoffs"
description: ""
category: articles
tags: []
---

I just finished reading an [interesting article][1] here on DZone about the
benefits of Java EE in contrast to microservices. In my opinion, it's always
salutary to see an argument like this that goes against the prevailing
trend, because it helps us to remember that one of the most important rules
of architecture is the one defined by Robert Heinlein: [There Ain't No Such
Thing as a Free Lunch (TANSTAAFL)][2].

I myself spent a few years as the architect of a large-scale system built on
Java Enterprise technology, and I was the one who selected the technology we
used. My reasons were very similar to [those given][1] by Mr. Soika. I knew
that we were building an application with lots of short connections to update
and retrieve data from the database; I knew that much of our system was
driven by external events, and we needed to integrate publish-subscribe
messaging; and I was devising the replacement for a system that, due to
technical limitations when it was built, was missing a clean separation
between user interface, business logic, and data storage.

That system was highly successful and is still in use and being maintained
today, so in that sense it was a success. So why did I not choose Java Enterprise
for the next system I designed? Because of the tradeoffs.

First, any time you adopt a framework for building an application, you are
inevitably going to spend time debugging and becoming expert in the framework.
So while it is true that our team was able to focus primarily on just writing
our business logic in the form of session beans and message-driven beans, it was
also true that any time we had an edge case (long running processing, need for
a sequence of events to occur in a certain order, complex data updates) we would
run into issues with the way we were using the frameworks. This puts a strain
on the subset of the team that is expert (unfortunately not everyone can be an
expert in the framework and in the business logic too).

Second, migrating to the new version of a Java Enterprise application server is
made more complicated by the number of moving parts. In the areas of the system
where we needed complex behavior from the framework, we often ended up writing
something that turned out to be brittle when the next version came along. I
think there are a lot of Java Enterprise projects on backlevel versions of Java
and of the application server that serve as a testament to this issue. In our
case, it was a credit to the JBoss team that they were able to rewrite the core
of their application server twice in the last six years, and what they produced
with Wildfly is very cool, but it did us no favors to lose access to some
features we were using.

Of course, this article is about tradeoffs, not about issues with Java EE in
particular. So it's fair to ask, for the recent work I've done with microservices,
what have been the tradeoffs? First, the system is much harder to conceptualize.
It was much more difficult to devise the [one diagram][3] that describes how the
whole system works. I've also found it harder to bring new people up to speed on
how it works, not least because there are more discrete moving parts and a lot
more different third-party tools involved.

Second, with Java Enterprise there is generally a clear right way to do things.
With a microservice architecture, a lot of times there a few performant ways to
do things, but lots of ways that perform very badly or are hard to maintain.
Using a microservice architecture puts the onus on individuals to choose the
right approach for their particular components. This is good from a team
autonomy standpoint, but bad if not everyone is equipped to make those kinds of
decisions.

All of that has been pretty gloomy so far; whatever path we choose, we are going
to run into negatives that make our job harder. But in exchange for these
tradeoffs we also get advantages. In our Java Enterprise code, it was really
easy to reason about very complicated things like threading and transactions,
because a lot of work had already been done in the application server to implement
these so that we could just configure our way to success. In that architecture we
send thousands of messages around every minute for hours straight, and not one
of them goes missing or takes more than a few milliseconds to deliver. We were
also able to turn whole components of our system on and off at will in that
architecture and have no issues at all, something that was never possible in the
legacy system it replaced.

On the microservice side, systems are able to have new components show up
exactly as they are, in whatever programming language, with whatever required
interfaces. Adaptation to various interfaces (exposing publish-subscribe as a
web service, or invoking a library when a message comes in) are reduced to a
few XML elements by using [Apache Camel][4]. Also, the "old" problems of lots
of simultaneous connections to a database are handled by allowing each service
to bring its own data storage; we're willing to give up a single data model
across the whole system in favor of well defined interfaces that make the
internal structure of the data less relevant. 

This weighing of tradeoffs is what real architecture is about. I'm always
impressed when I see someone put together a complex and valuable piece of
technology, then write an introduction that says, "this is what you should
use this for" but also "this is what you should not use this for".



[1]:https://dzone.com/articles/why-its-better-to-trust-in-java-ee
[2]:http://www.technovelgy.com/ct/content.asp?Bnum=735
[3]:https://dzone.com/articles/in-search-of-simplicity-one-diagram
[4]:http://camel.apache.org/

