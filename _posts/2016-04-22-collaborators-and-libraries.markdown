---
layout: post
title: "Collaborators and Libraries: Java Design Patterns for Success"
description: ""
category: articles
tags: []
---

My fellow [Zone Leader][zl] [Sam Atkinson][sam] wrote an [excellent
article][art] on Beautiful Constructors. While I definitely agree that
the constructors in his article are beautiful, I wasn't as sure that
his prescriptions could be universally applied. He graciously allowed
me to use his piece as a springboard for a counterpoint, in the hope
of some good discussion. Of course, the opinions in this article are my
own.

## Collaborators

The style of design Sam describes seems to me to work best for a
*collaborator* class. I'm not as convinced it's the right approach
for a *library* class. Here's what I mean.

In any well-designed, modular program, we have more structure than
just "a bunch of objects that call each other". Classes are part of
a larger group and work together within that group to accomplish
some discrete function for the overall program. Ideally, there are
very few points where these larger groups reach outside the group
and interact with other groups. This concept is called "low coupling,
high cohesion" or controlling "interface width".

At its best, this design style means that even in a large application,
we have just a few classes that are the entry point for each of these
modules we've defined. These are our collaborators: as far as other
modules are concerned they represent the whole behavior of the module,
hiding the implementation details. The whole thing is like the 
interaction of the Great Powers in the [Concert of Europe][concert]:
each collaborator agrees to stay out of the internal affairs of the
others and to respect their territory.

Collaborators shouldn't expose their internal state to other collaborators;
it's their job to keep that hidden. Also, collaborators should not
be handling possible "null" values for other collaborators, because
knowing what to do in the case some other Great Power is missing typically
requires knowing a lot about what that Great Power does, which breaks
encapsulation. Finally, collaborators should not generally throw exceptions from
their constructor (except in the case of fatal programming errors) because they
are expected to handle exceptional conditions themselves and not propagate them
to other collaborators. Great Powers suppress their own rebellions.

So I am definitely a fan of simple constructors for a collaborator
(with a simple non-null assertion so we fail fast):

```java
public class Austria {
private final Prussia prussia;
private final France france;
public Austria(Prussia prussia, France france) {
    Assert.notNull(prussia, france);
    this.prussia = prussia;
    this.france = france;
}
```

The non-null assertion above is from Spring; if you're not already using
Spring don't bring it in just for that assertion. (As an aside, I think
that bringing in a chain of dependencies to get one simple function should
forever be known as "[leftpadding][lp]".)

Of course, if all the collaborators depend on each other, we can't strictly use
constructors, because we end up with a circular dependency issue. But in a lot
of cases the dependencies between well-designed collaborators end up mostly
being acyclic because there is some natural ordering in the application.

## Library Classes

By contrast, I don't think this style of constructor is always the right one
for library classes. By library class, I mean a class that may be an entry
point to multiple classes of functionality, but is not at the level of a
collaborator because it serves too specific of a purpose. Often this purpose is
technology-specific rather than application-specific. Some examples will help
to illustrate the difference.

When I saw Sam's suggestion to avoid complex constructors and instead have a
separate init method, one counter-example that jumped into my head is that
well-known library class from Java network programming, `java.net.Socket`.

```java
client = new Socket("localhost", 12345);
```

Socket definitely has some complex logic in the constructor, which can throw
either `UnknownHostException` or the more generic `IOException`. The constructor
actually makes the socket connection!

To me this makes perfect sense semantically, and thinking about "why" helped me
to understand what I think is the important difference between collaborators
and library classes. By throwing an exception from the constructor, this class
is saying:

* I exist solely to wrap a socket connection
* If I don't connect successfully, you don't have a "Socket"

This seems like exactly the right set of semantics for a socket class. I only
wish this class went one step further and eliminated the "unconnected" constructors
and the "connect" public method. A better example might be `FileOutputStream`:

```java
outStream = new FileOutputStream("temp.txt");
```

This class does not have a public "open" method, so the only way to get an
instance of this class is to successfully open a file, and the only way to
reopen a closed file is to make a new instance. That seems exactly right
because it suggests the right behavior, which is to keep this object around
only for as long as it is needed to write to the file. So this class is
implicitly saying:

* I exist solely to wrap an open file
* If I can't open the file, you don't have a file output stream
* Once you close me, my instance cannot be used and should be discarded

That's some impressive semantic richness that we get just by throwing
exceptions from the constructor and not having a public "init" or "open"
method. Note that all of this is in the Javadoc, but we didn't need the
Javadoc, because we could infer it from the available methods and their
signatures. That is the best kind of documentation.

## Null Values

So how about null values? Can I make a case for using them sometimes? 
Possibly. I really, really like the design pattern that Sam suggests, which
is to have a no-op implementation of the interface that can be used as a 
"default" by users of the class that don't need the behavior.

But I don't think it can be applied universally. I'm not sure what the "no-op"
implementation of a transaction is; it seems dangerous to lead users to think
they have a transaction when they don't have one. And often, what we require
is not a transaction but a `TransactionManager`; not a connection but a 
`ConnectionFactory`. I'm not sure what a no-op implementation of either of
those would look like.

This gets back to the distinction I made between collaborators and library
classes. A collaborator has to combine behavior from many things, but it does
it in the context of one application. A library class does one thing, but it
does it in the context of many different applications. With library classes,
it's pretty much inherent that you want your functionality to be usable in a
wide variety of contexts, which means you wind up writing code that says, 
"I'll use a transaction manager if you give me one, but I won't fail if you
don't".

## Conclusion

Hopefully I've added to the conversation here. I think there's a lot of value
in thinking about topics like this, so I'm very grateful to Sam for his article
and I'm looking forward to reading his next, whether in reply to this one or
on some other topic. Mostly, I think as developers we need to cultivate an
*aesthetic* sense of what good design is, because it makes it easier to "see"
good design when we don't have to stop to reason through it at each step.
But the only way to cultivate that aesthetic sense of design is to make
arguments about "what makes design good" and then try to back it up with
examples.

[zl]:https://dzone.com/pages/zoneleader
[sam]:https://dzone.com/users/1338295/samberic.html
[art]:https://dzone.com/articles/beautiful-constructors
[concert]:https://en.wikipedia.org/wiki/Concert_of_Europe
[lp]:http://www.haneycodes.net/npm-left-pad-have-we-forgotten-how-to-program/

