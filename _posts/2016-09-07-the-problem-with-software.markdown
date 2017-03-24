---
layout: post
title: "The Problem With Software"
description: ""
category: articles
tags: []
---

I was reading Martin Fowler's [well-known paper][1] on architecture as a result
of the reading and thinking I've been doing about the work of an architect (as
exemplified in a [few][2] [recent][3] [articles][4]).

I very much like the idea of thinking about architecture as "things which are
hard to change". As he points out, in software there is no particular reason
why *anything* should be hard to change. For anything we can think of:
interfaces, database schema, even programming language, someone has come up
with a scheme to make it easy to change.

In the article, Fowler extensively quotes Ralph Johnson. In one place, Johnson
points out that there is some limit to making something easy to change. Every
attempt to make something easy to change increases the complexity a little bit.
Coding to interfaces is an excellent practice to make it easy to change out the
implementation, but it makes the job of the maintainer a little more complex,
as it breaks the explicit connection between the method being called and the
specific implementation. Dependency injection makes it easy to change a class'
collaborators, but at the cost of shifting the satisfaction of dependencies
somewhere else.

It's interesting to compare this way of thinking with what Fred Brooks says in
[No Silver Bullet][5]. They both agree that complexity is what makes software
difficult. The question is whether this complexity is purely a consequence of
limits in our imagination, designs, and organizations, as Johnson and Fowler
seem to imply, or whether it is inherent in the underlying problem that
software is trying to solve, which is what Brooks suggests in No Silver Bullet.

As an example, take a piece of software that is trying to model some real-world
phenomenon, like the climate. The Earth's climate is enormously complex. To
create a complete computer simulation of the climate would require a computer
program that contained every significant factor. Unfortunately, as Douglas
Adams pointed out by [disproving the existence of art][6], there simply isn't
a simulation big enough.

So we need a model, which omits some of the significant factors but hopefully
gives us enough of the biggest ones so that we can make large-scale predictions.
(We can't make small-scale predictions without all the factors; that would be
the equivalent of predicting the weather a month from now.) The point is that,
in order to produce a program we can actually run, we already have to reduce
the complexity of our computer program compared to that of the real world.
(Of course, global climate models have been doing rather poorly compared to
observations lately, but even if they were doing well the point would still
hold.)

So without even introducing any complexity brought about by architecture or
design flaws, we already have as much complexity as we can possibly handle.
In fact, we have left over complexity that we can't handle; if we could handle
more complexity, we would introduce more climate factors and make the program
more complex.

This is what Brooks means by the *essential* complexity. It comes to us from
the fact that we are modeling the real world. There is no reason to think that
there is any way to remove or get around this essential complexity. Even in
cases where the complexity is ultimately human (as in the complexity of an
app like Uber that is continually matching riders with drivers) we can't
make the complexity go away, no matter how good our architecture is.

So what would be the hallmark of a good architecture? One answer might be
that it introduces as little complexity as possible. However, we saw
earlier that every time we make something easy to change, we introduce some
complexity. So maybe we would say it introduces as little complexity as
practical. But really all we've done is just push the question back a
step, because how do we know if the complexity we've introduced is practical?

Fowler says that agile methods attempt to contain complexity by reducing
"irreversability". When we say we make something easy to change, we could also
say that we are making the decision easy to "undo". I code to interfaces even
though I've already picked an implementation because I might want to "unpick"
that implementation. Unfortunately, this looks to me more like shifting
complexity rather than eliminating it. I introduce a microservice architecture
to make it easy to change out a component, but now in place of the complexity
of coupling I have the complexity of asynchronous processing and interface
marshalling. 

Ultimately I don't think this problem admits a solution. I suppose that's
good, in a way; I enjoy spending part of my time doing software architecture
and it would be a pity if there turned out to be One Right Architecture that
we just had to apply to solve all our problems. I don't think there's anything
we can reasonably expect to do as software developers other than continue to
muddle through, do the best we can with what we know, and continue to
grind out incremental improvements in building software with each new
technology, new idea, and new generation of developers. But given that this
is how we got from the observation balloon to sending people into space,
maybe that's not such a bad approach after all.

[1]:http://www.in-gmbh.de/uploads/media/whoNeedsArchitect.pdf
[2]:https://dzone.com/articles/two-kinds-of-simplicity
[3]:https://dzone.com/articles/simplicity-one-concept
[4]:https://dzone.com/articles/in-search-of-simplicity-one-diagram
[5]:http://worrydream.com/refs/Brooks-NoSilverBullet.pdf
[6]:http://www.goodreads.com/quotes/92489-the-hitchhiker-s-guide-to-the-galaxy-s-definition-of-universe-the

