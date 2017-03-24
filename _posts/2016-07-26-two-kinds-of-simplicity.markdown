---
layout: post
title: "Two Kinds of Simplicity"
description: ""
category: articles
tags: []
---

Suggested Zone: Java

TLDR: Why do we argue so much about which way is simpler?

I was reading Niklaus Wirth's [On the Design of Programming Languages][1]
and was struck by his discussion of simplicity. It appeared to me to
apply to a number of concepts in architecture and design beyond just
programming languages, and even to explain why we so often disagree
about design choices.

One of the key insights of his paper is that there are multiple kinds of
simplicity. He gives the example of generalizing all of the different
data types into untyped values.  He points out that this simplicity
through generality makes it easier to write compilers, but shifts the
onus to the programmer to make sure that type-less values are used
correctly. So it's really a tradeoff of one kind of simplicity for
another.

Of course this debate has continued right down to the present day, with
Java on one side, JavaScript on the other, and Python somewhere in the
middle. However, perhaps because we've had this debate for so long, we
no longer talk about it in terms of simplicity; we talk in terms of
safety or tractability.

But this way of thinking reminded me of another debate that's very live
in the Java community, the debate about frameworks. Interestingly, both
sides talk in terms of simplicity. The pro-framework side talks about
how simple it is to create code that accomplishes significant function,
while the other side talks about how our code is simpler to understand
and debug without all the framework under the covers.

You see this kind of debate in numerous areas in Java. It was one of the
original arguments behind the shift from SOAP to REST in web services (although
the framework side managed to make REST frameworks). It's a major argument
behind whether Java annotations are good or bad (since the use of annotations
pretty much necessitates some framework to find those annotations and do
something intelligent with them). And it's definitely present in the discussion
over Object Relational Mapping (ORM) using [Hibernate][2] versus writing SQL
directly or using an API like [jOOQ][3].

In debates like these, where it appears that people are talking past each
other, it usually means that there is some disagreement of terminology.
(In contrast, the debate over type safety seems much less contentious,
because both sides agree what values are at stake and the only disagreement
is about the relative importance of those values. It's much easier to
"agree to disagree" over ranking of values.)

It took me reading Wirth's paper to realize that the disagreement of
terminology is about "simplicity". A little searching will show people
saying that they are choosing the Java Persistence API (JPA) "for simplicity",
but the jOOQ user manual says that "heavy mappers" hide the simplicity
of relational data. Clearly both sides can't be using the term simplicity
in the same way.

I think one way to describe the two sides is "simplicity of abstraction" and
"simplicity of structure". On the ORM side, you have an abstraction of data
that has a very simple programming interface. You store your data in the objects
you have, the Entity Manager API has relatively few methods, of which you
mostly only use persist() and find(), and when you write queries you use
the property names of your objects and mostly ignore the underlying table
structure. The abstraction of the ORM reduces the number of concepts and
languages floating around, resulting in a simpler implementation.

On the jOOQ side, or writing SQL directly in a Database Access Object (DAO),
there is a clear connection between the code being written and the communication
with the database. If something is wrong with a query, it is simple to find the
code that runs it and perform debugging. If something is wrong with the code
that reads the result set and populates objects, it is simple to know where
that code is and fix it. Nothing is hidden; the structure is visible and simple.

Deciding which of these is better is probably best left to the individual system
and use case. But it's worth noting that the tradeoff is shades of gray, not
black and white. jOOQ provides a fluent API that abstracts SQL somewhat, and
even writing SQL directly in a DAO leverages Java Database Connectivity (JDBC)
to do the actual database communication. JDBC is an abstraction on top of a
low level network protocol, and SQL itself is an abstraction on top of database
storage. On the ORM side, besides the ability to "createNativeQuery()" that
jumps down to the SQL level, even regular queries are a nod to having a
simpler structure at the cost of a full abstraction. Query documents like those
found in MongoDB, where a model object is created and used to match items in
the database, is arguably more abstract even than Entity Query Lanaguage (EQL)
because it bypasses a query language entirely in favor of an object-based
query.

We can have a similar discussion about using or not using Java annotations.
On one side we have the "simplicity of representation", where an annotated Java
class declares its behavior briefly, allowing focus on the business rules the
code is implementing. On the other side we have the "simplicity of flow" where
what part of the code calls what other part is clearly known. 

In neither case are we likely to convince anyone to change their views on
which one is "simpler". But hopefully we've learned that it's necessary to
ask, "Simpler in what way?"

[1]:http://web.eecs.umich.edu/~bchandra/courses/papers/Wirth_Design.pdf
[2]:http://hibernate.org/
[3]:http://www.jooq.org/

