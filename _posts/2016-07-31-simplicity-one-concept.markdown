---
layout: post
title: "Simplicity: One Concept"
description: ""
category: articles
tags: []
---

Suggested Zone: Agile

TLDR: For a system to survive long-term incremental development, it helps to
have one concept that stays true.

I've been thinking and writing about simplicity in architecture and design as a
result of reading Niklaus Wirth's [article on programming languages][1]. The
first article was about how arguments over design can result from having
[multiple kinds of simplicity][2], while the second was about the need for
architects to communicate using [one diagram][3].

This time I want to discuss a kind of simplicity related to architecture and
communication. In any complex system, there are a lot of interrelated pieces
with associated interfaces. It is impossible to have a complete mental model of
all of the pieces down to the lowest level of detail. So we need an
abstraction.

But the kind of abstraction we pick can make a large difference in the ability
to understand the system and make useful predictions about its behavior. This
is hard to talk about in general, so let's take a specific example. The core
idea of a Service Oriented Architecture (SOA) seems like a very simple and
useful abstraction. And there is some value to it. It suggests that the various
pieces of the system will be encapsulated in services that will be as
independent from each other as possible. These services will use each other
via defined, typically language agnostic interfaces.

So by saying that a system uses SOA we have said something useful about it that
enables us to think about the system without having to go into every detail
about every piece. But I think there's an insufficiency here that is the reason
that so many attempts to do SOA (or similarly to do a microservice architecture)
go badly wrong. We've established rules for *how* one piece of our system talks
to another, but we haven't established any rules as to *which* pieces generally
should communicate with each other, *when*, or *what* they should communicate.

I'll show my age a little by pointing out that SOA (and even some microservice
architectures) remind me of [CORBA][]. CORBA also specified a model for
interaction between components in a system. We would ignore process boundaries,
locality, and programming languages, and define objects that accepted and
responded synchronously to messages as defined in an interface description
language.

Unfortunately, with only the *how* of communication specified, many CORBA
systems became a hodge-podge of objects communicating with and dependent on
each other, resulting in brittle systems that struggled with performance. And
also unfortunately, there's been a share of that with SOA and more recently
with microservice architectures as well.

So what is an example of a single unifying concept that is abstract enough to
unite the pieces of a single system, while having enough meat to specify
not just interactions but also rules of behavior? I don't think I can identify
a rule for coming up with such an abstraction, but I've seen a couple that
worked for real-world systems.

A while back I was the architect for a system that provides near-real-time
data updates from various specialized pieces of hardware, while also allowing
the system users to control that hardware. This system uses an n-tier architecture,
but since there are multiple hardware devices and events are fed into the
system from both the users and the hardware, it had the potential to become
uncontrolled and therefore difficult to manage state. To avoid this, the concept
we chose was "synchronous down, asynchronous up". User input is fed into the
application via synchronous remote calls to a stateless application layer,
where the user interface is notified that the input was received successfully.
This constrains the user interface to assemble complete requests to the system,
since there is no mechanism to fire off partial requests. Meanwhile, data from
the hardware devices is fed asynchronously to the application when received,
even if the hardware device is queried via polling. This has the effect of
decoupling the interfaces used by the user interface from those used by the
hardware (since one is remote invocation while the other is messaging),
effectively separating the two types of inputs to the system. Similarly,
data updates to the user interface go asynchronously, which simplifies the
behavior of the application tier and permits it to be agnostic as to how
many users there are and how they use the data.

All of which is a great many words to say things that are inherent in the
concept of "synchronous down, asynchronous up". I think this is a good
*post hoc* indicator that the single system concept is truly one that
simplifies thinking about the system while also specifying its behavior; it
should be possible to use the concept to illuminate a large number of system
behaviors that otherwise do not appear related.

On another recent system, we were presented with the challenge of building an
architecture for a set of unknown applications, with the desire of integrating
arbitrary future applications. For this system, we chose a concept of
"distributed integration" based on the [Enterprise Integration Patterns][eip].
The preferred backbone communication is publish-subscribe messaging using a
canonical data model, but if individual applications show up with custom data
models or with custom interfaces, the system accomodates this by adding
integration capabilities that are as local to the application as is practical.
Similar to the above, this concept serves as a guide for the "right way" to
perform a variety of behaviors in the system. For example, if an application
produces data that must be persisted to a database, rather than having a single
persistence application that knows all about every application, a new small
piece is added to perform persistence for that specific application's data.
Or, if Application A relies on a capability provided by Application B, but
expects a REST interface rather than directly following the [Request-Reply][rr]
pattern, that REST interface should be created as a separate piece rather than
requiring Application B to add that REST interface. This is another valuable
thing to look for in a simplifying system concept; it should make it easier to
make decisions about how to implement the system in cases where the decision
could go either way.

So while it might not be easy to identify a process for devising the "one
concept" for a system, I think there are a few lessons we can draw from
these examples. First, it's necessary but not sufficient to identify a category
of architecture like "SOA" or "microservice". Those categories are valuable
to get people thinking in the right direction, but they allow too much flexibility
in implementation to have a consistent system. Second, the system concept has
to be specific to the end goals of the system. There's an interesting parallel to
the ["As a... I want... so that..."][us] template used for user stories; the
system concept should tie back directly to key system goals. Finally, the
system concept should work both retrospectively (to explain to maintainers why
the system works the way it does) and prospectively (to help maintainers 
understand how to add capability without breaking the system).

As I said above, I don't think I have a good process or approach for coming up
with this concept; it probably falls into a ["magic happens here"][magic] step.
But as architects, time spent thinking about the system and what it needs to
accomplish is well spent anyway, and ending up with a good diagram and a good
single concept might enable our system to last longer and work better.

[1]:http://web.eecs.umich.edu/~bchandra/courses/papers/Wirth_Design.pdf
[2]:https://dzone.com/articles/two-kinds-of-simplicity
[3]:https://dzone.com/articles/in-search-of-simplicity-one-diagram
[corba]:http://www.corba.org/
[eip]:http://www.enterpriseintegrationpatterns.com/
[rr]:http://www.enterpriseintegrationpatterns.com/patterns/messaging/RequestReply.html
[us]:https://www.mountaingoatsoftware.com/blog/advantages-of-the-as-a-user-i-want-user-story-template
[magic]:https://dzone.com/articles/looking-along-the-beam-analysis-and-insight

