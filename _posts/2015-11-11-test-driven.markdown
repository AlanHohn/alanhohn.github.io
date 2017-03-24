---
layout: post
title: "Situational Test Driven Development"
description: ""
category: articles
tags: []
---

I was thinking today about Test Driven Development (TDD) in the context
of Code I Have Known. I think I found a couple examples that
illustrate what I think is great and not so great about TDD. Both
are examples of code I wrote, and of which I am proud, which I think
is important for the example. 

The first was a message parser I wrote to support a strange packed binary
format. There were a number of possible message types, each with its
own set of fields (e.g. fixed point, enumerated). Fields were an arbitrary and
certainly not byte-aligned length. The data was then split up into
six bit chunks and encoded (not [Base 64][b64] encoding, a different one).
Taking the incoming ASCII data, converting back to six-bit
bytes, then shifting, we could make a packed byte array. This packed
byte array could then be read in a painful, non-byte-aligned fashion. And
this was all in Java, so of course no unsigned types.

[b64]:https://tools.ietf.org/html/rfc3548

This is the kind of problem in which TDD shines. I started with a
message of known content, wrote unit tests, and coded until those
tests passed. Then I did the same thing with a whole file of messages.
And, of course, when messages broke the parser, I made them
into new tests. I can't imagine trying to write this without a proper
unit test framework or trying to write the whole thing without testing
any of the parts in isolation.

The second example was a unit test framework I wrote to allow Java EE
code to be tested in a regular Java SE unit test, without starting up
an application server. It provided an API to statically deploy
individual Enterprise Java Beans ([EJB][ejb]s), and provided them with
dependency injection, lookup, transactions, persistence, and messaging.
Clever use of mocking meant that you could focus on one EJB, and maybe
a couple collaborators, without needing a lot of complex setup of
initial conditions.
The whole thing was based on Spring, with help from ActiveMQ and just
the right amount of custom code. ([JNDI][jndi] is just a fancy HashMap, 
right?)

[ejb]:http://www.oracle.com/technetwork/java/javaee/ejb/index.html
[jndi]:http://www.oracle.com/technetwork/java/jndi/index.html

For this problem, getting the API right is the biggest issue, and I
went through a few iterations before finding something that worked
well (informed by a [fluent interface][fi] perspective). During that
refactoring, I wrote no unit tests, and unit tests would not have 
helped me to achieve the right API. If I had written tests
first, presumably with some mock implementation to make the simplest
possible test pass, I would have spent lots of effort refactoring unit
tests every time I changed the API. Indeed, I wonder if I would have
been subtly shaped by having working unit tests and not wanted to rip
them up to go after a better API.

[fi]:http://martinfowler.com/bliki/FluentInterface.html

Of course, once the core API was in place, with some functionality
behind it, I wrote a simple unit test, used it to fix issues, then
wrote more and more tests. Then as people used the framework and found
bugs, I added tests as I fixed the bugs. So the unit tests were still
very helpful (and the framework ended up with over 90% unit test
code coverage). But in no way could you describe what I did as Test
*Driven* Development.

This gets to my central view on TDD, which is that it is great for
testing code with known inputs and outputs, and it is nice having 
a lot of unit tests when you are
refactoring, but you can't rely on it to refactor yourself into a
good design. (That seems obvious, but I have seen tutorials on TDD
that include a Final Refactor to a good design. They then argue that TDD,
rather than just good software design principles, was involved
in figuring out the design that was chosen.) In fact, if you 
haven't settled on how the code should be organized and especially 
the right structure and signatures, having a bunch of tests that 
continually need rework is a productivity drain and could get
in the way of that inspiration you need to make something worth
being proud of.

Really, this is not a criticism of TDD, but of any attempt to
turn a good technique or behavior into a Methodology or Process.
Engineering is performed ["in the light of experience as guided by 
intelligence"][nw]. For any Process, there is what I call a
Magic Happens Here step, where the real architecture, design, or
implementation decisions are made. If we become slaves to a routine, 
we risk not allowing the magic to happen.

[nw]:http://pq.2002.tripod.com/nero_wolfe_quotes.html

